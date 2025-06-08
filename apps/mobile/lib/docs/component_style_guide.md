# ⚠️ DEPRECATED DOCUMENT ⚠️

> **IMPORTANT**: This document is no longer maintained and may contain outdated information. The current brand aesthetics documentation is now available at [`/lib/docs/brand_aesthetic.md`](/lib/docs/brand_aesthetic.md).

---

# HIVE Component Style Guide

This guide explains how to use the HiveComponentStyle system introduced in the brand aesthetic documentation. The component style system allows for consistent application of HIVE's Counter-Culture Premium aesthetic across different features and contexts.

## Overview

HIVE implements a contextual design system with three primary style variants:

1. **Standard Style**: Apple-inspired premium feel (default)
2. **Rebellion Style**: Counter-culture enhanced for new features
3. **Secret Style**: Maximum styling for hidden and experimental features

The `HiveComponentStyle` enum and supporting utilities can be found in `lib/theme/component_style.dart`.

## Style Characteristics

Each style has distinct visual characteristics:

### Standard Style
- Pure black backgrounds
- White text with subtle gold accents
- 30px rounded corners on elements
- Standard animation timing (400ms)
- Curves.easeOut for transitions
- Subtle glassmorphism effects

### Rebellion Style
- Pure black backgrounds
- Enhanced gold accents
- Sharp corners (0px radius)
- Quicker animation timing (250-300ms)
- Custom rebellious curve
- Enhanced glassmorphism blur

### Secret Style
- Pure black backgrounds
- Maximum gold accents and highlights
- Mix of sharp and minimal rounding
- Dramatic animation timing (200-400ms)
- Custom cubic curves
- Maximum glassmorphism blur

## When to Use Each Style

### Standard Style (Default)
- Core application functionality
- Main navigation and basic UI elements
- Established features that users are familiar with
- Any component where a specific style is not specified

**Examples:**
- Main navigation bar
- Feed screens
- Standard buttons
- Profile views
- Settings screens

### Rebellion Style
Use for features that represent HIVE's counter-culture identity:
- New features being introduced to users
- Community-focused areas
- Student-exclusive functionality
- Content that challenges traditional university structures

**Examples:**
- New feature announcements
- Community discussion areas
- Student governance sections
- Exclusive content areas
- Features that bypass traditional university systems

### Secret Style
Use for features that represent power user capabilities or experimental functionality:
- Hidden features that require specific gestures to access
- Experimental or beta features
- Advanced settings
- Developer tools
- Power user capabilities

**Examples:**
- Experimental features behind feature flags
- Advanced filtering options
- Developer mode screens
- Hidden easter eggs
- Advanced user tools

## Implementation Examples

### Basic Component Usage

```dart
// Standard button (default)
HiveButton(
  text: 'Submit',
  onPressed: () => submitForm(),
)

// Rebellion style button for a new feature
HiveButton(
  text: 'Try New Feature',
  onPressed: () => launchNewFeature(),
  componentStyle: HiveComponentStyle.rebellion,
)

// Secret style button for advanced settings
HiveButton(
  text: 'Developer Options',
  onPressed: () => openDevOptions(),
  componentStyle: HiveComponentStyle.secret,
)
```

### Context-Based Styling

Use the `HiveComponentStyleHelper` to determine the appropriate style based on context:

```dart
Widget buildFeatureButton(BuildContext context) {
  // Determine the appropriate style based on feature context
  final style = HiveComponentStyleHelper.getComponentStyle(
    context: context,
    isNewFeature: feature.isNew,
    isCommunityFeature: feature.isCommunity,
    isExperimentalFeature: feature.isExperimental,
  );
  
  // Use the determined style
  return HiveButton(
    text: feature.title,
    onPressed: () => feature.launch(),
    componentStyle: style,
  );
}
```

### Screen-Level Style Application

For entire screens or sections:

```dart
class NewFeatureScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // For new features, use rebellion style
    final componentStyle = HiveComponentStyle.rebellion;
    
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        // Use style-specific attributes
        elevation: componentStyle == HiveComponentStyle.standard ? 0 : 2,
        title: Text('New Feature'),
      ),
      body: Column(
        children: [
          // Apply consistent styling to all components
          HiveCard(
            componentStyle: componentStyle,
            child: Text('Feature Description'),
          ),
          HiveButton(
            text: 'Continue',
            componentStyle: componentStyle,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
```

### Animation Style Application

Use the HiveAnimations class to create style-appropriate animations:

```dart
// In a StatefulWidget
late AnimationController _controller;
late Animation<double> _fadeAnimation;
late Animation<Offset> _slideAnimation;

@override
void initState() {
  super.initState();
  
  // Define the component style for this feature
  final componentStyle = HiveComponentStyle.rebellion;
  
  // Create controller with style-appropriate duration
  _controller = AnimationController(
    duration: componentStyle.getAnimationDuration(),
    vsync: this,
  );
  
  // Create animations with style-appropriate curves
  _fadeAnimation = HiveAnimations.createFadeIn(
    _controller,
    style: componentStyle,
  );
  
  _slideAnimation = HiveAnimations.createSlideUp(
    _controller,
    style: componentStyle,
  );
  
  _controller.forward();
}
```

### Glassmorphism Effects

Use the extension methods to apply style-specific glassmorphism:

```dart
Container(
  // Content
  child: Text('Content'),
).addStyledGlassmorphism(
  style: HiveComponentStyle.rebellion,
  // Optional overrides
  borderRadius: 8.0,
)
```

## Style Progression

Components should progress through the style variants as features mature:

1. New features start with Rebellion style to draw attention
2. As features become established, they transition to Standard style
3. Power user features use Secret style

## Visual Decision Tree

When implementing a new component or screen, use this decision tree:

1. **Is this a core app feature or established functionality?**
   - Yes → Use Standard style
   - No → Continue to question 2

2. **Is this a new feature, community-focused area, or student-exclusive functionality?**
   - Yes → Use Rebellion style
   - No → Continue to question 3

3. **Is this a power user feature, hidden functionality, or experimental feature?**
   - Yes → Use Secret style
   - No → Default to Standard style

## Best Practices

1. **Consistency**: Use the same style for all components within a feature
2. **Progressive Disclosure**: Use style progression to guide users from standard to more advanced features
3. **Meaningful Application**: Don't overuse Rebellion or Secret styles - they should indicate special functionality
4. **Performance**: Test animations on target devices to ensure smooth performance
5. **Accessibility**: Ensure sufficient contrast and touch targets regardless of style

## Implementation Checklist

When implementing components with the style system:
- [ ] Determine the appropriate style context for the feature
- [ ] Apply consistent styling to all components within the feature
- [ ] Use style-appropriate animations and transitions
- [ ] Include appropriate haptic feedback
- [ ] Test on different devices to ensure consistent experience
- [ ] Document any style-specific behaviors or interactions 