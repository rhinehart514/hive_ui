# HIVE UI/UX Standards Guide

> "Beautiful interfaces emerge from controlled, elegant restraint and meticulous attention to interaction quality." - HIVE Design Philosophy

## Core Design Philosophy

The HIVE platform embraces sophisticated minimalism with an Apple-like premium quality and OpenAI-inspired clarity, wrapped in a social experience. Our interface embodies:

1. **Zero Visual Noise**: Every UI element justifies its existence by advancing comprehension or emotion
2. **Dark Infrastructure**: Premium black (#0D0D0D) background with gold accent (#FFD700) used sparingly for focus points
3. **Living Interface**: Subtle animations that respond to user interactions and social context
4. **System-Level Elegance**: Platform-native interaction patterns with physics-based animations

## Design System Components

| Component | Standard | Implementation | 
|-----------|----------|---------------|
| [Buttons](mdc:lib/docs/components/button_standards.md) | Consistent height (36pt), physics-based press animation, haptic feedback | `HivePrimaryButton`, `HiveSecondaryButton` |
| [Cards](mdc:lib/docs/components/card_standards.md) | Gradient surfaces, subtle shadows, consistent radius (20pt) | Various implementations |
| [Modals](mdc:lib/docs/components/modal_standards.md) | Z-zoom entrance with blur, slide dismissal | Custom implementations |
| [Forms](mdc:lib/docs/components/form_standards.md) | Consistent validation, responsive layouts | `BrandedTextField` and others |
| [Navigation](mdc:lib/docs/components/navigation_standards.md) | Platform-appropriate gestures, smooth transitions | Go Router implementation |

## Color System

Our color system is based on a token approach documented in [Color Token System](mdc:lib/docs/design_tokens/color_tokens.md).

- **Primary Background**: #0D0D0D (Deep Matte Black)
- **Secondary Surface**: #1E1E1E to #2A2A2A gradient
- **Text**: Pure #FFFFFF
- **Accent**: #FFD700 (Gold)

For a complete guide to color usage, see [app_colors.dart](mdc:lib/theme/app_colors.dart).

## Motion & Animation

HIVE animations follow iOS-inspired physics with precise timing as documented in [Animation Standards](mdc:lib/docs/animation_standards.md).

Animation durations:
- Micro-interactions: 150-200ms
- Page transitions: 300-350ms
- Modals: 400-500ms maximum

## Layout & Spacing

- **Mobile-first** design approach
- **16pt minimum** side padding, 24pt maximum
- Honor system **safe areas** on all platforms
- Proper layout adaptation across different screen sizes

## Typography

- **Font stack**: SF Pro (iOS/Web) → Inter (Android fallback)
- **Type scale**: 14/17/22/28/34pt only - no arbitrary font sizes
- **Headlines**: SF Pro Display / Medium / 28pt maximum
- **Body**: SF Pro Text / Regular / 17pt
- **Captions**: SF Pro Text / Regular / 14pt

## Space Customization Patterns

HIVE provides curated customization options for Space owners, including:

- **Visual Identity**: Controlled header images and theme choices
- **Structural Layout**: Modular components with consistent styling
- **Narrative Control**: Custom welcome messages and descriptions

See [Space Customization Guidelines](mdc:lib/docs/space_customization_guidelines.md) for details.

## Interactive Patterns

We've adopted proven interaction patterns from leading platforms while creating HIVE-specific innovations:

### Adopted Patterns
- Instagram-style double-tap reactions
- Pull-to-refresh with resistance
- Discord-style hierarchical content organization

### HIVE Originals
- Press-and-hold to get content context
- Slide-to-join interaction for rituals

## Accessibility Standards

All interfaces must meet:
- **Contrast ratios**: 4.5:1 for text ≤17pt; 3:1 for 18pt+ text
- **Touch targets**: 44×44pt (mobile); 48×48px (web)
- **Motion reduction** options
- Proper **screen reader** support

## Implementation Process

1. All UI components should be built with these standards in mind
2. Use existing components from `/core/widgets/` whenever possible
3. Follow atomic design principles for new components
4. Ensure platform-specific behavior works correctly

## Component Decision Tree

See [Component Selection Guide](mdc:lib/docs/component_selection_guide.md) for guidance on when to use each UI component type.

---

This document serves as the entry point to HIVE's comprehensive UI/UX standards. For detailed component-specific guides, refer to the linked documentation. 