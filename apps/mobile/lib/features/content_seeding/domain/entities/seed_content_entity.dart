import 'package:hive_ui/features/content_seeding/data/models/seed_content_model.dart';

/// Entity class for seed content
class SeedContentEntity {
  /// Unique identifier for this seed content
  final String id;
  
  /// Type of content
  final SeedContentType type;
  
  /// Content data to be seeded
  final Map<String, dynamic> data;
  
  /// Current status of the seeding operation
  final SeedingStatus status;
  
  /// Target environment(s) for this seed content
  final SeedingEnvironment environment;
  
  /// Whether this content should be seeded for all new users
  final bool seedForNewUsers;
  
  /// Whether this content should replace existing content with the same ID
  final bool replaceExisting;
  
  /// Priority of seeding (higher numbers are seeded first)
  final int priority;
  
  /// Dependencies - IDs of other seed content that must be seeded first
  final List<String> dependencies;
  
  /// Tags for categorizing and filtering seed content
  final List<String> tags;
  
  /// Additional metadata for the seed content
  final Map<String, dynamic> metadata;
  
  /// When this seed content was created
  final DateTime createdAt;
  
  /// When this seed content was last updated
  final DateTime updatedAt;
  
  /// Error message if seeding failed
  final String? errorMessage;
  
  /// Constructor
  const SeedContentEntity({
    required this.id,
    required this.type,
    required this.data,
    required this.status,
    required this.environment,
    required this.seedForNewUsers,
    required this.replaceExisting,
    required this.priority,
    required this.dependencies,
    required this.tags,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.errorMessage,
  });
  
  /// Check if this content has dependencies
  bool hasDependencies() => dependencies.isNotEmpty;
  
  /// Check if this content is targeted for a specific environment
  bool isTargetedForEnvironment(SeedingEnvironment targetEnv) {
    return environment == targetEnv || environment == SeedingEnvironment.all;
  }
  
  /// Check if this content is ready to be seeded
  bool isReadyToSeed() {
    return status == SeedingStatus.pending;
  }
  
  /// Check if this content is for new users only
  bool isForNewUsersOnly() {
    return seedForNewUsers && !replaceExisting;
  }
  
  /// Get a copy of this entity with updated properties
  SeedContentEntity copyWith({
    String? id,
    SeedContentType? type,
    Map<String, dynamic>? data,
    SeedingStatus? status,
    SeedingEnvironment? environment,
    bool? seedForNewUsers,
    bool? replaceExisting,
    int? priority,
    List<String>? dependencies,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? errorMessage,
  }) {
    return SeedContentEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      data: data ?? this.data,
      status: status ?? this.status,
      environment: environment ?? this.environment,
      seedForNewUsers: seedForNewUsers ?? this.seedForNewUsers,
      replaceExisting: replaceExisting ?? this.replaceExisting,
      priority: priority ?? this.priority,
      dependencies: dependencies ?? this.dependencies,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
} 