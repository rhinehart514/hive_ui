import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlService {
  /// Opens a URL in the external browser
  static Future<void> openUrl(String url,
      {bool useExternalBrowser = true}) async {
    try {
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: useExternalBrowser
              ? LaunchMode.externalApplication
              : LaunchMode.platformDefault,
        );
      } else {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  /// Checks if a URL can be launched
  static Future<bool> canOpen(String url) async {
    try {
      final uri = Uri.parse(url);
      return await canLaunchUrl(uri);
    } catch (e) {
      debugPrint('Error checking URL: $e');
      return false;
    }
  }
}
