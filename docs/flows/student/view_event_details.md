# Flow: Student - View Event Details

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:**
*   [Flow: Student - Discover Events (via Feed)](./events_discovery.md)
*   [Hive UI Product Context & Documentation Principles](../../product_context.md)

**Figma Link (Overall Flow):** [Link to Figma Frame for Event Detail Screen]

---

## 1. Title & Goal

*   **Title:** Student View Event Details
*   **Goal:** Allow the student user to view comprehensive information about a specific Event encountered in their feed, understand its details, and decide whether to RSVP or take other relevant actions.

---

## 2. Persona & Prerequisites

*   **Persona:** Student (Authenticated User)
*   **Prerequisites:**
    *   User has tapped on an Event Card from their main feed or potentially another entry point (e.g., link in a post, notification).
    *   The target Event exists.

---

## 3. Sequence

*   **Trigger:** User taps an Event Card.
*   **System Action:** Navigate to the Event Detail Screen for the selected Event ID.
    *   Fetch detailed data for the Event.
*   **Screen:** Event Detail Screen
    *   **UI Elements:**
        *   **Header:** Event Cover Image (prominent), Event Name.
        *   **Date & Time:** Clearly displayed (e.g., "Friday, April 26, 8:00 PM - 11:00 PM").
        *   **Location:** Detailed location information (e.g., Building Name, Room Number, Address). **(Q1 Map):** If address exists, location text is tappable, linking to the **external device map app** (e.g., Apple/Google Maps).
        *   **Host Info:** Name and link to the hosting Space or organization profile.
        *   **RSVP Status/Action Button:**
            *   **State: Not RSVP'd:** Display **"RSVP"** button. **(Q2 CTA Style):** Gold pill, full-width (or prominent placement).
            *   **State: RSVP'd ("Going"):** Display **"✓ GOING"** button. **(Q3 Style):** Outlined pill, soft glow.
        *   **Attendee Info:** **(Q4 Count):** If RSVP'd, display count below/near button (e.g., "🔥 42 attending"). Count is hidden if not RSVP'd. No attendee list shown in V1.
        *   **Event Description:** Full description text.
        *   **(Optional) Tags/Categories:** Relevant event tags.
        *   **(Optional) Add to Calendar Button:** **(Q5 Include):** Yes. Secondary placement (e.g., below RSVP button or in menu).
        *   **(Optional) Share Event Button:** Button to share event link externally.
    *   **User Action (RSVP):** User taps the **"RSVP"** button.
        *   **System Action:** Process RSVP (API call), update button to "✓ GOING" state, provide feedback (haptics).
        *   *(RSVP Success Feedback details in RSVP flow, but primarily UI morph + haptic)*
    *   **User Action (Cancel RSVP):** User taps the **"✓ GOING"** button.
        *   **System Action (Q3 Cancel):** Open a **confirmation bottom drawer** ("Cancel your RSVP?"). Actions: "Confirm", "Keep Attending".
        *   **User Action:** Taps "Confirm" in bottom drawer.
        *   **System Action:** Process cancellation (API call), update button back to "RSVP" state, provide feedback.
        *   *(Cancel Success Feedback details in RSVP flow)*
    *   **User Action (View Host):** User taps the host Space/Org name.
        *   **System Action:** Navigate to the host Space/Org profile screen.
    *   **User Action (View Map):** User taps the location text (if tappable).
        *   **System Action:** Open external device map app (Q1).
    *   **User Action (Add to Calendar):** User taps "Add to Calendar" button.
        *   **System Action (Q5):** Trigger device calendar event creation flow with pre-filled details (Title, Time, Location, Notes from Description).
    *   **Analytics:** [`flow_step: event.details_viewed {event_id}`], [`flow_step: event.host_tapped {host_id}`], [`flow_step: event.map_viewed {event_id}`], [`flow_step: event.add_to_calendar_attempt {event_id}`], [`flow_step: event.share_attempt {event_id}`]

---

## 4. State Diagrams

*   **Initial (Not RSVP'd):** Screen loaded, shows event info, "RSVP" button visible.
*   **Initial (RSVP'd):** Screen loaded, shows event info, "✓ GOING" button visible, attendee count visible.
*   **RSVPing:** Loading state potentially on button after tap (brief).
*   **Cancelling:** Confirmation bottom drawer visible after tapping "✓ GOING".
*   **RSVP Success:** Button/UI updates to "✓ GOING" state, count appears.
*   **Cancel Success:** Button/UI updates to "RSVP" state, count disappears.

---

## 5. Error States & Recovery

*   **Trigger:** Failure to load Event details.
    *   **State:** Show loading indicator, then full-screen error (e.g., "Couldn't load Event details. Try again.") with back/retry.
    *   **Recovery:** User taps retry or navigates back.
    *   **Analytics:** [`flow_error: event.details_load_failed {event_id}`]
*   **Trigger:** Trying to view details of a non-existent/deleted Event.
    *   **State:** API returns 404. Display "Event not found" screen.
    *   **Recovery:** User navigates back.
*   **Trigger:** Failure during RSVP/Cancel API call.
    *   **State:** Show error message (Snackbar: "Failed to update RSVP. Please try again."). Button resets.
    *   **Recovery:** User retries action. (Error handling detailed in RSVP flow)

---

## 6. Acceptance Criteria

*   **Pre-conditions:** User taps a valid Event Card/link.
*   **Success Post-conditions:**
    *   User sees detailed information for the selected Event.
    *   Location info links to external map if address exists (Q1).
    *   User sees the correct binary RSVP state ("RSVP" or "✓ GOING") (Q2, Q3).
    *   User can cancel RSVP via a confirmation bottom drawer (Q3).
    *   Attendee count is shown only after RSVPing (Q4).
    *   "Add to Calendar" button triggers native calendar flow (Q5).
    *   User can navigate to the Host profile.
*   **General:**
    *   Loading and error states are handled gracefully.

---

## 7. Metrics & Analytics

*   **Event Detail View Rate:** (# Users viewing any Event Detail screen) / (# Users encountering Event Cards).
*   **RSVP Rate (from Details):** (# RSVP actions from Details screen) / (# Event Detail views).
*   **Host Profile Click Rate:** (# Taps on host link) / (# Event Detail views).
*   **Feature Usage:** Clicks on Map View, Add to Calendar, Share.
*   **Analytics Events:** (Listed in Sequence section)

---

## 8. Design/UX Notes

*   Clear hierarchy: Event Name, Time, Location, and RSVP action should be most prominent.
*   Readability of description is important.
*   **(Q4):** Attendee count provides social proof post-RSVP; hiding it initially encourages commitment.
*   RSVP cancel flow via bottom drawer prevents accidental cancellations.
*   **(Q5):** "Add to Calendar" provides utility and external commitment.

---

## 9. API Calls & Data

*   **Get Event Details API Call:**
    *   Request: Event ID, User ID.
    *   Response: Detailed Event object (... Location Details [Address, potentially Map Coords for external linking], ..., Attendee Count, Current User RSVP Status [None, Going]).
*   **(API Calls for RSVP/Cancel defined in RSVP flow)**

---

## 10. Open Questions

*   **(Resolved)** Q1: Map Integration links **external map app** if address exists.
*   **(Resolved)** Q2: Primary CTA is a binary **"RSVP" / "✓ GOING"** system.
*   **(Resolved)** Q3: RSVP'd state shown as "✓ GOING" button. Cancel via **tap -> confirmation bottom drawer**.
*   **(Resolved)** Q4: Attendee Info shows **count only**, **after user RSVPs**. No list V1.
*   **(Resolved)** Q5: **Yes**, include "Add to Calendar" functionality (triggers native flow).

*   **(Action Item):** Design the Event Detail screen layout, including header, info hierarchy.
*   **(Action Item):** Design the specific styles for "RSVP" and "✓ GOING" buttons (Gold pill vs. Outlined + glow).
*   **(Action Item):** Design the confirmation bottom drawer for cancelling RSVP.
*   **(Action Item):** Design the Attendee Count display ("🔥 42 attending").
*   **(Action Item):** Design placement and style for "Add to Calendar" and "Share" buttons. 