# HIVE Platform Business Logic Architecture

## Overview

This document defines the complete business logic architecture of the HIVE platform. HIVE is a student-powered campus layer that reflects the real energy of student life. It gives students psychological control over their experience through dynamic signals, self-organizing communities, and emergent cultural rhythm.

HIVE is built on lightweight actions (RSVPs, reposts, reactions), micro-affiliations (Spaces), and real-time resonance, replacing dead systems of record with a living map of what's alive right now on campus. This architecture articulates the behaviors, states, permissions, identity models, engagement patterns, and governance structures that the HIVE platform enforces.

## I. Platform Grammar & Core Constructs

### Core Constructs

| Construct | Function | Description | Student Relationship |
| --- | --- | --- | --- |
| **Space** | Identity Field | A node of affiliation, community, or orbit | "This is where I belong or observe" |
| **Signal** | Microexpression | A small action with high interpretive value (RSVP, repost, react) | "This matters to me—even if I don't say why" |
| **Cluster** | Emergent Grouping | A dynamic network formed by behavior overlap (shared follows, same Spaces) | "These are people like me" |
| **Pulse** | Energy Snapshot | A moment or topic that is vibrating through campus | "This is what's hot right now" |
| **Trail** | Memory Thread | A user's evolving footprint through participation and creation | "This is how I got here" |
| **Gathering** | Coordinated Energy | A time-bound event, meetup, or moment | "We're converging around this" |
| **Gravity** | Network Pull | The invisible force that draws users toward certain Spaces or content | "I keep seeing this—it's pulling me in" |
| **Boost** | Signal Amplification | A way to increase visibility or momentum within the network | "This deserves more attention" |
| **Role** | Structural Function | A user's defined position within a Space or cluster (creator, member, observer) | "This is how I show up here" |
| **Vibe** | Social Feel | The soft signal or tone of a Space, post, or event | "This feels like my energy" |

### System Properties

- **Dynamic**: HIVE constantly adapts to real-time micro-behaviors
- **Behavioral-First**: Interaction > intention. HIVE reads what students do *and don't do*
- **Bottom-Up**: Students shape the platform. Admin and others adapt to it, not vice versa
- **Structurally Aware**: HIVE operates on defined constructs like Spaces, Signals, Trails
- **Friction-Responsive**: Every action must lead to feedback. The system acknowledges presence

## II. Student Archetypes & Role Models

### Student Archetypes

| Archetype | Behavior | System Impact | Risk |
|-----------|----------|---------------|------|
| **The Seeker** | Browses, taps, follows—searching for resonance | Creates gravity, drives demand quietly | Leaves if nothing resonates quickly |
| **The Reactor** | Reposts, reacts, responds but rarely creates | Amplifies Pulse, contributes to momentum | Feels invisible if there's no feedback loop |
| **The Joiner** | Joins Spaces, lightly engages, follows cultural flows | Builds participation maps, creates density | Fades into background if not surfaced or acknowledged |
| **The Builder** | Creates Spaces, runs gatherings, generates cultural architecture | Shapes structure, powers growth | Burns out or bounces to other platforms if under-supported |
| **The Lurker-Turned-Leader** | Starts as a passive Seeker, eventually builds | Critical for conversion and resilience | Lost if system doesn't offer progressive empowerment |
| **The Skeptic** | Observes, critiques, distrusts systems | Offers valuable tension, tests legitimacy | Opts out fully if HIVE feels top-down, extractive, or performative |

### Role-Based Logic Modifiers

| Logic Role | Behavioral Pattern | Logic Modifications | System Impact |
| --- | --- | --- | --- |
| **Seeker** | Browses, hovers, rarely acts | Feed prioritizes soft-entry content; nudges to React or Follow | Reduces bounce rate; increases chance of alignment |
| **Reactor** | High reactions/reposts, low creation | Feed emphasizes trending content; provides repost feedback loops | Fuels Pulse and social proof loops |
| **Joiner** | Frequently joins Spaces, RSVPs, lightly engages | Receives more Space-based content in Feed; sees highlights from past joined events | Builds Trail depth and participation density |
| **Builder** | Creates content, Spaces, events | Feed gives stronger creator feedback; early access to Boost; Trail visible to others (opt-in) | Drives cultural architecture and loop ignition |
| **Skeptic** | Long-time viewer, no interaction, low trust | Feed shows transparent system messages, peer validation signals, trust-building content | Attempts to earn engagement slowly through proof |
| **Lurker-Builder** | Initially quiet, then transitions to contributor | Trail shows progression; system boosts early content; Feed nudges others to follow | Converts latent energy into system-building force |

## III. Identity Tiers & Permissions

### Identity Access Tiers

| Tier | Profile Surface | Interaction Permissions |
| --- | --- | --- |
| **Public (non-.edu)** | No Profile | View-only Feed access |
| **Verified (.edu)** | Private Profile | Full interaction: Join, Drop, Repost, RSVP, Create Spaces |
| **Verified+** | Public Profile | Builder permissions: Events, Boosts, Rituals, Feed surfacing |

### Profile Structure By Tier

#### Verified (Private)
- Display name (optional)
- Account status: "Verified Student"
- Activity Summary (soft Trail)
- Spaces You're In (toggleable)
- "Your Motion" (visible to self only)
- Privacy settings

#### Verified+ (Public)
- Name + blue check
- Role badge (e.g., "Builder of UB Creatives")
- Builder Stats
- Motion Preview
- Pinned Motion (optional)
- Public Badge Slot (if earned from Ritual)

### System Triggers & Profile Effects

| Action | Profile Effect |
| --- | --- |
| Create Space | "Builder of..." status visible |
| Host Event | "Hosted [Event]" added to Activity |
| Join Ritual | "Participated in [Ritual]" logs privately |
| Earn Badge | Badge appears in profile slot |
| High motion | Profile may be suggested in Feed or Clusters |

## IV. Core Behavioral Logic

### Behavior Logic: `Join Space`

| Field | Description |
| --- | --- |
| **Trigger** | User taps "Join" on a Space or accepts an invite |
| **Immediate Effect** | User added to member list, system logs source and time |
| **System Logic** | Increases Space gravity; adjusts feed weight; logs join trail; triggers visibility if thresholds are met |
| **Signal Type** | Affiliation Signal |
| **State Transitions** | User becomes Member; Space may become Live if dormant |
| **Visibility** | Visible to Space leaders; may show in Trail or Feed depending on privacy |

### Behavior Logic: `React`

| Field | Description |
| --- | --- |
| **Trigger** | User taps a quick emoji or lightweight reaction on a post or Pulse |
| **Immediate Effect** | Registers micro-signal; contributes to Pulse heat and post visibility |
| **System Logic** | Adds behavioral weight to the content; increases feed visibility based on cumulative reactions |
| **Signal Type** | Expression Signal |
| **State Transitions** | Content may move from cold → warm → hot states |
| **Visibility** | Anonymous or semi-anonymous (aggregate only); creator sees reactions; system logs patterns |

### Behavior Logic: `Repost`

| Field | Description |
| --- | --- |
| **Trigger** | User shares content to their own network or profile feed |
| **Immediate Effect** | Content appears in follower/peer feed with original attribution |
| **System Logic** | Increases content's reach and social validation weight; links repost to reputation graph of user |
| **Signal Type** | Alignment Signal |
| **State Transitions** | Post may enter trending Pulse or receive momentum flag |
| **Visibility** | Public; included in Trail; visible in shared feed and post analytics |

### Behavior Logic: `Create Space`

| Field | Description |
| --- | --- |
| **Trigger** | User initiates a new Space with title, tags, and optional structure |
| **Immediate Effect** | Space is added to system index; creator becomes default admin |
| **System Logic** | Requires threshold (e.g., 3 joins) before appearing publicly; system checks tag uniqueness and quality risk |
| **Signal Type** | Ownership / Identity Formation Signal |
| **State Transitions** | Space goes from Hidden → Seeded → Live based on join activity and post frequency |
| **Visibility** | Private at first; becomes public upon reaching thresholds |

### Behavior Logic: `Pulse`

| Field | Description |
| --- | --- |
| **Trigger** | Multiple reactions/reposts in short time frame around the same content or idea |
| **Immediate Effect** | Creates a visual feedback loop for trending content; flags the post or Space for broader surfacing |
| **System Logic** | Heat thresholds determine Pulse classification (micro, local, global); Pulse decay over time unless sustained |
| **Signal Type** | Energy Signal |
| **State Transitions** | Cold → Warm → Pulse (Trending) → Faded |
| **Visibility** | Visible in Feed; may generate push notifications depending on settings |

### Behavior Logic: `Boost`

| Field | Description |
| --- | --- |
| **Trigger** | Admin/leader chooses to highlight post or event |
| **Immediate Effect** | Boosted content surfaces at top of Feed and is visually distinguished |
| **System Logic** | Limited uses per time period (scarcity model); requires minimum engagement before eligibility |
| **Signal Type** | Priority / Leadership Signal |
| **State Transitions** | None, but affects Pulse speed and Feed position |
| **Visibility** | Public; visibly labeled as Boosted |

### Behavior Logic: `Drop`

| Field | Description |
| --- | --- |
| **Trigger** | User adds 1-line post inside a Space |
| **Immediate Effect** | Content appears in-thread; flags Space as active; notifies participants optionally |
| **System Logic** | Increases Space activity score; may extend Pulse if engagement follows |
| **Signal Type** | Participation Signal |
| **State Transitions** | May move Space from Dormant → Active |
| **Visibility** | Public within Space; visible in Trail |

### Behavior Logic: `Gather` (Events)

| Field | Description |
| --- | --- |
| **Trigger** | User initiates an event or gathering |
| **Immediate Effect** | Event published to Feed or Space; RSVP available; system tracks engagement |
| **System Logic** | Supports RSVP tracking, activity prediction, Trail entry; requires contextual info (time/place/host) |
| **Signal Type** | Mobilization Signal |
| **State Transitions** | Draft → Announced → Live → Archived |
| **Visibility** | Public in Feed; private in invite-only mode |

## V. System States & Lifecycle

### Space States

| State | Trigger | Effect | Notes |
| --- | --- | --- | --- |
| `Seeded` | Space is created, 0–2 members | Not publicly listed; only accessible via invite or link | Default private mode |
| `Forming` | 3–10 members joined or 1 post made | Visible in Feed via Joiner's graph; soft searchable | Early alignment phase |
| `Live` | 10+ members and consistent activity | Fully public and discoverable; contributes to Gravity | Eligible for Boosts and Feed surfacing |
| `Dormant` | No activity in 14+ days | Feed and search visibility reduced; owner notified | Can reawaken with 1+ contribution |
| `Legacy` | Archived by creator or auto-faded | Trail-only visibility; not discoverable | Preserves historical footprint |

### Pulse States

| State | Trigger | Effect | Notes |
| --- | --- | --- | --- |
| `Cold` | Initial post or low engagement | Appears only in local Feed | Needs amplification to grow |
| `Warming` | 3+ Reactions or 2+ Reposts in short window | Begins surfacing to Clusters | Temperature tracked over time |
| `Hot (Pulse)` | 10+ reactions/reposts in short burst | Feed priority across network; Pulse label appears | Triggers Gravity spikes |
| `Cooling` | Engagement slows > 8h | Feed weight decreases; visible only to Cluster members | Graceful decay logic |
| `Faded` | No engagement for 24h+ | Archived to Trail if part of meaningful moment | Soft memory, not deletion |

### Event States (`Gather`)

| State | Trigger | Effect | Notes |
| --- | --- | --- | --- |
| `Draft` | Created, not yet shared | Only visible to creator or co-organizers | Can be edited freely |
| `Announced` | Shared to Feed or Space | Feed + calendar listing begins; open RSVP | Activity triggers Trail entries |
| `Live` | Within 1h of start time | Real-time Feed prioritization | Syncs with notifications if enabled |
| `Concluded` | End time passed | Feedback prompts issued; archived to Trail | Boost ends automatically |
| `Highlight` | Receives post-event activity | Converted into Pulse thread or Gallery | Used to extend memory cycle |

## VI. Core System Layers

### Discovery Layer

This layer enables students—especially unaffiliated, passive, or socially tentative users—to see, sense, and align with what's happening around them on campus. It surfaces motion, not content.

#### Core Surfaces
- Feed (Main Scroll)
- Feed Strip (Top band, horizontally scrollable)
- HiveLab (via ritual cards embedded in strip)
- Passive Trail memory + Cluster motion triggers

#### Discovery Mechanics
1. **Repost & Quote Flow**
   - Peer reposts elevate Feed presence
   - Quote = micro-authorship, creates narrative layer

2. **Friend Motion Cards**
   - "Someone you know RSVPed" → passive trust layer
   - Cluster-based, not based on follow graph

3. **Curiosity Memory**
   - System tracks taps, lingers, and revisits
   - Adds low-weight entries to user Trail
   - Powers silent resurfacing in Feed

4. **Space Suggestions**
   - Based on Trail overlaps, cluster motion, rituals joined
   - One-tap join, visible in main Feed

5. **Ritual Strip Prompts**
   - Emotional, low-barrier entry into the system
   - Participation reshapes Feed, triggers affinity loops
   - Always 1 active ritual (campus-wide or micro)

### Affiliation Layer

This layer governs how students align with identity structures inside HIVE—not through bios, chats, or forms, but through lightweight behavioral signals.

#### Key Behaviors & Surfaces
| Surface | Behavior | System Effect |
| --- | --- | --- |
| Feed Suggestion | Tap / linger | Adds curiosity weight; triggers Observer |
| Join Button | Tap | Adds Member status; Trail + Gravity start |
| Join Button | Long-press | Adds to Watchlist; soft affiliation |
| Space Content | Repost / RSVP | Triggers Active tier |
| Reaffirmation Strip | "Still vibing?" | Adjusts Trail/Gravity based on response |
| Feed Echo | Multiple Space taps | Suggests formal Join / Watch |

#### Invisible Tiered Affiliation
| Tier | Trigger | Meaning |
| --- | --- | --- |
| Observer | 3+ passive touches (taps, lingers, hovers) | Curiosity detected |
| Member | Taps Join | Starts Trail + Feed/Space weighting |
| Active | Posts, RSVPs, rituals inside Space | High Gravity; shown in Builder Dashboard |
| Dormant | 14+ days inactivity | Downweighted affiliation |
| Dropped | 21+ days no action or ritual "Ghosted" | Trail archived; removed from weighting |

### Participation Layer

This layer defines how students take visible actions within HIVE through lightweight, expressive, and consequential behaviors.

#### Supported Participation Types
| Action | Description | Location |
| --- | --- | --- |
| **Drop** | 1-line post inside a Space. No replies. | Space |
| **RSVP** | Tap to attend an event. | Feed / Event |
| **Repost** | Share content to Feed. | Feed / Space |
| **Quote** | Repost with a 1-line comment. | Feed / Space |
| **Vote** | Tap to respond to a poll. | Space |
| **Boost** | Highlight a Drop to top (Builder-only). | Space |
| **Watch** | Soft-follow a Space or event. | Feed / Space |
| **React** | Tap-to-signal interest (e.g. 🔥 👀). | Feed (optional) |

#### Card Lifecycle Logic
| Card Type | Default Lifespan | Extensions |
| --- | --- | --- |
| Drop | 48h | Boost +24h; Quote +12h |
| Event | Until start time | RSVP resets decay window |
| Poll | Set by Builder | Votes extend visibility |
| Quote | 24h | Requotes add time |
| Boosted Card | 6h pinned | One boost per post |

### Creation Layer

This layer defines how new objects — Spaces, Events, and Rituals — are introduced into the system.

#### Objects That Can Be Created
| Object | Who Creates It | Surface | Purpose |
| --- | --- | --- | --- |
| **Space** | Any student | Feed → Space Tab | Starts a new affiliation node |
| **Event** | Builder only, or auto-promoted Drop | Inside Space | Creates group convergence |
| **Ritual** | Builder (inside HiveLab) | HiveLab → Feed | Social interaction scaffolding |

#### Space Creation Flow
- "Name it. Tag it. Done."
  - Inputs: Space name, 1-2 tags from system library
  - Optional: 1-liner description, emoji or logo

#### Event Creation Flow
- **Builder-Initiated Event**: Tap "Create Event" inside a Space
  - Inputs: Title, Time, Location, Optional context
- **Event-As-Post**: 
  - A student Drops: "movie night @ 8pm, my place"
  - 3+ people tap "Going?" → System auto-converts Drop to Event

#### Ritual Creation
- Created inside HiveLab by Builders
- Limited-time, participation-based
- Results feed back into Feed → triggers motion

## VII. Core Logic Modules

| Module | Function | Operates On | Outputs To |
| --- | --- | --- | --- |
| **Feed Engine** | Personalizes and curates Feed based on behavior, clusters, and recency | Roles, Gravity, Reposts, Pulses | Feed UI, visibility weights |
| **Pulse Engine** | Detects surging content; tracks energy peaks and decays | Reposts, Reactions, Time | Feed, Notifications, Pulse State |
| **Gravity Engine** | Calculates directional interest between users, Spaces, and content | Repeat views, soft taps, latent behavior | Feed weight, Cluster edges |
| **Trail Engine** | Maintains memory record and generates summarizations | Contributions, RSVPs, Joins | Trail display, Feedback loops |
| **Role Engine** | Interprets behavioral patterns to infer archetype roles | Engagement frequency, action mix, time decay | Feed filters, nudge logic |
| **Space Lifecycle Engine** | Governs transitions from Seeded → Live → Dormant | Joins, posts, decay timers | Visibility indexing, search scope |
| **Moderation Engine** | Handles trust, safety, low-signal detection | Flags, post velocity, reports | Visibility throttling, prompts, shadow actions |
| **Cluster Engine** | Maps behavioral overlap into dynamic social groups | Shared follows, repost chains, Spaces | Feed personalization, suggested content |
| **Memory Engine** | Surfaces legacy content, throwbacks, or historical echoes | Trail patterns, dormancy, timing | Feed highlights, Trail popups |

### Module Execution Modes

| Module | Execution Mode | Rationale |
| --- | --- | --- |
| Feed Engine | Real-Time | Needs to reflect user actions immediately |
| Pulse Engine | Real-Time | Pulse windows are short-lived; must respond quickly to surges |
| Gravity Engine | Hybrid | Immediate reaction to some behaviors, batch recalibration nightly |
| Trail Engine | Batch | Evaluated hourly/daily; used for summary and reflection |
| Role Engine | Batch | Inferred over time through behavior windows |
| Space Lifecycle Engine | Batch | Space state transitions based on multi-day activity decay |
| Moderation Engine | Hybrid | Flagging is instant; visibility throttling may queue or delay |
| Cluster Engine | Batch | Cluster calculations run periodically; affects Feed in next cycle |
| Memory Engine | Batch | Triggered by calendar/time logic; no real-time user impact |

## VIII. Implementation Guidelines

### Moderation Scaffolding

| Role | Permissions | Notes |
| --- | --- | --- |
| **System (Backend)** | Auto-detection of spam, abuse, bot behavior | Can soft-remove content, throttle reach, issue shadow warnings |
| **Space Admins (Student Leaders)** | Flag posts, hide from Space view, issue soft warnings | Cannot delete users or posts from system; visibility scoped to Space |
| **Peer Moderators (Optional)** | Earned role through contribution + feedback | Trusted to guide tone, not enforce rules |

### Moderation Actions

| Action | Who Can Trigger | Effect | System Design Notes |
| --- | --- | --- | --- |
| `Flag Post` | Any user | Sends signal to backend moderation queue | Multiple flags increase urgency |
| `Mute User` | Space Admin | Hides content in that Space only | Does not notify user; reversible |
| `Shadow Throttle` | System | Temporarily reduces content reach | Used for spam-like behavior |
| `Soft Ban (Local)` | System | Prevents access to specific Spaces temporarily | Triggered by repeated abuse, not visible to other users |
| `Feedback Prompt` | System | Encourages user to revise or rethink content | Trust-building over policing |

### Feed Components

1. **Feed Strip (Top-of-Feed Cards)**
   - Horizontally-scrollable strip that sets the tone, signals activity
   - Example cards: "Last Night on Campus", "Top Event Today", "Try One Space"

2. **Main Feed Cards**
   - Event Cards: Standard, Boosted, Reposted
   - Space Suggestions based on behavior
   - Friend Motion Cards showing social proof
   - Ritual Cards for participation

### UX Design Principles

- Every participation option is 1-step max
- No modals with >1 input
- No threading, replies, or infinite comments
- Participation creates modular cards, not content streams
- System must visibly respond (card moves, Feed changes, Strip updates)

## IX. Data Structures & Firestore Implementation

### Trail Summarization Logic

The Trail system tracks a student's progression through HIVE as a narrative of participation.

#### What a Trail Includes
- Spaces Joined with join date and re-visit frequency
- Events Attended with optional highlight recap
- Posts Created linked to role evolution
- Reposts / Reactions for engagement signal volume
- Roles Held (Builder or moderator status)

#### Summarization Logic
| Trigger | Summary Type | Output |
| --- | --- | --- |
| Monthly Engagement | Trail Recap | "This month you joined 2 Spaces, attended 3 events, and reposted 6 items." |
| Role Transition | Progression Milestone | "You've grown from a Joiner to a Builder. You've now created 3 Spaces." |
| Dormant Reentry | Highlight Throwback | "Welcome back. You last posted 46 days ago in [Space]." |
| Milestone Moment | Culture Recognition | "100 reactions received on your contributions – students are resonating with your energy." |

### Profile Data Model

```json
{
  "userId": "user789",
  "handle": "@laney",
  "displayName": "Laney Thompson",
  "avatarUrl": "...",
  "status": "verified+",
  "bio": "Sometimes outside",
  "spaces": ["space123", "space456"],
  "builderOf": ["space123"],
  "trail": {
    "drops": 6,
    "events": 3,
    "promptsVoted": 4,
    "quotes": 2
  },
  "badges": ["campus_madness_2025"],
  "legacy": {
    "joinedAt": "2025-04-01T...",
    "topDrop": "'film kids are unhinged'"
  }
}
```

### Space Metadata Structure

```json
{
  "spaceId": "abc123",
  "name": "UB Creatives",
  "tags": ["art", "late night", "chaotic"],
  "members": ["user123", "user456"],
  "builders": ["user123"],
  "events": [...],
  "drops": [...],
  "prompts": [...],
  "quotes": [...],
  "state": "live",
  "createdAt": timestamp
}
```

### Pulse Object

```json
{
  "pulseId": "pulse456",
  "sourceCardId": "drop789",
  "level": "hot",
  "decayRate": 0.15,
  "triggerCount": 12
}
```

## Final Notes

HIVE is more than an events feed or social app—it is a structured campus infrastructure layer that reflects the real energy of student life. It doesn't impose structure—it lets structure emerge. It doesn't push events—it surfaces energy. It doesn't design for compliance—it evolves through participation.

This business logic framework governs every user interaction, system behavior, and relationship between components. It ensures that HIVE is built following the core principle: HIVE isn't just built for students. It's authored by them. 