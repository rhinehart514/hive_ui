import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:share_plus/share_plus.dart';

/// Apple platform integration utilities that provide platform-specific
/// functionality for iOS and macOS versions of HIVE UI.
class ApplePlatformIntegration {
  /// Singleton instance
  static final ApplePlatformIntegration _instance = ApplePlatformIntegration._internal();
  
  /// Factory constructor
  factory ApplePlatformIntegration() => _instance;
  
  /// Private constructor
  ApplePlatformIntegration._internal();
  
  /// Returns true if running on any Apple platform (iOS or macOS)
  bool get isApplePlatform => Platform.isIOS || Platform.isMacOS;
  
  /// Returns true if running on iOS
  bool get isIOS => Platform.isIOS;
  
  /// Returns true if running on macOS
  bool get isMacOS => Platform.isMacOS;
  
  /// Sets up platform-specific visual configurations
  void configureAppleVisuals() {
    if (!isApplePlatform) return;
    
    // Configure status bar appearance
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark, // iOS: dark text for light status bar
        statusBarIconBrightness: Brightness.light, // Android: light icons for dark background
      ),
    );
    
    // Configure preferred orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
  
  /// Returns platform-appropriate scroll physics
  ScrollPhysics getScrollPhysics() {
    return isApplePlatform 
        ? const BouncingScrollPhysics() 
        : const ClampingScrollPhysics();
  }
  
  /// Provides a platform-specific dialog
  Future<T?> showPlatformDialog<T>({
    required BuildContext context, 
    required String title,
    required String message,
    String? cancelText,
    String? confirmText,
  }) async {
    if (isApplePlatform) {
      return showCupertinoDialog<T>(
        context: context,
        barrierDismissible: false,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            if (cancelText != null)
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.pop(context),
                child: Text(cancelText),
              ),
            if (confirmText != null)
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmText),
              ),
          ],
        ),
      );
    } else {
      return showDialog<T>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            if (cancelText != null)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(cancelText),
              ),
            if (confirmText != null)
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmText),
              ),
          ],
        ),
      );
    }
  }
  
  /// Initiates Sign in with Apple flow
  Future<AuthorizationCredentialAppleID?> signInWithApple() async {
    if (!isApplePlatform) return null;
    
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      return credential;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code != AuthorizationErrorCode.canceled) {
        debugPrint('Apple Sign In Error: ${e.message}');
      }
      return null;
    } catch (e) {
      debugPrint('Unexpected Apple Sign In Error: $e');
      return null;
    }
  }
  
  /// Adds an event to the device calendar (iOS/macOS specific implementation)
  Future<bool> addToCalendar({
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    String? location,
  }) async {
    if (!isApplePlatform) return false;
    
    final Event event = Event(
      title: title,
      description: description,
      location: location ?? '',
      startDate: startDate,
      endDate: endDate,
    );
    
    try {
      return await Add2Calendar.addEvent2Cal(event);
    } catch (e) {
      debugPrint('Error adding event to calendar: $e');
      return false;
    }
  }
  
  /// Shares content with platform-specific UI
  Future<void> shareContent({
    required String text,
    String? subject,
    List<String>? imagePaths,
    Rect? sharePositionOrigin, // Used for iPads to position the share sheet
  }) async {
    if (!isApplePlatform) return;
    
    final box = sharePositionOrigin ?? Rect.zero;
    
    if (imagePaths != null && imagePaths.isNotEmpty) {
      await Share.shareXFiles(
        imagePaths.map((path) => XFile(path)).toList(),
        text: text,
        subject: subject,
        sharePositionOrigin: box,
      );
    } else {
      await Share.share(
        text,
        subject: subject,
        sharePositionOrigin: box,
      );
    }
  }
  
  /// Opens the App Store page for this app
  Future<bool> openAppStorePage({
    String iOSAppId = '9fb3df22f', // Replace with your actual App Store ID
  }) async {
    if (!isApplePlatform) return false;
    
    final Uri url;
    if (isIOS) {
      url = Uri.parse('https://apps.apple.com/app/id$iOSAppId');
    } else if (isMacOS) {
      url = Uri.parse('https://apps.apple.com/app/id$iOSAppId');
    } else {
      return false;
    }
    
    try {
      return await url_launcher.launchUrl(
        url, 
        mode: url_launcher.LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Error opening App Store page: $e');
      return false;
    }
  }
  
  /// Returns appropriate date picker for the platform
  Widget buildDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required Function(DateTime) onDateChanged,
  }) {
    if (isApplePlatform) {
      return SizedBox(
        height: 200,
        child: CupertinoDatePicker(
          initialDateTime: initialDate,
          mode: CupertinoDatePickerMode.date,
          onDateTimeChanged: onDateChanged,
          backgroundColor: const Color(0xFF1E1E1E),
        ),
      );
    } else {
      return CalendarDatePicker(
        initialDate: initialDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        onDateChanged: onDateChanged,
      );
    }
  }
  
  /// Returns platform-specific loading indicator
  Widget getLoadingIndicator({Color? color}) {
    if (isApplePlatform) {
      return CupertinoActivityIndicator(
        color: color ?? const Color(0xFFEEB700),
      );
    } else {
      return CircularProgressIndicator(
        color: color ?? const Color(0xFFEEB700),
      );
    }
  }
} 