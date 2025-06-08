import 'package:hive_ui/features/auth/domain/repositories/auth_repository.dart';
import 'package:hive_ui/core/usecases/usecase.dart';

/// UseCase for sending a password reset email
class ResetPasswordUseCase implements UseCase<void, ResetPasswordParams> {
  final AuthRepository _authRepository;

  /// Creates a ResetPasswordUseCase instance
  ResetPasswordUseCase(this._authRepository);

  /// Execute the password reset operation
  @override
  Future<void> call(ResetPasswordParams params) async {
    return await _authRepository.sendPasswordResetEmail(params.email);
  }
}

/// Parameters for the password reset use case
class ResetPasswordParams {
  final String email;

  /// Creates ResetPasswordParams instance
  ResetPasswordParams({required this.email});
}
