import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/huge_icons.dart';

/// Determines the type of profile card to display
enum ProfileCardType {
  primary,
  social,
  secondary,
  achievement,
  activity,
  main,
}

/// A reusable profile card component with glassmorphism styling
class ProfileCard extends StatelessWidget {
  final Widget child;
  final ProfileCardType type;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final bool addGoldAccent;
  final VoidCallback? onTap;
  final bool showBorder;
  final double? height;
  final double? width;

  const ProfileCard({
    super.key,
    required this.child,
    this.type = ProfileCardType.primary,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.addGoldAccent = false,
    this.onTap,
    this.showBorder = true,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    BoxDecoration decoration;

    switch (type) {
      case ProfileCardType.primary:
        decoration = BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        );
        break;
      case ProfileCardType.social:
        decoration = BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        );
        break;
      case ProfileCardType.achievement:
        decoration = BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        );
        break;
      case ProfileCardType.secondary:
        decoration = BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
        );
        break;
      case ProfileCardType.activity:
        decoration = BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        );
        break;
      case ProfileCardType.main:
        decoration = BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        );
        break;
    }

    return Container(
      margin: margin,
      decoration: decoration,
      padding: padding,
      child: child,
    );
  }
}

/// A specialized profile card for displaying an activity item
class ProfileActivityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String timeAgo;
  final IconData iconData;
  final Color iconColor;
  final VoidCallback? onTap;
  final String id;

  const ProfileActivityCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    required this.iconData,
    required this.iconColor,
    required this.id,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'activity-$id',
      child: Material(
        color: Colors.transparent,
        child: ProfileCard(
          type: ProfileCardType.secondary,
          padding: EdgeInsets.zero,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Activity icon with enhanced neumorphic effect
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 200),
                  tween: Tween<double>(begin: 0.8, end: 1.0),
                  builder: (context, value, child) => Transform.scale(
                    scale: value,
                    child: child,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: iconColor.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          spreadRadius: 0,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      iconData,
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Activity details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),

                // Timestamp
                Text(
                  timeAgo,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A specialized profile card for displaying interest tags
class ProfileInterestTag extends StatelessWidget {
  final String interest;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool isAddButton;

  const ProfileInterestTag({
    super.key,
    required this.interest,
    this.isSelected = true,
    this.onTap,
    this.isAddButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.selectionClick();
          onTap!();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isAddButton
              ? Colors.grey[800]!.withOpacity(0.3)
              : isSelected
                  ? AppColors.gold.withOpacity(0.1)
                  : Colors.grey[800]!.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isAddButton
                ? Colors.grey.withOpacity(0.3)
                : isSelected
                    ? AppColors.gold.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: isAddButton
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Add',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            : Text(
                interest,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isSelected ? AppColors.gold : Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }
}

/// A specialized profile card for empty states
class ProfileEmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onActionPressed;
  final String? actionLabel;

  const ProfileEmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.onActionPressed,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileCard(
      type: ProfileCardType.primary,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[850]!.withOpacity(0.3),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.05),
                    blurRadius: 15,
                    spreadRadius: -5,
                    offset: const Offset(-5, -5),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(5, 5),
                  ),
                  BoxShadow(
                    color: AppColors.gold.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: -5,
                  ),
                ],
                gradient: RadialGradient(
                  colors: [
                    Colors.grey[800]!.withOpacity(0.5),
                    Colors.grey[900]!.withOpacity(0.3),
                  ],
                  stops: const [0.3, 1.0],
                ),
              ),
              child: HugeIcon(
                icon: icon,
                color: Colors.white.withOpacity(0.7),
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            if (onActionPressed != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  onActionPressed!();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  actionLabel!,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
