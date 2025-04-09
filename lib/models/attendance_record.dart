import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Defines the method used to verify attendance
enum VerificationMethod {
  /// Location based verification (user is physically at the event)
  location,
  
  /// Manually verified by organizer
  manual,
}

/// Represents a record of attendance for an event
class AttendanceRecord {
  /// The ID of the user who attended
  final String userId;
  
  /// When the user checked in
  final DateTime checkedInAt;
  
  /// Method used to verify attendance
  final VerificationMethod verificationMethod;
  
  /// Optional notes about attendance
  final String? notes;
  
  /// Additional data for the verification
  final Map<String, dynamic>? verificationData;

  /// Constructor
  AttendanceRecord({
    required this.userId,
    required this.checkedInAt,
    required this.verificationMethod,
    this.notes,
    this.verificationData,
  });

  /// Create from JSON
  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    // Parse verification method
    VerificationMethod method = VerificationMethod.manual;
    if (json['verificationMethod'] != null) {
      final methodStr = json['verificationMethod'].toString().toLowerCase();
      if (methodStr == 'location') {
        method = VerificationMethod.location;
      }
    }
    
    // Parse timestamp that could be Timestamp or String
    DateTime parseTimestamp(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          debugPrint('Error parsing timestamp: $e');
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return AttendanceRecord(
      userId: json['userId'] as String? ?? '',
      checkedInAt: parseTimestamp(json['checkedInAt']),
      verificationMethod: method,
      notes: json['notes'] as String?,
      verificationData: json['verificationData'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'checkedInAt': checkedInAt.toIso8601String(),
      'verificationMethod': verificationMethod.toString().split('.').last,
      'notes': notes,
      'verificationData': verificationData,
    };
  }

  /// Create a copy with updated fields
  AttendanceRecord copyWith({
    String? userId,
    DateTime? checkedInAt,
    VerificationMethod? verificationMethod,
    String? notes,
    Map<String, dynamic>? verificationData,
  }) {
    return AttendanceRecord(
      userId: userId ?? this.userId,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      verificationMethod: verificationMethod ?? this.verificationMethod,
      notes: notes ?? this.notes,
      verificationData: verificationData ?? this.verificationData,
    );
  }
} 