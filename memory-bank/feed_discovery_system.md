# HIVE vBETA - Feed & Discovery Algorithm Documentation

_Last Updated: January 2025_  
_Status: Implementation Ready - Core Behavioral Engine_

## 1. System Overview

**Strategic Role:** The Feed is the behavioral narrative superstructure that transforms individual Motion Log data into coordinated campus activity. It serves as the primary interface where students witness, respond to, and participate in campus-wide coordination without traditional social media mechanics.

**Core Philosophy:** "The Feed reflects what's happening across campus - students don't use it to post, they use it to witness, respond, align, and act."

## 2. Feed Architecture - Single Timeline Intelligence

### ✅ What Is the Feed?
The Feed is a vertically scrollable, unified timeline that evolves dynamically based on system triggers and student behavioral patterns. It is:
- **Unified:** One shared timeline for all students
- **Personalized:** Content ordering based on Motion Log and campus context
- **Behavioral:** Surfaces activity, not personal status updates
- **Coordination-Focused:** Designed to facilitate campus-wide action

### 🧱 Content Sequencing Logic

```
FEED ALGORITHM HIERARCHY
├── System-Priority Pins (Always Top)
│   ├── Active Ritual countdown timers
│   ├── Campus-wide emergency notifications
│   ├── Platform announcements and updates
│   └── Seasonal event markers
├── Behavioral Activity Layer (Dynamic Middle)
│   ├── Tool surge detection and surfacing
│   ├── Event RSVP momentum highlighting
│   ├── Builder Tool drops with early traction
│   └── Ritual participation prompts
├── Campus Relevance Weight (Personalized Base)
│   ├── Your dorm activity and events
│   ├── Your major Space activity
│   ├── Your joined Space activity
│   └── Your Ritual participation lineage
├── Seasonal Structuring (Context Layer)
│   ├── Orientation Week emphasis
│   ├── Finals Mode streamlining
│   ├── Break period dormancy
│   └── Campus tradition highlighting
└── Fallback Content (When Activity is Low)
    ├── Campus motion highlights
    ├── Historical Ritual completions
    ├── Seasonal campus information
    └── Platform usage encouragement
```

## 3. Feed Content Types & Mechanics (vBETA Implementation)

### 🔮 Ritual Posts (Core Social Primitive)

**First Light Ritual (Week 2 - vBETA Launch)**
```
RITUAL MECHANICS
├── Activation Trigger: 7 days post-vBETA launch
├── Participation Window: 72 hours
├── Threshold Requirement: 100 student intro posts
├── Content Type: 250-character intro responses
├── Visibility: Private until threshold met, then Feed-surfaced
├── Social Effect: Unlocks emoji reactions, creates first user-generated content
├── Failure Mode: If threshold not met, Ritual extends 24 hours (max 2 extensions)
└── Success Result: Intro posts surface in Feed with emoji reaction capability
```

**Orientation Q&A Ritual (Week 4)**
```
RITUAL MECHANICS
├── Activation Trigger: 14 days post-First Light completion
├── Participation Window: 5 days
├── Threshold Requirement: 50 questions submitted
├── Content Type: Anonymous campus questions
├── Visibility: Questions private, answers surface in Feed once threshold met
├── Social Effect: Creates shared campus knowledge base
├── Moderation: Builder and admin review before Feed surfacing
└── Success Result: Q&A highlights appear in Feed as scrollable answer cards
```

**Invite Ritual (Week 6)**
```
RITUAL MECHANICS
├── Activation Trigger: Individual student action (invite someone to HIVE)
├── Participation Window: When invitee joins and completes First Light
├── Threshold Requirement: Individual completion (no campus-wide threshold)
├── Social Effect: Unlocks connection layer features
├── Connection Features: "Crossed motion with" Feed overlays
├── Profile Enhancement: Shared Ritual lineage display
└── Progression: Early access to Arena/Game features
```

**Arena Opens Ritual (Week 7)**
```
RITUAL MECHANICS
├── Activation Trigger: 21 days post-vBETA launch
├── Participation Window: 48 hours for initial vote
├── Threshold Requirement: 200 votes for Game Ritual selection
├── Content Type: Campus-wide bracket/game selection vote
├── Game Options: "Top Artist," "Best Campus Spot," "Ultimate Study Snack"
├── Social Effect: Live matchup cards in Feed, campus-wide engagement
└── Success Result: Selected Game Ritual launches with daily matchups
```

### 🔨 Tool Motion Posts

**Surge Detection Algorithm:**
```
TOOL SURGE CRITERIA
├── Interaction Velocity: 10+ interactions within 4-hour window
├── Cross-Space Adoption: Tool used in 2+ different Spaces within 24 hours
├── Sustained Engagement: 20+ interactions maintained over 12 hours
├── Builder Impact: Tool from Builder with previous successful placements
├── Seasonal Boost: Enhanced during Orientation and Finals periods
└── Manual Override: Admin can force-surface critical coordination Tools
```

**Tool Motion Feed Cards:**
```
FEED CARD CONTENT
├── Tool Identification: Name or function description
├── Participation Count: Current interaction numbers
├── Space Context: "Moving in [Space Name]" or "Across campus"
├── Interaction Button: Direct Tool engagement from Feed
├── Attribution: Builder name (if they opt-in to attribution)
├── Fork Option: If Tool is remixable and available for forking
└── Time Decay: Cards disappear after 24 hours unless re-surge
```

### 📆 Event Posts

**Event Surfacing Logic:**
```
EVENT FEED PRIORITY
├── RSVP Velocity: Events with rapidly increasing RSVP counts
├── Campus Context: Events relevant to your dorm, major, or joined Spaces
├── Timing Priority: Events happening within next 7 days
├── Social Overlay: "X from your dorm attending" if 3+ shared connections
├── Capacity Alerts: "Nearly full" notifications for limited-capacity events
└── Cross-Space Events: Events posted across multiple Spaces you're in
```

**Event Feed Cards:**
```
FEED CARD CONTENT
├── Event Title and Time
├── RSVP Count and Capacity Information
├── Location and Context Details
├── RSVP Button (opens Event Tool interaction)
├── Social Context: Dorm/major attendance overlay
├── Add to Calendar Shortcut
├── Space Attribution: Source Space identification
└── Builder/Creator Attribution
```

### 🛠️ Builder Tool Drops

**Tool Drop Surfacing Criteria:**
```
BUILDER DROP ALGORITHM
├── Early Traction: 5+ interactions within first 2 hours of placement
├── Cross-Space Interest: Comments or engagement from multiple Spaces
├── Builder Reputation: Previous successful Tool placements by same Builder
├── Innovation Factor: Tools using new or rarely-used Element combinations
├── Community Response: High emoji reaction or positive feedback
└── Manual Community Flag: Students can nominate impressive Tools
```

**Builder Drop Feed Cards:**
```
FEED CARD CONTENT
├── Builder Attribution: "New Tool from [Builder Name]"
├── Tool Function: Brief description of Tool capability
├── Space Context: "Moving in [Space Name]"
├── Early Adoption Metrics: "X students already using"
├── Preview/Interaction Button: Direct Tool access from Feed
├── Fork Availability: If Tool is available for community forking
└── Builder Recognition: Profile link and previous Tool attribution
```

### 👤 Intro Post Cards (Post-First Light)

**Intro Post Surfacing Logic:**
```
INTRO POST FEED ALGORITHM
├── Ritual Completion: Only surfaces after First Light threshold met
├── Diversity Weighting: Ensures representation across dorms, majors, years
├── Engagement Boost: Intro posts with high emoji reaction frequency
├── Temporal Decay: New intro posts prioritized over older ones
├── Connection Context: Prioritize intro posts from students with shared activity
└── Anonymous Option: Students can toggle anonymous intro post display
```

**Intro Post Feed Cards:**
```
FEED CARD CONTENT
├── Student Name or Anonymous Tag
├── 250-Character Intro Response
├── Optional Shared Tags: "CS · Clement Hall · Builder"
├── Emoji Reaction Bar: React-only interaction (no comments)
├── Ritual Attribution: "From First Light Ritual"
├── Time Stamp: When intro was posted
└── Profile Connection: Link to student Profile (if public)
```

### 💬 Q&A Highlights (Post-Orientation Q&A)

**Q&A Feed Surfacing Logic:**
```
Q&A HIGHLIGHT ALGORITHM
├── Community Value: Questions with highest engagement
├── Practical Utility: Campus navigation, academic, social questions
├── Seasonal Relevance: Questions relevant to current campus period
├── Answer Quality: Responses from Builders, staff, experienced students
├── Anonymous Protection: All questions and answers remain anonymous
└── Weekly Curation: Top questions surface in weekly digest format
```

### 🎮 Game Ritual Cards (Post-Arena Opens)

**Game Ritual Mechanics:**
```
GAME RITUAL FEED INTEGRATION
├── Daily Matchups: Bracket-style voting cards surface daily
├── Live Results: Real-time percentage updates and voting counts
├── Campus Engagement: Participation metrics and trending indicators
├── Social Energy: Campus-wide reaction and alignment display
├── Progression Tracking: Bracket advancement and winner prediction
├── Resolution: Final winner announcement and community celebration
└── Seasonal Cycling: New Game Rituals based on campus calendar
```

### 🧭 Campus Motion Highlights

**Campus Activity Summary Cards:**
```
CAMPUS MOTION CONTENT
├── Weekly Activity Summary: "2,174 Tools used · 63 Events launched"
├── Community Recognition: "Top Space: UB Devs · Top Builder: Remi A."
├── Participation Milestones: "500th student joined HIVE this week"
├── Coordination Success: "23 study groups formed · 45 events attended"
├── Platform Growth: "12 new Tools created · 8 Spaces activated"
└── Seasonal Markers: "Finals Week: 89% study Tool usage increase"
```

## 4. Feed Personalization Algorithm (vBETA Implementation)

### 🎯 Personalization Logic Framework

**Campus Context Weighting:**
```
PERSONALIZATION FACTORS
├── Space Membership (40% of Feed weight)
│   ├── Auto-assigned Spaces: Dorm, major, academic
│   ├── Voluntarily joined Spaces: Interests, organizations
│   ├── Builder-managed Spaces: Enhanced visibility for your Tools
│   └── Recently active Spaces: Boosted priority for current engagement
├── Motion Log Analysis (30% of Feed weight)
│   ├── Tool Usage Patterns: Frequently used Tool types prioritized
│   ├── Event Participation: Similar events and RSVPs highlighted
│   ├── Ritual Completion: Access to social layer content
│   └── Builder Activity: Enhanced visibility of Builder ecosystem
├── Temporal Campus Context (20% of Feed weight)
│   ├── Academic Calendar: Finals, orientation, break periods
│   ├── Daily Rhythm: Study time, meal time, social time
│   ├── Weekly Patterns: Weekend vs. weekday content prioritization
│   └── Seasonal Adjustments: Campus tradition and event alignment
├── Social Layer Activation (10% of Feed weight)
│   ├── Connection Overlays: "Crossed motion with" prioritization
│   ├── Invite Lineage: Content from inviter/invitee network
│   ├── Shared Ritual Participation: Common experience highlighting
│   └── Builder Network: Tools from Builders you've interacted with
```

**Cold Start Algorithm (New Users):**
```
NEW USER FEED CONTENT
├── System Space Activity: Campus-wide, New Students 2025 content
├── Default Space Content: Auto-assigned dorm and major Space activity
├── Popular Content: High-engagement Tools and Events from past week
├── Ritual Prompts: Active Ritual participation opportunities
├── Onboarding Content: Platform introduction and usage guidance
├── Template Tools: Showcase of available Tool templates and examples
└── Builder Highlights: Recognition of active Builders and Tool creators
```

## 5. Feed Performance & Technical Implementation

### ⚡ Real-Time Content Processing

**Surge Detection Infrastructure:**
```
TECHNICAL REQUIREMENTS
├── Real-Time Analytics: 5-minute update intervals for Tool interaction tracking
├── Cross-Space Monitoring: Tool usage pattern detection across multiple Spaces
├── Threshold Management: Ritual participation counting and threshold detection
├── Event RSVP Tracking: Real-time RSVP velocity and capacity monitoring
├── Builder Activity Monitoring: Tool placement and early engagement tracking
└── Campus Motion Aggregation: Weekly and daily activity summarization
```

**Feed Generation Pipeline:**
```
FEED REFRESH MECHANICS
├── Individual Feed Refresh: Every 15 minutes during active use
├── Push Notification Triggers: Ritual threshold achievements, surging content
├── Priority Content: Immediate surfacing for time-sensitive Rituals and Events
├── Batch Processing: Campus Motion Highlights generated daily at 2 AM
├── Cache Management: Personal Feed caching with 24-hour expiration
└── Emergency Override: Manual content injection for campus emergencies
```

### 📊 Content Moderation & Quality Control

**Automated Content Filtering:**
```
MODERATION PIPELINE
├── Ritual Content Review: Builder and admin approval before Feed surfacing
├── Anonymous Content Screening: Automated inappropriate content detection
├── Tool Surge Validation: Manual review of high-velocity Tool activity
├── Event Content Verification: Basic event information accuracy checking
├── Community Flagging: Student reporting mechanism for inappropriate content
└── Builder Content Oversight: Enhanced review for Builder-created content
```

## 6. Feed System Governance (vBETA Locked Decisions)

### 🔒 Critical Implementation Decisions Locked:

1. **Unified Timeline Architecture:** Single Feed for all students, personalized by algorithm
2. **Ritual Integration:** Rituals serve as primary social layer activation mechanism
3. **Surge Detection:** Tool and Event surfacing based on engagement velocity
4. **Campus Context Weighting:** Space membership and Motion Log drive personalization
5. **No User-Generated Posting:** Students interact through Tools and Rituals, not direct posting
6. **Anonymous Participation:** Q&A and certain Rituals maintain anonymity
7. **Builder Attribution:** Opt-in Tool creator recognition and community building
8. **Temporal Content Decay:** Most content disappears after 24-48 hours unless re-engaged
9. **Emergency Override Capability:** Admin ability to surface critical campus information
10. **Privacy-First Personalization:** Motion Log data used for curation, not exposure

### vBETA Scope Limitations:

- No complex social graph features or friend recommendations
- No direct messaging or private communication (launches in Invite Ritual unlocks)
- No user profile customization or personal content creation
- No advanced analytics dashboards for students
- Limited Ritual variety (4 core Rituals for vBETA)

### Post-vBETA Evolution Path:

- Advanced behavioral pattern recognition for content curation
- Enhanced Ritual variety and campus-specific customization
- Sophisticated connection layer features and social coordination
- AI-powered content recommendation and campus intelligence
- Cross-campus behavioral analysis and coordination optimization

## 7. Success Metrics & KPIs

### Feed Engagement Indicators
```
CORE METRICS
├── Ritual Participation Rates: Threshold achievement consistency
├── Tool Surge Detection Accuracy: Relevant vs. irrelevant content surfacing
├── Event RSVP Conversion: Feed-to-RSVP click-through rates
├── Campus Motion Engagement: Weekly summary interaction and sharing
├── Content Time-on-Screen: How long students engage with Feed content
├── Cross-Space Discovery: Students joining new Spaces via Feed content
└── Builder Tool Adoption: Tool discovery and forking via Feed exposure
```

### Platform Intelligence Indicators
```
BEHAVIORAL ANALYTICS
├── Motion Log Pattern Recognition: Successful personalization accuracy
├── Campus Coordination Enhancement: Improved event attendance and Tool usage
├── Community Formation: Space activation and sustained engagement
├── Seasonal Adaptation: Feed effectiveness during different campus periods
├── Privacy Compliance: Student data control and transparency maintenance
└── Platform Growth: User retention and engagement sustainability
```

---

**Implementation Priority:** Critical - Core user experience foundation for vBETA
**Dependencies:** Motion Log collection, Ritual orchestration system, Real-time analytics
**Timeline Impact:** 4-5 weeks development for core Feed algorithm and Ritual integration
**Risk Mitigation:** Fallback content strategy for low-activity periods, manual content curation capability

**Final Assessment:** The Feed serves as HIVE's behavioral coordination engine, transforming individual Motion Log data into campus-wide narrative while maintaining privacy and avoiding traditional social media pitfalls. Rituals provide structured social activation without performative pressure. 