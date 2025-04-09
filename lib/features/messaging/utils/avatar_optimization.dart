import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Cache manager dedicated to avatar images
final avatarCacheManager = CacheManager(
  Config(
    'avatarCacheKey',
    stalePeriod: const Duration(days: 7),
    maxNrOfCacheObjects: 200,
    repo: JsonCacheInfoRepository(databaseName: 'avatarCache'),
    fileService: HttpFileService(),
  ),
);

/// Utility class for optimizing and working with avatar images in messaging
class AvatarOptimization {
  /// Get the appropriate size avatar URL based on display size
  /// 
  /// Many services allow requesting different image sizes with URL params
  static String getOptimizedAvatarUrl(String baseUrl, double size) {
    // Round up to nearest 100
    final roundedSize = ((size ~/ 100) + 1) * 100;
    // Maximum reasonable size for avatars
    final cappedSize = math.min(roundedSize, 400);
    
    // Check if the URL has query parameters
    if (baseUrl.contains('?')) {
      return '$baseUrl&size=$cappedSize';
    } else {
      return '$baseUrl?size=$cappedSize';
    }
  }
  
  /// Get appropriate cache width for avatar image
  static int getCacheWidth(double displaySize) {
    // We multiply by device pixel ratio (generally 2-3) to ensure quality on high-DPI screens
    return (displaySize * 2.5).ceil();
  }
  
  /// Preload avatar image into cache
  static Future<void> preloadAvatar(String avatarUrl, {double size = 80, BuildContext? context}) async {
    final optimizedUrl = getOptimizedAvatarUrl(avatarUrl, size);
    final cacheProvider = CachedNetworkImageProvider(
      optimizedUrl,
      cacheManager: avatarCacheManager,
      cacheKey: 'avatar_$avatarUrl',
    );
    
    // Load the image directly without precaching
    await cacheProvider.obtainKey(const ImageConfiguration());
  }
  
  /// Extract dominant color from an avatar for use in UI
  static Future<Color> extractAvatarColor(String avatarUrl) async {
    try {
      final optimizedUrl = getOptimizedAvatarUrl(avatarUrl, 100);
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(
          optimizedUrl,
          cacheManager: avatarCacheManager,
        ),
        size: const Size(100, 100),
        maximumColorCount: 5,
      );
      
      // Try to get dominant vibrant color, fallback to dominant
      final color = paletteGenerator.vibrantColor?.color ?? 
                   paletteGenerator.dominantColor?.color ??
                   AppColors.gold;
                   
      return color;
    } catch (e) {
      // Return default color if extraction fails
      return AppColors.gold;
    }
  }
  
  /// Get a unique avatar placeholder based on the user ID or name
  static Widget getAvatarPlaceholder(String identifier, {double size = 80}) {
    // Generate a reproducible color based on the identifier
    final colorSeed = identifier.hashCode % Colors.primaries.length;
    final baseColor = Colors.primaries[colorSeed];
    final colors = [
      baseColor.shade300,
      baseColor.shade700,
    ];
    
    // Generate initials from identifier (take first letter from first and last word)
    final parts = identifier.split(' ');
    String initials = '';
    
    if (parts.isNotEmpty) {
      initials += parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '';
      if (parts.length > 1) {
        initials += parts.last.isNotEmpty ? parts.last[0].toUpperCase() : '';
      }
    }
    
    if (initials.isEmpty) {
      initials = 'U'; // Default for empty initials
    }
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }
} 
 
 