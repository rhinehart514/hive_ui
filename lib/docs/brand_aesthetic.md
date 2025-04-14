# HIVE Brand Aesthetic Guide

## Core Principles

HIVE's aesthetic serves its behavioral-first approach to campus life. The interface is designed not just to be visually appealing, but to facilitate specific behavioral patterns and user journeys through the five system layers.

### Behavioral-First Design

All visual elements support HIVE's core behavioral patterns:
- **Discover**: Visual cues that encourage exploration and discovery
- **Affiliate**: Clear visual language for joining and identifying with Spaces
- **Participate**: Lightweight interaction points with immediate visual feedback
- **Create**: Intuitive creation flows with minimal friction
- **Profile**: Personal identity markers that evolve with engagement

### Dynamic & Responsive

The interface responds to user behavior, adapting based on:
- User's role (Seeker, Reactor, Joiner, Builder, etc.)
- Affiliation tier with Spaces (Observer, Member, Active, etc.)
- Time-sensitive content states (Cold, Warming, Hot/Pulse, Cooling)
- Trail data and interaction history

## Core Color Palette

```dart
// Primary colors
static const Color black = Color(0xFF0A0A0A); // Primary background (deep, near-black)
static const Color white = Color(0xFFFFFFFF); // Primary text & bright accents
static const Color secondaryText = Color(0xFFBFBFBF); // Secondary text (80% white on black)
static const Color tertiaryText = Color(0xFF808080); // Tertiary text (50% white on black, for metadata)
static const Color yellow = Color(0xFFFFD700); // Interactive accent color, signals intent
static const Color gold = Color(0xFFFFD700); // Alias for yellow

// System Colors (Used for specific behavioral patterns)
static const Color pulseHot = Color(0xFFE53935); // Trending content indicator
static const Color activeState = Color(0xFF0ECB81); // Active/live state indicator
static const Color attentionState = Color(0xFFFFB74D); // Needs attention indicator
```

## Design Principles

### 1. Behavioral Signal Clarity

All interface elements support the behavioral system architecture:

- **Signal Types**: Visual distinction between Signal types (affiliation, expression, alignment)
- **State Indicators**: Clear visual markers for content states (cold, warming, pulse)
- **Role Visualization**: Subtle visual cues based on user role (Builder badge, etc.)
- **Motion Sensitivity**: Interface elements respond to the emergent motion of Spaces and content

Implementation guidelines:
- Use consistent visual language for each Signal type across the system
- Animation and interaction design reflects the energy state of content
- Time-sensitive visual cues degrade naturally as states change
- Color accents and highlights map to behavioral significance

### 2. Yellow as a Cognitive Signal

Yellow (#FFD700) serves as an intention-focused interactive signal:

- **Never Decorative**: Yellow is reserved for interactive elements requiring attention
- **Decision Points**: Used exclusively for elements requiring student decisions
- **Specific Applications**:
  - RSVP buttons and confirmations
  - "Hot" Pulse state indicators
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

## Typography System

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

### Button System (By Behavioral Intent)

Buttons are styled based on their behavioral role in the system:

```dart
// Signal Button (Primary action that creates a Signal in the system)
ElevatedButton(
  onPressed: () {
    HapticFeedback.mediumImpact();
    // Action that generates a Signal (e.g., RSVP, Join, Repost)
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
  child: Text('RSVP', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
)

// Affiliation Button (Space joining, group actions)
OutlinedButton(
  onPressed: () {
    HapticFeedback.lightImpact(); // Lighter haptic
    // Action related to affiliation with a Space
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
  child: Text('Join Space', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
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

### Card System (By Content Type)

HIVE uses specialized cards for different content types, each supporting specific behavioral patterns:

#### Event Cards

```dart
// Standard Event Card
Container(
  padding: const EdgeInsets.all(16), // Consistent internal padding
  decoration: BoxDecoration(
    color: const Color(0xFF1C1C1E), // Slightly lighter than pure black
    borderRadius: BorderRadius.circular(16), // More rounded corners
    border: Border.all(
      color: Colors.white.withOpacity(0.1), // Fainter border
      width: 0.5,
    ),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Title Section
      Text('Event Title', style: AppTextStyles.titleLarge),
      const SizedBox(height: 4),
      
      // Metadata Row (Time, Location)
      Row(
        children: [
          Icon(Icons.access_time, size: 12, color: AppColors.tertiaryText),
          const SizedBox(width: 4),
          Text('8:00 PM', style: AppTextStyles.caption),
          const SizedBox(width: 16),
          Icon(Icons.location_on, size: 12, color: AppColors.tertiaryText),
          const SizedBox(width: 4),
          Text('Student Center', style: AppTextStyles.caption),
        ],
      ),
      const SizedBox(height: 8),
      
      // Host Information (Optional)
      Text('Hosted by Computer Science Club', style: AppTextStyles.bodyMedium),
      const SizedBox(height: 12),
      
      // Description (Optional, can be expandable)
      Text('Event description text goes here...', style: AppTextStyles.bodyLarge),
      const SizedBox(height: 16),
      
      // Action Row (RSVP, Share, etc)
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              // RSVP action
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.yellow,
              foregroundColor: AppColors.black,
              // Button styling...
            ),
            child: Text('RSVP', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
          IconButton(
            icon: Icon(Icons.share, color: AppColors.secondaryText),
            onPressed: () {
              // Share action
     HapticFeedback.lightImpact();
            },
          ),
        ],
      ),
      
      // Social Proof (Optional, based on behavioral data)
      if (showSocialProof) Text('3 friends are going', style: AppTextStyles.caption),
    ],
  ),
)
```

#### Space Cards

```dart
// Space Card (For horizontal carousel)
Container(
  width: MediaQuery.of(context).size.width * 0.75, // 75% of screen width
  margin: const EdgeInsets.only(right: 12), // Margin for carousel spacing
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF1C1C1E),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.white.withOpacity(0.1),
        width: 0.5,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      // Space Header with Avatar + Name
        Row(
          children: [
          // Space Avatar or Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.tertiaryText,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text('CS', style: AppTextStyles.titleLarge),
            ),
          ),
          const SizedBox(width: 12),
          // Space Name + Member Count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CS Club', style: AppTextStyles.titleLarge),
                Text('124 members', style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      
      // Tags Row
      Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('tech', style: AppTextStyles.caption),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('coding', style: AppTextStyles.caption),
          ),
        ],
      ),
      const SizedBox(height: 16),
      
      // Join Button or Member Status
      OutlinedButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          // Join Space action
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.white,
          // Button styling...
        ),
        child: Text('Join Space', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
      ),
    ],
  ),
)
```

#### Drop Cards (1-line posts)

```dart
// Drop Card (1-line post inside a Space)
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: const Color(0xFF1C1C1E),
    borderRadius: BorderRadius.circular(16),
           border: Border.all(
      color: Colors.white.withOpacity(0.1),
             width: 0.5,
           ),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Author Row
      Row(
        children: [
          // Author Avatar
          CircleAvatar(radius: 16),
          const SizedBox(width: 8),
          // Author Name + Timestamp
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Jane Doe', style: AppTextStyles.bodyMedium),
              Text('10m ago', style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
      const SizedBox(height: 12),
      
      // Drop Content (1-line post)
      Text('Movie night at the dorm tonight. Who\'s coming?', style: AppTextStyles.bodyLarge),
      const SizedBox(height: 12),
      
      // Action Row
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // "Going?" action for event promotion
          TextButton.icon(
            icon: Icon(Icons.event, size: 16, color: AppColors.yellow),
            label: Text('Going?', style: AppTextStyles.labelMedium),
            onPressed: () {
              HapticFeedback.lightImpact();
              // Convert to event action
            },
          ),
          
          // Repost action
          IconButton(
            icon: Icon(Icons.repeat, color: AppColors.secondaryText),
            onPressed: () {
              HapticFeedback.lightImpact();
              // Repost action
            },
          ),
        ],
      ),
    ],
  ),
)
```

## Feed Strip System

The Feed Strip is a key UI component supporting the Discovery layer:

```dart
// Feed Strip Container
Container(
  height: 125.0,
  child: ListView(
    scrollDirection: Axis.horizontal,
    physics: BouncingScrollPhysics(),
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    children: [
      // Space Heat Strip Card
      _buildStripCard(
        title: 'CS Club is on fire 🔥',
        subtitle: '14 new members in the past hour',
        color: AppColors.pulseHot.withOpacity(0.2),
        icon: Icons.whatshot,
        iconColor: AppColors.pulseHot,
      ),
      
      // Ritual Launch Strip Card
      _buildStripCard(
        title: 'Weekly Photo Challenge',
        subtitle: 'Post your best campus shot',
        color: Colors.purple.withOpacity(0.2),
        icon: Icons.camera_alt,
        iconColor: Colors.purple,
      ),
      
      // Time Marker Strip Card
      _buildStripCard(
        title: 'Last Night on Campus',
        subtitle: '3 events you might have missed',
        color: Colors.blue.withOpacity(0.2),
        icon: Icons.nightlife,
        iconColor: Colors.blue,
      ),
      
      // Motion Recap Strip Card
      _buildStripCard(
        title: 'Your Friends Are Moving',
        subtitle: 'See what 5 friends are up to',
        color: Colors.green.withOpacity(0.2),
        icon: Icons.people,
        iconColor: Colors.green,
      ),
    ],
  ),
)

// Strip Card Builder
Widget _buildStripCard({
  required String title,
  required String subtitle,
  required Color color,
  required IconData icon,
  required Color iconColor,
}) {
  return Container(
    width: 280,
    margin: const EdgeInsets.only(right: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.white.withOpacity(0.1),
        width: 0.5,
      ),
    ),
    child: Row(
      children: [
        // Icon Container
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor),
        ),
        const SizedBox(width: 16),
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: AppTextStyles.titleLarge),
              const SizedBox(height: 4),
              Text(subtitle, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ],
    ),
  );
}
```

## State Visualization

### Pulse States

```dart
// Visual indicators for different Pulse states
Widget getPulseIndicator(PulseState state) {
  switch (state) {
    case PulseState.cold:
      return Container(); // No visual indicator for cold state
      
    case PulseState.warming:
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.trending_up, color: Colors.orange, size: 12),
            const SizedBox(width: 4),
            Text('Trending', style: AppTextStyles.caption.copyWith(color: Colors.orange)),
          ],
        ),
      );
      
    case PulseState.hot:
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.pulseHot.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department, color: AppColors.pulseHot, size: 12),
            const SizedBox(width: 4),
            Text('Hot', style: AppTextStyles.caption.copyWith(color: AppColors.pulseHot)),
          ],
        ),
      );
      
    case PulseState.cooling:
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.whatshot, color: Colors.blue, size: 12),
            const SizedBox(width: 4),
            Text('Popular', style: AppTextStyles.caption.copyWith(color: Colors.blue)),
          ],
        ),
      );
      
    default:
      return Container();
  }
}
```

### Space States

```dart
// Visual indicators for different Space states
Widget getSpaceStateIndicator(SpaceState state) {
  switch (state) {
    case SpaceState.seeded:
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.grass, color: Colors.green, size: 12),
          const SizedBox(width: 4),
          Text('New', style: AppTextStyles.caption.copyWith(color: Colors.green)),
        ],
      );
      
    case SpaceState.forming:
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.group_add, color: Colors.blue, size: 12),
          const SizedBox(width: 4),
          Text('Growing', style: AppTextStyles.caption.copyWith(color: Colors.blue)),
        ],
      );
      
    case SpaceState.live:
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, color: AppColors.yellow, size: 12),
          const SizedBox(width: 4),
          Text('Active', style: AppTextStyles.caption.copyWith(color: AppColors.yellow)),
        ],
      );
      
    case SpaceState.dormant:
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.nights_stay, color: AppColors.tertiaryText, size: 12),
          const SizedBox(width: 4),
          Text('Quiet', style: AppTextStyles.caption),
        ],
      );
      
    default:
      return Container();
  }
}
```

## Motion & Interaction Design

HIVE uses animation to communicate the behavioral nature of content:

### Motion Patterns by Behavior

| Behavior | Animation Pattern | Purpose |
|----------|-------------------|---------|
| Signal Creation | Quick pulse + confirmation | Shows the user their micro-signal is registered |
| Space Joining | Soft slide + scale | Reflects the lightweight nature of affiliation |
| Pulse Detection | Growing pulse waves | Visualizes how content is gathering energy |
| Content Decay | Subtle fade + desaturation | Shows natural lifecycle of content |
| Trail Recording | Micro-animations after actions | Indicates the system is building memory |

```dart
// RSVP Signal Animation Example
void _animateRsvpSignal() {
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

### Interaction Timing Guide

| System Layer | Action | Timing | Curve | Haptic |
|--------------|--------|--------|-------|--------|
| Discovery | Feed scroll | 300ms deceleration | `Curves.easeOutQuint` | None |
| Discovery | Card expand | 250ms | `Curves.easeOutCubic` | Light |
| Affiliation | Join Space | 350ms | `Curves.elasticOut` (subtle) | Medium |
| Participation | RSVP | 300ms | `Curves.easeOutCubic` | Medium |
| Participation | Drop post | 400ms | `Curves.easeOutQuint` | Medium |
| Creation | Sheet open | 350ms | `Curves.easeOutQuint` | Light |
| Profile | Tab switch | 250ms | `Curves.easeInOut` | Selection |

## Accessibility Guidelines

### Color Contrast

- Minimum 4.5:1 contrast ratio for text over backgrounds
- All interactive elements have clear visual indicators beyond color
- Primary actions maintain 3:1 contrast minimum

### Interactive Element Considerations

- 48dp minimum touch target size for all interactive elements
- Clear press states (visual + haptic) for all controls
- Avoid touch-and-hold actions for primary functions
- Label all interactive elements with accessibility hints

### Text Scaling

- All text scales appropriately with system font size settings
- Interface layout accommodates larger text without breaking
- Minimum body text size of 14dp regardless of content density needs

## Implementation Checklist

When developing features according to HIVE's behavioral design approach:

1. **Identify the Behavioral Pattern**
   - Which system layer does this feature belong to?
   - What behavioral signals does it enable users to create?
   - How does it reflect or display user signals?

2. **Select Appropriate Visual Components**
   - Use consistent card styles based on content type
   - Apply state visualizations based on system states
   - Maintain 8dp grid spacing system

3. **Implement Interaction Feedback**
   - Add appropriate animations based on the behavior
   - Include haptic feedback for key interactions
   - Ensure visual states reflect system states

4. **Test Accessibility & Performance**
   - Verify all text meets contrast guidelines
   - Ensure all touch targets meet size requirements
   - Optimize animations for 60fps performance on target devices

5. **Validate Behavioral Alignment**
   - Does the UI clearly communicate the user's current state?
   - Are behavioral signals clearly differentiated?
   - Does the interface adapt based on user role and behavior?

Consistent application of these guidelines ensures HIVE's interface isn't just visually appealing, but actually reinforces the behavioral patterns at the core of the platform.
