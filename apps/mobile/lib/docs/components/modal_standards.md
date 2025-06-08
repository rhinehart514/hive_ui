# HIVE Modal Standards

> "Modals aren't interruptions—they're focused moments of attention."

## Core Modal Philosophy

Modals in HIVE create focused interaction spaces that temporarily elevate above the main interface. Every modal should:

1. **Serve a clear purpose** that requires user attention
2. **Enter and exit gracefully** with appropriate physics
3. **Maintain visual coherence** with the HIVE aesthetic
4. **Respect user control** with intuitive dismissal

## Modal Types

### Standard Modal Sheet

The primary modal type for presenting focused content or actions.

#### Specifications:
- **Entrance**: Slide up from bottom with slight zoom (scale 0.95 → 1.0)
- **Background**: Blur depth increase + dim to 50% opacity
- **Corner radius**: 20pt on top corners only
- **Max height**: 90% of screen height
- **States**:
  - **Entrance**: 320ms, cubic-bezier(0.25, 0.8, 0.30, 1)
  - **Exit**: 250ms, cubic-bezier(0.4, 0, 0.2, 1)
  - **Swipe dismiss**: Interactive with velocity tracking

### Dialog Modal

Used for critical information or confirmation that requires explicit action.

#### Specifications:
- **Entrance**: Fade in + subtle zoom (scale 0.9 → 1.0)
- **Background**: Same as Standard Modal
- **Corner radius**: 20pt on all corners
- **Max width**: 80% of screen width on mobile, 420pt on larger screens
- **States**: Similar to Standard Modal but typically not swipe-dismissible

### Quick Action Sheet

Used for contextual actions related to on-screen content.

#### Specifications:
- **Entrance**: Quick slide up (250ms)
- **Height**: Auto-sized to content, maximum 70% of screen
- **Layout**: List of actions with icons
- **Dismissal**: Tap outside, swipe down, or select an action

### Alert Modal

Used for critical information that requires acknowledgment.

#### Specifications:
- **Entrance**: Quick zoom with attention-getting animation
- **Size**: Compact, centered
- **Content**: Clear message + action buttons
- **Dismissal**: Explicit button tap only

## Modal Anatomy

### Header Section
- **Title**: Clear, concise heading (maximum 1-2 lines)
- **Close button**: Consistent placement (top-right)
- **Drag handle**: Visible indicator for swipeable modals
- **Divider**: Subtle separation from content (optional)

### Content Section
- **Padding**: Consistent 24pt horizontal padding
- **Scroll behavior**: Contained scrolling that doesn't affect modal position
- **Content organization**: Clear visual hierarchy

### Action Section
- **Button placement**: Bottom-aligned, full width on mobile
- **Primary action**: Right-aligned or bottom position
- **Cancel action**: Left-aligned or top position
- **Safe area**: Respect device safe areas

## Interaction Standards

### Touch Behavior
- **Backdrop**: Tap to dismiss (except for critical modals)
- **Swipe**: Natural physics with velocity and edge resistance
- **Buttons**: Standard HIVE button behavior within modals

### Visual Feedback
- **On swipe**: Modal follows finger with resistance at edges
- **Dismiss attempt on forced modal**: Brief shake or bounce
- **State transitions**: Smooth animations between loading states

### Keyboard Handling
- **Escape key**: Dismisses non-critical modals
- **Return/Enter key**: Typically triggers primary action
- **Tab order**: Logical focus progression through modal elements

## Implementation Guidelines

1. **Use the modal system** rather than creating custom implementations
2. **Implement proper animations** that follow HIVE motion standards
3. **Handle all edge cases** like device rotation and keyboard appearance
4. **Test interactions** across platforms

### Dismissal Handling

Modals must handle dismissal appropriately:

- **Unsaved changes**: Confirm before dismissing
- **In-progress operations**: Prevent dismissal or confirm
- **Completed actions**: Auto-dismiss after success feedback

```dart
// Example modal with dismissal handling
HiveModalSheet.show(
  context: context,
  isDismissible: !hasUnsavedChanges,
  onDismissPrevent: () {
    // Show confirmation dialog if needed
    if (hasUnsavedChanges) {
      showConfirmationDialog(
        title: 'Discard changes?',
        message: 'Your unsaved changes will be lost.',
        onConfirm: () => Navigator.of(context).pop(),
      );
      return false; // Prevent immediate dismissal
    }
    return true; // Allow dismissal
  },
  builder: (context) => YourModalContent(),
);
```

## Decision Matrix: When to Use Each Modal Type

| Context | Modal Type | Notes |
|---------|-----------|-------|
| View details | Standard Modal | For expanded content |
| Confirmation | Dialog Modal | For important decisions |
| Multiple options | Quick Action Sheet | For contextual choices |
| Critical alert | Alert Modal | For errors or warnings |
| Form input | Standard Modal | For focused data entry |

## Accessibility Requirements

- **Focus management**: Initial focus on appropriate element
- **Keyboard navigation**: Full keyboard control
- **Screen readers**: Proper ARIA roles and announcements
- **Reduced motion**: Simplified animations when accessibility settings enabled

## Technical Implementation

HIVE provides a consistent modal implementation through the `HiveModalSheet` component:

```dart
// Standard modal example
HiveModalSheet.show(
  context: context,
  title: 'Event Details',
  hasCloseButton: true,
  isSwipeDismissible: true,
  backgroundColor: AppColors.surfaceBackground,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Image.network(
        event.coverImageUrl,
        height: 200,
        fit: BoxFit.cover,
      ),
      Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: TextStyles.heading,
            ),
            const SizedBox(height: 8),
            Text(
              event.description,
              style: TextStyles.body,
            ),
          ],
        ),
      ),
      const Spacer(),
      Padding(
        padding: const EdgeInsets.all(24.0),
        child: HivePrimaryButton(
          label: 'RSVP',
          onPressed: () => handleRsvp(event.id),
          fullWidth: true,
        ),
      ),
    ],
  ),
);
```

### Dialog example:

```dart
HiveDialog.show(
  context: context,
  title: 'Delete Post',
  message: 'Are you sure you want to delete this post? This action cannot be undone.',
  primaryAction: HiveDialogAction(
    label: 'Delete',
    isDestructive: true,
    onPressed: () => deletePost(postId),
  ),
  secondaryAction: HiveDialogAction(
    label: 'Cancel',
    onPressed: () => Navigator.of(context).pop(),
  ),
);
```

## Edge Cases and Considerations

- **Nested modals**: Generally avoid; if necessary, handle dismissal appropriately
- **Modal over modal**: Consider using a different approach like progressive disclosure
- **Long content**: Test scrolling behavior and ensure proper truncation/pagination
- **Device rotation**: Handle orientation changes without disrupting the modal
- **Notches and cutouts**: Test on devices with screen cutouts to ensure proper display
- **Deep linking**: Consider how modals interact with deep links and navigation

## Performance Guidelines

- **Animation performance**: Target 60fps for all modal animations
- **Content loading**: Show loading states when fetching modal content
- **Memory management**: Dispose controllers and listeners when modal is dismissed
- **Render optimizations**: Use const where possible and optimize rebuild scope

---

For implementation help, see the following references:
- [HiveModalSheet Implementation](mdc:lib/core/widgets/modals/hive_modal_sheet.dart)
- [HiveDialog Implementation](mdc:lib/core/widgets/modals/hive_dialog.dart)
- [Modal Animation Standards](mdc:lib/docs/animation_standards.md) 