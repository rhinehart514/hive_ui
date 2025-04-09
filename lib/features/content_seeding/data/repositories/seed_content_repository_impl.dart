import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/features/content_seeding/data/models/seed_content_model.dart';
import 'package:hive_ui/features/content_seeding/domain/entities/seed_content_entity.dart';
import 'package:hive_ui/features/content_seeding/domain/repositories/seed_content_repository.dart';

/// Implementation of [SeedContentRepository]
class SeedContentRepositoryImpl implements SeedContentRepository {
  final FirebaseFirestore _firestore;
  
  /// Collection name for seed content
  static const String _collection = 'seed_content';
  
  /// Constructor
  SeedContentRepositoryImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;
  
  @override
  Future<List<SeedContentEntity>> getAllSeedContent() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('priority', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => SeedContentModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      debugPrint('Error getting seed content: $e');
      return [];
    }
  }
  
  @override
  Future<List<SeedContentEntity>> getSeedContentForEnvironment(
    SeedingEnvironment environment, {
    bool forNewUsersOnly = false,
  }) async {
    try {
      // Start with base query
      Query<Map<String, dynamic>> query = _firestore.collection(_collection);
      
      // Filter by environment (or 'all')
      query = query.where('environment', whereIn: [
        environment.toString().split('.').last,
        SeedingEnvironment.all.toString().split('.').last,
      ]);
      
      // Filter for new user content if requested
      if (forNewUsersOnly) {
        query = query.where('seedForNewUsers', isEqualTo: true);
      }
      
      // Order by priority
      query = query.orderBy('priority', descending: true);
      
      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => SeedContentModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      debugPrint('Error getting seed content for environment $environment: $e');
      return [];
    }
  }
  
  @override
  Future<SeedContentEntity?> getSeedContentById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      
      if (!doc.exists) {
        return null;
      }
      
      return SeedContentModel.fromFirestore(doc).toEntity();
    } catch (e) {
      debugPrint('Error getting seed content by ID $id: $e');
      return null;
    }
  }
  
  @override
  Future<List<SeedContentEntity>> getSeedContentByType(SeedContentType type) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('type', isEqualTo: type.toString().split('.').last)
          .orderBy('priority', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => SeedContentModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      debugPrint('Error getting seed content by type $type: $e');
      return [];
    }
  }
  
  @override
  Future<List<SeedContentEntity>> getSeedContentByTags(List<String> tags) async {
    try {
      // Firestore doesn't support direct OR queries across array contains
      // So we need to split into multiple queries and combine the results
      final List<SeedContentEntity> results = [];
      
      for (final tag in tags) {
        final snapshot = await _firestore
            .collection(_collection)
            .where('tags', arrayContains: tag)
            .get();
        
        final entities = snapshot.docs
            .map((doc) => SeedContentModel.fromFirestore(doc).toEntity())
            .toList();
        
        // Add only unique entities
        for (final entity in entities) {
          if (!results.any((e) => e.id == entity.id)) {
            results.add(entity);
          }
        }
      }
      
      // Sort by priority
      results.sort((a, b) => b.priority.compareTo(a.priority));
      return results;
    } catch (e) {
      debugPrint('Error getting seed content by tags $tags: $e');
      return [];
    }
  }
  
  @override
  Future<bool> createSeedContent(SeedContentEntity content) async {
    try {
      final model = SeedContentModel.fromEntity(content);
      
      await _firestore
          .collection(_collection)
          .doc(content.id)
          .set(model.toFirestore());
      
      return true;
    } catch (e) {
      debugPrint('Error creating seed content: $e');
      return false;
    }
  }
  
  @override
  Future<bool> updateSeedContentStatus(
    String id, 
    SeedingStatus status, {
    String? errorMessage,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (errorMessage != null) {
        updates['errorMessage'] = errorMessage;
      }
      
      await _firestore
          .collection(_collection)
          .doc(id)
          .update(updates);
      
      return true;
    } catch (e) {
      debugPrint('Error updating seed content status: $e');
      return false;
    }
  }
  
  @override
  Future<bool> deleteSeedContent(String id) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(id)
          .delete();
      
      return true;
    } catch (e) {
      debugPrint('Error deleting seed content: $e');
      return false;
    }
  }
  
  @override
  Future<bool> seedContentExists(String id) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(id)
          .get();
      
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking if seed content exists: $e');
      return false;
    }
  }
  
  @override
  Future<int> getCompletedSeedCount() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: SeedingStatus.completed.toString().split('.').last)
          .count()
          .get();
      
      // Ensure non-null return value
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Error getting completed seed count: $e');
      return 0;
    }
  }
  
  @override
  Future<Map<SeedingStatus, int>> getSeedStatusCounts() async {
    try {
      final result = <SeedingStatus, int>{};
      
      // Initialize all statuses with zero count
      for (final status in SeedingStatus.values) {
        result[status] = 0;
      }
      
      // Get the counts for each status
      final snapshot = await _firestore
          .collection(_collection)
          .get();
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final statusStr = data['status'] as String?;
        
        if (statusStr != null) {
          try {
            final status = SeedingStatus.values.firstWhere(
              (s) => s.toString().split('.').last == statusStr,
            );
            result[status] = (result[status] ?? 0) + 1;
          } catch (_) {
            // Ignore invalid status values
          }
        }
      }
      
      return result;
    } catch (e) {
      debugPrint('Error getting seed status counts: $e');
      return {};
    }
  }
  
  @override
  Stream<List<SeedContentEntity>> watchSeedContent() {
    try {
      return _firestore
          .collection(_collection)
          .orderBy('priority', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => SeedContentModel.fromFirestore(doc).toEntity())
              .toList());
    } catch (e) {
      debugPrint('Error watching seed content: $e');
      return Stream.value([]);
    }
  }
} 