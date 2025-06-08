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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/widgets/profile/verification_dialog.dart';

/// A widget that displays the profile header with image, info, and action buttons
class ProfileHeader extends ConsumerWidget {
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

  /// User's first name
  final String firstName;
  
  /// User's last name
  final String lastName;
  
  /// User's class level
  final String? classLevel;
  
  /// User's field of study
  final String? fieldOfStudy;
  
  /// User's residential status
  final String? residentialStatus;
  
  /// User's account tier
  final AccountTier accountTier;
  
  /// User's verification status (Deprecated, use accountTier)
  final VerificationStatus verificationStatus;

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
    required this.firstName,
    required this.lastName,
    this.classLevel,
    this.fieldOfStudy,
    this.residentialStatus,
    this.accountTier = AccountTier.public,
    this.verificationStatus = VerificationStatus.none,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    return SizedBox(
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
                                accountTier: profile.accountTier,
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
                  accountTier: profile.accountTier,
                  onVerifiedPlusTap: isCurrentUser ? () => _showVerificationDialog(context) : onVerifiedPlusTap,
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
              
              // Avatar/Bio Nudge - only show for current user and if missing avatar or bio
              if (isCurrentUser && (profile.profileImageUrl == null || profile.bio == null || profile.bio?.isEmpty == true))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onEditProfile(context, profile);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.gold, width: 1),
                        borderRadius: BorderRadius.circular(20),
                        color: AppColors.gold.withOpacity(0.1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add_photo_alternate,
                            size: 16,
                            color: AppColors.gold,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            profile.profileImageUrl == null
                                ? 'Add profile photo'
                                : profile.bio == null || profile.bio?.isEmpty == true
                                    ? 'Add bio'
                                    : 'Complete profile',
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

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
          Future.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted) {
              _showImagePositioningDialog(context, imagePath);
            }
          });
        }
      },
    );
  }

  /// Show verification dialog when badge is tapped
  void _showVerificationDialog(BuildContext context) {
    showVerificationDialog(
      context,
      currentStatus: verificationStatus,
    );
  }
}
