# Flow: Student - Event Check-In

**Version:** 1.0 (Future Feature Definition)
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:**
*   [Flow: Student - View Event Details](./view_event_details.md)
*   [Flow: Student - RSVP / Cancel RSVP](./event_rsvp.md)
*   [Hive UI Product Context & Documentation Principles](../../product_context.md)

**Figma Link (Overall Flow):** [Link to Figma Frame for Check-In Interface/Options]

---

## 1. Title & Goal

*   **Title:** Student Event Check-In
*   **Goal:** Allow a student who has RSVP'd to an event to formally check-in upon arrival, confirming their attendance either via scanning a QR code provided by the host or automatically via geo-location proximity.

---

## 2. Persona & Prerequisites

*   **Persona:** Student (Attendee)
*   **Prerequisites:**
    *   User is logged in.
    *   User has RSVP'd ("Going") to the target Event.
    *   The Event is currently in progress or within a defined check-in window.
        *   ❓ **Q1:** How is the check-in window defined (e.g., 30 mins before start to 1 hour after start)? Is it configurable by the host?
        *   ✅ **A1 (V1):** Fixed window: **Opens 15 minutes before** event start time, **closes 45 minutes after** event start time. Not configurable by host in V1.
    *   ❓ **Q2:** What is the primary mechanism for V1 check-in? QR Code Scan, Geo-location, or Both?
    *   ✅ **A2 (V1):** **Both.** QR Code is the primary method, Geo-location serves as an optional/backup method.

---

## 3. Sequence (Scenario Dependent - QR vs Geo)

### 3.1 Scenario A: QR Code Check-In (If Q2 includes QR)
*   **Trigger:** Student arrives at the event venue. Host displays a unique QR code for the event.
*   **User Action:** Student navigates to the Event Detail screen.
    *   ❓ **Q3:** Where on the Event Detail screen is the "Check-In" action located during the active window?
    *   ✅ **A3 (V1):** During the active check-in window (A1), the RSVP/"Going" button area is replaced by a gold **"Check In Now" CTA button**.
*   **User Action:** Student taps the "Check In Now" action.
*   **System Action (Attempt Geo First):** App checks if location permissions are granted and if the user is within the defined geo-radius (A5).
    *   **If Geo Success:** Proceed directly to Geo Check-In feedback (Section 3.2 Feedback).
    *   **If Geo Fails (Permissions, Radius) or Not Available:** Proceed to QR Code flow.
*   **System Action (QR Flow):** App requests camera permissions (if not already granted).
*   **System Action:** Opens an in-app camera view/QR scanner.
*   **User Action:** Student points camera at the QR code provided by the host.
*   **System Action:** Scans QR code, validates it against the event.
*   **System Action:** API call to record check-in for the user at the event.
*   **Feedback:**
    *   **Success:** "You're checked in!" message + gold ripple animation. Haptic: Light tick.
    *   **Invalid QR:** "Invalid code — try again" message (red text). Haptic: Short buzz.
    *   **Already Checked In:** "Already checked in" message (gray text, replaces button). Haptic: Soft buzz.
    *   **Outside Window:** "Check-in is closed" message (replaces button if window closed). Haptic: Short vibrate.
    *   **Outside Geo Radius (if Geo attempted):** "Too far from event to check in" message. Haptic: Shake.
    *   ❓ **Q4:** What specific visual/haptic feedback should be used for success/failure states?
    *   ✅ **A4 (V1):**
        *   **Success:** "You're checked in!" message + gold ripple animation. Haptic: Light tick.
        *   **Invalid QR:** "Invalid code — try again" message (red text). Haptic: Short buzz.
        *   **Already Checked In:** "Already checked in" message (gray text, replaces button). Haptic: Soft buzz.
        *   **Outside Window:** "Check-in is closed" message (replaces button if window closed). Haptic: Short vibrate.
        *   **Outside Geo Radius (if Geo attempted):** "Too far from event to check in" message. Haptic: Shake.

### 3.2 Scenario B: Geo-Location Check-In (If Q2 includes Geo)
*   **Trigger:** Student taps the "Check In Now" button (A3) while within the predefined geofence radius (A5) during the check-in window (A1).
    *   ❓ **Q5:** How is the event location defined for geofencing? Does it rely on the host's input accuracy? What's the radius?
    *   ✅ **A5 (V1):** Location derived from event address (geocoded server-side). **Radius: 75 meters** with a ±10m accuracy buffer.
*   **System Action:** App (potentially in the background or upon opening) detects user's proximity to the event location.
*   **System Action:** Presents a prompt or notification to the user: "You're at [Event Name]! Check in?"
    *   ❓ **Q6:** How is this prompt presented? In-app banner? Push notification? Both?
    *   ✅ **A6 (V1):** Check-in is initiated by the user tapping the "Check In Now" button (A3). No separate automatic prompt is presented in V1. The button itself serves as the prompt during the window.
*   **User Action:** (Covered by tapping button in A3)
*   **System Action:** API call to record check-in (method=Geo).
*   **Feedback:**
    *   **Success:** Visual confirmation ("You're checked in!" + gold ripple), Haptic feedback (Light tick). Event Detail button updates to "✓ You're checked in". (Same as A4 Success).
    *   **Failure (Outside Radius/Window):** Feedback defined in A4.
    *   **Failure (Permissions):** If location permissions denied when button tapped, flow defaults immediately to QR scanner.
    *   ❓ **Q7:** What happens if the user misses or dismisses the prompt? Can they trigger the check-in manually from the Event Detail screen?
    *   ✅ **A7 (V1):** User interaction is always manual via the "Check In Now" button (A3). If Geo fails, it falls back to QR. If the window is missed, the button disappears or shows "Check-in is closed".

*   **Analytics:** [`flow_step: student.check_in.initiated {event_id, method(qr/geo)}`], [`flow_step: student.check_in.success {event_id, method}`], [`flow_error: student.check_in.failed {event_id, method, reason(invalid_code/already_checked_in/outside_window/permissions/geo_error/outside_radius)}`]

---

## 4. Host Perspective (Briefly)

*   ❓ **Q8:** How does the Host generate/display the QR code (if applicable)?
*   ✅ **A8 (V1):** Host accesses via "Manage Event" three-dot menu -> "Show QR Code". App displays a full-screen, dynamic QR code (refreshes every 60 seconds) for attendees to scan.
*   ❓ **Q9:** How does the Host view the list of checked-in attendees? Is it part of the existing "View RSVPs" screen or separate?
*   ✅ **A9 (V1):** Within the existing "View RSVPs" screen, Host uses a toggle: "Show Check-In Status". This filters/annotates the list, showing Name, .edu email, check-in timestamp, and profile link for checked-in users. Access restricted to host.

---

## 5. Error States & Recovery

*   **Trigger:** Invalid QR Code scanned.
    *   **State:** Error message displayed on scanner screen.
    *   **Recovery:** User rescans or confirms code with host.
*   **Trigger:** Geo-location check-in fails (permissions, accuracy, outside window/radius).
    *   **State:** Error message in prompt or on Event Detail screen.
    *   **Recovery:** User checks permissions, moves closer, or tries manual check-in if available (Q7).
*   **Trigger:** API error during check-in submission.
    *   **State:** Snackbar error.
    *   **Recovery:** User retries check-in action.

---

## 6. Acceptance Criteria

*   **Pre-conditions:** User RSVP'd, Event active, Check-in window open.
*   **Success Post-conditions (QR):**
    *   User can initiate QR scan from Event Detail (Q3).
    *   Valid QR code successfully checks user in.
    *   Appropriate feedback provided (Q4).
    *   Check-in status reflected in UI and backend.
*   **Success Post-conditions (Geo):**
    *   User can tap "Check In Now" button when within geofence during active window (A3, A5, A1).
    *   Successful Geo check-in occurs if conditions met upon tap.
    *   Appropriate feedback provided (A4).
    *   Check-in status reflected in UI and backend.
*   **General:**
    *   Check-in only possible within defined window (Q1).
    *   Users cannot check-in multiple times.
    *   Error states (invalid code, permissions, API errors) are handled gracefully.
    *   Host can facilitate/view check-ins (A8, A9).

---

## 7. Metrics & Analytics

*   **Check-In Rate:** (# Check-Ins) / (# RSVPs).
*   **Check-In Method Usage:** (# QR Check-Ins) vs (# Geo Check-Ins).
*   **Check-In Failure Rate:** (# Failed Check-In Attempts) / (# Total Check-In Attempts).
*   **Analytics Events:** (Listed in Sequence section)

---

## 8. Design/UX Notes

*   Check-in process should be fast and frictionless.
*   Clear feedback is crucial for success/failure.
*   QR code scanning needs good error tolerance.
*   Geo-location needs careful handling of permissions and accuracy issues.
*   Consider edge cases like poor network connectivity at the venue.

---

## 9. API Calls & Data

*   **Check-In API Call:**
    *   **Request:** User ID, Event ID, Timestamp, Method (QR/Geo), [Optional: QR Code Payload if method=QR].
    *   **Response:** Success/Failure (Reason: Already checked in, Invalid event, Outside window, etc.).
*   **Get Event QR Code API Call (Host):**
    *   **Request:** Event ID, Host User ID.
    *   **Response:** Unique QR Code Payload/Image URL.
*   **Get Checked-In Attendees API Call (Host):**
    *   **Request:** Event ID, Host User ID.
    *   **Response:** List of User objects who have checked in (potentially extending the RSVP list view).

---

## 10. Open Questions

1.  ~~**Check-In Window:** How is the active check-in period defined and configured?~~
    *   ✅ **A1 (V1):** Fixed: 15 mins before start to 45 mins after start. Not configurable.
2.  ~~**Primary Mechanism (V1):** QR Code, Geo-location, or Both?~~
    *   ✅ **A2 (V1):** Both. QR (Primary), Geo (Optional/Backup).
3.  ~~**Check-In Action Location:** Where on the Event Detail screen does the check-in button/action appear for attendees?~~
    *   ✅ **A3 (V1):** Gold "Check In Now" CTA replaces RSVP/Going button during the window.
4.  ~~**Feedback:** Specific visual/haptic feedback patterns for success/failure states?~~
    *   ✅ **A4 (V1):** Defined patterns for Success, Invalid QR, Already Checked In, Outside Window, Outside Radius.
5.  ~~**Geo-Location Definition:** How is the event location defined for geofencing? Radius? Accuracy handling?~~
    *   ✅ **A5 (V1):** Geocoded from address. 75m radius ±10m buffer.
6.  ~~**Geo-Location Prompt:** How is the automatic geo check-in prompted (Banner, Push, Both)?~~
    *   ✅ **A6 (V1):** User manually initiates via "Check In Now" button. No separate auto-prompt.
7.  ~~**Geo Prompt Recovery:** What if the user misses/dismisses the geo prompt? Manual trigger option?~~
    *   ✅ **A7 (V1):** Always manual trigger via button. Geo failure falls back to QR. Window closing removes button.
8.  ~~**Host QR Generation:** How does the host get/display the event's QR code?~~
    *   ✅ **A8 (V1):** Via "Manage Event" -> "Show QR Code" (dynamic, full-screen).
9.  ~~**Host View:** How does the host see who has checked in? (Part of RSVP list? Separate view?)~~
    *   ✅ **A9 (V1):** Via toggle/filter on "View RSVPs" list (shows Name, .edu, timestamp, profile link).

**All questions resolved for V1 definition.** 