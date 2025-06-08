import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ui/features/content_seeding/domain/entities/seed_content_entity.dart';

/// Types of content that can be seeded
enum SeedContentType {
  /// Post type content
  post,
  
  /// Event type content
  event,
  
  /// Space type content
  space,
  
  /// Announcement type content
  announcement,
  
  /// Profile type content
  profile,
}

/// Status of a seeding operation
enum SeedingStatus {
  /// Content is pending to be seeded
  pending,
  
  /// Content is currently being seeded
  inProgress,
  
  /// Content was successfully seeded
  completed,
  
  /// Seeding operation failed
  failed,
  
  /// Seeding operation was skipped (e.g., content already exists)
  skipped,
}

/// Target environment for seeded content
enum SeedingEnvironment {
  /// Content for development environment
  development,
  
  /// Content for testing environment
  testing,
  
  /// Content for production environment
  production,
  
  /// Content for all environments
  all,
}

/// Model representing content to be seeded into the app
class SeedContentModel {
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
  const SeedContentModel({
    required this.id,
    required this.type,
    required this.data,
    this.status = SeedingStatus.pending,
    this.environment = SeedingEnvironment.all,
    this.seedForNewUsers = true,
    this.replaceExisting = false,
    this.priority = 0,
    this.dependencies = const [],
    this.tags = const [],
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
    this.errorMessage,
  });
  
  /// Convert model to entity
  SeedContentEntity toEntity() {
    return SeedContentEntity(
      id: id,
      type: type,
      data: data,
      status: status,
      environment: environment,
      seedForNewUsers: seedForNewUsers,
      replaceExisting: replaceExisting,
      priority: priority,
      dependencies: dependencies,
      tags: tags,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
      errorMessage: errorMessage,
    );
  }
  
  /// Create model from entity
  factory SeedContentModel.fromEntity(SeedContentEntity entity) {
    return SeedContentModel(
      id: entity.id,
      type: entity.type,
      data: entity.data,
      status: entity.status,
      environment: entity.environment,
      seedForNewUsers: entity.seedForNewUsers,
      replaceExisting: entity.replaceExisting,
      priority: entity.priority,
      dependencies: entity.dependencies,
      tags: entity.tags,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      errorMessage: entity.errorMessage,
    );
  }
  
  /// Create model from Firestore document
  factory SeedContentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return SeedContentModel(
      id: doc.id,
      type: SeedContentType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => SeedContentType.post,
      ),
      data: data['content'] as Map<String, dynamic>,
      status: SeedingStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => SeedingStatus.pending,
      ),
      environment: SeedingEnvironment.values.firstWhere(
        (e) => e.toString().split('.').last == data['environment'],
        orElse: () => SeedingEnvironment.all,
      ),
      seedForNewUsers: data['seedForNewUsers'] as bool? ?? true,
      replaceExisting: data['replaceExisting'] as bool? ?? false,
      priority: data['priority'] as int? ?? 0,
      dependencies: List<String>.from(data['dependencies'] as List? ?? []),
      tags: List<String>.from(data['tags'] as List? ?? []),
      metadata: data['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      errorMessage: data['errorMessage'] as String?,
    );
  }
  
  /// Convert model to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'type': type.toString().split('.').last,
      'content': data,
      'status': status.toString().split('.').last,
      'environment': environment.toString().split('.').last,
      'seedForNewUsers': seedForNewUsers,
      'replaceExisting': replaceExisting,
      'priority': priority,
      'dependencies': dependencies,
      'tags': tags,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'errorMessage': errorMessage,
    };
  }
  
  /// Create a copy of this model with updated properties
  SeedContentModel copyWith({
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
    return SeedContentModel(
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
  
  /// Create a default space seed content
  static SeedContentModel createDefaultSpace({
    required String id,
    required String name,
    required String description,
    String? imageUrl,
    List<String> tags = const [],
  }) {
    final now = DateTime.now();
    
    return SeedContentModel(
      id: id,
      type: SeedContentType.space,
      data: {
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'isPublic': true,
        'isOfficial': true,
        'members': [],
        'tags': tags,
      },
      status: SeedingStatus.pending,
      environment: SeedingEnvironment.all,
      seedForNewUsers: true,
      priority: 10, // High priority for spaces
      tags: ['default', 'space', ...tags],
      createdAt: now,
      updatedAt: now,
    );
  }
  
  /// Create a default event seed content
  static SeedContentModel createDefaultEvent({
    required String id,
    required String title,
    required String description,
    required DateTime startTime,
    DateTime? endTime,
    String? imageUrl,
    String? spaceId,
    List<String> tags = const [],
  }) {
    final now = DateTime.now();
    
    return SeedContentModel(
      id: id,
      type: SeedContentType.event,
      data: {
        'title': title,
        'description': description,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': endTime != null ? Timestamp.fromDate(endTime) : null,
        'imageUrl': imageUrl,
        'spaceId': spaceId,
        'isPublic': true,
        'isOfficial': true,
        'attendees': [],
        'tags': tags,
      },
      status: SeedingStatus.pending,
      environment: SeedingEnvironment.all,
      seedForNewUsers: true,
      priority: 5, // Medium priority for events
      dependencies: spaceId != null ? [spaceId] : [],
      tags: ['default', 'event', ...tags],
      createdAt: now,
      updatedAt: now,
    );
  }
  
  /// Create a default post seed content
  static SeedContentModel createDefaultPost({
    required String id,
    required String content,
    String? imageUrl,
    String? authorId,
    String? spaceId,
    List<String> tags = const [],
  }) {
    final now = DateTime.now();
    
    return SeedContentModel(
      id: id,
      type: SeedContentType.post,
      data: {
        'content': content,
        'imageUrl': imageUrl,
        'authorId': authorId,
        'spaceId': spaceId,
        'likes': 0,
        'comments': 0,
        'isPublic': true,
        'tags': tags,
      },
      status: SeedingStatus.pending,
      environment: SeedingEnvironment.all,
      seedForNewUsers: true,
      priority: 3, // Lower priority for posts
      dependencies: [
        if (spaceId != null) spaceId,
        if (authorId != null) authorId,
      ],
      tags: ['default', 'post', ...tags],
      createdAt: now,
      updatedAt: now,
    );
  }
} 