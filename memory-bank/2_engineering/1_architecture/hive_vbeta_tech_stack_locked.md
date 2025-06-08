# HIVE vBETA Technical Stack - LOCKED SPECIFICATION

_Last Updated: January 2025_  
_Status: PRODUCTION LOCKED - No Changes Without Architecture Review_  
_Authority: Technical Architecture Decision Record_

---

## 🔒 EXECUTIVE SUMMARY

This document represents the **LOCKED** technical foundation for HIVE vBETA development. All technology choices have been validated against our architectural principles, performance requirements, and campus-scale deployment needs.

**Key Decision:** Web-first development with Flutter mobile as strategic follow-up, unified by token-driven design system.

---

## 🌐 FRONT-END • WEB PLATFORM

### **Framework & Runtime Foundation**
- **React 19** - Latest stable with concurrent features
- **Next.js 15** - App Router, React Server Components, Turbopack
- **TypeScript 5.3+** - Strict mode with comprehensive type safety

**Strategic Rationale:**
- App Router enables file-based routing with layout composition
- React Server Components optimize initial page loads critical for campus WiFi
- Turbopack provides sub-second refresh for rapid iteration

### **Styling Architecture**
- **Tailwind CSS 4** - Utility-first with CSS-in-JS compatibility
- **Style Dictionary** - Single source of truth for design tokens
- **CSS Custom Properties** - `var(--hive-*)` tokens for theme consistency

**Token Pipeline:**
```
Style Dictionary → CSS Variables → Tailwind Config → Component Classes
```

### **Component System Architecture**
```
COMPONENT LAYER HIERARCHY
├── shadcn/ui (Radix-powered primitives)
│   ├── Accessibility built-in (ARIA, keyboard navigation)
│   ├── Headless logic with customizable styling
│   └── Battle-tested component behaviors
├── Class-Variance-Authority (CVA)
│   ├── Type-safe variant management
│   ├── Campus-specific intent mapping
│   └── Consistent API across components
└── React-Aria Components (new/headless primitives)
    ├── Adobe's accessibility-first components
    ├── Keyboard interaction standards
    └── Screen reader optimization
```

**Integration Strategy:**
- shadcn/ui provides immediate Radix accessibility + reliability
- CVA wrappers add HIVE-specific variants (urgent, social, destructive)
- React-Aria Components for advanced interactions not covered by shadcn

### **Motion & Animation**
- **Framer Motion 11** - Physics-based animations with spring presets
- **Animation Strategy:** 150-200ms micro-interactions, 300-400ms transitions
- **Performance Target:** 60fps guaranteed, reduced motion support

### **State Management**
```
STATE ARCHITECTURE
├── TanStack Query v5 (Server State)
│   ├── Automatic caching and background updates
│   ├── Optimistic updates for responsive UX
│   ├── Error boundaries and retry logic
│   └── Real-time sync with Firestore
└── Zustand 5 (Client State)
    ├── Simple, non-boilerplate global state
    ├── TypeScript-first with immer integration
    ├── Persistence for user preferences
    └── DevTools integration for debugging
```

### **Forms & Validation**
- **react-hook-form 8** - Performance-optimized form management
- **Zod** - Runtime type validation with TypeScript inference
- **Strategy:** Schema-first validation with real-time feedback

### **Icons & Assets**
- **lucide-react** - Consistent 1.5-2px stroke weight
- **Performance:** Tree-shaking enabled, SVG optimization
- **HIVE Standard:** Line-based icons only, no filled variants

---

## 📱 MOBILE • FLUTTER PLATFORM

### **Framework Foundation**
- **Flutter 3.22 (stable)** - Production-ready with Dart 3 compatibility
- **Dart 3** - Sound null safety with pattern matching

### **Token Bridge Architecture**
```
DESIGN TOKEN FLOW
Style Dictionary → flutter_gen → Dart Classes
```

**Generated Classes:**
- `HiveColors.primaryBackground` 
- `HiveSpacing.space4`
- `HiveRadius.buttonRadius`
- `HiveDuration.fastTransition`

### **UI Architecture**
```
FLUTTER COMPONENT SYSTEM
├── Custom HiveWidget Library
│   ├── Material Design DISABLED (no built-in Material widgets)
│   ├── Pure Container + DecoratedBox composition
│   ├── Apple-flat aesthetic matching web exactly
│   └── Campus-specific variants (urgent, social, destructive)
├── Animation System
│   ├── Flutter Animate for complex sequences
│   ├── AnimatedContainer for property transitions
│   ├── Hero widgets for page transitions
│   └── Physics-based spring curves
└── Platform Integration
    ├── iOS: Cupertino navigation patterns
    ├── Android: Material motion with HIVE styling
    └── Haptic feedback integration
```

### **Navigation & Routing**
- **go_router 9** - URL-aware routing with web fallback compatibility
- **Deep Linking:** Full URL support for campus sharing
- **Transition Strategy:** iOS-inspired push/pop with custom HIVE animations

### **State Management**
- **Riverpod 3** - Compile-time safety with provider dependency injection
- **Architecture Benefits:**
  - No runtime errors from provider access
  - Built-in testing support
  - DevTools integration
  - Automatic disposal

### **Networking & Backend**
- **dio** - HTTP client with interceptors for error handling
- **firebase_core + firebase_auth** - Parity with web authentication
- **Firestore SDK** - Real-time sync with offline persistence

### **Icons & Graphics**
- **flutter_svg** - Same lucide icon paths as web
- **Consistency:** Identical icon library across platforms

### **Accessibility & Testing**
- **Semantics widgets** - Screen reader optimization
- **flutter_a11y lints** - Automated accessibility validation
- **Testing Stack:**
  - Flutter Driver for integration tests
  - golden_toolkit for pixel-perfect UI regression testing

---

## 🚀 BACK-END & INFRASTRUCTURE

### **Core Services** (Established & Working)
- **Firebase Auth** - .edu email validation with custom claims
- **Firestore** - Real-time database with optimized security rules
- **Cloud Functions (TypeScript)** - RSS processing, surge detection
- **Cloud Storage** - Media assets and tool templates

### **Deployment Architecture**
- **Web:** Vercel (Edge Functions, global CDN)
- **Functions & Database:** Google Cloud Platform (us-central1)
- **Mobile:** App Store + Google Play Store distribution

### **Geographic Strategy**
- **Primary Region:** us-central1 (Chicago) - optimal for University at Buffalo
- **CDN:** Global edge caching for static assets
- **Performance Target:** <2s load times campus-wide

---

## 🛠️ DEVELOPMENT TOOLCHAIN

### **Monorepo Architecture**
```
REPOSITORY STRUCTURE
├── pnpm workspaces (JavaScript/TypeScript)
│   ├── apps/web (Next.js)
│   ├── packages/tokens (Style Dictionary)
│   └── packages/shared (utilities)
└── Melos (Dart/Flutter packages)
    ├── apps/mobile (Flutter)
    └── packages/flutter_tokens (generated)
```

### **Continuous Integration Pipeline**
```
GITHUB ACTIONS WORKFLOW
├── Web Build & Test
│   ├── Next.js production build
│   ├── Vitest unit tests
│   ├── Playwright E2E tests
│   ├── axe-core accessibility audit
│   └── Lighthouse CI performance validation
├── Flutter Build & Test
│   ├── APK/IPA compilation
│   ├── Flutter Driver integration tests
│   ├── Golden file regression testing
│   └── flutter_a11y accessibility validation
└── Deployment
    ├── Vercel automatic deployment (web)
    ├── TestFlight distribution (iOS)
    └── Firebase App Distribution (Android)
```

### **Quality Assurance Stack**
- **Web Monitoring:** Sentry + LogRocket for error tracking
- **Flutter Monitoring:** Sentry with custom crash reporting
- **Performance:** Lighthouse CI with budget enforcement
- **Security:** Dependabot for automated dependency updates

### **Documentation & Design**
- **Storybook 8** (Web) - Component documentation with interaction testing
- **Widgetbook** (Flutter) - Mobile component playground
- **Token Sharing:** JSON design tokens consumed by both platforms

---

## 🎯 ARCHITECTURAL PRINCIPLES VALIDATION

### **Performance Requirements** ✅
- **Web:** <2s load times, 60fps animations, Core Web Vitals green
- **Mobile:** 60fps UI, <100ms touch response, efficient memory usage
- **Backend:** <200ms API response times, real-time sync <500ms

### **Accessibility Standards** ✅
- **WCAG 2.1 AA compliance** across web and mobile
- **Keyboard navigation** for all interactive elements
- **Screen reader optimization** with semantic markup
- **Reduced motion support** for animation preferences

### **Campus Scale Requirements** ✅
- **Concurrent Users:** 1000+ students during peak periods
- **Real-time Updates:** Live feed refresh, RSVP sync, tool surge detection
- **Offline Capability:** Profile data cache, event information persistence
- **Cross-Platform Data Sync:** Instant sync between web and mobile

### **Developer Experience** ✅
- **Type Safety:** End-to-end TypeScript/Dart type checking
- **Hot Reload:** <1s refresh times for rapid iteration
- **Component Testing:** Comprehensive test coverage with visual regression
- **Documentation:** Self-documenting components with usage examples

---

## 🔒 TECHNOLOGY LOCK STATUS

### **LOCKED DECISIONS** (No Changes Without Architecture Review)
- ✅ React 19 + Next.js 15 (App Router) for web platform
- ✅ Flutter 3.22 + Dart 3 for mobile platform  
- ✅ Style Dictionary → CSS Variables → Tailwind workflow
- ✅ shadcn/ui + CVA component architecture
- ✅ TanStack Query + Zustand state management
- ✅ Firebase backend infrastructure
- ✅ Monorepo with pnpm + Melos toolchain

### **FLEXIBLE DECISIONS** (Can Evolve Based on Usage)
- 🔄 Specific component variants and campus intents
- 🔄 Animation timing and motion preferences
- 🔄 Mobile navigation patterns
- 🔄 Performance optimization strategies
- 🔄 Testing framework enhancements

### **FUTURE EVOLUTION PATH**
- **Post-vBETA:** Evaluate React 19 concurrent features
- **Scale-Up:** Consider GraphQL for complex queries
- **Advanced Features:** WebRTC for real-time collaboration
- **Platform Expansion:** React Native evaluation for faster mobile development

---

## 📊 IMPLEMENTATION CONFIDENCE

### **Risk Assessment** 
- **LOW RISK:** All technologies are production-proven
- **PROVEN SCALING:** Tech stack supports 10,000+ user growth
- **CAMPUS VALIDATION:** Optimized for university network conditions
- **MAINTENANCE:** Long-term support guaranteed for all major dependencies

### **Team Readiness**
- **Documentation:** Comprehensive setup guides and architectural decisions
- **Tooling:** Development environment fully configured
- **Standards:** Code quality gates and review processes established
- **Monitoring:** Error tracking and performance monitoring operational

---

**TECHNICAL FOUNDATION STATUS: LOCKED AND READY FOR PRODUCTION**

*This technology stack provides the solid foundation for building HIVE into the definitive campus coordination platform, with each choice validated against our architectural principles and campus-scale requirements.* 