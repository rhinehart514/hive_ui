import 'package:hive_ui/features/auth/domain/entities/auth_user.dart';
import 'package:hive_ui/features/auth/domain/repositories/auth_repository.dart';
import 'package:hive_ui/core/usecases/usecase.dart';

/// UseCase for creating a new user account with email and password
class SignUpUseCase implements UseCase<AuthUser, SignUpParams> {
  final AuthRepository _authRepository;

  /// Creates a SignUpUseCase instance
  SignUpUseCase(this._authRepository);

  /// Execute the sign up operation
  @override
  Future<AuthUser> call(SignUpParams params) async {
    return await _authRepository.createUserWithEmailPassword(
      params.email,
      params.password,
    );
  }
}

/// Parameters for the sign up use case
class SignUpParams {
  final String email;
  final String password;

  /// Creates SignUpParams instance
  SignUpParams({
    required this.email,
    required this.password,
  });
}
