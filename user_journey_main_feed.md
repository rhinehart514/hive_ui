# HIVE Platform - Comprehensive User Journey

## 1. Initial Experience

### 1.1 Launch & Authentication
- App opens to a dark (#121212) background with HIVE branding
- Subtle animation welcomes user (300-400ms duration with cubic-bezier easing)
- System checks authentication status silently
- If first-time user, minimal onboarding with clear CTAs

### 1.2 Cold Start Experience
- Feed pre-populated with campus-relevant events (no empty states)
- Feed Strip displays time marker and active ritual prompt
- ShimmerEventCard placeholders shown during data loading with subtle animation
- System begins tracking curiosity signals (taps, lingers, hovers) immediately

## 2. Feed Structure & Components

### 2.1 Feed Strip (Top Horizontal Section)
- Pinned to top, horizontally scrollable
- Contains 5 cards maximum in viewport
- Card types rotate based on:
  - 🔥 Space Heat: "UB Creatives is heating up"
  - 🎯 Ritual Launch: "Confess in 1 line now"
  - ⏳ Time Marker: "Finals Week Begins" 
  - 📈 Motion Recap: "2 of your Spaces just got Boosted"
  - 👀 Peer Proximity: "You and 2 others RSVP'd to..."
- Uses glassmorphism effect with subtle blur and gold accent for active elements

### 2.2 Feed Body (Vertical Stack)
- Event Cards: Title, time, location, RSVP button
- Repost Cards: "Laney reposted..." with original content
- Quote Cards: "Laney: 'bring snacks'" with source event
- Ritual Cards: Campus-wide interactive prompts
- Space Suggestion Cards: "Design Union just got active"
- Friend Motion Cards: "You and 2 others just viewed this"
- All cards use consistent corner radius (8px) and spacing (8px multiples)

## 3. User Interactions & Feedback

### 3.1 Gesture System
- Tap: Primary action (RSVP, Join, Participate)
- Long-press: Contextual actions (Boost for Verified+ users)
- Swipe down: Refresh feed with haptic feedback
- Horizontal swipe: Navigate Feed Strip cards

### 3.2 Feedback Loops
- Every interaction provides immediate visual feedback
- RSVP: Button state changes + haptic feedback
- Join Space: Instant addition to member list
- Ritual participation: Visual acknowledgment + Trail update
- Feed reshapes subtly after significant actions
- Success messages appear with gold accent (#EEB700)

### 3.3 Pull-to-Refresh
- Custom gold-accented refresh indicator
- Haptic feedback on refresh initiation and completion
- Brief success message on data refresh
- Feed content updates with subtle transition

## 4. Content Discovery Progression

### 4.1 Seeker Phase
- System detects curiosity through taps and lingers
- "Observer" status assigned after 3+ passive touches
- Feed gradually adapts to show content from Spaces user has viewed
- Space suggestions appear based on browsing patterns
- Friend Motion cards increase social proof

### 4.2 Joiner Phase 
- After joining first Space, Feed shows more content from that Space
- System suggests related Spaces based on Cluster Engine
- Event cards get higher visibility for Spaces user has joined
- Ritual Strip adapts to show more relevant prompts
- "Still vibing with [Space]?" check-ins appear periodically

### 4.3 Builder Progression (Advanced)
- Space creation button becomes more prominent after joining multiple Spaces
- Builder permissions unlock (Boost, Events, Rituals)
- Feed gives stronger creator feedback
- Verified+ status may be offered based on engagement patterns

## 5. Participation & Engagement Models

### 5.1 Lightweight Signals
- Repost: Tap to amplify content to personal network
- Quote: Repost with added context (single line)
- RSVP: Simple tap to confirm attendance
- Join Space: One-tap affiliation

### 5.2 Ritual Engagement
- Ritual cards appear in Feed with clear calls-to-action
- Participation creates Trail entry and reshapes Feed
- Results may resurface later as Feed cards
- System-wide rituals create shared cultural moments

### 5.3 Authentic Feedback (No Vanity Metrics)
- No public like counts or follower numbers
- Engagement measured through meaningful actions (RSVPs, Joins)
- Cultural pulse shown through "Space Heat" and "Motion Recap" cards
- Badge system for ritual participation (not numerical metrics)

## 6. Feed Intelligence & Personalization

### 6.1 Feed Engine Logic
- Content ranked by: Recency × PulseScore × GravityScore × RoleMultiplier
- Pulse: Detection of surging content based on engagement velocity
- Gravity: Directional interest between users, Spaces, and content
- Role: Behavioral patterns mapped to archetypes (Seeker, Joiner, Builder)

### 6.2 Trail System
- Silent tracking of participation and curiosity
- Used to personalize Feed without explicit preferences
- Feeds into Cluster Engine for social mapping
- Creates memory and continuity across sessions

### 6.3 Affiliation Impact
- Joined Spaces get priority in Feed ranking
- Member status unlocks deeper Space participation
- Active membership creates stronger Gravity scores
- Feed visibly shifts after significant affiliations

## 7. State Transitions & Card Lifecycle

### 7.1 Content States
- Cold: Initial state, limited visibility
- Warming: Gaining traction through reactions/reposts
- Hot (Pulse): High engagement, increased visibility
- Cooling: Engagement slowing, visibility decreasing
- Faded: Archived but preserved in Trail

### 7.2 Card Decay Rules
- Event Cards: Visible until event start time
- Repost Cards: 48-hour default visibility
- Quote Cards: 24-hour default visibility
- Ritual Cards: Active during ritual duration
- All lifespans extended by engagement

## 8. Performance & Accessibility

### 8.1 Performance Optimization
- Lazy loading of images and content
- Pagination for smooth scrolling experience
- Content prioritization based on viewport
- Memory management for large feed streams

### 8.2 Accessibility Features
- High contrast text meeting WCAG AA standards
- Focus states with gold accent (#EEB700, ≥2px)
- Respects prefers-reduced-motion settings
- Semantic structure for screen readers

## 9. Motion & Animation Guidelines

### 9.1 Animation Principles
- Transitions: 300-400ms default duration
- Microinteractions: 150-250ms duration
- Easing: cubic-bezier(0.4, 0, 0.2, 1)
- Only animate opacity and transform properties for performance
- All animations respect prefers-reduced-motion
- Purposeful motion, not decorative

### 9.2 Haptic Feedback
- Light impact for standard interactions
- Medium impact for confirmations (RSVP, Join)
- Consistent across all interactive elements
- Enhances the physical feel of the interface

## 10. Space User Journey

### 10.1 Space Discovery
- **Entry Points:** Feed suggestions, Friend Motion cards, or direct search
- **Observation Phase:** User views Space content without joining
- System silently tracks views and creates curiosity weight in Trail
- After 3+ views, user is classified as an "Observer" for this Space

### 10.2 Space Structure
- **Header:** Space name, tags, Join button, member avatars (no counts)
- **Content Modules:**
  - Upcoming Events with RSVP buttons
  - Active Prompts with voting options
  - Drop Stream (1-line posts from members)
  - Most Quoted Drops with interaction contexts
  - Join Momentum summaries ("3 students joined this week")
  - Past Prompt Results with visual outcomes

### 10.3 Space Joining & Participation
- One-tap join with immediate feedback
- Joining unlocks ability to:
  - Add Drops (1-line posts)
  - Vote on Prompts
  - Participate fully in Space-specific Rituals
- All participation is recorded in Trail
- Space members see period "Still vibing with [Space]?" check-ins

### 10.4 Space Lifecycle
- **Hidden:** Initially created, only visible to creator
- **Forming:** 3+ joins or 1 active contribution triggers searchability
- **Live:** 10+ members and consistent activity enables Feed suggestions
- **Dormant:** 7+ days without activity reduces visibility
- **Legacy:** Archived but preserved in Trail for historical context

### 10.5 Builder Experience
- Space creator automatically becomes Builder
- Builders can:
  - Create Events within the Space
  - Boost content to increase visibility
  - Run Space-specific Rituals and Prompts
  - See additional engagement metrics

## 11. Events User Journey

### 11.1 Event Creation Pathways
- **Builder-Created:** Formal event creation with title, time, location fields
- **Organic Formation:** When a member's Drop (e.g., "movie night @ 8pm") gets 3+ "Going?" responses, system auto-converts to Event

### 11.2 Event Discovery
- Events appear in Feed based on Space affiliation and RSVP momentum
- RSVP count increases Feed visibility and Pulse score
- Friend Motion cards show when peers RSVP
- Builder-Boosted events get temporary Feed priority

### 11.3 Event Interaction
- One-tap RSVP with immediate visual and haptic feedback
- Event cards show:
  - Title and description
  - Time and location
  - RSVP count (no usernames unless Friends)
  - Space affiliation

### 11.4 Event States
- **Draft:** Created, visible only in Space
- **Live:** With 1+ RSVP, visible to Space members
- **Feed-Surfaceable:** 5+ RSVPs or Boosted
- **Active:** During event time window
- **Concluded:** Transforms into memory or highlight in Trail

## 12. Rituals User Journey

### 12.1 Campus-Wide Rituals
- System-authored, time-limited interactive experiences
- Always featured prominently in Feed Strip
- Examples:
  - Campus Confessions (anonymous 1-line shares)
  - 1:1 Pairing Night (opt-in matching)
  - Vote-to-unlock campus moments
  - Seasonal challenges or activities

### 12.2 Ritual Participation Flow
- User taps Ritual card in Feed or Strip
- Full-screen interaction appears with clear action prompt
- Participation is lightweight (tap, vote, short text input)
- Immediate feedback on completion
- Ritual participation may earn exclusive badges for Profile

### 12.3 Space Rituals
- Created by Space Builders specifically for their members
- Formats include polls, prompts, and lightweight challenges
- Results may surface in Feed: "Design Union ran a ritual — here's what happened..."
- Creates shared experience and identity for Space members

### 12.4 Ritual Impact
- Shapes Feed algorithm based on participation
- Creates cultural touchpoints and shared references
- May form new Clusters based on similar participation patterns
- Earns badges that become visible identity markers on Profile

## 13. Profile & Identity Journey

### 13.1 Profile Structure
- **Header:** Avatar, name, status badge (Verified, Verified+)
- **Conditional Modules:**
  - Current Spaces (affiliation cards)
  - Motion Summary (based on Trail)
  - Badge Showcase (from Ritual participation)
  - Builder Credential (if applicable)
  - Legacy Trail highlights

### 13.2 Identity Formation Principles
- Profile reflects motion, not self-description
- No manual editing beyond name/avatar/bio
- No vanity metrics (likes, follower counts)
- All content generated by system based on behavior
- "You are what you do" philosophy

### 13.3 Privacy & Visibility
- Profiles private by default
- Optional toggles for:
  - Public profile visibility
  - Showing joined Spaces
  - Displaying activity summary
- Ghost Mode option to hide all activity while browsing

### 13.4 Identity Tiers
- **Public User:** View-only access to Feed (no .edu required)
- **Verified:** Full interaction with private profile (.edu required)
- **Verified+:** Builder permissions with public profile (earned through engagement)

## 14. Cross-Platform User Flows

### 14.1 Seeker to Builder Progression
1. **Discovery Phase:** Browse Feed, tap interesting content
2. **Affiliation Phase:** Join Spaces after multiple views
3. **Participation Phase:** Drop posts, RSVP to events, vote on prompts
4. **Creation Phase:** Create first Space, unlocking Builder permissions

### 14.2 Event Mobilization Flow
1. **Creation:** Builder creates event or organic formation occurs
2. **Momentum:** RSVPs increase visibility in Feed
3. **Pre-Event:** System sends reminders through Feed Strip
4. **Post-Event:** Event archived to Trail, may resurface as memory

### 14.3 System Intelligence Connections
- Feed actions trigger Trail updates
- Trail depth influences Feed algorithm
- Space participation increases Gravity scores
- Ritual engagement reshapes Cluster mapping
- All behaviors contribute to Role classification

## 15. Implementation Success Criteria

A successful HIVE platform implementation must satisfy these criteria:

### 15.1 All Platform Layers
- Student energy and motion visible throughout system
- No likes, comments, or vanity metrics
- Lightweight participation with meaningful impact
- Motion-based identity over self-declaration
- WCAG AA compliance throughout

### 15.2 Cross-Component Integration
- Feed effectively surfaces Space and Event activity
- Profile authentically reflects system-wide participation
- Rituals reshape Feed, Spaces, and cultural patterns
- Cold start resilience across all components
- Student-led evolution visible in all features 