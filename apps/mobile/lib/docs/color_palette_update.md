# Color Palette Update (March 29, 2024)

This document outlines the recent updates to HIVE's color palette to align with our new brand aesthetic guidelines.

## Key Changes

1. **Base Background**: Changed from pure black (`#000000`) to dark gray (`#0A0A0A`)
2. **Gold/Yellow Standardization**: Unified gold and yellow to the same value (`#FFD700`)
3. **Secondary Text Color**: Standardized to light gray (`#BFBFBF`) 
4. **Gray Scale Adjustment**: Adjusted all gray values to create proper visual hierarchy with the new base color

## Color Mapping

| Purpose | Old Value | New Value | Notes |
|---------|-----------|-----------|-------|
| Background | `#000000` | `#0A0A0A` | Less harsh on OLED displays |
| Gold/Yellow | `#FFD600` | `#FFD700` | Used exclusively for interactive elements |
| Secondary Text | `#BBFFFFFF` | `#BFBFBF` | Improved readability |
| Card Background | `#050505` | `#0D0D0D` | Better contrast with base background |
| Button Secondary | `#111111` | `#151515` | Improved visibility of secondary actions |

## Implementation

The color updates have been applied to `lib/theme/app_colors.dart`, which serves as the source of truth for all colors in the application.

```dart
// Primary colors
static const Color black = Color(0xFF0A0A0A); // Updated from pure black
static const Color white = Color(0xFFFFFFFF);
static const Color gold = Color(0xFFFFD700); // Signal yellow
static const Color yellow = Color(0xFFFFD700); // Same as gold
```

## Yellow Usage Guidelines

Yellow (`#FFD700`) is now used exclusively as a cognitive signal for interactive elements requiring attention:

- RSVP buttons and confirmations
- "Honey Mode" featured events
- Repost tags and indicators
- Achievement badges
- Interactive call-to-action elements 

It should never be used as a background color or for purely decorative elements.

## Migration Notes

When implementing this updated color palette:

1. Replace any instances of pure black (`#000000`) with our new base color (`#0A0A0A`)
2. Ensure gold and yellow both use `#FFD700`
3. Update any custom gray values to maintain proper contrast with the new base color
4. Ensure correct use of yellow as a cognitive signal only

For the full brand aesthetic guidelines, refer to [`/lib/docs/brand_aesthetic.md`](/lib/docs/brand_aesthetic.md). 