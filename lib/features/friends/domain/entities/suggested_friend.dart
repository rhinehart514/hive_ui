import 'package:hive_ui/models/friend.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum defining the various criteria used to match suggested friends
enum MatchCriteria {
  /// Matched based on shared interests
  interest,
  
  /// Matched based on education/major
  major,
  
  /// Matched based on location/residence
  residence,
}

/// Entity representing a suggested friend to connect with
class SuggestedFriend {
  /// Unique identifier for the suggested friend
  final String id;
  
  /// Display name of the suggested friend
  final String name;
  
  /// URL to the suggested friend's profile image (optional)
  final String? profileImage;
  
  /// The criteria used to match this suggestion
  final MatchCriteria matchCriteria;
  
  /// The specific value that matched (e.g., interest name, major name)
  final String matchValue;
  
  /// User status message or brief description
  final String status;
  
  /// Whether a friend request has already been sent to this user
  final bool isRequestSent;
  
  /// Whether this user is already a friend
  final bool isAlreadyFriend;
  
  /// Last active time of the user
  final DateTime? lastActive;

  /// Constructor
  const SuggestedFriend({
    required this.id,
    required this.name,
    this.profileImage,
    required this.matchCriteria,
    required this.matchValue,
    this.status = '',
    this.isRequestSent = false,
    this.isAlreadyFriend = false,
    this.lastActive,
  });
  
  /// Create a SuggestedFriend from a Friend model
  factory SuggestedFriend.fromFriend(
    Friend friend,
    MatchCriteria matchCriteria,
    String matchValue,
  ) {
    return SuggestedFriend(
      id: friend.id,
      name: friend.name,
      profileImage: friend.imageUrl,
      matchCriteria: matchCriteria,
      matchValue: matchValue,
      status: friend.status,
      isRequestSent: false,
      isAlreadyFriend: false,
      lastActive: friend.lastActive,
    );
  }
  
  /// Create a SuggestedFriend from Firestore document
  factory SuggestedFriend.fromFirestore(
    DocumentSnapshot doc,
    MatchCriteria matchCriteria,
    String matchValue,
    bool isRequestSent,
    bool isAlreadyFriend,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    
    return SuggestedFriend(
      id: doc.id,
      name: data['username'] ?? data['name'] ?? 'Unknown User',
      profileImage: data['profileImageUrl'] ?? data['imageUrl'],
      matchCriteria: matchCriteria,
      matchValue: matchValue,
      status: data['major'] != null && data['year'] != null
        ? '${data['major']} • ${data['year']}'
        : '',
      isRequestSent: isRequestSent,
      isAlreadyFriend: isAlreadyFriend,
      lastActive: data['lastActive'] != null
        ? (data['lastActive'] as Timestamp).toDate()
        : null,
    );
  }
  
  /// Create a copy of this SuggestedFriend with specified changes
  SuggestedFriend copyWith({
    String? id,
    String? name,
    String? profileImage,
    MatchCriteria? matchCriteria,
    String? matchValue,
    String? status,
    bool? isRequestSent,
    bool? isAlreadyFriend,
    DateTime? lastActive,
  }) {
    return SuggestedFriend(
      id: id ?? this.id,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      matchCriteria: matchCriteria ?? this.matchCriteria,
      matchValue: matchValue ?? this.matchValue,
      status: status ?? this.status,
      isRequestSent: isRequestSent ?? this.isRequestSent,
      isAlreadyFriend: isAlreadyFriend ?? this.isAlreadyFriend,
      lastActive: lastActive ?? this.lastActive,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is SuggestedFriend &&
        other.id == id &&
        other.name == name &&
        other.profileImage == profileImage &&
        other.matchCriteria == matchCriteria &&
        other.matchValue == matchValue &&
        other.status == status &&
        other.isRequestSent == isRequestSent &&
        other.isAlreadyFriend == isAlreadyFriend &&
        other.lastActive == lastActive;
  }
  
  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      profileImage,
      matchCriteria,
      matchValue,
      status,
      isRequestSent,
      isAlreadyFriend,
      lastActive,
    );
  }
  
  /// Legacy support for imageUrl accessor
  String? get imageUrl => profileImage;
} 