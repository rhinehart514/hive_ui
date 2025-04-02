import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:hive_ui/theme/app_colors.dart';
import '../../../../theme/huge_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/routes.dart';

/// A premium app bar for the profile section that follows HIVE's brand aesthetic
/// Maintains consistency with app bars in feed and spaces sections
class ProfileAppBar extends StatefulWidget implements PreferredSizeWidget {
  /// Whether the app bar should be in its expanded state
  final bool isExpanded;
  
  /// Scroll controller to detect scroll changes
  final ScrollController scrollController;

  /// Called when the settings icon is tapped
  final VoidCallback? onSettingsTap;

  /// Constructor
  const ProfileAppBar({
    Key? key,
    this.isExpanded = true,
    required this.scrollController,
    this.onSettingsTap,
  }) : super(key: key);

  @override
  State<ProfileAppBar> createState() => _ProfileAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _ProfileAppBarState extends State<ProfileAppBar> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<double> _elevationAnimation;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuint,
    ));

    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    widget.scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (widget.scrollController.offset > 10 && !_isScrolled) {
      setState(() {
        _isScrolled = true;
      });
      _animationController.forward();
    } else if (widget.scrollController.offset <= 10 && _isScrolled) {
      setState(() {
        _isScrolled = false;
      });
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_scrollListener);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.black,
            boxShadow: [
              if (_isScrolled)
                BoxShadow(
                  color: Colors.black.withOpacity(_elevationAnimation.value * 0.3),
                  blurRadius: 8 * _elevationAnimation.value,
                  offset: Offset(0, 2 * _elevationAnimation.value),
                ),
            ],
          ),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 10, // Match spaces/feed blur value for consistency
                sigmaY: 10,
              ),
              child: _buildAppBarContent(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBarContent() {
    return SafeArea(
      child: SizedBox(
        height: 60, // Match the height in spaces/feed app bar
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // HIVE logo
              _buildLogo(),
              
              // Settings icon (styled the same as messaging in other app bars)
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact(); // Match spaces haptic style
                  if (widget.onSettingsTap != null) {
                    widget.onSettingsTap!();
                  } else {
                    GoRouter.of(context).go(AppRoutes.settings);
                  }
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    HugeIcons.settings,
                    color: Colors.white, // Use white color for consistency
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return GestureDetector(
      onTap: () {
        // Scroll to top on logo tap
        if (widget.scrollController.offset > 0) {
          HapticFeedback.lightImpact();
          widget.scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutQuint,
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutQuint,
        height: 32,
        child: Image.asset(
          'assets/images/hivelogo.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
} 