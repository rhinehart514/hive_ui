import 'package:cloud_firestore/cloud_firestore.dart';

/// The privacy setting for a space
enum SpacePrivacy {
  /// Visible to anyone, can be joined by anyone
  public,
  
  /// Visible to anyone, but requires approval to join
  restricted,
  
  /// Not visible in search, requires invitation to join
  private,
}

/// The type of space
enum SpaceType {
  /// A general community space
  community,
  
  /// A space for clubs and organizations
  club,
  
  /// A space for academic purposes
  academic,
  
  /// A space for events
  event,
  
  /// A space exclusive to HIVE
  hiveExclusive,
}

/// Represents a community space in the platform
class Space {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final String ownerId;
  final List<String> moderatorIds;
  final List<String> memberIds;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;
  final bool isVerified;
  
  const Space({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.ownerId,
    required this.moderatorIds,
    required this.memberIds,
    required this.createdAt,
    this.metadata,
    this.isVerified = false,
  });
  
  /// Create an empty space
  factory Space.empty() {
    return Space(
      id: '',
      name: '',
      description: '',
      ownerId: '',
      moderatorIds: const [],
      memberIds: const [],
      createdAt: DateTime.now(),
    );
  }
  
  /// Check if a user is a member of this space
  bool isMember(String userId) {
    return memberIds.contains(userId) || 
           moderatorIds.contains(userId) || 
           ownerId == userId;
  }
  
  /// Check if a user is a moderator of this space
  bool isModerator(String userId) {
    return moderatorIds.contains(userId) || ownerId == userId;
  }
  
  /// Check if a user is the owner of this space
  bool isOwner(String userId) {
    return ownerId == userId;
  }
  
  /// Create a copy of the space with updated fields
  Space copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? ownerId,
    List<String>? moderatorIds,
    List<String>? memberIds,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
    bool? isVerified,
  }) {
    return Space(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      ownerId: ownerId ?? this.ownerId,
      moderatorIds: moderatorIds ?? this.moderatorIds,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
      isVerified: isVerified ?? this.isVerified,
    );
  }
  
  /// Convert space to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'ownerId': ownerId,
      'moderatorIds': moderatorIds,
      'memberIds': memberIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'metadata': metadata,
      'isVerified': isVerified,
    };
  }
  
  /// Create space from JSON
  factory Space.fromJson(Map<String, dynamic> json) {
    return Space(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      ownerId: json['ownerId'],
      moderatorIds: List<String>.from(json['moderatorIds'] ?? []),
      memberIds: List<String>.from(json['memberIds'] ?? []),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      metadata: json['metadata'],
      isVerified: json['isVerified'] ?? false,
    );
  }
  
  /// Create space from Firestore document
  factory Space.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Space.fromJson({
      ...data,
      'id': doc.id,
    });
  }
} 