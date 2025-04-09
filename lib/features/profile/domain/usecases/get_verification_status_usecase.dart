// import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../entities/verification_status.dart';
import '../repositories/verification_repository.dart';
// TODO: Add dependency injection for repository

// part 'get_verification_status_usecase.g.dart';

/// Use case for getting the verification status of a user.
class GetVerificationStatusUseCase {
  final VerificationRepository _repository;

  GetVerificationStatusUseCase(this._repository);

  /// Executes the use case to get the current verification status.
  Future<UserVerification?> execute(String userId) {
    return _repository.getVerificationStatus(userId);
  }
}

/// Use case for watching the verification status of a user.
class WatchVerificationStatusUseCase {
  final VerificationRepository _repository;

  WatchVerificationStatusUseCase(this._repository);

  /// Executes the use case to watch verification status updates.
  Stream<UserVerification?> execute(String userId) {
    return _repository.watchVerificationStatus(userId);
  }
}

// Example Riverpod provider generation (adjust based on actual DI setup)
// This assumes you might use Riverpod for dependency injection

// @riverpod
// VerificationRepository verificationRepository(VerificationRepositoryRef ref) {
//   // Replace with actual repository implementation provider
//   throw UnimplementedError(); 
// }

// @riverpod
// GetVerificationStatusUseCase getVerificationStatusUseCase(GetVerificationStatusUseCaseRef ref) {
//   return GetVerificationStatusUseCase(ref.watch(verificationRepositoryProvider));
// }

// @riverpod
// WatchVerificationStatusUseCase watchVerificationStatusUseCase(WatchVerificationStatusUseCaseRef ref) {
//   return WatchVerificationStatusUseCase(ref.watch(verificationRepositoryProvider));
// } 