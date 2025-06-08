# HIVE + shadcn/ui Integration Strategy

## Overview

HIVE's design system is built as a sophisticated layer on top of shadcn/ui, maintaining our campus-native aesthetic while leveraging battle-tested primitives. This document outlines the integration architecture and best practices.

## Integration Layers

| Layer | Existing HIVE Stack | shadcn/ui Integration | Implementation Notes |
|-------|-------------------|---------------------|---------------------|
| **Design-token source** | Style Dictionary → Tailwind config / RN / Flutter | No change to token generation | Run `style-dictionary build` first so copied shadcn files can reference `var(--hive-...)` tokens immediately |
| **Styling & variants** | Tailwind CSS + class-variance-authority (CVA) | Keep both systems | Use CVA wrappers around copied shadcn files—this decouples variant logic from raw Tailwind strings |
| **Headless primitives** | React-Aria Components | shadcn copies of Radix primitives | Long-term: treat shadcn components as temporary skins around Radix logic; migrate to React-Aria later without breaking public API |
| **Motion** | Framer Motion | Add shadcn's animate helpers if desired | Wrap each shadcn component in `<motion...>` once after paste; motion logic lives next to CVA wrapper |
| **Forms & schema** | react-hook-form + zod | shadcn's form helpers are optional | Keep react-hook-form as source of truth; if copying FormField.tsx, re-export RHF hooks under shadcn alias |
| **Docs / QA** | Storybook 8 + axe-core | Import shadcn stories via CLI | Run `npx shadcn@latest ui card` then `ui:storybook card` to generate stories that surface token mismatches |

## HIVE Theme Configuration

### CSS Variables (globals.css)

```css
@layer base {
  :root {
    /* HIVE Dark Theme - Campus Infrastructure */
    --background: 13 13 13; /* #0D0D0D - Deep matte black */
    --foreground: 255 255 255; /* #FFFFFF - Pure white text */
    
    --card: 30 30 30; /* #1E1E1E - Surface gray */
    --card-foreground: 255 255 255;
    
    --primary: 255 215 0; /* #FFD700 - Sacred gold */
    --primary-foreground: 13 13 13; /* Black text on gold */
    
    --secondary: 42 42 42; /* #2A2A2A - Elevated surface */
    --secondary-foreground: 255 255 255;
    
    --muted: 42 42 42;
    --muted-foreground: 153 153 153; /* #999999 - Tertiary text */
    
    --destructive: 255 59 48; /* #FF3B30 - iOS red */
    --destructive-foreground: 255 255 255;
    
    --border: 64 64 64; /* #404040 - Subtle borders */
    --input: 30 30 30;
    --ring: 255 215 0; /* Gold focus rings */
  }
}
```

## Component Enhancement Strategy

### 1. CVA-Wrapped shadcn Components

Each HIVE component extends shadcn with campus-specific intents:

```typescript
// HiveButton extends shadcn Button
const buttonVariants = cva(
  "inline-flex items-center justify-center...", // shadcn base
  {
    variants: {
      intent: {
        primary: "bg-foreground text-background hover:bg-foreground/90",
        urgent: "hive-button-urgent", // Custom HIVE class
        social: "hive-button-social",
        destructive: "hive-button-destructive",
      }
    }
  }
)
```

### 2. Campus Context Classes

```css
@layer components {
  /* Campus-specific button intents */
  .hive-button-urgent {
    @apply bg-primary text-primary-foreground font-semibold shadow-lg;
    @apply hover:bg-primary/90 active:bg-primary/80;
  }
  
  /* Campus content card contexts */
  .hive-card-event {
    @apply border-l-4 border-primary/50;
  }
  
  .hive-card-poll {
    @apply bg-gradient-to-br from-card to-blue-500/5 border border-blue-500/20;
  }
}
```

### 3. Framer Motion Integration

```typescript
const HiveButton = React.forwardRef<HTMLButtonElement, HiveButtonProps>(
  ({ className, intent, size, asChild = false, loading, children, ...props }, ref) => {
    const Comp = asChild ? Slot : motion.button
    
    return (
      <Comp
        className={cn(buttonVariants({ intent, size, className }))}
        whileTap={{ scale: 0.98 }}
        transition={{ duration: 0.15 }}
        {...props}
      >
        {children}
      </Comp>
    )
  }
)
```

## Campus-Specific Component Variants

### Button Intents (Campus Actions)
- **Primary**: Join Space, Create Event (core actions)
- **Urgent**: RSVP NOW, Join Queue (time-sensitive with gold + shadow)
- **Social**: Invite Friends, Share Event (community building)
- **Secondary**: View Details, Learn More (exploration)
- **Destructive**: Leave Space, Cancel RSVP (safe exits)

### Card Contexts (Campus Content)
- **Event**: Time-sensitive gatherings (gold left border)
- **Poll**: Community decision-making (info gradient)
- **Announcement**: Important updates (warning gradient)
- **Group**: Social connections (success gradient)
- **Resource**: Academic materials (clean borders)

### Input Variants (Student Expression)
- **Default**: Profiles, general forms
- **Poll Option**: Quick poll creation (info styling)
- **Anonymous**: Safe expression (dark, anonymous badge)
- **Live Chat**: Real-time communication (gold borders, live dot)

## Development Workflow

### 1. Adding New shadcn Components

```bash
# Install shadcn component
npx shadcn@latest add card

# Generate Storybook story (if available)
npx shadcn@latest ui:storybook card

# Create HIVE wrapper in @/components/ui/hive-card.tsx
```

### 2. HIVE Enhancement Process

1. **Base**: Start with generated shadcn component
2. **CVA**: Add campus-specific variants using class-variance-authority
3. **Motion**: Wrap with Framer Motion for interactions
4. **CSS**: Add custom campus context classes in globals.css
5. **Types**: Extend props interface for campus scenarios
6. **Stories**: Update Storybook with HIVE variants

### 3. Token Integration

```bash
# Regenerate tokens first
npm run tokens:build

# Then copy/modify shadcn components
npx shadcn@latest add button

# Tokens are immediately available as var(--primary), var(--background), etc.
```

## Best Practices

### 1. Token Priority
- **Always** use shadcn CSS variables (`--primary`, `--background`) over direct colors
- Only add custom HIVE variables for campus-specific semantics
- Run token build before component development

### 2. Variant Isolation
- Keep campus logic in CVA variants, not inline Tailwind
- Use descriptive intent names (`urgent`, `social`) not style names (`yellow`, `blue`)
- Campus contexts should solve real student problems

### 3. Progressive Enhancement
- shadcn component works standalone
- HIVE variants add campus-specific behavior
- Motion and custom styling are additive layers

### 4. Migration Path
- shadcn provides immediate Radix + accessibility
- Can migrate individual components to React-Aria later
- Public API remains stable through CVA wrapper

## Campus Social Platform Requirements

### Real-World Scenarios
- **Urgent housing deadline** → Announcement card + urgent button
- **Study group formation** → Group card + social button + avatars
- **Anonymous feedback** → Anonymous input + safe expression
- **Live event happening** → Event card + live status + urgent RSVP

### Social Proof Elements
- Status indicators (LIVE, FULL, ENDING SOON)
- Role badges (Builder, RA, Org Leader)
- Participation counts (23 going, 4/6 spots filled)
- Real-time indicators (live dots, pulse animations)

## Quality Assurance

### Automated Checks
- Storybook stories for all HIVE variants
- axe-core accessibility testing
- Visual regression testing for token changes
- Type safety for all campus-specific props

### Manual Testing
- Campus scenario walkthroughs
- Mobile responsiveness
- Dark theme consistency
- Animation performance (60fps target)

## File Structure

```
apps/web/
├── components/ui/
│   ├── button.tsx           # shadcn base
│   ├── hive-button.tsx      # HIVE wrapper with campus intents
│   ├── card.tsx             # shadcn base
│   ├── hive-card.tsx        # HIVE wrapper with contexts
│   └── ...
├── app/globals.css          # HIVE theme + campus classes
└── stories/
    ├── Button.stories.tsx   # shadcn variants
    └── HiveButton.stories.tsx # Campus scenarios
```

This integration strategy ensures HIVE maintains its sophisticated campus aesthetic while leveraging the reliability and accessibility of shadcn/ui primitives. 