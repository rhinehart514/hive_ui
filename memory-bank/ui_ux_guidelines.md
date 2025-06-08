# HIVE UI/UX Guidelines & Implementation Checklist

_Last updated: [Current Date]_

**Objective:** To establish and maintain a unified, high-quality user interface and experience across the HIVE platform, ensuring adherence to the core brand aesthetic and interaction principles. This document defines the actionable rules and standards for UI/UX implementation.

**Core Philosophy & Brand:** [memory-bank/brand_aesthetic.md](mdc:memory-bank/brand_aesthetic.md) (MUST consult for intent & feeling)
**Related Plan:** [memory-bank/app_completion_plan.md](mdc:memory-bank/app_completion_plan.md)

--- 

## I. Core UI/UX Principles (Derived from `brand_aesthetic.md`)

*These are the non-negotiable pillars. Implementation MUST reflect these.* 

*   [ ] **Zero Visual Noise:** Every element must justify its existence by advancing comprehension or emotion. Eliminate clutter relentlessly. (Ref: Brand Aesthetic 2.1)
*   [ ] **Dark Infrastructure:** Maintain the premium black (#0D0D0D) background with gold accent (#FFD700) used *sparingly* and intentionally for focus, live status, and key triggers only. (Ref: Brand Aesthetic 2.1, 2.3, 8.1)
*   [ ] **Living Interface & Kinetic Sophistication:** Implement subtle animations and transitions that respond to user interaction, social context, pressure, tempo, and presence. UI feels alive and responsive, not static. (Ref: Brand Aesthetic 2.1, 6)
*   [ ] **System-Level Elegance & iOS DNA:** Follow iOS-inspired interaction patterns (gestures, physics-based animations, component shapes) for a premium, intuitive feel. (Ref: Brand Aesthetic 3, 9)
*   [ ] **Cultural Gravity:** Design guides focus toward live energy and social momentum without being overly loud or distracting. (Ref: Brand Aesthetic 2.1, 10.2, 10.3)
*   [ ] **Invisible Depth:** Utilize layers, blur, and transparency to create a sense of depth and hierarchy, akin to an OS layer. Adhere to the defined Layered Depth System. (Ref: Brand Aesthetic 2.1, 4.1, 4.3)
*   [ ] **Tactile Feedback:** Incorporate appropriate haptic feedback for key interactions according to the Haptic Feedback Matrix to enhance responsiveness. (Ref: Brand Aesthetic 7)
*   [ ] **Clarity & Consistency:** Ensure UI elements, patterns, and flows are consistent across the entire application.
*   [ ] **Accessibility First:** Design and implement with accessibility standards (contrast, touch targets, screen readers) from the start. (Ref: Brand Aesthetic 11)
*   [ ] **Mobile First:** Design and implement with mobile context as the primary consideration, adapting gracefully to web/tablet. (Ref: Brand Aesthetic 2.4)

---

## II. Guideline Checklist: Implementation Rules

### A. Color System (Ref: `brand_aesthetic.md` Sections 4.1, 8)

*   [ ] **Primary Background:** Use `#0D0D0D` exclusively for base canvases. Implement 3% gold grain texture overlay. 
*   [ ] **Secondary Surface:** Use `#1E1E1E` to `#2A2A2A` gradient for cards and elevated surfaces. Verify gradient implementation (soft radial/directional). Implement micro-grain texture (2-5%).
*   [ ] **Text:** Use `#FFFFFF` exclusively for all body and header text. Ensure contrast.
*   [ ] **Accent (#FFD700 - Gold):**
    *   [ ] Used *exclusively* for: Focus rings, Live status indicators, Key triggers (Join, Submit, RSVP, Live Now). Confirm restricted usage. (Ref: Brand Aesthetic 2.3)
    *   [ ] **Never** used for: Text, decorative elements, large background areas.
    *   [ ] Implement Accent States correctly: Default (#FFD700), Hover/Focus (#FFDF2B), Pressed (#CCAD00), Disabled (#FFD70080). (Ref: Brand Aesthetic 8.2)
*   [ ] **Semantic Colors:** Use defined colors correctly and sparingly: Success (#8CE563), Error (#FF3B30), Warning (#FF9500), Info (#56CCF2). (Ref: Brand Aesthetic 8.3)
*   [ ] **Glass Layers:** Implement precisely: Blur (20pt), Tint (rgba(13, 13, 13, 0.8)), Gold glow streak overlay. (Ref: Brand Aesthetic 4.1)
*   [ ] **Contrast Ratios:** Strictly enforce WCAG AA: 4.5:1 (text ≤17pt), 3:1 (text ≥18pt / UI elements). Verify with tools. (Ref: Brand Aesthetic 11.1)

### B. Typography (Ref: `brand_aesthetic.md` Section 5)

*   [ ] **Font Stack:** Implement SF Pro (Variable) for iOS/Web, Inter for Android fallback. Ensure variable font features (optical sizing) are utilized where possible.
*   [ ] **Type Scale Adherence:** Use only defined sizes: 14pt, 17pt, 22pt, 28pt, 34pt. No arbitrary sizes.
    *   [ ] Verify Headline style: SF Pro Display / Medium / Max 28pt / -1.8% Kern.
    *   [ ] Verify Body style: SF Pro Text / Regular / 17pt.
    *   [ ] Verify Caption style: SF Pro Text / Regular / 14pt.
    *   [ ] Verify Tab Label style: SF Pro Text / Medium / 14pt.
    *   [ ] Verify CTA Button style: SF Pro Text / Semibold / 17pt.
*   [ ] **Line Height & Spacing:** Apply consistent, readable line heights (typically 1.3-1.5x font size, adjust per style).
*   [ ] **Weight Usage:** Use specified weights for hierarchy.
*   [ ] **Dynamic Type:** Ensure layouts adapt correctly to system font size changes, mapping 1-to-1 where possible.

### C. Layout & Spacing (Ref: `brand_aesthetic.md` Section 10)

*   [ ] **Global Padding:** Enforce 16pt minimum, 24pt maximum side padding consistently across all screens. (Ref: Brand Aesthetic 10.1)
*   [ ] **Safe Areas:** System safe areas honored meticulously on all platforms (iOS notch/indicator, Android status/nav bars). Check bottom sheets respect home indicator safe area. (Ref: Brand Aesthetic 10.1)
*   [ ] **Grid System:** Maintain consistent alignment and spacing based on an 8pt or 4pt grid. Verify element alignment.
*   [ ] **Component Spacing:** Use consistent vertical/horizontal spacing between elements (e.g., 8pt label-input, 16pt related items, 24dp major sections). Document standard spacing values if not explicitly in Brand Aesthetic.
*   [ ] **Responsiveness:** Layouts must adapt gracefully across screen sizes (phone, tablet, web). Verify content reflow and readability.
    *   [ ] Test navigation patterns switch (Bottom Nav vs. Side Rail) at 640px breakpoint (Guideline II.H).

### D. Motion & Animation (Ref: `brand_aesthetic.md` Section 6)

*   [ ] **Physics & Curves:** Prioritize spring animations (damping ratio: 0.7-0.85) or specified cubic-bezier curves. *No linear tweens.* (Ref: Brand Aesthetic 6.3)
*   [ ] **Standard Durations & Specs:** Implement standard transitions exactly as defined in the Motion Specification table (Surface Fade, Content Slide, Tap Feedback, Deep Press, Page push/pop, Button press, Selection toggle, Error shake). Verify timings and curves. (Ref: Brand Aesthetic 6.1)
*   [ ] **Meaningful Transitions:** Ensure animations serve as narrative cues (hierarchy, state change, spatial logic), avoiding purely decorative motion. (Ref: Brand Aesthetic 2.2)
*   [ ] **Component Motion:** Implement specific animations for Cards (tap/hover), Modals (Z-zoom), Tabs (underline slide), Feed Scroll (elastic) precisely as defined. (Ref: Brand Aesthetic 6.2)
*   [ ] **Microinteractions:** Implement specified sensory microinteractions (Join Space ripple, Drop created pop, Event live pulse, RSVP snap, etc.) with correct visual and haptic feedback. (Ref: Brand Aesthetic 7.3)
*   [ ] **Performance:** Animations MUST target 60fps. Profile key transitions. Reject builds with >2% frame drop on standard transitions. (Ref: Brand Aesthetic 13.1)
*   [ ] **Reduced Motion:** Implement "Reduced Motion" accessibility setting: disable parallax, replace physics/bounces with cross-fades ≤150ms, kill pulses/shimmers. Test thoroughly. (Ref: Brand Aesthetic 11.1)

### E. Components (Ref: `brand_aesthetic.md` Sections 3.2, 4.1, 9, 12.2)

*   [ ] **Buttons (Chip-Sized):**
    *   [ ] Dimensions: 36pt height, 24pt radius.
    *   [ ] Active State: Verify 98% scale, background darken, glow ring appearance/timing.
    *   [ ] Focus State: Verify #FFD700 ring, 2px width.
    *   [ ] Verify Haptics: Light impact on press.
    *   [ ] Implement Primary (Gold BG/Black text) and Secondary (Transparent BG/White text) styles correctly.
*   [ ] **Cards:**
    *   [ ] Surface: Verify #1E1E1E → #2A2A2A gradient & texture.
    *   [ ] Shape: Verify 20pt corner radius (Ref: Brand Aesthetic 3.2).
    *   [ ] Border: Verify no border default, 1px `rgba(255, 255, 255, 0.06)` when active.
    *   [ ] Padding: 16pt verified.
    *   [ ] Interaction: Verify tap (fade/compress/glow) and hover (elevation/parallax) states/animations.
    *   [ ] Image Treatment: Verify edge blur for edge-to-edge images.
*   [ ] **Tabs:**
    *   [ ] Active State: Verify #FFD700 accent bar, full width.
    *   [ ] Inactive State: Verify #757575 color and fade animation.
    *   [ ] Interaction: Verify drag-to-switch with inertia and sliding underline animation.
*   [ ] **Modals:**
    *   [ ] Verify Z-zoom entrance/dismissal animation, blur depth (20pt), background dim (50%).
    *   [ ] Ensure modals respect Layered Depth System (z-index 100). (Ref: Brand Aesthetic 4.3)
*   [ ] **Iconography:**
    *   [ ] Use line-based icons exclusively, 1.5–2px stroke.
    *   [ ] Active state verified (accent color or 20% scale pop).
    *   [ ] No filled/solid icons.
*   [ ] **Input Fields:**
    *   [ ] Verify styling: 12pt radius (Ref: Brand Aesthetic 3.2), height, padding, border (0.5px white 10% opacity default, 2px Gold focus).
    *   [ ] Ensure consistent background (`#1E1E1E`).
*   [ ] **Empty States:** Verify subtle background animation, gold-accented flat icon illustration, clear CTA, float-in animation. (Ref: Brand Aesthetic 10.4)
*   [ ] **Progress Indicators:** Use subtle indicators (e.g., linear gold bar, dots styled per theme). Avoid large spinners.
*   [ ] **Lists:** Implement standard list item styling (padding, dividers if used).
*   [ ] **Dialogs/Alerts:** Use standard HIVE styling, typically modal presentation.
*   [ ] **Snackbars/Toasts:** Use consistent positioning, styling (semantic colors), and entrance/exit animations.

### F. Interaction & Haptics (Ref: `brand_aesthetic.md` Sections 3.1, 7, 9.4)

*   [ ] **iOS-Inspired Gestures:** System-standard edge-swipe back, pull-to-refresh implemented correctly.
*   [ ] **Haptic Feedback:** Implement feedback *exactly* as defined in the Haptic Feedback Matrix for Tap, Deep Hold, Success Submit, Error/Blocked. Adhere to Haptic Governance rules (no double taps <300ms). (Ref: Brand Aesthetic 7.1, 7.2)
*   [ ] **Scroll Physics:** Physics-based scroll with rubber-band effect verified.
*   [ ] **Validation Patterns:** Implement specified patterns: inline for simple fields, on-blur + final submit for forms. Error states include shake animation + haptic alert. (Ref: Brand Aesthetic 9.4)
*   [ ] **Confirmation:** Destructive actions require explicit confirmation modals with clear destructive action styling. No implicit undo. (Ref: Brand Aesthetic 9.4)
*   [ ] **Focus Management:** Ensure logical keyboard focus order, especially on web.

### G. Accessibility (A11y) (Ref: `brand_aesthetic.md` Section 11)

*   [ ] **Contrast:** All text and UI elements meet WCAG AA (Verify with tools).
*   [ ] **Touch Targets:** Minimum 44x44pt (mobile) / 48x48px (web) targets enforced.
*   [ ] **Screen Reader Support (VoiceOver/TalkBack):**
    *   [ ] All interactive elements have clear, concise semantic labels.
    *   [ ] Images have appropriate alt text or are marked decorative.
    *   [ ] Logical focus/reading order maintained.
    *   [ ] Headings marked correctly for structure.
    *   [ ] State changes announced (e.g., button toggled).
*   [ ] **Reduced Motion:** Setting respected across all animations (See Guideline II.D).
*   [ ] **Font Scaling:** UI adapts gracefully to larger system font sizes without breaking layout or clipping text.

### H. Platform Specifics (Ref: `brand_aesthetic.md` Section 2.4)

*   [ ] **Navigation:** Implement Bottom Navigation Bar (Mobile/Narrow Web ≤ 640px) vs. Side Navigation Rail (Tablet/Wide Web > 641px) switch correctly.
*   [ ] **Input Methods:** Test keyboard navigation (web), focus handling, and virtual keyboard interactions/dismissal (mobile).
*   [ ] **Platform Conventions:** Respect essential platform norms (e.g., share sheet integration, back button behavior on Android) where they don't conflict with HIVE's core aesthetic or specified interactions.

---

## III. UI/UX Task Checklist (Process Reminders)

*This section is NOT a feature checklist, but a reminder of the process for applying the guidelines.* 

*   [ ] **Consult Principles:** Before implementing any UI, re-read Section I (Core Principles) and relevant `brand_aesthetic.md` sections. Understand the *intent*.
*   [ ] **Apply Rules:** Implement using the specific rules defined in Section II (Guideline Checklist).
*   [ ] **Leverage Standard Components:** Use existing HIVE shared widgets/components whenever possible before creating new ones.
*   [ ] **Verify Against Guidelines:** After implementation, manually check the UI against the relevant rules in Section II (Color, Type, Layout, Motion, Components, Interaction, A11y).
*   [ ] **Test Interactions & Motion:** Verify animations, transitions, and haptics match specifications exactly.
*   [ ] **Test Responsiveness:** Check layout and usability across target screen sizes/platforms.
*   [ ] **Test Accessibility:** Perform basic A11y checks (contrast, labels, focus order, screen reader).

---

## IV. Decision Log

*(Record key UI/UX decisions that clarify or extend these guidelines, e.g., "Standard spacing between list items defined as 12pt - [Date]").*

*   ...

--- 