import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model for user restrictions in the moderation system
class UserRestrictionModel {
  /// Unique identifier for the restriction record
  final String id;
  
  /// ID of the restricted user
  final String userId;
  
  /// Whether the user is currently restricted
  final bool isActive;
  
  /// Reason for the restriction
  final String reason;
  
  /// ID of the moderator who applied the restriction
  final String restrictedBy;
  
  /// When the restriction was created
  final DateTime createdAt;
  
  /// When the restriction will end (null for permanent restrictions)
  final DateTime? expiresAt;
  
  /// Additional notes or context about the restriction
  final String? notes;
  
  /// History of previous restrictions for this user
  final List<PreviousRestrictionModel>? restrictionHistory;
  
  /// Constructor
  UserRestrictionModel({
    required this.id,
    required this.userId,
    required this.isActive,
    required this.reason,
    required this.restrictedBy,
    required this.createdAt,
    this.expiresAt,
    this.notes,
    this.restrictionHistory,
  });
  
  /// Create a model from Firestore data
  factory UserRestrictionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse previous restrictions
    List<PreviousRestrictionModel>? restrictionHistory;
    if (data['restrictionHistory'] != null) {
      restrictionHistory = (data['restrictionHistory'] as List)
          .map((item) => PreviousRestrictionModel.fromMap(item as Map<String, dynamic>))
          .toList();
    }
    
    return UserRestrictionModel(
      id: doc.id,
      userId: data['userId'] as String,
      isActive: data['isActive'] as bool,
      reason: data['reason'] as String,
      restrictedBy: data['restrictedBy'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: data['expiresAt'] != null 
          ? (data['expiresAt'] as Timestamp).toDate() 
          : null,
      notes: data['notes'] as String?,
      restrictionHistory: restrictionHistory,
    );
  }
  
  /// Convert model to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'isActive': isActive,
      'reason': reason,
      'restrictedBy': restrictedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'notes': notes,
      'restrictionHistory': restrictionHistory?.map((item) => item.toMap()).toList(),
    };
  }
}

/// Model class to represent previous restrictions in the user history
class PreviousRestrictionModel {
  /// When the restriction was created
  final DateTime createdAt;
  
  /// When the restriction ended (if applicable)
  final DateTime? endedAt;
  
  /// Reason for the restriction
  final String reason;
  
  /// ID of the moderator who applied the restriction
  final String restrictedBy;
  
  /// ID of the moderator who removed the restriction (if applicable)
  final String? removedBy;
  
  /// Reason for removing the restriction (if applicable)
  final String? removalReason;
  
  /// Constructor
  PreviousRestrictionModel({
    required this.createdAt,
    this.endedAt,
    required this.reason,
    required this.restrictedBy,
    this.removedBy,
    this.removalReason,
  });
  
  /// Create a model from a map
  factory PreviousRestrictionModel.fromMap(Map<String, dynamic> map) {
    return PreviousRestrictionModel(
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      endedAt: map['endedAt'] != null ? (map['endedAt'] as Timestamp).toDate() : null,
      reason: map['reason'] as String,
      restrictedBy: map['restrictedBy'] as String,
      removedBy: map['removedBy'] as String?,
      removalReason: map['removalReason'] as String?,
    );
  }
  
  /// Convert model to a map
  Map<String, dynamic> toMap() {
    return {
      'createdAt': Timestamp.fromDate(createdAt),
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      'reason': reason,
      'restrictedBy': restrictedBy,
      'removedBy': removedBy,
      'removalReason': removalReason,
    };
  }
} 