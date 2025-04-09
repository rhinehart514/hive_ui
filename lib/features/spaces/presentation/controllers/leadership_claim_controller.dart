import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/spaces/domain/entities/leadership_claim_entity.dart';
import 'package:hive_ui/features/spaces/presentation/providers/leadership_claim_providers.dart';
import 'package:hive_ui/features/spaces/domain/repositories/leadership_claim_repository.dart';

/// Controller for leadership claim operations
class LeadershipClaimController {
  final Ref _ref;
  
  /// Constructor
  LeadershipClaimController(this._ref);
  
  /// Create a new leadership claim
  Future<void> createClaim({
    required String spaceId,
    required String userId,
    required String userName,
    required String email,
    required String role,
    required VerificationDocumentType documentType,
    String? documentUrl,
    required String notes,
  }) async {
    try {
      // Set loading state
      _ref.read(claimOperationStateProvider.notifier).state = ClaimOperationState.loading();
      
      // Get the use case
      final useCase = _ref.read(createLeadershipClaimUseCaseProvider);
      
      // Execute the use case
      await useCase.execute(
        spaceId: spaceId,
        userId: userId,
        userName: userName,
        email: email,
        role: role,
        documentType: documentType,
        documentUrl: documentUrl,
        notes: notes,
      );
      
      // Set success state
      _ref.read(claimOperationStateProvider.notifier).state = ClaimOperationState.success();
      
      // Refresh providers
      _ref.refresh(spaceClaimProvider(spaceId));
      _ref.refresh(pendingClaimsProvider);
      _ref.refresh(userClaimsProvider(userId));
    } catch (e) {
      // Set error state
      final errorMessage = e is LeadershipClaimException ? e.message : e.toString();
      _ref.read(claimOperationStateProvider.notifier).state = ClaimOperationState.error(errorMessage);
    }
  }
  
  /// Approve a claim
  Future<void> approveClaim({
    required String claimId,
    required String reviewerId,
    String? reviewNotes,
  }) async {
    try {
      // Set loading state
      _ref.read(claimOperationStateProvider.notifier).state = ClaimOperationState.loading();
      
      // Get the use case
      final useCase = _ref.read(approveClaimUseCaseProvider);
      
      // Execute the use case
      final updatedClaim = await useCase.execute(
        claimId: claimId,
        reviewerId: reviewerId,
        reviewNotes: reviewNotes,
      );
      
      // Set success state
      _ref.read(claimOperationStateProvider.notifier).state = ClaimOperationState.success();
      
      // Refresh providers
      _ref.refresh(spaceClaimProvider(updatedClaim.spaceId));
      _ref.refresh(pendingClaimsProvider);
      _ref.refresh(userClaimsProvider(updatedClaim.userId));
    } catch (e) {
      // Set error state
      final errorMessage = e is LeadershipClaimException ? e.message : e.toString();
      _ref.read(claimOperationStateProvider.notifier).state = ClaimOperationState.error(errorMessage);
    }
  }
  
  /// Reject a claim
  Future<void> rejectClaim({
    required String claimId,
    required String reviewerId,
    required String reviewNotes,
  }) async {
    try {
      // Set loading state
      _ref.read(claimOperationStateProvider.notifier).state = ClaimOperationState.loading();
      
      // Get the use case
      final useCase = _ref.read(rejectClaimUseCaseProvider);
      
      // Execute the use case
      final updatedClaim = await useCase.execute(
        claimId: claimId,
        reviewerId: reviewerId,
        reviewNotes: reviewNotes,
      );
      
      // Set success state
      _ref.read(claimOperationStateProvider.notifier).state = ClaimOperationState.success();
      
      // Refresh providers
      _ref.refresh(spaceClaimProvider(updatedClaim.spaceId));
      _ref.refresh(pendingClaimsProvider);
      _ref.refresh(userClaimsProvider(updatedClaim.userId));
    } catch (e) {
      // Set error state
      final errorMessage = e is LeadershipClaimException ? e.message : e.toString();
      _ref.read(claimOperationStateProvider.notifier).state = ClaimOperationState.error(errorMessage);
    }
  }
  
  /// Cancel a claim
  Future<void> cancelClaim({
    required String claimId,
    required String userId,
    required String spaceId,
  }) async {
    try {
      // Set loading state
      _ref.read(claimOperationStateProvider.notifier).state = ClaimOperationState.loading();
      
      // Get the use case
      final useCase = _ref.read(cancelClaimUseCaseProvider);
      
      // Execute the use case
      await useCase.execute(
        claimId: claimId,
        userId: userId,
      );
      
      // Set success state
      _ref.read(claimOperationStateProvider.notifier).state = ClaimOperationState.success();
      
      // Refresh providers
      _ref.refresh(spaceClaimProvider(spaceId));
      _ref.refresh(pendingClaimsProvider);
      _ref.refresh(userClaimsProvider(userId));
    } catch (e) {
      // Set error state
      final errorMessage = e is LeadershipClaimException ? e.message : e.toString();
      _ref.read(claimOperationStateProvider.notifier).state = ClaimOperationState.error(errorMessage);
    }
  }
  
  /// Check if a space requires a leadership claim
  Future<bool> spaceRequiresClaim(String spaceId) async {
    final useCase = _ref.read(checkSpaceRequiresClaimUseCaseProvider);
    return useCase.execute(spaceId);
  }
}

/// Provider for the leadership claim controller
final leadershipClaimControllerProvider = Provider<LeadershipClaimController>((ref) {
  return LeadershipClaimController(ref);
}); 