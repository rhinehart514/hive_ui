import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/models/space_type.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/core/navigation/deep_link_schemes.dart';

/// Service for generating and sharing deep links for app content
class DeepLinkSharingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Base URL for web links (fallback for platforms that don't support custom schemes)
  final String _baseWebUrl = 'https://hiveapp.com';
  
  /// Custom URI scheme for deep links
  final String _customScheme = 'hive';
  
  /// Generate a deep link for an event
  String generateEventLink(Event event, {bool useWebUrl = true}) {
    return DeepLinkUrlGenerator.eventLink(event.id, useWebUrl: useWebUrl);
  }
  
  /// Generate a deep link for a space
  String generateSpaceLink(Space space, {bool useWebUrl = true}) {
    // Convert the space type enum to a string
    final spaceType = space.spaceType.toString().split('.').last;
    
    return DeepLinkUrlGenerator.spaceLink(spaceType, space.id, useWebUrl: useWebUrl);
  }
  
  /// Generate a deep link for a profile
  String generateProfileLink(UserProfile profile, {bool useWebUrl = true}) {
    return DeepLinkUrlGenerator.profileLink(profile.id, useWebUrl: useWebUrl);
  }
  
  /// Generate a deep link for a chat
  String generateChatLink(String chatId, {bool useWebUrl = true}) {
    return DeepLinkUrlGenerator.chatLink(chatId, useWebUrl: useWebUrl);
  }
  
  /// Generate a deep link for a group chat
  String generateGroupChatLink(String groupId, {bool useWebUrl = true}) {
    return DeepLinkUrlGenerator.groupChatLink(groupId, useWebUrl: useWebUrl);
  }
  
  /// Generate a deep link for a post
  String generatePostLink(String postId, {bool useWebUrl = true}) {
    return DeepLinkUrlGenerator.postLink(postId, useWebUrl: useWebUrl);
  }
  
  /// Generate a deep link for a search query
  String generateSearchLink(String query, {Map<String, String>? filters, bool useWebUrl = true}) {
    return DeepLinkUrlGenerator.searchLink(query, filters: filters, useWebUrl: useWebUrl);
  }
  
  /// Generate a deep link for an organization
  String generateOrganizationLink(String organizationId, {bool useWebUrl = true}) {
    return DeepLinkUrlGenerator.organizationLink(organizationId, useWebUrl: useWebUrl);
  }
  
  /// Generate a deep link for an event check-in
  String generateEventCheckInLink(String eventId, String code, {bool useWebUrl = true}) {
    return DeepLinkUrlGenerator.eventCheckInLink(eventId, code, useWebUrl: useWebUrl);
  }
  
  /// Share an event with other apps
  Future<void> shareEvent(Event event) async {
    try {
      // Create an event deep link
      final eventUrl = generateEventLink(event);
      
      // Generate share text with event details
      final shareText = '${event.title} on Hive! $eventUrl';
      
      // Share using the share_plus plugin
      await Share.share(
        shareText,
        subject: 'Check out this event on Hive',
      );
      
      // Log the share
      await _logContentShare('event', event.id);
    } catch (e) {
      debugPrint('DeepLinkSharingService: Error sharing event: $e');
    }
  }
  
  /// Share a space with other apps
  Future<void> shareSpace(Space space) async {
    try {
      // Create a space deep link
      final spaceUrl = generateSpaceLink(space);
      
      // Generate share text with space details
      final shareText = 'Check out ${space.name} on Hive! $spaceUrl';
      
      // Share using the share_plus plugin
      await Share.share(
        shareText,
        subject: 'Check out this space on Hive',
      );
      
      // Log the share
      await _logContentShare('space', space.id);
    } catch (e) {
      debugPrint('DeepLinkSharingService: Error sharing space: $e');
    }
  }
  
  /// Share a profile with other apps
  Future<void> shareProfile(UserProfile profile) async {
    try {
      // Create a profile deep link
      final profileUrl = generateProfileLink(profile);
      
      // Generate share text
      final shareText = 'Connect with ${profile.username} on Hive! $profileUrl';
      
      // Share using the share_plus plugin
      await Share.share(
        shareText,
        subject: 'Check out this profile on Hive',
      );
      
      // Log the share
      await _logContentShare('profile', profile.id);
    } catch (e) {
      debugPrint('DeepLinkSharingService: Error sharing profile: $e');
    }
  }
  
  /// Share a chat with other apps
  Future<void> shareChat(String chatId, String chatName) async {
    try {
      // Create a chat deep link
      final chatUrl = generateChatLink(chatId);
      
      // Generate share text
      final shareText = 'Join our conversation on Hive! $chatUrl';
      
      // Share using the share_plus plugin
      await Share.share(
        shareText,
        subject: 'Join this chat on Hive',
      );
      
      // Log the share
      await _logContentShare('chat', chatId);
    } catch (e) {
      debugPrint('DeepLinkSharingService: Error sharing chat: $e');
    }
  }
  
  /// Share a group chat with other apps
  Future<void> shareGroupChat(String groupId, String groupName) async {
    try {
      // Create a group chat deep link
      final groupUrl = generateGroupChatLink(groupId);
      
      // Generate share text
      final shareText = 'Join our group chat "$groupName" on Hive! $groupUrl';
      
      // Share using the share_plus plugin
      await Share.share(
        shareText,
        subject: 'Join this group chat on Hive',
      );
      
      // Log the share
      await _logContentShare('group_chat', groupId);
    } catch (e) {
      debugPrint('DeepLinkSharingService: Error sharing group chat: $e');
    }
  }
  
  /// Share a post with other apps
  Future<void> sharePost(String postId, String postTitle) async {
    try {
      // Create a post deep link
      final postUrl = generatePostLink(postId);
      
      // Generate share text
      final shareText = 'Check out this post on Hive! $postUrl';
      
      // Share using the share_plus plugin
      await Share.share(
        shareText,
        subject: 'Check out this post on Hive',
      );
      
      // Log the share
      await _logContentShare('post', postId);
    } catch (e) {
      debugPrint('DeepLinkSharingService: Error sharing post: $e');
    }
  }
  
  /// Share a search query with other apps
  Future<void> shareSearchResults(String query, Map<String, String>? filters) async {
    try {
      // Create a search results deep link
      final searchUrl = generateSearchLink(query, filters: filters);
      
      // Generate share text
      final shareText = 'Check out these search results on Hive! $searchUrl';
      
      // Share using the share_plus plugin
      await Share.share(
        shareText,
        subject: 'Check out these search results on Hive',
      );
      
      // Log the share
      await _logContentShare('search', query);
    } catch (e) {
      debugPrint('DeepLinkSharingService: Error sharing search results: $e');
    }
  }
  
  /// Share an organization with other apps
  Future<void> shareOrganization(String organizationId, String organizationName) async {
    try {
      // Create an organization deep link
      final organizationUrl = generateOrganizationLink(organizationId);
      
      // Generate share text
      final shareText = 'Check out $organizationName on Hive! $organizationUrl';
      
      // Share using the share_plus plugin
      await Share.share(
        shareText,
        subject: 'Check out this organization on Hive',
      );
      
      // Log the share
      await _logContentShare('organization', organizationId);
    } catch (e) {
      debugPrint('DeepLinkSharingService: Error sharing organization: $e');
    }
  }
  
  /// Copy an event link to clipboard
  Future<void> copyEventLinkToClipboard(Event event) async {
    try {
      final eventUrl = generateEventLink(event);
      await Clipboard.setData(ClipboardData(text: eventUrl));
      await _logContentShare('event', event.id, isClipboard: true);
    } catch (e) {
      debugPrint('DeepLinkSharingService: Error copying event link: $e');
    }
  }
  
  /// Copy a space link to clipboard
  Future<void> copySpaceLinkToClipboard(Space space) async {
    try {
      final spaceUrl = generateSpaceLink(space);
      await Clipboard.setData(ClipboardData(text: spaceUrl));
      await _logContentShare('space', space.id, isClipboard: true);
    } catch (e) {
      debugPrint('DeepLinkSharingService: Error copying space link: $e');
    }
  }
  
  /// Copy a profile link to clipboard
  Future<void> copyProfileLinkToClipboard(UserProfile profile) async {
    try {
      final profileUrl = generateProfileLink(profile);
      await Clipboard.setData(ClipboardData(text: profileUrl));
      await _logContentShare('profile', profile.id, isClipboard: true);
    } catch (e) {
      debugPrint('DeepLinkSharingService: Error copying profile link: $e');
    }
  }
  
  /// Copy a chat link to clipboard
  Future<void> copyChatLinkToClipboard(String chatId) async {
    try {
      final chatUrl = generateChatLink(chatId);
      await Clipboard.setData(ClipboardData(text: chatUrl));
      await _logContentShare('chat', chatId, isClipboard: true);
    } catch (e) {
      debugPrint('DeepLinkSharingService: Error copying chat link: $e');
    }
  }
  
  /// Copy a post link to clipboard
  Future<void> copyPostLinkToClipboard(String postId) async {
    try {
      final postUrl = generatePostLink(postId);
      await Clipboard.setData(ClipboardData(text: postUrl));
      await _logContentShare('post', postId, isClipboard: true);
    } catch (e) {
      debugPrint('DeepLinkSharingService: Error copying post link: $e');
    }
  }
  
  /// Log content share event to Firestore for analytics
  Future<void> _logContentShare(String contentType, String contentId, {bool isClipboard = false}) async {
    try {
      await _firestore.collection('content_shares').add({
        'contentType': contentType,
        'contentId': contentId,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.toString().split('.').last,
        'method': isClipboard ? 'clipboard' : 'share',
      });
    } catch (e) {
      debugPrint('DeepLinkSharingService: Error logging content share: $e');
    }
  }
}

/// Provider for the deep link sharing service
final deepLinkSharingServiceProvider = Provider<DeepLinkSharingService>((ref) {
  return DeepLinkSharingService();
}); 