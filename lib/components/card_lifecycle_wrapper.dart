import 'package:flutter/material.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Defines the lifecycle state of a card in the UI
enum CardLifecycleState {
  /// Fresh content that should have full visual prominence
  fresh,
  
  /// Content that is aging but still relevant
  aging,
  
  /// Content that is old but might still be of interest
  old,
  
  /// Content that is archived (minimally visible or in archive views only)
  archived
}

/// A wrapper widget that applies visual effects to cards based on their lifecycle state
class CardLifecycleWrapper extends StatelessWidget {
  /// The card content to display
  final Widget child;
  
  /// The lifecycle state of the card
  final CardLifecycleState state;
  
  /// When the content was created/published
  final DateTime createdAt;
  
  /// Optional override for the opacity values for each state
  final Map<CardLifecycleState, double>? opacityOverrides;
  
  /// Optional override for the saturation values for each state
  final Map<CardLifecycleState, double>? saturationOverrides;
  
  /// Optional override for the scale values for each state
  final Map<CardLifecycleState, double>? scaleOverrides;
  
  /// Whether to show a visual indicator of the lifecycle state
  final bool showIndicator;
  
  /// Whether to apply automatic aging based on creation time
  /// If false, the provided state is used regardless of time
  final bool autoAge;
  
  /// The durations for automatic state transitions
  /// How long content stays in each state
  final Map<CardLifecycleState, Duration> agingDurations;
  
  /// Constructor
  const CardLifecycleWrapper({
    Key? key,
    required this.child,
    required this.createdAt,
    this.state = CardLifecycleState.fresh,
    this.opacityOverrides,
    this.saturationOverrides,
    this.scaleOverrides,
    this.showIndicator = false,
    this.autoAge = true,
    this.agingDurations = const {
      CardLifecycleState.fresh: Duration(hours: 24),
      CardLifecycleState.aging: Duration(days: 3),
      CardLifecycleState.old: Duration(days: 7),
    },
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Determine the actual lifecycle state based on autoAge setting
    final effectiveState = autoAge ? _calculateLifecycleState() : state;
    
    // Get visual properties based on state
    final opacity = _getOpacity(effectiveState);
    final saturation = _getSaturation(effectiveState);
    final scale = _getScale(effectiveState);
    
    // Apply visual effects to the child widget
    Widget result = Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: ColorFiltered(
          colorFilter: ColorFilter.matrix(_createSaturationMatrix(saturation)),
          child: child,
        ),
      ),
    );
    
    // Apply subtle transition effect between states
    result = AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      child: result,
    );
    
    // Add state indicator if needed
    if (showIndicator) {
      result = Stack(
        children: [
          result,
          Positioned(
            top: 8,
            right: 8,
            child: _buildStateIndicator(effectiveState),
          ),
        ],
      );
    }
    
    return result;
  }
  
  /// Calculate the lifecycle state based on creation time and aging durations
  CardLifecycleState _calculateLifecycleState() {
    final now = DateTime.now();
    final age = now.difference(createdAt);
    
    // Fresh content is less than the fresh duration old
    if (age <= (agingDurations[CardLifecycleState.fresh] ?? const Duration(hours: 24))) {
      return CardLifecycleState.fresh;
    }
    
    // Aging content is between fresh and aging durations old
    final agingThreshold = (agingDurations[CardLifecycleState.fresh] ?? const Duration(hours: 24)) +
        (agingDurations[CardLifecycleState.aging] ?? const Duration(days: 3));
    if (age <= agingThreshold) {
      return CardLifecycleState.aging;
    }
    
    // Old content is between aging and old durations old
    final oldThreshold = agingThreshold +
        (agingDurations[CardLifecycleState.old] ?? const Duration(days: 7));
    if (age <= oldThreshold) {
      return CardLifecycleState.old;
    }
    
    // Content older than the old threshold is archived
    return CardLifecycleState.archived;
  }
  
  /// Get the opacity value for a lifecycle state
  double _getOpacity(CardLifecycleState state) {
    // Use override if provided
    if (opacityOverrides != null && opacityOverrides!.containsKey(state)) {
      return opacityOverrides![state]!;
    }
    
    // Default opacity values
    switch (state) {
      case CardLifecycleState.fresh:
        return 1.0;
      case CardLifecycleState.aging:
        return 0.9;
      case CardLifecycleState.old:
        return 0.75;
      case CardLifecycleState.archived:
        return 0.5;
    }
  }
  
  /// Get the saturation value for a lifecycle state
  double _getSaturation(CardLifecycleState state) {
    // Use override if provided
    if (saturationOverrides != null && saturationOverrides!.containsKey(state)) {
      return saturationOverrides![state]!;
    }
    
    // Default saturation values
    switch (state) {
      case CardLifecycleState.fresh:
        return 1.0;
      case CardLifecycleState.aging:
        return 0.8;
      case CardLifecycleState.old:
        return 0.6;
      case CardLifecycleState.archived:
        return 0.3;
    }
  }
  
  /// Get the scale value for a lifecycle state
  double _getScale(CardLifecycleState state) {
    // Use override if provided
    if (scaleOverrides != null && scaleOverrides!.containsKey(state)) {
      return scaleOverrides![state]!;
    }
    
    // Default scale values
    switch (state) {
      case CardLifecycleState.fresh:
        return 1.0;
      case CardLifecycleState.aging:
        return 1.0;
      case CardLifecycleState.old:
        return 0.99;
      case CardLifecycleState.archived:
        return 0.97;
    }
  }
  
  /// Create a saturation matrix for color filtering
  List<double> _createSaturationMatrix(double saturation) {
    final r = 0.2126 * (1 - saturation);
    final g = 0.7152 * (1 - saturation);
    final b = 0.0722 * (1 - saturation);
    
    return [
      r + saturation, g, b, 0, 0,
      r, g + saturation, b, 0, 0,
      r, g, b + saturation, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }
  
  /// Build an indicator that shows the lifecycle state
  Widget _buildStateIndicator(CardLifecycleState state) {
    final Color color;
    final IconData icon;
    
    switch (state) {
      case CardLifecycleState.fresh:
        color = AppColors.gold;
        icon = Icons.star;
        break;
      case CardLifecycleState.aging:
        color = AppColors.info;
        icon = Icons.access_time;
        break;
      case CardLifecycleState.old:
        color = AppColors.grey;
        icon = Icons.history;
        break;
      case CardLifecycleState.archived:
        color = AppColors.grey.withOpacity(0.7);
        icon = Icons.archive;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: 12,
      ),
    );
  }
}

/// Extension methods for CardLifecycleState
extension CardLifecycleStateExtension on CardLifecycleState {
  /// Get a human-readable name for this state
  String get displayName {
    switch (this) {
      case CardLifecycleState.fresh:
        return 'Fresh';
      case CardLifecycleState.aging:
        return 'Aging';
      case CardLifecycleState.old:
        return 'Old';
      case CardLifecycleState.archived:
        return 'Archived';
    }
  }
  
  /// Get a description of this state
  String get description {
    switch (this) {
      case CardLifecycleState.fresh:
        return 'New content with high visibility';
      case CardLifecycleState.aging:
        return 'Content that is aging but still relevant';
      case CardLifecycleState.old:
        return 'Older content with reduced visibility';
      case CardLifecycleState.archived:
        return 'Very old content, minimally visible';
    }
  }
} 