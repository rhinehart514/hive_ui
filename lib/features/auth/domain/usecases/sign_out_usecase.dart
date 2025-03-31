import 'package:hive_ui/features/auth/domain/repositories/auth_repository.dart';
import 'package:hive_ui/core/usecases/usecase.dart';

/// UseCase for signing out the current user
class SignOutUseCase implements NoParamsUseCase<void> {
  final AuthRepository _authRepository;

  /// Creates a SignOutUseCase instance
  SignOutUseCase(this._authRepository);

  /// Execute the sign out operation
  @override
  Future<void> call() async {
    return await _authRepository.signOut();
  }
}
