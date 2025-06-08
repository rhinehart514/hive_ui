# HIVE vBETA Build Requirements

*Strategic Foundation for Late May 2025 Launch*

## 🚀 LAUNCH CRITICAL (MUST SHIP)

These systems must be fully functional for vBETA launch. Students need immediate value on first open.

### **1. PROFILE SYSTEM - Core Dashboard**

#### **Calendar Tool (Priority 1)**
```
- Manual event entry (title, time, location)
- Quiet Hours blocks (visual calendar overlay)
- Stack Tool integration (Reminders appear as calendar items)
- Auto-populated events from Space RSVPs
- Week view primary, month view secondary
- NO external calendar sync (Google/iCal) for vBETA
```

#### **Motion Log (Priority 1)**
```
- Chronological list of user actions:
  - Space joins (auto and manual)
  - Tool usage (Stack Tools, PromptPosts)
  - Event RSVPs and check-ins
  - Calendar edits (Quiet Hours set/changed)
- Simple text-based entries with timestamps
- Infinite scroll, most recent first
```

#### **Stack Tools (Priority 1)**
```
- Quiet Hours: Calendar block creator with mute functionality
- Reminder: Time-based alerts with calendar integration
- PromptPost: Personal journal/reflection input (private for vBETA)
- All tools are personal, non-shareable in vBETA
```

#### **Now Panel (Priority 2)**
```
- Dynamic banner showing today's activity
- Examples: "1 event today", "Tool active again", "New Space activity"
- Updates based on Calendar events and motion state changes
- Simple text display, no complex graphics needed for launch
```

#### **Auto-Joined Spaces Display (Priority 1)**
```
- List of assigned Spaces (dorm + major based)
- Preview cards showing dormant vs activated state
- Quick navigation to Space detail pages
```

### **2. SPACES SYSTEM - Group Foundation**

#### **Dormant State UI (Priority 1)**
```
- Preview mode showing:
  - Pinned intro text (editable by system/Builder)
  - Mock Tool placeholders with descriptions
  - "Want to run this Space?" CTA for potential Builders
  - Member count display
  - Basic Space metadata (type, category)
```

#### **Auto-Assignment Logic (Priority 1)**
```
- Match students to Spaces based on onboarding inputs:
  - Dorm = housing selection
  - Major = academic program
- Create initial Space roster on student signup
- NO university partnership required for vBETA
```

#### **Basic Space Surfaces (Priority 1)**
```
- Pinned: Static intro message (Builder-editable post-activation)
- Events: Calendar view of Space-related events
- Tools: List of placed Tools (empty until Builder activation)
- Members: Auto-generated list of joined students
- Posts: Hidden until PromptPost Tool is placed
- Chat: Locked with "Coming in v0.1.1" message
```

#### **Space Activation Flow (Priority 2)**
```
- Builder places first Tool → Space becomes "activated"
- UI changes from preview to live mode
- Member notifications about activation
- Tool interaction becomes live
```

### **3. HIVELAB SYSTEM - Builder Engine**

#### **Builder Onboarding (Priority 1)**
```
- Opt-in flow during initial onboarding OR from Profile
- Simple explainer: "Help shape your Spaces with Tools"
- Short intro to HiveLAB interface
- Access to Builder dashboard
```

#### **Basic Tool Composer (Priority 1)**
```
- Template selection interface
- Simple Tool configuration (text fields, toggles)
- Preview mode before placement
- Save to "Your Tools Library"
- NO complex Element system for vBETA launch
```

#### **Tool Placement System (Priority 1)**
```
- Menu-based Tool selection (FAB button)
- Choose Tool → Select target Space → Configure → Place
- Visual confirmation of placement
- Tool appears in target Space immediately
```

#### **Template Tools Library (Priority 1)**
```
- Pre-built Tools for common use cases:
  - Intro Thread (prompt with replies)
  - Event Announcer (create/share events)
  - Quick Poll (simple voting)
  - Study Group Finder (matching/coordination)
```

#### **Builder Dashboard (Priority 2)**
```
- Your Tools Library (created/forked Tools)
- Placement history
- Basic Tool performance (usage, interactions)
- Weekly Builder Prompt display
```

## 🔄 WEEKLY ITERATION FEATURES

These can be built and deployed during summer based on learning:

### **Week 1-2 (Early June): Builder Activation**
- Tool interaction analytics
- Builder activity feed
- Tool forking functionality
- Enhanced Tool templates

### **Week 3-4 (Mid June): Motion Enhancement**
- Now Panel intelligence improvements
- Motion Log filtering/search
- Calendar visual enhancements
- Stack Tool variations

### **Week 5-8 (July): Orientation Integration**
- Freshman-specific onboarding flow
- Orientation event integration
- International student Space types
- Calendar import utilities

### **Week 9-12 (August): Social Layer Emergence**
- Feed-like surface (if validated)
- PromptPost visibility options
- Connect/Seen mechanics
- Public profile elements

## 🚫 EXPLICITLY DEFERRED

Do NOT build these for vBETA launch:

- Complex Element system (TextInput, AnonSubmit, etc.)
- Messaging/Chat functionality
- Public profile pages
- Feed/social layer
- Ritual system (Bracket, Pulse)
- Connect/Seen mechanics
- Tool marketplace/sharing
- Advanced analytics
- Push notifications (beyond basic system alerts)

## 📊 SUCCESS METRICS FOR vBETA

**Week 1:** Calendar adoption rate, Space auto-assignment success
**Week 2:** Builder opt-in rate, first Tool placement frequency  
**Week 3:** Space activation rate, Tool interaction frequency
**Week 4:** Daily return rate, Stack Tool usage patterns

## 🛠 TECHNICAL IMPLEMENTATION NOTES

### **Data Models (Firestore)**
```
- Users: Basic profile + tier + Builder status
- Spaces: Metadata + member lists + Tool placements
- Tools: Template definitions + configurations
- Motion: User action logs with timestamps
- Calendar: Personal events + Quiet Hours blocks
```

### **State Management (Riverpod)**
```
- ProfileProvider: Calendar, Motion Log, Stack Tools
- SpacesProvider: Auto-joined Spaces, activation status
- BuilderProvider: Tool library, placement capabilities
- CalendarProvider: Events, Quiet Hours, daily view
```

### **Navigation Structure**
```
/profile - Main dashboard
/profile/calendar - Full calendar view
/profile/motion - Motion Log detail
/spaces - Auto-joined Spaces list
/space/:id - Individual Space detail
/hivelab - Builder dashboard (if Builder)
/hivelab/compose - Tool creation interface
```

This build plan supports your "design laboratory" strategy while ensuring students get immediate value from day one. 