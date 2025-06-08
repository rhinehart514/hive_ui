import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service for sharing profiles and handling deep links
class ProfileSharingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Base URL for deep links to profiles
  final String _baseUrl = 'https://hiveapp.com/profile';

  /// Share a profile with other apps
  Future<void> shareProfile(UserProfile profile) async {
    try {
      // Create a dynamic link URL
      final profileUrl = '$_baseUrl/${profile.id}';

      // Generate share text
      final shareText = 'Connect with ${profile.username} on Hive! $profileUrl';

      // Share using the share_plus plugin
      await Share.share(
        shareText,
        subject: 'Check out this profile on Hive',
      );

      // Log the share
      await _logProfileShare(profile.id);
    } catch (e) {
      debugPrint('ProfileSharingService: Error sharing profile: $e');
    }
  }

  /// Generate a QR code content for profile sharing
  String getProfileQrContent(UserProfile profile) {
    return '$_baseUrl/${profile.id}';
  }

  /// Copy profile link to clipboard
  Future<void> copyProfileLinkToClipboard(UserProfile profile) async {
    try {
      final profileUrl = '$_baseUrl/${profile.id}';
      await Clipboard.setData(ClipboardData(text: profileUrl));
      await _logProfileShare(profile.id);
    } catch (e) {
      debugPrint('ProfileSharingService: Error copying profile link: $e');
    }
  }

  /// Log profile share event to Firestore for analytics
  Future<void> _logProfileShare(String profileId) async {
    try {
      await _firestore.collection('profile_shares').add({
        'profileId': profileId,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.toString().split('.').last,
      });
    } catch (e) {
      debugPrint('ProfileSharingService: Error logging profile share: $e');
    }
  }

  /// Extract profile ID from a deep link
  String? extractProfileIdFromLink(String link) {
    try {
      if (link.contains(_baseUrl)) {
        final uri = Uri.parse(link);
        final pathSegments = uri.pathSegments;

        if (pathSegments.length >= 2 && pathSegments[0] == 'profile') {
          return pathSegments[1];
        }
      }
      return null;
    } catch (e) {
      debugPrint('ProfileSharingService: Error extracting profile ID: $e');
      return null;
    }
  }
}

/// Provider for the profile sharing service
final profileSharingServiceProvider = Provider<ProfileSharingService>((ref) {
  return ProfileSharingService();
});
