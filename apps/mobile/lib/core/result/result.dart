import 'package:meta/meta.dart';

/// A class that represents a result of an operation that can either succeed with a value
/// of type [S] or fail with an error of type [F].
@immutable
class Result<S, F> {
  final S? _success;
  final F? _failure;
  final bool _isSuccess;

  /// Creates a success result with the given [value].
  const Result.success(S value)
      : _success = value,
        _failure = null,
        _isSuccess = true;
  
  /// Creates a failure result with the given [error].
  const Result.failure(F error)
      : _success = null,
        _failure = error,
        _isSuccess = false;
  
  /// Named constructor for creating a success result (alias for [Result.success]).
  /// This constructor is commonly used in functional programming.
  const Result.right(S value) : this.success(value);
  
  /// Named constructor for creating a failure result (alias for [Result.failure]).
  /// This constructor is commonly used in functional programming.
  const Result.left(F error) : this.failure(error);

  /// Returns whether this result is a success result.
  bool get isSuccess => _isSuccess;
  
  /// Returns whether this result is a failure result.
  bool get isFailure => !_isSuccess;
  
  /// Returns the success value if this result is a success result, otherwise throws.
  S get getSuccess {
    if (!isSuccess) {
      throw StateError('Cannot get success value from a failure result');
    }
    return _success as S;
  }
  
  /// Returns the failure value if this result is a failure result, otherwise throws.
  F get getFailure {
    if (!isFailure) {
      throw StateError('Cannot get failure value from a success result');
    }
    return _failure as F;
  }
  
  /// Maps the success value of this result using the given [mapper] function.
  /// If this result is a failure, returns a new result with the same failure.
  Result<T, F> map<T>(T Function(S) mapper) {
    if (isSuccess) {
      return Result.success(mapper(getSuccess));
    } else {
      return Result.failure(getFailure);
    }
  }
  
  /// Maps the failure value of this result using the given [mapper] function.
  /// If this result is a success, returns a new result with the same success.
  Result<S, E> mapFailure<E>(E Function(F) mapper) {
    if (isFailure) {
      return Result.failure(mapper(getFailure));
    } else {
      return Result.success(getSuccess);
    }
  }
  
  /// Performs [onSuccess] if this result is a success, or [onFailure] if it is a failure.
  void fold({
    required void Function(S) onSuccess,
    required void Function(F) onFailure,
  }) {
    if (isSuccess) {
      onSuccess(getSuccess);
    } else {
      onFailure(getFailure);
    }
  }
  
  /// Returns the success value or the result of calling [defaultValue] if this result is a failure.
  S getOrElse(S Function(F) defaultValue) {
    if (isSuccess) {
      return getSuccess;
    } else {
      return defaultValue(getFailure);
    }
  }
  
  /// Returns a new result by applying [f] to the success value of this result.
  /// If this result is a failure, returns a new result with the same failure.
  Result<T, F> flatMap<T>(Result<T, F> Function(S) f) {
    if (isSuccess) {
      return f(getSuccess);
    } else {
      return Result.failure(getFailure);
    }
  }
  
  @override
  String toString() {
    if (isSuccess) {
      return 'Success($getSuccess)';
    } else {
      return 'Failure($getFailure)';
    }
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Result<S, F> &&
        other.isSuccess == isSuccess &&
        (isSuccess ? other.getSuccess == getSuccess : other.getFailure == getFailure);
  }
  
  @override
  int get hashCode {
    if (isSuccess) {
      return getSuccess.hashCode ^ isSuccess.hashCode;
    } else {
      return getFailure.hashCode ^ isSuccess.hashCode;
    }
  }
} 