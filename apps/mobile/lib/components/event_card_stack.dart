import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ui/components/swipeable_event_card.dart';
import 'package:hive_ui/models/event.dart';
import 'dart:math' as math;

/// A stack of event cards that can be swiped through
/// Inspired by Tinder and similar card-swiping UI patterns
class EventCardStack extends StatefulWidget {
  final List<Event> events;
  final Function(Event) onRSVP;
  final Function(Event) onShare;
  final Function(Event) onCardTap;
  final Function(Event, SwipeDirection) onSwipe;
  final VoidCallback onEmptyStack;

  const EventCardStack({
    super.key,
    required this.events,
    required this.onRSVP,
    required this.onShare,
    required this.onCardTap,
    required this.onSwipe,
    required this.onEmptyStack,
  });

  @override
  State<EventCardStack> createState() => _EventCardStackState();
}

class _EventCardStackState extends State<EventCardStack>
    with SingleTickerProviderStateMixin {
  /// Maximum number of cards to show in the stack
  static const int _maxStackSize = 3;

  /// Index of the top card
  int _topCardIndex = 0;

  /// Keeps track of which cards are being dismissed
  final Map<int, bool> _isDismissing = {};

  /// Animation controller for the card rotation effect
  late AnimationController _animationController;

  /// Animation for the background cards
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Define the scale animation for background cards
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuint,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(EventCardStack oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reset state if the events list changes significantly
    if (widget.events.length != oldWidget.events.length) {
      _topCardIndex = 0;
      _isDismissing.clear();
      if (_animationController.status == AnimationStatus.dismissed) {
        _animationController.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle empty events list
    if (widget.events.isEmpty) {
      return Center(child: _buildEmptyState());
    }

    // Return empty state if we've swiped through all events
    if (_topCardIndex >= widget.events.length) {
      Future.delayed(Duration.zero, () {
        widget.onEmptyStack();
      });
      return Center(child: _buildEmptyState());
    }

    // Build the stack of cards
    return SizedBox(
      width: double.infinity,
      height: math.min(550, MediaQuery.of(context).size.height * 0.75),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: _buildCardStack(),
      ),
    );
  }

  List<Widget> _buildCardStack() {
    final List<Widget> cards = [];

    // Determine how many cards to show in the stack (limited by available events)
    final int stackSize =
        math.min(_maxStackSize, widget.events.length - _topCardIndex);

    // Add cards from back to front (reverse order)
    for (int i = stackSize - 1; i >= 0; i--) {
      final int cardIndex = _topCardIndex + i;

      // Skip if this card is being dismissed
      if (_isDismissing[cardIndex] == true) continue;

      // Only the top card is fully interactive
      final bool isTopCard = i == 0;

      // Build the card with appropriate transformations
      cards.add(
        Positioned(
          bottom: 0,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              final double scale = isTopCard
                  ? 1.0
                  : 0.9 +
                      (0.1 *
                          _scaleAnimation.value *
                          (stackSize - i) /
                          stackSize);

              final double yOffset = isTopCard ? 0 : 20.0 * (stackSize - i);

              return Transform.translate(
                offset: Offset(0, yOffset),
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: isTopCard ? 1.0 : 0.85 - (0.1 * i),
                    child: child,
                  ),
                ),
              );
            },
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: isTopCard
                  ? _buildActiveCard(cardIndex)
                  : _buildInactiveCard(cardIndex),
            ),
          ),
        ),
      );
    }

    return cards;
  }

  Widget _buildActiveCard(int index) {
    final event = widget.events[index];

    // Generate a random number of attendees for demonstration
    final int attendeeCount = 2 + math.Random().nextInt(18);

    return SizedBox(
      width: MediaQuery.of(context).size.width - 32,
      child: SwipeableEventCard(
        event: event,
        attendeeCount: attendeeCount,
        onRSVP: widget.onRSVP,
        onShare: widget.onShare,
        onView: widget.onCardTap,
        onSwipe: _handleSwipe,
      ),
    );
  }

  Widget _buildInactiveCard(int index) {
    final event = widget.events[index];

    // Generate a random number of attendees for demonstration
    final int attendeeCount = 2 + math.Random().nextInt(18);

    return SizedBox(
      width: MediaQuery.of(context).size.width - 32,
      child: IgnorePointer(
        child: SwipeableEventCard(
          key: ValueKey('inactive-card-$index'),
          event: event,
          attendeeCount: attendeeCount,
          onRSVP: widget.onRSVP,
          onShare: widget.onShare,
          onView: widget.onCardTap,
          onSwipe: _handleSwipe,
        ),
      ),
    );
  }

  void _handleSwipe(Event event, DismissDirection direction) {
    // Convert DismissDirection to SwipeDirection
    final swipeDirection = direction == DismissDirection.startToEnd
        ? SwipeDirection.right
        : SwipeDirection.left;

    // Provide haptic feedback
    HapticFeedback.mediumImpact();

    // Mark this card as being dismissed
    setState(() {
      _isDismissing[_topCardIndex] = true;
      _topCardIndex++;
    });

    // Restart animation for next card
    _animationController.reset();
    _animationController.forward();

    // Call the onSwipe callback
    widget.onSwipe(event, swipeDirection);
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.event_busy,
          size: 48,
          color: Colors.white.withOpacity(0.5),
        ),
        const SizedBox(height: 16),
        const Text(
          'No more events',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Pull down to refresh',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
