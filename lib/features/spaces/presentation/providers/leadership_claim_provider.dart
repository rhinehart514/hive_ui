import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/spaces/data/repositories/claims_repository_impl.dart';
import 'package:hive_ui/features/spaces/domain/entities/claim_entity.dart';
import 'package:hive_ui/features/spaces/domain/repositories/claims_repository.dart';
import 'package:hive_ui/features/spaces/domain/repositories/spaces_repository.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_providers.dart';

/// Enum representing the different states of a leadership claim submission
enum ClaimSubmissionState {
  initial,
  submitting,
  success,
  error,
}

/// Data class representing a leadership claim
class LeadershipClaim {
  final String id;
  final String spaceId;
  final String userId;
  final String userName;
  final String userEmail;
  final String role;
  final String verificationMethod;
  final String? notes;
  final DateTime submittedAt;
  
  const LeadershipClaim({
    required this.id,
    required this.spaceId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.role,
    required this.verificationMethod,
    this.notes,
    required this.submittedAt,
  });
  
  /// Convert to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'spaceId': spaceId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'role': role,
      'verificationMethod': verificationMethod,
      'notes': notes,
      'submittedAt': submittedAt.toIso8601String(),
      'status': 'pending',
    };
  }
}

/// State class for the leadership claim provider
class LeadershipClaimState {
  final ClaimSubmissionState submissionState;
  final String? errorMessage;
  final ClaimEntity? currentClaim;
  final List<ClaimEntity> userClaims;
  
  const LeadershipClaimState({
    this.submissionState = ClaimSubmissionState.initial,
    this.errorMessage,
    this.currentClaim,
    this.userClaims = const [],
  });
  
  /// Create a copy of this state with the given fields replaced
  LeadershipClaimState copyWith({
    ClaimSubmissionState? submissionState,
    String? errorMessage,
    ClaimEntity? currentClaim,
    List<ClaimEntity>? userClaims,
  }) {
    return LeadershipClaimState(
      submissionState: submissionState ?? this.submissionState,
      errorMessage: errorMessage ?? this.errorMessage,
      currentClaim: currentClaim ?? this.currentClaim,
      userClaims: userClaims ?? this.userClaims,
    );
  }
}

/// Provider for leadership claim operations
class LeadershipClaimNotifier extends StateNotifier<LeadershipClaimState> {
  final ClaimsRepository _claimsRepository;
  final SpacesRepository _spacesRepository;
  
  LeadershipClaimNotifier(this._claimsRepository, this._spacesRepository) 
      : super(const LeadershipClaimState());
  
  /// Submit a new leadership claim
  Future<void> submitClaim({
    required String spaceId,
    required String userId,
    required String userName,
    required String userEmail,
    required String role,
    required String verificationMethod,
    String? notes,
  }) async {
    try {
      state = state.copyWith(
        submissionState: ClaimSubmissionState.submitting,
        errorMessage: null,
      );
      
      // Get the space to check if it can be claimed
      final space = await _spacesRepository.getSpaceById(spaceId);
      if (space == null) {
        state = state.copyWith(
          submissionState: ClaimSubmissionState.error,
          errorMessage: 'Space not found',
        );
        return;
      }
      
      // Submit the claim
      final claim = await _claimsRepository.submitClaim(
        spaceId: spaceId,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        role: role,
        verificationMethod: verificationMethod,
        notes: notes,
      );
      
      // Update state to success
      state = state.copyWith(
        submissionState: ClaimSubmissionState.success,
        currentClaim: claim,
      );
      
      // Refresh user claims
      await loadUserClaims(userId);
    } catch (e) {
      debugPrint('Error submitting leadership claim: $e');
      state = state.copyWith(
        submissionState: ClaimSubmissionState.error,
        errorMessage: 'Failed to submit claim: ${e.toString()}',
      );
    }
  }
  
  /// Load claims for a specific user
  Future<void> loadUserClaims(String userId) async {
    try {
      final claims = await _claimsRepository.getClaimsByUserId(userId);
      state = state.copyWith(userClaims: claims);
    } catch (e) {
      debugPrint('Error loading user claims: $e');
    }
  }
  
  /// Load claim details by ID
  Future<void> loadClaimById(String claimId) async {
    try {
      final claim = await _claimsRepository.getClaimById(claimId);
      if (claim != null) {
        state = state.copyWith(currentClaim: claim);
      }
    } catch (e) {
      debugPrint('Error loading claim: $e');
    }
  }
  
  /// Cancel the current claim
  Future<bool> cancelClaim(String claimId) async {
    try {
      final result = await _claimsRepository.cancelClaim(claimId);
      if (result) {
        // Refresh the current claim
        await loadClaimById(claimId);
        // Refresh the user's claims if we have a current user
        if (state.currentClaim != null) {
          await loadUserClaims(state.currentClaim!.userId);
        }
      }
      return result;
    } catch (e) {
      debugPrint('Error canceling claim: $e');
      return false;
    }
  }
  
  /// Clear the current submission state
  void clearSubmissionState() {
    state = state.copyWith(
      submissionState: ClaimSubmissionState.initial,
      errorMessage: null,
    );
  }
}

/// Provider for the claims repository
final claimsRepositoryProvider = Provider<ClaimsRepository>((ref) {
  final spacesRepository = ref.watch(spacesRepositoryProvider);
  return ClaimsRepositoryImpl(spacesRepository: spacesRepository);
});

/// Provider for the leadership claim state
final leadershipClaimProvider = 
    StateNotifierProvider<LeadershipClaimNotifier, LeadershipClaimState>((ref) {
  final claimsRepository = ref.watch(claimsRepositoryProvider);
  final spacesRepository = ref.watch(spacesRepositoryProvider);
  return LeadershipClaimNotifier(claimsRepository, spacesRepository);
}); 