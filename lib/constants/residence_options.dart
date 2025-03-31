import 'package:flutter/foundation.dart';

/// Provides a consistent list of residence options used throughout the app
@immutable
class ResidenceOptions {
  /// A comprehensive list of residence options users can select
  static const List<String> options = [
    'Ellicott',
    'Governors',
    'Greiner',
    'On Campus Apartments',
    'Commuter',
  ];

  /// Private constructor to prevent instantiation
  const ResidenceOptions._();
}
