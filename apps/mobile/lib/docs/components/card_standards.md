# HIVE Card Standards

> "Cards aren't containers—they're canvases for curated experiences."

## Core Card Philosophy

Cards are foundational UI elements in HIVE that organize and present content in cohesive, visually pleasing surfaces. Every card should:

1. **Elevate content** through thoughtful presentation and hierarchy
2. **Respond elegantly** to user interaction with subtle animation
3. **Maintain visual consistency** while supporting content variety
4. **Feel premium** through proper surface treatment and material design

## Card Types

### Standard Content Card

The primary card type used throughout the app for displaying various content types.

#### Specifications:
- **Radius**: 20pt rounded corners
- **Background**: #1E1E1E to #2A2A2A gradient
- **Padding**: 16pt standard (outer spacing varies by context)
- **Shadow**: Subtle elevation (2-4pt)
- **Border**: None by default; 1px solid rgba(255, 255, 255, 0.06) when active
- **States**:
  - **Default**: Standard elevation
  - **Active/Pressed**: Subtle scale (98%), momentary darkness, inner glow
  - **Selected**: Gold outline (very subtle, 1px)

### Featured Card

Used for highlighted or promoted content. More visually prominent.

#### Specifications:
- **Radius**: Same as standard (20pt)
- **Background**: Enhanced gradient with subtle accent tint
- **Media treatment**: Higher-quality images, potentially with subtle parallax
- **Shadow**: Slightly higher elevation (4-6pt)

### Compact Card

Used in lists or space-constrained areas.

#### Specifications:
- **Height**: Fixed, content-dependent (typically 72-80pt)
- **Padding**: Reduced (12pt horizontal, 10pt vertical)
- **Layout**: Often uses horizontal arrangement with leading thumbnail
- **States**: Same as standard cards but with simpler animations

### Glass Card

Used for overlays and floating UI elements.

#### Specifications:
- **Effect**: Blur (20pt) with tint rgba(13, 13, 13, 0.8)
- **Border**: Subtle light border (0.5px, 5% opacity)
- **Gold accent**: Optional subtle gold streak (vertical fade from top)

## Card Anatomy

### Content Organization
- **Header**: Optional title area with consistent typography
- **Media**: Images maintain fixed aspect ratios (16:9, 4:3, 1:1)
- **Body**: Main content area with consistent text styles
- **Footer**: Optional action area (typically for buttons/interactions)

### Interaction Areas
- **Primary tap target**: Entire card (unless containing other interactive elements)
- **Secondary targets**: Clearly defined button areas within the card
- **Swipe areas**: When applicable, clear affordances for swipe actions

## Interaction Standards

### Touch Behavior
- **Tap animation**: Quick compress (98% scale) + subtle darkness (150ms)
- **Press-and-hold**: For contextual actions, with haptic feedback
- **Tap+release**: Returns to original state with slight overshoot

### Visual Feedback
- **On tap**: Subtle inner glow effect (inset)
- **On hover** (web): Slight elevation increase + soft parallax (Z: 2px)
- **Error state**: Subtle red tint (only when applicable)

### Transitions
- **Enter viewport**: Subtle fade + small upward movement (12px)
- **Exit viewport**: Quick fade out
- **Between states**: Smooth transitions (no abrupt changes)

## Implementation Guidelines

1. **Use consistent styling** for cards of the same type
2. **Implement proper animations** that follow HIVE motion standards
3. **Ensure proper content scaling** within cards
4. **Test interactions** across platforms
5. **Consider edge cases** like overflow content

### Media Treatment

All images within cards should:
- Use proper loading states (shimmer effect)
- Have consistent corner rounding (if rounded)
- Include subtle edge blur to integrate with the card background
- Support fallback for failed loads

```dart
// Example card with image
Card(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20.0),
  ),
  elevation: 4.0,
  child: Column(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            frameBuilder: (_, child, frame, __) {
              return frame == null
                  ? ShimmerLoadingEffect()
                  : child;
            },
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: // Content...
      ),
    ],
  ),
)
```

## Decision Matrix: When to Use Each Card Type

| Content Type | Card Type | Notes |
|--------------|-----------|-------|
| Feed items | Standard Card | Core content display |
| Highlighted content | Featured Card | For promotional or key content |
| List items | Compact Card | For dense information display |
| Overlays/tooltips | Glass Card | For contextual information |
| Live events | Standard + Gold accent | Add subtle gold animation |

## Accessibility Requirements

- **Focus states**: Cards with tap actions need visible focus indicators
- **Content contrast**: Text must meet 4.5:1 minimum contrast ratio
- **Semantic structure**: Proper heading hierarchy within cards
- **Touch targets**: Interactive elements minimum 44×44pt

## Implementation Examples

### Standard Content Card
```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.surfaceStart, // #1E1E1E
        AppColors.surfaceEnd,   // #2A2A2A
      ],
    ),
    borderRadius: BorderRadius.circular(20.0),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        offset: Offset(0, 2),
        blurRadius: 4.0,
      ),
    ],
  ),
  child: // Card content...
)
```

### Glass Card
```dart
ClipRRect(
  borderRadius: BorderRadius.circular(20.0),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
    child: Container(
      decoration: BoxDecoration(
        color: Color(0x0D0D0D).withOpacity(0.8),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: // Glass card content...
    ),
  ),
)
```

## Edge Cases and Considerations

- **Variable content**: Cards should gracefully handle different content lengths
- **Empty states**: Include proper empty state handling
- **Loading states**: Show shimmer effect during content loading
- **Error states**: Graceful error handling within the card
- **High-density layouts**: Ensure consistent spacing between multiple cards

---

For implementation help, see the following references:
- [Card Component Examples](mdc:lib/core/widgets/cards/)
- [Glassmorphism Usage Guide](mdc:lib/docs/glassmorphism_usage_guide.dart)
- [Dark Surface Implementation](mdc:lib/theme/dark_surface.dart) 