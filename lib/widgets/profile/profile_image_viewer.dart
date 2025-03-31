import 'package:flutter/material.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/components/optimized_image.dart';
import 'dart:io';

/// Shows a full-screen dialog to view a profile image
void showProfileImageViewer(BuildContext context, String? imageUrl) {
  // Check for null or empty image URL
  if (imageUrl == null || imageUrl.isEmpty) {
    debugPrint('Null or empty image URL provided to showProfileImageViewer');
    return;
  }

  // Handle network images vs local files differently
  if (imageUrl.startsWith('http')) {
    try {
      final uri = Uri.parse(imageUrl);
      if (!uri.hasScheme || !uri.hasAuthority) {
        debugPrint('Invalid image URL format in showProfileImageViewer: $imageUrl');
        return;
      }
    } catch (e) {
      debugPrint('Error parsing image URL in showProfileImageViewer: $e');
      return;
    }
  } else {
    // For local files, check if the file exists
    try {
      final file = File(imageUrl);
      if (!file.existsSync()) {
        debugPrint('Local image file does not exist: $imageUrl');
        return;
      }
    } catch (e) {
      debugPrint('Error checking local file: $e');
      return;
    }
  }

  // Use a unique, non-null Hero tag
  final heroTag = 'profile-image-${DateTime.now().millisecondsSinceEpoch}';

  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.95),
    builder: (context) => ProfileImageViewer(
      imageUrl: imageUrl,
      heroTag: heroTag,
    ),
  );
}

/// A widget that displays an expanded profile image with zoom functionality
class ProfileImageViewer extends StatelessWidget {
  /// The URL of the image to display
  final String imageUrl;

  /// Hero tag for transition animation
  final String heroTag;

  const ProfileImageViewer({
    super.key,
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Fullscreen image with better touch handling
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: screenSize.width,
              height: screenSize.height,
              color: Colors.black,
              child: Center(
                child: Hero(
                  tag: heroTag,
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: _buildImage(context, isSmallScreen),
                  ),
                ),
              ),
            ),
          ),

          // Close button with solid background
          Positioned(
            top: isSmallScreen ? 40 : 60,
            right: isSmallScreen ? 16 : 40,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                customBorder: const CircleBorder(),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the image widget based on the URL type
  Widget _buildImage(BuildContext context, bool isSmallScreen) {
    // Additional check for empty URL (this should never happen due to validation in showProfileImageViewer)
    if (imageUrl.isEmpty) {
      return _buildErrorWidget(isSmallScreen, 'No image provided');
    }

    // Handle local files
    if (!imageUrl.startsWith('http')) {
      try {
        // For local files, use Image.file not Image.asset
        return Image.file(
          File(imageUrl),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error loading local image in viewer: $error');
            return _buildErrorWidget(isSmallScreen);
          },
        );
      } catch (e) {
        debugPrint('Exception loading local image in viewer: $e');
        return _buildErrorWidget(isSmallScreen);
      }
    }

    // Network image
    return OptimizedImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      errorWidget: (context, url, error) {
        debugPrint('Error loading network image in viewer: $error');
        return _buildErrorWidget(isSmallScreen);
      },
      loadingWidget: const Center(
        child: CircularProgressIndicator(
          color: AppColors.gold,
        ),
      ),
    );
  }

  /// Builds an error widget when image loading fails
  Widget _buildErrorWidget(bool isSmallScreen, [String message = 'Unable to load image']) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
