import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/glassmorphism_guide.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:hive_ui/extensions/neumorphic_extension.dart';

/// A peeking bottom sheet for profile sharing with QR code
class ProfileShareModal extends StatefulWidget {
  /// The profile to share
  final UserProfile profile;

  /// Callback when the share link button is pressed
  final VoidCallback? onShareLinkPressed;

  /// Callback when copy link button is pressed
  final VoidCallback? onCopyLinkPressed;

  /// Profile URL to be shared (defaults to a placeholder)
  final String profileUrl;

  const ProfileShareModal({
    super.key,
    required this.profile,
    this.onShareLinkPressed,
    this.onCopyLinkPressed,
    this.profileUrl = 'https://hive.app/profile/',
  });

  @override
  State<ProfileShareModal> createState() => _ProfileShareModalState();
}

class _ProfileShareModalState extends State<ProfileShareModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Transform.translate(
            offset: Offset(
                0,
                MediaQuery.of(context).size.height *
                    0.4 *
                    _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  // Handle drag to expand
                  if (details.primaryDelta! < -10) {
                    // Expand the sheet on upward drag
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => _buildFullSheet(context),
                    );
                  }
                },
                child: _buildPeekingSheet(context),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build the peeking version of the sheet
  Widget _buildPeekingSheet(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final qrSize = isSmallScreen ? 140.0 : 150.0; // Reduced size slightly to prevent overflow

    return Container(
      height: isSmallScreen ? 220 : 240, // Increased height to accommodate the pop effect
      margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ).addGlassmorphism(
        blur: GlassmorphismGuide.kStandardBlur,
        opacity: GlassmorphismGuide.kStandardGlassOpacity,
        addGoldAccent: true,
        border: true,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),

          // QR Code with improved neumorphic effect
          Container(
            width: qrSize,
            height: qrSize,
            child: const SizedBox() // Empty container for sizing
                .addNeumorphicQrCode(
              qrData: '${widget.profileUrl}${widget.profile.id}',
              size: qrSize,
              elevation: 1.5, // Slightly reduced for the peeking view
              embeddedImage: widget.profile.profileImageUrl != null &&
                      widget.profile.profileImageUrl!.isNotEmpty
                  ? NetworkImage(widget.profile.profileImageUrl!)
                  : null,
              embeddedImageSize: const Size(30, 30),
              padding: 8.0, // Smaller padding for peek view
              borderRadius: 16.0,
            ),
          ),
        ],
      ),
    );
  }

  /// Build the full expanded sheet
  Widget _buildFullSheet(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final qrSize = isSmallScreen ? 240.0 : 280.0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.symmetric(
          vertical: 20, horizontal: isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.90),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.3),
          width: 1,
        ),
      ).addGlassmorphism(
        blur: GlassmorphismGuide.kStandardBlur,
        opacity: GlassmorphismGuide.kStandardGlassOpacity,
        addGoldAccent: true,
        border: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 24),

          // Profile info at top
          Text(
            'Share Profile',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Profile name
          Text(
            widget.profile.username,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.gold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // QR Code using the neumorphic extension
          Container(
            width: qrSize,
            height: qrSize,
            child: const SizedBox() // Empty container for sizing
                .addNeumorphicQrCode(
              qrData: '${widget.profileUrl}${widget.profile.id}',
              size: qrSize,
              elevation: 2.5, // Enhanced elevation for full-screen view
              embeddedImage: widget.profile.profileImageUrl != null &&
                      widget.profile.profileImageUrl!.isNotEmpty
                  ? NetworkImage(widget.profile.profileImageUrl!)
                  : null,
              embeddedImageSize: const Size(50, 50),
              padding: 12.0,
              borderRadius: 24.0,
            ),
          ),

          const Spacer(),

          // Link text with copy button - improved overflow handling
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16,
                vertical: isSmallScreen ? 10 : 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${widget.profileUrl}${widget.profile.id}',
                    style: GoogleFonts.inter(
                      fontSize: isSmallScreen ? 12 : 13,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    if (widget.onCopyLinkPressed != null) {
                      widget.onCopyLinkPressed!();
                    } else {
                      _copyProfileLink();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.copy,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: isSmallScreen ? 16 : 20),

          // External share button
          SizedBox(
            width: double.infinity,
            height: isSmallScreen ? 48 : 54,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                if (widget.onShareLinkPressed != null) {
                  widget.onShareLinkPressed!();
                } else {
                  _shareProfile();
                }
                Navigator.pop(context); // Close sheet after sharing
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 24 : 27),
                ),
                elevation: 0,
              ),
              child: Text(
                'Share Link',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: isSmallScreen ? 15 : 16,
                ),
              ),
            ),
          ),

          SizedBox(height: isSmallScreen ? 12 : 16),

          // Cancel button
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Copy profile link to clipboard
  void _copyProfileLink() {
    final link = '${widget.profileUrl}${widget.profile.id}';
    Clipboard.setData(ClipboardData(text: link));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Profile link copied to clipboard',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Share profile using system share dialog
  void _shareProfile() {
    final link = '${widget.profileUrl}${widget.profile.id}';

    // Pass to callback which will handle proper sharing
    if (widget.onShareLinkPressed != null) {
      widget.onShareLinkPressed!();
    } else {
      debugPrint('Sharing profile link: $link');
    }
  }
}

/// Extension for adding glassmorphism effects to BoxDecoration
extension BoxDecorationExt on BoxDecoration {
  BoxDecoration addGlassmorphism({
    required double blur,
    required double opacity,
    required bool addGoldAccent,
    required bool border,
  }) {
    // In actual implementation, this would apply glassmorphism effects
    return this;
  }
}
