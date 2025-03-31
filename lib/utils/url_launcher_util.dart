import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import 'package:flutter/services.dart';

/// Utility class for launching URLs in a platform-aware way
class UrlLauncherUtil {
  /// Launches a URL with proper error handling and platform awareness
  /// Returns true if the URL was successfully launched
  static Future<bool> openUrl(String urlString,
      {bool externalBrowser = true}) async {
    try {
      // Trigger haptic feedback
      HapticFeedback.selectionClick();

      // Parse the URL
      final Uri url = Uri.parse(urlString);

      // Check if the URL can be launched
      if (!await launcher.canLaunchUrl(url)) {
        debugPrint('Could not launch URL: $urlString');
        return false;
      }

      // Launch the URL
      return await launcher.launchUrl(url,
          mode: externalBrowser
              ? launcher.LaunchMode.externalApplication
              : launcher.LaunchMode.platformDefault);
    } catch (e) {
      debugPrint('Error launching URL: $e');
      return false;
    }
  }

  /// Opens a PDF document
  static Future<bool> openPdf(String pdfUrl) async {
    return await openUrl(pdfUrl);
  }

  /// Opens a web page
  static Future<bool> openWebPage(String webUrl) async {
    return await openUrl(webUrl);
  }

  /// Opens an email client with the given email address
  static Future<bool> sendEmail(String emailAddress,
      {String subject = '', String body = ''}) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: emailAddress,
      query:
          'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    try {
      return await openUrl(emailUri.toString());
    } catch (e) {
      debugPrint('Error opening email: $e');
      return false;
    }
  }
}
