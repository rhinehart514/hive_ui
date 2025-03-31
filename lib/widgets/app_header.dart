import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/huge_icons.dart';
import 'package:hive_ui/extensions/glassmorphism_extension.dart';
import 'package:hive_ui/theme/glassmorphism_guide.dart';

/// A consistent header widget to be used throughout the app with glassmorphism styling
/// Enhanced with smooth animations and improved haptic feedback for frictionless UX
class AppHeader extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showBackButton;
  final bool showMessageButton;
  final bool showSettingsButton;
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;
  final VoidCallback? onBackPressed;
  final VoidCallback? onMessagePressed;
  final VoidCallback? onSettingsPressed;
  final Widget? leadingIcon;
  final List<Widget>? actions;
  final bool useGlassmorphism;
  final bool elevated;
  final Widget? trailing;
  final bool showBottomBorder;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = true,
    this.showMessageButton = true,
    this.showSettingsButton = false,
    this.backgroundColor = Colors.black,
    this.textColor = Colors.white,
    this.iconColor = Colors.white,
    this.onBackPressed,
    this.onMessagePressed,
    this.onSettingsPressed,
    this.leadingIcon,
    this.actions,
    this.useGlassmorphism = true,
    this.elevated = false,
    this.trailing,
    this.showBottomBorder = false,
  });

  @override
  State<AppHeader> createState() => _AppHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AppHeaderState extends State<AppHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      backgroundColor:
          widget.useGlassmorphism ? Colors.transparent : widget.backgroundColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: widget.showBackButton ? _buildBackButton() : null,
      title: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildTitle(),
      ),
      actions: widget.actions ?? _buildDefaultActions(),
      bottom: widget.showBottomBorder
          ? PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 0.5,
                color: Colors.white.withOpacity(0.1),
              ),
            )
          : null,
    );

    if (!widget.useGlassmorphism) {
      return appBar;
    }

    // Apply glassmorphism effect to the AppBar
    return Container(
      decoration: widget.showBottomBorder
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
            )
          : null,
      child: appBar.addHeaderGlassmorphism(
        opacity: widget.elevated
            ? GlassmorphismGuide.kCardGlassOpacity
            : GlassmorphismGuide.kStandardGlassOpacity,
      ),
    );
  }

  Widget _buildBackButton() {
    return IconButton(
      icon: widget.leadingIcon ??
          Icon(
            Icons.arrow_back_ios,
            color: widget.iconColor,
            size: 20,
          ),
      onPressed: () {
        // Enhanced haptic feedback for more natural feel
        HapticFeedback.lightImpact();

        // Allow custom back behavior or default pop
        if (widget.onBackPressed != null) {
          widget.onBackPressed!();
        } else {
          Navigator.pop(context);
        }
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.white.withOpacity(0.1),
    );
  }

  Widget _buildTitle() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title,
          style: GoogleFonts.outfit(
            color: widget.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        if (widget.subtitle != null)
          Text(
            widget.subtitle!,
            style: GoogleFonts.outfit(
              color: widget.textColor.withOpacity(0.7),
              fontWeight: FontWeight.w400,
              fontSize: 13,
            ),
          ),
      ],
    );
  }

  List<Widget> _buildDefaultActions() {
    final List<Widget> defaultActions = [];

    if (widget.trailing != null) {
      defaultActions.add(widget.trailing!);
      return defaultActions;
    }

    if (widget.showSettingsButton) {
      defaultActions.add(
        IconButton(
          icon: Icon(
            HugeIcons.settings,
            color: widget.iconColor,
          ),
          onPressed: widget.onSettingsPressed ??
              () {
                HapticFeedback.lightImpact();
              },
          splashColor: Colors.transparent,
          highlightColor: Colors.white.withOpacity(0.1),
        ),
      );
    }

    if (widget.showMessageButton) {
      defaultActions.add(
        IconButton(
          icon: Icon(
            HugeIcons.strokeRoundedMessageLock01,
            color: widget.iconColor,
          ),
          onPressed: widget.onMessagePressed ??
              () {
                HapticFeedback.lightImpact();
              },
          splashColor: Colors.transparent,
          highlightColor: Colors.white.withOpacity(0.1),
        ),
      );
    }

    return defaultActions;
  }
}
