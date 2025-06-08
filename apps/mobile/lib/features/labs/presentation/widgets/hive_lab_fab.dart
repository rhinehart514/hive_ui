import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/labs/domain/hive_lab_action.dart';
import 'package:hive_ui/features/labs/presentation/providers/hive_lab_provider.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A floating action button for accessing HiveLab features
/// This component follows the brand aesthetic guidelines with animations and haptic feedback
class HiveLabFAB extends ConsumerStatefulWidget {
  /// Callback when a HiveLab action is selected
  final Function(HiveLabAction action)? onActionSelected;
  
  /// Initial display mode
  final HiveLabFABMode initialMode;
  
  /// Option to show only non-premium actions
  final bool hidePreferredActions;
  
  /// Maximum number of actions to display
  final int maxActions;
  
  /// Custom opacity for the glass effect
  final double glassOpacity;
  
  /// Whether to show the FAB as elevated
  final bool elevated;
  
  /// Constructor
  const HiveLabFAB({
    super.key,
    this.onActionSelected,
    this.initialMode = HiveLabFABMode.collapsed,
    this.hidePreferredActions = false,
    this.maxActions = 4,
    this.glassOpacity = 0.2,
    this.elevated = true,
  });
  
  @override
  ConsumerState<HiveLabFAB> createState() => _HiveLabFABState();
}

class _HiveLabFABState extends ConsumerState<HiveLabFAB> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize with the provided mode
    _isExpanded = widget.initialMode == HiveLabFABMode.expanded;
    
    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      reverseDuration: const Duration(milliseconds: 250),
    );
    
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuint,
      reverseCurve: Curves.easeInQuad,
    );
    
    // Set initial animation state
    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      
      // Provide haptic feedback
      HapticFeedback.selectionClick();
      
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }
  
  void _handleActionTap(HiveLabAction action) {
    // Provide haptic feedback for better UX
    HapticFeedback.mediumImpact();
    
    // Track the action click
    ref.read(hiveLabProvider.notifier).trackActionClick(action.id);
    
    // Collapse the FAB
    setState(() {
      _isExpanded = false;
      _animationController.reverse();
    });
    
    // Call the callback
    widget.onActionSelected?.call(action);
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Expanded actions menu
            _buildExpandedActions(),
            
            // Main FAB
            _buildMainButton(),
          ],
        );
      },
    );
  }
  
  Widget _buildMainButton() {
    return Positioned(
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onTap: _toggleExpanded,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _isExpanded 
                ? Colors.black.withOpacity(0.7) 
                : AppColors.yellow,
            shape: BoxShape.circle,
            boxShadow: widget.elevated ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ] : null,
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _isExpanded
                ? const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                    key: ValueKey('close'),
                  )
                : const Icon(
                    Icons.science_outlined,
                    color: Colors.black,
                    size: 24,
                    key: ValueKey('lab'),
                  ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildExpandedActions() {
    // Only build if animation has started
    if (_expandAnimation.value == 0) {
      return const SizedBox.shrink();
    }
    
    // Get the actions from the provider
    final actionsAsync = ref.watch(hiveLabActionsProvider(
      HiveLabActionsParams(
        maxCount: widget.maxActions,
        includePremium: !widget.hidePreferredActions,
      ),
    ));
    
    return Positioned(
      right: 0,
      bottom: 68, // Position above the main FAB with spacing
      child: FadeTransition(
        opacity: _expandAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.5),
            end: Offset.zero,
          ).animate(_expandAnimation),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                width: 280,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(widget.glassOpacity),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 0.5,
                  ),
                  boxShadow: widget.elevated ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: -5,
                      offset: const Offset(0, 10),
                    ),
                  ] : null,
                ),
                child: actionsAsync.when(
                  data: (actions) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 16, bottom: 8),
                        child: Text(
                          'HiveLab',
                          style: TextStyle(
                            color: AppColors.yellow,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Divider(
                        color: Colors.white10,
                        height: 1,
                      ),
                      const SizedBox(height: 8),
                      ...actions.map(_buildActionItem).toList(),
                      if (actions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No actions available',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                    ],
                  ),
                  loading: () => const SizedBox(
                    height: 100,
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.yellow),
                        ),
                      ),
                    ),
                  ),
                  error: (error, stack) => const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 24,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Failed to load actions',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionItem(HiveLabAction action) {
    // Select icon based on action type
    IconData actionIcon;
    Color iconColor;
    
    switch (action.iconType) {
      case HiveLabActionIconType.idea:
        actionIcon = Icons.lightbulb_outline;
        iconColor = Colors.amber;
        break;
      case HiveLabActionIconType.experiment:
        actionIcon = Icons.science_outlined;
        iconColor = Colors.green;
        break;
      case HiveLabActionIconType.feedback:
        actionIcon = Icons.chat_bubble_outline;
        iconColor = Colors.blue;
        break;
      case HiveLabActionIconType.survey:
        actionIcon = Icons.poll_outlined;
        iconColor = Colors.purple;
        break;
      case HiveLabActionIconType.team:
        actionIcon = Icons.groups_outlined;
        iconColor = Colors.orange;
        break;
      case HiveLabActionIconType.beta:
        actionIcon = Icons.new_releases_outlined;
        iconColor = Colors.red;
        break;
    }
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleActionTap(action),
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white10,
        highlightColor: Colors.white10,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Icon(
                actionIcon,
                color: iconColor,
                size: 20,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      action.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (action.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        action.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (action.isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'V+',
                    style: TextStyle(
                      color: AppColors.yellow,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Display mode for the HiveLab FAB
enum HiveLabFABMode {
  /// Collapsed state (only showing the main button)
  collapsed,
  
  /// Expanded state (showing actions menu)
  expanded,
} 