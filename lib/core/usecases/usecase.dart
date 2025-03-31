/// Base UseCase interface that all use cases will implement
///
/// Type parameters:
/// * T - Return type of the use case
/// * P - Parameters type required by the use case
abstract class UseCase<T, P> {
  /// Execute the use case with the provided parameters
  Future<T> call(P params);
}

/// Special use case that doesn't require any parameters
abstract class NoParamsUseCase<T> {
  /// Execute the use case without parameters
  Future<T> call();
}
