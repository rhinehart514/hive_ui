import 'package:flutter/material.dart';
import 'package:hive_ui/components/card_lifecycle_wrapper.dart';

/// Utility class for handling content age and lifecycle states
class ContentAgeUtils {
  /// Default durations for each lifecycle state
  static const Map<CardLifecycleState, Duration> defaultAgingDurations = {
    CardLifecycleState.fresh: Duration(hours: 24),
    CardLifecycleState.aging: Duration(days: 3),
    CardLifecycleState.old: Duration(days: 7),
  };
  
  /// Calculate the lifecycle state based on content age
  static CardLifecycleState calculateLifecycleState(DateTime createdAt, {
    Map<CardLifecycleState, Duration>? customDurations,
  }) {
    final now = DateTime.now();
    final age = now.difference(createdAt);
    
    // Use custom durations or defaults
    final durations = customDurations ?? defaultAgingDurations;
    
    // Fresh content is less than the fresh duration old
    if (age <= (durations[CardLifecycleState.fresh] ?? const Duration(hours: 24))) {
      return CardLifecycleState.fresh;
    }
    
    // Aging content is between fresh and aging durations old
    final agingThreshold = (durations[CardLifecycleState.fresh] ?? const Duration(hours: 24)) +
        (durations[CardLifecycleState.aging] ?? const Duration(days: 3));
    if (age <= agingThreshold) {
      return CardLifecycleState.aging;
    }
    
    // Old content is between aging and old durations old
    final oldThreshold = agingThreshold +
        (durations[CardLifecycleState.old] ?? const Duration(days: 7));
    if (age <= oldThreshold) {
      return CardLifecycleState.old;
    }
    
    // Content older than the old threshold is archived
    return CardLifecycleState.archived;
  }
  
  /// Get the percentage progress through the current lifecycle state
  /// Returns a value between 0.0 and 1.0
  static double getProgressThroughState(DateTime createdAt, CardLifecycleState state, {
    Map<CardLifecycleState, Duration>? customDurations,
  }) {
    final now = DateTime.now();
    final age = now.difference(createdAt);
    
    // Use custom durations or defaults
    final durations = customDurations ?? defaultAgingDurations;
    
    switch (state) {
      case CardLifecycleState.fresh:
        final freshDuration = durations[CardLifecycleState.fresh] ?? const Duration(hours: 24);
        return age.inMilliseconds / freshDuration.inMilliseconds;
        
      case CardLifecycleState.aging:
        final freshDuration = durations[CardLifecycleState.fresh] ?? const Duration(hours: 24);
        final agingDuration = durations[CardLifecycleState.aging] ?? const Duration(days: 3);
        
        final stateAge = age - freshDuration;
        return stateAge.inMilliseconds / agingDuration.inMilliseconds;
        
      case CardLifecycleState.old:
        final freshDuration = durations[CardLifecycleState.fresh] ?? const Duration(hours: 24);
        final agingDuration = durations[CardLifecycleState.aging] ?? const Duration(days: 3);
        final oldDuration = durations[CardLifecycleState.old] ?? const Duration(days: 7);
        
        final stateAge = age - freshDuration - agingDuration;
        return stateAge.inMilliseconds / oldDuration.inMilliseconds;
        
      case CardLifecycleState.archived:
        // Archived content is always at 100% progress
        return 1.0;
    }
  }
  
  /// Get a human-readable time ago string
  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else {
      return '${(difference.inDays / 365).floor()}y ago';
    }
  }
  
  /// Get a color based on content age
  static Color getAgeColor(DateTime createdAt, {
    Color freshColor = Colors.green,
    Color agingColor = Colors.blue,
    Color oldColor = Colors.orange,
    Color archivedColor = Colors.grey,
    Map<CardLifecycleState, Duration>? customDurations,
  }) {
    final state = calculateLifecycleState(createdAt, customDurations: customDurations);
    
    switch (state) {
      case CardLifecycleState.fresh:
        return freshColor;
      case CardLifecycleState.aging:
        return agingColor;
      case CardLifecycleState.old:
        return oldColor;
      case CardLifecycleState.archived:
        return archivedColor;
    }
  }
  
  /// Get appropriate opacity based on content age
  static double getAgeOpacity(DateTime createdAt, {
    Map<CardLifecycleState, Duration>? customDurations,
    Map<CardLifecycleState, double>? opacityValues,
  }) {
    final state = calculateLifecycleState(createdAt, customDurations: customDurations);
    
    // Default opacity values
    final defaultOpacities = {
      CardLifecycleState.fresh: 1.0,
      CardLifecycleState.aging: 0.9,
      CardLifecycleState.old: 0.75,
      CardLifecycleState.archived: 0.5,
    };
    
    // Use custom values or defaults
    final opacities = opacityValues ?? defaultOpacities;
    
    return opacities[state] ?? 1.0;
  }
} 