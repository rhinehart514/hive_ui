import 'package:hive_ui/features/auth/domain/repositories/auth_repository.dart';
import 'package:hive_ui/core/usecases/usecase.dart';

/// UseCase for sending email verification
class SendEmailVerificationUseCase implements NoParamsUseCase<void> {
  final AuthRepository _authRepository;

  /// Creates a SendEmailVerificationUseCase instance
  SendEmailVerificationUseCase(this._authRepository);

  /// Execute the email verification operation
  @override
  Future<void> call() async {
    return await _authRepository.sendEmailVerification();
  }
}

/// UseCase for checking if email is verified
class CheckEmailVerifiedUseCase implements NoParamsUseCase<bool> {
  final AuthRepository _authRepository;

  /// Creates a CheckEmailVerifiedUseCase instance
  CheckEmailVerifiedUseCase(this._authRepository);

  /// Execute the email verification check
  @override
  Future<bool> call() async {
    return await _authRepository.checkEmailVerified();
  }
}

/// UseCase for updating email verification status
class UpdateEmailVerificationStatusUseCase implements NoParamsUseCase<void> {
  final AuthRepository _authRepository;

  /// Creates an UpdateEmailVerificationStatusUseCase instance
  UpdateEmailVerificationStatusUseCase(this._authRepository);

  /// Execute the update email verification status operation
  @override
  Future<void> call() async {
    return await _authRepository.updateEmailVerificationStatus();
  }
}
