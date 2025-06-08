import 'package:hive_ui/features/auth/domain/entities/auth_user.dart';
import 'package:hive_ui/features/auth/domain/repositories/auth_repository.dart';
import 'package:hive_ui/core/usecases/usecase.dart';

/// UseCase for getting the current authenticated user
class GetCurrentUserUseCase implements NoParamsUseCase<AuthUser> {
  final AuthRepository _authRepository;

  /// Creates a GetCurrentUserUseCase instance
  GetCurrentUserUseCase(this._authRepository);

  /// Execute to get the current user
  @override
  Future<AuthUser> call() async {
    return _authRepository.getCurrentUser();
  }
}
