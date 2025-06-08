# HIVE Component Selection Guide

> "Choosing the right component isn't about preference—it's about purpose."

## Introduction

This guide helps developers select the appropriate component for each use case in the HIVE app. Consistent component selection ensures a coherent user experience and maintains the premium quality of the application.

## Decision Trees

### Button Selection

```
Is this the primary action on the screen?
├── Yes → Is it a destructive action?
│   ├── Yes → Use HiveSecondaryButton with error color
│   └── No → Use HivePrimaryButton
└── No → Is it a secondary action?
    ├── Yes → Use HiveSecondaryButton
    └── No → Is it a minor/tertiary action?
        ├── Yes → Is it space-constrained?
        │   ├── Yes → Use TextButton
        │   └── No → Use HiveSecondaryButton (smaller variant)
        └── No → Is it a common action with a universally recognized icon?
            ├── Yes → Use IconButton
            └── No → Use HiveSecondaryButton
```

### Card Selection

```
What is the content purpose?
├── Main feed item → Use StandardContentCard
├── Highlighted content → Use FeaturedCard
├── Dense list item → Use CompactCard
├── Overlay/tooltip → Use GlassCard
└── Live/active content → Use StandardContentCard with gold accent
```

### Input Selection

```
What kind of input is needed?
├── Text input → What length?
│   ├── Single line → Use BrandedTextField
│   └── Multiple lines → Use BrandedTextArea
├── Selection → How many options?
│   ├── Binary choice → Use HiveToggleSwitch
│   ├── Few options (2-5) → Use HiveSegmentedControl
│   └── Many options → Use HiveDropdown
├── Date/Time → Use HiveDatePicker or HiveTimePicker
└── Media upload → Use HiveMediaUploader
```

### Navigation Selection

```
What type of navigation?
├── Primary navigation → Use HiveBottomBar
├── Tab navigation within a screen → Use HiveTabBar
├── Hierarchical navigation → Use nested routes with go_router
├── Modal presentation → Use HiveModalSheet
└── Contextual actions → Use HiveActionSheet
```

## Component Matrix By Context

| Context | Primary Component | Secondary Components | Notes |
|---------|-------------------|----------------------|-------|
| Authentication | HivePrimaryButton | BrandedTextField, HiveSecondaryButton | Focus on security and clarity |
| Feed | StandardContentCard | CompactCard, ActionButton | Optimize for content consumption |
| Profile | ProfileHeader | StatCard, HiveTabBar | Balance personal expression with consistent layout |
| Events | EventCard | DateDisplay, ActionButton | Emphasize time, location, and RSVP |
| Spaces | SpaceCard | MembersList, FeaturedSection | Community-focused components |
| Messaging | MessageBubble | InputBar, AttachmentPreview | Familiar messaging patterns |
| Settings | SettingsCard | HiveToggleSwitch, HiveRadioButton | Clarity and feedback on changes |

## Component Substitution Rules

When a specific component isn't available, follow these guidelines:

| Needed | Substitute | Adaptation |
|--------|------------|------------|
| Custom button | HiveSecondaryButton | Modify only colors within palette |
| Specialized card | StandardContentCard | Add custom content while maintaining outer structure |
| Complex input | BrandedTextField + helpers | Compose basic inputs rather than creating custom |
| Custom navigation | Standard navigation + custom transitions | Maintain system navigation patterns |

## Core Components Reference

### Buttons

| Component | Use Case | Import Path |
|-----------|----------|------------|
| HivePrimaryButton | Main actions, CTAs | `lib/core/widgets/hive_primary_button.dart` |
| HiveSecondaryButton | Alternative actions | `lib/core/widgets/hive_secondary_button.dart` |
| IconButton | Common icon-based actions | `flutter/material.dart` |
| TextButton | Minor text-based actions | `flutter/material.dart` |

```dart
// Primary Button example
HivePrimaryButton(
  label: 'Join Space',
  onPressed: handleJoin,
  isLoading: isLoading,
)

// Secondary Button example
HiveSecondaryButton(
  label: 'View Details',
  onPressed: showDetails,
  icon: Icons.info_outline,
)
```

### Cards

| Component | Use Case | Import Path |
|-----------|----------|------------|
| StandardContentCard | Main content display | `lib/core/widgets/cards/standard_content_card.dart` |
| FeaturedCard | Highlighted content | `lib/core/widgets/cards/featured_card.dart` |
| CompactCard | List items | `lib/core/widgets/cards/compact_card.dart` |
| GlassCard | Overlays and tooltips | `lib/core/widgets/cards/glass_card.dart` |

```dart
// Standard card example
StandardContentCard(
  title: 'Event Title',
  subtitle: 'Location • Date',
  imageUrl: event.coverImageUrl,
  onTap: () => showEvent(event.id),
)

// Glass card example
GlassCard(
  child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Text('Contextual information'),
  ),
)
```

### Inputs

| Component | Use Case | Import Path |
|-----------|----------|------------|
| BrandedTextField | Text input | `lib/core/widgets/branded_text_field.dart` |
| BrandedTextArea | Multiline text input | `lib/core/widgets/branded_text_area.dart` |
| HiveDropdown | Selection from many options | `lib/core/widgets/hive_dropdown.dart` |
| HiveToggleSwitch | Binary selection | `lib/core/widgets/hive_toggle_switch.dart` |

```dart
// Text field example
BrandedTextField(
  controller: emailController,
  label: 'Email',
  hint: 'Enter your email address',
  keyboardType: TextInputType.emailAddress,
  validator: validateEmail,
)

// Toggle example
HiveToggleSwitch(
  value: notificationsEnabled,
  onChanged: (value) => updateNotifications(value),
  label: 'Enable Notifications',
)
```

### Navigation

| Component | Use Case | Import Path |
|-----------|----------|------------|
| HiveBottomBar | Main app navigation | `lib/core/widgets/navigation/hive_bottom_bar.dart` |
| HiveTabBar | In-screen tab navigation | `lib/core/widgets/navigation/hive_tab_bar.dart` |
| HiveModalSheet | Modal presentation | `lib/core/widgets/navigation/hive_modal_sheet.dart` |
| HiveAppBar | Screen headers | `lib/core/widgets/navigation/hive_app_bar.dart` |

```dart
// Tab bar example
HiveTabBar(
  tabs: [
    HiveTab(label: 'Upcoming'),
    HiveTab(label: 'Past'),
    HiveTab(label: 'Saved'),
  ],
  controller: tabController,
)

// Modal sheet example
HiveModalSheet.show(
  context: context,
  title: 'Event Details',
  child: EventDetailsContent(event: event),
)
```

## Component Selection Best Practices

1. **Start with existing components**: Always check if a suitable component already exists before creating custom solutions.

2. **Consider the hierarchy**: Choose components that properly reflect the hierarchy of information and actions.

3. **Maintain consistency**: Use the same component for the same purpose throughout the app.

4. **Respect platform patterns**: Consider platform-specific expectations, particularly for navigation and inputs.

5. **Think about context**: A primary action in one context might be secondary in another.

6. **Consider states**: Ensure your chosen component supports all required states (loading, error, disabled, etc.).

7. **Performance impact**: More complex components have higher performance costs. Use the simplest component that meets the needs.

## Extending the Component Library

When new UI patterns emerge that aren't covered by existing components:

1. First, try **composing existing components** to meet the need.
2. If truly unique, **create a new component** following HIVE design principles.
3. **Document the new component** in this guide.
4. **Consider backward compatibility** for older app versions.

Follow these steps when creating a new component:

```dart
// Example of extending the component library
class HiveCustomComponent extends StatelessWidget {
  const HiveCustomComponent({
    Key? key,
    required this.title,
    required this.onAction,
    this.isActive = false,
  }) : super(key: key);

  final String title;
  final VoidCallback onAction;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    // Follow HIVE design system principles
    // Reuse existing styling patterns
    // Handle all appropriate states
    // Consider accessibility
    return // Implementation
  }
}
```

## Common Anti-Patterns

| Anti-Pattern | Alternative Approach |
|--------------|----------------------|
| Custom button styles | Use HivePrimaryButton or HiveSecondaryButton with standard parameters |
| Direct Container usage for cards | Use StandardContentCard or other Card components |
| Raw TextFields | Use BrandedTextField with proper validation |
| Custom navigation schemes | Use standard navigation patterns with go_router |
| Hard-coded colors/styles | Use ThemeData and AppColors tokens |

---

Remember: Component selection isn't just about visual consistency—it's about creating predictable, learnable patterns that enhance usability while maintaining HIVE's premium aesthetic. 