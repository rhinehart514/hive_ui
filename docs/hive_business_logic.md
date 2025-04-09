# HIVE Platform Business Logic Architecture

## Overview

This document defines the complete business logic architecture of the HIVE platform at launch and throughout its evolution. HIVE is not just a student events app—it is a purpose-built, adaptive platform designed to structure, govern, and amplify student life across campuses, blending social experience, infrastructure design, and data value capture.

This architecture articulates the rules, behaviors, permissions, identity models, engagement economics, governance structures, and data handling principles that the HIVE platform enforces in both its current and future states. These logic systems are embedded across the frontend, backend, data layers, and institutional integrations.

## I. Identity Tiers & Role Governance

### Role Types

| Role | Description | Access Level |
|------|-------------|--------------|
| **Public** | Anyone who downloads the app or accesses the platform | Can view public events and explore Spaces but has no creation or management rights |
| **Verified** | A user verified as an active student at a participating university | Gains full access to the platform's social and participatory functions |
| **Verified+** | A student leader or organizational officer | Manages one or more official campus clubs, groups, or Spaces |
| **Admin** | HIVE Staff member with system maintenance privileges | Platform-wide controls, overrides, and moderation capabilities for platform integrity |

### Role Rules

- Role determines access, visibility, creation privileges, and weight of engagement signals
- Role assignment is validated through either institutional linkage (SSO, registrar APIs) or verified club leadership claim protocols
- Role upgrades are governed by secure, auditable workflows
- Feature access is strictly role-bound
- Role state is immutable without verification protocol

### Federated Future Support

- Role definitions are scoped per institution (multi-tenant structure)
- Role inheritance is layered—users may have Verified+ in one Space, and basic Verified status elsewhere
- Institution-specific role requirements and validation methods are configurable

## II. Role Upgrade Mechanisms

### Public → Verified

**Trigger:** Email verification, university SSO, or institutional authentication

**Steps:**
1. User initiates verification via onboarding or profile settings
2. System validates email domain, authenticates via SSO, or links user ID with institution record
3. Success = role upgrade to Verified; failure = fallback to Public

**Outcome:** Gains ability to join Spaces, RSVP to events with memory, and receive personalized feeds

**Future-Safe Considerations:**
- Must support SAML, OAuth2, and institution-specific APIs
- Abstract verification flow to plug into different university systems
- Track verification source and timestamp to build trust metrics

### Verified → Verified+

**Trigger:** Applies to lead/manage a Space or claim organizational ownership

**Workflow:**
1. User submits claim via Space creation flow or Club Join Request
2. System presents organization list (auto-populated or manually created)
3. User submits proof of leadership (e.g., .edu email + leadership role evidence)
4. Backend routes request to:
   - Automated verification (if rules pre-defined)
   - Manual approval queue (fallback for edge cases)
5. Once approved, user gains admin capabilities over Space-linked content

**Logic Constraints:**
- One user can manage multiple Spaces, but role inheritance is scoped
- Verified+ status can be lost if the leadership term ends or abuse is detected
- Disputed claims initiate an escalation workflow with override options for institutional stakeholders
- Spaces may have more than one Verified+ admin; roles should be tiered (Owner, Admin, Contributor)

**Future-Safe Considerations:**
- Add organizational verification APIs or campus chapter registries
- Track claim history and allow escalation workflows (e.g., disputes over control)
- Enable audit trails and Space admin management logs
- Build override logic for institutional overrides in rare cases

## III. Spaces: Social Infrastructure Layer

Spaces are the backbone of content creation, engagement tracking, and visibility mapping.

### Firestore Implementation
- Spaces are stored at: `spaces/{spaceType}/spaces/{spaceID}`

### Space Types

1. **Student Organizations (`student_org`)**
   - Formal student organizations
   - Department or university-sponsored groups

2. **University Organizations (`uni_org`)**
   - Official university departments and programs

3. **Campus Living (`campus_living`)**
   - Dorms and housing groups
   - Living-learning communities

4. **Fraternities & Sororities (`fraternity_sorority`)**
   - Greek life organizations

5. **HIVE Exclusive (`hive_exclusive`)**
   - Interest-based collectives created within HIVE
   - User-generated community spaces

6. **Other (`other`)**
   - Temporary or event-specific groups
   - Miscellaneous community spaces

### Space Origin & Creation Rules

- **Pre-seeded Spaces** (student_org, uni_org, campus_living, fraternity_sorority)
  - Created by HIVE staff before launch
  - Automatically populated via institutional data
  - Not deletable by users
  - Require Verified+ claim process for management
  - Can be auto-updated via RSS feeds from institution

- **User-Created Spaces** (hive_exclusive, other)
  - Created by Verified users
  - Fully managed by creators
  - Can be deleted by Verified+ members

### Space Lifecycle

```
Created → Active → Dormant → Archived
```

- **Created**: Space established, awaiting content/events
- **Active**: Recent events or user interaction
- **Dormant**: No activity for 30+ days
- **Archived**: Manually or systemically locked, read-only

### Core Rules

- Users must be affiliated with a Space to create events
- Space creation is open to Verified users, but verification is required for full feature unlock
- Dormancy is automatically triggered after periods of inactivity
- Spaces are the minimal unit of group identity
- No anonymous or ad-hoc event creation
- All user-generated content must anchor to a Space

### Space Features

- Role-based admin tiers (Owner, Admin, Editor, Viewer)
- Internal analytics, event history, and Space health tracking
- Customizable visibility and join settings
- Event creation and management tools
- Member communication channels

### Space Governance

#### Roles Within Spaces

- No single owner; all control is via Verified+ role
- Verified+ required for:
  - Editing metadata
  - Creating events
  - Using Boosts/Honey Mode
  - Managing membership
- Member: Participation rights (must be Verified)
- Follower: Receives updates (any role)

#### Leadership Claim Process

- Leadership claims for pre-seeded spaces must be manually approved by HIVE staff
- Claim status tracked as "unclaimed" | "pending" | "approved"
- Future implementation will include role history, admin logs, and verified+ audit trails

#### Visibility Rules

- Pre-seeded: Always public
- HIVE-exclusive: Public or private (invite-only)
- All Spaces are search indexed regardless of visibility or type

#### Membership Mechanisms

- Only Verified users can join Spaces
- Verified+ manages member list, invites, and moderation
- Open: Anyone can join
- Approval: Join requests require approval
- Invitation: Join by invitation only
- Restricted: Institutional controls (e.g., department Spaces)
- Membership tracked for personalization and analytics

#### Space Metadata Structure

```json
{
  "space_type": "enum",
  "origin": "preseeded" | "hive",
  "visibility": "public" | "private",
  "deletable": true | false,
  "rss_feed_source": "url | null",
  "search_indexed": true,
  "claim_status": "unclaimed" | "pending" | "approved"
}
```

#### Event Integration Logic

- All events must belong to a Space
- Pre-seeded Spaces auto-ingest events via RSS feeds
- RSS events:
  - Can be enhanced (media, formatting)
  - Require Verified+ to report attendance manually (for university integration)
- HIVE-exclusive events: manually created, fully editable

#### Activity Requirements

- Inactive Spaces (no events for 30+ days) flagged as dormant
- Abandoned Spaces (no activity for 180+ days) archived
- Reactivation protocol for archived Spaces

#### Moderation Rules

- Verified+ must uphold community standards
- Abuse of permissions triggers role review
- Spaces can be flagged and escalated to HIVE staff or institution

### Future Space Features

- Subspaces for large organizations
- Space health scoring model (based on interaction/activity)
- Role history, admin logs, and verified+ audit trails
- Discovery recommendations (based on user behavior and network)

## IV. Events: Temporal Priority Architecture

Events are the atomic unit of activity in HIVE. Their structure dictates engagement, feed presence, and behavioral memory.

### Event Types

1. **One-time Events**
   - Standard single occurrence events

2. **Recurring Events**
   - Weekly, monthly, or custom patterns
   - Persistent series with individual instances

3. **Multi-day or Series-based Events**
   - Extended duration events
   - Related events grouped as a series

4. **Collaborative Events**
   - Multi-Space sponsored events
   - Cross-organizational collaborations

### Event Lifecycle

```
Draft → Published → Live → Completed → Archived
```

### State Transitions & Rules

1. **Draft**
   - Editable by Space owners/creators
   - Not visible in feeds
   - No time limit in this state

2. **Published**
   - Visible in feeds according to visibility algorithm
   - Limited edits allowed (description, details)
   - Core details locked (time, date, location)
   - RSVP collection active
   - Changes to Published events are versioned

3. **Live**
   - Current ongoing events
   - Automatically transitions based on event time
   - Enhanced visibility in feeds
   - Check-in functionality active
   - Cannot be edited unless flagged and approved

4. **Completed**
   - Brief post-event engagement window
   - Attendance records finalized
   - Photos/recap content collection
   - Feedback solicitation period
   - Triggers post-event engagement capture and analytics

5. **Archived**
   - Searchable but not in main feed
   - Analytics and history preserved
   - Template for future events

### Temporal Logic

- Events become active based on their start time
- "Remind Me" buttons activate based on time thresholds
- Feed prioritization changes dynamically based on time proximity
- Recurring events maintain presence with dynamic visibility
- Post-event visibility window of 12 hours for engagement

## V. Feed System: Dynamic Attention Economy

The main feed acts as a ranked, personalized stream of high-relevance campus activity, serving as the central surface of the HIVE platform. It functions as the dynamic, personalized, and context-aware discovery layer that connects students with live campus activity, event opportunities, and emerging campus culture.

### Feed Purpose & Philosophy

- Acts as the pulse of student life
- Activates passive users through ambient belonging
- Empowers Verified+ users to amplify their events
- Creates a daily rhythm of relevance, trust, and curiosity
- Surfaces campus dynamics without overwhelming or fragmenting
- **NOT chronological** — intentional visibility algorithm informed by behavioral cues, cultural context, and system rules

### Core Feed Components

#### 1. Signal Strip (Top-of-Feed Cards)
- Horizontally-scrollable strip that sets the tone, signals activity, and provides narrative framing
- Cards curated by platform logic and updated daily
- Example card types:
  - "Last Night on Campus"
  - "Top Event Today"
  - "Try One Space"
  - "Chaos Pulse" (Hivelab activity teaser)
  - "Underrated Gem: This event blew up unexpectedly"
- Purpose:
  - Establish campus rhythm
  - Provide cultural context
  - Tease feedback & experimentation (future UGC)

#### 2. Ranked Event Cards
- Events form the core stack of the feed, including:
  - Native Events (created by Verified+ users)
  - Boosted Events (manually elevated by Verified+)
  - Honey Mode Events (1/month highlight slot per org)
  - Reposted Events (re-shared with student commentary)
- Support overlay enhancements:
  - "Your friend RSVPed"
  - "Popular with students in your major"
  - "First-time event from this club"

##### Event Card UX Variants

| Card Type | Visual Treatment |
|-----------|------------------|
| **Standard Card** | Title, time, location, RSVP button, club tag |
| **Boosted Card** | Highlight badge, momentum graph sparkline |
| **Honey Mode Card** | Spotlight border, enhanced image focus, motion feedback |
| **Reposted Card** | User handle/quote if available, soft social stamp |
| **Low RSVP Card** | "Just getting started" hint to boost curiosity |
| **Last-Minute Card** | Countdown visual + urgency CTA |

#### 3. Discovery Prompts
- Feed-integrated recommendations shown contextually:
  - Space Suggestions: For students with no active Spaces
  - Friend Suggestions: Based on shared RSVPs or Space affiliations
  - "Try One" CTA: Nudge for lightweight joining behavior

#### 4. Hivelab FAB
- Persistent Floating Action Button (FAB) for anonymous feedback:
  - Bug 🐞
  - Feature 🛠
  - Chaos 🗩️
- Supports:
  - Continuous listening and sentiment collection
  - Cultural intelligence and vibe mapping
  - Future UGC surfacing and experimentation

### Scoring System Inputs

- RSVP volume and velocity
- Reposts and boosts
- Verified+ endorsements
- Engagement ratios (views-to-clicks)
- Time until event begins (urgency score)
- Personal proximity (past behavior, followed Spaces)
- Role-weighted interactions (student leader vs. casual student)
- Content freshness (newer content ranks higher)

### Feed Logic

- Feed is not chronological—it is weighted, adaptive, and responsive to student behavior
- Some events may be hard-coded for high visibility (admin override, institutional highlight)
- Cold-start content is rotated in for discovery
- Events gain prominence 48 hours before start time
- All Spaces guaranteed minimum visibility
- New Spaces receive temporary visibility boost
- Low-engagement content gradually deprioritized, not hidden

### Feed Modes

- Default (For You)
- Trending / Near You
- Smart Filters (recurring, sponsored, club-based)

### Fairness Mechanisms

- All Spaces guaranteed minimum visibility
- New Spaces receive temporary visibility boost
- Low-engagement content gradually deprioritized, not hidden
- "Cold start" protections for new events/Spaces
- Some events (campus-wide, sponsored, critical mass) are forcibly elevated

### Integrity Controls

- Repost caps: Only one reposted version of a given event is shown per user
- Boost decay: Boosted visibility expires unless momentum is sustained
- Feed rotation: New orgs and events get visibility slots regardless of volume
- Honey Mode enforcement: One active Honey event per org per month

### Temporal Logic

#### Daily Rhythms
- Feed changes subtly across time-of-day:
  - Morning: Focus on RSVP conversions
  - Afternoon: Trending and repost-heavy
  - Evening: Reflection via signal cards + last-minute events

#### Seasonal Modes (Future)
- Quiet Weeks: Inject calm narratives ("Everyone's in finals mode")
- Launch Weeks: Heavier promo of new clubs/events
- Move-In/Club Rush: Event density + Space discoverability

### Strategic Outcomes by User Type

| User Type | Feed Outcome |
|-----------|-------------|
| **Passive Student** | Gains ambient awareness, low-pressure entry into engagement |
| **Curious Lurker** | Sees cultural signals and potential Spaces to explore |
| **Verified+ Leader** | Sees visibility impact, understands momentum, optimizes timing |
| **Club Rookie** | Gets rotation-based visibility despite no legacy status |

### Future Evolvability

- Feed tabs (Personal / Trending / Hivelab) as usage grows
- Experimental UGC surfacing within curated Signal Cards
- Event threads or micro-reactions scoped by Space
- Cross-campus signal blending for federated features
- Reputation scoring for Verified+ content consistency

## VI. Visibility Systems: Boosts, Honey Mode, and Prioritization

### Boost System

**Definition:** Manual visibility nudge that temporarily increases content prominence in feeds. Each Space has limited boosts available per week/month.

**Rules:**
- Limited to Verified+ accounts only
- Weekly quota enforced
- Cooldowns clearly indicated in UI
- Boost effects are time-boxed
- History of boosts is logged and auditable

### Honey Mode

**Definition:** Premium visibility state activated once per month per Space. Includes enhanced UI treatment (highlighted card, animation, pinning) and top-tier feed positioning.

**Rules:**
- Once-per-month per Space limitation
- Requires event to meet minimum enrichment standards (media, call-to-action)
- Honey Mode opt-in must include justification or content enrichment
- Enhanced UI treatment clearly distinguishes these events
- Effects last for limited duration based on event type

### Priority Enforcement

- All visibility tools are time-boxed and logged
- Visibility enhancements are integrated into feed scoring
- Tools do not override moderation or institutional veto logic
- UI clearly indicates boosted/honey mode content to maintain transparency
- System prevents abuse through rate limiting

## VII. Interaction Memory & Personalization Engine

All user actions create a persistent interaction memory that informs personalization.

### Tracked Actions

- RSVP decisions and patterns
- Content reposts and sharing
- Profile taps and views
- Event card expansions (indicating interest)
- "Remind Me" toggles
- Space follow/unfollow
- Check-ins and attendance

### Application

- These actions power both algorithmic personalization and reputation systems
- Used to generate personalized feed scores
- Feeds evolve over time based on this memory
- Repeated behaviors build implicit preference clusters
- Over time, user engagement history will inform:
  - Suggested events in the feed
  - Space recommendations
  - Priority boosts for content
  - Personalized notifications and reminders

### Decay & Refresh

- Interaction weight fades over time
- Periodic resets or re-weighting ensure adaptability
- Recent interactions have stronger weight than historical ones
- System accommodates changing interests and affiliations

## VIII. UI Principles: Role Parity Enforcement

### Core Rule

- All users, including Verified+ leaders, interact through the same interface
- No separate admin dashboards or CMS-style portals
- Management capabilities are contextually embedded in the standard interface

### Rationale

- Maintains cohesion across users
- Prevents separation between leaders and members
- Promotes humility and parity in leadership roles
- Ensures leadership understands the standard user experience
- Simplifies codebase and maintenance

### Implementation

- Role-specific controls are layered into the general UI
- Additional controls (e.g., manage event, boost) appear only where relevant
- UI elements dynamically adapt to user role
- Complex administrative functions are progressive disclosures rather than separate interfaces

## IX. Governance & Moderation Logic

### Moderation Layers

1. **Community Reporting**
   - User-initiated flags and reports
   - Space-level content moderation by owners

2. **Automated Moderation**
   - Auto-flagging via keyword and behavior triggers
   - Pattern recognition for problematic content

3. **Institution-level Moderation**
   - Campus administrator review
   - Policy enforcement mechanisms

### Escalation Process

1. **Step 1:** Community flags → soft-hide
2. **Step 2:** Manual review by moderators
3. **Step 3:** Space or platform-level consequences (content takedown, role revocation)

### Moderation Capabilities

- Space-level content policies
- Report mechanism for policy violations
- Multi-level review process
- Graduated enforcement actions

### Enforcement Actions

- Content removal
- Temporary restrictions
- Role revocation
- Space suspension

### Verified+ Conduct Rules

- Leaders must maintain a reputation score
- Abuse of Boosts, spam, or misrepresentation leads to penalties
- Verified+ status can be suspended or revoked

## X. Firestore Rule Architecture

### Enforcement Dimensions

- Document-level role checks
- Collection-level create/read/write/delete (CRUD) gates
- Timestamp-based mutation prevention
- Scoped reads (e.g. can only view data from Spaces you belong to)
- Role validation on all write operations
- Ownership verification for management actions
- Rate limiting for abuse prevention
- Collection-level creation rights
- Temporal gating (e.g., cannot modify a Live event post-deadline)
- Role-scoped queries (prevent unauthorized data visibility or writes)

### Admin Logic

- Centralized policy config file governs rule sets
- Logs of all elevated actions (e.g. boosts, deletions)
- Redundancy for auditability and emergency overrides

### API Constraints

- Consistent permission checking
- Input validation and sanitization
- Audit logging for sensitive operations
- Request throttling

### Data Integrity

1. **Validation Requirements**
   - Event times must be future dates
   - Spaces must have valid categories
   - RSVPs cannot exceed capacity limits
   - Profile information must meet format requirements

2. **Consistency Rules**
   - Related data updated atomically
   - Cache invalidation on data changes
   - Event state transitions logged
   - Conflict resolution strategy for offline changes

## XI. Data-as-a-Service (DaaS) Architecture

HIVE's long-term value includes offering structured, privacy-preserving data to universities and organizations.

### Core Rule

- All behavioral data must be structured, queryable, and privacy-preserving

### Data Structure

- Event metadata and performance
- Engagement patterns
- Space health metrics
- Participation trends
- Temporal clustering of student activity
- User-level micro-behaviors (taps, views, dwell time)

### Governance

- Every data point tagged with source, timestamp, and role scope
- Consent flows required for personal analytics
- University-level dashboards scoped to respective tenants

### Ethics & Privacy

- Data must be anonymized before external use
- No sale of personal user data
- Institutional insights are value-aligned (retention, wellbeing, resource allocation)
- Transparent collection with user consent
- Aggregate over individual when possible
- Purpose-limited usage
- Retention policies by data type

### Usage Scenarios

- Institutional insights (admin dashboards - future B2B layer)
- Behavioral modeling for feed optimization
- Space health diagnostics
- User engagement analysis

## XII. Analytics & Insights

### Tracked Metrics

1. **Event Performance**
   - RSVP-to-attendance conversion
   - Growth rate compared to previous events
   - Engagement levels (views, shares, comments)
   - Demographic distribution

2. **Space Health**
   - Active member ratio
   - Event frequency and consistency
   - Growth trends
   - Cross-Space participation

3. **User Engagement**
   - Participation breadth (across Spaces)
   - Consistency of engagement
   - Influence score (effect on others' participation)
   - Content contribution

### Insight Access

- Space owners see Space-level insights
- Users see personal engagement data
- Institutional partners see approved aggregate metrics
- System admins see health monitoring data

### Reporting Capabilities

- Automated weekly summaries
- Trend analysis dashboards
- Engagement anomaly detection
- Comparative benchmarking

## XIII. Integration & Ecosystem Rules

### Calendar Integration

1. **Export Rules**
   - RSVP'd events automatically exportable
   - Recurring events handled as series
   - Updates propagate to external calendars
   - Rich metadata included in exports

2. **Import Rules**
   - Space calendars can import external events
   - Imported events clearly marked
   - Auto-synchronization options

### Notification System

1. **Notification Types**
   - Event reminders (24h, 1h before)
   - Space activity updates
   - Direct interactions (mentions, messages)
   - Administrative alerts

2. **Delivery Rules**
   - User preference controls
   - Quiet hours respect
   - Batching for non-urgent notifications
   - Priority override for critical information

## XIV. Cross-University Federation (Future-Ready Logic)

### Multi-Tenant Foundation

- Each campus = data and access silo
- Users scoped per campus, but can toggle when eligible

### Logic Implications

- Spaces, events, and feeds are bounded by institution unless explicitly federated
- Role assignment is independent per institution
- Federation tools (e.g. regional events, global Spaces) to be layered in modularly

### Implementation Strategy

- Shared authentication but segmented data stores
- Campus-specific customizations and policies
- Optional cross-campus discovery for approved content

## XV. Monetization Logic (Planned)

### Sponsored Events

- Paid elevation in feed
- Must meet enrichment standards
- Clearly labeled and limited to institutional relevance

### Premium Space Tools

- Analytics upgrades
- Content scheduling
- Advanced moderation controls

### Subscription Layer

- Optional for club leaders or institutions
- Unlocks extended DaaS insights and automation

## XVI. Extensibility Framework

### Plugin Model

- Standard interfaces for extensions
- Capability scopes and permissions
- Versioning and compatibility rules
- Review process for new integrations

### API Gateway Rules

- Authentication requirements
- Rate limits and quotas
- Data access constraints
- Documentation standards

## Final Notes

HIVE is more than an events feed or social app—it is a structured campus infrastructure layer for organizing student life, recognizing leadership, and enabling dynamic, participatory networks.

This business logic framework governs every user interaction, system behavior, and long-term strategic capability. It ensures that HIVE scales with clarity, trust, adaptability, and depth—powering a smarter, more connected, and data-enriched student ecosystem. 