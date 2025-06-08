import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A badge that displays the verification status of a user
class VerificationBadge extends StatelessWidget {
  /// The verification status to display
  final VerificationStatus status;
  
  /// Whether to show the label
  final bool showLabel;
  
  /// Size of the badge
  final double size;
  
  /// Callback when tapped
  final VoidCallback? onTap;
  
  /// Constructor
  const VerificationBadge({
    Key? key,
    required this.status,
    this.showLabel = true,
    this.size = 20.0,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // If status is none, don't show anything
    if (status == VerificationStatus.none) {
      return const SizedBox.shrink();
    }
    
    // Setup colors and icons based on status
    final Color badgeColor = status == VerificationStatus.verifiedPlus
        ? AppColors.gold
        : Colors.lightBlueAccent;
    
    final IconData badgeIcon = status == VerificationStatus.verifiedPlus
        ? Icons.verified
        : Icons.check_circle;
    
    final String badgeLabel = status == VerificationStatus.verifiedPlus
        ? "Verified+"
        : "Verified";

    // Build the badge widget
    return InkWell(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.selectionClick();
          onTap!();
        }
      },
      customBorder: const CircleBorder(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            size: size,
            color: badgeColor,
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              badgeLabel,
              style: GoogleFonts.inter(
                fontSize: size * 0.7,
                fontWeight: FontWeight.w500,
                color: badgeColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
} 