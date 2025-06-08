import 'dart:io';

/// Configuration for Apple platforms (iOS and macOS)
class ApplePlatformConfig {
  /// The bundle ID for the app as registered in the App Store
  static const String bundleId = 'com.example.hiveUi'; // Update with your actual Bundle ID
  
  /// The App Store ID for the iOS app
  static const String appStoreId = '9fb3df22f'; // Update with your actual App Store ID
  
  /// Configuration for Sign in with Apple
  static const signInWithAppleConfig = AppleSignInConfig(
    clientId: 'com.example.hiveUi', // Match your bundle ID
    redirectUri: 'https://hive-9265c.firebaseapp.com/__/auth/handler',
    scopes: ['email', 'name'],
  );
  
  /// Returns true if the device supports authentication with biometrics
  static Future<bool> get supportsBiometricAuth async {
    if (!Platform.isIOS && !Platform.isMacOS) return false;
    
    // In a real implementation, you would check for biometric capabilities
    // using a plugin like local_auth
    return true;
  }
  
  /// Configuration for deep linking
  static const deepLinkConfig = AppleDeepLinkConfig(
    urlScheme: 'hiveapp://',
    universalLinkDomain: 'buffalo.campuslabs.com',
    associatedDomains: ['applinks:buffalo.campuslabs.com'],
  );
  
  /// Configuration for media handling
  static const mediaConfig = AppleMediaConfig(
    photoLibraryUsageDescription: 'This app needs photos access to let you select profile photos',
    cameraUsageDescription: 'This app needs camera access to take profile photos',
    microphoneUsageDescription: 'This app needs microphone access to record audio for messages',
  );
  
  /// Configuration for notifications
  static const notificationConfig = AppleNotificationConfig(
    requestAlertPermission: true,
    requestSoundPermission: true,
    requestBadgePermission: true,
    defaultPresentAlert: true,
    defaultPresentSound: true,
    defaultPresentBadge: true,
  );
  
  /// Configuration for Apple Pay (if implemented)
  static const applePayConfig = ApplePayConfig(
    merchantId: 'merchant.com.example.hiveUi',
    supportedNetworks: ['visa', 'mastercard', 'amex'],
    supportedCountries: ['US'],
    currencyCode: 'USD',
  );
}

/// Configuration for Sign in with Apple
class AppleSignInConfig {
  final String clientId;
  final String redirectUri;
  final List<String> scopes;
  
  const AppleSignInConfig({
    required this.clientId,
    required this.redirectUri,
    required this.scopes,
  });
}

/// Configuration for deep linking on Apple platforms
class AppleDeepLinkConfig {
  final String urlScheme;
  final String universalLinkDomain;
  final List<String> associatedDomains;
  
  const AppleDeepLinkConfig({
    required this.urlScheme,
    required this.universalLinkDomain,
    required this.associatedDomains,
  });
}

/// Configuration for media handling permissions
class AppleMediaConfig {
  final String photoLibraryUsageDescription;
  final String cameraUsageDescription;
  final String microphoneUsageDescription;
  
  const AppleMediaConfig({
    required this.photoLibraryUsageDescription,
    required this.cameraUsageDescription,
    required this.microphoneUsageDescription,
  });
}

/// Configuration for notifications on Apple platforms
class AppleNotificationConfig {
  final bool requestAlertPermission;
  final bool requestSoundPermission;
  final bool requestBadgePermission;
  final bool defaultPresentAlert;
  final bool defaultPresentSound;
  final bool defaultPresentBadge;
  
  const AppleNotificationConfig({
    required this.requestAlertPermission,
    required this.requestSoundPermission,
    required this.requestBadgePermission,
    required this.defaultPresentAlert,
    required this.defaultPresentSound, 
    required this.defaultPresentBadge,
  });
}

/// Configuration for Apple Pay (if implemented)
class ApplePayConfig {
  final String merchantId;
  final List<String> supportedNetworks;
  final List<String> supportedCountries;
  final String currencyCode;
  
  const ApplePayConfig({
    required this.merchantId,
    required this.supportedNetworks,
    required this.supportedCountries,
    required this.currencyCode,
  });
} 