import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/profile/presentation/providers/profile_media_provider.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/utils/profile_image_handler.dart';

/// A modal sheet for adding or changing a profile photo
class ProfilePhotoSheet extends ConsumerWidget {
  /// Callback for when an image has been selected
  final Function(String?)? onImageSelected;

  const ProfilePhotoSheet({
    super.key,
    this.onImageSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.black,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with close button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
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
                        onPressed: () {
                          // Restore navigation bar before closing
                          _restoreNavigationBar();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Take new photo button
                _buildOptionButton(
                  icon: Icons.camera_alt,
                  label: 'Take New Photo', 
                  onTap: () => _handleTakePhoto(context, ref),
                ),
                
                const SizedBox(height: 16),
                
                // Choose from gallery button
                _buildOptionButton(
                  icon: Icons.photo_library,
                  label: 'Choose from Gallery',
                  onTap: () => _handleChooseGallery(context, ref),
                ),
                
                // Add padding at bottom for safe area
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          ),
          // Add extra black space to ensure coverage of navigation bar
          Container(
            color: Colors.black,
            height: 100, // Extra height to ensure coverage
          ),
        ],
      ),
    );
  }
  
  /// Build an option button
  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.gold.withOpacity(0.5),
              width: 1,
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
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Handle taking a photo from camera
  Future<void> _handleTakePhoto(BuildContext context, WidgetRef ref) async {
    // Restore navigation bar before accessing camera
    _restoreNavigationBar();
    
    // Close the dialog
    Navigator.pop(context);
    
    // Get image from camera
    final imagePath = await ProfileImageHandler.getImageFromCamera();
    
    if (imagePath != null) {
      if (onImageSelected != null) {
        onImageSelected!(imagePath);
      } else {
        // Use the provider to update profile image
        await ref.read(profileMediaProvider.notifier).updateProfileImageFromCamera();
      }
    }
  }
  
  /// Handle choosing photo from gallery
  Future<void> _handleChooseGallery(BuildContext context, WidgetRef ref) async {
    // Restore navigation bar before accessing gallery
    _restoreNavigationBar();
    
    // Close the dialog
    Navigator.pop(context);
    
    // Get image from gallery
    final imagePath = await ProfileImageHandler.getImageFromGallery();
    
    if (imagePath != null) {
      if (onImageSelected != null) {
        onImageSelected!(imagePath);
      } else {
        // Use the provider to update profile image
        await ref.read(profileMediaProvider.notifier).updateProfileImageFromGallery();
      }
    }
  }
  
  /// Restore the navigation bar
  void _restoreNavigationBar() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
  }
}

/// Show the profile photo sheet modal
Future<void> showProfilePhotoSheet(
  BuildContext context, {
  Function(String?)? onImageSelected,
}) async {
  // Use haptic feedback for better UX
  HapticFeedback.mediumImpact();
  
  // Completely hide system UI including navigation bar
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [], // Explicitly specify no overlays to ensure navigation bar is hidden
  );
  
  // Show modal bottom sheet
  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    barrierColor: Colors.black.withOpacity(0.5),
    useSafeArea: false, // Don't use safe area to allow full extension
    builder: (context) => Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: ProfilePhotoSheet(
          onImageSelected: onImageSelected,
        ),
      ),
    ),
  ).then((_) {
    // Ensure navigation bar is restored when sheet is dismissed
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
  });
} 