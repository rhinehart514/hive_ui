/// A user recommendation with scoring and reasons
class RecommendedUser {
  /// The user's unique identifier
  final String id;

  /// The user's display name
  final String name;

  /// The user's profile image URL
  final String? profileImage;

  /// The user's major or field of study
  final String? major;

  /// The user's academic year
  final String? year;

  /// The user's residence or location
  final String? residence;

  /// Reasons why this user is recommended
  final List<String> reasons;

  /// The recommendation score (higher is better)
  final double score;

  /// Constructor
  const RecommendedUser({
    required this.id,
    required this.name,
    this.profileImage,
    this.major,
    this.year,
    this.residence,
    required this.reasons,
    required this.score,
  });

  /// Create a RecommendedUser from a Firestore document
  factory RecommendedUser.fromFirestore(Map<String, dynamic> data, String id) {
    return RecommendedUser(
      id: id,
      name: data['displayName'] ?? 'Anonymous',
      profileImage: data['profileImageUrl'],
      major: data['major'],
      year: data['year'],
      residence: data['residence'],
      reasons: List<String>.from(data['reasons'] ?? []),
      score: (data['score'] ?? 0.0).toDouble(),
    );
  }

  /// Convert to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'displayName': name,
      'profileImageUrl': profileImage,
      'major': major,
      'year': year,
      'residence': residence,
      'reasons': reasons,
      'score': score,
    };
  }
} 