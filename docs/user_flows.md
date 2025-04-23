# Hive UI User Flows Documentation

This document outlines the complete set of user flows required to build the Hive UI application, as well as the key user journeys to map.

**IMPORTANT:** All flows listed here should be designed and documented following the principles and standards outlined in the [Hive UI Product Context & Documentation Principles](docs/product_context.md).

---

## 1. Core Hive User Flows

### 1.1 Onboarding & Initial Setup
- [x] **Sign‑Up** (Email/Password) - See `docs/flows/student/onboarding_signup_email.md`
- [x] **Sign‑Up** (Google) - See `docs/flows/student/onboarding_signup_google.md`
- [ ] **Sign‑Up** (Apple)
- [x] **Email Verification** - See `docs/flows/student/email_verification.md`
- [x] **Profile Completion** (*Note: Documented flow `onboarding_profile_completion.md` covers Name, Year, Major, Residence, Interests, Tier. Does NOT cover unique Username, Bio, Avatar*) - See `docs/flows/student/onboarding_profile_completion.md`
- [x] **Onboarding Highlights / Tutorial** - See `docs/flows/student/onboarding_tutorial.md`
- [Future] **Invite Peer to Join** - *(V1 Deprioritized - Needs value prop)*

### 1.2 Authentication & Security
- [x] **Login** (Email/Password, SSO) - See `docs/flows/student/login_email.md` (*Note: SSO Login TBD*)
- [ ] **Login** (Google SSO)
- [ ] **Login** (Apple SSO)
- [x] **Password Reset / Forgot Password** - See `docs/flows/student/password_reset.md`
- [x] **Logout** - See `docs/flows/student/logout.md`
- [ ] **(Future) Multi‑Factor Authentication**
- [ ] **Session Expiry & Re‑Auth**

### 1.3 Main Feed
- [x] **Feed Loading & Refresh** - See `docs/flows/student/feed_loading_refresh.md`
- [x] **Infinite Scroll / Pagination** - See `docs/flows/student/feed_pagination.md`
- [x] **Content Preview → Detail Drill‑In** - See `docs/flows/student/feed_content_drill_in.md`
- [x] **Sorting & Filtering** - *(V1 relies on default algorithm, no user controls) - See `docs/flows/student/feed_sorting_filtering.md`*
- [x] **Boost / Repost (Within Space)** - See `docs/flows/student/feed_boost_repost.md`
- [x] **Save / Bookmark for Later** - See `docs/flows/student/feed_save_bookmark.md`

### 1.4 Content Creation & Editing
- [x] **Text‑Only Post** - See `docs/flows/student/create_text_post.md`
- [x] **Rich Media Post** (Images/Videos) - See `docs/flows/student/create_media_post.md`
- [ ] **Event‑As‑Post**
- [x] **Draft Auto‑Save & Resume** - See `docs/flows/student/post_draft_handling.md`
- [x] **Edit / Delete Post** - See `docs/flows/student/manage_post.md`
- [ ] **Post Visibility Settings**

### 1.5 Content Interaction
- [x] **Like / Unlike** - See `docs/flows/student/content_like.md`
- [x] **Comment / View Thread** - See `docs/flows/student/content_comment.md`
- [x] **Share Externally** (Copy Link) - See `docs/flows/student/content_share_external.md`
- [x] **Report Content** - See `docs/flows/student/content_report.md`

### 1.6 Spaces (Communities)
- [x] **Browse / Search Spaces** - See `docs/flows/student/spaces_discovery.md`
- [x] **View Space Details** - See `docs/flows/student/view_space_details.md`
- [x] **Join Public Space** - *(Handled within [View Space Details](./student/view_space_details.md))*
- [x] **Request to Join Private Space** - *(Handled within [View Space Details](./student/view_space_details.md))*
- [x] **Leave Space** - See `docs/flows/student/leave_space.md`
- [x] **(Builder) Create Space** - See `docs/flows/builder/create_space.md`
- [x] **(Builder) Moderate Content & Members** - See `docs/flows/builder/moderate_space.md`
- [x] **Space Decay & Archival Logic** - See `docs/system/space_lifecycle.md`

### 1.7 Events
- [x] **Browse / Search Events** - *(Discovery via Feed Integration - See `docs/flows/student/events_discovery.md`)*
- [x] **View Event Details** - See `docs/flows/student/view_event_details.md`
- [x] **RSVP / Cancel RSVP** - See `docs/flows/student/event_rsvp.md`
- [x] **Host: Create Event** - See `docs/flows/builder/create_event.md`
- [x] **Host: Manage Event Details & Attendees** - See `docs/flows/builder/manage_event.md`
- [ ] **(Future) Event Check‑In** (QR, Geo) - *Defined* `docs/flows/student/event_check_in.md`
- [ ] **Host: Post‑Event Follow‑Up** (Review, Photos)

### 1.8 Direct Messaging
*   ### 1.8 Direct Messaging - See `docs/flows/student/direct_messaging.md`
    *   [x] **View Chat List**
    *   [x] **Start New DM**
    *   [x] **Send / Receive Message** (Text Only V1)
    *   [x] **Delete / Archive Conversation**
    *   [ ] **(Future) Group Chat Seeding via Space**
    *   [x] **Report Conversation**

### 1.9 Rituals & HiveLab Experiments
*   ### 1.9 Rituals & HiveLab Experiments - See `docs/flows/student/rituals_bracket.md`
    *   [x] **Discover Active Rituals** (V1: THE BRACKET via Feed Strip)
    *   [x] **Participate in Ritual** (V1: Viewing THE BRACKET)
    *   [x] **View Ritual Progress & Leaderboard** (V1: THE BRACKET View)
    *   [ ] **(Builder) Create / Seed New Ritual** (Out of Scope V1)
    *   [ ] **Claim Badge & Share** (Out of Scope V1)

### 1.10 Notifications
*   ### 1.10 Notifications - See `docs/flows/student/notifications.md`
    *   [x] **View Notification Feed**
    *   [x] **Tap‑Through to Context**
    *   [x] **Mark Read / Bulk Actions** (Mark all read only V1)
    *   [x] **Notification Settings & Preferences**
    *   [x] **Push Permission Prompt & Onboarding**

### 1.11 Profile & Social Graph
*   ### 1.11 Profile & Social Graph - See `docs/flows/student/profile_social.md`
    *   [x] **View Own Profile**
    *   [x] **View Other's Profile**
    *   [x] **Edit Profile Details**
    *   [x] **Follow / Unfollow User**
    *   [x] **View Followers / Following**
    *   [x] **Activity Trail (Private)**
    *   [ ] **Badge Showcase & Achievements** (Section exists, no badges V1)

### 1.12 Settings & Support
*   ### 1.12 Settings & Support - See `docs/flows/student/settings_support.md`
    *   [x] **Account Settings** (Email, Password, Sign Out)
    *   [x] **Privacy & Visibility Controls** (Private Profile, DM Control V1)
    *   [x] **Notification Preferences**
    *   [x] **Accessibility Options** (Reduced Motion V1)
    *   [x] **Help & FAQ Access**
    *   [x] **Report a Problem / Contact Support**

### 1.13 Admin & Analytics (DaaS)
*   ### 1.13 Admin & Analytics (DaaS) - See `docs/flows/admin/daas_dashboard.md`
    *   [ ] **University Admin Sign‑Up & Verification** (Manual V1)
    *   [x] **Access Data Dashboard**
    *   [ ] **Configure Reports & Alerts** (Out of Scope V1)
    *   [x] **Export / Integrate via API** (CSV Export only V1)
    *   [ ] **Manage Seat Allocations & Permissions** (Out of Scope V1)

### 1.14 Offline & Error Handling
*   ### 1.14 Offline & Error Handling - See `docs/system/offline_error_handling.md`
    *   [x] **Offline Mode**: Cached Feed & Queued Posts
    *   [x] **Network Error States & Retry**
    *   [x] **Maintenance & Version Upgrade Prompt**

---

## 2. Key Hive User Journeys to Map

- **New User Activation**: Install → Sign‑Up → Profile Setup → First Post / First Space Join
- **Feed Discovery & Habit Formation**: App Open → Scan Feed → Interact (Like, Comment) → Return Next Day
- **Community Seeker**: Identify Interest → Search Space → Join Space → First Interaction → Network Formation
- **Event Enthusiast**: Event Alert → RSVP → Receive Reminders → Attend Event → Post‑Event Share
- **Content Creator Growth**: Idea → Create Post → Monitor Engagement → Reply to Comments → Gain Followers
- **Ritual Participant**: See Ritual Seeded → Join → Complete Tasks → Claim Badge → Share
- **Student Leader Workflow**: Create Space → Pre‑Seed Content → Manage Members/Events → View Analytics → Drive Engagement
- **Admin Data Consumer**: Verify Account → Define Metrics → Receive Reports → Drill into Dashboards → Act on Insights
- **Re‑Engagement Hook**: User Dormancy → Personalized Push → Deep Link to New Content/Event → Re‑entry
- **Error Recovery**: Encounter Error → See Recovery Prompt → Retry or Contact Support → Resume Flow

*   ### Admin Flows
    *   **User Management**
        *   [ ] View User List / Search
        *   [ ] View User Details
        *   [ ] Manage User Roles/Permissions
        *   [ ] Warn / Ban / Unban User
    *   **Content Moderation**
        *   [x] View Reports Queue & Handle Appeals ([docs](./flows/admin/view_reports_appeals.md))
        *   [ ] Take Action on Reported Content/User
        *   [ ] View Moderation History
    *   **System Management**
    *   **Data as a Service (DaaS)**
        *   [x] **View Dashboard & Export Data (V1)** - See `docs/flows/admin/daas_dashboard.md`