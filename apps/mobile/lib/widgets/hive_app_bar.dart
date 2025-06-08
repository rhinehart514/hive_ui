import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App bar style variants for different sections of the app
enum HiveAppBarStyle {
  /// Standard app bar with title and optional actions
  standard,
  
  /// App bar with tabs below the title
  withTabs,
  
  /// App bar with search functionality
  withSearch,
  
  /// App bar with both tabs and search
  withTabsAndSearch,
  
  /// Transparent app bar for profile or content-focused screens
  transparent,
}

/// A consistent app bar component that works throughout the platform
/// Supports scrolling behavior, search expansion, and mobile responsiveness
class HiveAppBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  /// The title of the app bar
  final String title;
  
  /// Optional subtitle to display below the title
  final String? subtitle;
  
  /// App bar style variant
  final HiveAppBarStyle style;
  
  /// TabBar to display below the title (for styles that include tabs)
  final TabBar? tabBar;
  
  /// Whether to show a back button
  final bool showBackButton;
  
  /// Custom back button callback, defaults to Navigator.pop
  final VoidCallback? onBackPressed;
  
  /// Actions to display on the right side of the app bar
  final List<Widget>? actions;
  
  /// Leading widget to replace the back button
  final Widget? leading;
  
  /// Whether to respond to scroll events with animation
  final bool scrollable;
  
  /// External scroll controller to sync app bar behavior with page scrolling
  final ScrollController? scrollController;
  
  /// Whether to show a bottom border
  final bool showBottomBorder;
  
  /// Title style override
  final TextStyle? titleStyle;
  
  /// Icon color override
  final Color? iconColor;
  
  /// Background color override (applies to non-transparent styles)
  final Color? backgroundColor;
  
  /// Whether to apply glassmorphism effect
  final bool useGlassmorphism;
  
  /// Whether to center the title
  final bool centerTitle;
  
  /// Search related properties
  final bool showSearchButton;
  final VoidCallback? onSearchPressed;
  final TextEditingController? searchController;
  final FocusNode? searchFocusNode;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchClosed;
  
  const HiveAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.style = HiveAppBarStyle.standard,
    this.tabBar,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
    this.leading,
    this.scrollable = false,
    this.scrollController,
    this.showBottomBorder = true,
    this.titleStyle,
    this.iconColor,
    this.backgroundColor,
    this.useGlassmorphism = true,
    this.centerTitle = false,
    this.showSearchButton = false,
    this.onSearchPressed,
    this.searchController,
    this.searchFocusNode,
    this.onSearchChanged,
    this.onSearchClosed,
  });

  @override
  ConsumerState<HiveAppBar> createState() => _HiveAppBarState();

  @override
  Size get preferredSize {
    double height = kToolbarHeight; // Base height
    
    // Add height for subtitle
    if (subtitle != null) {
      height += 16;
    }
    
    // Add height for tabs
    if (style == HiveAppBarStyle.withTabs || style == HiveAppBarStyle.withTabsAndSearch) {
      height += (tabBar?.preferredSize.height ?? 48);
    }
    
    // Add height for search when expanded (handled dynamically in the state)
    
    return Size.fromHeight(height);
  }
}

class _HiveAppBarState extends ConsumerState<HiveAppBar> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  bool _isScrolled = false;
  bool _isSearchExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize scroll controller if it's scrollable
    _scrollController = widget.scrollController ?? ScrollController();
    
    // Set up animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    // Add scroll listener if scrollable
    if (widget.scrollable) {
      _scrollController.addListener(_scrollListener);
    }
  }
  
  @override
  void dispose() {
    // Only dispose the controller if we created it
    if (widget.scrollController == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_scrollListener);
    }
    
    _animationController.dispose();
    super.dispose();
  }
  
  void _scrollListener() {
    if (_scrollController.offset > 10 && !_isScrolled) {
      setState(() {
        _isScrolled = true;
      });
      _animationController.forward();
    } else if (_scrollController.offset <= 10 && _isScrolled) {
      setState(() {
        _isScrolled = false;
      });
      _animationController.reverse();
    }
  }
  
  void _toggleSearchExpanded(bool expanded) {
    setState(() {
      _isSearchExpanded = expanded;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: _getPreferredSize(),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: widget.style == HiveAppBarStyle.transparent
                  ? Colors.transparent
                  : (widget.backgroundColor ?? AppColors.black).withOpacity(
                      widget.useGlassmorphism ? 0.2 : 1.0),
              border: widget.showBottomBorder
                  ? const Border(
                      bottom: BorderSide(
                        color: Colors.white10,
                        width: 0.5,
                      ),
                    )
                  : null,
              boxShadow: _isScrolled && widget.scrollable
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(_elevationAnimation.value * 0.3),
                        blurRadius: 30 * _elevationAnimation.value,
                        spreadRadius: -5,
                        offset: Offset(0, 10 * _elevationAnimation.value),
                      ),
                    ]
                  : null,
            ),
            child: SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SizedBox(
                    height: kToolbarHeight + (widget.subtitle != null ? 16.0 : 0) +
                           (widget.tabBar != null ? widget.tabBar!.preferredSize.height : 0) +
                           (_isSearchExpanded ? 56.0 : 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: _buildTopSection(),
                        ),
                        
                        // Search bar when expanded
                        if ((widget.style == HiveAppBarStyle.withSearch || 
                            widget.style == HiveAppBarStyle.withTabsAndSearch) &&
                            _isSearchExpanded &&
                            widget.searchController != null)
                          Flexible(
                            child: _buildSearchBar(),
                          ),
                        
                        // Tab bar if provided
                        if ((widget.style == HiveAppBarStyle.withTabs || 
                            widget.style == HiveAppBarStyle.withTabsAndSearch) &&
                            widget.tabBar != null)
                          SizedBox(
                            height: widget.tabBar!.preferredSize.height - 0.5, // Subtract 0.5 to prevent overflow
                            child: widget.tabBar,
                          ),
                      ],
                    ),
                  );
                }
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Size _getPreferredSize() {
    // Base height calculation
    double height = widget.subtitle != null ? 72 : 56;
    
    // Add height for tabs
    if ((widget.style == HiveAppBarStyle.withTabs || 
         widget.style == HiveAppBarStyle.withTabsAndSearch) &&
        widget.tabBar != null) {
      height += widget.tabBar!.preferredSize.height - 0.5; // Subtract 0.5 to prevent overflow
    }
    
    // Add height for search when expanded
    if ((widget.style == HiveAppBarStyle.withSearch || 
         widget.style == HiveAppBarStyle.withTabsAndSearch) &&
        _isSearchExpanded) {
      height += 56;
    }
    
    // Add buffer for safe area
    height += MediaQuery.of(context).padding.top;
    
    return Size.fromHeight(height);
  }
  
  Widget _buildTopSection() {
    return SizedBox(
      height: widget.subtitle != null ? 71.5 : 55.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Row(
          children: [
            // Leading widget or back button
            if (widget.leading != null)
              widget.leading!
            else if (widget.showBackButton)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                icon: Icon(
                  Icons.arrow_back,
                  color: widget.iconColor ?? AppColors.white,
                  size: 24,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  if (widget.onBackPressed != null) {
                    widget.onBackPressed!();
                  } else {
                    Navigator.maybePop(context);
                  }
                },
              )
            else
              const SizedBox(width: 32),
            
            // Title section
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: widget.centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: widget.titleStyle ?? GoogleFonts.inter(
                      color: AppColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: widget.centerTitle ? TextAlign.center : TextAlign.start,
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle!,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: widget.centerTitle ? TextAlign.center : TextAlign.start,
                    ),
                  ],
                ],
              ),
            ),
            
            // Actions row
            Row(
              mainAxisSize: MainAxisSize.min,
              children: _buildActions(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutQuint,
      height: _isSearchExpanded ? 60 : 0,
      decoration: BoxDecoration(
        color: AppColors.black.withOpacity(0.2),
        border: const Border(
          bottom: BorderSide(
            color: Colors.white10,
            width: 0.5,
          ),
        ),
      ),
      child: _isSearchExpanded
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.yellow.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: widget.searchController,
                        focusNode: widget.searchFocusNode,
                        style: GoogleFonts.inter(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.1,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: GoogleFonts.inter(
                            color: AppColors.textTertiary,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.1,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.yellow,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        onChanged: widget.onSearchChanged,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.yellow, size: 20),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (widget.searchController != null) {
                        widget.searchController!.clear();
                      }
                      if (widget.onSearchChanged != null) {
                        widget.onSearchChanged!('');
                      }
                      _toggleSearchExpanded(false);
                      if (widget.onSearchClosed != null) {
                        widget.onSearchClosed!();
                      }
                    },
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
  
  List<Widget> _buildActions() {
    final List<Widget> actionWidgets = [];
    
    // Search button if needed
    if (widget.showSearchButton && 
        (widget.style == HiveAppBarStyle.withSearch || 
         widget.style == HiveAppBarStyle.withTabsAndSearch) &&
        !_isSearchExpanded) {
      actionWidgets.add(
        IconButton(
          icon: const Icon(Icons.search, color: AppColors.white),
          onPressed: () {
            HapticFeedback.selectionClick();
            _toggleSearchExpanded(true);
            if (widget.onSearchPressed != null) {
              widget.onSearchPressed!();
            }
            if (widget.searchFocusNode != null) {
              Future.delayed(const Duration(milliseconds: 100), () {
                widget.searchFocusNode!.requestFocus();
              });
            }
          },
        ),
      );
    }
    
    // Add custom actions
    if (widget.actions != null) {
      actionWidgets.addAll(widget.actions!);
    }
    
    // Add spacing for edge
    actionWidgets.add(const SizedBox(width: 8));
    
    return actionWidgets;
  }
} 