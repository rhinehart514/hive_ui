import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service to handle feed scrolling functionality, particularly
/// for highlighting specific card types like active rituals.
class FeedScrollService {
  /// Scroll controller for the feed
  final ScrollController scrollController;
  
  /// Whether a scroll to ritual card is pending
  bool _pendingScrollToRitual = false;
  
  /// Creates an instance of [FeedScrollService].
  FeedScrollService() : scrollController = ScrollController();
  
  /// Disposes of the scroll controller when no longer needed.
  void dispose() {
    scrollController.dispose();
  }
  
  /// Sets a flag to scroll to the top-most ritual card when the feed is loaded.
  /// 
  /// This should be called before the feed is built, typically from a route
  /// transition like the tutorial completion.
  void scheduleScrollToTopRitualCard() {
    _pendingScrollToRitual = true;
  }
  
  /// Scrolls to the ritual card if its global position is known.
  /// 
  /// [ritualCardKey] should be the GlobalKey of the ritual card widget.
  /// [highlightDuration] controls how long to apply the highlight animation.
  Future<void> scrollToRitualCard(
    GlobalKey ritualCardKey, {
    Duration highlightDuration = const Duration(seconds: 1),
  }) async {
    _pendingScrollToRitual = false;
    
    // Wait for the widget to be built and laid out
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Find the ritual card's render object
    final RenderObject? renderObject = ritualCardKey.currentContext?.findRenderObject();
    if (renderObject == null) {
      debugPrint('Could not find ritual card render object.');
      return;
    }
    
    // Get the ritual card's position in the scrollview
    final RenderAbstractViewport viewport = RenderAbstractViewport.of(renderObject);
    final double offset = viewport.getOffsetToReveal(renderObject, 0.0).offset;
    
    if (scrollController.hasClients) {
      // Scroll to the ritual card with animation
      await scrollController.animateTo(
        offset - 80, // Adjust to position card with some space above
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      
      // Highlight the card (implementation in the widget)
      // The widget should listen for this notification
      // Widget will need to implement highlight animation
    }
  }
  
  /// Checks if there is a pending scroll to ritual card operation.
  bool get isPendingScrollToRitual => _pendingScrollToRitual;
}

/// Provider for the feed scroll service.
final feedScrollServiceProvider = Provider<FeedScrollService>((ref) {
  final service = FeedScrollService();
  
  // Ensure the service is disposed when the provider is disposed
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
}); 