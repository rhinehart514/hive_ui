import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/utils/profile_image_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/shell.dart';

/// A modal dialog that displays options for adding a profile photo
class ProfilePhotoPicker extends StatelessWidget {
  /// Callback when a new image is selected from camera
  final void Function(String imagePath)? onImageSelected;

  /// Whether to show the close button
  final bool showCloseButton;

  /// Reference to the ProviderContainer (optional)
  final ProviderContainer? container;

  const ProfilePhotoPicker({
    super.key,
    this.onImageSelected,
    this.showCloseButton = true,
    this.container,
  });

  @override
  Widget build(BuildContext context) {
    // Configure UI overlay to hide navigation bar
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [SystemUiOverlay.top],
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                if (showCloseButton)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      // Restore navigation bar visibility
                      if (container != null) {
                        container!.read(navigationBarVisibilityProvider.notifier).state = true;
                      }
                      
                      // Restore UI overlay when closing
                      SystemChrome.setEnabledSystemUIMode(
                        SystemUiMode.edgeToEdge,
                        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
                      );
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Take new photo button
          _buildActionButton(
            context,
            icon: Icons.camera_alt,
            label: 'Take New Photo',
            onTap: () => _handleTakePhoto(context),
          ),
          
          const SizedBox(height: 16),
          
          // Choose from gallery button
          _buildActionButton(
            context,
            icon: Icons.photo_library,
            label: 'Choose from Gallery',
            onTap: () => _handleChooseGallery(context),
          ),
          
          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  /// Build an action button
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
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
    );
  }

  /// Handle taking a new photo
  Future<void> _handleTakePhoto(BuildContext context) async {
    // Restore navigation bar visibility
    if (container != null) {
      container!.read(navigationBarVisibilityProvider.notifier).state = true;
    }
    
    // Restore UI overlay before opening camera
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    
    // Close the dialog first
    Navigator.pop(context);

    // Get image from camera
    final imagePath = await ProfileImageHandler.getImageFromCamera();
    
    if (imagePath != null && onImageSelected != null) {
      onImageSelected!(imagePath);
    }
  }

  /// Handle choosing from gallery
  Future<void> _handleChooseGallery(BuildContext context) async {
    // Restore navigation bar visibility
    if (container != null) {
      container!.read(navigationBarVisibilityProvider.notifier).state = true;
    }
    
    // Restore UI overlay before opening gallery
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    
    // Close the dialog first
    Navigator.pop(context);

    // Get image from gallery
    final imagePath = await ProfileImageHandler.getImageFromGallery();
    
    if (imagePath != null && onImageSelected != null) {
      onImageSelected!(imagePath);
    }
  }
}

/// Show the profile photo picker dialog
void showProfilePhotoPicker(
  BuildContext context, {
  void Function(String)? onImageSelected,
}) {
  HapticFeedback.mediumImpact();
  
  // Find the ProviderContainer in the widget tree
  ProviderContainer? container;
  try {
    final scope = context.findAncestorWidgetOfExactType<UncontrolledProviderScope>();
    if (scope != null) {
      container = scope.container;
      // Hide navigation bar
      container.read(navigationBarVisibilityProvider.notifier).state = false;
    }
  } catch (e) {
    debugPrint('Error finding ProviderContainer: $e');
  }
  
  // Hide the navigation bar
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [SystemUiOverlay.top],
  );

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => ProfilePhotoPicker(
      onImageSelected: onImageSelected,
      container: container,
    ),
  ).then((_) {
    // Restore navigation bar
    if (container != null) {
      container.read(navigationBarVisibilityProvider.notifier).state = true;
    }
    
    // Restore system UI when dialog is closed
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
  });
} 