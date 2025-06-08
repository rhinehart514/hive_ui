import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/spaces/data/repositories/leadership_claim_repository_impl.dart';
import 'package:hive_ui/features/spaces/domain/entities/leadership_claim_entity.dart';
import 'package:hive_ui/features/spaces/domain/repositories/leadership_claim_repository.dart';
import 'package:hive_ui/features/spaces/domain/usecases/leadership_claim_usecase.dart';
import 'package:hive_ui/features/spaces/presentation/providers/space_repository_provider.dart';

/// Provider for the leadership claim repository
final leadershipClaimRepositoryProvider = Provider<LeadershipClaimRepository>((ref) {
  final spacesRepository = ref.watch(spaceRepositoryProvider);
  return LeadershipClaimRepositoryImpl(spacesRepository: spacesRepository);
});

/// Provider for the create leadership claim use case
final createLeadershipClaimUseCaseProvider = Provider<CreateLeadershipClaimUseCase>((ref) {
  final repository = ref.watch(leadershipClaimRepositoryProvider);
  return CreateLeadershipClaimUseCase(repository);
});

/// Provider for the get space claim use case
final getSpaceClaimUseCaseProvider = Provider<GetSpaceClaimUseCase>((ref) {
  final repository = ref.watch(leadershipClaimRepositoryProvider);
  return GetSpaceClaimUseCase(repository);
});

/// Provider for the get pending claims use case
final getPendingClaimsUseCaseProvider = Provider<GetPendingClaimsUseCase>((ref) {
  final repository = ref.watch(leadershipClaimRepositoryProvider);
  return GetPendingClaimsUseCase(repository);
});

/// Provider for the get user claims use case
final getUserClaimsUseCaseProvider = Provider<GetUserClaimsUseCase>((ref) {
  final repository = ref.watch(leadershipClaimRepositoryProvider);
  return GetUserClaimsUseCase(repository);
});

/// Provider for the approve claim use case
final approveClaimUseCaseProvider = Provider<ApproveClaimUseCase>((ref) {
  final repository = ref.watch(leadershipClaimRepositoryProvider);
  return ApproveClaimUseCase(repository);
});

/// Provider for the reject claim use case
final rejectClaimUseCaseProvider = Provider<RejectClaimUseCase>((ref) {
  final repository = ref.watch(leadershipClaimRepositoryProvider);
  return RejectClaimUseCase(repository);
});

/// Provider for the cancel claim use case
final cancelClaimUseCaseProvider = Provider<CancelClaimUseCase>((ref) {
  final repository = ref.watch(leadershipClaimRepositoryProvider);
  return CancelClaimUseCase(repository);
});

/// Provider for the check space requires claim use case
final checkSpaceRequiresClaimUseCaseProvider = Provider<CheckSpaceRequiresClaimUseCase>((ref) {
  final repository = ref.watch(leadershipClaimRepositoryProvider);
  return CheckSpaceRequiresClaimUseCase(repository);
});

/// Provider for a specific space's claim
final spaceClaimProvider = FutureProvider.family<LeadershipClaimEntity?, String>((ref, spaceId) async {
  final useCase = ref.watch(getSpaceClaimUseCaseProvider);
  return useCase.execute(spaceId);
});

/// Provider for pending claims
final pendingClaimsProvider = FutureProvider<List<LeadershipClaimEntity>>((ref) async {
  final useCase = ref.watch(getPendingClaimsUseCaseProvider);
  return useCase.execute();
});

/// Provider for a user's claims
final userClaimsProvider = FutureProvider.family<List<LeadershipClaimEntity>, String>((ref, userId) async {
  final useCase = ref.watch(getUserClaimsUseCaseProvider);
  return useCase.execute(userId);
});

/// State class for claim operations
class ClaimOperationState {
  /// Is the operation in progress
  final bool isLoading;
  
  /// Error message if operation failed
  final String? errorMessage;
  
  /// Is the operation successful
  final bool isSuccess;
  
  /// Constructor
  const ClaimOperationState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });
  
  /// Initial state
  factory ClaimOperationState.initial() {
    return const ClaimOperationState();
  }
  
  /// Loading state
  factory ClaimOperationState.loading() {
    return const ClaimOperationState(isLoading: true);
  }
  
  /// Error state
  factory ClaimOperationState.error(String message) {
    return ClaimOperationState(errorMessage: message);
  }
  
  /// Success state
  factory ClaimOperationState.success() {
    return const ClaimOperationState(isSuccess: true);
  }
  
  /// Create a copy with modified fields
  ClaimOperationState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return ClaimOperationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// Provider for claim operation state
final claimOperationStateProvider = StateProvider<ClaimOperationState>((ref) {
  return ClaimOperationState.initial();
}); 