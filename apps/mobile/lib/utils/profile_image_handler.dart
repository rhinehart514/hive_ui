import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/utils/file_path_handler.dart';

/// Utility class for handling profile image operations
class ProfileImageHandler {
  /// Get image from camera with quality settings
  static Future<String?> getImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200, // Limit max width for better performance
        maxHeight: 1200, // Limit max height for better performance
        imageQuality: 90, // High quality (0-100)
      );

      if (image != null) {
        return FilePathHandler.getProperPath(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error taking photo: $e');
      return null;
    }
  }

  /// Get image from gallery with quality settings
  static Future<String?> getImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200, // Limit max width for better performance
        maxHeight: 1200, // Limit max height for better performance
        imageQuality: 90, // High quality (0-100)
      );

      if (image != null) {
        return FilePathHandler.getProperPath(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Show options to change profile image
  static Future<String?> showProfileImageOptions(BuildContext context) async {
    String? imagePath;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.black.withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle for better UX
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    shape: BoxShape.circle,
                    // Add neumorphic effect to icon containers
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 4,
                        spreadRadius: 0,
                        offset: const Offset(2, 2),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.05),
                        blurRadius: 4,
                        spreadRadius: 0,
                        offset: const Offset(-1, -1),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: AppColors.gold,
                  ),
                ),
                title: Text(
                  'Take a photo',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                  imagePath = await getImageFromCamera();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    shape: BoxShape.circle,
                    // Add neumorphic effect to icon containers
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 4,
                        spreadRadius: 0,
                        offset: const Offset(2, 2),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.05),
                        blurRadius: 4,
                        spreadRadius: 0,
                        offset: const Offset(-1, -1),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: AppColors.gold,
                  ),
                ),
                title: Text(
                  'Choose from gallery',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                  imagePath = await getImageFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );

    return imagePath;
  }

  /// Show option to remove profile image
  static Future<bool> showRemoveProfileImageOption(
    BuildContext context,
    UserProfile profile,
  ) async {
    bool shouldRemove = false;

    if (profile.profileImageUrl == null) return false;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.black.withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle for better UX
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 4,
                        spreadRadius: 0,
                        offset: const Offset(2, 2),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.05),
                        blurRadius: 4,
                        spreadRadius: 0,
                        offset: const Offset(-1, -1),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                ),
                title: Text(
                  'Remove current photo',
                  style: GoogleFonts.outfit(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  shouldRemove = true;
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );

    return shouldRemove;
  }

  /// Display profile image with appropriate handling
  static Widget buildProfileImage(String? imageUrl,
      {BoxFit fit = BoxFit.cover}) {
    // Check if imageUrl is null or empty
    if (imageUrl == null || imageUrl.isEmpty) {
      return buildDefaultProfileImage(fit: fit);
    }

    // Validate URL format for network images
    if (imageUrl.startsWith('http')) {
      try {
        // Try to create a URI to validate the URL
        final uri = Uri.parse(imageUrl);
        
        // Check for missing scheme or host
        if (!uri.hasScheme || !uri.hasAuthority) {
          debugPrint('Invalid image URL format: $imageUrl');
          return buildDefaultProfileImage(fit: fit);
        }

        return Image.network(
          imageUrl,
          fit: fit,
          height: double.infinity,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Network image error: $error');
            return buildDefaultProfileImage(fit: fit);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                color: AppColors.gold,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
        );
      } catch (e) {
        debugPrint('Error parsing image URL: $e');
        return buildDefaultProfileImage(fit: fit);
      }
    } else {
      // Handle local file paths
      try {
        // Create a file object directly without parsing URI
        final file = File(imageUrl);
        
        // Check if file exists before attempting to load it
        if (!file.existsSync()) {
          debugPrint('Local image file does not exist: $imageUrl');
          return buildDefaultProfileImage(fit: fit);
        }
        
        return Image.file(
          file,
          fit: fit,
          height: double.infinity,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error loading profile image: $error');
            return buildDefaultProfileImage(fit: fit);
          },
        );
      } catch (e) {
        debugPrint('Error handling local image file: $e');
        return buildDefaultProfileImage(fit: fit);
      }
    }
  }

  /// Build default profile image (used when no image is available or on error)
  static Widget buildDefaultProfileImage({BoxFit fit = BoxFit.cover}) {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person,
              size: 48,
              color: Colors.white.withOpacity(0.7),
            ),
            const SizedBox(height: 8),
            Text(
              'No Image',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show expanded profile image in a fullscreen dialog
  static void showExpandedProfileImage(
      BuildContext context, String? imageUrl, String heroTag) {
    // Don't show dialog if imageUrl is null or empty
    if (imageUrl == null || imageUrl.isEmpty) {
      debugPrint('Cannot show expanded image: URL is null or empty');
      return;
    }

    // Validate URL if it's a network image
    if (imageUrl.startsWith('http')) {
      try {
        final uri = Uri.parse(imageUrl);
        if (!uri.hasScheme || !uri.hasAuthority) {
          debugPrint('Invalid image URL format for expanded view: $imageUrl');
          return;
        }
      } catch (e) {
        debugPrint('Error parsing image URL for expanded view: $e');
        return;
      }
    } else {
      // Check if local file exists
      try {
        final file = File(imageUrl);
        if (!file.existsSync()) {
          debugPrint('Local image file does not exist for expanded view: $imageUrl');
          return;
        }
      } catch (e) {
        debugPrint('Error checking local file for expanded view: $e');
        return;
      }
    }

    final screenSize = MediaQuery.of(context).size;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Fullscreen image
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: screenSize.width,
                height: screenSize.height,
                color: Colors.black.withOpacity(0.9),
                child: Hero(
                  tag: heroTag,
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: imageUrl.startsWith('http')
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.gold,
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('Error loading expanded network image: $error');
                              return Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.broken_image, 
                                      color: Colors.white.withOpacity(0.6), 
                                      size: 64),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Unable to load image',
                                      style: GoogleFonts.outfit(color: Colors.white),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : Image.file(
                            File(imageUrl),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('Error loading expanded file image: $error');
                              return Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.broken_image, 
                                      color: Colors.white.withOpacity(0.6), 
                                      size: 64),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Unable to load image',
                                      style: GoogleFonts.outfit(color: Colors.white),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
            ),

            // Close button
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show error SnackBar for image operations
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(),
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show success SnackBar for image operations
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(),
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
