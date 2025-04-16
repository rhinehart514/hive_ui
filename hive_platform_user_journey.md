# HIVE Platform - Three-Tab User Journey

This document outlines the complete user journey across HIVE's three-tab architecture: Feed, Spaces, and Profile. All components follow the "Sophisticated Dark Infrastructure" aesthetic with consistent design language.

## 1. Shared Visual Language

### 1.1 Core Visual Elements (All Tabs)
- **Color System:** Dark (#121212) backgrounds with gold accent (#EEB700)
- **Typography:** Inter font family exclusively:
  - Headings: 24px/18px Semi-Bold
  - Body: 16px Regular, 1.5-1.6x line height
  - Meta text: 14px/12px Medium
- **Spacing:** 8px grid system (all spacing is multiple of 8px)
- **Corners:** 8px radius for cards, 4px for interactive elements
- **Glassmorphism:** Subtle backdrop blur (8px) with 10-20% opacity overlays

### 1.2 Animation & Motion
- **Transitions:** 300-400ms duration
- **Microinteractions:** 150-250ms duration
- **Easing:** cubic-bezier(0.4, 0, 0.2, 1)
- **Tab Switching:** Subtle fade transition (400ms)
- **Card Appearance:** Slight scale-up (from 0.98 to 1.0)
- **All animations respect prefers-reduced-motion settings**

### 1.3 Shared Interaction Patterns
- **Tap:** Primary action with light haptic feedback
- **Long-press:** Secondary actions with medium haptic feedback
- **Pull-to-refresh:** Available in all scrollable areas with consistent gold indicator
- **Tab Bar:** Fixed at bottom with subtle active state indicator
- **Toast Messages:** Brief success/error feedback with gold/error tones

## 2. Feed Tab Journey

### 2.1 Feed Structure
- **Feed Strip (Top):** Horizontal scrollable section showing:
  - 🔥 Space Heat updates
  - 🎯 Ritual prompts (campus-wide)
  - ⏳ Time markers
  - 📈 Motion recaps
  - 👀 Peer proximity indicators
- **Vertical Feed Stack:** Primary content area with:
  - Event cards
  - Repost cards
  - Quote cards
  - Space suggestions
  - Friend motion cards

### 2.2 Content Discovery & Interaction
- **Event Cards:** Shows title, time, location, RSVP button (tap to RSVP)
- **Space Motion Cards:** "UB Creatives is heating up" (tap to view Space)
- **Ritual Cards:** Campus-wide prompts (tap to participate)
- **Pull-to-refresh:** Updates content with the latest campus activity
- **All cards show appropriate active states on interaction**

### 2.3 Ritual Experience (Within Feed)
- **System-wide Rituals:** Always featured in Feed Strip
- **Participation Flow:**
  - Tap ritual card or strip element
  - Full-screen overlay with clear action prompt
  - Lightweight participation (tap, vote, 1-line input)
  - Immediate success feedback with gold accent
  - Badge earning notification if applicable
- **Results may resurface in Feed later as cultural touchpoints**

## 3. Spaces Tab Journey

### 3.1 Spaces Discovery
- **Entry View:** Grid of joined Spaces and suggestions
- **Space Card:** Shows name, member avatars, tag chips
- **Search Bar:** At top with recent/trending suggestions
- **New Space Button:** Appears more prominently after user joins multiple Spaces

### 3.2 Space Interior Structure
- **Header:** Space name, tags, Join/Joined button, member avatars
- **Content Modules:**
  - **Events Section:** Upcoming events with one-tap RSVP
  - **Active Prompts:** Space-specific rituals/polls
  - **Drop Stream:** 1-line posts from members
  - **Momentum Summary:** Join activity visualization
  - **Past Results:** Outcomes from previous prompts
- **All modules use consistent card design with 8px radius and glassmorphism**

### 3.3 Event Experience (Within Spaces)
- **Event Creation:**
  - **Builder-Created:** Formal creation with structured fields
  - **Organic Formation:** When a member's Drop (e.g., "movie night @ 8pm") gets 3+ "Going?" responses
- **Event States:**
  - Draft → Live → Feed-Surfaceable → Active → Concluded
- **RSVP Interaction:** One-tap with immediate visual feedback
- **Event Details:** Structured information with consistent typography

### 3.4 Space-Specific Rituals
- **Created by Space Builders for their members**
- **Format Types:**
  - Quick polls (tap options)
  - Text prompts (1-line input)
  - Challenge cards (structured action)
- **Results visible within Space and may surface in Feed**
- **Creates shared cultural touchpoints for Space identity**

### 3.5 Space Lifecycle Journey
- **Hidden:** Initially created, visible only to creator
- **Forming:** 3+ joins or 1 action triggers searchability
- **Live:** 10+ members with activity enables Feed suggestions
- **Dormant:** Reduced visibility after 7+ days of inactivity
- **Legacy:** Archived but preserved in member Trails

## 4. Profile Tab Journey

### 4.1 Profile Structure
- **Header Section:**
  - Avatar (editable)
  - Name/display handle
  - Status badge (Public/Verified/Verified+)
  - Builder credentials (if applicable)
  - Optional short bio (max 150 characters)

- **Conditional Modules (appear only when earned):**
  - **Current Spaces:** Cards showing active affiliations
  - **Motion Summary:** Trail-generated activity overview
  - **Badge Showcase:** Earned from system-wide Rituals
  - **Builder Status:** Spaces created and managed
  - **Legacy Highlights:** Notable past activity

### 4.2 Identity Principles
- **Motion-Based Profile:** Content reflects actions, not self-declaration
- **No Vanity Metrics:** No follower counts or public engagement numbers
- **System-Generated Content:** Based on participation and Trail
- **Limited Manual Editing:** Only name/avatar/bio can be changed

### 4.3 Privacy Controls
- **Default:** Private profile
- **Toggle Options:**
  - Profile visibility (private/public)
  - Spaces visibility
  - Trail visibility
- **Ghost Mode:** Option to browse without creating visible motion

### 4.4 Trail Visualization
- **Personal Activity History:** Visual timeline of participation
- **Spaces Joined:** Chronological affiliation record
- **Events Attended:** Past RSVPs with contextual metadata
- **Ritual Participation:** Record of engagement
- **All visualized with consistent design language**

## 5. Cross-Tab User Progression

### 5.1 Seeker to Builder Journey
- **Feed Tab:** Initial discovery through browsing and passive signals
- **Spaces Tab:** Joining begins after multiple views in Feed
- **Participation:** Within Spaces through Events and Rituals
- **Creation:** Creating first Space unlocks Builder status on Profile
- **Tab Usage Shifts:** As users progress, their tab usage patterns evolve

### 5.2 Tab Transitions & Memory
- **Consistent State Preservation:** Return to same scroll position
- **Cross-Tab Awareness:** Actions in one tab reflected in others
- **Tab Switching Animation:** Subtle fade with 400ms duration
- **Active Tab Indication:** Gold accent in bottom navigation

## 6. Implementation Success Criteria

### 6.1 Brand Aesthetic Consistency
- **Dark Infrastructure:** Consistent application of dark theme (#121212)
- **Gold Accent:** Strategic use of accent color (#EEB700) for focus/action
- **Typography Discipline:** Inter font used consistently across all tabs
- **Motion Philosophy:** Purposeful transitions with consistent timing
- **Glassmorphism:** Applied consistently for card treatments

### 6.2 Interaction Quality
- **One-Tap Philosophy:** Primary actions require single interaction
- **Haptic Language:** Consistent feedback patterns across tabs
- **Responsive Animation:** All interactive elements provide visual feedback
- **Focus States:** Clear indication of interactive elements (gold outline)

### 6.3 User-Centered Experience
- **Cold Start:** Each tab provides immediate value even with no history
- **No Empty States:** Pre-seeded content where needed
- **Passive Value:** Browsing without interaction still provides system benefits
- **Progressive Disclosure:** Features revealed as users demonstrate readiness

### 6.4 Motion-Based System
- No likes, comments, or vanity metrics
- Lightweight participation with meaningful impact
- Actions in any tab contribute to the shared Trail system
- Student-led cultural patterns emerge through collective behavior 