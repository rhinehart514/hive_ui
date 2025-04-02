import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hive_ui/services/performance_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io' show Platform, File;
import '../theme/app_colors.dart';
import '../utils/file_path_handler.dart';
import 'dart:math';

/// Dedicated cache manager for event images with tuned parameters
class EventImageCacheManager {
  // Use a singleton pattern for the cache manager
  static CacheManager instance = CacheManager(
    Config(
      'event_images_cache',
      stalePeriod: const Duration(days: 7), // Keep images for a week
      maxNrOfCacheObjects: 500, // Limit cache size to 500 objects
      repo: JsonCacheInfoRepository(databaseName: 'event_images_cache'),
      fileService: HttpFileService(),
    ),
  );
  
  // Separate small cache manager with different settings for thumbnails
  static CacheManager thumbnailInstance = CacheManager(
    Config(
      'thumbnail_images_cache',
      stalePeriod: const Duration(days: 14), // Keep thumbnails longer
      maxNrOfCacheObjects: 1000, // More thumbnails, they're smaller
      repo: JsonCacheInfoRepository(databaseName: 'thumbnail_images_cache'),
      fileService: HttpFileService(),
    ),
  );

  /// Clear all cached images
  static Future<void> clearCache() async {
    await instance.emptyCache();
    await thumbnailInstance.emptyCache();
  }
  
  /// Get stats about the cache
  static Future<Map<String, dynamic>> getCacheStats() async {
    // CacheManager doesn't have a stats method, so we'll provide a simpler implementation
    return {
      'event_images': {
        'size': 'unknown', // We can't directly get this information
      },
      'thumbnails': {
        'size': 'unknown', // We can't directly get this information
      }
    };
  }
}

/// Maximum dimension for image caching
const int kMaxCachedImageDimension = 1500;

/// Clean URL by removing query parameters for better caching
String cleanImageUrl(String? url) {
  if (url == null || url.isEmpty) {
    return '';
  }
  
  // Remove query parameters after '?' for better cache efficiency
  final questionIndex = url.indexOf('?');
  if (questionIndex > 0) {
    return url.substring(0, questionIndex);
  }
  
  return url;
}

/// Default placeholder widget when image is loading
Widget defaultPlaceholder(
    BuildContext context, String url, {Color? backgroundColor}) {
  return Container(
    color: backgroundColor ?? Colors.grey[900],
    child: Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold.withOpacity(0.7)),
        ),
      ),
    ),
  );
}

/// Default error widget when image fails to load
Widget defaultErrorWidget(
    BuildContext context, String url, dynamic error, {Color? backgroundColor}) {
  return Container(
    color: backgroundColor ?? Colors.grey[900],
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/hivelogo.png',
            width: 48,
            height: 48,
            color: AppColors.gold.withOpacity(0.7),
          ),
          const SizedBox(height: 8),
          Text(
            'Image not available',
            style: TextStyle(
              color: AppColors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Provider for whether to use progressive image loading
final progressiveLoadingProvider = StateProvider<bool>((ref) => true);

/// Provider for whether to enable image caching (can be disabled for low-memory devices)
final imageCachingEnabledProvider = StateProvider<bool>((ref) => true);

/// Extension for precache helper
extension ImagePrecacheExtension on BuildContext {
  /// Helper method to precache images
  void precacheNetworkImage(String url) {
    if (url.isNotEmpty) {
      // Use the Flutter framework's precacheImage method
      precacheImage(NetworkImage(url), this);
    }
  }
}

/// Custom BlurHash placeholder to replace the flutter_blurhash package
class CustomBlurHashWidget extends StatelessWidget {
  final String? hash;
  final double? width;
  final double? height;
  final BoxFit fit;
  
  const CustomBlurHashWidget({
    Key? key,
    this.hash,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // If no hash is provided, return a simple placeholder
    if (hash == null || hash!.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.black12,
      );
    }
    
    // Create a gradient based on the first characters of the hash
    // This is not a true blurhash decoder but provides a visually similar effect
    // for a temporary solution
    final seedColor = _generateColorFromHash(hash!);
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            seedColor,
            seedColor.withOpacity(0.7),
            seedColor.withOpacity(0.5),
          ],
        ),
      ),
    );
  }
  
  // Generate a color from the hash
  Color _generateColorFromHash(String hash) {
    if (hash.length < 6) {
      return Colors.grey;
    }
    
    // Use the first 6 characters of the hash as a hex color
    final colorHex = hash.substring(0, 6);
    
    try {
      return Color(int.parse('0xFF$colorHex'));
    } catch (e) {
      return Colors.grey;
    }
  }
}

/// Optimized image widget with production-ready features
class OptimizedImage extends ConsumerWidget {
  final String imageUrl;
  final String fallbackUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;
  final Widget? loadingWidget;
  final String? blurhash;
  final bool useFallback;
  final bool useThumbnailCache;
  final bool precacheImages;
  final bool useProgressiveLoading;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final Duration fadeInDuration;
  final bool isCompact;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.fallbackUrl = '',
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.margin,
    this.backgroundColor,
    this.placeholder,
    this.errorWidget,
    this.loadingWidget,
    this.blurhash,
    this.useFallback = true,
    this.useThumbnailCache = false,
    this.precacheImages = true,
    this.useProgressiveLoading = true,
    this.memCacheWidth,
    this.memCacheHeight,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Clean the URL for better caching
    final cleanedUrl = cleanImageUrl(imageUrl);
    final cleanedFallbackUrl = cleanImageUrl(fallbackUrl);
    
    // Handle empty URL case
    if ((cleanedUrl.isEmpty && cleanedFallbackUrl.isEmpty) || 
        (cleanedUrl.isEmpty && !useFallback)) {
      return _buildErrorContainer(context);
    }
    
    // Track image loading times for performance monitoring
    final perfService = ref.read(performanceServiceProvider);
    
    // Determine whether to use progressive loading from provider or local prop
    final useProgressive = ref.watch(progressiveLoadingProvider) && useProgressiveLoading;
    
    // Get memory cache dimensions
    final dimensions = _calculateMemoryCacheSize(context);
    
    // Precache the image if needed
    if (precacheImages && cleanedUrl.isNotEmpty) {
      context.precacheNetworkImage(cleanedUrl);
    }
    
    // Use the appropriate cache manager based on the use case
    final cacheManager = useThumbnailCache 
        ? EventImageCacheManager.thumbnailInstance 
        : EventImageCacheManager.instance;
    
    // Begin performance tracking
    final stopwatch = Stopwatch()..start();
    
    // Create base widget
    Widget imageWidget = ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: cleanedUrl.isNotEmpty ? cleanedUrl : cleanedFallbackUrl,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: fadeInDuration,
        memCacheWidth: dimensions.width,
        memCacheHeight: dimensions.height,
        cacheManager: cacheManager,
        imageBuilder: (context, imageProvider) {
          // Track successful load time
          stopwatch.stop();
          
          if (cleanedUrl.isNotEmpty) {
            perfService.recordImageLoadTime(cleanedUrl, stopwatch.elapsedMilliseconds);
          }
          
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: imageProvider,
                fit: fit,
              ),
            ),
          );
        },
        placeholder: (context, url) {
          // Use blurhash if available and progressive loading is enabled
          if (blurhash != null && blurhash!.isNotEmpty && useProgressive) {
            return CustomBlurHashWidget(
              hash: blurhash,
              width: width,
              height: height,
              fit: fit,
            );
          }
          
          // Fall back to default or custom placeholder
          return placeholder != null 
              ? placeholder!(context, url) 
              : loadingWidget ?? defaultPlaceholder(context, url, backgroundColor: backgroundColor);
        },
        errorWidget: (context, url, error) {
          // Track failed load
          stopwatch.stop();
          perfService.recordImageLoadFailure(url);
          
          // Try fallback URL if available
          if (url == cleanedUrl && cleanedFallbackUrl.isNotEmpty && useFallback) {
            return CachedNetworkImage(
              imageUrl: cleanedFallbackUrl,
              width: width,
              height: height,
              fit: fit,
              fadeInDuration: fadeInDuration,
              placeholder: (context, url) => 
                  placeholder != null 
                      ? placeholder!(context, url) 
                      : loadingWidget ?? defaultPlaceholder(context, url, backgroundColor: backgroundColor),
              errorWidget: (context, url, error) => 
                  errorWidget != null 
                      ? errorWidget!(context, url, error) 
                      : defaultErrorWidget(context, url, error, backgroundColor: backgroundColor),
            );
          }
          
          // Use custom or default error widget
          return errorWidget != null 
              ? errorWidget!(context, url, error) 
              : defaultErrorWidget(context, url, error, backgroundColor: backgroundColor);
        },
      ),
    );
    
    // Apply margin if specified
    if (margin != null) {
      imageWidget = Container(
        margin: margin,
        child: imageWidget,
      );
    }
    
    return imageWidget;
  }
  
  // Build error container
  Widget _buildErrorContainer(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[900],
        borderRadius: borderRadius ?? BorderRadius.zero,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/hivelogo.png',
              width: isCompact ? 32 : 48,
              height: isCompact ? 32 : 48,
              color: AppColors.gold.withOpacity(0.7),
            ),
            if (!isCompact) ...[
              const SizedBox(height: 8),
              Text(
                'No image available',
                style: TextStyle(
                  color: AppColors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  // Calculate memory cache size
  _ImageDimensions _calculateMemoryCacheSize(BuildContext context) {
    // Use passed dimensions or calculate based on device size
    final deviceSize = MediaQuery.of(context).size;
    
    // Calculate reasonable dimensions based on device
    final deviceWidth = deviceSize.width.toInt();
    final deviceHeight = deviceSize.height.toInt();
    
    final width = memCacheWidth ?? min(deviceWidth, kMaxCachedImageDimension);
    final height = memCacheHeight ?? min(deviceHeight, kMaxCachedImageDimension);
    
    return _ImageDimensions(width, height);
  }
}

/// Helper class for image dimensions
class _ImageDimensions {
  final int width;
  final int height;
  
  const _ImageDimensions(this.width, this.height);
}
