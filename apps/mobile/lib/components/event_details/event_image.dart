import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../optimized_image.dart';

/// A widget that displays an event image with proper URL handling and fallbacks
class EventImage extends StatelessWidget {
  /// The event to display the image for
  final Event event;

  /// How to fit the image in its bounds
  final BoxFit fit;

  /// Width of the image
  final double? width;

  /// Height of the image
  final double? height;

  /// Border radius of the image
  final BorderRadius? borderRadius;

  /// Constructor
  const EventImage({
    Key? key,
    required this.event,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OptimizedImage(
      imageUrl: _getSafeImageUrl(),
      fit: fit,
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }

  // Helper method to get a safe image URL
  String _getSafeImageUrl() {
    // Return the image URL if it exists and is not empty, otherwise return an empty string
    return event.imageUrl.isNotEmpty ? event.imageUrl : '';
  }
}
