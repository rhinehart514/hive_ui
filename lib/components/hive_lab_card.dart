import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_theme.dart';
import '../extensions/neumorphic_extension.dart';

/// A card component for HIVE Lab - for user-generated content and feature requests
class HiveLabCard extends ConsumerStatefulWidget {
  /// Title of the featured request or content
  final String title;

  /// Brief description
  final String description;

  /// Called when the user taps the primary action button
  final VoidCallback? onPrimaryAction;

  /// Label for primary action button
  final String primaryActionLabel;

  /// Called when the card is tapped
  final VoidCallback? onTap;

  /// Called when user wants to suggest a feature
  final VoidCallback? onSuggestFeature;

  /// Constructor
  const HiveLabCard({
    super.key,
    required this.title,
    required this.description,
    this.onPrimaryAction,
    this.primaryActionLabel = 'Join Lab',
    this.onTap,
    this.onSuggestFeature,
  });

  @override
  ConsumerState<HiveLabCard> createState() => _HiveLabCardState();
}

class _HiveLabCardState extends ConsumerState<HiveLabCard>
    with SingleTickerProviderStateMixin {
  // Animation controller for smooth animations
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Track if the card is being pressed
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
          _animationController.forward();
        });
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
          _animationController.reverse();
        });
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
          _animationController.reverse();
        });
      },
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap?.call();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: _buildCardContent().addNeumorphism(
            backgroundColor: const Color(0xFF111111), // Slightly lighter for lab card
            borderRadius: 16.0,
            depth: 6.0, // Deep effect for lab cards
            intensity: 0.16, // Higher intensity for lab cards
            isPressed: _isPressed,
            hasBorder: true,
            lightSource: Alignment.topLeft,
          ),
        ),
      ),
    );
  }

  /// Build the card content
  Widget _buildCardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with lab icon
        _buildLabHeader(),

        // Main content
        _buildContent(),

        // Action buttons
        _buildActionButtons(),
      ],
    );
  }

  /// Build the header with lab icon and title
  Widget _buildLabHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.gold.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Lab icon with subtle glow
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.black,
              border: Border.all(
                color: AppColors.gold,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.science_outlined,
                color: AppColors.gold,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // HIVE Lab text
          Text(
            'HIVE LAB',
            style: AppTheme.titleMedium.copyWith(
              color: AppColors.gold,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),

          const Spacer(),

          // Experimental badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppColors.gold.withOpacity(0.3),
                width: 0.5,
              ),
            ),
            child: Text(
              'EXPERIMENTAL',
              style: AppTheme.bodySmall.copyWith(
                color: AppColors.gold,
                fontWeight: FontWeight.w500,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the main content section
  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with special heading style
          Text(
            widget.title,
            style: AppTheme.titleMedium.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            widget.description,
            style: AppTheme.bodyMedium.copyWith(
              color: AppColors.white.withOpacity(0.8),
            ),
          ),

          // Extra content indicators (dots)
          const SizedBox(height: 16),
          Row(
            children: [
              ...List.generate(
                5,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < 3
                        ? AppColors.gold.withOpacity(0.3 + (index * 0.2))
                        : AppColors.white.withOpacity(0.1),
                  ),
                ),
              ),
              const Spacer(),

              // Create button
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add_circle_outline,
                    color: AppColors.gold,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Suggest Feature',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ).addNeumorphicSecondaryButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  widget.onSuggestFeature?.call();
                },
                borderRadius: 8,
                outlineColor: AppColors.gold,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build action buttons
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Text(
        widget.primaryActionLabel,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.black,
        ),
        textAlign: TextAlign.center,
      ).addNeumorphicPrimaryButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          widget.onPrimaryAction?.call();
        },
        borderRadius: 8,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }
}
