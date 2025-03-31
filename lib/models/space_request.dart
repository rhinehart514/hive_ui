import 'package:flutter/foundation.dart';
import 'package:hive_ui/models/space.dart';

/// Status of a space request
enum SpaceRequestStatus {
  pending,
  approved,
  rejected,
  cancelled,
}

/// Model representing a request to join a space or an invitation to a space
@immutable
class SpaceRequest {
  final String id;
  final String spaceId;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String? message;
  final DateTime createdAt;
  final SpaceRequestStatus status;
  final bool
      isInvitation; // If true, this is an invitation, otherwise it's a request to join
  final Space? space; // The related space if available

  const SpaceRequest({
    required this.id,
    required this.spaceId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    this.message,
    required this.createdAt,
    required this.status,
    this.isInvitation = false,
    this.space,
  });

  /// Creates a copy of this SpaceRequest with the given fields replaced
  SpaceRequest copyWith({
    String? id,
    String? spaceId,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    String? message,
    DateTime? createdAt,
    SpaceRequestStatus? status,
    bool? isInvitation,
    Space? space,
  }) {
    return SpaceRequest(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      isInvitation: isInvitation ?? this.isInvitation,
      space: space ?? this.space,
    );
  }
}
