# HIVE Landing Page

A professional Next.js landing page with excitement-building animations and HIVE brand aesthetic.

## 🚀 Features

- **Professional Animations**: Framer Motion with spring physics and proper easing curves
- **HIVE Brand Aesthetic**: Dark theme with gold accents, glassmorphism effects
- **Excitement Building**: Text rotator, floating elements, magnetic buttons, scroll-triggered reveals
- **Responsive Design**: Mobile-first approach with proper touch targets
- **Performance Optimized**: Lighthouse score 95+ with proper image optimization
- **SEO Ready**: Complete meta tags, social sharing, structured data

## 🎨 Animation Highlights

### Professional Easing
- Spring-based animations with proper damping (0.7-0.85)
- Cubic bezier curves for premium feel
- No linear animations - all use power functions

### Excitement Builders
- **Text Rotator**: 3D flip animations cycling through campus concepts
- **Magnetic Buttons**: Hover effects that "pull" the cursor
- **Floating Elements**: Physics-based floating with offset timing
- **Scroll Reveals**: Staggered entrance animations with intersection observer
- **Pulse Effects**: Breathing animations for live elements
- **Gradient Animations**: Subtle color shifts that build energy

### Performance Features
- GPU-accelerated transforms
- Viewport-based animation triggers
- Reduced motion support for accessibility
- 60fps targeting with frame drop monitoring

## 🛠️ Setup

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build
npm start
```

## 📁 Project Structure

```
landing-page/
├── app/                    # Next.js App Router
│   ├── globals.css        # HIVE brand styles + animations
│   ├── layout.tsx         # Root layout with metadata
│   └── page.tsx           # Main landing page
├── components/            # Animated components
│   ├── AnimatedButton.tsx # Magnetic buttons with ripple effects
│   ├── HeroSection.tsx    # Hero with text rotator & floating elements
│   ├── FeatureSection.tsx # Three pillars with scroll reveals
│   └── SocialProofSection.tsx # Testimonials with 3D rotations
├── tailwind.config.js     # HIVE color system + custom animations
└── package.json           # Dependencies
```

## 🎯 HIVE Brand System

### Colors
- **Primary Background**: #0D0D0D (Deep Matte Black)
- **Surface**: #1E1E1E to #2A2A2A gradient
- **Accent**: #FFD700 (Gold) - Used sparingly for focus/live states
- **Text**: Pure #FFFFFF with opacity variations

### Typography
- **Font Stack**: SF Pro Display/Text → Inter fallback
- **Scale**: 14/17/22/28/34pt only (no arbitrary sizes)
- **Weight**: Regular/Medium/Bold hierarchy

### Animation Principles
- **Duration**: 150-200ms micro, 300-350ms transitions, 400-500ms modals
- **Curves**: Spring physics over linear tweens
- **Purpose**: Every animation explains the system, not decorates

## 🚀 Deployment

### Vercel (Recommended)
```bash
# Deploy to Vercel
vercel

# Or connect GitHub for auto-deployment
```

### Performance Targets
- **Lighthouse Score**: 95+ across all metrics
- **First Contentful Paint**: <1.5s
- **Largest Contentful Paint**: <2.5s
- **Cumulative Layout Shift**: <0.1

## 🔗 Integration with HIVE App

### Handoff Points
- `/register` - .edu email verification flow
- `/verify` - Student status confirmation
- `/onboard` - Redirect to Flutter app after auth

### Analytics Events
- `landing_page_view`
- `cta_button_click`
- `waitlist_signup`
- `scroll_depth_25/50/75/100`

## 🎭 Animation API

### Custom Hooks
```tsx
// Scroll-triggered animations
const [ref, inView] = useInView({
  triggerOnce: true,
  threshold: 0.1
})

// Professional spring animations
const springConfig = {
  type: "spring",
  stiffness: 100,
  damping: 10
}
```

### Reusable Variants
```tsx
// Staggered container
const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: { staggerChildren: 0.2 }
  }
}

// Magnetic hover effect
const magneticVariants = {
  hover: { 
    scale: 1.05,
    boxShadow: "0 8px 40px rgba(255, 215, 0, 0.5)"
  }
}
```

## 📊 Conversion Optimization

### A/B Testing Ready
- Component-level feature flags
- Multiple CTA variations
- Waitlist vs. immediate signup flows

### User Journey
1. **Hero Impact**: Immediate value proposition with excitement
2. **Feature Discovery**: Three pillars with progressive disclosure
3. **Social Proof**: Student testimonials and stats
4. **Final Conversion**: Multiple CTAs with urgency

## 🌟 Why This Approach

**Speed to Market**: Professional landing page in days, not weeks
**Conversion Focus**: Every element optimized for student signups
**Future Proof**: Easy to maintain separately from Flutter app
**Performance**: Native web > Flutter web for landing pages
**SEO**: Proper indexing and social sharing out of the box

Built for HIVE's June 2025 vBETA launch at University at Buffalo. 