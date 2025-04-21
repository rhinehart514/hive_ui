/// Represents the details of a HIVE Space.
class SpaceDetails {
  final String id;
  final String name;
  final String? avatarUrl;
  final int memberCount;
  final String? description;
  final bool canCreateEvents; // Added based on design discussion

  const SpaceDetails({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.memberCount,
    this.description,
    this.canCreateEvents = false, // Default to false, fetch real permission
  });

  // Optional: Add copyWith, toJson, fromJson if needed
} 