import 'package:flutter/material.dart';

/// The type of space, used for categorization
enum SpaceType {
  studentOrg,
  universityOrg,
  campusLiving,
  fraternityAndSorority,
  other,
}

/// Extension on SpaceType to provide human-readable names and icons
extension SpaceTypeExtension on SpaceType {
  /// Get the display name for this space type
  String get displayName {
    switch (this) {
      case SpaceType.studentOrg:
        return 'Student Organization';
      case SpaceType.universityOrg:
        return 'University Organization';
      case SpaceType.campusLiving:
        return 'Campus Living';
      case SpaceType.fraternityAndSorority:
        return 'Fraternity & Sorority';
      case SpaceType.other:
        return 'Other';
    }
  }

  /// Get appropriate icon for this space type
  IconData get icon {
    switch (this) {
      case SpaceType.studentOrg:
        return Icons.people;
      case SpaceType.universityOrg:
        return Icons.account_balance;
      case SpaceType.campusLiving:
        return Icons.home;
      case SpaceType.fraternityAndSorority:
        return Icons.groups;
      case SpaceType.other:
        return Icons.category;
    }
  }

  /// Convert to string for storage in Firestore
  String toFirestoreValue() {
    return toString().split('.').last;
  }

  /// Create a SpaceType from a Firestore string value
  static SpaceType fromFirestoreValue(String? value) {
    if (value == null) return SpaceType.other;

    switch (value) {
      case 'studentOrg':
        return SpaceType.studentOrg;
      case 'universityOrg':
        return SpaceType.universityOrg;
      case 'campusLiving':
        return SpaceType.campusLiving;
      case 'fraternityAndSorority':
        return SpaceType.fraternityAndSorority;
      default:
        return SpaceType.other;
    }
  }
}
