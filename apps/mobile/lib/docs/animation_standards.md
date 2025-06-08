# HIVE Animation & Motion Standards

> "Every transition must serve as a narrative cue, not an effect. The system explains itself in how it moves."

## Core Animation Philosophy

HIVE's motion design creates a premium, responsive experience inspired by iOS physics while maintaining the app's sophisticated aesthetic. Our animations:

1. **Communicate function** - Motion explains what is happening
2. **Feel physical** - Animations obey natural laws of motion
3. **Guide attention** - Direct focus to what matters 
4. **Maintain restraint** - Subtle, purposeful motion over decoration

## Animation Technical Standards

### Duration Guidelines

| Interaction | Duration | Use Case |
|-------------|----------|----------|
| Micro-interactions | 150-200ms | Button press, toggle, tap feedback |
| Standard transitions | 300-350ms | Page transitions, content reveal |
| Complex transitions | 400-500ms | Modal entrances, multi-step animations |

Never exceed 500ms for standard interface animations unless a specific narrative purpose exists.

### Animation Curves

| Curve | Specification | Use Case |
|-------|---------------|----------|
| Standard curve | cubic-bezier(0.4, 0, 0.2, 1) | Most transitions |
| Deceleration curve | cubic-bezier(0.0, 0, 0.2, 1) | Elements entering screen |
| Acceleration curve | cubic-bezier(0.4, 0, 1, 1) | Elements leaving screen |
| Sharp curve | cubic-bezier(0.4, 0, 0.6, 1) | Emphasized state changes |

**Never** use linear timing for animations.

### Spring Physics

For natural motion, use spring-based animations:

| Animation | Damping | Stiffness | Mass | Use Case |
|-----------|---------|-----------|------|----------|
| Subtle spring | 0.8 | 180 | 1.0 | Button press, small movements |
| Medium spring | 0.7 | 120 | 1.0 | Card transitions, list items |
| Bouncy spring | 0.5 | 100 | 1.0 | Celebratory moments, attention-grabbing |

```dart
// Example spring animation implementation
final _controller = AnimationController(
  duration: const Duration(milliseconds: 300),
  vsync: this,
);

final _animation = SpringSimulation(
  SpringDescription(
    mass: 1.0, 
    stiffness: 180.0, 
    damping: 20.0,
  ),
  0.0,
  1.0,
  0.0,
).animate(_controller);
```

## Component-Specific Motion

### Buttons

| State | Animation |
|-------|-----------|
| Press | 120ms ease-out, scale to 98%, subtle darkness |
| Release | 150ms ease-in-out with slight overshoot |
| Loading | Continuous subtle pulse (opacity 100% → 80% → 100%) |
| Disabled | 200ms transition to disabled visual state |

### Cards

| Interaction | Animation |
|-------------|-----------|
| Tap | Quick compress (98% scale) + subtle darkness |
| Press-and-hold | Slow compress + haptic feedback |
| Appear in view | Subtle fade in + small upward movement (12px) |
| Active/Selected | Subtle inner glow pulse |

### Modals

| State | Animation |
|-------|-----------|
| Enter | Z-zoom entrance (scale 0.9 → 1.0) with blur depth increase |
| Exit | Reverse of entrance or slide down + fade |
| Background dim | Synchronized fade to 50% opacity |

### Transitions Between Screens

| Transition | Animation |
|------------|-----------|
| Push | Standard iOS-like push (slide from right) |
| Pop | Reverse of push |
| Modal | Bottom-up slide with slight scale adjustment |
| Tab switch | Cross-fade with subtle position shift |

## Microinteractions

### Interactive Feedback

| Interaction | Animation | Haptics |
|-------------|-----------|---------|
| Button press | Scale + opacity | Light impact |
| Toggle switch | Position shift + color transition | Light impact |
| Swipe action | Follow finger + rubber band at edges | None |
| Error | Horizontal shake (3 oscillations) | Error feedback |

### Status Indicators

| State | Animation |
|-------|-----------|
| Loading | Subtle shimmer effect or spinner |
| Success | Brief green pulse + checkmark scale |
| Error | Red pulse + error icon reveal |
| Live status | Gold pulsating glow (subtle, not distracting) |

## Implementation Guidelines

### Performance Optimization

1. **Optimize for 60fps** - No frame drops on target devices
2. **Use hardware acceleration** when appropriate
3. **Batch animations** that occur simultaneously
4. **Test on low-end devices** to ensure smooth performance

```dart
// Efficient animation implementation
AnimatedContainer(
  duration: const Duration(milliseconds: 300),
  curve: Curves.easeInOut,
  decoration: BoxDecoration(
    color: _isActive ? AppColors.surfaceActive : AppColors.surface,
    borderRadius: BorderRadius.circular(20),
  ),
  child: child,
)
```

### Accessibility Considerations

1. **Respect reduced motion settings**:
   - Check platformDispatcher.accessibilityFeatures.reduceMotion
   - Provide simplified animations or static alternatives
   - Reduce durations by 50% when reduced motion is enabled

2. **Never rely solely on animation** to convey information
3. **Avoid animations that could trigger vestibular disorders**

```dart
// Respecting reduced motion preferences
final bool shouldReduceMotion = MediaQuery.of(context).accessibilityFeatures.reduceMotion;

final Duration animationDuration = shouldReduceMotion 
  ? const Duration(milliseconds: 100) 
  : const Duration(milliseconds: 300);
```

## Staggered Animations

For complex UI with multiple elements, use staggered animations:

1. **Sequence related movements** with slight delays (50-100ms)
2. **Maintain consistent direction** for related elements
3. **Layer animations** from background to foreground

```dart
// Staggered animation example
void _animateItems() {
  _backgroundController.forward();
  Future.delayed(Duration(milliseconds: 50), () {
    _headingController.forward();
  });
  Future.delayed(Duration(milliseconds: 100), () {
    _contentController.forward();
  });
  Future.delayed(Duration(milliseconds: 150), () {
    _actionsController.forward();
  });
}
```

## User-Triggered vs. System Animations

| Trigger | Principle |
|---------|-----------|
| User-triggered | Immediate response, follow input (e.g., swipe follows finger) |
| System-triggered | Predictable, consistent timing, non-disruptive |

## Testing Guidelines

1. **Visual inspection** on target devices
2. **Performance profiling** using Flutter DevTools
3. **Motion sickness testing** with representative users
4. **Verification across devices** (iOS, Android, Web)

## References

- [Animation Durations](mdc:lib/theme/animation_durations.dart)
- [iOS Style Animations](mdc:lib/theme/ios_style.dart)
- [Flutter Animation Documentation](https://flutter.dev/docs/development/ui/animations)

---

Remember: Animation in HIVE should feel premium, responsive, and physically satisfying—like using a luxury device rather than an app. Motion should always serve function first, with delight as a byproduct. 