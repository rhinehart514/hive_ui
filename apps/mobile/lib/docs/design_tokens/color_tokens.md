# HIVE Color Token System

> "Our color palette isn't just dark—it's considered, elegant darkness with purpose."

## Core Color Philosophy

HIVE's color system embodies sophisticated restraint through a disciplined approach to color usage. We employ a dark infrastructure with carefully placed gold accents to create a premium experience. This system ensures:

1. **Visual harmony** across all screens and surfaces
2. **Emotional cues** through sparing use of accent colors
3. **Focus direction** by emphasizing what matters
4. **Brand reinforcement** through consistent application

## Primary Color Palette

### Foundation Colors

| Token | Hex | Usage |
|-------|-----|-------|
| `background.primary` | #0D0D0D | Main app background |
| `background.secondary` | #141414 | Subtle background variation |
| `surface.start` | #1E1E1E | Card gradient start |
| `surface.end` | #2A2A2A | Card gradient end |
| `surface.elevated` | #333333 | Higher elevation surfaces |

### Text Colors

| Token | Hex | Usage |
|-------|-----|-------|
| `text.primary` | #FFFFFF | Main text |
| `text.secondary` | #CCCCCC | Secondary text |
| `text.tertiary` | #999999 | Subdued text |
| `text.disabled` | #666666 | Disabled state text |

### Brand Accent

| Token | Hex | State |
|-------|-----|-------|
| `accent.primary` | #FFD700 | Default gold accent |
| `accent.hover` | #FFDF2B | Hover/focus state (+8% lightness) |
| `accent.pressed` | #CCAD00 | Pressed state (–15% lightness) |
| `accent.disabled` | #FFD70080 | Disabled state (50% opacity) |

## Semantic Colors

### Status Colors

| Token | Hex | Usage |
|-------|-----|-------|
| `status.success` | #8CE563 | Success states, confirmations |
| `status.error` | #FF3B30 | Error states, destructive actions |
| `status.warning` | #FF9500 | Warning states, caution needed |
| `status.info` | #56CCF2 | Information, neutral notifications |

### Functional Colors

| Token | Hex | Usage |
|-------|-----|-------|
| `interactive.active` | #3D7BFF | Interactive elements |
| `interactive.focus` | #FFD700 | Focus rings (gold) |
| `overlay.scrim` | #00000080 | Modal backdrop |
| `overlay.glass` | #0D0D0DCC | Glass effect base |

## Gradients & Effects

### Surface Gradients

| Token | Definition | Usage |
|-------|------------|-------|
| `gradient.surface` | #1E1E1E → #2A2A2A, 135° | Standard card surfaces |
| `gradient.featured` | #232323 → #2F2F2F, 135° | Featured content |
| `gradient.glass` | #0D0D0DCC with blur(20px) | Overlays and modals |

### Special Effects

| Token | Definition | Usage |
|-------|------------|-------|
| `effect.goldShimmer` | Animated subtle gold glow | Live status indicators |
| `effect.innerGlow` | Inner shadow white(0.03) | Active cards |
| `effect.grain` | 3% transparent noise texture | Canvas texture |

## Usage Guidelines

### Color Hierarchy

1. **Background Tier**: The deepest layer (primary background)
2. **Surface Tier**: Cards and containers (gradients)
3. **Content Tier**: Text and media
4. **Accent Tier**: Gold highlights (use sparingly!)

### Contrast Requirements

All text must meet WCAG 2.1 AA standards:
- 4.5:1 minimum for normal text (≤17pt)
- 3:1 minimum for large text (≥18pt)
- 3:1 minimum for UI components and graphical objects

### Gold Accent Rules

The gold accent (#FFD700) is sacred. Use ONLY for:
- Focus rings
- Live status indicators
- Key triggers (Join, Submit, Live Now)

NEVER use gold accent for:
- Large text blocks
- Background fills
- Decorative elements without purpose

## Implementation

### In Dart Code

Colors should always be accessed through the `AppColors` class, never hardcoded:

```dart
// CORRECT usage
Text(
  'HIVE',
  style: TextStyle(
    color: AppColors.textPrimary,
    fontSize: 28,
  ),
)

// INCORRECT - never hardcode
Text(
  'HIVE', 
  style: TextStyle(
    color: Color(0xFFFFFFFF), // Wrong! Use AppColors.textPrimary
    fontSize: 28,
  ),
)
```

### For Gradients

Use the predefined gradient tokens:

```dart
Container(
  decoration: BoxDecoration(
    gradient: AppColors.surfaceGradient,
    borderRadius: BorderRadius.circular(20),
  ),
  child: // Content
)
```

## Color Context Sensitivity

Some colors should adapt based on context:

| Context | Adaptation |
|---------|------------|
| Dark mode only | Our default - all colors designed for dark |
| High contrast mode | Increase contrast ratios by 30% |
| Reduced motion | Remove subtle color animations |
| Error states | Apply subtle error tint to backgrounds |

## Extending The System

When new UI patterns require color extensions:

1. **First try** using existing tokens in new combinations
2. **If needed**, propose new token with clear purpose
3. **Document** the token with usage guidelines
4. **Add** to `AppColors` in a backward-compatible way

Always maintain semantic meaning in color choices.

## Color Audit Process

1. Run accessibility checks using automated tools
2. Verify all colors are accessed via the token system
3. Check color combinations against approved pairings
4. Validate interaction states (hover, focus, pressed)

## References

- [AppColors Implementation](mdc:lib/theme/app_colors.dart)
- [Dark Surface Implementation](mdc:lib/theme/dark_surface.dart)
- [Glassmorphism Usage Guide](mdc:lib/docs/glassmorphism_usage_guide.dart)

---

Remember: Color decisions are not aesthetic preferences but functional choices that impact usability, recognition, and emotional response. The HIVE color system is designed to create a premium, sophisticated experience through restraint and purpose. 