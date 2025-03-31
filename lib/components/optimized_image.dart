import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:io' show Platform, File;
import '../theme/app_colors.dart';
import '../theme/huge_icons.dart';
import '../utils/file_path_handler.dart';

/// Custom cache manager for event images with longer duration
class EventImageCacheManager {
  static const key = 'eventImagesCache';
  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 200,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}

/// A widget that displays an optimized image with proper loading/error states
class OptimizedImage extends StatelessWidget {
  /// URL of the image to display
  final String imageUrl;

  /// Width of the image
  final double? width;

  /// Height of the image
  final double? height;

  /// How to inscribe the image
  final BoxFit fit;

  /// Border radius of the image
  final BorderRadius? borderRadius;

  /// Optional placeholder widget
  final Widget Function(BuildContext, String)? placeholder;

  /// Optional error widget
  final Widget Function(BuildContext, String, dynamic)? errorWidget;

  /// Optional widget to show while loading
  final Widget? loadingWidget;

  /// If true, use a fallback placeholder image if URL is empty
  final bool useFallback;

  /// Fallback placeholder image URL
  final String fallbackUrl;

  /// Maximum dimension for image caching
  static const int _maxCacheDimension = 1200;

  /// Constructor
  const OptimizedImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.loadingWidget,
    this.useFallback = true,
    this.fallbackUrl = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    try {
      // Handle empty URLs
      if (imageUrl.isEmpty || imageUrl.trim().isEmpty) {
        return _buildErrorWidget(context, '', null);
      }

      // Clean up the URL/path first
      String cleanPath;
      try {
        cleanPath = _cleanImagePath(imageUrl);
        if (cleanPath.isEmpty) {
          return _buildErrorWidget(context, imageUrl, 'Invalid path format');
        }
      } catch (e) {
        debugPrint('OptimizedImage: Error cleaning path: $e');
        return _buildErrorWidget(context, imageUrl, e);
      }

      // Handle network images
      if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
        try {
          // Double-check URI is valid before attempting to build network image
          final uri = Uri.parse(cleanPath);
          if (!uri.hasScheme || uri.host.isEmpty) {
            debugPrint('OptimizedImage: Invalid network URL format: $cleanPath');
            return _buildErrorWidget(context, cleanPath, 'Invalid URL format');
          }
          return _buildNetworkImage(cleanPath);
        } catch (e) {
          debugPrint('OptimizedImage: Error parsing URL: $e');
          return _buildErrorWidget(context, cleanPath, e);
        }
      }

      // Handle local file paths - wrap in try/catch to catch any exceptions
      try {
        return _buildLocalImage(cleanPath);
      } catch (e) {
        debugPrint('OptimizedImage: Exception with local image: $e');
        return _buildErrorWidget(context, cleanPath, e);
      }
    } catch (e) {
      debugPrint('OptimizedImage: Unhandled exception: $e');
      return _buildErrorWidget(context, imageUrl, e);
    }
  }

  /// Clean up image path/URL
  static String _cleanImagePath(String path) {
    if (path.isEmpty) return '';

    try {
      // Handle network URLs
      if (path.startsWith('http://') || path.startsWith('https://')) {
        try {
          final uri = Uri.parse(path);
          // Validate URI has a valid host
          if (!uri.hasScheme || uri.host.isEmpty) {
            debugPrint('OptimizedImage: Invalid network URL format: $path');
            return '';
          }
          
          // Handle Unsplash URLs specially - ensure proper parameters
          if (uri.host.contains('unsplash.com')) {
            // Add quality and format parameters if not present
            final params = Map<String, String>.from(uri.queryParameters);
            if (!params.containsKey('q')) params['q'] = '80';
            if (!params.containsKey('fm')) params['fm'] = 'jpg';
            return uri.replace(queryParameters: params).toString();
          }
          return path;
        } catch (e) {
          debugPrint('OptimizedImage: Error parsing URL: $e');
          return '';
        }
      }
      
      // File URLs and local paths - use the centralized handler
      return FilePathHandler.getProperPath(path);
    } catch (e) {
      debugPrint('OptimizedImage: Error cleaning path: $e');
      return '';
    }
  }

  /// Builds a network image with proper error handling and caching
  Widget _buildNetworkImage(String url) {
    // Extra safety check - prevent empty URLs from being processed
    if (url.isEmpty || url.trim().isEmpty) {
      debugPrint('OptimizedImage: Attempted to build network image with empty URL');
      return Builder(
        builder: (BuildContext context) {
          return _buildErrorWidget(context, '', 'Empty URL');
        }
      );
    }
    
    return Builder(
      builder: (BuildContext context) {
        Widget imageWidget = Image.network(
          url,
          width: width,
          height: height,
          fit: fit,
          cacheWidth: _calculateMemCacheSize(width),
          cacheHeight: _calculateMemCacheSize(height),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return loadingWidget ?? _buildPlaceholderWidget(context, url);
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint('OptimizedImage: Error loading image from $url: $error');
            return errorWidget != null
                ? errorWidget!(context, url, error)
                : _buildErrorWidget(context, url, error);
          },
        );

        return _wrapWithBorderRadius(imageWidget);
      },
    );
  }

  /// Builds a local image with proper error handling
  Widget _buildLocalImage(String path) {
    return Builder(
      builder: (BuildContext context) {
        try {
          // Additional validation for local path
          if (path.isEmpty) {
            debugPrint('OptimizedImage: Empty file path');
            return _buildErrorWidget(context, path, 'Empty file path');
          }

          // Check for file:// protocol that might have slipped through
          if (path.startsWith('file://')) {
            debugPrint('OptimizedImage: Unexpected file:// protocol in _buildLocalImage');
            final cleanedPath = path.replaceFirst('file://', '');
            if (cleanedPath.isEmpty) {
              return _buildErrorWidget(context, path, 'Invalid file path');
            }
            path = Platform.isWindows 
                ? cleanedPath.replaceFirst(RegExp(r'^/+'), '')
                : cleanedPath;
          }
          
          // Try to create a File object and check if it exists
          final file = File(path);
          if (!file.existsSync()) {
            debugPrint('OptimizedImage: File does not exist: $path');
            return _buildErrorWidget(context, path, 'File not found');
          }

          Widget imageWidget = Image.file(
            file,
            width: width,
            height: height,
            fit: fit,
            cacheWidth: _calculateMemCacheSize(width),
            cacheHeight: _calculateMemCacheSize(height),
            errorBuilder: (context, error, stackTrace) {
              debugPrint('OptimizedImage: Error loading local file: $error');
              return _buildErrorWidget(context, path, error);
            },
          );

          return _wrapWithBorderRadius(imageWidget);
        } catch (e) {
          debugPrint('OptimizedImage: Exception loading local file: $e');
          return _buildErrorWidget(context, path, e);
        }
      },
    );
  }

  /// Wraps widget with border radius if specified
  Widget _wrapWithBorderRadius(Widget child) {
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: child,
      );
    }
    return child;
  }

  /// Default placeholder widget
  Widget _buildPlaceholderWidget(BuildContext context, String url) {
    if (loadingWidget != null) return loadingWidget!;

    return Container(
      width: width,
      height: height,
      color: AppColors.cardBackground.withOpacity(0.5),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  /// Default error widget
  Widget _buildErrorWidget(BuildContext context, String url, dynamic error) {
    return Container(
      width: width,
      height: height,
      color: AppColors.cardBackground.withOpacity(0.5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/hivelogo.png',
              width: _calculateIconSize() * 1.5,
              height: _calculateIconSize() * 1.5,
              color: AppColors.gold.withOpacity(0.7),
            ),
            if (height != null && height! > 100) ...[
              const SizedBox(height: 8),
              Text(
                "Image unavailable",
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Calculate memory cache size with safety checks
  int? _calculateMemCacheSize(double? size) {
    if (size == null || size <= 0) return null;
    if (size.isNaN || size.isInfinite) return null;

    try {
      final calculatedSize = (size * 2).roundToDouble();
      if (calculatedSize.isNaN || calculatedSize.isInfinite) return null;

      return calculatedSize.clamp(0, _maxCacheDimension).round();
    } catch (e) {
      return null;
    }
  }

  /// Calculate a safe icon size based on container dimensions
  double _calculateIconSize() {
    const double defaultSize = 24.0;
    if (width == null) return defaultSize;

    try {
      final calculatedSize = width! / 5;
      if (calculatedSize.isNaN || calculatedSize.isInfinite) return defaultSize;
      return calculatedSize.clamp(16.0, 48.0);
    } catch (e) {
      return defaultSize;
    }
  }
}

/// Extension for pre-caching images
extension ImagePreCaching on BuildContext {
  /// Pre-cache images for smoother UI
  Future<void> preCacheImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      if (url.isEmpty) continue;
      try {
        final cleanUrl = OptimizedImage._cleanImagePath(url);
        if (cleanUrl.isNotEmpty) {
          await EventImageCacheManager.instance.getSingleFile(cleanUrl);
        }
      } catch (e) {
        debugPrint('Error pre-caching image: $e');
      }
    }
  }
}
