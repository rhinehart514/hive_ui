import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/core/event_bus/app_event_bus.dart';
import 'package:hive_ui/features/content_seeding/data/models/seed_content_model.dart';
import 'package:hive_ui/features/content_seeding/domain/entities/seed_content_entity.dart';
import 'package:hive_ui/features/content_seeding/domain/repositories/seed_content_repository.dart';

/// Event emitted when a content seeding operation is completed
class ContentSeedingCompletedEvent extends AppEvent {
  /// The ID of the seeded content
  final String contentId;
  
  /// The type of the seeded content
  final SeedContentType contentType;
  
  /// Constructor
  const ContentSeedingCompletedEvent({
    required this.contentId,
    required this.contentType,
  });
}

/// Event emitted when a content seeding operation fails
class ContentSeedingFailedEvent extends AppEvent {
  /// The ID of the seeded content
  final String contentId;
  
  /// The error message
  final String errorMessage;
  
  /// Constructor
  const ContentSeedingFailedEvent({
    required this.contentId,
    required this.errorMessage,
  });
}

/// Event emitted when a content seeding batch is completed
class ContentSeedingBatchCompletedEvent extends AppEvent {
  /// The number of successfully seeded content items
  final int successCount;
  
  /// The number of failed seeding operations
  final int failureCount;
  
  /// The total number of seed operations attempted
  final int totalCount;
  
  /// Constructor
  const ContentSeedingBatchCompletedEvent({
    required this.successCount,
    required this.failureCount,
    required this.totalCount,
  });
}

/// Service for seeding content into the application
class ContentSeedingService {
  final SeedContentRepository _repository;
  final AppEventBus _eventBus;
  
  /// Whether a seeding operation is currently in progress
  bool _isSeeding = false;
  
  /// Current seeding environment
  SeedingEnvironment _environment = SeedingEnvironment.development;
  
  /// Constructor
  ContentSeedingService({
    required SeedContentRepository repository,
    AppEventBus? eventBus,
  }) : 
    _repository = repository,
    _eventBus = eventBus ?? AppEventBus();
  
  /// Set the current environment for seeding operations
  void setEnvironment(SeedingEnvironment environment) {
    _environment = environment;
  }
  
  /// Get the current environment
  SeedingEnvironment get currentEnvironment => _environment;
  
  /// Check if a seeding operation is in progress
  bool get isSeeding => _isSeeding;
  
  /// Seed default content for a new application setup
  /// 
  /// This will seed basic content needed for any new instance
  Future<bool> seedDefaultContent() async {
    if (_isSeeding) {
      debugPrint('🌱 Seeding already in progress');
      return false;
    }
    
    _isSeeding = true;
    
    try {
      debugPrint('🌱 Seeding default content...');
      
      final defaultContent = await _createDefaultSeedContent();
      
      // Create default content in repository if it doesn't exist
      for (final content in defaultContent) {
        if (!await _repository.seedContentExists(content.id)) {
          await _repository.createSeedContent(content);
        }
      }
      
      // Seed the default content
      final result = await _seedContentBatch(defaultContent);
      
      debugPrint('🌱 Default content seeding completed: ${result.successCount}/${result.totalCount} successful');
      
      _eventBus.emit(ContentSeedingBatchCompletedEvent(
        successCount: result.successCount,
        failureCount: result.failureCount,
        totalCount: result.totalCount,
      ));
      
      return result.successCount > 0;
    } catch (e) {
      debugPrint('🌱 Error seeding default content: $e');
      return false;
    } finally {
      _isSeeding = false;
    }
  }
  
  /// Seed content for a new user
  /// 
  /// This will seed sample content for a new user to get started with
  Future<bool> seedNewUserContent() async {
    if (_isSeeding) {
      debugPrint('🌱 Seeding already in progress');
      return false;
    }
    
    _isSeeding = true;
    
    try {
      debugPrint('🌱 Seeding new user content...');
      
      // Get all content marked for new users in the current environment
      final contentList = await _repository.getSeedContentForEnvironment(
        _environment,
        forNewUsersOnly: true,
      );
      
      if (contentList.isEmpty) {
        debugPrint('🌱 No content to seed for new users');
        return false;
      }
      
      // Seed the content
      final result = await _seedContentBatch(contentList);
      
      debugPrint('🌱 New user content seeding completed: ${result.successCount}/${result.totalCount} successful');
      
      _eventBus.emit(ContentSeedingBatchCompletedEvent(
        successCount: result.successCount,
        failureCount: result.failureCount,
        totalCount: result.totalCount,
      ));
      
      return result.successCount > 0;
    } catch (e) {
      debugPrint('🌱 Error seeding new user content: $e');
      return false;
    } finally {
      _isSeeding = false;
    }
  }
  
  /// Seed specific content by ID
  Future<bool> seedSpecificContent(String contentId) async {
    if (_isSeeding) {
      debugPrint('🌱 Seeding already in progress');
      return false;
    }
    
    _isSeeding = true;
    
    try {
      final content = await _repository.getSeedContentById(contentId);
      
      if (content == null) {
        debugPrint('🌱 Content not found: $contentId');
        return false;
      }
      
      // Check if this content is applicable for the current environment
      if (!content.isTargetedForEnvironment(_environment)) {
        debugPrint('🌱 Content not targeted for current environment: $contentId');
        return false;
      }
      
      // Seed the content
      final success = await _seedContent(content);
      
      if (success) {
        await _repository.updateSeedContentStatus(contentId, SeedingStatus.completed);
        
        _eventBus.emit(ContentSeedingCompletedEvent(
          contentId: contentId,
          contentType: content.type,
        ));
      } else {
        await _repository.updateSeedContentStatus(
          contentId, 
          SeedingStatus.failed,
          errorMessage: 'Failed to seed content',
        );
        
        _eventBus.emit(ContentSeedingFailedEvent(
          contentId: contentId,
          errorMessage: 'Failed to seed content',
        ));
      }
      
      return success;
    } catch (e) {
      debugPrint('🌱 Error seeding specific content: $e');
      
      await _repository.updateSeedContentStatus(
        contentId, 
        SeedingStatus.failed,
        errorMessage: e.toString(),
      );
      
      _eventBus.emit(ContentSeedingFailedEvent(
        contentId: contentId,
        errorMessage: e.toString(),
      ));
      
      return false;
    } finally {
      _isSeeding = false;
    }
  }
  
  /// Seed content by type
  Future<bool> seedContentByType(SeedContentType type) async {
    if (_isSeeding) {
      debugPrint('🌱 Seeding already in progress');
      return false;
    }
    
    _isSeeding = true;
    
    try {
      debugPrint('🌱 Seeding content of type: $type');
      
      // Get all content of the specified type in the current environment
      final contentList = await _repository.getSeedContentByType(type);
      
      if (contentList.isEmpty) {
        debugPrint('🌱 No content found of type: $type');
        return false;
      }
      
      // Filter for current environment
      final filteredList = contentList.where(
        (c) => c.isTargetedForEnvironment(_environment)
      ).toList();
      
      if (filteredList.isEmpty) {
        debugPrint('🌱 No content of type $type targeted for current environment');
        return false;
      }
      
      // Seed the content
      final result = await _seedContentBatch(filteredList);
      
      debugPrint('🌱 Content seeding by type completed: ${result.successCount}/${result.totalCount} successful');
      
      _eventBus.emit(ContentSeedingBatchCompletedEvent(
        successCount: result.successCount,
        failureCount: result.failureCount,
        totalCount: result.totalCount,
      ));
      
      return result.successCount > 0;
    } catch (e) {
      debugPrint('🌱 Error seeding content by type: $e');
      return false;
    } finally {
      _isSeeding = false;
    }
  }
  
  /// Seed a batch of content
  /// 
  /// This will process dependencies first and respect priority ordering
  Future<_SeedingResult> _seedContentBatch(List<SeedContentEntity> contentList) async {
    // Sort by priority
    final sortedContent = List<SeedContentEntity>.from(contentList)
      ..sort((a, b) => b.priority.compareTo(a.priority));
    
    // Track results
    int successCount = 0;
    int failureCount = 0;
    
    // Track processed IDs to avoid duplicates
    final Set<String> processedIds = {};
    
    // Process each content item in order
    for (final content in sortedContent) {
      // Skip already processed content
      if (processedIds.contains(content.id)) continue;
      
      try {
        // First process dependencies if any
        if (content.hasDependencies()) {
          for (final depId in content.dependencies) {
            // Skip already processed dependencies
            if (processedIds.contains(depId)) continue;
            
            // Get dependency content
            final depContent = await _repository.getSeedContentById(depId);
            
            if (depContent != null) {
              await _processSingleSeedContent(depContent, processedIds, 
                onSuccess: () => successCount++,
                onFailure: () => failureCount++,
              );
            } else {
              debugPrint('🌱 Dependency not found: $depId for content: ${content.id}');
              
              // Mark this content as skipped
              await _repository.updateSeedContentStatus(
                content.id,
                SeedingStatus.skipped,
                errorMessage: 'Dependency not found: $depId',
              );
              
              failureCount++;
              processedIds.add(content.id);
              continue;
            }
          }
        }
        
        // Process this content item
        await _processSingleSeedContent(content, processedIds,
          onSuccess: () => successCount++,
          onFailure: () => failureCount++,
        );
      } catch (e) {
        debugPrint('🌱 Error processing content ${content.id}: $e');
        
        // Mark as failed
        await _repository.updateSeedContentStatus(
          content.id,
          SeedingStatus.failed,
          errorMessage: e.toString(),
        );
        
        failureCount++;
        processedIds.add(content.id);
        
        _eventBus.emit(ContentSeedingFailedEvent(
          contentId: content.id,
          errorMessage: e.toString(),
        ));
      }
    }
    
    return _SeedingResult(
      successCount: successCount,
      failureCount: failureCount,
      totalCount: contentList.length,
    );
  }
  
  /// Process a single seed content item
  Future<void> _processSingleSeedContent(
    SeedContentEntity content,
    Set<String> processedIds, {
    required VoidCallback onSuccess,
    required VoidCallback onFailure,
  }) async {
    // Skip already processed content
    if (processedIds.contains(content.id)) return;
    
    // Mark as in progress
    await _repository.updateSeedContentStatus(content.id, SeedingStatus.inProgress);
    
    // Attempt to seed the content
    final success = await _seedContent(content);
    
    if (success) {
      // Mark as completed
      await _repository.updateSeedContentStatus(content.id, SeedingStatus.completed);
      
      _eventBus.emit(ContentSeedingCompletedEvent(
        contentId: content.id,
        contentType: content.type,
      ));
      
      onSuccess();
    } else {
      // Mark as failed
      await _repository.updateSeedContentStatus(
        content.id,
        SeedingStatus.failed,
        errorMessage: 'Failed to seed content',
      );
      
      _eventBus.emit(ContentSeedingFailedEvent(
        contentId: content.id,
        errorMessage: 'Failed to seed content',
      ));
      
      onFailure();
    }
    
    // Mark as processed
    processedIds.add(content.id);
  }
  
  /// Seed a specific content entity
  /// 
  /// This implements the actual seeding logic for different content types
  Future<bool> _seedContent(SeedContentEntity content) async {
    try {
      debugPrint('🌱 Seeding content: ${content.id} (${content.type})');
      
      switch (content.type) {
        case SeedContentType.space:
          return await _seedSpaceContent(content);
        case SeedContentType.event:
          return await _seedEventContent(content);
        case SeedContentType.post:
          return await _seedPostContent(content);
        case SeedContentType.announcement:
          return await _seedAnnouncementContent(content);
        case SeedContentType.profile:
          return await _seedProfileContent(content);
        default:
          debugPrint('🌱 Unsupported content type: ${content.type}');
          return false;
      }
    } catch (e) {
      debugPrint('🌱 Error seeding content ${content.id}: $e');
      return false;
    }
  }
  
  /// Seed space content
  /// 
  /// Creates or updates a space based on the seed content
  Future<bool> _seedSpaceContent(SeedContentEntity content) async {
    // In a real implementation, this would create a space in Firestore
    // For now, we'll just simulate the operation
    await Future.delayed(const Duration(milliseconds: 500));
    
    debugPrint('🌱 Seeded space: ${content.id}');
    return true;
  }
  
  /// Seed event content
  /// 
  /// Creates or updates an event based on the seed content
  Future<bool> _seedEventContent(SeedContentEntity content) async {
    // In a real implementation, this would create an event in Firestore
    // For now, we'll just simulate the operation
    await Future.delayed(const Duration(milliseconds: 500));
    
    debugPrint('🌱 Seeded event: ${content.id}');
    return true;
  }
  
  /// Seed post content
  /// 
  /// Creates or updates a post based on the seed content
  Future<bool> _seedPostContent(SeedContentEntity content) async {
    // In a real implementation, this would create a post in Firestore
    // For now, we'll just simulate the operation
    await Future.delayed(const Duration(milliseconds: 500));
    
    debugPrint('🌱 Seeded post: ${content.id}');
    return true;
  }
  
  /// Seed announcement content
  /// 
  /// Creates or updates an announcement based on the seed content
  Future<bool> _seedAnnouncementContent(SeedContentEntity content) async {
    // In a real implementation, this would create an announcement in Firestore
    // For now, we'll just simulate the operation
    await Future.delayed(const Duration(milliseconds: 500));
    
    debugPrint('🌱 Seeded announcement: ${content.id}');
    return true;
  }
  
  /// Seed profile content
  /// 
  /// Creates or updates a profile based on the seed content
  Future<bool> _seedProfileContent(SeedContentEntity content) async {
    // In a real implementation, this would create a profile in Firestore
    // For now, we'll just simulate the operation
    await Future.delayed(const Duration(milliseconds: 500));
    
    debugPrint('🌱 Seeded profile: ${content.id}');
    return true;
  }
  
  /// Create default seed content for initial application setup
  /// 
  /// This generates the default content that should be seeded in any environment
  Future<List<SeedContentEntity>> _createDefaultSeedContent() async {
    final now = DateTime.now();
    final List<SeedContentEntity> defaultContent = [];
    
    // Default spaces
    final campusNewsSpace = SeedContentModel.createDefaultSpace(
      id: 'campus-news',
      name: 'Campus News',
      description: 'Official news and announcements from the university',
      tags: ['official', 'news'],
    ).toEntity();
    
    final eventsSpace = SeedContentModel.createDefaultSpace(
      id: 'campus-events',
      name: 'Campus Events',
      description: 'Events happening around campus',
      tags: ['official', 'events'],
    ).toEntity();
    
    final communitySpace = SeedContentModel.createDefaultSpace(
      id: 'community',
      name: 'Community',
      description: 'General community discussions',
      tags: ['community', 'discussion'],
    ).toEntity();
    
    defaultContent.addAll([campusNewsSpace, eventsSpace, communitySpace]);
    
    // Default events
    final orientationEvent = SeedContentModel.createDefaultEvent(
      id: 'new-student-orientation',
      title: 'New Student Orientation',
      description: 'Welcome to campus! Join us for an introduction to university life.',
      startTime: DateTime(now.year, now.month, now.day + 7, 9, 0),
      endTime: DateTime(now.year, now.month, now.day + 7, 16, 0),
      spaceId: 'campus-events',
      tags: ['orientation', 'new-students'],
    ).toEntity();
    
    final tourEvent = SeedContentModel.createDefaultEvent(
      id: 'campus-tour',
      title: 'Campus Tour',
      description: 'Get to know the campus with a guided tour.',
      startTime: DateTime(now.year, now.month, now.day + 3, 14, 0),
      endTime: DateTime(now.year, now.month, now.day + 3, 16, 0),
      spaceId: 'campus-events',
      tags: ['orientation', 'tour'],
    ).toEntity();
    
    defaultContent.addAll([orientationEvent, tourEvent]);
    
    // Default posts
    final welcomePost = SeedContentModel.createDefaultPost(
      id: 'welcome-post',
      content: 'Welcome to our campus community! We\'re excited to have you join us.',
      spaceId: 'campus-news',
      tags: ['welcome'],
    ).toEntity();
    
    final resourcesPost = SeedContentModel.createDefaultPost(
      id: 'resources-post',
      content: 'Check out these important resources for new students.',
      spaceId: 'campus-news',
      tags: ['resources', 'new-students'],
    ).toEntity();
    
    defaultContent.addAll([welcomePost, resourcesPost]);
    
    return defaultContent;
  }
}

/// Internal class to track seeding results
class _SeedingResult {
  final int successCount;
  final int failureCount;
  final int totalCount;
  
  _SeedingResult({
    required this.successCount,
    required this.failureCount,
    required this.totalCount,
  });
} 