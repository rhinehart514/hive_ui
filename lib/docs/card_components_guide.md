# HIVE UI Card Components Guide

## Overview

Cards are a fundamental UI component in HIVE, used to group related content and actions. This guide outlines the different card types, their usage patterns, and implementation details.

## Card Types

### Standard Cards

Standard cards are the most basic container used throughout the app. They provide a consistent container with glassmorphism effects and subtle borders.

**Characteristics:**
- Pure black background (`AppColors.black`)
- Subtle white border (`AppColors.cardBorder`)
- Rounded corners (12px border radius)
- Light glassmorphism effect (15 blur, 0.08 opacity)
- Optional gold accent

**Usage:**
- Content containers
- List items
- Settings panels

### Profile Cards

Profile cards are specialized for displaying user information with a more premium look.

**Characteristics:**
- Darker background (`AppColors.grey800`)
- Gold accent border
- Higher corner radius (16px)
- Enhanced glassmorphism effect
- Shadow effects for depth

**Usage:**
- User profiles
- Profile sections
- User cards in lists

### Social Cards

Social cards are designed for user-generated content with interactions.

**Characteristics:**
- Standard black background
- Interactive hover/press states
- Action buttons
- Support for media content
- Engagement metrics (likes, comments)

**Usage:**
- Posts in feeds
- Shared content
- Comments

### Activity Cards

Activity cards display user activities with a distinctive icon and color.

**Characteristics:**
- Color-coded by activity type
- Prominent icon
- Concise information display
- Timestamp
- Light background effect that matches the activity color

**Usage:**
- Activity feeds
- Notification items
- Timeline events

## Implementation

### Base Card Component

The base card component uses glassmorphism and includes:

```dart
ProfileCard(
  type: ProfileCardType.main, // main, social, activity
  padding: const EdgeInsets.all(16),
  margin: const EdgeInsets.symmetric(vertical: 8),
  addGoldAccent: true, // Optional gold accent
  child: YourContent(),
)
```

### Card Types Enum

```dart
enum ProfileCardType {
  main,    // Standard card
  social,  // Social content card
  activity // Activity item card
}
```

### Responsive Considerations

- Cards maintain consistent horizontal margins (16-20px)
- Content padding remains consistent (16px)
- On smaller screens, reduce padding slightly (to 12px)
- For horizontal scrolling cards, maintain 80% width

## Theming Properties

### Glassmorphism

- **Blur**: 15 (standard cards)
- **Opacity**: 0.08 (standard), 0.1 (interactive)
- **Border**: 1px white at 8% opacity

### Shadows

- Light shadow: `Color(0x10FFFFFF)` with 4px blur, -1px y-offset
- Dark shadow: `Color(0x40000000)` with 6px blur, 2px y-offset
- Gold accent: `AppColors.gold.withOpacity(0.15)` with 10px blur

### Animations

- Hover scale: 1.02x with 150ms duration
- Press scale: 0.98x with 100ms duration
- Transition curves: `Curves.easeOutCubic` for natural movement

## Best Practices

1. **Maintain Consistency**: Use the same card type for similar content
2. **Content Density**: Don't overcrowd cards; maintain adequate spacing
3. **Hierarchy**: Use card elevation to establish hierarchy
4. **Interactivity**: Make it clear which cards are interactive
5. **Information Architecture**: Group related information within a card
6. **Accessibility**: Ensure adequate contrast for text on cards
7. **Performance**: Use `const` constructors where possible

## Examples

### Standard Content Card

```dart
ProfileCard(
  type: ProfileCardType.main,
  padding: const EdgeInsets.all(16),
  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Card Title',
        style: AppTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      Text(
        'Card content goes here with supporting information',
        style: AppTheme.bodyMedium,
      ),
    ],
  ),
)
```

### Interactive Social Card

```dart
ProfileCard(
  type: ProfileCardType.social,
  padding: const EdgeInsets.all(16),
  addGoldAccent: true,
  child: Column(
    children: [
      // Header with user info
      Row(
        children: [
          CircleAvatar(radius: 16),
          const SizedBox(width: 8),
          Text('Username', style: AppTheme.titleSmall),
        ],
      ),
      
      // Content
      const SizedBox(height: 12),
      Text('Post content...', style: AppTheme.bodyLarge),
      
      // Actions
      const SizedBox(height: 12),
      Row(
        children: [
          IconButton(icon: Icon(Icons.favorite_border)),
          IconButton(icon: Icon(Icons.comment_outlined)),
          IconButton(icon: Icon(Icons.share_outlined)),
        ],
      ),
    ],
  ),
)
```

### Activity Card

```dart
ProfileCard(
  type: ProfileCardType.activity,
  padding: const EdgeInsets.all(12),
  child: Row(
    children: [
      // Activity icon
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.gold.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.event, color: AppColors.gold),
      ),
      
      const SizedBox(width: 12),
      
      // Activity details
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Activity Title', style: AppTheme.titleSmall),
            Text('Activity description', style: AppTheme.bodySmall),
          ],
        ),
      ),
      
      // Timestamp
      Text('2h ago', style: AppTheme.bodySmall),
    ],
  ),
)
``` 