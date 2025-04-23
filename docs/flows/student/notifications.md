# Flow: Student - Notifications (V1)

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:**
*   [Flow: Student - Settings & Support](./settings_support.md) (Notification Preferences)
*   [Hive UI Product Context & Documentation Principles](../../product_context.md)

**Figma Link (Overall Flow):** [Link to Figma Frame for Notification Feed & Settings]

---

## 1. Title & Goal

*   **Title:** Student Notifications
*   **Goal:** Define how users receive, view, interact with, and manage in-app and push notifications for relevant activities within HIVE.

---

## 2. Persona & Prerequisites

*   **Persona:** Student (Logged-in User)
*   **Prerequisites:**
    *   User is logged in.
    *   Activity triggering notifications occurs.

---

## 3. Sequence of Actions

### 3.1 Receiving Notifications
*   **Trigger:** A notification-worthy event occurs related to the user.
    *   **V1 Trigger Events:** Likes, Comments, Mentions (in posts/comments), New Followers, DMs received, Event RSVP confirmations, Space Invites. (Q1.10.2)
*   **System Action (In-App):** If the app is open, an in-app notification indicator might appear (e.g., a badge on the notification icon).
*   **System Action (Push):** If the app is closed/backgrounded and push permissions are granted, a push notification is sent to the device.

### 3.2 Viewing the Notification Feed
*   **Trigger:** User wants to check their notifications.
*   **User Action:** User taps the notification access point.
    *   **Entry Point:** A **bell icon (🔔)** located in the **global header (top-right)**. (Q1.10.1)
*   **UI State:** Navigates to the Notification Feed screen.
    *   **Presentation:** Displays a list of notifications.
    *   **Ordering:** Pure **chronological order**, newest first. (Q1.10.3)
    *   **Grouping:** No grouping by type in V1. (Q1.10.3)
    *   **Read State:** Unread notifications might have a visual distinction (e.g., background color, dot indicator).

### 3.3 Interacting with Notifications
*   **User Action:** User taps on a specific notification in the feed.
*   **System Action:** Marks the notification as read automatically. (Q1.10.5)
*   **System Action:** Deep-links the user directly to the relevant content context. (Q1.10.4)
    *   *Examples:* Tapping a "like" notification goes to the liked post; tapping a DM notification opens the DM conversation; tapping an event reminder goes to the event detail screen.

### 3.4 Managing Read Status & Bulk Actions
*   **Trigger:** User wants to manage the read status of notifications.
*   **System Action (Auto-Read):** Notifications are marked read automatically upon tap-through. (Q1.10.5)
*   **User Action (Bulk Read):** User taps a "Mark all as read" action, likely available at the top-right of the notification feed screen. (Q1.10.6)
*   **System Action:** All notifications in the feed are marked as read.
    *   *Constraint:* No "Clear all" or bulk delete functionality in V1. (Q1.10.6)

### 3.5 Setting Notification Preferences
*   **Trigger:** User wants to customize which notifications they receive.
*   **User Action:** User navigates to Settings > Notifications.
*   **UI State (Settings):** Presents notification preference options.
    *   **Granularity:** Provides **type-based toggles** (On/Off) for categories like Likes, Comments, DMs, Follows, Event Reminders, etc. (Q1.10.7)
    *   **Channels:** Allows distinguishing between **Push Notifications** and **In-App Notifications** for each type (or globally). (Q1.10.7)
    *   **Global Mute:** Includes a global mute option to disable all notifications temporarily or permanently. (Q1.10.7)
*   **User Action:** User adjusts toggles according to their preferences.
*   **System Action:** Preferences are saved and applied to future notification delivery.

### 3.6 Push Notification Permissions
*   **Trigger:** User experiences their first notification-triggering event OR potentially during onboarding (TBD - Q1.10.8 decision needed).
    *   *Decision:* Prompt occurs **after the first meaningful event** that would trigger a push notification (e.g., first DM received, first follower). (Q1.10.8)
*   **System Action:** Presents a pre-permission dialog (modal) explaining the value of push notifications (e.g., "Stay updated on DMs, event reminders, and important activity..."). (Q1.10.8)
*   **User Action:** User interacts with the pre-permission dialog (e.g., taps "Allow" or "Maybe Later").
*   **System Action:** If user allows, the **native OS permission prompt** is triggered.
*   **User Action:** User grants or denies permission at the OS level.
*   **System Action:** Permission status is recorded; push notifications are enabled/disabled accordingly.

*   **Analytics:** [`flow_step: student.notification.view_feed`], [`flow_step: student.notification.tap_through {type}`], [`flow_step: student.notification.mark_all_read`], [`flow_step: student.notification.settings_changed {setting, value}`], [`event: system.notification.push_permission_prompted`], [`event: system.notification.push_permission_granted`], [`event: system.notification.push_permission_denied`]

---

## 4. State Diagrams

*   (Diagram: Event Occurs -> [Push Sent / In-App Indicator] -> User Taps Icon -> View Feed -> Tap Notification -> Deep Link -> [Mark All Read])
*   (Diagram: Settings -> Notifications -> Adjust Toggles -> Save Preferences)
*   (Diagram: First Event -> Pre-Prompt -> Allow -> OS Prompt -> Grant/Deny)

---

## 5. Error States & Recovery

*   **Trigger:** Error loading notification feed.
    *   **State:** Error message displayed.
    *   **Recovery:** Retry mechanism.
*   **Trigger:** Deep-link target content no longer exists.
    *   **State:** Tapping notification leads to an error state or a generic fallback screen ("Content unavailable").
    *   **Recovery:** N/A.
*   **Trigger:** Error saving notification preferences.
    *   **State:** Error message (Snackbar). Settings UI doesn't reflect the change.
    *   **Recovery:** User retries saving.

---

## 6. Acceptance Criteria

*   Notification feed is accessible via the header icon (Q1.10.1).
*   Correct event types trigger notifications (Q1.10.2).
*   Feed displays notifications chronologically without grouping (Q1.10.3).
*   Tapping a notification deep-links correctly (Q1.10.4) and marks it as read (Q1.10.5).
*   "Mark all as read" functionality works (Q1.10.6).
*   Notification preferences allow type-based and channel-based control (Q1.10.7).
*   Push permission flow (pre-prompt + OS prompt) is implemented correctly (Q1.10.8).

---

## 7. Metrics & Analytics

*   **Notification View Rate:** (# Notification Feed Views) / (# Active Users).
*   **Notification CTR:** (# Tapped Notifications) / (# Notifications Viewed/Received).
*   **Notification Preference Engagement:** % of users who customize settings.
*   **Push Permission Opt-in Rate:** % of users granting push permission.
*   **Analytics Events:** (Listed in Sequence section)

---

## 8. Design/UX Notes

*   Balance notification value with potential annoyance. Ensure relevance.
*   Make the notification feed clean and easy to scan.
*   Deep-linking (Q1.10.4) is critical for context.
*   Granular settings (Q1.10.7) empower users.
*   The push permission prompt (Q1.10.8) timing and messaging significantly impact opt-in rates.

---

## 9. API Calls & Data

*   **Get Notifications API Call:**
    *   **Request:** User ID, [Pagination Info].
    *   **Response:** List of Notification objects (ID, Type, Actor Info, Target Content Ref, Timestamp, Read Status).
*   **Mark Notifications Read API Call:**
    *   **Request:** User ID, List of Notification IDs or [Mark All = true].
    *   **Response:** Success/Failure.
*   **Update Notification Preferences API Call:**
    *   **Request:** User ID, Preference Settings (Map of type -> push/in-app boolean).
    *   **Response:** Success/Failure.
*   **Register Push Token API Call:**
    *   **Request:** User ID, Device Push Token.
    *   **Response:** Success/Failure.

---

## 10. Open Questions (Resolved for V1)

1.  **Feed Access Point:** Where is the notification feed accessed?
    *   ✅ **A1.10.1:** Bell icon (🔔) in global header (top-right).
2.  **V1 Trigger Events:** What actions trigger notifications?
    *   ✅ **A1.10.2:** Likes, Comments, Mentions, Follows, DMs, Event RSVP confirms, Space Invites.
3.  **Feed Presentation/Grouping:** How are notifications displayed/ordered/grouped?
    *   ✅ **A1.10.3:** Pure chronological list, no grouping V1.
4.  **Tap-Through Behavior:** Confirm tapping deep-links to context?
    *   ✅ **A1.10.4:** Yes, deep-links to relevant content.
5.  **Mark Read Mechanism:** How are notifications marked read?
    *   ✅ **A1.10.5:** Automatically on tap-through.
6.  **Bulk Actions V1:** Are bulk actions (mark all read, clear all) available?
    *   ✅ **A1.10.6:** "Mark all as read" available. No "clear all".
7.  **Settings Granularity V1:** What level of control in notification settings?
    *   ✅ **A1.10.7:** Type-based toggles (Likes, Comments, DMs, etc.), distinction between Push vs. In-app, Global mute option.
8.  **Push Permission Timing/Logic:** When/how is push permission requested?
    *   ✅ **A1.10.8:** After first meaningful event, using pre-permission modal before OS prompt.

**All questions resolved for V1.** 