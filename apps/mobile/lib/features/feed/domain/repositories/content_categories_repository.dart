import 'package:hive_ui/features/feed/domain/entities/content_category_entity.dart';

/// Repository interface for managing content categories
abstract class ContentCategoriesRepository {
  /// Get all categories
  Future<List<ContentCategoryEntity>> getCategories();

  /// Get a single category by ID
  Future<ContentCategoryEntity> getCategory(String id);

  /// Get default categories
  Future<List<ContentCategoryEntity>> getDefaultCategories();

  /// Create a new category
  Future<ContentCategoryEntity> createCategory(ContentCategoryEntity category);

  /// Update an existing category
  Future<void> updateCategory(String id, ContentCategoryEntity category);

  /// Delete a category
  Future<void> deleteCategory(String id);

  /// Watch all categories (stream)
  Stream<List<ContentCategoryEntity>> watchCategories();

  /// Watch a specific category (stream)
  Stream<ContentCategoryEntity> watchCategory(String id);

  /// Get categories for a specific content item
  Future<List<ContentCategoryEntity>> getCategoriesForContent(String contentId);

  /// Assign a category to a content item
  Future<void> assignCategoryToContent(String contentId, String categoryId);

  /// Remove a category from a content item
  Future<void> removeCategoryFromContent(String contentId, String categoryId);

  /// Ensure default categories exist
  Future<void> ensureDefaultCategories();
} 