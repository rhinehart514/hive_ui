# HIVE vBETA Product Specification

_Last Updated: January 2025_  
_Status: Development Ready_

## 1. Executive Summary

HIVE vBETA represents a fundamental shift from social network consumption to behavioral platform creation. Students don't scroll feeds—they build Tools, activate Spaces, and create campus infrastructure piece by piece.

**Core Mission:** Give students programmable agency over campus life so they can shape their environment, not just react to it.

**Target Launch:** May 29, 2025  
**Primary Audience:** International students, incoming students, campus builders  
**Platform Evolution:** Weekly Tool drops, summer behavioral learning, fall scale preparation

## 2. Four-System Architecture

### SYSTEM 1: PROFILE — Personal Behavioral Dashboard

**Strategic Role:** The only system every student sees. Must work without social engagement and grows with motion.

**Core Components:**
- **Now Panel** — Dynamic banner summarizing today's activity and campus context
- **Motion Log** — Chronological record of Tools used, Spaces joined, Events RSVP'd
- **Calendar Tool** — Week view combining class blocks, Quiet Hours, Tools, RSVPs
- **Stack Tools** — Self-service behavioral tools (Reminder, Quiet Hours, Focus Timer)
- **Your Spaces** — List of joined, previewed, and auto-assigned Spaces
- **Your Events** — Calendar-integrated event viewer
- **HiveLAB Console** — Appears when user becomes a Builder
- **Builder Card** — Appears when user places a Tool (opt-in visibility)

**Student Value Proposition:**
- Personal productivity dashboard that actually helps with immediate needs
- Campus navigation without overwhelming social pressure
- Behavioral habit formation through Tool usage tracking

### SYSTEM 2: SPACES — Structured Group Containers

**Strategic Role:** Where behavior lives, but only when activated by Builders. Nothing is visible unless someone builds it.

**Fixed Surfaces:**
- **Pinned** — Static intro message (Builder-editable)
- **Posts** — Hidden until activated by PromptPost Tool
- **Events** — Calendar of RSS + Tool-based events
- **Tools** — Stack of placed modules
- **Chat** — Locked for vBETA (ships in patch 0.1.1)
- **Members** — Auto-generated list of joined students

**Space Types & Auto-Assignment:**
- **Residential Spaces** — Auto-join by dorm/housing
- **Academic Spaces** — Auto-join by major/department
- **Cultural/Org Spaces** — Request join or Builder-added
- **Internal/System Spaces** — Admin controlled

**Activation Model:**
- All Spaces launch dormant (no content, no activity)
- Builder must place a Tool to activate any functionality
- Template Tools assist initial activation
- Community is earned through Builder action, not assumed

### SYSTEM 3: HIVELAB — Builder Behavior Engine

**Strategic Role:** How students create behavior without settings, permissions, or admin panels. The shaping layer of HIVE.

**Builder Capabilities:**
- Fork existing Tools or build from Elements
- Place Tools into any eligible Space
- Activate dormant Spaces through Tool placement
- Access platform experiments and beta features
- Respond to Builder Prompts and community feedback

**HiveLAB Components:**
- **Builder Prompt of the Week** — Platform insights, voting, feedback requests
- **Tool Composer** — Fork → edit → preview → save workflow
- **Your Tools Library** — Created and forked Tools management
- **Builder Activity Feed** — Tool surges, placements, forks, attribution
- **Platform Experiments** — Beta feature toggles and testing access

**Tool Ecosystem:**
- **Platform Tools** — System-defined (Join, Chat, Events)
- **Template Tools** — Predefined structures (editable by Builders)
- **Custom Tools** — Built from raw Elements by advanced Builders

**Builder Economy:**
- Tool attribution creates social currency
- Successful Tools get visual "surge" highlighting
- Builder Cards show Tool creation history
- Platform recognition through Builder Prompts

### SYSTEM 4: FEED — [SPECIFICATION PENDING]

**Status:** Architecture defined, content strategy in development
**Role:** To be determined based on summer behavioral learning
**Implementation:** Deferred until Systems 1-3 are stable

## 3. Student Journey & Value Propositions

### For International Students

**Pain Points Addressed:**
- Social disorientation and lack of informal campus intel
- Structural confusion about campus rhythms and opportunities
- Isolation without overwhelming social pressure

**vBETA Value:**
- **Profile Calendar Tool** — Shows campus rhythms and dining/library hours
- **Auto-assigned Spaces** — Immediate belonging without social friction
- **Stack Tools** — Personal productivity without requiring social engagement
- **Ambient awareness** — See campus activity without posting pressure

### For Incoming Students

**Pain Points Addressed:**
- Pre-arrival anxiety about social connections
- Lack of peer validation and campus preparation
- Overwhelming orientation information

**vBETA Value:**
- **Soft onboarding** — Profile-first experience builds confidence
- **Space previews** — See future communities before arriving
- **Builder pathway** — Clear progression from Tool user to campus leader
- **Peer-created Tools** — Upperclassmen-built orientation assistance

### For All Students

**Universal Value Propositions:**
- **Behavioral agency** — Shape campus environment through Tool creation
- **Ambient community** — Light presence without performance pressure
- **Seasonal adaptation** — Platform evolves with campus rhythms
- **Skill development** — Learn platform building and community leadership

## 4. Technical Implementation Strategy

### Development Priorities

**Phase 1: Core Systems (May 2025)**
- Profile behavioral dashboard with Calendar Tool
- Spaces framework with dormant/activation states
- HiveLAB Tool placement and basic Builder console
- Authentication and auto-assignment logic

**Phase 2: Tool Ecosystem (June 2025)**
- Template Tool library expansion
- Custom Tool composer with Elements
- Builder prompt system and community feedback
- Tool attribution and surge mechanics

**Phase 3: Summer Evolution (July-August 2025)**
- Platform behavioral learning and analytics
- Weekly Tool drops and feature updates
- Builder recruitment and Space activation campaigns
- Fall preparation and scale-up planning

### Technical Architecture

**Platform:** Flutter (iOS, Android, Web)
**State Management:** Riverpod with system-specific providers
**Backend:** Firebase (Firestore, Cloud Functions, Authentication)
**Navigation:** go_router with system-based routing
**Data Layer:** Clean Architecture with feature-based repositories
**Caching:** Client-side using Hive for offline support

**Performance Requirements:**
- 60fps animations on mid-range devices
- <200ms page load times
- Offline-first Tool usage
- Real-time Tool surge updates

## 5. Summer Evolution Strategy

### Campus Context (June-August 2025)

**Student Population:**
- Incoming first-years (hungry for social clues)
- International students (need quiet connection)
- Builder-minded users (early explorers seeking influence)
- Staff/Org leaders (observing, prepping for fall)

**Platform Learning Objectives:**
- Which Tools get placed vs. actually used
- Space activation patterns and successful combinations
- Builder recruitment and retention strategies
- Seasonal behavior shifts and campus rhythms

### Weekly Evolution Plan

**Weeks 1-2: Personal Utility Foundation**
- Focus on Profile and Stack Tools adoption
- Calendar Tool integration with campus schedules
- Auto-assignment to Spaces (dormant state)

**Weeks 3-4: Builder Emergence**
- HiveLAB access for student leaders
- First Tool placements and Space activations
- Template Tool library expansion

**Weeks 5-8: Community Formation**
- Tool attribution and Builder recognition
- Cross-Space Tool sharing and collaboration
- Fall preparation and orientation Tool creation

**Weeks 9-12: Scale Preparation**
- Platform optimization based on summer learning
- Builder recruitment for fall campus influx
- Tool ecosystem maturation and proven patterns

## 6. Success Metrics & KPIs

### Summer 2025 Targets

**Profile Engagement:**
- 70% of users interact with Calendar Tool weekly
- 50% of users try at least 3 different Stack Tools
- 40% daily return rate for Profile dashboard

**Spaces Activation:**
- 25% of Spaces activated by Builders during summer
- 60% of activated Spaces maintain weekly activity
- 15% of students join additional Spaces beyond auto-assignment

**Builder Adoption:**
- 10% of summer users become Builders
- 80% of Builders place at least one Tool
- 50% of placed Tools get used by other students

**Platform Evolution:**
- Weekly Tool drops maintain 30% adoption rate
- Builder feedback response rate >60%
- Platform experiments achieve statistical significance

### Fall 2025 Preparation Metrics

**Scale Readiness:**
- Tool ecosystem supports 10x user growth
- Builder-to-student ratio maintains 1:20
- Space activation templates proven effective

**Community Foundation:**
- Successful Tool patterns documented and replicable
- Builder recruitment pipeline established
- Campus rhythm understanding validated

## 7. Risk Mitigation & Contingencies

### Technical Risks

**Performance at Scale:**
- Mitigation: Aggressive caching and offline-first architecture
- Contingency: Graceful degradation and feature flagging

**Tool Ecosystem Complexity:**
- Mitigation: Start with Template Tools, gradual Element introduction
- Contingency: Simplified Tool creation workflows

### Product Risks

**Builder Recruitment:**
- Mitigation: Target existing student leaders with clear value proposition
- Contingency: Staff-seeded Tool creation during low adoption periods

**Space Activation:**
- Mitigation: Template Tools make activation low-friction
- Contingency: Pre-activated Spaces for critical campus functions

**Summer Engagement:**
- Mitigation: Focus on personal utility over social features
- Contingency: Accelerated Tool drop schedule and Builder incentives

### Market Risks

**Competitive Response:**
- Mitigation: Focus on unique behavioral platform positioning
- Contingency: Accelerated feature development and campus partnerships

**Campus Adoption:**
- Mitigation: Target high-influence student leaders first
- Contingency: Multiple campus pilot programs

## 8. Post-vBETA Evolution

### Fall 2025 Considerations

**Social Layer Finalization:**
- Feed system implementation based on summer behavioral data
- Messaging system activation (patch 0.1.1)
- Enhanced personalization and ritual surfaces

**Scale Challenges:**
- 10x user growth management
- Builder-to-student ratio maintenance
- Tool ecosystem quality control

**Revenue Preparation:**
- University insight dashboard development
- Builder economy monetization exploration
- Data analytics product validation

### Long-term Vision (2026+)

**Platform Maturation:**
- Cross-campus Tool sharing and collaboration
- Advanced Builder economy with reputation systems
- Institutional partnerships and revenue streams

**Market Expansion:**
- Multi-campus deployment
- High school and corporate adaptations
- Platform-as-a-Service for educational institutions

---

**Note:** This specification represents a complete behavioral platform designed to give students agency over their campus environment. The focus is on creation, not consumption—building community through Tools rather than scrolling through feeds. Success is measured by student empowerment and campus culture enhancement, not engagement metrics or screen time. 