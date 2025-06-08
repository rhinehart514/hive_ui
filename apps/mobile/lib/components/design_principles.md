# HIVE Component Design Principles

These four principles govern every component in the HIVE system. Every component must pass the principle compliance test before implementation.

## 🎯 Principle 1: Campus-first minimalism

**Every surface is slate-dark or paper-white so real student photos, events, and rituals supply the color. If a screen feels empty, we fix the content loop—not the chrome.**

### Component Guidelines:
- Use translucent backgrounds (`Colors.white.withOpacity(0.06)`) to let real content show through
- Avoid decorative elements that don't serve a functional purpose
- If a component feels "empty", add real campus data, not more UI elements
- Dark surfaces (#0D0D0D, #1E1E1E) should act as canvas for colorful content

### Examples:
```dart
// ✅ DO: Translucent backdrop for real content
Container(
  color: Colors.white.withOpacity(0.06), // Minimal backdrop
  child: StudentPhotoGrid(), // Real content provides color
)

// ❌ DON'T: Decorative gradients that compete with content
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(...), // Competes with student content
  ),
)
```

## ⚡ Principle 2: Living momentum

**Motion ≫ hue. Metrics, votes, and live counters weight-pulse or glide before they ever turn gold. Students should feel campus energy tick upward in the corner of their eye.**

### Component Guidelines:
- Use subtle animations (weight-pulse, glide) to create peripheral energy
- Animate metrics and counters to show live campus activity
- Physics-based curves over linear tweens
- Motion should communicate state and energy, not just decoration

### Animation Tokens:
```dart
// Weight-pulse animation (800ms cycle)
AnimationController _pulseController = AnimationController(
  duration: const Duration(milliseconds: 800),
  vsync: this,
);

// Glide animation for live updates
Curves.easeOutCubic // Physics-based, not linear
```

### Examples:
```dart
// ✅ DO: Pulse animation for live energy
AnimatedBuilder(
  animation: _pulseAnimation,
  builder: (context, child) => Transform.scale(
    scale: _pulseAnimation.value, // 0.8 to 1.0 scale
    child: LiveCounterWidget(),
  ),
)

// ❌ DON'T: Static counters
Text('42 students online') // No sense of live energy
```

## 🍯 Principle 3: Honey-drop restraint

**#FFD700 ("nectar/prime") is sacred. Max three concurrent fills. When gold appears, it signals either (a) take action now or (b) celebrate a win. Everything else downgrades to pulse-blue or stays neutral.**

### Component Guidelines:
- Gold (#FFD700) only for:
  - "Take action now" moments (selected states, primary CTAs)
  - "Celebrate a win" moments (success states, achievements)
- Maximum 3 concurrent gold elements on screen
- Use pulse-blue (#56CCF2) for hover states and secondary interactions
- Use neutral colors for everything else

### Color Tokens:
```dart
static const Color goldAccent = Color(0xFFFFD700); // Sacred - use sparingly
static const Color pulseBlue = Color(0xFF56CCF2);  // Hover states
static const Color neutralBorder = Colors.white;   // Default interactions
```

### Examples:
```dart
// ✅ DO: Gold only for "take action now"
Container(
  color: isSelected ? goldAccent.withOpacity(0.15) : Colors.transparent,
  // Gold appears when user can take action
)

// ✅ DO: Pulse-blue for hover states
border: Border.all(
  color: isHovering ? pulseBlue.withOpacity(0.8) : neutralBorder.withOpacity(0.1),
)

// ❌ DON'T: Gold for decoration or passive states
Icon(Icons.star, color: goldAccent) // Not an action or win moment
```

## 🔧 Principle 4: Builder-first modularity

**Every component can be dragged, re-skinned, or forked by a student Builder without breaking brand. That means one token sheet, one spacing grid, one elevation ramp—no exceptions.**

### Component Guidelines:
- Use centralized design tokens instead of hardcoded values
- Make everything customizable via props
- Consistent spacing grid (4pt base unit)
- Unified elevation system (e0, e1, e2, e3, e4)
- Components should work independently and compose together

### Design Tokens:
```dart
// Spacing tokens (4pt base grid)
static const double space1 = 4.0;   // 1 unit
static const double space2 = 8.0;   // 2 units  
static const double space4 = 16.0;  // 4 units
static const double space6 = 24.0;  // 6 units

// Border radius tokens
static const double radiusSm = 4.0;    // Small
static const double radiusMd = 8.0;    // Medium  
static const double radiusLg = 12.0;   // Large
static const double radiusXl = 24.0;   // Button radius

// Elevation tokens
static const List<BoxShadow> elevation1 = [...]; // e1
static const List<BoxShadow> elevation2 = [...]; // e2
```

### Examples:
```dart
// ✅ DO: Use design tokens
Container(
  padding: EdgeInsets.all(DesignTokens.space4), // Token-based
  borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
  boxShadow: DesignTokens.elevation2,
)

// ✅ DO: Make everything customizable
class HiveCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor; // Customizable by Builders
  final double? borderRadius;   // Customizable by Builders
  final List<BoxShadow>? elevation; // Customizable by Builders
  
  const HiveCard({
    required this.child,
    this.backgroundColor,
    this.borderRadius,
    this.elevation,
  });
}

// ❌ DON'T: Hardcode values
Container(
  padding: EdgeInsets.all(16), // Should use token
  borderRadius: BorderRadius.circular(12), // Should use token
)
```

## 🔍 Principle Compliance Checklist

Before implementing any component, verify it passes all four principles:

### Campus-first minimalism:
- [ ] Uses translucent or minimal backgrounds
- [ ] Doesn't compete with real student content
- [ ] No unnecessary decorative elements
- [ ] Serves as canvas for colorful campus data

### Living momentum:
- [ ] Includes subtle motion that feels alive
- [ ] Uses physics-based animation curves
- [ ] Shows live energy in peripheral vision
- [ ] Motion serves a purpose (not decoration)

### Honey-drop restraint:
- [ ] Gold (#FFD700) only for "take action" or "celebrate win"
- [ ] Maximum 3 concurrent gold elements
- [ ] Uses pulse-blue (#56CCF2) for hover states
- [ ] Neutral colors for everything else

### Builder-first modularity:
- [ ] Uses centralized design tokens
- [ ] Fully customizable via props
- [ ] Follows unified spacing grid
- [ ] Works independently and composes well
- [ ] Can be modified without breaking brand

## Component Examples by Principle

### Perfect Principle Compliance: PredictiveSearchInput
- **Campus-first**: Translucent backdrop highlights campus search terms
- **Living momentum**: Pulse animation on search icon, shimmer on results
- **Honey-drop restraint**: Gold only on selected result (take action), pulse-blue for hover
- **Builder-first**: Token-based spacing, customizable via props

### Principle Violations to Avoid:
- Using gold for decorative purposes (violates honey-drop restraint)
- Static components with no sense of live energy (violates living momentum)
- Hardcoded spacing/colors (violates builder-first modularity)
- Heavy backgrounds that compete with content (violates campus-first minimalism)

These principles ensure every HIVE component feels cohesive, purposeful, and builder-friendly while maintaining the sophisticated dark infrastructure aesthetic. 