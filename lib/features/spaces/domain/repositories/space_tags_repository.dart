import 'package:flutter/material.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_tag_entity.dart';

/// Repository interface for managing space tags
abstract class SpaceTagsRepository {
  /// Get all tags
  Future<List<SpaceTagEntity>> getTags();

  /// Get tags by category
  Future<List<SpaceTagEntity>> getTagsByCategory(TagCategory category);

  /// Get a single tag by ID
  Future<SpaceTagEntity> getTag(String id);

  /// Get tags for a specific space
  Future<List<SpaceTagEntity>> getTagsForSpace(String spaceId);

  /// Create a new tag
  Future<SpaceTagEntity> createTag(
    String name,
    String description,
    TagCategory category, {
    Color color = Colors.blue,
    bool isOfficial = false,
    bool isFilterable = true,
    bool isSearchable = true,
    bool isExclusive = false,
    Map<String, dynamic> metadata = const {},
  });

  /// Update an existing tag
  Future<void> updateTag(
    String id, {
    String? name,
    String? description,
    Color? color,
    TagCategory? category,
    bool? isOfficial,
    bool? isFilterable,
    bool? isSearchable,
    bool? isExclusive,
    Map<String, dynamic>? metadata,
  });

  /// Delete a tag
  Future<void> deleteTag(String id);

  /// Increment usage count for a tag
  Future<void> incrementTagUsage(String id);

  /// Decrement usage count for a tag
  Future<void> decrementTagUsage(String id);

  /// Add a tag to a space
  Future<void> addTagToSpace(String spaceId, String tagId);

  /// Remove a tag from a space
  Future<void> removeTagFromSpace(String spaceId, String tagId);

  /// Watch all tags (stream)
  Stream<List<SpaceTagEntity>> watchTags();

  /// Watch tags by category (stream)
  Stream<List<SpaceTagEntity>> watchTagsByCategory(TagCategory category);

  /// Watch a specific tag (stream)
  Stream<SpaceTagEntity> watchTag(String id);

  /// Watch tags for a specific space (stream)
  Stream<List<SpaceTagEntity>> watchTagsForSpace(String spaceId);

  /// Search for tags by query string
  Future<List<SpaceTagEntity>> searchTags(String query);

  /// Get the most frequently used tags
  Future<List<SpaceTagEntity>> getMostUsedTags({int limit = 10});
} 