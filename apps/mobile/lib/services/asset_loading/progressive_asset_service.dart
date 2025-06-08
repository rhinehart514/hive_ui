import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for progressive loading of assets
/// This service handles efficient loading of images and other assets
/// with support for placeholders, progressive loading, and caching
class ProgressiveAssetService {
  // Singleton instance
  static final ProgressiveAssetService _instance = ProgressiveAssetService._internal();

  // Factory constructor to return singleton instance
  factory ProgressiveAssetService() => _instance;

  // Default cache manager
  final DefaultCacheManager _cacheManager = DefaultCacheManager();
  
  // Firebase storage instance
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Connection status
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final StreamController<ConnectivityResult> _connectionStatusController = StreamController<ConnectivityResult>.broadcast();
  
  // Quality settings for different connection types
  final Map<ConnectivityResult, int> _qualitySettings = {
    ConnectivityResult.mobile: 75, // Lower quality on mobile
    ConnectivityResult.wifi: 100,   // Full quality on WiFi
    ConnectivityResult.none: 50,    // Lowest quality when offline (from cache)
  };
  
  // Device settings
  bool _isLowPowerMode = false;
  bool _isLowEndDevice = false;
  
  // User preferences
  bool _prefetchEnabled = true;
  bool _progressiveLoadingEnabled = true;
  
  // Prefetch queue
  final Set<String> _prefetchQueue = {};
  Timer? _prefetchTimer;
  
  // Internal constructor
  ProgressiveAssetService._internal() {
    _initService();
  }
  
  /// Initialize the service
  Future<void> _initService() async {
    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      // Use first result if available, otherwise use none
      _connectionStatus = results.isNotEmpty ? results.first : ConnectivityResult.none;
      _connectionStatusController.add(_connectionStatus);
    });
    
    // Get initial connectivity status
    try {
      final results = await Connectivity().checkConnectivity();
      _connectionStatus = results.isNotEmpty ? results.first : ConnectivityResult.none;
    } catch (e) {
      debugPrint('Error getting connectivity status: $e');
      _connectionStatus = ConnectivityResult.none;
    }
    
    // Load user preferences
    await _loadPreferences();
    
    // Start prefetch timer if enabled
    if (_prefetchEnabled) {
      _startPrefetchTimer();
    }
    
    // Determine if device is low-end based on memory
    _detectDeviceCapabilities();
  }
  
  /// Load user preferences for asset loading
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _prefetchEnabled = prefs.getBool('asset_prefetch_enabled') ?? true;
    _progressiveLoadingEnabled = prefs.getBool('asset_progressive_loading') ?? true;
    _isLowPowerMode = prefs.getBool('is_low_power_mode') ?? false;
  }
  
  /// Detect device capabilities to adjust loading strategy
  void _detectDeviceCapabilities() {
    // A simple heuristic for demo - would use more sophisticated detection in production
    // For example, checking available memory, processor speed, etc.
    _isLowEndDevice = false; // Default to false
  }
  
  /// Get a stream of connectivity status changes
  Stream<ConnectivityResult> get connectionStatusStream => _connectionStatusController.stream;
  
  /// Set user preferences for asset loading
  Future<void> setPreferences({
    bool? prefetchEnabled,
    bool? progressiveLoadingEnabled,
    bool? lowPowerMode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (prefetchEnabled != null) {
      _prefetchEnabled = prefetchEnabled;
      await prefs.setBool('asset_prefetch_enabled', prefetchEnabled);
      
      if (prefetchEnabled) {
        _startPrefetchTimer();
      } else {
        _prefetchTimer?.cancel();
      }
    }
    
    if (progressiveLoadingEnabled != null) {
      _progressiveLoadingEnabled = progressiveLoadingEnabled;
      await prefs.setBool('asset_progressive_loading', progressiveLoadingEnabled);
    }
    
    if (lowPowerMode != null) {
      _isLowPowerMode = lowPowerMode;
      await prefs.setBool('is_low_power_mode', lowPowerMode);
    }
  }
  
  /// Get appropriate quality level based on connection and device
  int _getQualityLevel() {
    int quality = _qualitySettings[_connectionStatus] ?? 100;
    
    // Reduce quality on low-end devices or in low power mode
    if (_isLowEndDevice) quality = (quality * 0.8).round();
    if (_isLowPowerMode) quality = (quality * 0.7).round();
    
    return quality.clamp(25, 100);
  }
  
  /// Load an asset from a URL with progressive loading
  Future<ImageProvider> loadImageAsset(String url, {
    bool usePlaceholder = true,
    bool forceProgressiveLoading = false,
    Map<String, String>? headers,
    String? cacheKey,
  }) async {
    // Use cache key or url for cache operations
    final key = cacheKey ?? url;
    
    // Check if the image is in the cache
    final fileInfo = await _cacheManager.getFileFromCache(key);
    
    // If file is in cache and not expired, use it directly
    if (fileInfo != null && !fileInfo.validTill.isBefore(DateTime.now())) {
      return FileImage(fileInfo.file);
    }
    
    // If no internet connection, try to return cached version even if expired
    if (_connectionStatus == ConnectivityResult.none && fileInfo != null) {
      return FileImage(fileInfo.file);
    }
    
    // If progressive loading is enabled or forced
    if ((_progressiveLoadingEnabled || forceProgressiveLoading) && usePlaceholder) {
      // Start downloading full image in background
      _loadAndCacheImage(url, key, headers: headers);
      
      // Return blurred placeholder or thumbnail for immediate display
      return _getPlaceholderImage(url, key);
    }
    
    // Otherwise, load and wait for full image
    try {
      final file = await _cacheManager.getSingleFile(
        url,
        key: key,
        headers: headers,
      );
      return FileImage(file);
    } catch (e) {
      debugPrint('Error loading image: $e');
      // Return a default asset image if loading fails
      return const AssetImage('assets/images/placeholder_image.png');
    }
  }
  
  /// Get a placeholder image while the main image loads
  ImageProvider _getPlaceholderImage(String url, String key) {
    // Try to get a low-res version first
    final lowResUrl = _getLowResUrl(url);
    
    if (lowResUrl != null) {
      return NetworkImage(lowResUrl);
    }
    
    // If no low-res version available, use asset placeholder
    return const AssetImage('assets/images/placeholder_image.png');
  }
  
  /// Get a low resolution version of the URL if available
  String? _getLowResUrl(String url) {
    // For Firebase Storage URLs, use a thumbnail if available
    if (url.contains('firebasestorage.googleapis.com')) {
      try {
        final uri = Uri.parse(url);
        
        // If this is an image, try to get a thumbnail version
        if (url.toLowerCase().endsWith('.jpg') || 
            url.toLowerCase().endsWith('.jpeg') || 
            url.toLowerCase().endsWith('.png')) {
          
          // Convert to thumb_<width>_ format supported by some setups
          // This will only work if the server supports this naming convention
          // Replace with your actual thumbnail generation logic
          return '$url?alt=media&width=100';
        }
      } catch (e) {
        debugPrint('Error parsing URL for low-res: $e');
      }
    }
    
    return null;
  }
  
  /// Load and cache an image in the background
  Future<void> _loadAndCacheImage(
    String url, 
    String key, {
    Map<String, String>? headers,
  }) async {
    try {
      // Quality adjusted based on connection and device
      final qualityLevel = _getQualityLevel();
      
      // For Firebase Storage URLs, adjust the quality
      String adjustedUrl = url;
      if (url.contains('firebasestorage.googleapis.com') && qualityLevel < 100) {
        adjustedUrl = '$url?alt=media&quality=$qualityLevel';
      }
      
      // Download and cache the image - Note: downloadFile() doesn't support headers directly
      // We need to do a http request first and then use putFile()
      if (headers != null && headers.isNotEmpty) {
        // Manual fetch with headers
        final response = await http.get(Uri.parse(adjustedUrl), headers: headers);
        if (response.statusCode == 200) {
          await _cacheManager.putFile(
            adjustedUrl,
            response.bodyBytes,
            key: key,
          );
        }
      } else {
        // Normal cache download
        await _cacheManager.downloadFile(
          adjustedUrl,
          key: key,
        );
      }
    } catch (e) {
      debugPrint('Error caching image: $e');
    }
  }
  
  /// Add a URL to the prefetch queue to be loaded in the background
  void prefetchAsset(String url, {String? cacheKey, int priority = 0}) {
    final key = cacheKey ?? url;
    
    // Add to queue with additional metadata for priority
    _prefetchQueue.add(key);
    
    // Process immediately if priority is high and we have good connection
    if (priority > 0 && _connectionStatus != ConnectivityResult.none) {
      _processPrefetchItem(url, key);
    }
  }
  
  /// Start the prefetch timer to load queued assets
  void _startPrefetchTimer() {
    _prefetchTimer?.cancel();
    _prefetchTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _processPrefetchQueue();
    });
  }
  
  /// Process the prefetch queue
  Future<void> _processPrefetchQueue() async {
    // Skip if offline or queue is empty
    if (_connectionStatus == ConnectivityResult.none || _prefetchQueue.isEmpty) {
      return;
    }
    
    // Take a few items from the queue to process
    final itemsToProcess = _prefetchQueue.take(3).toList();
    
    for (final key in itemsToProcess) {
      // Check if already cached
      final info = await _cacheManager.getFileFromCache(key);
      if (info != null && !info.validTill.isBefore(DateTime.now())) {
        _prefetchQueue.remove(key);
        continue;
      }
      
      // Process the item
      await _processPrefetchItem(key, key);
      _prefetchQueue.remove(key);
    }
  }
  
  /// Process a single prefetch item
  Future<void> _processPrefetchItem(String url, String key) async {
    try {
      // Download at appropriate quality level
      final qualityLevel = _getQualityLevel();
      
      // For Firebase Storage URLs, adjust the quality
      String adjustedUrl = url;
      if (url.contains('firebasestorage.googleapis.com') && qualityLevel < 100) {
        adjustedUrl = '$url?alt=media&quality=$qualityLevel';
      }
      
      // Download with a timeout
      await _cacheManager.downloadFile(
        adjustedUrl,
        key: key,
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Error prefetching asset: $e');
    }
  }
  
  /// Clear all cached assets
  Future<void> clearCache() async {
    await _cacheManager.emptyCache();
  }
  
  /// Get a cached file if available
  Future<File?> getCachedFile(String url, {String? cacheKey}) async {
    final key = cacheKey ?? url;
    final fileInfo = await _cacheManager.getFileFromCache(key);
    return fileInfo?.file;
  }
  
  /// Load a video asset with adaptive quality
  Future<String> loadVideoAsset(String url, {
    String? cacheKey,
    bool adaptiveQuality = true,
  }) async {
    final key = cacheKey ?? url;
    
    // Check if video is in cache
    final fileInfo = await _cacheManager.getFileFromCache(key);
    
    // If file is in cache and not expired, use it directly
    if (fileInfo != null && !fileInfo.validTill.isBefore(DateTime.now())) {
      return fileInfo.file.path;
    }
    
    // If offline and we have a cached version, use that
    if (_connectionStatus == ConnectivityResult.none && fileInfo != null) {
      return fileInfo.file.path;
    }
    
    // For Firebase Storage videos, use adaptive quality if enabled
    if (adaptiveQuality && url.contains('firebasestorage.googleapis.com')) {
      final qualityLevel = _getQualityLevel();
      
      // For demo purposes - in production would use proper HLS or DASH
      if (qualityLevel <= 50) {
        url = url.replaceAll('.mp4', '_360p.mp4');
      } else if (qualityLevel <= 75) {
        url = url.replaceAll('.mp4', '_720p.mp4');
      }
    }
    
    // Download the video
    try {
      final file = await _cacheManager.getSingleFile(
        url,
        key: key,
      );
      return file.path;
    } catch (e) {
      debugPrint('Error loading video: $e');
      rethrow;
    }
  }
  
  /// Dispose resources
  void dispose() {
    _prefetchTimer?.cancel();
    _connectionStatusController.close();
  }
} 