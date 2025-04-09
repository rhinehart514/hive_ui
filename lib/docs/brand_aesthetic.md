# HIVE Brand Aesthetic Guide

## Core Color Palette

```dart
// Primary colors
static const Color black = Color(0xFF0A0A0A); // Primary background (deep, near-black)
static const Color white = Color(0xFFFFFFFF); // Primary text & bright accents
static const Color secondaryText = Color(0xFFBFBFBF); // Secondary text (80% white on black)
static const Color tertiaryText = Color(0xFF808080); // Tertiary text (50% white on black, for metadata)
static const Color yellow = Color(0xFFFFD700); // Interactive accent color, signals intent
static const Color gold = Color(0xFFFFD700); // Alias for yellow
```

## Design Principles

### 1. Elevated Grid Rhythm

HIVE utilizes a modular vertical stacking approach with subtle lateral flow patterns:

- **Vertical Primary Flow**: Optimized for natural scrolling while providing visual interest
- **Fixed-Width Modules**: Event cards maintain consistent width for visual stability
- **Lateral Motion**: Spaces use soft horizontal scrolls (iOS Safari tabs style)
- **Modal Layering**: Messaging uses vertically stacked, semi-glass modal overlays
- **Rhythmic Spacing**: Spacing serves as rhythm-creator, not just whitespace

Implementation guidelines:
- Use consistent 16dp vertical spacing between major content blocks (cards, sections).
- Apply 8dp spacing *within* content groupings (e.g., between title and description in a card).
- Maintain fixed card widths (match parent width minus consistent 16dp horizontal margins on mobile).
- Implement subtle elevation for visual hierarchy (see Depth & Elevation System).
- **Alignment is critical**: Use tools like `Column`, `Row`, `Stack`, `Align` precisely. Avoid visual clutter through strict alignment.

### 2. Yellow as a Cognitive Signal

Yellow (#FFD700) serves as an intention-focused interactive signal:

- **Never Decorative**: Yellow is reserved for interactive elements requiring attention
- **Decision Points**: Used exclusively for elements requiring student decisions
- **Specific Applications**:
  - RSVP buttons and confirmations
  - "Honey Mode" featured events
  - Repost tags and indicators
  - Achievement badges
  - Interactive call-to-action elements
- **Never Backgrounds**: Yellow should never be used as a background color
- **Icon Restriction**: Never used for purely decorative icons

Think of yellow as the "tap here, this matters" visual language.

- **Premium Feel**: Use yellow sparingly like a highlight, not broadly. Its impact comes from restraint.
- **State Indication**: Can be used subtly for active states (e.g., selected tab indicator, "liked" icon fill) but avoid large color fills.

### 3. True System Layers (Spatial, Not Flat)

The interface uses spatial layering to create depth and hierarchy:

- **Background Layer** (#0A0A0A): Base application canvas
- **Content Layer**: Where primary content lives (cards, lists)
- **Interactive Layer**: Controls and interactive elements
- **Modal Layer**: Overlays, dialogs, and contextual interfaces

Implementation guidelines:
- Use defined elevation levels and shadows (see Depth & Elevation System).
- Apply refined glassmorphism for overlays (see Glassmorphism & Surface Design).
- Maintain consistent z-index patterns.
- Animate transitions between layers with refined timing and curves (see Motion & Interaction).
- **Progressive Disclosure**: Design layers to reveal information contextually upon interaction, reducing initial visual load.

## Typography System (Refined)

```dart
// Base Font: Inter (Ensure imported via google_fonts or locally)

// Primary font styles
static TextStyle get displayLarge => GoogleFonts.inter( // Screen Titles
  color: AppColors.white,
  fontSize: 32,
  fontWeight: FontWeight.w700, // Bold
  letterSpacing: -0.5, // Slightly tighter tracking
);

static TextStyle get titleLarge => GoogleFonts.inter( // Card Titles, Section Headers
  color: AppColors.white,
  fontSize: 20,
  fontWeight: FontWeight.w600, // Semibold
  letterSpacing: -0.25,
);

static TextStyle get bodyLarge => GoogleFonts.inter( // Primary Body Text
  color: AppColors.white,
  fontSize: 16,
  fontWeight: FontWeight.w400, // Regular
  letterSpacing: 0,
);

static TextStyle get bodyMedium => GoogleFonts.inter( // Secondary Body Text
  color: AppColors.secondaryText, // Lighter gray
  fontSize: 14,
  fontWeight: FontWeight.w400, // Regular
  letterSpacing: 0.1, // Slightly looser for readability
);

static TextStyle get caption => GoogleFonts.inter( // Timestamps, Metadata
  color: AppColors.tertiaryText, // Lowest contrast gray
  fontSize: 12,
  fontWeight: FontWeight.w400, // Regular
  letterSpacing: 0.2, // Looser for small sizes
);

// Interactive text (buttons, links) - Prefer Yellow Accent
static TextStyle get labelLarge => GoogleFonts.inter( // Key action text
  color: AppColors.yellow,
  fontSize: 16,
  fontWeight: FontWeight.w600, // Semibold
  letterSpacing: 0.1,
);

static TextStyle get labelMedium => GoogleFonts.inter( // Smaller interactive text/icons
  color: AppColors.yellow,
  fontSize: 14,
  fontWeight: FontWeight.w500, // Medium
  letterSpacing: 0.1,
);
```
**Guidance**: Maintain strict adherence to these styles. Avoid one-off font sizes or weights. Use `letterSpacing` subtly for refinement.

## Component Guidelines

### Button System (Updated Styles & Feedback)

```dart
// Primary action button (High contrast, solid fill - Less common, use strategically)
ElevatedButton(
  onPressed: () {
    HapticFeedback.mediumImpact();
    // Action
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.white, // White button
    foregroundColor: AppColors.black, // Black text
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12), // Softer radius
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), // Adjusted padding
    minimumSize: const Size(0, 48), // Ensure min height
    elevation: 0, // Remove default elevation, control via custom shadow/state
  ).copyWith(
     // Add subtle press state if needed, e.g., slightly darker background
  ),
  child: Text('Primary Action', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
)

// Secondary action button (Subtle outline, default choice)
OutlinedButton(
  onPressed: () {
    HapticFeedback.lightImpact(); // Lighter haptic
    // Action
  },
  style: OutlinedButton.styleFrom(
    foregroundColor: AppColors.white, // White text
    side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1.0), // Defined border
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12), // Softer radius
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), // Adjusted padding
    minimumSize: const Size(0, 48), // Ensure min height
  ).copyWith(
    // Overlay color for press state (e.g., subtle white overlay)
    overlayColor: MaterialStateProperty.resolveWith<Color?>(
      (Set<MaterialState> states) {
        if (states.contains(MaterialState.pressed)) {
          return Colors.white.withOpacity(0.1); // Subtle press
        }
        return null; // Defer to the default
      },
    ),
  ),
  child: Text('Secondary Action', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
)

// Interactive accent button (Yellow, for key actions like RSVP)
TextButton(
  onPressed: () {
    HapticFeedback.mediumImpact(); // Clear feedback for important action
    // Action
  },
  style: TextButton.styleFrom(
    foregroundColor: AppColors.yellow, // Yellow text
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Generous padding
    minimumSize: const Size(0, 48), // Ensure touch target
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ).copyWith(
    // Yellow overlay for press state
    overlayColor: MaterialStateProperty.resolveWith<Color?>(
      (Set<MaterialState> states) {
        if (states.contains(MaterialState.pressed)) {
          return AppColors.yellow.withOpacity(0.15);
        }
        return null;
      },
    ),
  ),
  child: Text('RSVP Now', style: labelMedium), // Use defined text style
)
```
**Guidance**: Ensure all interactive elements have clear press states (visual + haptic) and meet the minimum 48dp touch target size, crucial for mobile usability. Use `MaterialStateProperty` for stateful styling.

### Cards & Containers (Refined Glass/Standard)

```dart
// Standard content card (Subtle dark background, minimal border)
Container(
  padding: const EdgeInsets.all(16), // Consistent internal padding
  decoration: BoxDecoration(
    // Slightly lighter than pure black for subtle lift
    color: const Color(0xFF1C1C1E), // Example: iOS dark mode card color
    borderRadius: BorderRadius.circular(16), // More rounded corners
    border: Border.all(
      color: Colors.white.withOpacity(0.1), // Fainter border
      width: 0.5,
    ),
  ),
  child: content, // Your card's content widget
)

// Interactive card (Can use subtle state changes or accent)
InkWell(
  onTap: () {
     HapticFeedback.lightImpact();
     onTap();
  },
  borderRadius: BorderRadius.circular(16), // Match decoration
  // Optional: Subtle highlight on tap
  // splashColor: AppColors.yellow.withOpacity(0.05),
  // highlightColor: Colors.white.withOpacity(0.05),
  child: Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF1C1C1E),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.white.withOpacity(0.1),
        width: 0.5,
      ),
      // Optional: Subtle shadow for more depth
      // boxShadow: [
      //   BoxShadow(
      //     color: Colors.black.withOpacity(0.2),
      //     blurRadius: 8,
      //     offset: Offset(0, 4),
      //   ),
      // ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Example: Title + Optional Accent Indicator
        Row(
          children: [
            Expanded(child: title), // Your title widget
            // Only show accent if truly interactive/needs attention
            // Icon(Icons.arrow_forward_ios, color: AppColors.yellow, size: 14),
          ],
        ),
        const SizedBox(height: 8),
        content, // Your main content
      ],
    ),
  ),
)
```
**Guidance**: Prioritize clean standard cards. Use interactive states (`InkWell`) judiciously. Keep borders and shadows very subtle for the minimal aesthetic. Use consistent `borderRadius`.

## Layout & Grid System

### Grid Foundation

HIVE uses an 8-point grid system that combines the best of Material Design and Apple design principles:

- **Base Unit**: 8dp (density-independent pixels)
- **Increments**: All measurements should be multiples of 8 (8, 16, 24, 32, 40, etc.)
- **Half Increments**: For finer details, 4dp increments (4, 12, 20, 28, 36) are acceptable
- **Minimum Touch Target**: 48dp (6 base units)

### Responsive Layout Margins

Content margins adapt based on device size:
- **Mobile**: 16px horizontal margins
- **Tablet**: 24px horizontal margins 
- **Web/Desktop**: 32px horizontal margins

Maintain consistent vertical rhythm using the 8pt grid system regardless of screen size.

### Card System

#### Event Cards
- **Width**: 100% of available width (minus 16dp horizontal margins on mobile).
- **Corner Radius**: 16dp standard.
- **Vertical Padding**: 16dp standard internal padding.
- **Content Structure**:
  - Clear hierarchy: Title (titleLarge), Metadata (caption), Description (bodyLarge/Medium).
  - Actions positioned clearly, often at the bottom, using defined Button styles and meeting 48dp touch target.

#### Space Cards
- **Display Pattern**: Horizontal scrolling carousel
- **Width**: 75% of available width
- **Visibility**: Always show partial next card to indicate scrollability
- **Scroll Physics**: Use `BouncingScrollPhysics()` for iOS-like feel or `ClampingScrollPhysics` for Android feel, ensure smooth performance.

#### Action Positioning
- **Core Principle**: Interactive elements in lower half of cards
- **Primary Actions**: RSVP, Share, Boost
- **Visual Language**: Yellow indicators for primary actions
- **Touch Target**: Minimum 48dp height for all interactive elements

### Navigation Architecture

#### Primary Navigation
- **Bottom Navigation Bar**: Primary student navigation pattern
- **Tab Count**: 4-5 tabs maximum
- **Active Indicator**: Subtle yellow dot *below* the icon, or slightly bolder icon weight + yellow icon color. Avoid large filled backgrounds or harsh underlines.
- **Position**: Fixed at bottom with appropriate safe area insets

#### Secondary Navigation
- **FABs**: For content creation and primary actions
- **Placement**: Lower right, above navigation bar
- **Drawers**: For higher-level creation flows (create space, create event)
- **Sheet Presentation**: Bottom sheets for contextual options

#### Spatial Navigation Model
- **Zones**: Interface organized into persistent spatial zones
- **Motion Design**: Transitions reinforce spatial relationships
- **Navigation Hierarchy**: Clear back path with consistent animations
- **Depth Indicators**: Subtle shadows and elevation changes to indicate hierarchy

Application of spatial navigation principles creates an environment where users develop location memory rather than navigating a flat information hierarchy.

## Glassmorphism & Surface Design (Refined)

### Glass Style (More Precision)

HIVE implements refined glassmorphism with precise details for a premium feel:

- **Blur Effect**: `BackdropFilter` with `ImageFilter.blur`.
  - *Subtle Content Blur (e.g., behind controls):* `sigmaX: 5, sigmaY: 5`
  - *Standard Modal/Sheet Blur:* `sigmaX: 10, sigmaY: 10`
  - *Max Blur (e.g., full screen overlay):* `sigmaX: 15, sigmaY: 15` (Use Sparingly)
- **Surface Tint**: `color: Colors.black.withOpacity(0.15)` to `0.3` within the blurred `Container`. Adjust based on desired brightness and legibility of content *on* the glass.
- **Border Radius**: Consistent `BorderRadius.circular(16)` or `24` for larger surfaces. Match card radius.
- **Edge Definition**: Use a *very subtle* border: `Border.all(color: Colors.white.withOpacity(0.15), width: 0.5)` to catch light and define the shape crisply.
- **Noise Texture (Optional Enhancement)**: For added materiality, overlay a faint noise texture image using `Opacity(opacity: 0.03, child: Image.asset('assets/images/noise.png', fit: BoxFit.cover))`. Ensure the noise pattern is subtle.
- **Shadow**: Use softer, more diffused shadows. Avoid sharp, dark default shadows. See Depth & Elevation System.

```dart
// Refined glass container implementation
Container(
  // Optional: Outer decoration for shadow if needed, separate from ClipRRect
  decoration: BoxDecoration(
     borderRadius: BorderRadius.circular(16), // Match clip radius
     boxShadow: [ // Softer shadow example
       BoxShadow(
         color: Colors.black.withOpacity(0.3), // Adjust opacity
         blurRadius: 30, // Increase blur
         spreadRadius: -10, // Pull shadow inwards slightly
         offset: Offset(0, 10), // Adjust offset
       ),
     ],
  ),
  child: ClipRRect( // Clip the BackdropFilter and content
    borderRadius: BorderRadius.circular(16),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Adjust blur
      child: Container(
        // Tint color ON the glass
        color: Colors.black.withOpacity(0.2), // Adjust opacity for tint
        // Optional: Add border INSIDE the clip for crisp edge
        decoration: BoxDecoration(
           border: Border.all(
             color: Colors.white.withOpacity(0.15),
             width: 0.5,
           ),
           // Need to re-apply radius if border is inside ClipRRect's child
           borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.all(16), // Content padding
        child: content, // Your content on the glass
      ),
    ),
  ),
)
```

### Layer Usage Guidelines

Glass surfaces should be applied strategically to reinforce the spatial UI model:

#### Event Details Modals
- Full-screen glass overlay with 10px blur
- Content slides up from bottom
- Maintains context of underlying content
- Dismissible with downward swipe

#### Messaging Overlays
- Semi-transparent glass surfaces
- Stacked card appearance for threads
- Maintains visual connection to background context
- Message input field uses subtle glass effect

#### HiveLab Inputs
- Form inputs with glass effect
- Subtle background blur (5px)
- Clear focus states with yellow highlight
- Maintains readability of input text

### Surface Hierarchy (Connect to Elevation)

Transparent surfaces simulate a depth-based hierarchy rather than visual weight:

- **Higher Layer = More Blur**: Increase blur radius for elements that appear closer to user
- **Stacking Order**: Overlay elements use stronger blur and shadow
- **Persistent Context**: Background content remains visible but de-emphasized
- **Transition States**: Blur intensity changes during transitions to reinforce spatial model

## Depth & Elevation System (New Section/Refined)

HIVE uses subtle elevation and shadows to create depth, moving away from Material Design's default elevation system towards a more iOS-inspired layered feel.

- **Level 0**: Base background (`#0A0A0A`) - No elevation.
- **Level 1**: Standard Cards, Content Blocks - Minimal or no shadow by default. Can have a very subtle shadow on interaction or if distinction is needed.
  - *Example Shadow (Subtle Lift):* `BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: Offset(0, 2))`
- **Level 2**: Floating Action Buttons, Bottom Navigation Bar - Slightly more pronounced shadow to lift off content.
  - *Example Shadow (Clear Separation):* `BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: Offset(0, 4))`
- **Level 3**: Modals, Dialogs, Sheets (especially Glassmorphism ones) - Softest, most diffused shadow indicating they are closest to the user.
  - *Example Shadow (Soft Depth):* `BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 30, spreadRadius: -5, offset: Offset(0, 10))`

**Guidance**: Use shadows sparingly. Rely more on layout, spacing, and subtle borders/tints for hierarchy. Shadows should feel natural and soft, not harsh lines. Define these shadow styles centrally (e.g., `AppShadows.card`, `AppShadows.modal`).

## Motion & Interaction Design (Refined Curves & Micro-interactions)

### Interaction Patterns (Refined Curves)

| Action                 | Animation Style              | Duration | Curve                 | Haptic Feedback       | Notes                                      |
| ---------------------- | ---------------------------- | -------- | --------------------- | --------------------- | ------------------------------------------ |
| Tap/Press (Button)     | Scale (0.98) + Opacity/Color | 150ms    | `Curves.easeOut`      | Light/Medium Impact   | Quick, responsive feedback                |
| RSVP / Key Action      | Pulse + Color Bloom / Fill   | 300ms    | `Curves.elasticOut` (subtle) | Medium Impact     | More expressive confirmation             |
| Modal/Sheet Open       | Slide-up + Fade/Blur Reveal  | 350ms    | `Curves.easeOutQuint` | None                  | Smooth, decelerating entrance             |
| Modal/Sheet Close      | Slide-down + Fade/Blur Hide  | 250ms    | `Curves.easeInQuad`   | None                  | Quick, accelerating exit                  |
| Tab Switch             | Cross-fade + Subtle Slide    | 250ms    | `Curves.easeInOut`    | Selection Click       | Clean transition between primary sections |
| Card Expand/Collapse   | Size + Fade                  | 300ms    | `Curves.easeInOut`    | Light Impact          | Smooth reveal of more content             |
| Icon State Change      | Cross-fade / Subtle Scale    | 200ms    | `Curves.easeOut`      | None                  | e.g., Like icon fill                      |
| List Item Reorder/Swipe| Slide + Elevation            | 250ms    | `Curves.easeOut`      | Selection Click       | Clear visual cue for manipulation         |

**Guidance**: Use standard Flutter `Curve` values. Ensure animations are performant on target mobile devices. Test thoroughly.

### Animation Implementation

```dart
// RSVP Button Animation
void _animateRsvp() {
  _animationController = AnimationController(
    duration: Duration(milliseconds: 300),
    vsync: this,
  );
  
  _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
    CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ),
  );
  
  _colorAnimation = ColorTween(
    begin: AppColors.black,
    end: AppColors.yellow,
  ).animate(
    CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ),
  );
  
  _animationController.forward().then((_) {
    _animationController.reverse();
  });
}
```

### Feedback Mechanisms

#### Haptic Feedback
- **Light Haptics**: RSVP, post creation, joining
- **Medium Haptics**: Important confirmations
- **Selection Click**: Navigation and selection
- **Success Haptics**: Completion of multistep processes

```dart
// Different haptic patterns for various interactions
void _triggerRsvpHaptic() => HapticFeedback.lightImpact();
void _triggerPostHaptic() => HapticFeedback.lightImpact();
void _triggerJoinHaptic() => HapticFeedback.lightImpact();
void _triggerImportantHaptic() => HapticFeedback.mediumImpact();
void _triggerSelectionHaptic() => HapticFeedback.selectionClick();
void _triggerSuccessHaptic() => HapticFeedback.mediumImpact();
```

#### Visual Affordances
- **Press States**: Clearly defined using `MaterialStateProperty` (scale, opacity, overlay color). Crucial for mobile feedback.
- **Focus States (Less mobile relevant, but good practice)**: Subtle outline or background change for keyboard navigation.
- **Subtle Micro-interactions**:
    - Icon transitions (outline -> fill, slight rotation).
    - Subtle scaling on list item tap.
    - Loading indicators integrated smoothly (e.g., shimmer effect, subtle pulsing accent color).

### Motion Principles

1. **Intentional**: Every animation serves a specific purpose
2. **Cohesive**: Related elements move together
3. **Responsive**: Animations feel tied to physical input
4. **Efficient**: Optimized for device performance
5. **Meaningful**: Reinforces spatial navigation model
6. **Subtle**: Enhances without distracting from content
7. **Performant**: Optimized for smooth 60fps+ on target mobile devices

### Animation Timing Guidelines

- **Short (150-200ms)**: Toggle switches, button presses
- **Medium (250-350ms)**: Page transitions, reveals
- **Long (350-450ms)**: Complex transitions, emphasis animations
- **Sequential**: Stagger related animations by 50-75ms
- **Delay**: Use 20-30ms delays between related animations

## Implementation Checklist

When implementing features according to this aesthetic:

1. **Background Color**
   - Use #0A0A0A as the primary background color
   - Avoid pure black (#000000) backgrounds

2. **Text Hierarchy**
   - Primary text: Pure white (#FFFFFF)
   - Secondary text: Light gray (#BFBFBF)
   - Never use yellow for paragraph text

3. **Yellow Usage**
   - Restrict to interactive elements and attention points
   - Never use as background or for decorative purposes
   - Apply consistently for similar interaction types

4. **Spacing & Rhythm**
   - Maintain consistent 8dp grid system.
   - Use 16dp between major components and for mobile screen horizontal margins.
   - Apply 8dp for internal spacing within components.
   - Enforce 48dp minimum touch targets.

5. **Layer System & Depth**
   - Apply defined elevation levels and subtle shadows consistently.
   - Use refined glassmorphism style for overlays/modals.
   - Ensure layer transitions use appropriate animations and timing.

6. **Typography & Text Styles**
   - Strictly use the defined `AppTextStyles` with correct weights and letter spacing.
   - Ensure sufficient contrast, especially for `secondaryText` and `tertiaryText`.

7. **Interaction Feedback**
   - Implement clear visual press states for all interactive elements.
   - Use haptic feedback consistently according to guidelines.
   - Ensure micro-interactions are subtle and purposeful.

## Special Components

### Signal Strip

The Signal Strip is a horizontally-scrollable component that appears at the top of the feed, providing narrative context and highlighting activity.

#### Usage Guidelines

- **Placement**: Always at the top of the feed, below the app bar
- **Height**: Fixed 125dp height for consistency
- **Scroll Physics**: Use `BouncingScrollPhysics()` for iOS-like feel
- **Card Width**: 280dp for optimal information density
- **Visual Weight**: Use glassmorphism for a premium, lightweight feel
- **Color System**: Each content type has its own distinct color
- **Time Limitation**: Set expiration times for time-sensitive content
- **Prioritization**: Display highest priority content first

```dart
// Standard implementation
SignalStrip(
  height: 125.0,
  padding: const EdgeInsets.symmetric(horizontal: 16.0),
  maxCards: 5,
  showHeader: true,
  useGlassEffect: true,
  glassOpacity: 0.15,
  onCardTap: (content) {
    // Handle tap based on content type
    switch (content.type) {
      case SignalType.lastNight:
        // Navigate to event recap
        break;
      case SignalType.topEvent:
        // Navigate to event details
        break;
      // Handle other types...
    }
  },
)
```

#### Signal Content Types

| Type | Purpose | Color | Icon |
|------|---------|-------|------|
| `lastNight` | Events from previous night | Purple | `nightlife` |
| `topEvent` | Top event happening today | Yellow (Accent) | `event` |
| `trySpace` | Recommended space to try | Blue | `group` |
| `hiveLab` | HiveLab activity teaser | Green | `science` |
| `underratedGem` | Surprising events that gained popularity | Amber | `star` |
| `universityNews` | Official university news | Red | `campaign` |
| `communityUpdate` | Community milestones and stats | Teal | `emoji_events` |

### HiveLab FAB

The HiveLab FAB is a floating action button that provides access to experimental features, feedback mechanisms, and collaborative opportunities.

#### Usage Guidelines

- **Placement**: Lower right corner, above the navigation bar
- **Expansion**: Expands upward when tapped, displaying a menu
- **Color**: Yellow (Accent) in collapsed state, transitions to black when expanded
- **Visual Weight**: Clear separation from background using Level 2 elevation
- **Content Priority**: Display actions by priority (highest first)
- **Verification Status**: Indicate which actions require Verified+ status

```dart
// Standard implementation
HiveLabFAB(
  onActionSelected: (action) {
    // Handle the selected action
    switch (action.type) {
      case HiveLabActionType.ideaSubmission:
        // Navigate to idea submission page
        break;
      case HiveLabActionType.feedback:
        // Show feedback form
        break;
      // Handle other action types...
    }
  },
  initialMode: HiveLabFABMode.collapsed,
  hidePreferredActions: false,
  maxActions: 4,
  elevated: true,
)
```

#### Menu Visual Style

- **Background**: Semi-transparent glass effect (10px blur)
- **Border**: Subtle white border (15% opacity, 0.5 width)
- **Header**: "HiveLab" label in accent yellow
- **Width**: Fixed 280dp width for menu panel
- **Spacing**: 12dp vertical padding between action items
- **Icons**: Colored icons to distinguish action types
- **V+ Indicator**: Small gold badge for premium actions

#### Animation Guidelines

- **Open**: 350ms duration, `Curves.easeOutQuint` curve
- **Close**: 250ms duration, `Curves.easeInQuad` curve 
- **Haptic**: Selection click on open/close, medium impact on action selection
- **Transition**: Fade + slide up for menu items
- **Icon**: Smooth transition from lab to close icon
