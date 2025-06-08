import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_ui/core/config/apple_platform_config.dart';
import 'package:hive_ui/core/utils/apple_platform_integration.dart';
import 'package:hive_ui/core/ui/apple_ui_adapters.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service to handle Apple-specific functionality and integrations
class ApplePlatformService {
  static final ApplePlatformService _instance = ApplePlatformService._internal();
  
  factory ApplePlatformService() => _instance;
  
  ApplePlatformService._internal();
  
  final ApplePlatformIntegration _platformIntegration = ApplePlatformIntegration();
  final AppleUIAdapters _uiAdapters = AppleUIAdapters();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  bool get isApplePlatform => Platform.isIOS || Platform.isMacOS;
  
  /// Initialize Apple platform specific settings
  Future<void> initialize() async {
    if (!isApplePlatform) return;
    
    // Configure system UI settings
    _platformIntegration.configureAppleVisuals();
    
    // Initialize deep link handling if needed
    _initializeDeepLinks();
    
    // Log platform initialization
    debugPrint('🍏 Apple platform service initialized');
  }
  
  /// Initialize deep link handling
  void _initializeDeepLinks() {
    // Deep link implementation would go here
    // Using packages like uni_links
  }
  
  /// Handle authentication with Apple
  Future<Map<String, dynamic>?> signInWithApple() async {
    if (!isApplePlatform) return null;
    
    try {
      final credential = await _platformIntegration.signInWithApple();
      
      if (credential == null) return null;
      
      // Format the result for Firebase Auth or your auth system
      return {
        'id': credential.userIdentifier,
        'email': credential.email,
        'name': {
          'firstName': credential.givenName,
          'lastName': credential.familyName,
        },
        'token': credential.authorizationCode,
        'identityToken': credential.identityToken,
      };
    } catch (e) {
      debugPrint('Error signing in with Apple: $e');
      return null;
    }
  }
  
  /// Store credentials securely using Apple's secure storage
  Future<void> secureStore(String key, String value) async {
    if (!isApplePlatform) return;
    
    await _secureStorage.write(key: key, value: value);
  }
  
  /// Retrieve credentials from secure storage
  Future<String?> secureRetrieve(String key) async {
    if (!isApplePlatform) return null;
    
    return _secureStorage.read(key: key);
  }
  
  /// Delete credentials from secure storage
  Future<void> secureDelete(String key) async {
    if (!isApplePlatform) return;
    
    await _secureStorage.delete(key: key);
  }
  
  /// Show Apple-styled dialog
  Future<T?> showPlatformDialog<T>({
    required BuildContext context,
    required String title,
    required String message,
    String? cancelText,
    String? confirmText,
  }) {
    return _platformIntegration.showPlatformDialog<T>(
      context: context,
      title: title,
      message: message,
      cancelText: cancelText,
      confirmText: confirmText,
    );
  }
  
  /// Get Apple-styled UI components
  AppleUIAdapters get ui => _uiAdapters;
  
  /// Get Apple platform integration utilities
  ApplePlatformIntegration get platform => _platformIntegration;
  
  /// Add event to Apple Calendar
  Future<bool> addToCalendar({
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    String? location,
  }) {
    return _platformIntegration.addToCalendar(
      title: title,
      description: description,
      startDate: startDate,
      endDate: endDate,
      location: location,
    );
  }
  
  /// Share content using Apple's native share sheet
  Future<void> shareContent({
    required BuildContext context,
    required String text,
    String? subject,
    List<String>? imagePaths,
  }) async {
    // Get position for iPad share sheet
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    final Rect? sharePositionOrigin = box != null
        ? Rect.fromPoints(
            box.localToGlobal(Offset.zero),
            box.localToGlobal(box.size.bottomRight(Offset.zero)),
          )
        : null;
    
    await _platformIntegration.shareContent(
      text: text,
      subject: subject,
      imagePaths: imagePaths,
      sharePositionOrigin: sharePositionOrigin,
    );
  }
  
  /// Open App Store page for this app
  Future<bool> openAppStore() async {
    return _platformIntegration.openAppStorePage(
      iOSAppId: ApplePlatformConfig.appStoreId,
    );
  }
} 