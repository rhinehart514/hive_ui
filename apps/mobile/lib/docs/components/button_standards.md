# HIVE Button Standards

> "Buttons must provide immediate tactile delight while clearly signaling their intention."

## Core Button Philosophy

Buttons in HIVE provide consistent, delightful interaction points that follow iOS-inspired physics while maintaining the HIVE aesthetic of sophisticated restraint. Every button should:

1. **Communicate purpose** clearly through design, position, and label
2. **Respond instantly** to touch with animation and haptic feedback
3. **Feel premium** through subtle motion and carefully designed states
4. **Maintain consistency** across the entire application

## Button Types

### Primary Buttons (`HivePrimaryButton`)

Used for main actions and CTAs. Implemented via `HivePrimaryButton`.

#### Specifications:
- **Height**: Fixed 36pt (44pt for large touch targets)
- **Radius**: 24pt (pill shape)
- **Color**: Context-dependent, often uses gold accent
- **States**:
  - **Default**: Filled background
  - **Pressed**: Scale to 98%, darkened by 10%
  - **Focus**: Gold ring (2px)
  - **Disabled**: 50% opacity

```dart
// Example implementation
HivePrimaryButton(
  label: 'Join Space',
  onPressed: () => spaceController.join(),
  isLoading: isJoining,
)
```

### Secondary Buttons (`HiveSecondaryButton`)

Used for secondary actions. Implemented via `HiveSecondaryButton`.

#### Specifications:
- **Height**: Same as Primary (36pt)
- **Border**: 1px with 50% opacity
- **Background**: Transparent
- **States**: Similar to primary but with border emphasis

```dart
// Example implementation
HiveSecondaryButton(
  label: 'View Details',
  onPressed: () => showEventDetails(),
  icon: Icons.info_outline,
)
```

### Text Buttons

Used for tertiary actions or in space-constrained areas.

#### Specifications:
- **Padding**: Horizontal 12pt, Vertical 8pt
- **States**: 
  - **Default**: Text only, no background
  - **Pressed**: 10% opacity background fill, subtle scale

### Icon Buttons

Used for common actions where the icon is universally understood.

#### Specifications:
- **Touch target**: Minimum 44×44pt
- **Icon size**: 24pt standard
- **States**: Similar to text buttons but with icon opacity changes

## Interaction Standards

### Touch Behavior
- **Press animation**: 120ms ease-out
- **Release animation**: 150ms ease-in with slight overshoot
- **Haptic feedback**: Light impact on press
- **Minimum touch target**: 44×44pt regardless of visual size

### Ergonomic Placement
- **Primary actions**: Bottom of screen or card
- **Secondary actions**: Adjacent to primary but visually distinct
- **Destructive actions**: Require confirmation and use error colors

## Implementation Guidelines

1. **Always use existing button components** rather than creating custom implementations
2. **Ensure haptic feedback** is properly implemented (platform-appropriate)
3. **Test animations** on low-end devices to ensure smoothness
4. **Verify button states** (pressed, disabled, loading) function correctly

### Loading States

All buttons should support a loading state that:
- Displays a properly styled activity indicator
- Disables interaction during loading
- Maintains the button's size to prevent layout shifts

```dart
// Example with loading state
HivePrimaryButton(
  label: 'Create Event',
  onPressed: isLoading ? null : () => createEvent(),
  isLoading: isLoading,
)
```

## Decision Matrix: When to Use Each Button Type

| Context | Button Type | Notes |
|---------|-------------|-------|
| Primary user flow | Primary Button | User journey's main path |
| Alternative action | Secondary Button | Less common but important action |
| Destructive action | Secondary Button (red) | Use error color, confirmation required |
| Navigation | Text Button | For navigation within a flow |
| Common action | Icon Button | Only for universally recognized icons |

## Accessibility Requirements

- **Labels**: All buttons must have descriptive labels
- **Contrast**: 4.5:1 minimum ratio against background
- **Touch target**: Never smaller than 44×44pt
- **Animation**: Must respect reduced motion settings

## Implementation Examples

### Primary Button
```dart
HivePrimaryButton(
  label: 'Create Account',
  onPressed: () => createUserAccount(),
  fullWidth: true,
)
```

### Secondary Button
```dart
HiveSecondaryButton(
  label: 'Learn More',
  onPressed: () => showInfoModal(),
  iconPosition: IconPosition.leading,
  icon: Icons.info_outline,
)
```

### Icon Button
```dart
IconButton(
  icon: Icon(Icons.share_outlined, color: AppColors.white),
  onPressed: () => shareContent(),
  tooltip: 'Share',
)
```

## Edge Cases and Considerations

- **Long text**: Buttons should truncate with ellipsis if text overflows
- **RTL languages**: Button icons must flip positions appropriately
- **Small screens**: On very small screens, prioritize primary buttons
- **Keyboard navigation**: Buttons must have proper tab order and focus states

---

For implementation help, see the following references:
- [HivePrimaryButton](mdc:lib/core/widgets/hive_primary_button.dart)
- [HiveSecondaryButton](mdc:lib/core/widgets/hive_secondary_button.dart)
- [Animation Durations](mdc:lib/theme/animation_durations.dart) 