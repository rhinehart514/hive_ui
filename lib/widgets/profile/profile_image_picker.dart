import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/widgets/profile/profile_info_overlay.dart'
    as info_overlay;
import 'package:cached_network_image/cached_network_image.dart';

/// A widget that handles selecting, displaying, and removing profile images
class ProfileImagePicker extends StatelessWidget {
  /// The current image URL/path, if any
  final String? imageUrl;

  /// Callback when a new image is selected from camera
  final void Function(String imagePath) onImageFromCamera;

  /// Callback when a new image is selected from gallery
  final void Function(String imagePath) onImageFromGallery;

  /// Callback when image is removed
  final VoidCallback onImageRemoved;

  /// Callback when image is tapped (for viewing expanded image)
  final VoidCallback? onImageTap;

  /// Callback when verified plus badge is tapped
  final VoidCallback? onVerifiedPlusTap;

  /// Height of the profile image container
  final double height;

  /// Width of the profile image container (default: double.infinity)
  final double? width;

  /// How the image should be fitted in its container
  final BoxFit fit;

  /// User profile data for displaying name and info
  final UserProfile? profile;

  const ProfileImagePicker({
    super.key,
    this.imageUrl,
    required this.onImageFromCamera,
    required this.onImageFromGallery,
    required this.onImageRemoved,
    this.onImageTap,
    this.onVerifiedPlusTap,
    this.height = 300.0,
    this.width,
    this.fit = BoxFit.cover,
    this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onImageTap,
          child: Container(
            height: height,
            width: width ?? double.infinity,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildProfileImage(),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.camera_alt,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        if (onImageTap != null)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onImageTap,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.0),
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (profile != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: info_overlay.ProfileInfoOverlay(
              profile: profile!,
              onVerifiedPlusTap: onVerifiedPlusTap,
            ),
          ),
      ],
    );
  }

  Widget _buildProfileImage() {
    // Handle null or empty image URL
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    // Validate URL for network images
    if (imageUrl!.startsWith('http')) {
      try {
        // Try to parse the URL to validate it
        final uri = Uri.parse(imageUrl!);
        if (!uri.hasScheme || !uri.hasAuthority) {
          debugPrint('Invalid image URL format in ProfileImagePicker: $imageUrl');
          return _buildPlaceholder();
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: imageUrl!,
            fit: fit,
            placeholder: (context, url) => _buildLoadingIndicator(),
            errorWidget: (context, url, error) {
              debugPrint('Error loading profile image: $error');
              return _buildPlaceholder();
            },
            // Add advanced caching options
            memCacheWidth: 500, // Limit memory cache size
            memCacheHeight: 500,
            cacheKey: 'profile_${imageUrl!.hashCode}', // Use a stable cache key
          ),
        );
      } catch (e) {
        debugPrint('Error parsing image URL in ProfileImagePicker: $e');
        return _buildPlaceholder();
      }
    }

    // Handle local file paths
    try {
      final file = File(imageUrl!);
      if (!file.existsSync()) {
        debugPrint('Local file does not exist: $imageUrl');
        return _buildPlaceholder();
      }
      
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          file,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error loading local profile image: $error');
            return _buildPlaceholder();
          },
        ),
      );
    } catch (e) {
      debugPrint('Error handling local profile image: $e');
      return _buildPlaceholder();
    }
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.gold,
        strokeWidth: 2,
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person,
              size: height * 0.25,
              color: Colors.white.withOpacity(0.7),
            ),
            const SizedBox(height: 8),
            Text(
              'Add Photo',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows image positioning options dialog
  void _showPositioningDialog(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      // If no image, show image selection options instead
      _showImageSelectionOptions(context);
      return;
    }

    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'Photo Options',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Adjust position/zoom option
              _buildActionButton(
                context,
                icon: Icons.crop,
                label: 'Adjust Position',
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              const SizedBox(height: 16),

              // Change photo from camera
              _buildActionButton(
                context,
                icon: Icons.camera_alt,
                label: 'Take New Photo',
                onTap: () => _pickImageFromCamera(context),
              ),

              const SizedBox(height: 16),

              // Change photo from gallery
              _buildActionButton(
                context,
                icon: Icons.photo_library,
                label: 'Choose from Gallery',
                onTap: () => _pickImageFromGallery(context),
              ),

              const SizedBox(height: 16),

              // Remove photo
              _buildActionButton(
                context,
                icon: Icons.delete_outline,
                label: 'Remove Photo',
                color: Colors.red.shade400,
                onTap: () {
                  onImageRemoved();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show options to change profile image
  void _showImageSelectionOptions(BuildContext context) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'Add Profile Photo',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Change photo from camera
              _buildActionButton(
                context,
                icon: Icons.camera_alt,
                label: 'Take New Photo',
                onTap: () => _pickImageFromCamera(context),
              ),

              const SizedBox(height: 16),

              // Change photo from gallery
              _buildActionButton(
                context,
                icon: Icons.photo_library,
                label: 'Choose from Gallery',
                onTap: () => _pickImageFromGallery(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Pick an image from the camera
  void _pickImageFromCamera(BuildContext context) {
    Navigator.pop(context);
    _getImageFromCamera();
  }

  /// Pick an image from the gallery
  void _pickImageFromGallery(BuildContext context) {
    Navigator.pop(context);
    _getImageFromGallery();
  }

  /// Build an action button for the options menu
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: color ?? AppColors.gold,
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color ?? Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Launch a screen to position/crop the image
  void _launchPositioningScreen(BuildContext context) {
    // Positioning functionality is now handled by the parent component
    Navigator.pop(context);
  }

  // Get image from camera with quality settings
  Future<void> _getImageFromCamera() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image != null) {
        onImageFromCamera(image.path);
      }
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
    }
  }

  // Get image from gallery with quality settings
  Future<void> _getImageFromGallery() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        onImageFromGallery(image.path);
      }
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
    }
  }
}
