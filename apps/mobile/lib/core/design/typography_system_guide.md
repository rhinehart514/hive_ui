# HIVE Typography System Guide - 2025-Ready Tech-Sleek Stack

## Overview

The HIVE Typography System implements a modern, 2025-ready font stack designed to feel cutting-edge while maintaining exceptional readability and performance across all platforms. This system follows the "tech-sleek" aesthetic inspired by ChatGPT, Midjourney dashboards, and premium AI interfaces.

## Font Stack Philosophy

### Primary Fonts

| Role | Primary Choice | Fallback | Why it feels 2025 AI |
|------|---------------|----------|---------------------|
| **Display / H1–H2** | Inter Tight (variable) | Inter | Ultra-compact counters, variable width-axis for bold yet space-efficient headlines—mirrors ChatGPT+Midjourney dashboards |
| **Body / UI** | Inter | System fonts | Humanist grotesque with tall x-height → high legibility on dark UIs; subtle warmth keeps us from looking sterile |
| **Code / Metrics** | JetBrains Mono | Menlo, Monaco | Punched-out "0" and slashed "Ø" aid Tool composer; variable weights let us surface code emphasis without color |
| **Editorial Accent** | Space Grotesk Semibold | Inter | Slight ink-traps give ritual countdowns a distinctive voice without adding a new color |

### Fallback Chain
All fonts include a comprehensive fallback chain for graceful degradation:
```
Inter → -apple-system → BlinkMacSystemFont → Segoe UI → Roboto → Helvetica Neue → Arial → sans-serif
```

## Scale & Rhythm (4-pt baseline)

Our typography follows a strict 4-point baseline grid with carefully calculated tracking for optimal dark-mode readability:

| Token | Size / Line | Tracking | Usage |
|-------|-------------|----------|--------|
| `text/h1` | 32 / 40 | -1% | Major screen titles, hero headlines |
| `text/h2` | 24 / 32 | -0.5% | Section headers, major divisions |
| `text/h3` | 20 / 28 | 0% | Subsection headers |
| `text/body` | 16 / 24 | 0.25% | Primary body text for comfortable reading |
| `text/caption` | 14 / 20 | 1% | Small utility text, timestamps, labels |
| `text/mono` | 13 / 20 | 0% | Code, metrics, technical displays |

## System Rules

### 1. One Sans, Everywhere
Body & UI share the same family (Inter); display cuts to the Tight axis or heavier weight for contrast.

### 2. Optical Sizing ON
Serve variable font with `opsz` axis so micro-text (Tool labels) gets extra spacing automatically.

### 3. Dark-mode Tuning
Bump tracking +2% below 16px to fight glow-blur on OLED displays. This is automatically applied via `applyDarkModetuning()` helper.

### 4. Haptics-to-Type Link
Every font-weight ramp over 500ms pairs with a light haptic (mobile) or subtle elevation shadow (web).

## Implementation

### Using the Typography System

#### Basic Usage
```dart
import 'package:hive_ui/core/design/typography_tokens.dart';

// Use predefined styles
Text(
  'Welcome to HIVE',
  style: TypographyTokens.h1,
)

// For body text
Text(
  'This is comfortable reading text',
  style: TypographyTokens.body,
)

// For code/metrics
Text(
  'user.id: 12345',
  style: TypographyTokens.mono,
)
```

#### Interactive States
```dart
// Create interactive (gold) variant
Text(
  'Join Space',
  style: TypographyTokens.makeInteractive(TypographyTokens.buttonPrimary),
)

// Create surging variant for dynamic emphasis
Text(
  'Live Event',
  style: TypographyTokens.makeSurging(TypographyTokens.body),
)

// Apply dark mode tuning for small text
Text(
  'Small label',
  style: TypographyTokens.applyDarkModetuning(TypographyTokens.caption),
)
```

#### Animation Support
```dart
// Font weight animation for surge effects
AnimatedDefaultTextStyle(
  duration: Duration(milliseconds: 400),
  style: isSurging 
    ? TypographyTokens.makeSurging(baseStyle)
    : baseStyle,
  child: Text('Dynamic content'),
)

// Using the custom FontWeightTween
AnimationController controller;
Animation<FontWeight> fontWeightAnimation = FontWeightTween(
  begin: FontWeight.w400,
  end: FontWeight.w600,
).animate(controller);
```

### Theme Integration

The typography system automatically integrates with Flutter's TextTheme:

```dart
// Access via Theme
Text(
  'Title',
  style: Theme.of(context).textTheme.headlineLarge, // Maps to TypographyTokens.h1
)

// Or use directly for more control
Text(
  'Title',
  style: TypographyTokens.h1,
)
```

## Mapping Guide

### Flutter TextTheme Mapping

| Flutter TextTheme | HIVE Typography | Font | Size | Weight | Usage |
|------------------|-----------------|------|------|--------|--------|
| `displayLarge` | `h1` | Inter Tight | 32pt | Bold | Hero headlines |
| `displayMedium` | `h2` | Inter Tight | 24pt | Semibold | Major sections |
| `displaySmall` | `h3` | Inter Tight | 20pt | Semibold | Subsections |
| `headlineLarge` | `h1` | Inter Tight | 32pt | Bold | Alias to displayLarge |
| `headlineMedium` | `h2` | Inter Tight | 24pt | Semibold | Alias to displayMedium |
| `headlineSmall` | `h3` | Inter Tight | 20pt | Semibold | Alias to displaySmall |
| `titleLarge` | `h3` | Inter Tight | 20pt | Semibold | Card titles |
| `titleMedium` | `labelLg` | Inter | 16pt | Semibold | Button text |
| `titleSmall` | `labelMd` | Inter | 14pt | Medium | Small titles |
| `bodyLarge` | `body` | Inter | 16pt | Regular | Primary text |
| `bodyMedium` | `bodySecondary` | Inter | 14pt | Regular | Secondary text |
| `bodySmall` | `caption` | Inter | 14pt | Regular | Captions |
| `labelLarge` | `buttonPrimary` | Inter | 16pt | Semibold | Button labels |
| `labelMedium` | `buttonSecondary` | Inter | 14pt | Medium | Small buttons |
| `labelSmall` | `caption` | Inter | 14pt | Regular | Utility labels |

## Performance Guidelines

### Font Loading
- All fonts are loaded via Google Fonts for optimal CDN delivery
- Variable fonts are preferred for optimal file size and performance
- Fallback fonts ensure immediate text rendering while web fonts load

### Optimization
- Use `const` constructors where possible for TextStyle definitions
- Leverage Flutter's text caching by reusing TextStyle instances
- Apply dark mode tuning only when necessary (small text < 16px)

## Accessibility

### Contrast Requirements
- All text meets WCAG AA standards (4.5:1 for normal text, 3:1 for large text)
- Gold accent (#FFD700) provides sufficient contrast against dark backgrounds
- Error states use high-contrast red (#FF3B30)

### Dynamic Type Support
- System respects user's font size preferences
- Minimum touch targets maintained (44×44pt mobile, 48×48px web)
- Line height ratios ensure comfortable reading at all sizes

## Brand Compliance

### Accent Usage Rules
- #FFD700 (Gold) is sacred - use ONLY for:
  - Interactive elements (`makeInteractive()`)
  - Live status indicators
  - Key triggers (Join, Submit, Live Now)
- NEVER use gold accent for:
  - Regular text content
  - Decorative elements
  - Backgrounds

### Variable Font Features
On surge states, animate font-weight 400→600 over 400ms instead of adding gold—keeps color discipline intact while still providing emphasis.

## Migration Guide

### From Old Typography System
```dart
// Old system
style: AppTypography.headlineLarge

// New system
style: TypographyTokens.h1

// Old interactive style
style: AppTypography.makeInteractive(AppTypography.body)

// New interactive style
style: TypographyTokens.makeInteractive(TypographyTokens.body)
```

### Best Practices
1. Always import from `typography_tokens.dart`, not legacy typography files
2. Use semantic names (h1, body, caption) over size-based names
3. Apply helper methods (makeInteractive, makeSurging) for state variants
4. Leverage dark mode tuning for improved OLED readability
5. Use animation helpers for smooth weight transitions

## Examples

### Complete Component Example
```dart
class EventCard extends StatefulWidget {
  final bool isLive;
  final bool isSurging;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event title - Display font for emphasis
            Text(
              'Campus Event Tonight',
              style: TypographyTokens.h3,
            ),
            SizedBox(height: 8),
            
            // Event description - Body text
            Text(
              'Join us for an amazing evening of music, food, and connection.',
              style: TypographyTokens.body,
            ),
            SizedBox(height: 12),
            
            // Event metadata - Caption with automatic dark mode tuning
            Text(
              'Tonight • 7:00 PM • Student Union',
              style: TypographyTokens.applyDarkModetuning(TypographyTokens.caption),
            ),
            SizedBox(height: 16),
            
            // Live indicator with surging animation
            AnimatedDefaultTextStyle(
              duration: Duration(milliseconds: 400),
              style: isSurging 
                ? TypographyTokens.makeSurging(TypographyTokens.ritualCountdown)
                : TypographyTokens.ritualCountdown,
              child: Text(isLive ? '● LIVE NOW' : 'Starting Soon'),
            ),
            
            SizedBox(height: 16),
            
            // Action button with proper typography
            ElevatedButton(
              onPressed: () {},
              child: Text(
                'Join Event',
                style: TypographyTokens.buttonPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

This typography system ensures HIVE feels modern, professional, and perfectly suited for the 2025 AI-native generation while maintaining exceptional readability and brand consistency across all platforms. 