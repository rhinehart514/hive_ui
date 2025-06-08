import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ui/features/feed/data/models/content_category_model.dart';
import 'package:hive_ui/features/feed/domain/entities/content_category_entity.dart';
import 'package:hive_ui/features/feed/domain/repositories/content_categories_repository.dart';

/// Implementation of the ContentCategoriesRepository
class ContentCategoriesRepositoryImpl implements ContentCategoriesRepository {
  final FirebaseFirestore _firestore;

  ContentCategoriesRepositoryImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection reference for content categories
  CollectionReference<Map<String, dynamic>> get _categoriesCollection =>
      _firestore.collection('content_categories');

  @override
  Future<List<ContentCategoryEntity>> getCategories() async {
    try {
      final snapshot = await _categoriesCollection.orderBy('priority', descending: true).get();
      
      return snapshot.docs
          .map((doc) => ContentCategoryModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }

  @override
  Future<ContentCategoryEntity> getCategory(String id) async {
    try {
      final doc = await _categoriesCollection.doc(id).get();
      if (!doc.exists) {
        throw Exception('Category not found');
      }
      return ContentCategoryModel.fromFirestore(doc).toEntity();
    } catch (e) {
      throw Exception('Failed to get category: $e');
    }
  }

  @override
  Future<List<ContentCategoryEntity>> getDefaultCategories() async {
    try {
      final snapshot = await _categoriesCollection
          .where('isDefault', isEqualTo: true)
          .orderBy('priority', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => ContentCategoryModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Failed to get default categories: $e');
    }
  }

  @override
  Future<ContentCategoryEntity> createCategory(ContentCategoryEntity category) async {
    try {
      // Convert entity to model
      final model = ContentCategoryModel(
        id: category.id,
        name: category.name,
        description: category.description,
        color: category.color,
        icon: category.icon,
        priority: category.priority,
        isDefault: category.isDefault,
        isSystemCategory: category.isSystemCategory,
        metadata: category.metadata,
        createdAt: category.createdAt,
        updatedAt: category.updatedAt,
      );
      
      // If the category has an ID, use it, otherwise let Firestore generate one
      final docRef = category.id.isNotEmpty
          ? _categoriesCollection.doc(category.id)
          : _categoriesCollection.doc();
          
      await docRef.set(model.toJson());
      final doc = await docRef.get();
      
      return ContentCategoryModel.fromFirestore(doc).toEntity();
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  @override
  Future<void> updateCategory(String id, ContentCategoryEntity category) async {
    try {
      // Convert entity to model
      final model = ContentCategoryModel(
        id: category.id,
        name: category.name,
        description: category.description,
        color: category.color,
        icon: category.icon,
        priority: category.priority,
        isDefault: category.isDefault,
        isSystemCategory: category.isSystemCategory,
        metadata: category.metadata,
        createdAt: category.createdAt,
        updatedAt: DateTime.now(), // Update the timestamp
      );
      
      await _categoriesCollection.doc(id).update(model.toJson());
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      // Check if category is a system category
      final doc = await _categoriesCollection.doc(id).get();
      if (!doc.exists) {
        throw Exception('Category not found');
      }
      
      final data = doc.data();
      if (data != null && data['isSystemCategory'] == true) {
        throw Exception('Cannot delete system category');
      }
      
      await _categoriesCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  @override
  Stream<List<ContentCategoryEntity>> watchCategories() {
    return _categoriesCollection
        .orderBy('priority', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ContentCategoryModel.fromFirestore(doc).toEntity())
            .toList());
  }

  @override
  Stream<ContentCategoryEntity> watchCategory(String id) {
    return _categoriesCollection
        .doc(id)
        .snapshots()
        .map((doc) => ContentCategoryModel.fromFirestore(doc).toEntity());
  }

  @override
  Future<List<ContentCategoryEntity>> getCategoriesForContent(String contentId) async {
    try {
      // Get the content document
      final contentDoc = await _firestore.collection('content').doc(contentId).get();
      if (!contentDoc.exists) {
        throw Exception('Content not found');
      }
      
      final data = contentDoc.data();
      if (data == null) {
        return [];
      }
      
      // Get the category IDs
      final categoryIds = data['categoryIds'] as List<dynamic>? ?? [];
      if (categoryIds.isEmpty) {
        return [];
      }
      
      // Get all categories in a batch
      final categories = await Future.wait(
        categoryIds.map((id) => _categoriesCollection.doc(id.toString()).get()),
      );
      
      return categories
          .where((doc) => doc.exists)
          .map((doc) => ContentCategoryModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Failed to get categories for content: $e');
    }
  }

  @override
  Future<void> assignCategoryToContent(String contentId, String categoryId) async {
    try {
      await _firestore.collection('content').doc(contentId).update({
        'categoryIds': FieldValue.arrayUnion([categoryId]),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Failed to assign category to content: $e');
    }
  }

  @override
  Future<void> removeCategoryFromContent(String contentId, String categoryId) async {
    try {
      await _firestore.collection('content').doc(contentId).update({
        'categoryIds': FieldValue.arrayRemove([categoryId]),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Failed to remove category from content: $e');
    }
  }

  @override
  Future<void> ensureDefaultCategories() async {
    try {
      // Define default categories
      final defaultCategories = [
        ContentCategoryModel.eventsCategory(),
        ContentCategoryModel.announcementsCategory(),
        ContentCategoryModel.socialCategory(),
        ContentCategoryModel.academicCategory(),
      ];
      
      // Create a batch write
      final batch = _firestore.batch();
      
      // Add each default category if it doesn't exist
      for (final category in defaultCategories) {
        final docRef = _categoriesCollection.doc(category.id);
        final docSnapshot = await docRef.get();
        
        if (!docSnapshot.exists) {
          batch.set(docRef, category.toJson());
        }
      }
      
      // Commit the batch
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to ensure default categories: $e');
    }
  }
} 