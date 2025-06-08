import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// Theme and Styling
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/extensions/glassmorphism_extension.dart';

/// A standard content module with header and content
/// Used for creating consistent module-based layouts
class ContentModule extends StatefulWidget {
  /// Title displayed in the header
  final String title;

  /// Content to display in the module
  final Widget content;

  /// Optional action button text
  final String? actionText;

  /// Called when the action button is tapped
  final VoidCallback? onAction;

  /// Whether the module can be expanded/collapsed
  final bool isExpandable;

  /// Whether the module is initially expanded
  final bool initiallyExpanded;

  /// Padding applied to the content
  final EdgeInsets contentPadding;

  /// Margin applied to the module
  final EdgeInsets margin;

  /// Whether to use glassmorphism effect
  final bool useGlassmorphism;

  /// Whether to add gold accent
  final bool addGoldAccent;

  const ContentModule({
    Key? key,
    required this.title,
    required this.content,
    this.actionText,
    this.onAction,
    this.isExpandable = false,
    this.initiallyExpanded = true,
    this.contentPadding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 16),
    this.useGlassmorphism = true,
    this.addGoldAccent = false,
  }) : super(key: key);

  @override
  State<ContentModule> createState() => _ContentModuleState();
}

class _ContentModuleState extends State<ContentModule>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
      HapticFeedback.lightImpact();
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget moduleContent = Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Module header
          _buildHeader(),

          // Module content
          if (widget.isExpandable)
            _buildExpandableContent()
          else
            Padding(
              padding: widget.contentPadding,
              child: widget.content,
            ),
        ],
      ),
    );

    // Apply glassmorphism if enabled
    if (widget.useGlassmorphism) {
      moduleContent = moduleContent.addGlassmorphism(
        blur: 5.0,
        opacity: 0.1,
        borderRadius: 16,
        addGoldAccent: widget.addGoldAccent,
      );
    }

    return moduleContent;
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title
          Text(
            widget.title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          // Action button or expand toggle
          if (widget.isExpandable)
            GestureDetector(
              onTap: _toggleExpand,
              child: AnimatedRotation(
                turns: _isExpanded ? 0.0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.keyboard_arrow_up,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else if (widget.onAction != null && widget.actionText != null)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onAction?.call();
              },
              child: Text(
                widget.actionText!,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppColors.gold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpandableContent() {
    return SizeTransition(
      sizeFactor: _expandAnimation,
      child: Padding(
        padding: widget.contentPadding,
        child: widget.content,
      ),
    );
  }
}
