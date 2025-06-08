# HIVE Design System — Modular vBETA‑Web

**One elastic language that scales infinitely.**

A comprehensive, token-first design system built for infinite scalability across web, iOS, and Android platforms. Currently optimized for the HIVE web experience with full light/dark mode support.

## 🎨 Architecture Overview

```
┌── design-tokens/           # Single JSON source of truth
│   ├── colors.json          # Semantic + functional color tiers
│   ├── typography.json      # Fluid typography with clamp()
│   └── motion.json          # Physics-based timing + easing
├── styles/                  # Generated CSS variables
├── components/ui/           # Primitive components (shadcn/ui)
├── components/patterns/     # Composed molecule components
└── app/                     # Next.js pages using the system
```

## ✨ Key Features

### Token-First Architecture
- **JSON-driven design tokens** → Style Dictionary → CSS variables
- **Instant theme switching** between light and dark modes
- **Semantic color system** that adapts automatically
- **Physics-based animations** with standardized timing

### Infinite Scalability
- Add new tokens → all components update automatically
- Consistent visual language across unlimited platforms
- Type-safe component API with full intellisense
- Built on industry-standard foundations (Radix + shadcn/ui)

### HIVE Brand Compliance
- **Sophisticated dark infrastructure** aesthetic (#0D0D0D background)
- **Sacred gold accent** (#FFD700) used sparingly for focus + triggers
- **Premium material system** with proper depth and texture
- **Apple-inspired interactions** with haptic-like feedback

## 🧩 Component Architecture

### Primitives (shadcn/ui + HIVE tokens)
Ready-to-use base components with HIVE styling:

- **Button** - 6 variants (primary, secondary, accent, ghost, text, destructive)
- **Card** - Interactive cards with elevation system
- **Badge** - Semantic badges with consistent meaning
- **Input** - Form inputs with proper focus states
- **Avatar** - User profile pictures with fallbacks
- **Tabs** - Navigation with sliding indicators

### Patterns (Composed molecules)
Complex components built from primitives for specific HIVE use cases:

#### `ToolCard`
For HiveLAB student-created tools and apps
```tsx
<ToolCard
  title="Quick Poll"
  description="Create instant polls for your Space members"
  category="Engagement"
  author="@sarah_builds"
  usageCount={142}
  isLive={true}
  onUse={() => handleToolUse()}
  onFork={() => handleToolFork()}
/>
```

#### `EventCard`
For campus events, study sessions, and activities
```tsx
<EventCard
  title="CS Study Session"
  description="Group study for algorithms exam"
  location="Library Study Room 204"
  date="Today"
  time="7:00 PM"
  organizer="Computer Science Club"
  attendeeCount={12}
  maxAttendees={15}
  tags={["Study", "CS", "Algorithms"]}
  onRSVP={() => handleRSVP()}
/>
```

#### `UserProfile`
For student profiles with builder status and stats
```tsx
<UserProfile
  name="Sarah Chen"
  username="sarah_builds"
  major="Computer Science"
  year="Junior"
  isBuilder={true}
  builderLevel="Gold"
  toolsCreated={12}
  spacesJoined={8}
  eventsAttended={24}
  onViewProfile={() => handleProfileView()}
/>
```

#### `FeedItem`
For social posts and interactions
```tsx
<FeedItem
  author={{
    name: "Sarah Chen",
    username: "sarah_builds",
    isBuilder: true,
    builderLevel: "Gold"
  }}
  content="Just launched a new study coordination tool! 🚀"
  timestamp="2 hours ago"
  spaceContext={{ name: "CS Students", type: "Academic" }}
  interactions={{ likes: 24, comments: 8, shares: 3 }}
  isLiked={true}
  onLike={() => handleLike()}
/>
```

#### `SpaceCard`
For campus communities and spaces
```tsx
<SpaceCard
  name="Computer Science Hub"
  description="Connect with CS students, share resources..."
  category="Academic"
  memberCount={234}
  onlineCount={18}
  isJoined={true}
  recentActivity={{
    type: 'post',
    description: 'Sarah shared a new study guide',
    timeAgo: '2 hours ago'
  }}
  tags={["Programming", "Study Groups"]}
  onJoin={() => handleJoin()}
/>
```

## 🎯 Design Tokens

### Color System
Semantic colors that automatically adapt to light/dark themes:

```css
/* Surface layers */
--surface-0: #0D0D0D / #FFFFFF
--surface-1: #181818 / #F7F7F7  
--surface-2: #242424 / #E9E9E9

/* Text hierarchy */
--text-primary: #FAFAFA / #0A0A0A
--text-secondary: #B3B3B3 / #5E5E5E

/* Brand & semantic */
--brand-gold-500: #FFD700 (sacred accent)
--success-500: #8CE563
--warning-500: #FF9500
--error-500: #FF3B30
```

### Typography Scale
Fluid typography using clamp() for responsive scaling:

```css
--font-display: clamp(2.5rem, 4vw, 3.5rem)
--font-h1: clamp(1.75rem, 3vw, 2.25rem)
--font-h2: clamp(1.5rem, 2.5vw, 1.875rem)
--font-h3: clamp(1.25rem, 2vw, 1.5rem)
--font-body: clamp(1rem, 1.5vw, 1.125rem)
--font-caption: clamp(0.875rem, 1vw, 1rem)
```

### Motion System
Physics-based timing for consistent animations:

```css
--duration-micro: 150ms     /* Hover, ripple */
--duration-standard: 250ms  /* Lists, navigation */
--duration-expansion: 450ms /* FAB to Sheet */
--duration-bounce: 600ms    /* Success feedback */

/* Easing curves */
--ease-tap-feedback: cubic-bezier(0.4, 0, 1, 1)
--ease-standard: cubic-bezier(0.4, 0, 0.2, 1)
--ease-bounce: cubic-bezier(0.68, -0.55, 0.265, 1.55)
```

## 🚀 Usage

### Quick Start
```tsx
import { ThemeProvider } from "@/components/ui/theme-provider";
import { Button } from "@/components/ui/button";
import { ToolCard } from "@/components/patterns";

function App() {
  return (
    <ThemeProvider defaultTheme="dark">
      <div className="min-h-screen bg-surface-0 text-text-primary">
        <Button variant="accent">Sacred Gold Accent</Button>
        <ToolCard {...toolProps} />
      </div>
    </ThemeProvider>
  );
}
```

### Theme Switching
```tsx
import { ThemeToggle } from "@/components/ui/theme-toggle";

// Instant toggle between light/dark
<ThemeToggle />

// Dropdown with system option
<ThemeDropdown />
```

### Adding New Tokens
1. Update JSON files in `design-tokens/`
2. Run `npm run tokens:build` to regenerate CSS
3. Use new tokens in components automatically

## 🔧 Development

### Testing Components
Visit `/test-design-system` to see all components with live theme switching.

### File Structure
```
apps/web/
├── design-tokens/
│   ├── colors.json
│   ├── typography.json
│   └── motion.json
├── styles/
│   ├── tokens.css         # Generated dark mode
│   ├── tokens-light.css   # Generated light mode
│   └── globals.css        # Base imports
├── components/
│   ├── ui/               # Primitives
│   └── patterns/         # Molecules
└── app/
    ├── test-design-system/  # Testing environment
    └── globals.css          # Theme imports
```

### Commands
```bash
npm run tokens:build    # Regenerate CSS from JSON
npm run dev            # Start development server
npm run build          # Production build
```

## 📏 Standards

### Component Requirements
- **TypeScript** - Full type safety with proper interfaces
- **Accessibility** - Proper ARIA labels, focus management
- **Performance** - Optimized animations, minimal rerenders  
- **Consistency** - Use design tokens, follow naming conventions
- **Responsiveness** - Mobile-first, proper touch targets

### Animation Guidelines
- Use token-based durations and easing
- Target 60fps for all interactions
- Provide reduced motion fallbacks
- Animations should convey meaning, not decoration

### Color Usage Rules
- **#FFD700 gold is sacred** - only for focus rings, live status, key triggers
- Use semantic tokens, never hardcoded colors
- Ensure 4.5:1 contrast ratio minimum
- Test in both light and dark modes

## 🔮 Future Roadmap

### Phase 2: Enhanced Patterns
- **Navigation components** (sidebar, mobile nav)
- **Data visualization** patterns  
- **Form validation** system
- **Loading states** and skeletons

### Phase 3: Advanced Features
- **Storybook documentation** for component library
- **Framer Motion integration** with motion tokens
- **Design system linting** rules
- **Cross-platform token export** (iOS/Android)

### Phase 4: Ecosystem
- **Component playground** for rapid prototyping
- **Design-to-code pipeline** automation
- **Usage analytics** and optimization
- **Community contribution** guidelines

---

**Built with love for the HIVE community.** 🐝

The design system embodies HIVE's core philosophy: sophisticated infrastructure that enables students to build and connect without constraints. Every component, token, and interaction is crafted to scale from a single student's web dashboard to enterprise-level experiences — all while maintaining the premium, physics-based feel that defines the HIVE aesthetic. 

**One elastic language that scales infinitely.**

A comprehensive, token-first design system built for infinite scalability across web, iOS, and Android platforms. Currently optimized for the HIVE web experience with full light/dark mode support.

## 🎨 Architecture Overview

```
┌── design-tokens/           # Single JSON source of truth
│   ├── colors.json          # Semantic + functional color tiers
│   ├── typography.json      # Fluid typography with clamp()
│   └── motion.json          # Physics-based timing + easing
├── styles/                  # Generated CSS variables
├── components/ui/           # Primitive components (shadcn/ui)
├── components/patterns/     # Composed molecule components
└── app/                     # Next.js pages using the system
```

## ✨ Key Features

### Token-First Architecture
- **JSON-driven design tokens** → Style Dictionary → CSS variables
- **Instant theme switching** between light and dark modes
- **Semantic color system** that adapts automatically
- **Physics-based animations** with standardized timing

### Infinite Scalability
- Add new tokens → all components update automatically
- Consistent visual language across unlimited platforms
- Type-safe component API with full intellisense
- Built on industry-standard foundations (Radix + shadcn/ui)

### HIVE Brand Compliance
- **Sophisticated dark infrastructure** aesthetic (#0D0D0D background)
- **Sacred gold accent** (#FFD700) used sparingly for focus + triggers
- **Premium material system** with proper depth and texture
- **Apple-inspired interactions** with haptic-like feedback

## 🧩 Component Architecture

### Primitives (shadcn/ui + HIVE tokens)
Ready-to-use base components with HIVE styling:

- **Button** - 6 variants (primary, secondary, accent, ghost, text, destructive)
- **Card** - Interactive cards with elevation system
- **Badge** - Semantic badges with consistent meaning
- **Input** - Form inputs with proper focus states
- **Avatar** - User profile pictures with fallbacks
- **Tabs** - Navigation with sliding indicators

### Patterns (Composed molecules)
Complex components built from primitives for specific HIVE use cases:

#### `ToolCard`
For HiveLAB student-created tools and apps
```tsx
<ToolCard
  title="Quick Poll"
  description="Create instant polls for your Space members"
  category="Engagement"
  author="@sarah_builds"
  usageCount={142}
  isLive={true}
  onUse={() => handleToolUse()}
  onFork={() => handleToolFork()}
/>
```

#### `EventCard`
For campus events, study sessions, and activities
```tsx
<EventCard
  title="CS Study Session"
  description="Group study for algorithms exam"
  location="Library Study Room 204"
  date="Today"
  time="7:00 PM"
  organizer="Computer Science Club"
  attendeeCount={12}
  maxAttendees={15}
  tags={["Study", "CS", "Algorithms"]}
  onRSVP={() => handleRSVP()}
/>
```

#### `UserProfile`
For student profiles with builder status and stats
```tsx
<UserProfile
  name="Sarah Chen"
  username="sarah_builds"
  major="Computer Science"
  year="Junior"
  isBuilder={true}
  builderLevel="Gold"
  toolsCreated={12}
  spacesJoined={8}
  eventsAttended={24}
  onViewProfile={() => handleProfileView()}
/>
```

#### `FeedItem`
For social posts and interactions
```tsx
<FeedItem
  author={{
    name: "Sarah Chen",
    username: "sarah_builds",
    isBuilder: true,
    builderLevel: "Gold"
  }}
  content="Just launched a new study coordination tool! 🚀"
  timestamp="2 hours ago"
  spaceContext={{ name: "CS Students", type: "Academic" }}
  interactions={{ likes: 24, comments: 8, shares: 3 }}
  isLiked={true}
  onLike={() => handleLike()}
/>
```

#### `SpaceCard`
For campus communities and spaces
```tsx
<SpaceCard
  name="Computer Science Hub"
  description="Connect with CS students, share resources..."
  category="Academic"
  memberCount={234}
  onlineCount={18}
  isJoined={true}
  recentActivity={{
    type: 'post',
    description: 'Sarah shared a new study guide',
    timeAgo: '2 hours ago'
  }}
  tags={["Programming", "Study Groups"]}
  onJoin={() => handleJoin()}
/>
```

## 🎯 Design Tokens

### Color System
Semantic colors that automatically adapt to light/dark themes:

```css
/* Surface layers */
--surface-0: #0D0D0D / #FFFFFF
--surface-1: #181818 / #F7F7F7  
--surface-2: #242424 / #E9E9E9

/* Text hierarchy */
--text-primary: #FAFAFA / #0A0A0A
--text-secondary: #B3B3B3 / #5E5E5E

/* Brand & semantic */
--brand-gold-500: #FFD700 (sacred accent)
--success-500: #8CE563
--warning-500: #FF9500
--error-500: #FF3B30
```

### Typography Scale
Fluid typography using clamp() for responsive scaling:

```css
--font-display: clamp(2.5rem, 4vw, 3.5rem)
--font-h1: clamp(1.75rem, 3vw, 2.25rem)
--font-h2: clamp(1.5rem, 2.5vw, 1.875rem)
--font-h3: clamp(1.25rem, 2vw, 1.5rem)
--font-body: clamp(1rem, 1.5vw, 1.125rem)
--font-caption: clamp(0.875rem, 1vw, 1rem)
```

### Motion System
Physics-based timing for consistent animations:

```css
--duration-micro: 150ms     /* Hover, ripple */
--duration-standard: 250ms  /* Lists, navigation */
--duration-expansion: 450ms /* FAB to Sheet */
--duration-bounce: 600ms    /* Success feedback */

/* Easing curves */
--ease-tap-feedback: cubic-bezier(0.4, 0, 1, 1)
--ease-standard: cubic-bezier(0.4, 0, 0.2, 1)
--ease-bounce: cubic-bezier(0.68, -0.55, 0.265, 1.55)
```

## 🚀 Usage

### Quick Start
```tsx
import { ThemeProvider } from "@/components/ui/theme-provider";
import { Button } from "@/components/ui/button";
import { ToolCard } from "@/components/patterns";

function App() {
  return (
    <ThemeProvider defaultTheme="dark">
      <div className="min-h-screen bg-surface-0 text-text-primary">
        <Button variant="accent">Sacred Gold Accent</Button>
        <ToolCard {...toolProps} />
      </div>
    </ThemeProvider>
  );
}
```

### Theme Switching
```tsx
import { ThemeToggle } from "@/components/ui/theme-toggle";

// Instant toggle between light/dark
<ThemeToggle />

// Dropdown with system option
<ThemeDropdown />
```

### Adding New Tokens
1. Update JSON files in `design-tokens/`
2. Run `npm run tokens:build` to regenerate CSS
3. Use new tokens in components automatically

## 🔧 Development

### Testing Components
Visit `/test-design-system` to see all components with live theme switching.

### File Structure
```
apps/web/
├── design-tokens/
│   ├── colors.json
│   ├── typography.json
│   └── motion.json
├── styles/
│   ├── tokens.css         # Generated dark mode
│   ├── tokens-light.css   # Generated light mode
│   └── globals.css        # Base imports
├── components/
│   ├── ui/               # Primitives
│   └── patterns/         # Molecules
└── app/
    ├── test-design-system/  # Testing environment
    └── globals.css          # Theme imports
```

### Commands
```bash
npm run tokens:build    # Regenerate CSS from JSON
npm run dev            # Start development server
npm run build          # Production build
```

## 📏 Standards

### Component Requirements
- **TypeScript** - Full type safety with proper interfaces
- **Accessibility** - Proper ARIA labels, focus management
- **Performance** - Optimized animations, minimal rerenders  
- **Consistency** - Use design tokens, follow naming conventions
- **Responsiveness** - Mobile-first, proper touch targets

### Animation Guidelines
- Use token-based durations and easing
- Target 60fps for all interactions
- Provide reduced motion fallbacks
- Animations should convey meaning, not decoration

### Color Usage Rules
- **#FFD700 gold is sacred** - only for focus rings, live status, key triggers
- Use semantic tokens, never hardcoded colors
- Ensure 4.5:1 contrast ratio minimum
- Test in both light and dark modes

## 🔮 Future Roadmap

### Phase 2: Enhanced Patterns
- **Navigation components** (sidebar, mobile nav)
- **Data visualization** patterns  
- **Form validation** system
- **Loading states** and skeletons

### Phase 3: Advanced Features
- **Storybook documentation** for component library
- **Framer Motion integration** with motion tokens
- **Design system linting** rules
- **Cross-platform token export** (iOS/Android)

### Phase 4: Ecosystem
- **Component playground** for rapid prototyping
- **Design-to-code pipeline** automation
- **Usage analytics** and optimization
- **Community contribution** guidelines

---

**Built with love for the HIVE community.** 🐝

The design system embodies HIVE's core philosophy: sophisticated infrastructure that enables students to build and connect without constraints. Every component, token, and interaction is crafted to scale from a single student's web dashboard to enterprise-level experiences — all while maintaining the premium, physics-based feel that defines the HIVE aesthetic. 
 