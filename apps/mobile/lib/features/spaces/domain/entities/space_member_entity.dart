import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Represents a member within a specific Space.
@immutable
class SpaceMemberEntity {
  /// The Firestore document ID (usually the same as userId).
  final String id;
  /// The ID of the user who is the member.
  final String userId;
  /// The role of the member within this specific space (e.g., 'member', 'admin').
  final String role;
  /// The display name of the member.
  final String? displayName;
  /// The timestamp when the user joined the space.
  final DateTime joinedAt;
  // Add other relevant member fields if needed, e.g., last_active, notification_prefs

  const SpaceMemberEntity({
    required this.id,
    required this.userId,
    required this.role,
    this.displayName,
    required this.joinedAt,
  });

  /// Creates an entity from a Firestore document snapshot.
  factory SpaceMemberEntity.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>? ?? {}; // Handle null data
    return SpaceMemberEntity(
      id: snapshot.id,
      userId: data['userId'] as String? ?? '', // Provide default value
      role: data['role'] as String? ?? 'member', // Default role if missing
      displayName: data['displayName'] as String?,
      joinedAt: (data['joinedAt'] as Timestamp? ?? Timestamp.now()).toDate(), // Default join time
    );
  }

  /// Creates an empty entity, useful for defaults or loading states.
  factory SpaceMemberEntity.empty() => SpaceMemberEntity(
        id: '',
        userId: '',
        role: 'member',
        displayName: null,
        joinedAt: DateTime(0), // Or DateTime.now() depending on use case
      );

  /// Converts the entity to a Map suitable for Firestore.
  Map<String, dynamic> toDocument() {
    return {
      'userId': userId,
      'role': role,
      'displayName': displayName,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpaceMemberEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          role == other.role &&
          displayName == other.displayName;

  @override
  int get hashCode => id.hashCode ^ userId.hashCode ^ role.hashCode ^ (displayName?.hashCode ?? 0);
} 