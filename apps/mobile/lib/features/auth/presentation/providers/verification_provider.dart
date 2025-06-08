import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/application/services/verification_service.dart';
import 'package:hive_ui/core/providers/auth_provider.dart';
import 'package:hive_ui/data/datasources/firestore_user_datasource.dart';
import 'package:hive_ui/domain/failures/auth_failure.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Verification state for tracking verification requests and status
sealed class VerificationState {
  const VerificationState();
}

/// Initial verification state
class VerificationInitial extends VerificationState {
  const VerificationInitial();
}

/// Verification not requested state
class VerificationNotRequested extends VerificationState {
  const VerificationNotRequested();
}

/// Verification request in progress state
class VerificationRequestInProgress extends VerificationState {
  const VerificationRequestInProgress();
}

/// Verification request pending review state
class VerificationPending extends VerificationState {
  const VerificationPending();
}

/// Verification approved state
class VerificationApproved extends VerificationState {
  const VerificationApproved();
}

/// Verification rejected state
class VerificationRejected extends VerificationState {
  const VerificationRejected();
}

/// Verification error state
class VerificationError extends VerificationState {
  final Failure failure;
  
  const VerificationError(this.failure);
}

/// A notifier for managing verification state
class VerificationNotifier extends StateNotifier<VerificationState> {
  final VerificationService _verificationService;
  final String _userId;
  
  /// Creates a new instance with the given dependencies
  VerificationNotifier({
    required VerificationService verificationService,
    required String userId,
  }) : _verificationService = verificationService,
       _userId = userId,
       super(const VerificationInitial()) {
    _initVerificationStatus();
  }
  
  /// Initialize the verification status based on the current user
  Future<void> _initVerificationStatus() async {
    if (_userId.isEmpty) {
      state = const VerificationNotRequested();
      return;
    }
    
    final result = await _verificationService.getVerificationStatus(_userId);
    
    if (result.isFailure) {
      state = VerificationError(result.getFailure);
      return;
    }
    
    final status = result.getSuccess;
    
    switch (status) {
      case VerificationStatus.notRequested:
        state = const VerificationNotRequested();
      case VerificationStatus.pending:
        state = const VerificationPending();
      case VerificationStatus.approved:
        state = const VerificationApproved();
      case VerificationStatus.rejected:
        state = const VerificationRejected();
    }
  }
  
  /// Request verification for the current user
  Future<void> requestVerification() async {
    if (_userId.isEmpty) {
      state = const VerificationError(
        InvalidInputFailure('User ID is empty')
      );
      return;
    }
    
    state = const VerificationRequestInProgress();
    
    final result = await _verificationService.requestVerification(_userId);
    
    if (result.isFailure) {
      state = VerificationError(result.getFailure);
      return;
    }
    
    state = const VerificationPending();
  }
  
  /// Cancel a pending verification request
  Future<void> cancelVerificationRequest() async {
    if (_userId.isEmpty) {
      state = const VerificationError(
        InvalidInputFailure('User ID is empty')
      );
      return;
    }
    
    if (state is! VerificationPending) {
      state = const VerificationError(
        InvalidInputFailure('No pending verification request to cancel')
      );
      return;
    }
    
    final result = await _verificationService.cancelVerificationRequest(_userId);
    
    if (result.isFailure) {
      state = VerificationError(result.getFailure);
      return;
    }
    
    state = const VerificationNotRequested();
  }
  
  /// Refresh the current verification status
  Future<void> refreshVerificationStatus() async {
    await _initVerificationStatus();
  }
  
  /// Check if the user is verified plus
  Future<bool> isVerifiedPlus() async {
    if (_userId.isEmpty) {
      return false;
    }
    
    final result = await _verificationService.isVerifiedPlus(_userId);
    
    if (result.isFailure) {
      return false;
    }
    
    return result.getSuccess;
  }
}

/// Provider for the verification state
final verificationProvider = StateNotifierProvider.autoDispose<VerificationNotifier, VerificationState>((ref) {
  final authState = ref.watch(authStateProvider).value;
  
  // If user isn't authenticated, return a notifier with empty user ID
  final userId = switch (authState) {
    AuthStateAuthenticated(user: final user) => user.uid,
    _ => '',
  };
  
  final verificationService = ref.watch(verificationServiceProvider);
  
  return VerificationNotifier(
    verificationService: verificationService,
    userId: userId,
  );
});

/// Provider for the verification service
final verificationServiceProvider = Provider<VerificationService>((ref) {
  // This is a placeholder - you'll need to provide the actual UserDataSource
  // Either create a userDataSourceProvider or use dependency injection
  final userDataSource = FirestoreUserDataSource(
    ref.watch(firebaseFirestoreProvider),
    'users',
    'verifiedRequests'
  );
  
  return VerificationService(userDataSource);
});

/// Provider for Firestore instance
final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Convenience provider for checking if verification is approved
/// 
/// Use this for conditional UI rendering based on verification status
final isVerifiedProvider = Provider<bool>((ref) {
  final verificationState = ref.watch(verificationProvider);
  return verificationState is VerificationApproved;
});

/// Convenience provider for checking if verification is pending
/// 
/// Use this for conditional UI rendering based on verification status
final isVerificationPendingProvider = Provider<bool>((ref) {
  final verificationState = ref.watch(verificationProvider);
  return verificationState is VerificationPending;
}); 