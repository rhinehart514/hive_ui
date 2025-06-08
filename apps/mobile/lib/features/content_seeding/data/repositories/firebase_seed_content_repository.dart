import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/core/error/app_error_handler.dart';
import 'package:hive_ui/features/content_seeding/data/models/seed_content_model.dart';
import 'package:hive_ui/features/content_seeding/domain/entities/seed_content_entity.dart';
import 'package:hive_ui/features/content_seeding/domain/repositories/seed_content_repository.dart';

/// Firebase implementation of the [SeedContentRepository]
class FirebaseSeedContentRepository implements SeedContentRepository {
  final FirebaseFirestore _firestore;
  final CollectionReference _collection;
  
  /// Constructor
  FirebaseSeedContentRepository({
    FirebaseFirestore? firestore,
  }) : 
    _firestore = firestore ?? FirebaseFirestore.instance,
    _collection = (firestore ?? FirebaseFirestore.instance).collection('seed_content');
  
  @override
  Future<List<SeedContentEntity>> getAllSeedContent() async {
    try {
      final snapshot = await _collection.orderBy('priority', descending: true).get();
      return snapshot.docs
          .map((doc) => SeedContentModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      debugPrint('Error getting all seed content: $e');
      throw UnexpectedFailure(
        technicalMessage: 'Failed to get seed content: ${e.toString()}',
        exception: e,
      );
    }
  }
  
  @override
  Future<List<SeedContentEntity>> getSeedContentForEnvironment(
    SeedingEnvironment environment, {
    bool forNewUsersOnly = false,
  }) async {
    try {
      Query query = _collection
          .where('environment', whereIn: [
            environment.toString().split('.').last,
            SeedingEnvironment.all.toString().split('.').last,
          ])
          .orderBy('priority', descending: true);
      
      if (forNewUsersOnly) {
        query = query.where('seedForNewUsers', isEqualTo: true);
      }
      
      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => SeedContentModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      debugPrint('Error getting seed content for environment: $e');
      throw UnexpectedFailure(
        technicalMessage: 'Failed to get seed content for environment: ${e.toString()}',
        exception: e,
      );
    }
  }
  
  @override
  Future<SeedContentEntity?> getSeedContentById(String id) async {
    try {
      final docSnapshot = await _collection.doc(id).get();
      
      if (!docSnapshot.exists) {
        return null;
      }
      
      return SeedContentModel.fromFirestore(docSnapshot).toEntity();
    } catch (e) {
      debugPrint('Error getting seed content by ID: $e');
      throw UnexpectedFailure(
        technicalMessage: 'Failed to get seed content by ID: ${e.toString()}',
        exception: e,
      );
    }
  }
  
  @override
  Future<List<SeedContentEntity>> getSeedContentByType(SeedContentType type) async {
    try {
      final snapshot = await _collection
          .where('type', isEqualTo: type.toString().split('.').last)
          .orderBy('priority', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => SeedContentModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      debugPrint('Error getting seed content by type: $e');
      throw UnexpectedFailure(
        technicalMessage: 'Failed to get seed content by type: ${e.toString()}',
        exception: e,
      );
    }
  }
  
  @override
  Future<List<SeedContentEntity>> getSeedContentByTags(List<String> tags) async {
    try {
      // Firestore can't filter arrays with OR logic, so we need to do it client-side
      final snapshot = await _collection
          .orderBy('priority', descending: true)
          .get();
      
      final filteredDocs = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final contentTags = List<String>.from(data['tags'] as List? ?? []);
        
        // Check if ANY of the requested tags match
        return contentTags.any((tag) => tags.contains(tag));
      }).toList();
      
      return filteredDocs
          .map((doc) => SeedContentModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      debugPrint('Error getting seed content by tags: $e');
      throw UnexpectedFailure(
        technicalMessage: 'Failed to get seed content by tags: ${e.toString()}',
        exception: e,
      );
    }
  }
  
  @override
  Future<bool> createSeedContent(SeedContentEntity content) async {
    try {
      final model = SeedContentModel.fromEntity(content);
      final data = model.toFirestore();
      
      // Set the document with the entity's ID
      await _collection.doc(content.id).set(data);
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
      final updateData = {
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (errorMessage != null) {
        updateData['errorMessage'] = errorMessage;
      }
      
      await _collection.doc(id).update(updateData);
      return true;
    } catch (e) {
      debugPrint('Error updating seed content status: $e');
      return false;
    }
  }
  
  @override
  Future<bool> deleteSeedContent(String id) async {
    try {
      await _collection.doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting seed content: $e');
      return false;
    }
  }
  
  @override
  Future<bool> seedContentExists(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking if seed content exists: $e');
      return false;
    }
  }
  
  @override
  Future<int> getCompletedSeedCount() async {
    try {
      final snapshot = await _collection
          .where('status', isEqualTo: SeedingStatus.completed.toString().split('.').last)
          .count()
          .get();
      
      // Handle nullable count value
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Error getting completed seed count: $e');
      return 0;
    }
  }
  
  @override
  Future<Map<SeedingStatus, int>> getSeedStatusCounts() async {
    try {
      final results = <SeedingStatus, int>{};
      
      // Initialize all statuses with zero count
      for (final status in SeedingStatus.values) {
        results[status] = 0;
      }
      
      // Get counts for each status
      for (final status in SeedingStatus.values) {
        final statusStr = status.toString().split('.').last;
        final snapshot = await _collection
            .where('status', isEqualTo: statusStr)
            .count()
            .get();
        
        // Handle nullable count value
        results[status] = snapshot.count ?? 0;
      }
      
      return results;
    } catch (e) {
      debugPrint('Error getting seed status counts: $e');
      
      // Return default values with all zero counts
      return Map.fromEntries(
        SeedingStatus.values.map((status) => MapEntry(status, 0)),
      );
    }
  }
  
  @override
  Stream<List<SeedContentEntity>> watchSeedContent() {
    return _collection
        .orderBy('priority', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SeedContentModel.fromFirestore(doc).toEntity())
              .toList();
        });
  }
} 