# HIVE UI/UX Design Plan - Aesthetic & Interaction Specifications

## Brand Aesthetic Foundation

HIVE's UI/UX embodies a dark, sophisticated digital infrastructure with distinct characteristics:

* **Visual Language**: Architectural darkness (#121212 base, #1E1E1E surfaces) with deliberate negative space. Gold accents (#EEB700) only for state changes, interactions, and focus - never decoration.

* **Emotional Clarity**: Clean, premium interfaces that feel impossibly alive yet calm. Interface elements respond with subtle micro-animations that feel organic yet precise, like interacting with physical architecture.

* **Interaction Philosophy**: The interface should "breathe" with student activity. Information density increases with relevance, not quantity. Touch interactions have physical weight - haptic feedback mirrors real-world resistance and release.

* **Spatial Hierarchy**: Three primary layers (Base Canvas, Content Surfaces, Floating UI) with clear Z-index discipline. Glass effects (8px blur, rgba(18,18,18,0.75)) create dimensional space without visual noise.

* **Typography**: Exclusively Inter with strict type scale hierarchy:
  - H1: 36px/600/1.3 (major section titles)
  - H2: 28px/600/1.4 (card titles, headers)
  - H3: 20px/600/1.5 (content headers)
  - Body: 14px/400/1.6 (primary content)
  - Small: 12px/500/1.5 (metadata, timestamps)

* **Timing & Motion**: Calm physics with precise timing:
  - Standard transitions: 300-400ms with cubic-bezier(0.20, 1.00, 0.30, 1.00) easing
  - Micro-interactions: 150-250ms with cubic-bezier(0.40, 0.00, 0.20, 1.00) easing
  - Celebrations: 500-800ms with cubic-bezier(0.18, 0.89, 0.32, 1.28) spring effect

## Verification Standard

All UI components and screens must be judged against these exacting standards:

1. **Visual Cohesion**: Does it maintain the dark infrastructure aesthetic with proper spacing, typography hierarchy, and minimal visual noise?
2. **Interaction Quality**: Does it feel alive but calm? Do transitions feel physics-based rather than mechanical?
3. **Emotional Impact**: Does it evoke a sense of premium quality and architectural elegance? Does it avoid feeling "gamified" or cluttered?
4. **Focus & Intent**: Does each screen have a clear purpose with obvious primary actions? Is information prioritized by relevance?
5. **Motion Discipline**: Are animations purposeful and enhancing understanding (not decoration)? Do they respect reduced motion preferences?

## Phase 0: Foundational Decisions & Design System Setup

**Before detailed screen design or verification commences, the following foundational steps are critical:**

**1. Resolve Critical Ambiguities & Define Scope:**
- [ ] **CRITICAL:** Define the core **Social Model** (Mutual Friends vs. Follower/Following vs. Hybrid).
- [ ] Finalize **Authentication** flows (SSO details, non-campus access policy, MFA, recovery).
- [ ] Define **Onboarding** scope (required vs. optional steps, initial recommendation strategy).
- [ ] Clarify scope and specific UI needs for **V1 Messaging**.
- [ ] Define scope and interaction models for **Post/Drop Creation**.
- [ ] Define scope and interaction models for **Notifications** (incl. entry point).
- [ ] Define scope and interaction models for **Search** (incl. entry point).
- [ ] Define scope and interaction models for **Rituals**.
- [ ] Define scope and interaction models for user-facing **Moderation Flows** (reporting).
- [ ] Define scope and interaction models for user-facing **Analytics Display**.
- [ ] Define scope and interaction models for **Visibility Controls**.
- [ ] Resolve other specific ambiguities noted within feature sections below.

**2. Solidify Core Navigation & Information Architecture:**
- [ ] **Design Navigation:** Create a pure black (#000000) bottom navigation bar with minimalist iconography. Active states use subtle gold indicator rather than fill. Transitions between tabs should feel like shifting architectural spaces (300ms cubic-bezier).
- [ ] **Define Spatial Movement:** Map how each screen transition represents moving through "space" - horizontal, vertical, or z-axis (modal) movement must be consistent and physically intuitive.

**3. Establish/Refine Core Design System & Patterns:**
- [ ] **Component Library Specification:** Define explicit visual specs for all core components:
  * **Buttons:** 
    - Primary: Pill shape (20px radius), white background, black text, 44px height, 4% white tint on hover, 0.98 scale + 2px inset shadow on active
    - Secondary: Transparent with 30% white border, white text, hover/active states as above
    - Tertiary: Text only, subtle hover effect
  * **Cards:** 
    - Standard elevation with 8px radius, 16px padding, #1E1E1E background 
    - Interactive states: 2% white tint on hover, 1.02 scale + 4% tint on active
    - Edge-to-edge media with text overlay using glassmorphism
  * **Input Fields:** 
    - 8px radius, #1E1E1E background, 10% white border, 16px padding
    - Labels always above inputs, never placeholders
    - Focus state: #EEB700 border with 4px subtle glow effect
    - Error state: #FF5252 border with subtle inward glow + gentle shake animation
  * **Lists & Grids:** 
    - Consistent 16px item spacing
    - Touch ripple effects constrained to item boundary
    - Scrolling with momentum and subtle elastic resistance at boundaries

- [ ] **Motion & Feedback System:**
  * **Develop Animation Library:**
    - Page transitions (300-400ms cubic-bezier)
    - Element entrances (staggered 200-300ms)
    - Interactive feedback (150-250ms)
    - Celebration patterns (RSVP confirmation, ritual completion)
  * **Haptic Pattern Library:**
    - Light: Tap feedback
    - Medium: Important state changes
    - Heavy: Completion/celebration
    - Error: Sharp triple + vibration
  * **System Sound Library (optional, disabled by default):**
    - Subtle UI interactions
    - Completion chimes
    - Error tones

## Overall Structure & Navigation (Post-Phase 0)

- [ ] **Design/Verify Primary Navigation:** 
  * Pure black (#000000) bottom navigation with 5 or fewer primary destinations
  * Icons use 24px containers with 50% white (inactive) to 100% white (active)
  * Active state includes subtle 2px #EEB700 indicator
  * Subtle 120ms scale + fade effect when switching tabs
  * Haptic feedback (light) on tab change

- [ ] **Design/Verify Global Transitions:** 
  * Feed → Detail: 350ms cubic-bezier(0.20, 1.00, 0.30, 1.00) with hero elements
  * Profile → Space: 320ms horizontal slide with parallax effect
  * Any → Modal: 280ms cubic-bezier(0.20, 1.00, 0.30, 1.00) from bottom with blur backdrop
  * Test on both high and low-end devices to ensure smoothness

- [ ] **Consolidate Screen/Page Structure:** Migrate screens from `lib/pages` and `lib/screens` into `lib/features/<feature_name>/presentation/`. **Priority: High**

- [ ] **Refactor Large Page Files:** Break down oversized files (`onboarding_profile.dart`, `profile_page.dart`, etc.) into smaller components. **Priority: High**

## Feature-Specific UI/UX Flows

### 1. Authentication

**Visual Direction:**
The authentication flow should feel like entering an exclusive space - minimal, elegant, with focused entry points. The dark backdrop (#121212) gives prominence to input fields and actions. Subtle gold highlights (#EEB700) guide the user through validation while maintaining sophistication.

- [ ] **Design/Verify Sign In screen:**
  * Full-screen dark gradient backdrop (#121212 → #0D0D0D)
  * Centered layout with prominent HIVE wordmark (28px)
  * Input fields with 10% white border, clear labels, #1E1E1E surface
  * Primary action button spans 80% of width, white background (#FFFFFF), black text
  * Secondary actions (Create Account, Forgot Password) as tertiary buttons (white text, no background)
  * Success transition: 350ms fade + scale out effect
  * Error: Subtle shake animation with 4px red glow on affected fields

- [ ] **Design/Verify Sign Up flow:**
  * Minimal multi-stage flow (max 3 steps)
  * Progress indicator as subtle dots or thin line (gold for completed)
  * Focused form with only 2-3 fields per screen
  * Campus email verification with real-time validation (checkmark animation)
  * Smooth transitions between steps (320ms slide + fade effect)
  * Final step transitions directly to onboarding with celebratory micro-animation

- [ ] **Design/Verify Password Reset flow:**
  * Single input screen with clear instructions
  * Success confirmation screen with clear next steps
  * Email design specs (ensure consistent styling in-app and email)

- [ ] **Design Account Tier Handling:**
  * Visual distinction for different account tiers (Verified, Verified+)
  * Subtle badges or indicators that feel integrated, not gamified
  * Upgrade flows that communicate privilege without intimidation

- [ ] **Verify all UI elements meet brand aesthetic:**
  * Input styling: Focus glow is subtle (4px blur, 30% opacity)
  * Button states: Hover, Active, Disabled states all visually distinct
  * Error messaging: Inline validation with helpful, human language
  * All transitions smooth at 300-400ms with consistent easing curves

- [ ] **Resolve outstanding specification questions**

### 2. Onboarding

**Visual Direction:**
Onboarding should feel like a ceremonial introduction to a new world - deliberate, premium, with a sense of progression. Each step should feel distinctly architectural with clear purpose and subtle motion cues guiding users forward. The experience balances excitement and utility.

- [ ] **Design Welcome/Introduction screens:**
  * Dramatic full-screen gradient with subtle animation (60s cycle)
  * Large, confident typography (36px H1) with ample negative space
  * Focused benefit statements (max 3) with minimal supporting illustration
  * Clear primary action surrounded by negative space for emphasis
  * Horizontal pagination with subtle parallax between screens (350ms transition)
  * Skip option discrete but accessible (12px Small text, top corner)

- [ ] **Design Profile Setup flow:**
  * Avatar editor with spotlight effect on upload area
  * Real-time username availability with subtle checkmark animation
  * Bio field with character counter that appears only after typing begins
  * Each completed field triggers subtle success animation (pulse + checkmark)
  * Continue button transforms from secondary to primary style upon valid input
  * Touch interactions feel weighty and responsive (medium haptic on completion)

- [ ] **Design Permissions Request screens:**
  * Clear purpose explanation before each permission request
  * Visual illustration of benefit (subtle, not cartoon-like)
  * Two-button choice (Allow/Later) with Allow as primary action
  * Fallback content previewed if permission denied

- [ ] **Design Interest/Space Selection:**
  * Grid or horizontal scroll of Space cards with minimal preview
  * Multi-select with subtle gold outline + checkmark for selected items
  * Selection counter with subtle numeric increment animation
  * "Discovery complete" celebration subtle but satisfying (radial burst)

- [ ] **Verify visual consistency:**
  * Typography hierarchy maintained across all screens
  * Spacing follows 8pt grid consistently
  * Interactive elements maintain 44px minimum touch target
  * Animations respect reduced motion settings
  * Empty states designed with clear next action

- [ ] **Refactor `onboarding_profile.dart` (3600+ lines). Priority: High**

### 3. Main Feed (*Completion Plan: 100%* -> Verification/Refinement Focus)

**Visual Direction:**
The Feed is HIVE's pulse - a living infrastructure of campus energy. It should feel like looking through architectural glass at real-time activity. Content surfaces float above the dark canvas with dimensionality. No infinite scroll or content overload - just the most relevant campus moments with spatial meaning.

- [ ] **Verify Core Feed interaction:** 
  * Scrolling has slight resistance (physics.clamping) + subtle haptic detents between major sections
  * Pull-to-refresh uses minimal spinner (thin gold arc) with satisfying completion
  * Card entrance has subtle staggered animation (100ms delay between items, 250ms entrance)
  * Main feed should feel dense with information but never cluttered

- [ ] **Verify Card Design:**
  * Cards use #1E1E1E surface with 8px radius and subtle (2px) elevation effect
  * Event cards: Edge-to-edge image header (16:9), glassmorphism overlay for time/location, 16px padding for content
  * Space posts: 16px padding throughout, focused typography, media constrained to card width
  * Ritual cards: Distinctive gold accent edge (left border 2px) to differentiate from standard content
  * Repost cards: Visual nesting effect (indentation + subtle shadow) to indicate provenance
  * All cards: Subtle hover state (2% white tint), active state (4% tint + 1.02 scale)

- [ ] **Verify Interaction patterns:**
  * Primary actions (RSVP, Join) use gold accent feedback
  * Subtle haptic feedback (light for browsing, medium for taking action)
  * Touch targets maintain 44-52px height
  * RSVP/Action feedback must include subtle celebration effect (radial burst + haptic success pattern)

- [ ] **Verify Loading & Empty states:**
  * Skeleton loader mimics final layout with subtle pulse animation (1.5s cycle)
  * Empty feed has architectural illustration + clear action prompt
  * First load should complete in < 2 seconds or provide visual distraction

- [ ] **Refactor & consolidate code:**
  * `main_feed.dart` (1300+ lines). **Priority: Medium**
  * Consolidate feed screen files into `lib/features/feed/presentation/`

- [ ] **Additional verification:**
  * Proper handling of long text (truncation with ellipsis)
  * Image aspect ratios maintained with consistent cropping strategy
  * Performance test: Smooth scrolling at 60fps even with complex content
  * Visual density check: Information hierarchy clear at a glance

### 4. Profile (*Completion Plan: 90%* -> Verification/Refinement Focus)

**Visual Direction:**
Profiles should feel like architectural spaces that represent individual identity - not social performance stages. A dynamic header transitions smoothly to content as users explore. Content is organized in clear spatial regions with thoughtful transitions between sections. The interface emphasizes involvement and connection over metrics and vanity.

- [ ] **Verify Header Design:**
  * Dynamic collapsing header using `SliverAppBar` with 300ms smooth transition
  * Avatar (72px circle) with subtle elevation effect
  * Username in H2 (28px/600) with verification badge if applicable
  * Metadata (joined date, Space affiliations) in Small (12px/500/1.5)
  * Action buttons use secondary style (transparent, white border) with proper spacing

- [ ] **Verify Content Tab Design:**
  * Tabs use subtle indicator (2px gold underline) rather than background fill
  * 300ms transition between tab content with subtle cross-fade
  * Content sections properly maintain momentum scrolling physics
  * Tabs maintain minimum 44px touch target height

- [ ] **Verify Trail/Activity Display:**
  * Chronological layout with clear date grouping
  * Event cards: Simplified variant of main feed cards, 30% smaller
  * Activity indicators: Subtle iconography with clear type hierarchy
  * Badges displayed with minimal visual treatment (no gamification aesthetic)

- [ ] **Verify Context-Aware Actions:**
  * Own profile: Edit, Settings, Privacy controls prominent
  * Other profiles: Follow/Friend action as primary, Message as secondary
  * Organization profiles: Join/Leave as primary, secondary actions contextual
  * All interactive elements properly communicate state through visual design

- [ ] **Design Privacy Controls UI:**
  * Clean toggle interfaces with clear labels
  * Grouped settings with proper hierarchy
  * Preview of visibility effects when possible
  * Changes save with subtle confirmation animation

- [ ] **Refactor & Consolidate:**
  * `profile_page.dart` (1300+ lines). **Priority: Medium**
  * Resolve distinction between profile and profiles directories

### 5. Events

**Visual Direction:**
Events are core to campus life and should feel immersive and actionable. Event details expand from cards into rich, layered spaces that communicate energy and context. Creation flows should feel enabling rather than bureaucratic. The design balances informational clarity with emotional resonance.

- [ ] **Design/Verify Event Detail Screen:**
  * Immersive header image with parallax scroll effect (subtle 10% movement)
  * Title overlay uses glassmorphism (rgba(18,18,18,0.75), 8px blur) for legibility
  * Key details (time, location, host) in highlighted info block with iconography
  * RSVP button: Prominent floating action button with state styles:
    - Going: Filled gold (#EEB700) with checkmark icon + text
    - Not Going: Secondary style (30% white border)
    - Pressed: Scale to 0.95 + haptic feedback + confetti celebration animation
  * Description uses proper text hierarchy with adequate spacing (24px top, 16px bottom)
  * Attendee list as horizontal scroll of avatars with +X overflow indicator
  * Map view with subtle border and interactive touch response

- [ ] **Design Event Creation Flow:**
  * Multi-step creation with progress indicator (thin line, gold for completed)
  * Each step focused on one aspect (Details, Time, Location, Privacy, Review)
  * Form fields follow input styling guidelines with clear validation
  * Date/time selector uses custom dark theme picker with gold selection indicator
  * Location field offers search with results in consistent card style
  * Image upload area with preview and edit capabilities
  * Review step shows complete event card as it will appear in feed

- [ ] **Verify Interaction Quality:**
  * Hero transitions from feed to detail feel continuous (350ms duration)
  * RSVP interaction provides satisfying feedback (haptic + visual)
  * Key actions (share, add to calendar) easily accessible
  * Back gesture/button returns to previous context with proper transition
  * Event updates (changed details, cancellations) handled with clear visual indicators

- [ ] **Refactor:**
  * `event_details_page.dart` (1100+ lines). **Priority: Medium**

### 6. Spaces (*Completion Plan: 100%* -> Verification/Refinement Focus)

**Visual Direction:**
Spaces are architectural environments for communities - distinct but interconnected with the broader campus. The design should convey identity, belonging, and activity. Spaces have their own presence but maintain HIVE's cohesive aesthetic system. Navigation within Spaces should feel like moving through connected rooms with clear purpose.

- [ ] **Verify Space Discovery:**
  * Directory layout with clear categorization system
  * Space cards: 16:9 header image with identity overlay, clear name (H3 20px), brief description, member count, and primary category tag
  * Filtering UI uses subtle dropdown with clean transition (250ms)
  * Categories use minimal visual treatment (text differentiation, not color coding)
  * Empty states and loading states follow global patterns but with Space-specific messaging

- [ ] **Verify Space Detail View:**
  * Header treatment similar to Profile but with space imagery
  * Identity panel includes: Name (H2), description, member metrics, verification status
  * Join/Leave button: Primary style when not joined, secondary when member
  * Joining animation includes subtle celebration effect with haptic feedback
  * Tab structure for:
    - Feed (Space posts and events)
    - Events (calendar or list view)
    - Members (grid with role indicators)
    - About (extended information)
  * All transitions between tabs use consistent 300ms duration with appropriate easing

- [ ] **Design Space "Rituals" Interaction:**
  * Rituals appear as distinct card type with subtle ceremonial aesthetic
  * Interaction model uses intuitive gestures (tap, hold, or custom gesture depending on ritual type)
  * Completion triggers more substantial celebration animation (particle effects, haptic pattern)
  * Rewards (badges, access) appear with elegant entrance animation
  * All elements maintain sophisticated aesthetic (never gamified or childish)

- [ ] **Verify Space Management Tools:**
  * Admin tools accessible through subtle but discoverable entry point
  * Management interfaces use same dark aesthetic but with subtle visual distinction
  * Creator tools (post, event, ritual creation) use FAB with expanding options
  * Member management uses clean list interface with clear role indicators
  * All management actions have appropriate confirmation dialogs

- [ ] **Refactor & Consolidate:**
  * Refactor `clubs_page.dart` (900+ lines)
  * Consolidate directories into `spaces` terminology

### 7. Messaging (*Future Enhancement?*)

**Visual Direction:**
Messaging embodies intimate communication within HIVE's architectural system. The design balances utility with emotional connection through typography and subtle animation. Conversations feel private yet connected to the broader platform. The aesthetic prioritizes readability and personal expression within the sophisticated dark infrastructure.

- [ ] **Design Chat List Screen:**
  * Clean list interface with avatar-led items (56px height)
  * Preview text uses single line with ellipsis, proper text hierarchy
  * Timestamps in small (12px) muted text (50% opacity)
  * Unread indicators use subtle gold dot (4px) rather than badges or counts
  * Archiving/management using swipe gestures with subtle animation

- [ ] **Design Chat Screen:**
  * Header maintains consistent app navigation with participant info
  * Message bubbles: 
    - Sent: Right-aligned, darker surface (#1A1A1A), subtle right edge radius variation
    - Received: Left-aligned, standard surface (#1E1E1E), subtle left edge radius variation
    - Both: 16px padding, 12px radius, proper spacing between messages (12px)
  * Timestamp groups rather than individual message timestamps
  * Input field spans bottom with subtle blur background effect
  * Send button uses gold accent (only when input has content)
  * Typing indicator uses subtle pulse animation (3 dots, 1.2s cycle)
  * Keyboard appearance/disappearance animates smoothly (250ms)

- [ ] **Design New Chat Flow:**
  * User selection interface with search and recent contacts
  * Selected users appear as removable chips with subtle animation
  * Transition to chat is smooth and continuous

- [ ] **Resolve scope for V1**

### 8. Friends

**Visual Direction:**
The connection system should feel elegant and intentional - focused on meaningful interaction rather than collection. The interface emphasizes context and recency without gamification. Aesthetically clean with subtle interactive elements that communicate relationship states through visual design rather than explicit labels when possible.

- [ ] **Design Connection List:**
  * Clean grid or list view with proper spacing
  * Profile cells with avatar (44px), name, subtle context information
  * Interaction states (tap, press) with appropriate feedback
  * Search and filter controls integrated into header
  * Scrolling physics consistent with global standards

- [ ] **Design Connection Request Interface:**
  * Requests have distinct visual treatment (subtle border or background)
  * Accept/Decline buttons use positive/neutral styling (not red for decline)
  * Accepting triggers subtle celebration animation + haptic
  * Context information (mutual connections) with minimal visualization

- [ ] **Design User Search/Discovery:**
  * Search field follows global input styling
  * Results appear with fluid animation (staggered entrance)
  * Connection status clearly indicated through button state rather than badges
  * Empty and loading states consistent with global patterns

- [ ] **Verify Confirmation Dialogs:**
  * Disconnection confirmations use standard dialog pattern
  * Clear but neutral language (never accusatory or negative)
  * Action buttons properly aligned with primary/secondary styling

- [ ] **CRITICAL: Resolve social model** and ensure UI reflects chosen approach

### 9. Notifications (*Needs Design*)

**Visual Direction:**
Notifications serve as the nervous system of HIVE's infrastructure - delivering timely awareness without overwhelming users. The design should feel like an architectural notification system - precise, calm, and contextual. Visually integrated with the platform while maintaining clear hierarchy of importance.

- [ ] **Design Notification Center:**
  * Full-screen experience with generous spacing
  * Clean list view with consistent item height (72px) for readability
  * Visual hierarchy: Icon (36px), primary text (Body 14px), secondary context (Small 12px), timestamp (Small 12px, 50% opacity)
  * Swipe actions for management (mark read, delete) with subtle animation
  * Grouping headers using H3 (20px) with proper spacing (24px top, 16px bottom)

- [ ] **Design Notification Items:**
  * Visual differentiation by type:
    - Mentions: Subtle gold dot indicator
    - Events: Calendar-like icon with date
    - Social: Avatar-led item design
    - System: Minimal icon treatment
  * Read vs Unread: Unread uses higher contrast background (+5% white)
  * Actionable vs Informational: Actionable includes subtle chevron or action button
  * All items maintain touch target size (min 44px height)

- [ ] **Design Empty & Loading States:**
  * Empty state includes architectural illustration and friendly message
  * Loading uses skeleton layout with subtle animation
  * First-time experience includes brief orientation tooltip

- [ ] **Resolve outstanding questions:**
  * Notification entry point (Bottom nav? Header icon?)
  * Specific triggering events
  * Grouping/filtering strategy

### 10. Search

**Visual Direction:**
Search is an architectural wayfinding system within HIVE - helping users navigate to people, spaces, and events with precision. The design should feel responsive and intelligent without overwhelming. Results appear with architectural organization, emphasizing relevance over quantity.

- [ ] **Design Search Input:**
  * Prominent search bar with 10% white border, #1E1E1E surface
  * Icon-led with clear tap target
  * Focus state brings keyboard with subtle animation (250ms)
  * Clear button appears only when text is entered
  * Real-time feedback as query is typed (subtle loading indicator)

- [ ] **Design Results Layout:**
  * Categorized sections with H3 headers (20px)
  * Result items follow consistent pattern based on type:
    - People: Avatar-led items with name and single context line
    - Spaces: Compact Space cards with visual preview
    - Events: Date-led item design with title and location
  * Hierarchy clearly communicates result relevance
  * Transitions between result sets smooth and intentional (200ms)

- [ ] **Design Recent/Suggestions:**
  * Recent searches appear as removable chips
  * Suggestions use subtle background distinction
  * Clear visual hierarchy between history and suggestions
  * Easy dismissal with expected touch interactions

- [ ] **Design Empty State:**
  * "No results" messaging with helpful suggestions
  * Minimal illustration that fits architectural aesthetic
  * Suggestions for broadening search when appropriate

- [ ] **Resolve entry point and additional details**

### 11. Settings

**Visual Direction:**
Settings should feel like the control room for HIVE's personal infrastructure - organized, calm, and empowering. The design emphasizes clarity and intentionality. Navigation feels precise and logical with appropriate grouping. The aesthetic maintains sophistication while ensuring usability.

- [ ] **Design Settings Home:**
  * Clean list view with grouped sections
  * Section headers use H3 (20px) with proper spacing
  * Items use consistent height (56px) with label and chevron
  * Icons used sparingly and only when adding clarity
  * Visual dividers minimal or absent (spacing creates division)

- [ ] **Design Subsection Navigation:**
  * Consistent header with back action
  * Title uses H2 (28px) for clear hierarchy
  * Transition between levels using horizontal slide (300ms)
  * Maintain scroll position when navigating back

- [ ] **Design Control Components:**
  * Toggles: Custom-styled with subtle animation, gold when active
  * Selection controls: Clean radio/checkbox with gold indicators
  * Text inputs: Consistent with global input styling
  * Pickers: Custom dark-themed selectors with proper contrast

- [ ] **Design Critical Action Flows:**
  * Logout: Standard confirmation dialog
  * Account Deletion: Multi-step confirmation with clear consequences
  * Data-changing operations: Appropriate confirmation + success feedback

- [ ] **Resolve specific settings requirements**

### 12. Admin

**Visual Direction:**
Admin interfaces balance power with restraint - providing comprehensive tools within HIVE's sophisticated aesthetic. The design emphasizes clarity, efficiency, and precision for platform management. Visual treatments distinguish admin functions while maintaining brand cohesion.

- [ ] **Design Access Flow:**
  * Secure authentication with appropriate verification
  * Clear transition signaling elevated access
  * Role-specific welcome/dashboard based on permissions

- [ ] **Design Dashboard:**
  * Key metrics with minimal but effective data visualization
  * Action cards for common functions with clear iconography
  * Alert system for items needing attention
  * All visualizations use brand color palette with subtle distinction

- [ ] **Design Management Interfaces:**
  * Tables with clear hierarchy, proper spacing
  * Filtering and search prominently accessible
  * Action menus with consistent interaction patterns
  * Forms follow global input guidelines with appropriate validation

- [ ] **Design Analytics Views:**
  * Data visualization using brand-appropriate styling
  * Filters and date ranges with custom selectors
  * Export functions with proper feedback
  * Loading states for data-intensive operations

- [ ] **Resolve platform decision and requirements**

### 13. Other Features (*Need Definition & Design*)

- [ ] **Design Post/Drop Creation:**
  * Entry point (FAB? Context button?)
  * Composer interface with clean input area
  * Media attachment handling with previews
  * Publishing flow with appropriate confirmation
  * All elements following global styling guidelines

- [ ] **Design Moderation Flows:**
  * Reporting interface that feels safe and responsive
  * Confirmation and feedback to reporter
  * Review interfaces for moderators with efficient tools
  * Status communications that maintain trust

- [ ] **Design specified features once requirements are defined**

## Cross-Cutting Concerns (Verification/Refinement)

- [ ] **Verify Error States:**
  * Consistent visual language (subtle red glow, shake animation for fields)
  * Clear messaging with actionable guidance
  * Appropriate recovery paths always visible
  * All states accessible via navigation and interaction

- [ ] **Verify Loading States:**
  * Skeleton screens match final layout with subtle animation
  * Progress indicators use minimal styling (thin arcs, subtle pulse)
  * Extended loading includes helpful messaging
  * Transitions from loading to content smooth and natural

- [ ] **Verify Empty States:**
  * Architectural illustrations that fit aesthetic (not cartoon)
  * Messaging strikes right tone (helpful, not apologetic)
  * Clear next actions when appropriate
  * Layout maintains proper spacing and hierarchy

- [ ] **Verify Modals & Dialogs:**
  * Glassmorphism effect consistent (rgba(18,18,18,0.75), 8px blur)
  * Entrance/exit animations smooth (300ms, appropriate easing)
  * Button placement follows expected patterns
  * Dismissal through expected methods (gesture, button, backdrop)

- [ ] **Verify Haptics & Feedback:**
  * Consistent mapping of interactions to haptic patterns
  * Celebration moments include coordinated visual + haptic
  * System settings respected for all feedback types
  * Fallbacks for devices without haptic capabilities

- [ ] **Audit Component Library:**
  * Comprehensive review of all UI elements against specs
  * Documentation with usage guidelines and examples
  * Performance testing for complex components
  * Consistency check across all application surfaces

## Accessibility (WCAG AA Compliance - Verification/Refinement)

- [ ] **Verify Color Contrast:**
  * Text elements achieve 4.5:1 minimum (test each text style)
  * UI elements maintain 3:1 minimum in all states
  * Critical information never conveyed by color alone
  * High contrast mode support

- [ ] **Verify Touch Targets:**
  * All interactive elements minimum 44x44pt
  * Proper spacing between touch targets (min 8px)
  * Testing on various device sizes
  * Special attention to dense interfaces (lists, grids)

- [ ] **Verify Focus Management:**
  * Visible focus indicators (gold glow effect, 4px)
  * Logical tab order through all interfaces
  * No focus traps in complex interfaces
  * Keyboard navigation fully supported

- [ ] **Verify Screen Reader Support:**
  * Proper semantic structure (headings, landmarks)
  * Meaningful labels for all interactive elements
  * Image descriptions where appropriate
  * Live region announcements for dynamic content

- [ ] **Verify Motion Controls:**
  * All animations respect `prefers-reduced-motion`
  * Alternative cues when motion is disabled
  * No critical information conveyed only through animation
  * Testing with animation disabled