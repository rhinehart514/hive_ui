import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A premium top bar component for HIVE that follows the brand aesthetic guidelines
/// Implements glassmorphism effect, proper typography, and spacing according to design tokens
class PremiumTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// Title to display in the top bar
  final String? title;
  
  /// Optional subtitle text
  final String? subtitle;
  
  /// Whether to center the title
  final bool centerTitle;
  
  /// Whether to use the logo instead of text title
  final bool useLogo;
  
  /// Actions to display on the right side
  final List<Widget>? actions;
  
  /// Whether to show a back button
  final bool showBackButton;
  
  /// Custom back button handler
  final VoidCallback? onBackPressed;
  
  /// Blur intensity (follows blur-md token by default)
  final double blurSigma;
  
  /// Background opacity (follows stylistic system)
  final double backgroundOpacity;
  
  /// Bottom content to display (such as tabs)
  final PreferredSizeWidget? bottom;

  const PremiumTopBar({
    Key? key,
    this.title,
    this.subtitle,
    this.centerTitle = true,
    this.useLogo = true,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
    this.blurSigma = 30.0, // blur-md token
    this.backgroundOpacity = 0.75, // stylistic system value
    this.bottom,
  }) : super(key: key);

  @override
  Size get preferredSize {
    final double height = kToolbarHeight + 
        (subtitle != null ? 16.0 : 0) + 
        (bottom?.preferredSize.height ?? 0);
    return Size.fromHeight(height);
  }

  @override
  Widget build(BuildContext context) {
    // Configure system UI overlay style for status bar integration
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
    
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          color: AppColors.dark.withOpacity(backgroundOpacity),
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Main app bar content
                SizedBox(
                  height: kToolbarHeight + (subtitle != null ? 16.0 : 0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0), // spacing-md token
                    child: _buildAppBarContent(context),
                  ),
                ),
                
                // Bottom content if provided
                if (bottom != null) bottom!,
                
                // Subtle divider
                Container(
                  height: 0.5,
                  color: Colors.white.withOpacity(0.1), // Decorative border at 10% opacity
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Builds the main app bar content with title and actions
  Widget _buildAppBarContent(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Leading section (back button or empty space)
        if (showBackButton)
          _buildBackButton(context)
        else
          const SizedBox(width: 48.0), // Reserve space for alignment when no back button

        // Title section
        Expanded(
          child: _buildTitleSection(),
        ),

        // Actions section
        Row(
          mainAxisSize: MainAxisSize.min,
          children: actions ?? [const SizedBox(width: 48.0)],
        ),
      ],
    );
  }
  
  /// Builds the back button with proper styling
  Widget _buildBackButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      splashRadius: 24.0,
      onPressed: () {
        // Provide haptic feedback for better UX
        HapticFeedback.lightImpact();
        
        if (onBackPressed != null) {
          onBackPressed!();
        } else {
          Navigator.maybePop(context);
        }
      },
    );
  }
  
  /// Builds the title section with logo or text
  Widget _buildTitleSection() {
    if (useLogo) {
      return Center(
        child: Text(
          'HIVE',
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: AppColors.gold, // Accent color used sparingly for the logo
            letterSpacing: 1.5,
          ),
        ),
      );
    } else if (title != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(
            title!,
            style: GoogleFonts.inter(
              fontSize: 20, // H3 from typography scale
              fontWeight: FontWeight.w600,
              color: Colors.white, // Text Primary color
              letterSpacing: 0.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: centerTitle ? TextAlign.center : TextAlign.start,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: GoogleFonts.inter(
                fontSize: 14, // Body text size
                fontWeight: FontWeight.w400,
                color: const Color(0xFFB0B0B0), // Text Secondary color
                letterSpacing: 0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: centerTitle ? TextAlign.center : TextAlign.start,
            ),
          ],
        ],
      );
    }
    
    return const SizedBox(); // Empty if no title or logo
  }
} 