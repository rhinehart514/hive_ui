import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/services/email_service.dart';
import 'package:hive_ui/features/auth/auth_providers.dart';
import 'package:hive_ui/features/profile/domain/entities/verification_status.dart';

/// Provider for getting the current user's verification status
final userVerificationProvider = StreamProvider<UserVerification>((ref) {
  final userId = ref.watch(currentUserProvider).value?.uid;
  if (userId == null) {
    return Stream.value(UserVerification.empty(''));
  }

  return FirebaseFirestore.instance
      .collection('user_verifications')
      .doc(userId)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) {
      return UserVerification.empty(userId);
    }
    return UserVerification.fromDocument(snapshot);
  });
});

/// Check if user can apply for verification
final canApplyForVerificationProvider = Provider.family<bool, UserVerification>((ref, verification) {
  // If user is already at verified+ level, they can't upgrade further
  if (verification.level == VerificationLevel.verifiedPlus) {
    return false;
  }
  
  // If user has a pending verification, they can't apply for another
  if (verification.status == VerificationStatus.pending) {
    return false;
  }
  
  // If the user is already verified at the standard level, they can't apply for 
  // verified+ directly as that requires admin approval
  if (verification.level == VerificationLevel.verified && 
      verification.status == VerificationStatus.verified) {
    return false; // Verified+ is admin-assigned only
  }
  
  return true;
});

/// Check if user is allowed to create content
final canCreateContentProvider = Provider<bool>((ref) {
  final verification = ref.watch(userVerificationProvider).value;
  if (verification == null) return false;
  
  // Public users can't create content
  if (verification.level == VerificationLevel.public) {
    return false;
  }
  
  // Verified or Verified+ users can create content if they're verified
  return verification.status == VerificationStatus.verified;
});

/// Check if user is allowed to create spaces
final canCreateSpacesProvider = Provider<bool>((ref) {
  final verification = ref.watch(userVerificationProvider).value;
  if (verification == null) return false;
  
  // Only verified users can create spaces
  return verification.level != VerificationLevel.public && 
         verification.status == VerificationStatus.verified;
});

/// State for email verification process
class EmailVerificationState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;
  final DateTime? codeSentAt;
  final String? verificationCode; // Will be null in production
  
  const EmailVerificationState({
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
    this.codeSentAt,
    this.verificationCode,
  });
  
  EmailVerificationState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? error,
    DateTime? codeSentAt,
    String? verificationCode,
  }) {
    return EmailVerificationState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
      codeSentAt: codeSentAt ?? this.codeSentAt,
      verificationCode: verificationCode ?? this.verificationCode,
    );
  }
}

/// Provider for email service
final emailServiceProvider = Provider<EmailService>((ref) {
  return EmailService();
});

/// Provider for handling email verification
class EmailVerificationNotifier extends StateNotifier<EmailVerificationState> {
  final Ref _ref;
  
  EmailVerificationNotifier(this._ref) : super(const EmailVerificationState());
  
  /// Send verification email with code
  Future<void> sendVerificationEmail() async {
    if (state.isLoading) return;
    
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    
    try {
      final emailService = _ref.read(emailServiceProvider);
      await emailService.sendVerificationEmail();
      
      // In a debug build, we might want to listen for the verification code
      // that was generated and stored in Firestore
      String? debugCode;
      if (true) { // Replace with a check for debug mode in production
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final snapshot = await FirebaseFirestore.instance
              .collection('emailVerifications')
              .where('userId', isEqualTo: user.uid)
              .orderBy('createdAt', descending: true)
              .limit(1)
              .get();
          
          if (snapshot.docs.isNotEmpty) {
            debugCode = snapshot.docs.first.data()['code'] as String?;
          }
        }
      }
      
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        codeSentAt: DateTime.now(),
        verificationCode: debugCode, // In production, this would be null
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  /// Verify the email using the provided code
  Future<void> verifyEmail(String code) async {
    if (state.isLoading) return;
    
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    
    try {
      final emailService = _ref.read(emailServiceProvider);
      await emailService.verifyEmailWithCode(code);
      
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

/// Provider for email verification
final emailVerificationProvider = StateNotifierProvider<EmailVerificationNotifier, EmailVerificationState>((ref) {
  return EmailVerificationNotifier(ref);
});

/// Request verification to be promoted to verified+ (admin granted)
class VerifiedPlusRequestNotifier extends StateNotifier<AsyncValue<void>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Ref _ref;
  
  VerifiedPlusRequestNotifier(this._ref) : super(const AsyncValue.data(null));
  
  /// Request verification for verified+ status (student leader)
  Future<void> requestVerifiedPlusStatus({
    required String spaceId,
    required String role,
    String? additionalInfo,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final user = _ref.read(currentUserProvider).value;
      if (user == null) {
        throw Exception('User not logged in');
      }
      
      // Check if user is already verified at standard level
      final verification = _ref.read(userVerificationProvider).value;
      if (verification == null || verification.level != VerificationLevel.verified) {
        throw Exception('You must be verified before requesting Verified+ status');
      }
      
      // Create verification request
      await _firestore.collection('verificationRequests').add({
        'userId': user.uid,
        'userName': user.displayName,
        'userEmail': user.email,
        'userPhotoUrl': user.photoURL,
        'requestedLevel': VerificationLevel.verifiedPlus.index,
        'currentLevel': verification.level.index,
        'spaceId': spaceId,
        'role': role,
        'additionalInfo': additionalInfo,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      
      // Update user verification status to pending
      await _firestore.collection('user_verifications').doc(user.uid).update({
        'status': VerificationStatus.pending.index,
        'submittedAt': FieldValue.serverTimestamp(),
        'connectedSpaceId': spaceId,
      });
      
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

/// Provider for verified+ requests
final verifiedPlusRequestProvider = StateNotifierProvider<VerifiedPlusRequestNotifier, AsyncValue<void>>((ref) {
  return VerifiedPlusRequestNotifier(ref);
}); 