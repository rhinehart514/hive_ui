# HIVE Color System Documentation

## Overview

The HIVE color system has been consolidated into a single, brand-compliant source of truth: **HiveColors**. This system follows the exact specifications in the HIVE brand aesthetic guidelines.

## Core Philosophy

- **Primary Background**: #0D0D0D (Deep Matte Black) - **Note**: The user requested #0F0F10, but brand aesthetic specifies #0D0D0D
- **Secondary Surface**: #1E1E1E to #2A2A2A gradient
- **Text**: Pure #FFFFFF
- **Accent**: #FFD700 (Gold) - **CRITICAL**: Use ONLY for focus rings, live status, key triggers

## File Structure

```
lib/core/theme/
├── hive_colors.dart          # ✅ NEW: Single source of truth
├── app_colors.dart           # 🔄 UPDATED: Now uses HiveColors
└── design_tokens.dart        # 🔄 UPDATED: Now uses HiveColors

lib/theme/
├── app_colors.dart           # 🔄 UPDATED: Facade over HiveColors
└── app_theme.dart            # 🔄 NEEDS UPDATE: Should use HiveColors

lib/constants/
└── app_colors.dart           # 🔄 UPDATED: Now uses HiveColors
```

## Migration Guide

### For New Code
```dart
// ✅ DO: Use HiveColors directly
import 'package:hive_ui/core/theme/hive_colors.dart';

Container(
  color: HiveColors.primaryBackground,
  child: Text(
    'Hello World',
    style: TextStyle(color: HiveColors.textPrimary),
  ),
)
```

### For Existing Code
```dart
// 🔄 COMPATIBLE: Existing imports still work
import 'package:hive_ui/theme/app_colors.dart';

Container(
  color: AppColors.dark, // Now points to HiveColors.primaryBackground
  child: Text(
    'Hello World',
    style: TextStyle(color: AppColors.textPrimary),
  ),
)
```

## Color Categories

### Core Brand Palette
- `HiveColors.primaryBackground` - #0D0D0D (Deep Matte Black)
- `HiveColors.surfaceStart` - #1E1E1E (Gradient start)
- `HiveColors.surfaceEnd` - #2A2A2A (Gradient end)
- `HiveColors.textPrimary` - #FFFFFF (Pure white)
- `HiveColors.accent` - #FFD700 (Gold accent)

### Gold Accent States
- `HiveColors.goldDefault` - #FFD700 (100% opacity)
- `HiveColors.goldHover` - #FFDF2B (+8% lightness)
- `HiveColors.goldPressed` - #CCAD00 (-15% lightness)
- `HiveColors.goldDisabled` - #FFD700 at 50% opacity

### Text Hierarchy
- `HiveColors.textPrimary` - #FFFFFF (Headlines, vital data)
- `HiveColors.textSecondary` - #B0B0B0 (Body copy, metadata)
- `HiveColors.textTertiary` - #757575 (Placeholder text)
- `HiveColors.textDisabled` - #666666 (Disabled elements)
- `HiveColors.textOnAccent` - #000000 (Text on gold backgrounds)

### Semantic Colors
- `HiveColors.success` - #8CE563 (Confirmations only)
- `HiveColors.error` - #FF3B30 (iOS standard)
- `HiveColors.warning` - #FF9500 (iOS standard)
- `HiveColors.info` - #56CCF2 (Neutral alerts)

### Gradients
- `HiveColors.surfaceGradient` - Standard surface gradient (#1E1E1E → #2A2A2A)
- `HiveColors.backgroundGradient` - Dark background variations
- `HiveColors.goldGradient` - Gold accent gradient (use sparingly)
- `HiveColors.glassGradient` - For glassmorphic effects

### Opacity Helpers
- `HiveColors.white10` - 10% white opacity
- `HiveColors.white20` - 20% white opacity
- `HiveColors.white30` - 30% white opacity
- `HiveColors.gold15` - 15% gold opacity
- `HiveColors.gold40` - 40% gold opacity

## Brand Compliance Rules

### ✅ CORRECT Gold Usage
```dart
// Focus rings
Container(
  decoration: BoxDecoration(
    border: Border.all(color: HiveColors.accent, width: 2),
  ),
)

// Live status indicators
Container(
  decoration: BoxDecoration(
    color: HiveColors.gold40, // With opacity for subtle effect
  ),
)

// Key triggers (buttons)
ElevatedButton(
  style: ElevatedButton.styleFrom(
    side: BorderSide(color: HiveColors.accent), // Border only
  ),
)
```

### ❌ INCORRECT Gold Usage
```dart
// NEVER use for backgrounds
Container(
  color: HiveColors.accent, // ❌ Too prominent
)

// NEVER use for text
Text(
  'Title',
  style: TextStyle(color: HiveColors.accent), // ❌ Poor readability
)

// NEVER use for decorative elements
Icon(
  Icons.star,
  color: HiveColors.accent, // ❌ Visual noise
)
```

## Extensions

The `HiveColorExtensions` provides additional utilities:

```dart
// Create lighter/darker variations
final lighterGold = HiveColors.accent.lighter(0.1);
final darkerSurface = HiveColors.surfaceStart.darker(0.2);
```

## Legacy Compatibility

All existing color classes now use HiveColors as their source:

- `AppColors.dark` → `HiveColors.primaryBackground`
- `AppColors.gold` → `HiveColors.accent`
- `AppColors.textDark` → `HiveColors.textPrimary`

Deprecated fields are marked with `@deprecated` to encourage migration.

## Testing

The color system includes utilities for testing:

```dart
// Material swatch generation
final swatch = HiveColors.createMaterialSwatch(HiveColors.accent);

// Opacity verification
expect(HiveColors.gold40.opacity, equals(0.4));
```

## Next Steps

1. Update `app_theme.dart` to use HiveColors throughout
2. Migrate component files to use HiveColors directly
3. Remove deprecated color definitions after migration
4. Add color system tests for brand compliance

## Support

For questions about the color system or brand compliance, refer to:
- `memory-bank/brand_aesthetic.md` - Complete brand guidelines
- This file - Implementation specifics
- Design team - For brand interpretation questions 