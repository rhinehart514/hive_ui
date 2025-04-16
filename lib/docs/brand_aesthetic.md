# HIVE Brand Aesthetic & UI/UX Architecture Guide (Version 1.2)

## 1. Executive Summary

HIVE's brand aesthetic is defined as **Sophisticated Dark Infrastructure**. This guide translates that vision into actionable, testable rules for the platform's presentation layer. It defines core principles, design tokens, layout structures, component styling, motion rules, and accessibility standards. Our design language embodies clarity, calmness, and power — supporting both the everyday browser and the power user while creating a premium, Apple-inspired user experience for students.

---

## 2. Core Principles

### 2.1 Sophisticated Dark Infrastructure
- **Sophistication**: Clean lines, pixel-perfect execution, minimalism, and strict adherence to spacing and typographic rules. Design serves content, not vice versa.
- **Dark Theme**: Default dark UI (#121212), with strict rules for #000000 (see Color section). Prioritize legibility, depth, and reduced eye strain.
- **Infrastructure**: Defined by functional clarity, reliability, robust information architecture, predictable navigation, and seamless performance. *Visually, infrastructure is not heavy or brutalist, but organized, clear, and dependable.*
- **Purposeful Motion**: Motion is used deliberately to provide feedback, guide transitions, and enhance usability. Avoid gratuitous or distracting animation. All motion must respect user accessibility settings (prefers-reduced-motion).
- **Authenticity Focused**: No public vanity metrics (likes, follower counts). Feedback and engagement mechanisms must be authentic, meaningful, and non-comparative.
- **Ambient/Calm**: Minimize unnecessary interruptions. Use subtle cues and calm technology principles.
- **Constraint Adherence**: All design and development must strictly follow these rules and tokens.

### 2.2 Focus & Cognitive Load
- **One primary action per screen**
- **Use progressive disclosure** to hide secondary actions
- **Avoid alert fatigue**; use unobtrusive banners, not popups
- **Focus on clarity**, not cleverness
- **Reduce choices per screen** for better decision-making

---

## 3. Color & Contrast

### 3.1 Palette
- **Primary Surface**: #121212 (Dark Grey) — default background for all main surfaces.
- **Secondary Surface**: #1E1E1E — for cards, secondary surfaces, and subtle differentiation.
- **Optional Deep Layer**: #000000 (Pure Black) — *only* for persistent navigation sidebars or overlays, never for main content backgrounds.
- **Text Primary**: #FFFFFF (White) — for primary text content.
- **Text Secondary**: #B0B0B0 — for secondary text content.
- **Text Tertiary**: #757575 — for tertiary information and hints.
- **Text Disabled**: #757575 — for disabled interface elements.
- **Text Link**: #80B9F3 — for link elements.
- **Accent**: #EEB700 (Hive Yellow) — for key interactive elements (CTAs, focus, highlights). Never for body text or backgrounds. Use sparingly for maximum impact.
- **Interactive Primary Background**: #3A6BFF — alternative button background color.
- **Interactive Primary Text**: #FFFFFF — text on primary interactive elements.
- **Borders/Dividers**: #E0E0E0 at 10-20% opacity *only if purely decorative*. If used for essential structure, must meet 3:1 non-text contrast.

### 3.2 Status Colors
- **Success**: #4CAF50
- **Warning**: #FFC107
- **Error**: #FF5252
- **Info**: #2196F3

### 3.3 Contrast Requirements
- **Text**: 4.5:1 minimum contrast ratio against backgrounds
- **UI Elements**: 3:1 minimum contrast ratio for borders, indicators, and interactive elements
- **Decorative elements**: No minimum contrast if purely decorative

---

## 4. Typography

### 4.1 Font Family
- **Primary**: Inter (variable font)
- **Fallback**: System sans-serif stack (e.g., -apple-system, BlinkMacSystemFont)
- **OpenType Features**: Enable calt, liga, tnum
  - tnum: tabular numbers for UI alignment
  - liga, calt: ligatures and contextual alternates

### 4.2 Type Scale
- **H1**: 36px, Weight: 600, Line height: 1.3
- **H2**: 28px, Weight: 600, Line height: 1.4
- **H3**: 20px, Weight: 600, Line height: 1.5
- **Body**: 14px, Weight: 400, Line height: 1.6
- **Small/Labels**: 12px, Weight: 500, Line height: 1.5

### 4.3 Typography Rules
- **Use rem units** for all font sizes to ensure scalability
- **Establish clear visual hierarchy** at a glance
- **Use no more than 3 font weights** per screen
- **Optimal reading width**: 45-75 characters
- **Spacing between text blocks**: 2x line height
- **Line Height**: Body text 1.5–1.6x font size

---

## 5. Spacing, Grid, and Corner Radius

### 5.1 Spacing Tokens (pt)
- **spacing-xxs**: 4
- **spacing-xs**: 8
- **spacing-sm**: 12
- **spacing-md**: 16
- **spacing-lg**: 24
- **spacing-xl**: 32

### 5.2 Grid System
- **Base Unit**: 8px (use multiples for all spacing, padding, margins)
- **Grid**: 12-column, with specified gutter widths and max container widths per breakpoint (see Design System for details)

### 5.3 Corner Radius
- **Corner Radius**: 4px or 8px, applied consistently. No arbitrary rounding.

### 5.4 Elevation & Layering
- **z-index-base**: 0
- **z-index-surface**: 10
- **z-index-modal**: 100
- **z-index-tooltip**: 300

### 5.5 Surface Logic
- Use background shifts or 3:1 border contrast to separate layers
- Prefer minimal, diffused drop shadows for elevation. Shadows should use generous blur radii and low opacity for a soft lift; avoid sharp, dark edges.
- Optionally, apply a very subtle, low-contrast inner shadow (inset) for pressed/active states of interactive elements (e.g., chips, buttons) to create a gentle 'pushed in' effect, ensuring contrast is maintained.
- For large secondary surfaces (#1E1E1E), an extremely subtle dark-grey-to-darker-grey gradient may be used to reduce flatness and suggest curvature, provided contrast is preserved.
- A low-opacity (2-5%), fine-grain noise texture may be consistently applied over base or secondary surfaces to add subtle materiality, as long as legibility and performance are not impacted.

---

## 6. Layout & Information Architecture

### 6.1 Layout Structure
- **Desktop**: Three-column (Left Nav #000000, Center Content #121212, Right Contextual #121212)
- **Mobile**: Single-column, bottom tab bar for 3–5 primary destinations (preferred over hamburger menu for discoverability)

### 6.2 Navigation
- **Active state** must use #EEB700 accent or distinct background
- **Secondary navigation** (tabs) uses accent for active underline/background
- **Breadcrumbs**: Required for deep hierarchies
- **Focus**: Keyboard navigation always shows #EEB700 outline

### 6.3 IA Principles
- Structure based on user research (card sorting, usability testing)
- Clear navigation paths
- Progressive disclosure for complex workflows
- Consistent placement of recurring elements

---

## 7. Motion & Interaction

### 7.1 Duration
- **instant**: 0ms
- **short**: 150-250ms (micro-interactions)
- **standard**: 300-400ms (UI transitions)
- **long**: 500ms (modals or overlays)

### 7.2 Easing Curves
- **standard**: cubic-bezier(0.4, 0, 0.2, 1)
- **exit**: cubic-bezier(0.4, 0, 1, 1)
- **entry**: cubic-bezier(0.0, 0, 0.2, 1)
- **linear**: linear

### 7.3 Motion Guidelines
- **Animate opacity and transform** only for performance
- **Never animate more than 2 elements** at once
- **No looping/decorative animations**
- **Respect prefers-reduced-motion**
- **All motion must be purposeful**, not decorative

### 7.4 Examples
- **Modal open**: standard + entry
- **Button press**: short + standard
- **List loading**: standard + staggered fade/slide

---

## 8. Haptic & Audio Feedback

### 8.1 Haptic Feedback
- **Tap**: light impact
- **Toggle/Picker**: light tick
- **Long Press**: medium impact
- **Success**: notificationSuccess pattern
- **Error**: notificationError pattern

### 8.2 Platform APIs
- **iOS**: UIFeedbackGenerator, UINotificationFeedbackGenerator
- **Android**: Vibrator, HapticFeedbackConstants

### 8.3 Audio Feedback (Optional)
- **Tap**: light click
- **Send/Receive**: soft whoosh
- **Alert/Error**: chime

### 8.4 Rules
- Haptics always support or confirm user action
- No vibration on every touch — be intentional
- Never rely on sound alone
- Respect system mute and preferences

---

## 9. Core Components

### 9.1 Buttons
- **Primary**: Solid white background, black text, chip-sized.
- **Secondary**: Off-white outline and text, chip-sized.
- **Tertiary**: Off-white text only.
- **Min touch area**: 44x44pt
- **Focus State**: #EEB700 outline/ring, >=2px, high visibility on all backgrounds.
- **Text must contrast 4.5:1** with background
- **All states** must be specified (:hover, :active, :focus, :disabled)
- **Size and Shape**: Chip-sized with horizontal padding that adapts to content, 36px height, 24px border radius.
- **Buttons are chips**: All buttons use the chip style (36px height, 24px radius), with clear state changes for hover, active, and focus. For a soft UI feel, active states may combine a subtle scale down (to 98%) with a low-contrast inset shadow and smooth standard-easing animation (150ms).

### 9.2 Input Fields
- **Default**: Subtle background, low-opacity white border, text color.
- **Focus**: #EEB700 border/outline.
- **Error**: Distinct color with icon and text.
- **Use labels**, never placeholders as primary identifier
- **Background must contrast 3:1** from parent
- **All states must be specified.**

### 9.3 Cards
- **Padding**: 16px internal, consistent spacing between elements.
- **Background**: #1E1E1E or slightly lighter than the base #121212.
- **Borders**: Only if decorative, or must meet 3:1 contrast.
- **Elevation**: Subtle, no heavy shadows.
- **Edge-to-edge** when media focused
- **Interactive cards** have hover/focus/active states
- **Cards are clean**: Cards use #1E1E1E, 16px padding, and subtle, diffused elevation. Consider using radius-md (8px) or radius-lg (16px) for a softer appearance. Content within rounded cards should be clipped to the card's shape.

### 9.4 Icons
- **Default**: #FFFFFF or #E0E0E0, 1.5–2px stroke.
- **Active/Highlight**: #EEB700, used sparingly.
- **Must be universally recognizable**

### 9.5 Interactive Feedback
- **Active States**: All tap targets respond visually (opacity, scale, color)
  - Active: scale down to 97%, darken by 5%
- **Focus**: Keyboard navigation always shows #EEB700 outline
- **Load & Progress**:
  - Streaming data preferred (e.g., typewriter effect)
  - Use skeleton loaders or immediate visual feedback

### 9.6 Affordance & Discoverability
- **Tappable elements** styled distinctively (color, icon, underline)
- **Custom gestures** must be introduced gently (onboarding, hints)

---

## 10. Engagement & Feedback (No Vanity Metrics)
- **No public likes, follower counts, or similar metrics.**
- **Alternative feedback mechanisms**:
  - Nuanced reaction systems (beyond simple likes)
  - Private analytics dashboards for creators
  - Qualitative feedback prompts
  - Community-based curation signals (e.g., discussion depth, saves)
- **User test all alternatives with target audience.**

---

## 11. Accessibility (WCAG AA Mandate)
- **Contrast**: All text and essential UI elements must meet WCAG AA (4.5:1 for text, 3:1 for UI elements).
- **Focus Indicators**: #EEB700 outline/ring, >=2px, offset and style specified in Design System. Must be highly visible on all backgrounds.
- **Keyboard Navigation**: All interactive elements must be fully keyboard accessible. Test all user flows.
- **Semantic HTML/ARIA**: All custom components must use correct roles/attributes.
- **Alt Text**: All non-decorative images must have meaningful alt text.
- **Forms**: All inputs must have programmatically associated labels and accessible error validation.
- **Motion**: Must implement prefers-reduced-motion and test.
- **Testing**: Automated and manual accessibility testing is required for all releases. Include keyboard-only and screen reader testing.

---

## 12. Behavioral Aesthetic Mapping

| Pillar | Implementation Examples |
|--------|--------------------------|
| Sophistication | Inter font, strict spacing, minimalist elevation |
| Dark Theme | #121212 base, #FFFFFF text, white chip buttons, #EEB700 focus indicator |
| Infrastructure | Grid-based layout, tnum font feature, predictable component logic |
| Purposeful Motion | Standard transitions, reduced-motion fallback, 1–2 concurrent animations |
| Authenticity | No vanity metrics, precise feedback, clear data sources |
| Calm | Minimal distractions, modal flow, subtle status cues |
| Accessibility | WCAG AA compliance, keyboard navigation, screen reader tested |

---

## 13. Implementation Checklist
1. **Clarify Aesthetic**: Review all work for alignment with core pillars.
2. **Apply Tokens**: Use only defined color, typography, spacing, and radius tokens.
3. **Component States**: Implement all interactive states for every component.
4. **Accessibility**: Test all flows for WCAG AA compliance, including focus, keyboard, and screen reader.
5. **Engagement**: Use only approved feedback mechanisms. No public vanity metrics.
6. **Visual Examples**: Reference canonical examples for all implementations.
7. **Iterate**: Gather feedback, test, and refine continuously.

---

## 14. Final UX Principles

- Everything should feel intentional
- Never animate without meaning
- Color only used to guide or support behavior
- The fewer choices per screen, the better
- Feedback must be fast, gentle, and reliable
- HIVE must always feel premium, personal, and precise

---

## 15. Premium Clarity Principles for Designers

To achieve HIVE's vision of a premium, cool, and crystal-clear user experience, all designers must adhere to the following actionable principles:

### 1. Visual Hierarchy & Simplicity
- **One clear focal point per screen**: Every layout must have a single, unmistakable visual anchor.
- **Limit simultaneous emphasis**: Never use more than one accent color or bold element in a single visual group.
- **Whitespace is luxury**: Use generous spacing to separate content and avoid crowding. If in doubt, add more space.
- **Consistent alignment**: All elements must snap to the 8px grid. No arbitrary offsets.

### 2. Color & Contrast
- **Accent with intent**: Use #EEB700 only for the most important interactive elements. Never for decoration or backgrounds.
- **Dark is not black**: Use #121212 for main backgrounds, #1E1E1E for surfaces, and #000000 only for persistent nav. Never mix these arbitrarily.
- **Text must always pass contrast**: If a text color fails 4.5:1 contrast, it must not be used.

### 3. Typography
- **Hierarchy at a glance**: H1, H2, and body text must be visually distinct. Never use more than three font sizes per screen.
- **No clever fonts**: Only use Inter (or system sans) at specified weights and sizes. No italics, no script, no display fonts.
- **Labels above, not inside**: Form field labels must always be outside the input, never as placeholders.

### 4. Motion & Feedback
- **Motion is meaning**: Every animation must clarify state or spatial relationship. If it doesn't, remove it.
- **Duration discipline**: Microinteractions (tap, hover) max 200ms. Transitions (modal, page) max 400ms. Never animate more than two elements at once.
- **No bounce, no wobble**: Use only smooth, cubic-bezier curves. Avoid playful or springy effects.
- **Immediate feedback**: All tap/click actions must provide visual and (if possible) haptic feedback within 50ms.

### 5. Iconography & Imagery
- **Universal icons**: Use only icons that are instantly recognizable. No metaphors that require explanation.
- **Consistent stroke**: All icons must use 1.5–2px stroke, no filled or mixed styles.
- **Imagery must serve clarity**: Only use images that add information or context. No decorative stock photos.

### 6. Component Consistency
- **Buttons are chips**: All buttons use the chip style (36px height, 24px radius), with clear state changes for hover, active, and focus.
- **Cards are clean**: Cards use #1E1E1E, 16px padding, and subtle, diffused elevation. Consider using radius-md (8px) or radius-lg (16px) for a softer appearance. Content within rounded cards should be clipped to the card's shape.
- **Inputs are obvious**: Inputs must always have a visible border and clear focus state (#EEB700 outline).

### 7. Clarity in Interaction
- **One primary action per screen**: Never present more than one main CTA at a time.
- **Progressive disclosure**: Hide advanced or secondary actions until needed.
- **No popups for alerts**: Use banners or inline messages to avoid disrupting flow.

### 8. Premium Touches
- **Glassmorphism for overlays**: Use subtle blur and translucency for modals and sheets, never for main content.
- **Subtle gold accent**: Use #EEB700 for focus rings, active states, and key highlights—never as a fill or background.
- **Minimalist elevation**: Use shadow only to indicate layering, not for decoration.

### 9. Review & Test
- **Design peer review**: All screens/components must be reviewed by another designer for clarity and premium feel before handoff.
- **Test on dark and light backgrounds**: Ensure clarity and contrast in all supported modes.
- **User test for instant comprehension**: If users hesitate or are confused, simplify further.

### 10. Softness through refinement
- **Softness through refinement**: Achieve a soft UI feel by prioritizing diffused shadows, subtle gradients, generous corner radii, and optional surface noise. All softness must maintain strict contrast and clarity standards.

---

*These principles are non-negotiable. Every HIVE designer is responsible for upholding them in every deliverable. Premium clarity is not a style—it's a standard.*

---

*For all detailed component specs, refer to the HIVE Design System documentation. This guide is the architectural blueprint; the Design System is the implementation law.*
