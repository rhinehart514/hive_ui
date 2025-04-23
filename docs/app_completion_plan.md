# HIVE Platform V1 Launch Plan

_Last updated: [Current Date]_

**Objective:** Align existing frontend codebase with documented V1 User Flows, integrate with the implemented backend, conduct thorough testing, and achieve production readiness.

**Guiding Documents:**
*   [V1 User Flows Documentation](docs/user_flows.md) (Primary source of truth for features)
*   [HIVE UI Coding Standards and Practices](docs/cursor_rules_hive_ui_clean_code.mdc)
*   [HIVE Core Design Principles](docs/cursor_rules/01-core-design-principles.mdc) & [Component Styling Guide](docs/cursor_rules/02-component-styling.mdc)
*   [HIVE Accessibility & Interaction Standards](docs/cursor_rules/03-accessibility-interaction.mdc)
*   [HIVE Performance & Optimization Standards](docs/cursor_rules/04-performance-optimization.mdc)
*   [State Management Guidelines](docs/cursor_rules/state_management_guidelines.mdc)

_**Note on Plan Evolution:** This plan is a living document. As tasks are completed, new sub-tasks or follow-up actions may be identified. Completed tasks should include brief notes pointing to any resulting artifacts (e.g., documentation, specific code modules)._

---

## Phase 1: User Journey Implementation & API Integration (Est. Duration: [Specify Time])

**Goal:** Implement each step of the user journey according to V1 User Flow specifications and connect to backend APIs.

### 1.1 API Verification & Documentation

*   [x] Analyze `functions/src/index.ts` and related modules to identify all exported Cloud Functions relevant to V1 flows.
*   [x] Document the precise request parameters, expected data format, response structure (success & error), and required authentication for each function. (See `docs/api_contracts.md`)
*   [ ] Cross-reference documented API contracts against the "API Calls & Data" sections in each V1 flow document (`docs/flows/**/*.md`) to ensure all frontend data needs are met. Flag any discrepancies or missing endpoints. *(In Progress)*
*   [x] Create a shared API contract definition (e.g., using OpenAPI/Swagger if desired, or a dedicated Markdown file) for frontend developers. (`docs/api_contracts.md` created)

### 1.2 User Journey Implementation

#### 1.2.1 First-Time Experience: Authentication & Onboarding
*   **Account Creation & Authentication**
    *   [ ] **Resolve Email Verification Discrepancy:** Decide between standard Firebase link verification (per `docs/flows/student/email_verification.md`) and custom code verification (per `functions/src/verification/email-verification.ts`). Update relevant flow documents and ensure backend/frontend implementation aligns with the chosen method.
    *   [ ] Adapt Signup screen UI elements (input fields, buttons) to match V1 flow requirements.
    *   [ ] Connect signup form to backend Auth functions.
    *   [ ] Implement signup loading states and handle success/error responses as defined in flows.
    *   [ ] Implement email verification flow based on chosen method.
    *   [ ] Refactor/Implement Riverpod providers for authentication state (`AuthStateNotifier`, `authProvider`).

*   **Profile Completion**
    *   [ ] Implement the multi-step PageView component with progress indicators.
        *   [ ] Create a custom `OnboardingPageView` widget that handles horizontal swiping
        *   [ ] Implement `PageController` for programmatic navigation between steps
        *   [ ] Add a persistent `ProgressIndicator` component showing current step/total steps
        *   [ ] Implement haptic feedback on page transitions (medium impact)
        *   [ ] Add nav buttons ("Back"/"Next") with proper enable/disable logic
        *   [ ] Include animation for transitions between pages (duration: 300-400ms)
    *   [ ] Create the Name Page with validation (non-empty check).
        *   [ ] Implement `NamePage` widget with branded styling
        *   [ ] Add text input fields for First Name and Last Name with proper keyboard types
        *   [ ] Implement real-time validation (show error when field is empty after interaction)
        *   [ ] Style error messages according to HIVE design system (Error #FF5252 with subtle shake)
        *   [ ] Connect input fields to PageView navigation ("Next" enabled only when valid)
        *   [ ] Store entered name data in shared onboarding state provider
    *   [ ] Create the Year Page with selection widget.
        *   [ ] Implement `YearPage` widget with selection options
        *   [ ] Create selectable cards for year options (Freshman, Sophomore, Junior, Senior, Grad)
        *   [ ] Add selection state styling (selected card has gold accent border)
        *   [ ] Implement tap handling with appropriate haptic feedback
        *   [ ] Automatically advance to next page after selection (with slight delay)
        *   [ ] Store selected year in shared onboarding state provider
    *   [ ] Create the Field (Major) Page with searchable selection.
        *   [ ] Implement `MajorPage` widget with search functionality
        *   [ ] Create a searchable dropdown with major options
        *   [ ] Add a text input field for searching through majors
        *   [ ] Implement filtered results based on search text
        *   [ ] Include recommended/popular majors section for quick selection
        *   [ ] Handle edge case for majors not found in the list (create custom option)
        *   [ ] Store selected major in shared onboarding state provider
    *   [ ] Create the Residence Page with selection options.
        *   [ ] Implement `ResidencePage` widget with residence type options
        *   [ ] Create selectable cards for residence options (On Campus, Off Campus, Commuter)
        *   [ ] For "On Campus" selection, add sub-selection for specific dorms
        *   [ ] Add selection state styling (selected card has gold accent border)
        *   [ ] Implement tap handling with appropriate haptic feedback
        *   [ ] Store residence selection in shared onboarding state provider
    *   [ ] Create the Interests Page with min/max selection validation.
        *   [ ] Implement `InterestsPage` widget with multi-select capability
        *   [ ] Create a grid/list of interest categories with selectable items
        *   [ ] Add category filters to help users find interests more easily
        *   [ ] Implement selection counter showing current/minimum selections (5-10)
        *   [ ] Add selection state styling (selected items have gold accent)
        *   [ ] Enforce minimum selection count (5) before enabling "Next" button
        *   [ ] Enforce maximum selection count (10) by disabling further selections
        *   [ ] Store selected interests array in shared onboarding state provider
    *   [ ] Create the Account Tier Page that displays tier based on email domain.
        *   [ ] Implement `AccountTierPage` widget with tier display
        *   [ ] Create logic to determine tier based on email domain (`.edu`, specific school domains)
        *   [ ] Display appropriate tier badge (Public, Verified, Verified+) with explanatory text
        *   [ ] For Verified/Verified+ tiers, show confirmation of status
        *   [ ] For Public tier, optionally show path to verification
        *   [ ] Add "Complete Profile" button with proper styling
        *   [ ] Connect button tap to profile submission function
    *   [ ] Implement form submission to save profile to Firestore.
        *   [ ] Create a `ProfileSubmissionService` to handle API interactions
        *   [ ] Build the complete `UserProfile` object from collected data
        *   [ ] Implement API call to Firestore (`users` collection)
        *   [ ] Add proper error handling for network/API failures
        *   [ ] Include retry mechanism for failed submissions
        *   [ ] Save profile data locally via `UserPreferencesService` as backup
    *   [ ] Handle loading state and error recovery.
        *   [ ] Implement button loading state (text change to "Saving..." with subtle animation)
        *   [ ] Disable all user interactions during submission
        *   [ ] Create error recovery UI for failed submissions (Snackbar with retry option)
        *   [ ] Add timeout handling for slow connections
        *   [ ] Implement logging for submission failures
    *   [ ] Ensure correct navigation from profile completion to tutorial (not directly to home).
        *   [ ] Update router configuration to define the correct flow sequence
        *   [ ] Implement proper route navigation after successful profile creation
        *   [ ] Mark onboarding as complete via `UserPreferencesService.setOnboardingCompleted(true)`
        *   [ ] Set proper analytics events for completion tracking
        *   [ ] Ensure user cannot navigate back to profile completion once completed

*   **Onboarding Tutorial**
    *   [ ] Implement swipeable card-based tutorial interface with max 4 cards.
    *   [ ] Create card 1 (Feed Introduction) with required content.
    *   [ ] Create card 2 (Rituals Introduction) with conditional content for active rituals.
    *   [ ] Create card 3 (Events Introduction) with required content.
    *   [ ] Create card 4 (Spaces Introduction) with required content and final action button.
    *   [ ] Implement transition from final tutorial card to Home/Feed.
    *   [ ] Set up automatic scroll to highlight top-most active Ritual card in Feed.

#### 1.2.2 Main Feed Experience & Content Discovery
*   **Feed Loading & Refreshing**
    *   [ ] Implement initial feed loading with hexagonal ripple loader animation.
        *   [ ] Create a custom `HexagonalRippleLoader` widget with black and gold color scheme
        *   [ ] Implement pulsing animation using `AnimationController` (subtle pulse, short loop)
        *   [ ] Ensure centered positioning in the feed area
        *   [ ] Set up proper loading state management in feed provider
        *   [ ] Add animation timing configurations (duration, curve)
        *   [ ] Optimize animation performance with `RepaintBoundary`
        *   [ ] Create fade-in/out transitions between loader and content
    *   [ ] Create custom empty state with floating gold hex illustration and CTA buttons.
        *   [ ] Design abstract floating gold hex illustration component
        *   [ ] Add dim glow effect to the illustration
        *   [ ] Create "It's quiet here..." headline with proper typography
        *   [ ] Implement primary CTA button "Explore Spaces" with tap handling
        *   [ ] For first-day users, add logic to rotate suggested CTAs (Join Ritual, Browse Events, Start Drop)
        *   [ ] Connect CTAs to appropriate navigation actions
        *   [ ] Implement subtle floating animation for the illustration
    *   [ ] Implement pull-to-refresh with gold hex spinner animation.
        *   [ ] Set up `RefreshIndicator` with custom styling
        *   [ ] Create gold hex spinner with ripple animation (non-linear)
        *   [ ] Position the spinner in the top bar area during refresh
        *   [ ] Connect refresh action to feed data provider
        *   [ ] Implement proper gesture detection and thresholds
        *   [ ] Add haptic feedback on refresh trigger and completion
        *   [ ] Set correct refresh completion criteria
    *   [ ] Set up local feed caching with 2-minute expiration.
        *   [ ] Create a `FeedCacheService` to manage local cache
        *   [ ] Implement cache storage using Hive or shared_preferences
        *   [ ] Add timestamp metadata to cached data
        *   [ ] Set up cache expiration logic (2-minute threshold)
        *   [ ] Create cache validation and retrieval methods
        *   [ ] Implement background refresh when showing cached data
        *   [ ] Add cache clearing on major app events (login, logout)
    *   [ ] Implement feed error states with retry options.
        *   [ ] Create full-screen error view for initial load failure
        *   [ ] Add prominent "Retry" button with proper styling
        *   [ ] Implement Snackbar for refresh failure ("Refresh failed. Try again.")
        *   [ ] Add error analytics tracking with reason categorization
        *   [ ] Set up automatic retry logic with exponential backoff
        *   [ ] Create network connectivity checking before retries
        *   [ ] Implement error state transitions and animations
    *   [ ] Ensure content cards (Post, Event, Ritual) match V1 designs and display correct data.
        *   [ ] Create base `FeedCard` widget with shared styling and behavior
        *   [ ] Implement `PostCard` variant with proper content layout
        *   [ ] Implement `EventCard` variant with time/location information
        *   [ ] Create `RitualCard` variant with active state indicators
        *   [ ] Implement "THE BRACKET" Ritual Strip with special styling
        *   [ ] Add card animations (hover state, active state)
        *   [ ] Ensure proper rendering of media content (edge-to-edge)
        *   [ ] Implement consistent border radius, padding, and spacing
        *   [ ] Add skeleton placeholder states for loading content
        *   [ ] Set up data binding between card and model classes

*   **Content Interaction (Feed Cards)**
    *   [ ] Implement tap targets on feed cards (main content area for drill-in, separate areas for profile/buttons).
    *   [ ] Set up navigation from feed cards to detail screens with proper transitions.
    *   [ ] Ensure back navigation returns user to previous scroll position.
    *   [ ] Handle errors for content that no longer exists.

*   **Feed Actions & Interactions**
    *   [ ] Implement Like action with optimistic updates and error handling.
    *   [ ] Implement Comment action navigating to comment interface.
    *   [ ] Implement Save/Bookmark action with local state updates.
    *   [ ] Implement Share action (external and internal).
    *   [ ] Implement Report action with appropriate UI flow.
    *   [ ] Implement Boost/Repost functionality.

#### 1.2.3 Engagement & Participation

*   **Rituals Participation (The Bracket)**
    *   [ ] Implement Bracket Status Strip in feed.
        *   [ ] Create `BracketStatusStrip` widget with distinctive styling
        *   [ ] Implement real-time data fetching for current bracket status
        *   [ ] Add visual indicators for active phase (matchup, nomination, etc.)
        *   [ ] Display current competing Spaces with micro-logos
        *   [ ] Show countdown timer for phase end
        *   [ ] Create pulsing highlight animation to draw attention
        *   [ ] Add tap handler to launch Engagement Hub
        *   [ ] Implement haptic feedback on tap (medium impact)
    *   [ ] Create full-screen modal BRACKET Engagement Hub with vertical slide-up animation.
        *   [ ] Set up `BracketEngagementHub` as a modal dialog route
        *   [ ] Implement fast vertical slide-up animation (250-350ms)
        *   [ ] Add semi-transparent backdrop with blur effect
        *   [ ] Create swipe-down gesture for dismissal
        *   [ ] Add close button ('X') with tap area optimization
        *   [ ] Create container with proper border radius and styling
        *   [ ] Implement safe area insets for device compatibility
    *   [ ] Implement LiveMomentumMeter component showing current engagement scores.
        *   [ ] Create `LiveMomentumMeter` widget with dynamic visualization
        *   [ ] Implement binary comparison visual (Space A vs Space B)
        *   [ ] Add real-time updating from backend data source
        *   [ ] Create smooth transition animations for score changes
        *   [ ] Implement color coding for leading team (gold accent)
        *   [ ] Add percentage or point display if applicable
        *   [ ] Create pulsing effect for close competitions
        *   [ ] Implement WebSocket connection for live updates
    *   [ ] Create EngagementActions component with support actions.
        *   [ ] Build `EngagementActions` container with proper layout
        *   [ ] Implement "Support [Space A/B]" section headers
        *   [ ] Create "Add Post" action button with custom styling
        *   [ ] Implement "Comment in Thread" action with navigation
        *   [ ] Create "React Now" quick action with reaction options
        *   [ ] Add "Invite Members" sharing action
        *   [ ] Implement phase-specific actions that appear conditionally
        *   [ ] Connect each action to appropriate handler function
    *   [ ] Implement loading states within action buttons.
        *   [ ] Create button-specific loading indicators (replacing text)
        *   [ ] Add spinner or progress animations within buttons
        *   [ ] Implement disabled state styling during loading
        *   [ ] Set up timeout handling for long-running operations
        *   [ ] Create smooth transitions between states
        *   [ ] Ensure loading state is directly tied to API call lifecycle
    *   [ ] Set up immediate contextual feedback and momentum meter updates.
        *   [ ] Implement immediate UI updates for user actions (post appears, comment added)
        *   [ ] Create visual update animation for `LiveMomentumMeter`
        *   [ ] Add success haptics on action completion
        *   [ ] Implement optimistic updates with rollback capability
        *   [ ] Create micro-animations for successful engagement
        *   [ ] Set up state synchronization between local and server data
    *   [ ] Handle various error states (inline, snackbar, modal dialog).
        *   [ ] Implement inline validation errors with appropriate styling
        *   [ ] Create Snackbar implementation for retryable API/network errors
        *   [ ] Build modal dialog system for critical errors (rate limiting, bans)
        *   [ ] Add error-specific recovery actions
        *   [ ] Create error analytics tracking
        *   [ ] Implement graceful degradation for partial failures
        *   [ ] Add localized error messages with clear user guidance
    *   [ ] Implement manual dismissal of the modal.
        *   [ ] Set up swipe gesture detection for dismissal
        *   [ ] Add close button tap handler
        *   [ ] Implement vertical slide-down animation on exit
        *   [ ] Create fade-out transition for the backdrop
        *   [ ] Add haptic feedback on dismissal
        *   [ ] Ensure proper cleanup of resources on dismissal
        *   [ ] Handle edge cases (dismiss during loading state)

*   **Events Discovery & Participation**
    *   [ ] Implement Event Card in feed with proper layout and information.
    *   [ ] Create Event Detail view with full event information.
    *   [ ] Implement RSVP and Cancel RSVP actions with confirmation.
    *   [ ] Create Event Check-in functionality with location verification if applicable.
    *   [ ] Set up reminder notifications for upcoming events.

*   **Spaces Discovery & Interaction**
    *   [ ] Implement Spaces Discovery UI with search/filter functionality.
    *   [ ] Create Space Detail view with description, members, content sections.
    *   [ ] Implement Join/Leave Space actions with confirmation dialogs.
    *   [ ] Connect space-specific content feeds.

#### 1.2.4 Content Creation & Management

*   **Post Creation**
    *   [ ] Adapt Post Composer UI for text and media posts.
        *   [ ] Create `PostComposerScreen` with proper layout and styling
        *   [ ] Implement expandable text input area with proper keyboard handling
        *   [ ] Add placeholder text ("What's happening?") with proper styling
        *   [ ] Create post type selector (Text, Image, Video) with toggle UI
        *   [ ] Implement toolbar with formatting options (bold, italic, etc.)
        *   [ ] Add emoji selector button with picker interface
        *   [ ] Create header area with avatar and user information
        *   [ ] Add "Cancel" and "Post" buttons with proper positioning
        *   [ ] Implement keyboard avoidance behavior
        *   [ ] Create animation for expanding/collapsing the composer
        *   [ ] Add haptic feedback for key interactions
    *   [ ] Implement media selection and preview.
        *   [ ] Create media picker interface for images and videos
        *   [ ] Implement gallery access with permission handling
        *   [ ] Add camera access option with permission handling
        *   [ ] Create preview thumbnails for selected media
        *   [ ] Implement multi-select capability (up to X media items)
        *   [ ] Add media removal functionality
        *   [ ] Create media reordering capability (drag-and-drop)
        *   [ ] Implement image cropping/editing capabilities
        *   [ ] Add video trimming functionality
        *   [ ] Create media compression service for optimal upload size
        *   [ ] Implement placeholder/skeleton UI during media loading
    *   [ ] Connect post submission to backend create functions.
        *   [ ] Create `PostCreationService` to handle API interactions
        *   [ ] Implement media upload process (potentially to Firebase Storage)
        *   [ ] Add progress tracking for media uploads
        *   [ ] Create post metadata generation (timestamp, location if enabled)
        *   [ ] Implement final post submission to Firestore
        *   [ ] Add tagging functionality for users, spaces, events
        *   [ ] Create logging for post creation analytics
        *   [ ] Implement error handling for upload/submission failures
        *   [ ] Add retry mechanism for failed submissions
    *   [ ] Implement character counters and button enable/disable logic.
        *   [ ] Create character counter UI with remaining count
        *   [ ] Implement max character limitation (X characters)
        *   [ ] Add visual indication when approaching limit (color change)
        *   [ ] Create hard stop at maximum character count
        *   [ ] Implement "Post" button enable logic (require text or media)
        *   [ ] Add validation for minimum meaningful content
        *   [ ] Create smooth animations for counter updates
        *   [ ] Implement warning for very short posts
    *   [ ] Set up Draft Auto-Save/Resume logic using local storage.
        *   [ ] Create `DraftService` for managing post drafts
        *   [ ] Implement periodic auto-save functionality (every X seconds)
        *   [ ] Add draft storage using Hive or similar local database
        *   [ ] Create draft metadata (timestamp, type, completion status)
        *   [ ] Implement draft listing and selection UI
        *   [ ] Add draft resumption functionality
        *   [ ] Create draft cleanup policy (expiration after X days)
        *   [ ] Implement draft recovery after app crash
        *   [ ] Add confirmation dialog for exiting with unsaved changes
        *   [ ] Create draft analytics to track abandonment and resumption

*   **Post Management**
    *   [ ] Implement Edit post functionality.
    *   [ ] Create Delete post flow with confirmation.
    *   [ ] Connect actions to backend functions.
    *   [ ] Handle loading and error states for all actions.

#### 1.2.5 Communication & Social Features

*   **Direct Messaging**
    *   [ ] Implement Chat List screen, fetching data from backend.
    *   [ ] Set up WebSocket connection for real-time message send/receive.
    *   [ ] Create DM conversation view UI.
    *   [ ] Implement Start New DM flow (search, profile entry).
    *   [ ] Connect Send Message, Archive, Delete, Report actions.

*   **Profile & Social Graph**
    *   [ ] Adapt Own/Other Profile screen UIs based on V1 definitions.
    *   [ ] Connect data fetching (posts, saved, spaces, events, followers).
    *   [ ] Implement Edit Profile UI and connect save action to backend.
    *   [ ] Connect Follow/Unfollow actions with confirmation prompts.
    *   [ ] Create private Activity Trail view.

*   **Notifications**
    *   [ ] Implement Notification Feed screen UI, fetching notifications from backend.
    *   [ ] Create tap-through deep-linking logic.
    *   [ ] Implement "Mark all read" action.
    *   [ ] Set up push notification registration and permission flow.
    *   [ ] Connect Notification Preferences screen in Settings to backend update API.

#### 1.2.6 Settings & Support

*   **Settings**
    *   [ ] Align Settings screen sections and UI.
    *   [ ] Connect Change Email/Password initiations.
    *   [ ] Connect Privacy toggles (Private Profile, DM Control) to backend update API.
    *   [ ] Connect Accessibility toggle (Reduced Motion) state.

*   **Support**
    *   [ ] Implement Help/FAQ external link.
    *   [ ] Create Contact Support in-app form.
    *   [ ] Connect submission to backend/support channel.
    *   [ ] Implement password reset functionality.
    *   [ ] Create logout flow.

#### 1.2.7 Cross-Cutting Concerns

*   **Offline & Error Handling**
    *   [ ] Implement persistent offline banner indicator.
    *   [ ] Create local caching strategy for feed/profile data.
    *   [ ] Set up offline action queueing logic for posts/comments.
    *   [ ] Implement queue synchronization logic on reconnect.
    *   [ ] Create standard Snackbar display for general network errors with retry.
    *   [ ] Implement Maintenance banner display logic.
    *   [ ] Create Force Upgrade modal logic.

### 1.3 Firestore Rules Validation

*   [ ] Review `firestore.rules` line-by-line against each V1 flow's data access requirements.
*   [ ] Verify rules for reading/writing posts, comments, spaces, events, profiles, DMs.
*   [ ] Ensure rules correctly handle public vs. private data, space membership, and ownership checks.
*   [ ] Write/update rules simulator tests if applicable.

---

## Phase 2: Polishing & HIVE Standard Compliance (Est. Duration: [Specify Time])

**Goal:** Ensure the application meets HIVE's high standards for design, interaction, accessibility, and performance.

### 2.1 UI/UX Audit & Refinement By Journey Stage

#### 2.1.1 First-Time Experience
*   [ ] Review and refine authentication screens (login, signup, verification).
*   [ ] Polish onboarding profile completion UI with consistent styling.
*   [ ] Enhance tutorial card animations and transitions.

#### 2.1.2 Main Feed Experience
*   [ ] Perfect feed loading animations and transitions.
*   [ ] Refine feed card designs and interaction states.
*   [ ] Polish pull-to-refresh mechanics and visual feedback.

#### 2.1.3 Engagement Features
*   [ ] Review ritual participation interfaces for visual polish.
*   [ ] Refine event cards and detail views.
*   [ ] Polish space discovery and detail screens.

#### 2.1.4 Content Creation
*   [ ] Enhance composer UI and interaction patterns.
*   [ ] Refine media selection and preview experiences.
*   [ ] Polish draft management interfaces.

#### 2.1.5 Communication & Social
*   [ ] Review and enhance DM interfaces.
*   [ ] Refine profile screens and social interactions.
*   [ ] Polish notification presentation and interaction.

#### 2.1.6 Overall UI Consistency
*   [ ] Correct color usage (`AppColors`, contrast ratios) across all screens.
*   [ ] Verify typography (Inter font, correct weights/sizes/line heights) throughout.
*   [ ] Check spacing, padding, margins against 8pt grid and spacing tokens.
*   [ ] Ensure consistent border radii (8px standard).
*   [ ] Validate implementation of glassmorphism effects (blur radius, opacity).
*   [ ] Confirm adherence to core styling rules (no mixed shapes, elevation only, edge-to-edge media).

### 2.2 Animation & Interaction Polish

*   [ ] Audit screen transitions (GoRouter) for smoothness and appropriate duration (300-400ms).
*   [ ] Review widget state change animations (e.g., button presses, loading spinners) for clarity and standard durations.
*   [ ] Implement standard Haptic feedback patterns (tap, success, error, long press) on interactive elements as per `03-accessibility-interaction`.
*   [ ] Test "Reduced Motion" toggle functionality across the app.

### 2.3 Accessibility Review

*   [ ] Check semantic structure (use of `Semantics` widget, heading levels).
*   [ ] Verify minimum contrast ratios (4.5:1 text, 3:1 UI elements).
*   [ ] Test focus indicator visibility and style (`#EEB700` glow).
*   [ ] Perform screen reader testing (VoiceOver/TalkBack) on key flows.
*   [ ] Ensure adequate touch target sizes (min 44x44pt).

### 2.4 Performance Tuning

*   [ ] Use Flutter DevTools to profile key screens/interactions (feed scroll, profile load, posting).
*   [ ] Identify and minimize unnecessary widget rebuilds (check `build` methods, use `const`, `StatefulWidget` lifecycle).
*   [ ] Optimize image loading (use appropriate formats like WebP, implement caching with `cached_network_image` or similar, resize images).
*   [ ] Review Firestore query efficiency (indexing, limiting reads).
*   [ ] Optimize list view performance (`ListView.builder`, appropriate keys).
*   [ ] Analyze app startup time.

---

## Phase 3: Testing & Validation Following User Journeys (Est. Duration: [Specify Time])

**Goal:** Achieve comprehensive test coverage and validate functionality, security, and stability.

### 3.1 Journey-Based Testing

#### 3.1.1 First-Time User Journey
*   [ ] Test complete signup flow with various email domains.
    *   [ ] Test signup with standard Gmail/non-edu email (Public tier)
    *   [ ] Test signup with generic .edu email domain (Verified tier)
    *   [ ] Test signup with specific school domain (e.g., buffalo.edu for Verified+ tier)
    *   [ ] Test validation error handling for invalid email formats
    *   [ ] Test validation error handling for password requirements
    *   [ ] Test account creation with existing email (duplicate detection)
    *   [ ] Verify email verification flow for each domain type
    *   [ ] Test signup flow completion after verification
    *   [ ] Verify analytics events for signup steps are triggered
    *   [ ] Test transition from signup completion to profile creation
*   [ ] Validate profile completion with different input combinations.
    *   [ ] Test Name page with valid inputs (both first and last name)
    *   [ ] Test Name page with empty fields (validation errors)
    *   [ ] Test Year page selection for each academic year option
    *   [ ] Test Major page with direct selection from list
    *   [ ] Test Major page with search functionality
    *   [ ] Test Major page with non-existent major search
    *   [ ] Test Residence page with each residence type
    *   [ ] Test Interests page with minimum selection (5 interests)
    *   [ ] Test Interests page with maximum selection (10 interests)
    *   [ ] Test Interests page with under-minimum selection (error state)
    *   [ ] Test Account Tier page display for each tier type
    *   [ ] Test profile submission success path
    *   [ ] Test profile submission error handling and recovery
    *   [ ] Verify all entered data is correctly saved to Firestore
    *   [ ] Confirm proper state management across multiple pages
*   [ ] Verify tutorial presentation and interaction.
    *   [ ] Confirm tutorial is displayed after profile completion
    *   [ ] Test card 1 (Feed Introduction) content and swipe/tap navigation
    *   [ ] Test card 2 (Rituals Introduction) with conditional content logic
    *   [ ] Test card 3 (Events Introduction) content and navigation
    *   [ ] Test card 4 (Spaces Introduction) content and final action button
    *   [ ] Verify animation and transitions between cards
    *   [ ] Test haptic feedback during tutorial navigation
    *   [ ] Confirm analytics events for tutorial steps are triggered
    *   [ ] Test "Let's Go" button on final card
*   [ ] Confirm proper transition to main feed.
    *   [ ] Verify navigation to Feed after tutorial completion
    *   [ ] Test auto-scroll to highlight top Ritual card
    *   [ ] Verify feed loading animation and data presentation
    *   [ ] Confirm proper onboarding completion state in UserPreferencesService
    *   [ ] Test navigation structure after onboarding (tab bar availability)
    *   [ ] Verify analytics event for onboarding completion
    *   [ ] Test return visit (app restart) to confirm onboarding is not reshown
    *   [ ] Verify all user data from onboarding is reflected in the app

#### 3.1.2 Returning User Journey
*   [ ] Test login with valid and invalid credentials.
*   [ ] Verify password reset flow.
*   [ ] Confirm proper loading of user data and preferences.

#### 3.1.3 Daily Engagement Journey
*   [ ] Test feed loading, refreshing, and interaction.
*   [ ] Validate content interactions (like, comment, save).
*   [ ] Test ritual participation flows.
*   [ ] Verify event discovery and RSVP functionality.

#### 3.1.4 Content Creation Journey
*   [ ] Test creating, editing, and deleting posts.
*   [ ] Verify media upload functionality.
*   [ ] Test draft saving and resuming.

#### 3.1.5 Social Interaction Journey
*   [ ] Test profile viewing and editing.
*   [ ] Validate follow/unfollow functionality.
*   [ ] Test direct messaging features.
*   [ ] Verify notification delivery and interaction.

### 3.2 Automated Testing

*   [ ] Write Unit Tests for critical state notifiers, utility functions, data parsing logic.
*   [ ] Write Widget Tests for reusable components (buttons, cards, input fields) verifying rendering and basic interactions.
*   [ ] Implement Integration Tests using `flutter_driver` or `integration_test` package for:
    *   Login / Logout flow
    *   Signup flow
    *   Create Text/Media Post flow
    *   View Feed & Drill-in flow
    *   Join/Leave Space flow
    *   RSVP/Cancel Event flow
    *   Send/Receive DM flow

### 3.3 Quality Assurance

*   [ ] Develop test cases based on the Acceptance Criteria listed in each V1 user flow document.
*   [ ] Execute test cases on target devices (iOS/Android phones, tablets?) and OS versions.
*   [ ] Test error handling scenarios (network offline, API errors, invalid input).
*   [ ] Test permission handling (camera, storage, notifications).
*   [ ] Verify offline mode functionality (caching, queuing, syncing).
*   [ ] Test usability and adherence to design during interactions.

### 3.4 Security Audit

*   [ ] Perform path traversal tests on Firestore rules.
*   [ ] Verify input sanitization in Cloud Functions.
*   [ ] Check for hardcoded secrets or keys in the frontend codebase.
*   [ ] Review authentication token storage and refresh logic.
*   [ ] Test access control based on user roles/permissions as defined for V1 (e.g., reporting, admin tools).

### 3.5 User Acceptance Testing (UAT)

*   [ ] Recruit 5-10 target student users.
*   [ ] Define realistic task scenarios based on key V1 user journeys.
*   [ ] Observe users performing tasks, collect feedback on usability, clarity, and bugs.

---

## Phase 4: Deployment & Launch Readiness (Est. Duration: [Specify Time])

**Goal:** Prepare infrastructure, monitoring, and app store presence for a successful launch.

### 4.1 Infrastructure & CI/CD

*   [ ] Set up separate Firebase projects for Development, Staging (Optional), and Production.
*   [ ] Configure Firestore, Auth, Storage, and Functions settings for Production (regions, scaling, rules deployment).
*   [ ] Implement CI/CD pipeline (e.g., GitHub Actions) to:
    *   Run linters (`flutter analyze`).
    *   Run automated tests (unit, widget, integration).
    *   Build iOS and Android app bundles/APKs (dev, prod variants).
    *   Deploy Cloud Functions.
    *   Deploy Firestore rules.
    *   Distribute builds to TestFlight (iOS) and Internal Testing (Android).
    *   (Optional) Automate store submission.

### 4.2 Analytics & Monitoring For User Journey Stages

*   [ ] Configure Analytics events for onboarding funnel tracking.
*   [ ] Set up event tracking for feed engagement and content interaction.
*   [ ] Implement ritual and event participation analytics.
*   [ ] Configure content creation and sharing analytics.
*   [ ] Set up social interaction and messaging event tracking.
*   [ ] Verify all `Analytics.` calls specified in flow docs are implemented.
*   [ ] Set up Firebase Crashlytics for crash reporting.
*   [ ] Set up Firebase Performance Monitoring for tracking network requests and screen load times.
*   [ ] Configure basic alerting for critical backend function errors or high crash rates.

### 4.3 App Store Preparation

*   [ ] Generate final app icons in all required sizes.
*   [ ] Create compelling screenshots and app preview videos for key V1 flows.
*   [ ] Write App Store and Google Play descriptions, keywords, and release notes.
*   [ ] Provide links to Privacy Policy and Terms of Service.
*   [ ] Configure app settings in App Store Connect and Google Play Console (pricing, availability, age rating, etc.).

### 4.4 Final Checks & Go/No-Go

*   [ ] Perform full regression testing on release candidate builds following user journeys.
    *   [ ] Run comprehensive test suite on iOS release candidate build
    *   [ ] Run comprehensive test suite on Android release candidate build
    *   [ ] Test on minimum supported iOS version (iOS X.X)
    *   [ ] Test on minimum supported Android version (Android X.X)
    *   [ ] Verify performance on low-end devices
    *   [ ] Test network degradation scenarios (slow connection, intermittent connection)
    *   [ ] Verify offline functionality works as expected
    *   [ ] Test background/foreground transitions and app state restoration
    *   [ ] Verify push notification delivery and handling
    *   [ ] Test deep linking functionality from notifications and external sources
    *   [ ] Verify analytics events are firing correctly and being received
    *   [ ] Perform final accessibility review (screen reader, contrast, touch targets)
    *   [ ] Test data migration for existing users (if applicable)
*   [ ] Complete launch checklist (infrastructure ready, monitoring active, store assets prepared, critical bugs fixed).
    *   [ ] Verify Firebase project configuration is complete
    *   [ ] Confirm Firestore rules are deployed and tested
    *   [ ] Verify Cloud Functions are deployed and operational
    *   [ ] Confirm Storage security rules are in place
    *   [ ] Test Authentication settings and providers
    *   [ ] Verify Crashlytics is properly configured
    *   [ ] Confirm Performance Monitoring is active
    *   [ ] Check Analytics event collection is working
    *   [ ] Verify all critical (P0/P1) bugs are resolved
    *   [ ] Confirm all blocking issues have been addressed
    *   [ ] Verify app store assets are finalized and approved
    *   [ ] Confirm versioning and build numbers are correct
    *   [ ] Check that app size is within acceptable limits
    *   [ ] Verify SSL certificates are valid and not expiring soon
    *   [ ] Confirm all third-party services have active accounts/credentials
    *   [ ] Test backup and recovery procedures
    *   [ ] Verify monitoring alerts are configured properly
*   [ ] Hold final Go/No-Go meeting with stakeholders.
    *   [ ] Prepare comprehensive test results summary
    *   [ ] Present metrics on app performance and stability
    *   [ ] Review outstanding issues with severity assessments
    *   [ ] Present mitigation plans for known issues
    *   [ ] Review analytics instrumentation coverage
    *   [ ] Confirm marketing and launch communications are ready
    *   [ ] Verify support team is prepared and trained
    *   [ ] Present rollout strategy and timeline
    *   [ ] Discuss criteria for emergency rollback
    *   [ ] Establish post-launch monitoring responsibilities
    *   [ ] Define success metrics for initial launch period
    *   [ ] Secure explicit go/no-go decision from each stakeholder
    *   [ ] Document decision with justification
    *   [ ] Create action plan for any conditional approvals

### 4.5 Deployment

*   [ ] Deploy final backend Cloud Functions and Firestore rules to Production.
*   [ ] Submit final iOS build to App Store Connect for review.
*   [ ] Submit final Android build to Google Play Console for review.
*   [ ] Monitor review process and respond to any feedback.
*   [ ] Plan release strategy (e.g., phased rollout vs. immediate availability).
*   [ ] Announce launch!

---

*This plan prioritizes implementing and integrating the user journey in order, followed by polishing, rigorous testing, and deployment preparation. By following the natural flow of the user experience, we ensure a coherent and complete implementation of the HIVE platform.*