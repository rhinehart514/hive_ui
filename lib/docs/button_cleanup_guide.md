# HIVE UI Button Standardization Guide

## Overview

This guide provides instructions for standardizing button usage across the HIVE UI codebase by replacing Flutter's built-in buttons with our custom `HiveButton` component.

## Affected Components

Replace the following Flutter components:
1. `ElevatedButton`
2. `TextButton`
3. `OutlinedButton`
4. Any custom button implementations (e.g., `FlatButton`, `NeumorphicButton`, etc.)

## Target Files

Button usage is widespread, but focus first on these high-impact files:

1. `lib/pages/profile_page.dart`
2. `lib/pages/main_feed.dart`
3. `lib/pages/sign_in_page.dart`
4. `lib/pages/spaces.dart`
5. `lib/widgets/profile/*.dart`

## Replacement Guide

### Step 1: Add the Import

Add the following import to the top of the file:

```dart
import 'package:hive_ui/components/buttons.dart';
```

### Step 2: Replace Buttons

#### ElevatedButton Replacement

Replace:
```dart
ElevatedButton(
  onPressed: () { /* action */ },
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.gold,
    foregroundColor: Colors.black,
    // ... other style properties
  ),
  child: Text('Button Text'),
)
```

With:
```dart
HiveButton(
  text: 'Button Text',
  variant: HiveButtonVariant.primary,
  onPressed: () { /* action */ },
)
```

#### TextButton Replacement

Replace:
```dart
TextButton(
  onPressed: () { /* action */ },
  child: Text('Button Text'),
)
```

With:
```dart
HiveButton(
  text: 'Button Text',
  variant: HiveButtonVariant.text,
  onPressed: () { /* action */ },
)
```

#### OutlinedButton Replacement

Replace:
```dart
OutlinedButton(
  onPressed: () { /* action */ },
  style: OutlinedButton.styleFrom(
    foregroundColor: Colors.white,
    // ... other style properties
  ),
  child: Text('Button Text'),
)
```

With:
```dart
HiveButton(
  text: 'Button Text',
  variant: HiveButtonVariant.secondary, // Or tertiary depending on styling
  onPressed: () { /* action */ },
)
```

### Step 3: Handle Button Configuration

Adjust the following properties based on the original button's appearance:

#### Size

Choose the appropriate size based on the button's context:
- `HiveButtonSize.small` - for compact buttons (height: 36)
- `HiveButtonSize.medium` - for standard buttons (height: 44, default)
- `HiveButtonSize.large` - for prominent buttons (height: 54)

#### Variants

Choose the appropriate variant based on the button's appearance:
- `HiveButtonVariant.primary` - gold background, black text (for important actions)
- `HiveButtonVariant.secondary` - outlined with gold border and text (for secondary actions)
- `HiveButtonVariant.tertiary` - outlined with white border and text (for tertiary actions)
- `HiveButtonVariant.text` - text only, no background or border (for minor actions)

#### Width

For full-width buttons, add:
```dart
fullWidth: true,
```

#### Icons

If the button has an icon:
```dart
icon: Icons.add, // specify the icon
```

#### Haptic Feedback

Customize haptic feedback if needed:
```dart
hapticFeedback: true, // default is true
feedbackType: HapticFeedbackType.medium, // light, medium, heavy, or selection
```

## Examples

### Example 1: Primary Button

```dart
HiveButton(
  text: 'Create Post',
  variant: HiveButtonVariant.primary,
  size: HiveButtonSize.large,
  fullWidth: true,
  icon: Icons.add,
  onPressed: () => createNewPost(),
)
```

### Example 2: Text Button

```dart
HiveButton(
  text: 'Cancel',
  variant: HiveButtonVariant.text,
  onPressed: () => Navigator.pop(context),
)
```

### Example 3: Secondary Button

```dart
HiveButton(
  text: 'See More',
  variant: HiveButtonVariant.secondary,
  size: HiveButtonSize.small,
  onPressed: () => loadMoreItems(),
)
```

### Example 4: Disabled Button

```dart
HiveButton(
  text: 'Submit',
  variant: HiveButtonVariant.primary,
  onPressed: isValid ? () => submitForm() : null, // null makes it disabled
)
```

## Button Color Mapping

Use these guidelines to determine which variant to use:

| Original Color | HiveButton Variant |
|----------------|-------------------|
| AppColors.gold background | HiveButtonVariant.primary |
| Transparent with gold border | HiveButtonVariant.secondary |
| Transparent with white border | HiveButtonVariant.tertiary |
| No background or border | HiveButtonVariant.text |

## Testing After Replacement

After replacing a button:
1. Verify that the button appears with the correct styling
2. Test that the button's interaction (tap, disabled state) works correctly
3. Confirm that any state-dependent styling (like conditional colors) is preserved

## Cleanup Checklist

As you standardize buttons, update the following checklist:

- [ ] lib/pages/profile_page.dart
- [ ] lib/pages/main_feed.dart
- [ ] lib/pages/sign_in_page.dart
- [ ] lib/pages/spaces.dart
- [ ] lib/widgets/profile/*.dart 