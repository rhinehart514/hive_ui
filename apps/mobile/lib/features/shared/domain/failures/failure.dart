/// Generic abstract failure class that all domain-specific failures should extend
abstract class Failure implements Exception {
  /// Human-readable error message suitable for display to users
  String get message;
  
  /// Technical error reason for logging purposes
  String get reason;
  
  /// String representation of the failure (defaults to reason)
  @override
  String toString() => reason;
}

/// Either type that can represent either a left value (typically a Failure)
/// or a right value (typically a success result)
class Either<L, R> {
  final L? _left;
  final R? _right;
  final bool _isLeft;
  
  /// Private constructor for left value
  const Either._left(this._left)
      : _right = null,
        _isLeft = true;
  
  /// Private constructor for right value
  const Either._right(this._right)
      : _left = null,
        _isLeft = false;
  
  /// Factory constructor for left value
  factory Either.left(L value) => Either._left(value);
  
  /// Factory constructor for right value
  factory Either.right(R value) => Either._right(value);
  
  /// Returns whether this is a left value
  bool get isLeft => _isLeft;
  
  /// Returns whether this is a right value
  bool get isRight => !_isLeft;
  
  /// Gets the left value
  /// 
  /// Throws if this is a right value
  L get left {
    if (isLeft) return _left as L;
    throw Exception('Tried to get left value from a right Either');
  }
  
  /// Gets the right value
  /// 
  /// Throws if this is a left value
  R get right {
    if (isRight) return _right as R;
    throw Exception('Tried to get right value from a left Either');
  }
  
  /// Folds both possible values into a single result
  T fold<T>(T Function(L left) leftFn, T Function(R right) rightFn) {
    return isLeft ? leftFn(left) : rightFn(right);
  }
  
  /// Maps the right value using the given function
  Either<L, T> map<T>(T Function(R right) f) {
    return isLeft ? Either<L, T>.left(left) : Either<L, T>.right(f(right));
  }
  
  /// Maps the left value using the given function
  Either<T, R> mapLeft<T>(T Function(L left) f) {
    return isLeft ? Either<T, R>.left(f(left)) : Either<T, R>.right(right);
  }
  
  /// Transforms the Either using the given function if it's a right value
  Either<L, T> flatMap<T>(Either<L, T> Function(R right) f) {
    return isLeft ? Either<L, T>.left(left) : f(right);
  }
  
  /// Returns the right value or the result of calling the function with the left value
  R getOrElse(R Function(L left) orElse) {
    return isLeft ? orElse(left) : right;
  }
} 