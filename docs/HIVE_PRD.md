# HIVE vBETA Product Requirements Document (PRD)

_Last Updated: May 30, 2025_  
_Replaces: Previous V1 specifications_

## 1. Overview

HIVE vBETA represents a fundamental pivot from a social network model to a structured platform anchored in three modular systems: **Profile**, **Spaces**, and **HiveLAB**. This is not a social network with a feed at its center—it's a behavioral platform where students build community piece by piece through Tool-driven interactions.

**Problem Solved:** Students struggle to create meaningful connections and structure within campus life without falling into social media patterns that distract from real engagement.

**Target Audience:** University students with valid .edu email addresses, particularly focusing on behavioral builders who want to shape their environment.

**Value Proposition:** A platform where community is earned, not assumed—where students actively build the social layer through structured Tools rather than consuming endless feeds.

## 2. Core System Architecture

### 2.1 SYSTEM 1: PROFILE — THE BEHAVIORAL CORE

**Strategic Role:** Profile is the only system every student sees. It must work without social engagement and grows with motion.

**Key Sections:**
- **Now Panel** – Dynamic banner summarizing today's activity
- **Motion Log** – Chronological record of Tools used, Spaces joined, Events RSVP'd
- **Your Spaces** – List of joined, previewed, and auto-assigned Spaces
- **Your Events** – Calendar-integrated event viewer
- **Calendar Tool** – Week view combining class blocks, Quiet Hours, Tools, RSVPs
- **Stack Tools** – Self-service tools (Reminder, Quiet Hours, PromptPost)
- **HiveLAB Console** – Appears if user becomes a Builder
- **Builder Card** – Appears if user places a Tool (opt-in visibility)

**Implementation Priority:** ✅ Live for Summer

### 2.2 SYSTEM 2: SPACES — STRUCTURED GROUP SURFACES

**Strategic Role:** Spaces are where behavior lives—but only when activated by Builders. Nothing is visible unless someone builds.

**Fixed Surfaces:**
- **Pinned** – Static intro message (Builder-editable)
- **Posts** – Hidden until activated by PromptPost Tool
- **Events** – Calendar of RSS + Tool-based events
- **Tools** – Stack of placed modules
- **Chat** – Locked for vBETA; ships in patch 0.1.1
- **Members** – Auto-generated list of joined students

**Space Types:**
- **Residential** (auto-join by dorm)
- **Academic** (auto-join by major)
- **Cultural/org** (request join or Builder-added)
- **Internal/system** (admin controlled)

**Activation Model:**
- All Spaces launch dormant
- A Builder must place a Tool to activate
- Templates assist initial activation

**Implementation Priority:** ✅ Live for Summer

### 2.3 SYSTEM 3: HIVELAB — BUILDER BEHAVIOR ENGINE

**Strategic Role:** HiveLAB is how students create behavior—without settings, permissions, or admin panels. It's the shaping layer of HIVE.

**Builder Capabilities:**
- Fork or build Tools using Elements
- Place Tools into any eligible Space
- Activate dormant Spaces
- Access platform experiments
- Respond to Builder Prompts

**HiveLAB Includes:**
- **Builder Prompt of the Week** (insight or voting)
- **Tool Composer** (fork → edit → preview → save)
- **Your Tools Library**
- **Builder Activity Feed** (surges, placements, forks)
- **Platform Experiments** toggles (beta features)

**Tool Types:**
- **Platform Tools** – System-set (Join, Chat, Events)
- **Template Tools** – Predefined Tool structures (editable)
- **Custom Tools** – Built from raw Elements by Builders

**Implementation Priority:** ✅ Live for Summer

### 2.4 DEFERRED SYSTEM: SOCIAL LAYER

**Current Status:** ❌ Not Finalized for vBETA

**What's been ruled out:**
- Infinite scroll feed
- Follower graph
- Open posting

**What's still being explored:**
- Reply-first threads (e.g. Intro thread)
- Social trace previews (e.g. "Chi joined your dorm")
- PromptPost visibility outside of Spaces
- Fall unlock of ambient posting, group DMs, presence-driven Feed

**Implementation:** This system will not ship in summer unless finalized through Builder experimentation and student feedback.

## 3. Authentication & User Management

### 3.1 Core Authentication
- **Email/Password Signup & Login** with `.edu` verification
- **Magic Link Verification** (10 min TTL)
- **First & Last Name Collection** (mandatory during onboarding)
- **Profile Information:** Year, Major, Residence, Interests

### 3.2 Account Tiers
- **verified:** Auto-assigned via `.edu` verification
- **verified_plus:** Manually assigned for pre-existing student leaders
- **Builder:** Unlocked through Tool placement activity

## 4. Technical Architecture

**Guiding Principle:** Clean Architecture with feature-based modularity focused on the three core systems.

**Core Stack:**
- **Platform:** Flutter (iOS, Android, Web)
- **State Management:** Riverpod with system-specific providers
- **Backend:** Firebase (Firestore, Cloud Functions, Authentication)
- **Navigation:** `go_router` with system-based routing
- **Data Layer:** Repositories abstracting Firestore
- **Caching:** Client-side using `Hive` for offline support

**System-Specific Architecture:**
- **Profile:** Personal data providers, calendar integration
- **Spaces:** Group-based data management, Tool activation logic
- **HiveLAB:** Builder-specific providers, Tool composition engine

## 5. Development Priorities (vBETA Launch)

### Phase 1: Core Systems (Current Focus)
- ✅ Profile behavioral dashboard
- ✅ Spaces activation framework
- ✅ HiveLAB Tool placement system
- ✅ Basic authentication and onboarding

### Phase 2: Tool Ecosystem
- Template Tool library
- Custom Tool composer
- Element system for Tool building
- Builder prompt and feedback systems

### Phase 3: Polish & Launch Prep
- Motion and animation refinement
- Performance optimization
- Security audit
- Analytics implementation

## 6. Success Metrics (vBETA)

**Profile Engagement:**
- Daily Profile visits
- Tool usage frequency
- Calendar integration adoption

**Spaces Activation:**
- Number of Spaces activated by Builders
- Tool placement frequency
- Member participation in activated Spaces

**Builder Adoption:**
- Students becoming Builders
- Tools created and placed
- Builder prompt engagement

## 7. Post-vBETA Evolution

**Fall 2025 Considerations:**
- Social layer finalization based on summer usage patterns
- Messaging system activation (patch 0.1.1)
- Enhanced personalization and ritual surfaces
- Community-driven feature development

---

**Note:** This specification represents a complete departure from feed-centric social networking. HIVE vBETA is designed to help students build community intentionally, piece by piece, rather than consuming endless streams of content. The feed is not missing—it's waiting to be earned. 