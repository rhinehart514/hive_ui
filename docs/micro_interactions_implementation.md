# HIVE UI Micro-Interactions Implementation Guide

This document outlines the implementation plans for priority micro-interactions to enhance user engagement in the HIVE app, focusing on scroll reactivity and state transitions.

## 1. Scroll Reactivity Implementation

### 1.1 Primary Components To Enhance

1. **Feed Scroll Experience**
   - Location: `lib/pages/main_feed.dart` and `lib/features/feed/presentation/pages/feed_page.dart`
   - Implementation: Add parallax effect to event cards as user scrolls

2. **Space/Club Discovery Screen**
   - Location: `lib/features/spaces/presentation/pages/space_discovery_page.dart`
   - Implementation: Add subtle scale/opacity changes to Space cards during scroll

3. **Profile Page Scroll Effects**
   - Location: `lib/features/profile/presentation/screens/profile_page.dart`
   - Implementation: Enhance existing header transition with additional parallax for profile image

### 1.2 Implementation Details

#### 1.2.1 Feed Event Cards Parallax Effect

```dart
// In the event card widget:
class EventCard extends StatelessWidget {
  final Event event;
  final ScrollController scrollController;
  
  @override
  Widget build(BuildContext context) {
    // Calculate parallax effect based on card position
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
        // Get the card's position in the viewport
        final RenderObject? renderObject = context.findRenderObject();
        if (renderObject == null || !renderObject.attached) {
          return child!;
        }
        
        // Calculate card position relative to viewport
        final RenderAbstractViewport viewport = RenderAbstractViewport.of(renderObject);
        final double viewportOffset = viewport.getOffsetToReveal(renderObject, 0.0).offset;
        final double scrollOffset = scrollController.offset;
        final double cardOffset = viewportOffset - scrollOffset;
        
        // Calculate parallax factor (adjust multiplier for effect intensity)
        final double parallaxOffset = cardOffset * 0.1;
        
        return Transform.translate(
          offset: Offset(0, parallaxOffset),
          child: child,
        );
      },
      child: // Original card content
    );
  }
}
```

#### 1.2.2 Scale/Opacity Changes for Space Cards

```dart
// In the space card widget:
class SpaceCard extends StatelessWidget {
  final Space space;
  final ScrollController scrollController;
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
        // Calculate position in scroll view
        final RenderObject? renderObject = context.findRenderObject();
        if (renderObject == null || !renderObject.attached) {
          return child!;
        }
        
        // Determine visibility percentage (0.0 to 1.0)
        final RenderAbstractViewport viewport = RenderAbstractViewport.of(renderObject);
        final double viewportDimension = viewport.viewportDimension;
        final double viewportOffset = viewport.getOffsetToReveal(renderObject, 0.0).offset;
        final double scrollOffset = scrollController.offset;
        final double cardOffset = viewportOffset - scrollOffset;
        
        // Calculate visibility factor (1.0 when fully visible, 0.0 when off-screen)
        final double visibilityFactor = (1.0 - (cardOffset / viewportDimension)).clamp(0.0, 1.0);
        
        // Apply subtle scale and opacity effects
        return Opacity(
          opacity: 0.7 + (visibilityFactor * 0.3), // 0.7 to 1.0 opacity range
          child: Transform.scale(
            scale: 0.95 + (visibilityFactor * 0.05), // 0.95 to 1.0 scale range
            child: child,
          ),
        );
      },
      child: // Original card content
    );
  }
}
```

#### 1.2.3 Enhanced Profile Header Parallax

```dart
// In profile_page.dart:
class ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double expandedHeight;
  final UserProfile profile;
  
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Calculate scroll percentage (0.0 when expanded, 1.0 when collapsed)
    final double scrollPercentage = shrinkOffset / maxExtent;
    
    // Enhanced parallax effect for profile image
    final double imageParallaxOffset = shrinkOffset * 0.3; // Adjust multiplier for effect intensity
    
    return Stack(
      children: [
        // Background with parallax
        Positioned.fill(
          child: Transform.translate(
            offset: Offset(0, imageParallaxOffset),
            child: Image.network(
              profile.backgroundImageUrl ?? 'default_bg_url',
              fit: BoxFit.cover,
            ),
          ),
        ),
        
        // Profile content with existing fade/transition effects
        // ...existing code...
      ],
    );
  }
}
```

## 2. State Transitions

### 2.1 Primary Components To Enhance

1. **Loading States**
   - Location: Throughout app, especially in `lib/widgets/` shared components
   - Implementation: Create smooth fade transitions between loading, content, and error states

2. **RSVP Status Changes**
   - Location: `lib/features/feed/presentation/widgets/rsvp_button.dart`
   - Implementation: Animate transitions between RSVP states

3. **Form Submission States**
   - Location: Various forms throughout the app
   - Implementation: Add loading/success/error animations for form submissions

### 2.2 Implementation Details

#### 2.2.1 Generic State Transition Container

```dart
// Create a new widget in lib/widgets/state_transition_container.dart:
class StateTransitionContainer extends StatelessWidget {
  final Widget loadingWidget;
  final Widget contentWidget;
  final Widget? errorWidget;
  final LoadingStatus status;
  final String? errorMessage;
  
  const StateTransitionContainer({
    Key? key,
    required this.loadingWidget,
    required this.contentWidget,
    this.errorWidget,
    required this.status,
    this.errorMessage,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (Widget child, Animation<double> animation) {
        // Fade transition combined with slight scale
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: _buildCurrentStateWidget(),
    );
  }
  
  Widget _buildCurrentStateWidget() {
    switch (status) {
      case LoadingStatus.loading:
        return loadingWidget;
      case LoadingStatus.error:
        return errorWidget ?? Text(errorMessage ?? 'An error occurred');
      case LoadingStatus.success:
        return contentWidget;
      default:
        return contentWidget;
    }
  }
}
```

#### 2.2.2 RSVP Button State Transitions

```dart
// Enhanced RSVP button with animated state transitions:
class RSVPButton extends StatefulWidget {
  final bool isRSVPed;
  final VoidCallback onRSVP;
  
  @override
  _RSVPButtonState createState() => _RSVPButtonState();
}

class _RSVPButtonState extends State<RSVPButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isProcessing = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_animationController);
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _handleRSVP() async {
    // Start animation
    _animationController.forward(from: 0.0);
    
    // Show processing state
    setState(() => _isProcessing = true);
    
    // Call RSVP action
    await widget.onRSVP();
    
    // Return to normal state
    setState(() => _isProcessing = false);
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isProcessing ? null : _handleRSVP,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: widget.isRSVPed 
                    ? Theme.of(context).colorScheme.secondary 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.isRSVPed 
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              child: _isProcessing
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: widget.isRSVPed
                            ? Colors.white
                            : Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : Text(
                      widget.isRSVPed ? 'Going' : 'RSVP',
                      style: TextStyle(
                        color: widget.isRSVPed
                            ? Colors.white
                            : Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
```

#### 2.2.3 Form Submission State Transitions

```dart
// Create a widget for form submission buttons:
class AnimatedSubmitButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isSuccess;
  final bool isError;
  
  const AnimatedSubmitButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isSuccess = false,
    this.isError = false,
  }) : super(key: key);
  
  @override
  _AnimatedSubmitButtonState createState() => _AnimatedSubmitButtonState();
}

class _AnimatedSubmitButtonState extends State<AnimatedSubmitButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _widthAnimation = Tween<double>(begin: 1.0, end: 0.3)
        .animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        ));
  }
  
  @override
  void didUpdateWidget(AnimatedSubmitButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Animate to loading state or back
    if (widget.isLoading && !oldWidget.isLoading) {
      _animationController.forward();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _animationController.reverse();
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Determine button color based on state
    Color buttonColor = Theme.of(context).colorScheme.primary;
    if (widget.isSuccess) {
      buttonColor = Colors.green;
    } else if (widget.isError) {
      buttonColor = Colors.red;
    }
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          width: MediaQuery.of(context).size.width * (_widthAnimation.value * 0.7 + 0.3),
          height: 48,
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: widget.isLoading
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : widget.isSuccess
                      ? Icon(Icons.check, color: Colors.white)
                      : widget.isError
                          ? Icon(Icons.error_outline, color: Colors.white)
                          : Text(
                              widget.label,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
            ),
          ),
        );
      },
    );
  }
}
```

## 3. Implementation Strategy

1. **Create Shared Components First**
   - Implement the `StateTransitionContainer` and `AnimatedSubmitButton` as shared widgets
   - Add these to the component library for reuse

2. **Roll Out Feature By Feature**
   - Start with the feed screen for scroll reactivity since it's the most visible
   - Implement RSVP button enhancements next as they're high-engagement touchpoints
   - Add profile header parallax as it's a commonly viewed element

3. **Test on Various Devices**
   - Ensure parallax effects work well on different screen sizes
   - Verify animations maintain 60fps on mid-range devices
   - Check if effects work correctly when scrolling at different speeds

## 4. Performance Considerations

1. **Use RepaintBoundary** for scroll effects to isolate repainting
2. **Keep animations simple** for weaker devices
3. **Use Skia shader warmup** for smoother first-time animations
4. **Implement conditional effects** based on device performance capability
5. **Limit parallax effect intensity** on lower-end devices

## 5. Detailed Implementation Timeline

1. **Week 1: Core Components** (3 days)
   - Create shared animation widgets
   - Implement StateTransitionContainer
   - Build AnimatedSubmitButton

2. **Week 1-2: Feed Experience** (3 days)
   - Add parallax effect to event cards
   - Enhance RSVP button animations
   - Test and optimize feed scroll performance

3. **Week 2: Additional Screens** (4 days)
   - Implement Space/Club discovery animations
   - Enhance profile header parallax
   - Apply form submission animations to key forms

4. **Week 3: Testing & Optimization** (3 days)
   - Test across device range
   - Optimize performance
   - Fix any animation bugs

Total implementation time: 13 working days 