# HIVE Design System - Core Components

This directory contains the official, production-ready HIVE design system components extracted from design system testing and validation.

## ✅ HiveCard System - LOCKED & EXTRACTED

**Status**: Production Ready  
**Extracted**: From comprehensive 10-task design system validation  
**Location**: `lib/core/design/hive_card.dart`

### Locked-in User Preferences:

- **Surface Treatment**: Sophisticated depth with premium shadows + minimalist flat for pressed states
- **Texture**: 2% grain texture overlay (locked preference)
- **Interactive**: Spring bounce animation with haptic feedback
- **Physics**: Ease curve timing (200ms duration)
- **Content Hierarchy**: Standard spacing (16pt)
- **Glass Treatment**: Frosted glass with backdrop blur
- **Responsive**: Adaptive grid layouts (1-4 columns)

### Components Included:

#### 1. HiveCard
```dart
// Primary sophisticated depth card
HiveCard.sophisticatedDepth(
  onTap: () => handleTap(),
  child: HiveCardContent(
    title: 'Event Title',
    subtitle: 'Event description',
    leading: Icon(Icons.event),
  ),
)

// Minimalist flat for pressed states
HiveCard.minimalistFlat(
  child: Text('Active state'),
)

// Frosted glass treatment
HiveCard.frostedGlass(
  child: Text('Premium glass'),
)
```

#### 2. HiveCardWithBackdrop
```dart
// Full backdrop filter glass effect
HiveCardWithBackdrop(
  onTap: () => {},
  child: HiveCardContent(
    title: 'Glass Card',
    subtitle: 'With blur effect',
  ),
)
```

#### 3. HiveCardGrid
```dart
// Responsive grid system
HiveCardGrid(
  cards: [
    HiveCard.sophisticatedDepth(child: Text('Card 1')),
    HiveCard.sophisticatedDepth(child: Text('Card 2')),
    // Auto-responsive: 1 col mobile, 2 tablet, 3-4 desktop
  ],
)
```

#### 4. HiveCardContent
```dart
// Standard content hierarchy helper
HiveCardContent(
  title: 'Title',
  subtitle: 'Subtitle',
  leading: Icon(Icons.star),
  trailing: Text('12:30'),
  hierarchy: HiveCardContentHierarchy.standard, // locked preference
)
```

### Features:

- **Haptic Feedback**: Light impact on tap
- **Spring Animation**: 97% scale on press with ease curve
- **Grain Texture**: 2% white opacity overlay
- **Responsive**: Auto-adapts 1→2→3→4 columns
- **Brand Compliance**: HIVE color system, premium shadows
- **Performance**: Optimized AnimatedScale and StatefulBuilder

### Usage Example:

```dart
import 'package:hive_ui/core/design/hive_card.dart';

// Event card with your locked preferences
HiveCard.sophisticatedDepth(
  onTap: () => Navigator.push(...),
  child: HiveCardContent(
    title: 'Campus Event',
    subtitle: 'Join the discussion',
    leading: Icon(Icons.event, color: Color(0xFFFFD700)),
    trailing: Text('2:30 PM'),
  ),
)
```

---

## Upcoming Components

### 🚧 HiveInput System
**Status**: In Development  
**Next**: Building on "smooth, tech, sleek" validation feedback

### 🚧 HiveButton System  
**Status**: Awaiting Validation  
**Components**: Focus rings, press physics, hover effects

### 🚧 HiveNavigation System
**Status**: Architecture Planning

---

## Design Philosophy

HIVE components follow the "Sophisticated Dark Infrastructure" philosophy:
- **Premium Feel**: Deep shadows, quality gradients, refined textures
- **Minimal Gold**: #FFD700 used sparingly for focus and live states
- **Physics-Based**: Real-world animation curves and haptic feedback
- **Responsive First**: Mobile→Tablet→Desktop adaptive layouts
- **Zero Visual Noise**: Every element justifies its existence

---

*Components in this directory are production-ready and follow the established HIVE brand guidelines. All variants have been validated through comprehensive design system testing.* 