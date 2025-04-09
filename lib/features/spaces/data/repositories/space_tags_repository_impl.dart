import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_ui/features/spaces/data/models/space_tag_model.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_tag_entity.dart';
import 'package:hive_ui/features/spaces/domain/repositories/space_tags_repository.dart';

/// Implementation of the SpaceTagsRepository
class SpaceTagsRepositoryImpl implements SpaceTagsRepository {
  final FirebaseFirestore _firestore;

  SpaceTagsRepositoryImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection reference for space tags
  CollectionReference<Map<String, dynamic>> get _tagsCollection =>
      _firestore.collection('space_tags');

  @override
  Future<List<SpaceTagEntity>> getTags() async {
    try {
      final snapshot = await _tagsCollection.get();
      return snapshot.docs
          .map((doc) => SpaceTagModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Failed to get tags: $e');
    }
  }

  @override
  Future<List<SpaceTagEntity>> getTagsByCategory(TagCategory category) async {
    try {
      final snapshot = await _tagsCollection
          .where('category', isEqualTo: category.toString().split('.').last)
          .get();
      return snapshot.docs
          .map((doc) => SpaceTagModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Failed to get tags by category: $e');
    }
  }

  @override
  Future<SpaceTagEntity> getTag(String id) async {
    try {
      final doc = await _tagsCollection.doc(id).get();
      if (!doc.exists) {
        throw Exception('Tag not found');
      }
      return SpaceTagModel.fromFirestore(doc).toEntity();
    } catch (e) {
      throw Exception('Failed to get tag: $e');
    }
  }

  @override
  Future<List<SpaceTagEntity>> getTagsForSpace(String spaceId) async {
    try {
      final spaceDoc = await _firestore.collection('spaces').doc(spaceId).get();
      
      if (!spaceDoc.exists) {
        throw Exception('Space not found');
      }
      
      final data = spaceDoc.data();
      if (data == null) {
        return [];
      }
      
      final tagIds = data['tagIds'] as List<dynamic>? ?? [];
      if (tagIds.isEmpty) {
        return [];
      }
      
      // Get all tags in a batch
      final tags = await Future.wait(
        tagIds.map((tagId) => _tagsCollection.doc(tagId.toString()).get()),
      );
      
      return tags
          .where((doc) => doc.exists)
          .map((doc) => SpaceTagModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Failed to get tags for space: $e');
    }
  }

  @override
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
  }) async {
    try {
      final now = DateTime.now();
      final data = {
        'name': name,
        'description': description,
        'color': color.value,
        'category': category.toString().split('.').last,
        'isOfficial': isOfficial,
        'usageCount': 0,
        'createdAt': now,
        'updatedAt': now,
        'isFilterable': isFilterable,
        'isSearchable': isSearchable,
        'isExclusive': isExclusive,
        'metadata': metadata,
      };
      
      final docRef = await _tagsCollection.add(data);
      final doc = await docRef.get();
      
      return SpaceTagModel.fromFirestore(doc).toEntity();
    } catch (e) {
      throw Exception('Failed to create tag: $e');
    }
  }

  @override
  Future<void> updateTag(String id, {
    String? name,
    String? description,
    Color? color,
    TagCategory? category,
    bool? isOfficial,
    bool? isFilterable,
    bool? isSearchable,
    bool? isExclusive,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final data = <String, dynamic>{
        'updatedAt': DateTime.now(),
      };
      
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (color != null) data['color'] = color.value;
      if (category != null) {
        data['category'] = category.toString().split('.').last;
      }
      if (isOfficial != null) data['isOfficial'] = isOfficial;
      if (isFilterable != null) data['isFilterable'] = isFilterable;
      if (isSearchable != null) data['isSearchable'] = isSearchable;
      if (isExclusive != null) data['isExclusive'] = isExclusive;
      if (metadata != null) data['metadata'] = metadata;
      
      await _tagsCollection.doc(id).update(data);
    } catch (e) {
      throw Exception('Failed to update tag: $e');
    }
  }

  @override
  Future<void> deleteTag(String id) async {
    try {
      await _tagsCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete tag: $e');
    }
  }

  @override
  Future<void> incrementTagUsage(String id) async {
    try {
      await _tagsCollection.doc(id).update({
        'usageCount': FieldValue.increment(1),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Failed to increment tag usage: $e');
    }
  }

  @override
  Future<void> decrementTagUsage(String id) async {
    try {
      await _tagsCollection.doc(id).update({
        'usageCount': FieldValue.increment(-1),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Failed to decrement tag usage: $e');
    }
  }

  @override
  Future<void> addTagToSpace(String spaceId, String tagId) async {
    try {
      await _firestore.collection('spaces').doc(spaceId).update({
        'tagIds': FieldValue.arrayUnion([tagId]),
        'updatedAt': DateTime.now(),
      });
      
      // Increment the tag usage
      await incrementTagUsage(tagId);
    } catch (e) {
      throw Exception('Failed to add tag to space: $e');
    }
  }

  @override
  Future<void> removeTagFromSpace(String spaceId, String tagId) async {
    try {
      await _firestore.collection('spaces').doc(spaceId).update({
        'tagIds': FieldValue.arrayRemove([tagId]),
        'updatedAt': DateTime.now(),
      });
      
      // Decrement the tag usage
      await decrementTagUsage(tagId);
    } catch (e) {
      throw Exception('Failed to remove tag from space: $e');
    }
  }

  @override
  Stream<List<SpaceTagEntity>> watchTags() {
    return _tagsCollection
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SpaceTagModel.fromFirestore(doc).toEntity())
            .toList());
  }

  @override
  Stream<List<SpaceTagEntity>> watchTagsByCategory(TagCategory category) {
    return _tagsCollection
        .where('category', isEqualTo: category.toString().split('.').last)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SpaceTagModel.fromFirestore(doc).toEntity())
            .toList());
  }

  @override
  Stream<SpaceTagEntity> watchTag(String id) {
    return _tagsCollection
        .doc(id)
        .snapshots()
        .map((doc) => SpaceTagModel.fromFirestore(doc).toEntity());
  }

  @override
  Stream<List<SpaceTagEntity>> watchTagsForSpace(String spaceId) {
    return _firestore
        .collection('spaces')
        .doc(spaceId)
        .snapshots()
        .asyncMap((doc) async {
          if (!doc.exists) {
            throw Exception('Space not found');
          }
          
          final data = doc.data();
          if (data == null) {
            return [];
          }
          
          final tagIds = data['tagIds'] as List<dynamic>? ?? [];
          if (tagIds.isEmpty) {
            return [];
          }
          
          // Get all tags in a batch
          final tagDocs = await Future.wait(
            tagIds.map((tagId) => _tagsCollection.doc(tagId.toString()).get()),
          );
          
          return tagDocs
              .where((doc) => doc.exists)
              .map((doc) => SpaceTagModel.fromFirestore(doc).toEntity())
              .toList();
        });
  }

  @override
  Future<List<SpaceTagEntity>> searchTags(String query) async {
    try {
      // Firebase doesn't support text search, so we'll use startsWith query
      // In a real app, consider using Algolia or other search service
      final snapshot = await _tagsCollection
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();
          
      return snapshot.docs
          .map((doc) => SpaceTagModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Failed to search tags: $e');
    }
  }

  @override
  Future<List<SpaceTagEntity>> getMostUsedTags({int limit = 10}) async {
    try {
      final snapshot = await _tagsCollection
          .orderBy('usageCount', descending: true)
          .limit(limit)
          .get();
          
      return snapshot.docs
          .map((doc) => SpaceTagModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Failed to get most used tags: $e');
    }
  }
} 