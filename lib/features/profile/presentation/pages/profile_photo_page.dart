import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/features/profile/presentation/providers/profile_media_provider.dart';
import 'package:hive_ui/features/profile/presentation/providers/profile_providers.dart';
import 'package:hive_ui/features/profile/presentation/widgets/profile_photo_sheet.dart';

/// A page that shows the profile photo picker and handles navigation
class ProfilePhotoPage extends ConsumerStatefulWidget {
  const ProfilePhotoPage({super.key});

  @override
  ConsumerState<ProfilePhotoPage> createState() => _ProfilePhotoPageState();
}

class _ProfilePhotoPageState extends ConsumerState<ProfilePhotoPage> {
  @override
  void initState() {
    super.initState();
    
    // Hide the system UI (including navigation bar) when this page opens
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [SystemUiOverlay.top],
    );
    
    // Show the photo picker after a short delay for smoother transition
    Future.microtask(() {
      showProfilePhotoSheet(
        context, 
        onImageSelected: _handleImageSelected,
      ).then((_) => _navigateBack());
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Return a transparent page that serves as a container for the photo sheet
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.7),
      body: const SizedBox.expand(),
    );
  }
  
  /// Handle when an image is selected
  Future<void> _handleImageSelected(String? imagePath) async {
    if (imagePath != null) {
      try {
        // Get the current profile
        final profileAsync = ref.read(profileProvider);
        final profile = profileAsync.profile;
        
        if (profile != null) {
          // Create file from path and update profile
          await ref.read(profileMediaProvider.notifier).updateProfileImageFromPath(imagePath);
        }
      } catch (e) {
        debugPrint('Error updating profile image: $e');
      }
    }
    
    // Navigate back after handling the image
    _navigateBack();
  }
  
  /// Navigate back to previous page
  void _navigateBack() {
    // Restore UI before navigating back
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    
    // Navigate back if mounted
    if (mounted) {
      context.pop();
    }
  }
  
  @override
  void dispose() {
    // Ensure system UI is restored when leaving the page
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    super.dispose();
  }
} 