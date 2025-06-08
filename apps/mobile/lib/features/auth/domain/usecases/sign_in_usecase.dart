import 'package:hive_ui/features/auth/domain/entities/auth_user.dart';
import 'package:hive_ui/features/auth/domain/repositories/auth_repository.dart';
import 'package:hive_ui/core/usecases/usecase.dart';

/// UseCase for signing in a user with email and password
class SignInUseCase implements UseCase<AuthUser, SignInParams> {
  final AuthRepository _authRepository;

  /// Creates a SignInUseCase instance
  SignInUseCase(this._authRepository);

  /// Execute the sign in operation
  @override
  Future<AuthUser> call(SignInParams params) async {
    return await _authRepository.signInWithEmailPassword(
      params.email,
      params.password,
    );
  }
}

/// Parameters for the sign in use case
class SignInParams {
  final String email;
  final String password;

  /// Creates SignInParams instance
  SignInParams({
    required this.email,
    required this.password,
  });
}
