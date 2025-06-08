import 'package:hive_ui/features/content_seeding/data/models/seed_content_model.dart';
import 'package:hive_ui/features/content_seeding/domain/entities/seed_content_entity.dart';

/// Repository interface for seed content operations
abstract class SeedContentRepository {
  /// Get all seed content
  Future<List<SeedContentEntity>> getAllSeedContent();
  
  /// Get seed content for a specific environment
  /// 
  /// [environment] - The target environment to filter by
  /// [forNewUsersOnly] - Whether to only include content for new users
  Future<List<SeedContentEntity>> getSeedContentForEnvironment(
    SeedingEnvironment environment, {
    bool forNewUsersOnly = false,
  });
  
  /// Get seed content by ID
  /// 
  /// [id] - The unique identifier of the seed content
  Future<SeedContentEntity?> getSeedContentById(String id);
  
  /// Get seed content by type
  /// 
  /// [type] - The type of content to filter by
  Future<List<SeedContentEntity>> getSeedContentByType(SeedContentType type);
  
  /// Get seed content by tags
  /// 
  /// [tags] - The list of tags to filter by (matches content with ANY of the tags)
  Future<List<SeedContentEntity>> getSeedContentByTags(List<String> tags);
  
  /// Create new seed content
  /// 
  /// [content] - The seed content entity to create
  /// Returns true if successful
  Future<bool> createSeedContent(SeedContentEntity content);
  
  /// Update the status of seed content
  /// 
  /// [id] - The unique identifier of the seed content
  /// [status] - The new status to set
  /// [errorMessage] - Optional error message in case of failure
  /// Returns true if successful
  Future<bool> updateSeedContentStatus(
    String id, 
    SeedingStatus status, {
    String? errorMessage,
  });
  
  /// Delete seed content
  /// 
  /// [id] - The unique identifier of the seed content to delete
  /// Returns true if successful
  Future<bool> deleteSeedContent(String id);
  
  /// Check if seed content exists
  /// 
  /// [id] - The unique identifier of the seed content to check
  Future<bool> seedContentExists(String id);
  
  /// Get count of completed seed content
  Future<int> getCompletedSeedCount();
  
  /// Get counts for each seeding status
  Future<Map<SeedingStatus, int>> getSeedStatusCounts();
  
  /// Watch for changes to seed content
  Stream<List<SeedContentEntity>> watchSeedContent();
} 