# ⚠️ DEPRECATED DOCUMENT ⚠️

> **IMPORTANT**: This document is no longer maintained and may contain outdated information. The current brand aesthetics documentation is now available at [`/lib/docs/brand_aesthetic.md`](/lib/docs/brand_aesthetic.md).

---

# HIVE UI Glassmorphism Design System

## Overview

The HIVE UI implements a consistent glassmorphism design system that creates a modern, clean interface with a black and white color scheme accented with gold highlights. This document outlines the key principles, components, and usage guidelines for maintaining a cohesive glassmorphism appearance throughout the app.

## What is Glassmorphism?

Glassmorphism is a UI design trend that features:
- Frosted glass effect (background blur)
- Semi-transparent containers/cards
- Subtle borders
- Light shadows to create depth
- Minimal, clean aesthetics

In HIVE, we've embraced this style to create a premium, modern look that:
- Maintains readability and accessibility
- Creates clear visual hierarchy
- Provides a consistent brand experience
- Feels contemporary and premium

## Core Components

### 1. GlassmorphismGuide

The `GlassmorphismGuide` class (`lib/theme/glassmorphism_guide.dart`) contains all standardized values for blur, opacity, shadows, and borders. This is the central source of truth for our design system.

Key constants:
- `kStandardBlur`, `kHeaderBlur`, `kCardBlur`, `kModalBlur` - Different blur intensities
- `kStandardGlassOpacity`, `kCardGlassOpacity`, `kModalGlassOpacity` - Opacity levels
- `kBorderWidth`, `kBorderOpacity` - Border styling
- `kStandardRadius`, `kModalRadius` - Border radius values

### 2. GlassmorphismExtension

The `GlassmorphismExtension` (`lib/extensions/glassmorphism_extension.dart`) provides easy-to-use methods to apply glassmorphism to any widget:

```dart
// Standard card or container
Widget someWidget = Container(...).addGlassmorphism();

// Modal or dialog
Widget modalWidget = Column(...).addModalGlassmorphism();

// Header or app bar
Widget headerWidget = AppBar(...).addHeaderGlassmorphism();
```

## Usage Guidelines

### General Principles

1. **Maintain Visual Hierarchy**
   - More important elements should have higher opacity (more visible)
   - Modal dialogs use stronger blur than background elements
   - Depth is conveyed through blur intensity and shadows

2. **Consistent Border Treatment**
   - All glassmorphic elements have a thin, subtle border
   - Border opacity is consistent (0.1)
   - Border width is standardized (0.5px)

3. **Background & Contrast**
   - Always ensure sufficient contrast for text readability
   - Dark backgrounds with light text are preferred
   - Gold accents for interactive elements and highlights

### When to Use Each Style

#### Standard Glassmorphism (`addGlassmorphism()`)
- Cards, list items, non-modal containers
- Content sections that need subtle separation from background
- Default opacity: 40%
- Default blur: 2.0

#### Modal Glassmorphism (`addModalGlassmorphism()`)
- Bottom sheets, dialogs, popovers
- Elements that need to float above main content
- Often include gold accent in shadows
- Higher opacity: 70%
- Stronger blur: 3.0

#### Header Glassmorphism (`addHeaderGlassmorphism()`)
- Navigation bars, tab bars, sticky headers
- Elements that need to stand out but not distract
- Medium opacity: 40-50%
- Medium blur: 2.5

### Layout Recommendations

1. **Spacing**
   - Maintain consistent spacing between glassmorphic elements
   - Use the app's standard spacing system (8, 16, 24px increments)

2. **Stacking & Z-index**
   - Use blur intensity to reinforce z-index hierarchy
   - Higher elements = stronger blur
   - Avoid stacking too many transparent elements

3. **Performance Considerations**
   - Limit the number of blurred elements on a single screen
   - Consider using opacity without blur for less critical elements
   - Test performance on older devices

## Implementation Examples

### Profile Card
```dart
Column(
  children: [
    // Profile content
  ],
).addGlassmorphism(
  blur: GlassmorphismGuide.kCardBlur,
  opacity: GlassmorphismGuide.kCardGlassOpacity,
  addGoldAccent: true,
);
```

### Modal Dialog
```dart
Dialog(
  child: Column(
    children: [
      // Modal content
    ],
  ).addModalGlassmorphism(),
);
```

### Tab Bar
```dart
TabBar(
  // TabBar configuration
).addHeaderGlassmorphism();
```

## Best Practices

1. **Avoid Overdoing It**
   - Not every element needs to be glassmorphic
   - Use sparingly for maximum impact

2. **Maintain Black & White + Gold Scheme**
   - The glassmorphism effect works best with our color palette
   - Avoid introducing other accent colors that compete

3. **Test Readability**
   - Always ensure text remains readable on transparent backgrounds
   - Increase opacity if content becomes hard to read

4. **Consistent Blur Values**
   - Stick to the standardized blur values
   - Don't create custom blur values unless absolutely necessary

5. **Consider Accessibility**
   - Some users may have difficulty with transparent interfaces
   - Ensure all content meets accessibility guidelines for contrast

## Troubleshooting

### Common Issues

1. **Text Readability Problems**
   - Solution: Increase background opacity or add text shadow

2. **Blurry/Pixelated Edges**
   - Solution: Add ClipRRect with same border radius as container

3. **Performance Issues**
   - Solution: Reduce number of blurred elements or use lighter blur effects

## Future Considerations

As we evolve the HIVE UI, we may extend the glassmorphism system to include:
- Animation guidelines for transitions between glassmorphic states
- Responsive adaptations for different screen sizes
- Light theme variations of glassmorphism effects 