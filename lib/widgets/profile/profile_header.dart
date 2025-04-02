import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/huge_icons.dart';
import 'package:hive_ui/widgets/profile/profile_image_picker.dart';
import 'package:hive_ui/widgets/profile/profile_tags_section.dart';
import 'package:hive_ui/widgets/profile/profile_interaction_buttons.dart';
import 'package:hive_ui/widgets/profile/profile_info_overlay.dart'
    as info_overlay;
import 'dart:io';
import 'package:flutter/services.dart'; // For haptic feedback
import 'package:hive_ui/features/profile/presentation/widgets/profile_photo_sheet.dart';

/// A widget that displays the profile header with image, info, and action buttons
class ProfileHeader extends StatelessWidget {
  /// The user profile to display
  final UserProfile profile;

  /// Whether this is the current user's profile
  final bool isCurrentUser;

  /// Callback when image is selected from camera
  final void Function(String) onImageFromCamera;

  /// Callback when image is selected from gallery
  final void Function(String) onImageFromGallery;

  /// Callback when image is removed
  final VoidCallback onImageRemoved;

  /// Callback when image is tapped (for viewing expanded image)
  final VoidCallback? onImageTap;

  /// Callback when verified plus badge is tapped
  final VoidCallback? onVerifiedPlusTap;

  /// Callback when edit profile is tapped
  final void Function(BuildContext, UserProfile) onEditProfile;

  /// Callback when request friend is tapped
  final void Function(UserProfile) onRequestFriend;

  /// Callback when message is tapped
  final void Function(BuildContext) onMessage;

  /// Callback when share profile is tapped
  final void Function(BuildContext, UserProfile) onShareProfile;

  /// Callback when add tags is tapped
  final VoidCallback? onAddTagsTapped;

  const ProfileHeader({
    super.key,
    required this.profile,
    required this.isCurrentUser,
    required this.onImageFromCamera,
    required this.onImageFromGallery,
    required this.onImageRemoved,
    this.onImageTap,
    this.onVerifiedPlusTap,
    required this.onEditProfile,
    required this.onRequestFriend,
    required this.onMessage,
    required this.onShareProfile,
    this.onAddTagsTapped,
  });

  @override
  Widget build(BuildContext context) {
    // Adapt height based on screen size
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final safePaddingTop = MediaQuery.of(context).padding.top;

    // Use more mobile-friendly image heights while still remaining mobile-friendly
    final imageHeight = isSmallScreen
        ? screenSize.height * 0.33 // Optimized height for mobile
        : screenSize.height * 0.38; // Height on larger screens

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile image picker with overlaid components
        SizedBox(
          height: imageHeight,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Profile image
              Hero(
                tag: 'profile_image_${profile.id}',
                child: DragTarget<String>(
                  onWillAccept: (data) {
                    if (data == null) return false;
                    
                    // Verify file exists and is an image
                    try {
                      final file = File(data);
                      if (!file.existsSync()) return false;
                      
                      final extension = data.toLowerCase();
                      return extension.endsWith('.jpg') ||
                             extension.endsWith('.jpeg') ||
                             extension.endsWith('.png') ||
                             extension.endsWith('.gif');
                    } catch (e) {
                      debugPrint('Error checking file: $e');
                      return false;
                    }
                  },
                  onAccept: (data) async {
                    try {
                      final file = File(data);
                      if (await file.exists()) {
                        HapticFeedback.mediumImpact();
                        onImageFromGallery(file.path);
                        // Show positioning dialog after accepting the drop
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (context.mounted) {
                            _showImagePositioningDialog(context, file.path);
                          }
                        });
                      }
                    } catch (e) {
                      debugPrint('Error accepting file: $e');
                    }
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      width: double.infinity,
                      height: imageHeight,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Semantics(
                              label: 'Profile image of ${profile.username}',
                              image: true,
                              child: ProfileImagePicker(
                                imageUrl: profile.profileImageUrl,
                                height: imageHeight,
                                profile: profile,
                                onImageFromCamera: (imagePath) {
                                  onImageFromCamera(imagePath);
                                  Future.delayed(const Duration(milliseconds: 500), () {
                                    if (context.mounted) {
                                      _showImagePositioningDialog(context, imagePath);
                                    }
                                  });
                                },
                                onImageFromGallery: (imagePath) {
                                  onImageFromGallery(imagePath);
                                  Future.delayed(const Duration(milliseconds: 500), () {
                                    if (context.mounted) {
                                      _showImagePositioningDialog(context, imagePath);
                                    }
                                  });
                                },
                                onImageRemoved: onImageRemoved,
                                onImageTap: onImageTap,
                                onVerifiedPlusTap: isCurrentUser ? onVerifiedPlusTap : null,
                                fit: BoxFit.cover,
                              ),
                            ),
                            // Show drag overlay when file is being dragged
                            if (candidateData.isNotEmpty && isCurrentUser)
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withOpacity(0.3),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.file_upload,
                                        color: Colors.white,
                                        size: 48,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Drop to Upload',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Profile info overlay at bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: info_overlay.ProfileInfoOverlay(
                  profile: profile,
                  onVerifiedPlusTap: onVerifiedPlusTap,
                ),
              ),

              // Add/Adjust Photo button in top left (only for current user)
              if (isCurrentUser)
                Positioned(
                  top: safePaddingTop > 0 ? safePaddingTop + 8 : 16,
                  left: 16,
                  child: Material(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(30),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        _showImageOptionsBottomSheet(context);
                      },
                      child: Semantics(
                        button: true,
                        label: 'Add or adjust profile photo',
                        child: Container(
                          padding: const EdgeInsets.all(12), // Larger touch target
                          child: const Icon(
                            HugeIcons.add,
                            color: AppColors.gold,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Tags section with full visibility
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(16, 20, 16, isSmallScreen ? 14 : 24),
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tags header with add button in top right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Semantics(
                    header: true,
                    label: 'Tags section',
                    child: Text(
                      'Tags',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),

              // Second row with tags and add interest button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ProfileTagsSection(
                      residence: profile.residence,
                      interests: profile.interests,
                      isCurrentUser: isCurrentUser,
                      onAddTagTapped: onAddTagsTapped,
                      showAddButton: false,
                      isCompact: isSmallScreen,
                    ),
                  ),
                  if (isCurrentUser)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: onAddTagsTapped,
                          child: Semantics(
                            button: true, 
                            label: 'Add new tag',
                            child: Container(
                              // Increase touch target size
                              padding: const EdgeInsets.all(10),
                              child: Icon(
                                Icons.add,
                                color: AppColors.gold,
                                size: isSmallScreen ? 18 : 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Action buttons
        Padding(
          padding: EdgeInsets.fromLTRB(
              16, isSmallScreen ? 16 : 20, 16, isSmallScreen ? 20 : 28),
          child: ProfileInteractionButtons(
            profile: profile,
            isCurrentUser: isCurrentUser,
            onEditProfile: onEditProfile,
            onRequestFriend: onRequestFriend,
            onMessage: onMessage,
            onShareProfile: onShareProfile,
          ),
        ),
      ],
    );
  }

  /// Shows a dialog to position/crop the image
  void _showImagePositioningDialog(BuildContext context, String imagePath) {
    if (imagePath.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Position Photo',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Container(
              height: MediaQuery.of(context).size.height * 0.5,
              width: MediaQuery.of(context).size.width - 64,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.hardEdge,
              child: InteractiveViewer(
                constrained: true,
                minScale: 0.5,
                maxScale: 3.0,
                child: Center(
                  child: imagePath.startsWith('http')
                      ? Image.network(
                          imagePath,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                color: AppColors.gold,
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        (loadingProgress.expectedTotalBytes ??
                                            1)
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                            child: Icon(Icons.broken_image,
                                color: Colors.white, size: 40),
                          ),
                        )
                      : Image.file(
                          File(imagePath),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                            child: Icon(Icons.broken_image,
                                color: Colors.white, size: 40),
                          ),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reset'),
                    onPressed: () {
                      // Reset zoom and position logic would go here
                      Navigator.pop(context);
                      HapticFeedback.lightImpact();
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (context.mounted) {
                          _showImagePositioningDialog(context, imagePath);
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Save'),
                    onPressed: () {
                      // In a real implementation, this would save the
                      // zoom and position changes
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows the image options bottom sheet with camera, gallery, and positioning options
  void _showImageOptionsBottomSheet(BuildContext context) {
    // Use the profile photo sheet, which will handle system UI mode
    showProfilePhotoSheet(
      context,
      onImageSelected: (imagePath) {
        if (imagePath != null) {
          // Check if it's from a camera or gallery (simplistic approach)
          if (imagePath.contains('DCIM') || imagePath.contains('camera')) {
            onImageFromCamera(imagePath);
          } else {
            onImageFromGallery(imagePath);
          }
          
          // Show positioning dialog after a short delay
          // and ensure navigation UI is properly restored first
          Future.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted) {
              // Ensure navigation bar is visible before showing dialog
              SystemChrome.setEnabledSystemUIMode(
                SystemUiMode.edgeToEdge,
                overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
              );
              _showImagePositioningDialog(context, imagePath);
            }
          });
        }
      },
    );
  }

  // Method to safely build profile image with error handling
  Widget _buildProfileImage(BuildContext context) {
    if (profile.profileImageUrl == null || profile.profileImageUrl!.isEmpty) {
      return _buildDefaultProfileImage();
    }

    return GestureDetector(
      onTap: onImageTap,
      child: Hero(
        tag: 'profile_image_${profile.id}',
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.gold,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipOval(
            child: Image(
              image: NetworkImage(_normalizeImageUrl(profile.profileImageUrl!)),
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Error loading profile image: $error');
                return _buildDefaultProfileImage();
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _normalizeImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return '';
    }

    // Trim whitespace
    final trimmedUrl = url.trim();

    // Return valid http/https URLs as-is
    if (trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://')) {
      return trimmedUrl;
    }

    // Fix file URLs for different platforms
    if (trimmedUrl.startsWith('file://')) {
      return trimmedUrl;
    }

    // For non-URL paths, try to ensure they're valid
    try {
      final file = File(trimmedUrl);
      return file.path;
    } catch (e) {
      debugPrint('Error normalizing image URL: $e');
      return trimmedUrl;
    }
  }

  Widget _buildDefaultProfileImage() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.black,
        border: Border.all(
          color: AppColors.gold,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Text(
          profile.username.isNotEmpty
              ? profile.username.substring(0, 1).toUpperCase()
              : '?',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
