import 'package:flutter/material.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Class containing consistent spacing values for messaging components
class MessageSpacing {
  /// Small spacing value (4dp)
  static const small = 4.0;
  
  /// Default spacing value (8dp)
  static const normal = 8.0;
  
  /// Medium spacing value (12dp)
  static const medium = 12.0;
  
  /// Large spacing value (16dp)
  static const large = 16.0;
  
  /// Extra large spacing value (24dp)
  static const xLarge = 24.0;
  
  /// Default message bubble padding
  static const messagePadding = EdgeInsets.symmetric(
    horizontal: large,
    vertical: medium,
  );
  
  /// Chat input padding
  static const inputPadding = EdgeInsets.symmetric(
    horizontal: medium,
    vertical: small,
  );
  
  /// Message list padding
  static const listPadding = EdgeInsets.symmetric(
    horizontal: medium,
    vertical: medium,
  );
  
  /// Spacing between messages
  static const messageSpacing = normal;
  
  /// Avatar size
  static const double avatarSize = 36.0;
  
  /// Message list bottom padding to accommodate input
  static const double listBottomPadding = 80.0;
}

/// Typography styles for messaging components
class MessageTypography {
  /// Style for primary message text
  static const TextStyle messageBody = TextStyle(
    fontSize: 16.0,
    color: Colors.white,
    height: 1.4,
  );
  
  /// Style for message sender name
  static const TextStyle senderName = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.bold,
    color: Colors.white70,
  );
  
  /// Style for timestamp text
  static const TextStyle timestamp = TextStyle(
    fontSize: 12.0,
    color: Colors.white54,
  );
  
  /// Style for system messages
  static const TextStyle systemMessage = TextStyle(
    fontSize: 14.0,
    fontStyle: FontStyle.italic,
    color: Colors.white70,
    height: 1.3,
  );
  
  /// Style for message input
  static const TextStyle messageInput = TextStyle(
    fontSize: 16.0,
    color: Colors.white,
    height: 1.3,
  );
  
  /// Style for message count badges
  static const TextStyle countBadge = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );
  
  /// Style for chat title in app bar
  static const TextStyle chatTitle = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  
  /// Style for placeholder/hint text
  static const TextStyle placeholder = TextStyle(
    fontSize: 16.0,
    color: Colors.white38,
  );
}

/// Theme for message bubbles
class MessageBubbleTheme {
  /// Border radius for sent messages
  static const BorderRadius sentBorderRadius = BorderRadius.only(
    topLeft: Radius.circular(16),
    topRight: Radius.circular(4),
    bottomLeft: Radius.circular(16),
    bottomRight: Radius.circular(16),
  );
  
  /// Border radius for received messages
  static const BorderRadius receivedBorderRadius = BorderRadius.only(
    topLeft: Radius.circular(4),
    topRight: Radius.circular(16),
    bottomLeft: Radius.circular(16),
    bottomRight: Radius.circular(16),
  );
  
  /// Background color for sent messages
  static final Color sentBackgroundColor = AppColors.gold.withOpacity(0.15);
  
  /// Background color for received messages
  static final Color receivedBackgroundColor = Colors.grey.shade800.withOpacity(0.3);
  
  /// Border gradient for sent messages
  static final List<Color> sentBorderGradient = [
    AppColors.gold.withOpacity(0.5),
    AppColors.gold.withOpacity(0.2),
  ];
  
  /// Border gradient for received messages
  static final List<Color> receivedBorderGradient = [
    Colors.white.withOpacity(0.2),
    Colors.white.withOpacity(0.05),
  ];
  
  /// Default blur amount for glassmorphic effect
  static const double defaultBlur = 10.0;
  
  /// Default opacity for glassmorphic effect
  static const double defaultOpacity = 0.2;
  
  /// Default border width
  static const double defaultBorderWidth = 0.5;
}

/// Utility class for image optimization in messaging
class MessageImageOptimization {
  /// Default avatar size for caching
  static const int avatarCacheSize = 80;
  
  /// Default thumbnail quality (0-100)
  static const int thumbnailQuality = 85;
  
  /// Maximum width for image thumbnails in pixels
  static const int maxThumbnailWidth = 800;
  
  /// Cache duration in days
  static const int cacheDurationDays = 7;
  
  /// Avatar placeholder color
  static final Color avatarPlaceholderColor = Colors.grey.shade800;
  
  /// Get optimal image dimensions based on original size and target width
  static Size getOptimalImageDimensions(Size original, double targetWidth) {
    final aspectRatio = original.width / original.height;
    final newWidth = targetWidth;
    final newHeight = newWidth / aspectRatio;
    return Size(newWidth, newHeight);
  }
} 
 
 