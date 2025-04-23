# Flow: Builder - Manage Event Details & Attendees

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:**
*   [Flow: Builder - Create Event](./create_event.md)
*   [Flow: Student - View Event Details](../student/view_event_details.md)
*   [Hive UI Product Context & Documentation Principles](../../product_context.md)

**Figma Link (Overall Flow):** [Link to Figma Frame for Manage Event Screen/Options]

---

## 1. Title & Goal

*   **Title:** Builder Manage Event Details & Attendees
*   **Goal:** Allow a user with Builder permissions for an Event (the Host) to modify event details, view/manage the attendee list, and perform other administrative actions like cancelling the event.

---

## 2. Persona & Prerequisites

*   **Persona:** Builder (Host of the specific Event, likely Admin of the host Space)
*   **Prerequisites:**
    *   User is logged in and has hosting permissions for the target Event.
    *   The Event exists.
    *   User is viewing the Event Detail screen for the event they host.
        *   ❓ **Q1:** Where is the entry point for accessing event management tools located on the Event Detail screen for hosts?
        *   ✅ **A1:** A **three-dot menu (···)** in the top-right corner, visible only to the Host. Tapping reveals options: `✏️ Edit Event`, `📋 View RSVPs`, `❌ Cancel Event`.

---

## 3. Sequence (High-Level - Specific actions TBD)

*   **Trigger:** Host identifies the need to manage their event.
*   **System Action:** Host accesses management tools/options via the defined entry point (Q1).
*   **Screen(s):** Event Management View / Edit Form / Attendee List
    *   ❓ **Q2:** Is editing done via the same form as creation, or a separate interface? Is attendee management a separate screen?
    *   ✅ **A2:** Editing uses the **same scrollable form interface as creation**, pre-filled with data. `View RSVPs` leads to a separate attendee list screen.
*   **User Action:** Host selects an action (e.g., Edit Details, View Attendees, Cancel Event).
*   **User Action:** Host makes changes (e.g., updates description, removes an attendee).
*   **System Action:** Presents confirmation where necessary (e.g., Cancel Event, Remove Attendee).
*   **User Action:** Host confirms action.
*   **System Action:** Processes request (API call), provides feedback.

--- 

### 3.1 Edit Event Details
*   **Access:** Host taps `✏️ Edit Event` in the three-dot menu (Q1).
*   **Screen:** Edit Event Form (same interface as creation - Q2).
*   **User Action:** Host modifies fields (e.g., Name, Description, Time, Location, Cover Image, Visibility, etc.).
    *   ❓ **Q3:** Which fields are editable after publishing?
    *   ✅ **A3:** Editable in V1: Event Name, Date & Time, Location, Description, Cover Image. Locked (Not Editable) in V1: Visibility, Host Space.
*   **User Action:** Host taps "Update Event" to save changes.
*   **System Action:** API call to update event. Provide feedback (e.g., Snackbar confirmation).

### 3.2 Manage Attendees
*   **Access:** Host taps `📋 View RSVPs` in the three-dot menu (Q1).
*   **Screen:** Attendee List View (Separate screen - Q2).
*   **UI Elements:** Scrollable list of users who have RSVP'd ("Going").
    *   ❓ **Q4:** What information is shown for each attendee (Name, Avatar?)?
    *   ✅ **A4:** Each entry shows: Compact 32px **Avatar**, **Display Name** (tappable, links to profile). RSVP timestamp available on hover/long-press. Email/ID never exposed.
    *   Option to remove/block specific attendees? ❓ **Q5:** Can hosts remove specific RSVP'd users in V1?
    *   ✅ **A5:** No, removing/blocking attendees is **not available in V1**. Functionality deferred to future Space moderation tools.
*   **User Action (Remove Attendee):** N/A in V1.
*   **System Action:** N/A in V1.

### 3.3 Cancel Event
*   **Access:** Host taps `❌ Cancel Event` in the three-dot menu (Q1).
*   **System Action:** Show confirmation dialog ("Cancel this event? Attendees will be notified."). Options: Confirm Cancel, Keep Event.
    *   ❓ **Q6:** Is the confirmation text adequate? Does it mention notification?
    *   ✅ **A6:** Use refined text: "Cancel this event? This event will be marked as cancelled. All RSVP'd users will be notified. This action cannot be undone." Buttons: "[ Cancel ] [ Confirm Cancel ]".
    *   ❓ **Q7:** What destructive styling is used for "Confirm Cancel"?
    *   ✅ **A7:** "Confirm Cancel" button: Red text, matte charcoal background, gold hover glow. On confirm: Red hex-pulse ripple animation. Dialog background: Dimmed blur.
*   **User Action:** Host confirms cancellation.
*   **System Action:** API call to cancel event. Provide feedback.
    *   Notify attendees? ❓ **Q8:** Does cancellation automatically trigger notifications to RSVP'd users?
    *   ✅ **A8:** Yes, automatic in-app alerts and push notifications (if enabled) sent to all RSVP'd users: "[Event Name] has been cancelled by the host."
    *   How is a cancelled event displayed in the UI (e.g., on the detail screen, in feeds)? ❓ **Q9:** Visual treatment for cancelled events?
    *   ✅ **A9:**
        *   **Feeds:** Greyed-out card with a "CANCELLED" badge (top-left).
        *   **Event Detail:** Layout remains, but header image darkened, "This event has been cancelled" banner at top, RSVP/Join actions hidden.
        *   **Search/Discovery:** Hidden by default in V1.

*   **Analytics:** [`flow_step: builder.manage_event.initiated {event_id}`], [`flow_step: builder.manage_event.edit_saved {event_id}`], [`flow_step: builder.manage_event.attendee_removed {event_id}`] `(DEFERRED V1)`, [`flow_step: builder.manage_event.event_cancelled {event_id}`], [`flow_error: builder.manage_event.action_failed {event_id, action_type, reason}`]

---

## 4. State Diagrams

*   (Diagrams would be specific to Edit, Attendee Management, Cancel sub-flows)

---

## 5. Error States & Recovery

*   **Trigger:** API error during Edit/Manage/Cancel actions.
    *   **State:** Show error message (Snackbar). UI might revert changes if edit failed.
    *   **Recovery:** Builder retries the action.
*   **Trigger:** Trying to manage an event they don't have permissions for (shouldn't happen via UI guards).
    *   **State:** API error (Permission Denied).
    *   **Recovery:** N/A.

---

## 6. Acceptance Criteria

*   **Pre-conditions:** User is Host for the target Event.
*   **Success Post-conditions:**
    *   Host can access event management tools via the three-dot menu (A1, A2).
    *   Host can edit permitted event details (Name, Time, Location, Desc, Image) via the standard form (A3).
    *   Host can view the attendee list (Avatar, Name) (A4).
    *   Host cannot remove attendees in V1 (A5).
    *   Host can cancel the event with clear confirmation and consequences (A6, A7).
    *   Attendees are automatically notified upon cancellation (A8).
    *   Cancelled events are displayed clearly and consistently (A9).
    *   UI updates correctly reflect changes.
*   **General:**
    *   Actions require confirmation where appropriate.
    *   Error states are handled gracefully.

---

## 7. Metrics & Analytics

*   **Event Edit Rate:** (# Events edited) / (# Events created).
*   **Event Cancellation Rate:** (# Events cancelled) / (# Events created).
*   **Attendee Removal Rate:** (# Attendees removed by host) / (# Total RSVPs).
*   **Analytics Events:** (Listed in Sequence section)

---

## 8. Design/UX Notes

*   Easy access to Edit/Manage functions for hosts is important.
*   Distinguish clearly between viewing and editing states.
*   Attendee list management needs to consider privacy.
*   Cancellation flow must be clear about consequences (notification).

---

## 9. API Calls & Data

*   **Update Event API Call:**
    *   **Request:** Event ID, Builder User ID, Updated Fields (Name, Desc, Time, Location, Image, Visibility, etc.).
    *   **Response:** Success/Failure.
*   **Get Attendee List API Call:**
    *   **Request:** Event ID.
    *   **Response:** Paginated list of User objects who RSVP'd.
*   **Remove Attendee API Call:**
    *   **Request:** Event ID, Builder User ID, Target User ID.
    *   **Response:** Success/Failure.
*   **Cancel Event API Call:**
    *   **Request:** Event ID, Builder User ID.
    *   **Response:** Success/Failure.

---

## 10. Open Questions

1.  ~~**Entry Point:** Where on the Event Detail screen do Hosts access management tools?~~
    *   ✅ **A1:** Three-dot menu (···) top-right for Host, revealing Edit/View RSVPs/Cancel.
2.  ~~**Interface:** Is editing/managing done in a dedicated screen or integrated into the detail view?~~
    *   ✅ **A2:** Editing uses same form as creation. View RSVPs is a separate list screen.
3.  ~~**Editable Fields:** Which event details can be edited after publishing?~~
    *   ✅ **A3:** Editable: Name, Date/Time, Location, Desc, Cover Image. Locked: Visibility, Host Space.
4.  ~~**Attendee Info:** What details are shown in the attendee list for the host?~~
    *   ✅ **A4:** Avatar (32px), Display Name (tappable). RSVP timestamp on interaction. No PII.
5.  ~~**Remove Attendees:** Can hosts remove specific RSVP'd users in V1?~~
    *   ✅ **A5:** No, not in V1. Deferred to Space moderation tools.
6.  ~~**Cancel Dialog Text:** Is the proposed confirmation text for cancellation adequate?~~
    *   ✅ **A6:** Use refined text emphasizing consequences and notification.
7.  ~~**Cancel Dialog Styling:** What destructive styling for the "Confirm Cancel" button?~~
    *   ✅ **A7:** Red text, charcoal background, gold hover glow, red pulse animation on confirm.
8.  ~~**Cancellation Notification:** Are attendees automatically notified when an event is cancelled?~~
    *   ✅ **A8:** Yes, automatic in-app and push notifications sent.
9.  ~~**Cancelled Event Display:** How does a cancelled event appear in the UI?~~
    *   ✅ **A9:** Greyed-out in feeds ("CANCELLED" badge), darkened detail screen with banner, hidden in search (V1).

**All questions resolved for V1.** 