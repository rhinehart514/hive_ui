import 'dart:io';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Utility for detecting specific Apple hardware devices.
/// 
/// This class provides detailed information about the specific Apple device
/// the app is running on, beyond just the platform type. This allows for
/// targeted optimizations based on device capabilities.
class AppleHardwareDetector {
  /// Singleton instance
  static final AppleHardwareDetector _instance = AppleHardwareDetector._internal();
  
  /// Device info plugin
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  /// Cached iOS device info
  IosDeviceInfo? _iosInfo;
  
  /// Cached macOS device info
  MacOsDeviceInfo? _macOsInfo;
  
  /// Factory constructor
  factory AppleHardwareDetector() => _instance;
  
  /// Private constructor
  AppleHardwareDetector._internal();
  
  /// Initialize the detector by fetching device info
  Future<void> initialize() async {
    if (!Platform.isIOS && !Platform.isMacOS) return;
    
    try {
      if (Platform.isIOS) {
        _iosInfo = await _deviceInfo.iosInfo;
        debugPrint('Detected iOS device: ${_iosInfo?.name} (${_iosInfo?.model})');
      } else if (Platform.isMacOS) {
        _macOsInfo = await _deviceInfo.macOsInfo;
        debugPrint('Detected macOS device: ${_macOsInfo?.computerName} (${_macOsInfo?.model})');
      }
    } catch (e) {
      debugPrint('Error detecting device info: $e');
    }
  }
  
  /// Checks if running on iOS
  bool get isIOS => Platform.isIOS;
  
  /// Checks if running on macOS
  bool get isMacOS => Platform.isMacOS;
  
  /// Gets the marketing name of the device (e.g., "iPhone 12 Pro Max")
  String get deviceName {
    if (isIOS) {
      return _iosInfo?.name ?? 'Unknown iOS Device';
    } else if (isMacOS) {
      return _macOsInfo?.computerName ?? 'Unknown Mac';
    }
    return 'Unknown Device';
  }
  
  /// Gets the system version (e.g., "15.5" for iOS)
  String get systemVersion {
    if (isIOS) {
      return _iosInfo?.systemVersion ?? 'Unknown';
    } else if (isMacOS) {
      return _macOsInfo?.osRelease ?? 'Unknown';
    }
    return 'Unknown';
  }
  
  /// Checks if device is iPhone
  bool get isIPhone => isIOS && (_iosInfo?.model.toLowerCase().contains('iphone') ?? false);
  
  /// Checks if device is iPad
  bool get isIPad => isIOS && (_iosInfo?.model.toLowerCase().contains('ipad') ?? false);
  
  /// Checks if device is iPod Touch
  bool get isIPodTouch => isIOS && (_iosInfo?.model.toLowerCase().contains('ipod') ?? false);
  
  /// Checks if device is a Pro model (iPhone Pro, iPad Pro)
  bool get isProModel {
    if (!isIOS) return false;
    final model = _iosInfo?.model.toLowerCase() ?? '';
    return model.contains('pro');
  }
  
  /// Checks if device has a notch (iPhone X and newer)
  bool get hasNotch {
    if (!isIPhone) return false;
    
    // Extract the device identifier (e.g., "iPhone10,3" -> 10)
    final model = _iosInfo?.model ?? '';
    final parts = model.split(',');
    if (parts.isEmpty) return false;
    
    final identifier = parts[0].replaceAll(RegExp(r'[^0-9]'), '');
    final modelNumber = int.tryParse(identifier) ?? 0;
    
    // iPhone X and newer have model numbers >= 10
    return modelNumber >= 10;
  }
  
  /// Checks if device has a Dynamic Island (iPhone 14 Pro and newer)
  bool get hasDynamicIsland {
    if (!isIPhone) return false;
    
    // Extract the device identifier
    final model = _iosInfo?.model ?? '';
    final parts = model.split(',');
    if (parts.isEmpty) return false;
    
    final identifier = parts[0].replaceAll(RegExp(r'[^0-9]'), '');
    final modelNumber = int.tryParse(identifier) ?? 0;
    
    // iPhone 14 Pro and Pro Max have model numbers >= 15
    return modelNumber >= 15 && isProModel;
  }
  
  /// Checks if device supports ProMotion display (120Hz refresh rate)
  bool get supportsProMotion {
    if (!isIOS) return false;
    
    if (isIPhone) {
      // Only iPhone 13 Pro and newer support ProMotion
      final model = _iosInfo?.model ?? '';
      final isIPhone13ProOrNewer = model.contains('iPhone14') && isProModel;
      return isIPhone13ProOrNewer;
    } else if (isIPad) {
      // Only iPad Pro models from 2017 and newer support ProMotion
      return isProModel;
    }
    
    return false;
  }
  
  /// Checks if device has Force Touch/3D Touch capability
  bool get hasForceTouch {
    if (!isIPhone) return false;
    
    // Extract model identifier
    final model = _iosInfo?.model ?? '';
    final parts = model.split(',');
    if (parts.isEmpty) return false;
    
    final identifier = parts[0].replaceAll(RegExp(r'[^0-9]'), '');
    final modelNumber = int.tryParse(identifier) ?? 0;
    
    // iPhone 6s through iPhone XS (model numbers 8-11) had 3D Touch
    return modelNumber >= 8 && modelNumber <= 11;
  }
  
  /// Gets the device's screen size in points
  Size? get screenSize {
    // This is not directly available from device_info_plus
    // Would need to use a different approach, possibly through MediaQuery in a widget context
    return null;
  }
  
  /// Gets the device's screen density (pixels per point)
  double? get screenDensity {
    if (isIOS) {
      final scale = _iosInfo?.utsname.machine.contains('iPhone') == true ? 2.0 : 
                   (_iosInfo?.utsname.machine.contains('iPad') == true ? 2.0 : null);
      return scale;
    }
    return null;
  }
  
  /// Checks if this is a newer, higher-performance device
  bool get isHighPerformanceDevice {
    if (isIOS) {
      // Approximation based on device model
      final model = _iosInfo?.model ?? '';
      final parts = model.split(',');
      if (parts.isEmpty) return false;
      
      final identifier = parts[0].replaceAll(RegExp(r'[^0-9]'), '');
      final modelNumber = int.tryParse(identifier) ?? 0;
      
      // iPhone 11 and newer, or iPad Pro
      return (isIPhone && modelNumber >= 12) || (isIPad && isProModel);
    } else if (isMacOS) {
      // All Macs are considered high performance for a mobile app
      return true;
    }
    
    return false;
  }
  
  /// Gets recommended animation complexity level based on device capabilities
  /// Higher value = more complex animations are appropriate
  int get recommendedAnimationLevel {
    if (!isIOS && !isMacOS) return 1;
    
    if (isMacOS) return 3; // Highest level for Macs
    
    if (isHighPerformanceDevice) {
      return supportsProMotion ? 3 : 2;
    }
    
    return 1; // Basic level for older/lower-end devices
  }
} 