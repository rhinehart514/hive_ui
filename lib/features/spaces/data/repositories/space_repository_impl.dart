import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/space_repository.dart';
import '../../domain/entities/space_entity.dart';
import '../../domain/entities/space_metrics_entity.dart';
import '../../domain/entities/space.dart' as space_domain;

class SpaceRepositoryImpl implements SpaceRepository {
  final FirebaseFirestore _firestore;

  SpaceRepositoryImpl({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<bool> createSpace(space_domain.Space space, {File? coverImage}) async {
    // Stub implementation
    throw UnimplementedError('Only getSuggestedSpacesForUser is implemented');
  }
  
  @override
  Future<space_domain.Space?> getSpaceById(String spaceId) async {
    // Stub implementation
    throw UnimplementedError('Only getSuggestedSpacesForUser is implemented');
  }
  
  @override
  Future<List<space_domain.Space>> getUserSpaces() async {
    // Stub implementation
    throw UnimplementedError('Only getSuggestedSpacesForUser is implemented');
  }
  
  @override
  Future<List<space_domain.Space>> getTrendingSpaces() async {
    // Stub implementation
    throw UnimplementedError('Only getSuggestedSpacesForUser is implemented');
  }
  
  @override
  Future<List<space_domain.Space>> getRecommendedSpaces() async {
    // Stub implementation
    throw UnimplementedError('Only getSuggestedSpacesForUser is implemented');
  }
  
  @override
  Future<bool> joinSpace(String spaceId) async {
    // Stub implementation
    throw UnimplementedError('Only getSuggestedSpacesForUser is implemented');
  }
  
  @override
  Future<bool> leaveSpace(String spaceId) async {
    // Stub implementation
    throw UnimplementedError('Only getSuggestedSpacesForUser is implemented');
  }
  
  @override
  Future<bool> updateSpace(space_domain.Space space, {File? coverImage}) async {
    // Stub implementation
    throw UnimplementedError('Only getSuggestedSpacesForUser is implemented');
  }
  
  @override
  Future<bool> deleteSpace(String spaceId) async {
    // Stub implementation
    throw UnimplementedError('Only getSuggestedSpacesForUser is implemented');
  }
  
  @override
  Future<bool> isSpaceNameAvailable(String name) async {
    // Stub implementation
    throw UnimplementedError('Only getSuggestedSpacesForUser is implemented');
  }
  
  @override
  Future<List<space_domain.Space>> searchSpaces(String query) async {
    // Stub implementation
    throw UnimplementedError('Only getSuggestedSpacesForUser is implemented');
  }

  @override
  Future<List<SpaceEntity>> getSuggestedSpacesForUser({
    required String userId,
    int limit = 5,
  }) async {
    try {
      // Get user data to extract interests
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        return [];
      }
      
      final userData = userDoc.data()!;
      final List<String> userInterests = List<String>.from(userData['interests'] ?? []);
      
      // Get spaces user has already joined to exclude them
      final userSpacesDoc = await _firestore.collection('userSpaces').doc(userId).get();
      final List<String> joinedSpaceIds = userSpacesDoc.exists
          ? List<String>.from(userSpacesDoc.data()?['joinedSpaces'] ?? [])
          : [];
          
      // Query spaces with matching interests
      QuerySnapshot interestSpacesSnapshot;
      if (userInterests.isNotEmpty) {
        interestSpacesSnapshot = await _firestore
            .collection('spaces')
            .where('tags', arrayContainsAny: userInterests)
            .where('isPrivate', isEqualTo: false) // Only public spaces
            .limit(limit * 2) // Get more than needed to filter
            .get();
      } else {
        // Fallback to trending spaces if no interests
        interestSpacesSnapshot = await _firestore
            .collection('spaces')
            .where('isPrivate', isEqualTo: false)
            .orderBy('memberCount', descending: true)
            .limit(limit * 2)
            .get();
      }
      
      // Convert to entities and filter out joined spaces
      List<SpaceEntity> suggestedSpaces = [];
      
      for (var doc in interestSpacesSnapshot.docs) {
        if (joinedSpaceIds.contains(doc.id)) {
          continue; // Skip spaces user has already joined
        }
        
        final data = doc.data() as Map<String, dynamic>;
        final int memberCount = data['memberCount'] ?? 0;
        
        suggestedSpaces.add(SpaceEntity(
          id: doc.id,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          iconCodePoint: data['iconCodePoint'] ?? 0xe000,
          imageUrl: data['imageUrl'],
          tags: List<String>.from(data['tags'] ?? []),
          isPrivate: data['isPrivate'] ?? false,
          createdAt: data['createdAt'] != null 
              ? (data['createdAt'] as Timestamp).toDate() 
              : DateTime.now(),
          updatedAt: data['updatedAt'] != null 
              ? (data['updatedAt'] as Timestamp).toDate() 
              : DateTime.now(),
          metrics: SpaceMetricsEntity.initial(doc.id).copyWith(
            memberCount: memberCount,
            isTrending: data['isTrending'] ?? false,
          ),
          spaceType: _parseEntitySpaceType(data['spaceType']),
        ));
        
        if (suggestedSpaces.length >= limit) {
          break;
        }
      }
      
      return suggestedSpaces;
    } catch (e) {
      print('Error getting suggested spaces: $e');
      return [];
    }
  }
  
  // Helper method to parse space type from string specifically for SpaceEntity
  SpaceType _parseEntitySpaceType(String? type) {
    switch (type) {
      case 'studentOrg':
        return SpaceType.studentOrg;
      case 'universityOrg':
        return SpaceType.universityOrg;
      case 'campusLiving':
        return SpaceType.campusLiving;
      case 'fraternityAndSorority':
        return SpaceType.fraternityAndSorority;
      default:
        return SpaceType.other;
    }
  }
} 