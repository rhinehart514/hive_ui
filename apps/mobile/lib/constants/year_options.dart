import 'package:flutter/foundation.dart';

/// Provides a consistent list of year options used throughout the app
@immutable
class YearOptions {
  /// A comprehensive list of year options users can select
  static const List<String> options = [
    'Freshman',
    'Sophomore',
    'Junior',
    'Senior',
    'Masters',
    'PhD',
    'Non-Degree Seeking',
  ];

  /// Private constructor to prevent instantiation
  const YearOptions._();
}
