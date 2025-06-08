# HIVE vBETA Component Priority Matrix

*Critical Path to Late May Launch*

## 🚨 TIER 1: LAUNCH BLOCKERS (Must Ship May 29)

These components are essential for students to get immediate value on first open.

### **Profile System - Core Value**
```
Priority 1A (Week -4):
📅 WeekView Component - Basic 7-day calendar grid
📅 EventCard Component - Simple event display
📝 ManualEventCreator - Quick event entry form
📊 MotionEntry Data Structure - Basic activity tracking
🔇 QuietHoursCreator - Time blocking interface
⏰ ReminderCreator - Simple reminder setup
🏠 SpacePreviewCard - Show assigned Spaces

Priority 1B (Week -3):
📜 MotionLogRenderer - Activity history display  
📢 NowPanelEngine - Daily activity summary
🏠 SpacesList - Organized Space display
```

### **Spaces System - Foundation**
```
Priority 1A (Week -3):
👁️ DormantSpaceView - Preview mode for inactive Spaces
👁️ MockToolPlaceholder - Show potential functionality
🎯 StudentSpaceAssigner - Auto-assign by dorm/major
👥 MembersList - Basic member display

Priority 1B (Week -2):
📌 PinnedContent - Static intro message display
📅 SpaceEventsCalendar - Space event listing
🛠️ PlacedToolsDisplay - Show active Tools (starts empty)
```

### **HiveLAB System - Builder Path**
```
Priority 1A (Week -2):
🚪 BuilderOnboardingFlow - Simple opt-in process
🏗️ TemplateLibrary - 4 basic Template Tools
📍 ToolPlacementFlow - Basic placement interface
🚀 SpaceActivationTrigger - Dormant→Active transition

Priority 1B (Week -1):
🏷️ ToolLibrary - Personal Tool collection
⚙️ ToolConfigurator - Simple Tool setup
```

### **Supporting Infrastructure**
```
Priority 1A (Week -4):
🔐 EduEmailVerification - .edu signup/login
🔐 ProfileInformationCollection - Dorm/major input
🧭 AppRouter - Basic navigation structure
💾 UserRepository - User data persistence

Priority 1B (Week -3):
🧭 ProfileProvider - Profile state management
🧭 SpacesProvider - Spaces state management  
💾 SpacesRepository - Space data persistence
💾 CalendarRepository - Calendar data persistence
```

---

## ⚡ TIER 2: LAUNCH ENHANCERS (Nice to Have May 29)

These improve the experience but aren't essential for core value delivery.

### **Profile Polish**
```
📅 QuietHoursOverlay Component - Visual calendar dimming
📢 ActivityIndicators - Event count badges  
⏰ ReminderManager - Reminder list management
✍️ PromptPostEditor - Personal journaling (private)
```

### **Spaces Polish**
```
📌 PinnedEditor - Rich text editing for Builders
👥 MemberPreviewCard - Enhanced member display
🚀 ActivationConfirmation - Success messaging
💬 PostsPlaceholder - "No posting yet" message
```

### **HiveLAB Polish**
```
🏗️ TemplateCard - Enhanced template preview
📈 BuilderActivityDisplay - Activity notifications
⚙️ ConfigurationPreview - Tool behavior preview
🚪 BuilderStatusManager - Badge/status management
```

---

## 🔄 TIER 3: ITERATION FEATURES (Week 1-4 Post-Launch)

Build these based on usage learning and student feedback.

### **Enhanced Motion & Intelligence**
```
Week 1-2:
📊 Advanced Motion Log filtering/search
📢 Intelligent Now Panel updates
📅 Calendar visual enhancements
⏰ Advanced reminder types

Week 3-4:
📈 Tool interaction analytics
🏷️ Placement history with metrics
🔇 Advanced Quiet Hours patterns
```

### **Social Layer Emergence**
```
Week 2-4 (If Validated):
👋 IntroThreadGenerator - System-generated prompts
👤 ProfilePreviewCard - Optional public profiles
👤 ConnectButton - Private connection mechanism
💭 ReplyThreadRenderer - Structured threading
```

### **Builder Ecosystem Growth**
```
Week 3-6:
🏗️ Tool forking functionality
📈 Builder community features
🏷️ Advanced Tool management
⚙️ Complex Tool configurations
```

---

## 🚫 TIER 4: EXPLICITLY DEFERRED 

Do NOT build these for vBETA (save engineering time).

### **Complex Social Features**
```
❌ Full Feed/timeline interface
❌ Messaging/DM system
❌ Public profile pages with full history
❌ Follower/following graphs
❌ Advanced social discovery
❌ Push notification system
```

### **Advanced Tool System**
```
❌ Complex Element composition system
❌ Visual Tool builder interface
❌ Advanced Tool marketplace
❌ Tool versioning and rollback
❌ Advanced analytics dashboard
```

### **Platform Features**
```
❌ Ritual/challenge system
❌ Achievement/gamification system
❌ Advanced moderation tools
❌ Content reporting system
❌ Advanced search functionality
```

---

## 📊 DEVELOPMENT RESOURCE ALLOCATION

### **Week -4 (April 28-May 4): 70% Profile, 20% Infrastructure, 10% Spaces**
Focus: Get Profile system providing immediate personal value

### **Week -3 (May 5-11): 50% Spaces, 30% Profile Polish, 20% Infrastructure**
Focus: Make Spaces compelling even in dormant state

### **Week -2 (May 12-18): 60% HiveLAB, 30% Spaces, 10% Integration**
Focus: Enable Builder path and Tool placement

### **Week -1 (May 19-25): 50% Integration, 30% Polish, 20% Testing**
Focus: Make everything work together seamlessly

---

## 🎯 SUCCESS METRICS BY TIER

### **Tier 1 Success (Launch Day):**
- 90%+ of students complete onboarding
- 70%+ create at least one calendar event
- 50%+ set up at least one Stack Tool
- 30%+ browse their auto-assigned Spaces
- 10%+ opt into Builder status

### **Tier 2 Success (Week 1):**
- 20%+ daily calendar usage
- 15%+ Builder Tool placement rate
- 5%+ Spaces get activated
- 60%+ user retention day 7

### **Tier 3 Success (Week 4):**
- 40%+ monthly active users
- 30%+ Spaces have at least one Tool
- 25%+ students have used Stack Tools repeatedly
- Clear signal on social layer demand

This priority matrix ensures you ship a functional product that provides immediate value while preserving engineering resources for post-launch learning and iteration. 