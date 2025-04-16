# HIVE Stylistic System

## 0. Introduction

### Purpose of this Guide
This document serves as the definitive source of truth for HIVE's design system, providing a cohesive set of rules and principles that guide the visual and interactive experience of the platform.

### How to Use This Document
Reference this document when designing new features, implementing UI components, or reviewing code to ensure consistency with HIVE's established aesthetic guidelines.

### Governing Philosophy
HIVE follows a "Sophisticated Dark Infrastructure" philosophy, prioritizing clarity, calmness, and power in a premium, Apple-inspired user experience. The platform is designed to be both accessible to everyday users and powerful enough for advanced users.

## 1. Core Design Tokens

### 1.1 Color System

#### Backgrounds
- **Primary Surface**: #121212 (Dark Grey)
- **Secondary Surface**: #1E1E1E
- **Glass Surface**: rgba(18,18,18,0.75) with 20-40px blur

#### Text & Icon Colors
- **Text Primary**: #FFFFFF
- **Text Secondary**: #B0B0B0
- **Text Tertiary**: #757575
- **Text Disabled**: #757575

#### Accent / Interactive Colors
- **Call-to-action**: #FFFFFF (White)
- **Focus Indicator**: #EEB700 (Hive Yellow)
- **Hovers**: Subtle opacity changes on existing colors

#### Border & Divider Tokens
- **Decorative Borders**: #E0E0E0 at 10-20% opacity
- **Structural Borders**: Must meet 3:1 non-text contrast

#### Status Colors
- **Success**: #4CAF50
- **Warning**: #FFC107
- **Error**: #FF5252
- **Info**: #2196F3

### 1.2 Typography

#### Font Family
- **Primary**: Inter (variable font)
- **Fallback**: System sans-serif stack

#### Scale & Hierarchy
- **H1**: 36px, Weight: 600, Line height: 1.3
- **H2**: 28px, Weight: 600, Line height: 1.4
- **H3**: 20px, Weight: 600, Line height: 1.5
- **Body**: 14px, Weight: 400, Line height: 1.6
- **Small/Labels**: 12px, Weight: 500, Line height: 1.5

#### OpenType Features
- tnum: Tabular numbers for UI alignment
- liga, calt: Ligatures and contextual alternates

### 1.3 Spacing

#### Base Unit
- 8px system (all spacing in multiples of 8)

#### Token Scale
- **spacing-xxs**: 4px
- **spacing-xs**: 8px
- **spacing-sm**: 12px
- **spacing-md**: 16px
- **spacing-lg**: 24px
- **spacing-xl**: 32px

#### Component Padding & Margin Tokens
- **Button Padding**: xs vertical, md horizontal
- **Card Padding**: md (16px)
- **Input Padding**: md (16px)

### 1.4 Elevation

#### Z-Index Layers
- **z-index-base**: 0
- **z-index-surface**: 10
- **z-index-modal**: 100
- **z-index-tooltip**: 300

#### Shadow Tiers
- **shadow-sm**: Subtle shadow for active/hover states
- **shadow-md**: Medium shadow for floating elements
- **shadow-lg**: Strong shadow for modal dialogs

#### Glass Blur Tokens
- **blur-sm**: 20px blur, rgba(18,18,18,0.75)
- **blur-md**: 30px blur, rgba(18,18,18,0.75)
- **blur-lg**: 40px blur, rgba(18,18,18,0.75)

### 1.5 Radius & Shape

#### Radii Tokens
- **radius-sm**: 4px
- **radius-md**: 8px
- **radius-lg**: 16px
- **radius-pill**: 24px (for chips and pill-shaped buttons)

#### Consistency Rules
- Rounded shapes are default
- No mixed shapes per layer
- Buttons use pill shape (radius-pill)
- Inputs and cards use radius-md (8px)

### 1.6 Stylistic Technique Layer Matrix

#### Visual Depth Layer
1. Dark Blur Modals (Glassmorphism, only for overlays)
2. Shadow-sm on press/hover
3. Opacity layering for inactive cards
4. Contrast layer stacking (background tokens)
5. Inset border logic (1px contrast edge)

#### Motion Layer
1. Micro-interaction scale on tap
2. Fade-in content load
3. Modal slide+fade entry/exit
4. Staggered list loading
5. Tab switch motion (swipe or fade)

#### Physicality Layer
1. Haptic on tap (light)
2. Long press feedback (strong)
3. Ritual/RSVP success = haptic confirm
4. Error trigger = shake + buzz
5. Toggle switches = subtle pulse

#### Expression Layer
1. Live aura glow (Events, Rituals)
2. Focus ring pulse (#EEB700)
3. Confetti micro-moment (first-time only)
4. Badge shimmer when earned
5. Ritual countdown animation

#### Restricted Layer
1. Parallax scrolling (breaks Calm)
2. Looping ambient animation
3. Skeuomorphic shadows
4. Bounce scroll physics
5. Autoplay video blocks

## 2. Component Styling

### 2.1 Buttons

#### Primary Button
- **Background**: White (#FFFFFF)
- **Text**: Black (#000000)
- **Shape**: Pill shape (24px radius)
- **Size**: Chip-sized (36px height, variable width)
- **States**:
  - **Hover**: Subtle opacity change
  - **Active**: Scale down to 97%, darken by 5%
  - **Focus**: #EEB700 outline ring
  - **Disabled**: Grey background, disabled text

#### Secondary Button
- **Background**: Transparent
- **Border**: White at 30% opacity
- **Text**: White
- **Shape**: Pill shape (24px radius)
- **Size**: Chip-sized (36px height, variable width)
- **States**: Same behavior as primary

#### Tertiary Button
- **Background**: None
- **Text**: White
- **Underline**: Optional
- **States**: Same behavior as primary

### 2.2 Inputs

#### Text Input
- **Background**: #1E1E1E
- **Border**: White at 10% opacity
- **Focus Border**: #EEB700
- **Text**: White
- **Label**: Above input, #B0B0B0
- **Radius**: 8px
- **Padding**: 16px

#### Textarea
- Same as text input with increased height

#### Selector (Dropdown)
- Same as text input with dropdown indicator

### 2.3 Cards

#### Standard Card
- **Background**: #1E1E1E
- **Padding**: 16px
- **Radius**: 8px
- **Border**: Optional, white at 10% opacity
- **States**:
  - **Hover**: Subtle background lighten
  - **Active**: Subtle scale down

#### Content Card
- Same as standard with potential for media content
- Edge-to-edge media when present

### 2.4 Tabs / Chips / Tags

#### Tabs
- **Active**: White text, #EEB700 indicator
- **Inactive**: Grey text, no indicator
- **Transition**: Smooth slide for indicator

#### Chips
- **Selected**: White background, black text
- **Unselected**: Transparent with white border
- **Radius**: Pill shape (24px)
- **Size**: 36px height, variable width

### 2.5 Overlays

#### Modal
- **Background**: Glass blur effect
- **Radius**: 8px
- **Animation**: Fade + slight upward shift
- **Close Behavior**: Tap outside or close button

#### Sheet (Bottom)
- **Background**: #000000
- **Radius**: 16px top corners only
- **Animation**: Slide up from bottom

### 2.6 Navigation

#### Mobile Tab Bar
- **Background**: #000000 (Pure Black)
- **Active Tab**: White with indicator
- **Inactive Tab**: Grey

#### Headers
- **Background**: #121212
- **Title**: Center or left aligned
- **Actions**: Right aligned

## 3. Motion System

### 3.1 Duration Tokens
- **duration-fast**: 150ms
- **duration-standard**: 300ms
- **duration-slow**: 500ms

### 3.2 Easing Curves
- **standard**: cubic-bezier(0.4, 0, 0.2, 1)
- **in**: cubic-bezier(0.4, 0, 1, 1)
- **out**: cubic-bezier(0.0, 0, 0.2, 1)
- **linear**: linear

### 3.3 Trigger Mapping
- **Tap**: Scale down to 97%, 150ms
- **Modal Open**: Fade + upward shift, 300ms
- **List Load**: Staggered fade in, 200-500ms
- **Page Transition**: Slide or fade, 300ms

### 3.4 Micro vs Macro Motion Rules
- **Micro**: <300ms, for feedback and immediate response
- **Macro**: 300-500ms, for transitions between states or views

### 3.5 prefers-reduced-motion Fallbacks
- All transitions reduced to simple fades or instant changes
- No motion for purely decorative purposes

## 4. Haptics & Audio Feedback

### 4.1 Haptic Map
- **Tap**: Light impact
- **Long Press**: Medium impact
- **Success**: notificationSuccess pattern
- **Error**: notificationError pattern + shake

### 4.2 Audio Cues
- Optional and minimalist
- Reserved for major achievements or confirmations

### 4.3 Cross-Platform Standards
- **iOS**: UIFeedbackGenerator, UINotificationFeedbackGenerator
- **Android**: Vibrator, HapticFeedbackConstants

## 5. Surface & Layer Strategy

### 5.1 Surface Types
- **Base Surface**: #121212
- **Card Surface**: #1E1E1E
- **Glass Surface**: Blur effect with rgba overlay

### 5.2 Elevation Logic
- Z-index follows clear hierarchy
- Shadows used sparingly, only on interaction
- Prefer opacity and color contrast for differentiation

### 5.3 Surface Separation
- Use spacing as primary means of separation
- Minimize use of borders and dividers
- When needed, use subtle contrast changes between surfaces

### 5.4 Light vs Dark Handling
- System optimized for dark mode
- No light mode in initial implementation

## 6. Behavioral Aesthetic Mapping

### 6.1 Sophistication
- Clean, minimal UI with strict grid alignment
- Consistent spacing and typography
- Restraint in use of decorative elements

### 6.2 Calm / Purposeful Motion
- No ambient animations
- Purposeful transitions and feedback
- Reduced visual noise

### 6.3 Infrastructure
- Predictable layout patterns
- Consistent navigation mechanisms
- Strong information architecture

### 6.4 Authenticity
- No public vanity metrics
- Clear system states and feedback
- Meaningful interactions

### 6.5 Accessibility
- WCAG AA compliance
- Strong contrast ratios
- Support for reduced motion
- Keyboard navigation

### 6.6 Cultural Adaptability
- Localized surfaces via HiveLab/branding engine
- Campus-specific visual elements

## 7. Meta System Principles

### 7.1 Non-Negotiables
- Contrast requirements
- Typography legibility
- No overlapping motion
- Accessibility compliance

### 7.2 Escalation Paths
- Design system issues must be escalated to system owner
- Documented deviation process for exceptions

### 7.3 Experimental Flags
- Visual experiments behind feature flags
- Ritual-specific visual modes

## 8. Escape Hatch System

### 8.1 Seasonal Brand Engines
- Campus Madness theming
- Holiday/seasonal adjustments

### 8.2 Temporary Visual Modes
- Pulse States for limited-time events
- Ritual Fever modes

### 8.3 Limited-Edition Ritual Aesthetics
- Special visual treatments for milestone rituals

### 8.4 Subculture / Campus-specific Skinning
- University color schemes
- Campus-specific visual elements

## 9. Accessibility Compliance Layer

### 9.1 WCAG AA Requirements
- 4.5:1 contrast for text
- 3:1 contrast for UI elements
- Keyboard navigability
- Reduced motion support

### 9.2 Focus Indicators
- 2px #EEB700 ring required
- Must be visible on all backgrounds
- Clear keyboard navigation paths

### 9.3 Contrast Testing Grid
- Test matrix for all color combinations
- Automated contrast checking in design system

### 9.4 Screen Reader Considerations
- Semantic HTML/Flutter structure
- ARIA labels
- Clear navigation hierarchy

## 10. Appendices

### A. Glossary of Visual Terms
- Ritual: Core engagement feature
- Trail: Achievement path
- Space: Community area
- Pulse: Temporary featured state

### B. Design Token Index
- Complete reference of all tokens for development

### C. System Mockup References
- Links to canonical examples

### D. Component Audit Log
- History of component changes and rationale 