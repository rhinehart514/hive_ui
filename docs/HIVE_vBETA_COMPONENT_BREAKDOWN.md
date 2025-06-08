# HIVE vBETA Component Breakdown

*Mapping Product Vision to Buildable Parts*

## 🎯 SYSTEM 1: PROFILE — THE BEHAVIORAL CORE

### **Calendar Tool Components**

#### **Calendar Display Engine**
```
📅 WeekView Component
- 7-day grid with time slots
- Event card rendering within time blocks
- Visual overlay for Quiet Hours (dimmed periods)
- Today indicator and current time line
- Scroll/navigation between weeks

📅 EventCard Component  
- Title, time, location display
- Source indicator (manual, Space RSVP, Tool-generated)
- Quick actions (edit, delete, view details)
- Color coding by event type/source

📅 QuietHoursOverlay Component
- Visual calendar block creation interface
- Time range selector (start/end times)
- Recurring pattern options (daily, weekdays, weekends)
- Visual dimming of selected periods
```

#### **Event Management System**
```
📝 ManualEventCreator
- Quick entry form (title, time, location)
- Date/time picker integration
- Save to personal calendar
- Auto-populate from Space events

🔔 EventRSVPIntegration
- Connect Space event RSVPs to personal calendar
- Sync event updates from Spaces
- Handle RSVP status changes
- Remove events when RSVP cancelled
```

### **Motion Log Components**

#### **Activity Tracker**
```
📊 MotionEntry Data Structure
- Timestamp, action type, target object
- Action types: space_join, tool_use, event_rsvp, calendar_edit
- Metadata: which Space, which Tool, event details
- Privacy level (always private in vBETA)

📜 MotionLogRenderer
- Chronological list view with infinite scroll
- Entry formatting: "Joined Clement Hall Space", "Used Reminder Tool"
- Timestamp display (relative: "2h ago", absolute: "March 15, 3:24 PM")
- Filtering/search capabilities (post-launch iteration)
```

### **Stack Tools Components**

#### **Quiet Hours Tool**
```
🔇 QuietHoursCreator
- Time range selection interface
- Recurring schedule builder
- Calendar integration (visual blocks)
- Notification suppression logic

🔇 QuietHoursManager
- Active/inactive status display
- Quick toggle on/off
- Edit existing Quiet Hours blocks
- Delete/modify schedules
```

#### **Reminder Tool**
```
⏰ ReminderCreator
- Text input for reminder content
- Date/time picker
- Reminder type selection (notification, calendar event)
- Recurring reminder options

⏰ ReminderManager
- List of active reminders
- Quick edit/delete actions
- Snooze functionality
- Integration with calendar display
```

#### **PromptPost Tool**
```
✍️ PromptPostEditor
- Text input with basic formatting
- Auto-save draft functionality
- Character limit indicator
- Private/personal storage (no sharing in vBETA)

✍️ PromptPostHistory
- Personal journal view of past PromptPosts
- Date-based organization
- Search through personal entries
- Export/backup options
```

### **Now Panel Components**

#### **Dynamic Activity Banner**
```
📢 NowPanelEngine
- Real-time activity aggregation
- Smart text generation ("1 event today", "Tool active again")
- Priority ranking (events > tool activity > space updates)
- Click-through navigation to relevant sections

📢 ActivityIndicators
- Event count badges
- Tool status indicators
- Space activity notifications
- New/unread markers
```

### **Auto-Joined Spaces Display**

#### **Space Preview Cards**
```
🏠 SpacePreviewCard
- Space name, type, member count
- Dormant vs activated state indicator
- Last activity timestamp
- Quick navigation to Space detail
- Join status (auto-joined, manually joined)

🏠 SpacesList
- Categorized display (Dorm, Major, Other)
- Search/filter functionality
- Sorting options (activity, alphabetical)
- Empty state handling
```

---

## 🏢 SYSTEM 2: SPACES — STRUCTURED CONTAINERS

### **Dormant State Components**

#### **Preview Mode Interface**
```
👁️ DormantSpaceView
- Pinned intro text display
- Mock Tool placeholders with descriptions
- Member count and preview avatars
- "Want to run this Space?" CTA button
- Space metadata (category, creation date, type)

👁️ MockToolPlaceholder
- Tool description and potential functionality
- Example use cases
- Benefits explanation
- "Available when activated" messaging
```

### **Space Activation Components**

#### **Builder Activation Flow**
```
🚀 SpaceActivationTrigger
- First Tool placement detection
- UI state transition (dormant → activated)
- Member notification system
- Activity log entry creation

🚀 ActivationConfirmation
- Success message display
- New capabilities explanation
- Next steps guidance
- Share activation with members
```

### **Space Surface Components**

#### **Pinned Surface**
```
📌 PinnedContent
- Static intro message display
- Builder edit capabilities (post-activation)
- Rich text formatting support
- File/image attachment options

📌 PinnedEditor (Builder-only)
- Rich text editor interface
- Preview mode
- Save/publish workflow
- Version history tracking
```

#### **Events Surface**
```
📅 SpaceEventsCalendar
- Space-specific event listing
- Calendar view integration
- RSVP functionality
- Event creation (via Tools)

📅 SpaceEventCard
- Event details display
- RSVP status and count
- Creator attribution
- Quick actions (RSVP, share, details)
```

#### **Tools Surface**
```
🛠️ PlacedToolsDisplay
- List of active Tools in Space
- Tool interaction interfaces
- Usage statistics display
- Builder management options

🛠️ ToolInteractionZone
- Dynamic rendering based on Tool type
- Form submissions, voting interfaces, etc.
- Real-time updates for collaborative Tools
- Result/response aggregation
```

#### **Members Surface**
```
👥 MembersList
- Auto-joined member display
- Manually joined member display
- Member status indicators (active, Builder)
- Profile preview on tap

👥 MemberPreviewCard
- Name, year, major display
- Join date and activity level
- Quick actions (Connect, view profile)
- Privacy-respectful information display
```

#### **Posts Surface (Hidden Until Activated)**
```
💬 PostsPlaceholder
- "No posting Tool placed yet" message
- Explanation of how posting gets enabled
- CTA for Builders to place PromptPost Tool

💬 PostsFeed (When PromptPost Tool Active)
- Chronological post display
- Reply threading interface
- Post interaction buttons
- Moderation controls (Builder-only)
```

### **Auto-Assignment Components**

#### **Space Matching Engine**
```
🎯 StudentSpaceAssigner
- Dorm-based Space assignment
- Major-based Space assignment  
- International student Space detection
- Assignment verification and confirmation

🎯 SpaceRosterManager
- Automatic member addition
- Roster synchronization
- Member removal handling
- Assignment history tracking
```

---

## 🧪 SYSTEM 3: HIVELAB — BEHAVIOR ENGINE

### **Builder Onboarding Components**

#### **Builder Opt-In Flow**
```
🚪 BuilderOnboardingFlow
- Capability explanation screens
- Responsibility overview
- First Tool placement tutorial
- HiveLAB access activation

🚪 BuilderStatusManager
- Builder badge assignment
- Capability unlocking
- Progress tracking
- Achievement system (future)
```

### **Tool Creation Components**

#### **Template Selection Interface**
```
🏗️ TemplateLibrary
- Template browsing interface
- Template preview and explanation
- Use case examples
- Fork/customize options

🏗️ TemplateCard
- Template name and description
- Example configurations
- Usage statistics
- Fork/use buttons
```

#### **Tool Configuration System**
```
⚙️ ToolConfigurator
- Dynamic form generation based on template
- Configuration preview
- Validation and testing interface
- Save to library functionality

⚙️ ConfigurationPreview
- Live preview of Tool behavior
- Test interaction simulation
- Output/result preview
- Validation feedback
```

### **Tool Placement Components**

#### **Placement Interface**
```
📍 ToolPlacementFlow
- Space selection interface
- Surface selection (which part of Space)
- Configuration final review
- Placement confirmation

📍 SpaceSelector
- Available Spaces listing
- Permission checking (Builder access)
- Space status indication
- Placement restrictions display
```

### **Builder Dashboard Components**

#### **Tool Management**
```
🏷️ ToolLibrary
- Personal Tool collection
- Created vs forked Tools
- Usage analytics per Tool
- Quick edit/configure options

🏷️ PlacementHistory
- Where Tools have been placed
- Performance metrics per placement
- Quick navigation to active Tools
- Removal/modification options
```

#### **Builder Activity Feed**
```
📈 BuilderActivityDisplay
- Tool interaction notifications
- Space activation updates
- Weekly prompt responses
- Community Builder highlights

📈 WeeklyPromptInterface
- Current prompt display
- Response submission form
- Previous prompt archive
- Community response viewing
```

---

## 🌱 EVOLVING SOCIAL LAYER COMPONENTS

### **Intro Thread System**
```
👋 IntroThreadGenerator
- System-prompt creation
- New user invitation
- Response collection interface
- Thread moderation tools

👋 IntroResponseCard
- User introduction display
- Basic profile information
- Response interaction options
- Connect button integration
```

### **Profile Preview System**
```
👤 ProfilePreviewCard
- Optional public information display
- Name, year, major, Spaces joined
- Connect button placement
- Privacy control interface

👤 ConnectButton
- Private link creation
- No-notification connection
- Connection status tracking
- Connection management
```

### **Reply Threading System**
```
💭 ReplyThreadRenderer
- Structured reply display
- Thread navigation interface
- Response submission form
- Thread moderation controls

💭 PromptReplyAggregator
- Cross-Space reply collection
- Anonymous vs attributed responses
- Reply interaction tracking
- Thread emergence detection
```

---

## 🔧 SUPPORTING INFRASTRUCTURE COMPONENTS

### **Authentication & Onboarding**
```
🔐 EduEmailVerification
🔐 ProfileInformationCollection  
🔐 SpaceAutoAssignment
🔐 BuilderOptInFlow
```

### **Navigation & State Management**
```
🧭 AppRouter (go_router implementation)
🧭 ProfileProvider (Riverpod)
🧭 SpacesProvider (Riverpod)
🧭 BuilderProvider (Riverpod)
```

### **Data Persistence**
```
💾 UserRepository
💾 SpacesRepository  
💾 ToolsRepository
💾 MotionRepository
💾 CalendarRepository
```

This breakdown provides the concrete buildable components for each strategic system you've designed. 