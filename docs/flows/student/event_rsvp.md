# Flow: Student - RSVP / Cancel RSVP for Event

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:**
*   [Flow: Student - View Event Details](./view_event_details.md)
*   [Hive UI Product Context & Documentation Principles](../../product_context.md)

**Figma Link (Overall Flow):** [Link to Figma Frame for RSVP Actions/Feedback]

---

## 1. Title & Goal

*   **Title:** Student RSVP / Cancel RSVP for Event
*   **Goal:** Allow the student user to reliably change their RSVP status for an event and receive clear feedback on the action's success or failure.

---

## 2. Persona & Prerequisites

*   **Persona:** Student (Authenticated User)
*   **Prerequisites:**
    *   User is viewing the Event Detail screen (`view_event_details.md`).
    *   The relevant action button ("RSVP" or "✓ GOING") is visible and tappable.

---

## 3. Sequence

### 3.1 RSVP Action

*   **Trigger:** User taps the **"RSVP"** button on the Event Detail screen.
*   **System Action:**
    1.  Initiate API call to RSVP for the event.
    2.  Provide **immediate optimistic UI update (Q1 Answer):** Yes. Button morphs to the "✓ GOING" state.
    3.  **(Q2 Loading):** If API response delayed > ~400ms, show brief **inline loading indicator** within the button (e.g., spinner/hex orbit) before confirming success state.
    4.  Trigger **haptic feedback** (short, sharp success pattern) upon tap.
*   **System Action (on API Success):**
    *   API confirms successful RSVP.
    *   Ensure UI remains in the "✓ GOING" state.
    *   Attendee count becomes visible below the button ("🔥 [N] attending").
    *   **(Q3 Success Feedback):** No Snackbar needed. Feedback is the UI state change, haptic tick, count appearance, and potentially a subtle micro-glow effect.
*   **System Action (on API Failure):**
    *   API returns an error (e.g., event full, server error, user ineligible).
    *   **Revert UI:** Button morphs back to the "RSVP" state.
    *   Display specific error message (Snackbar: e.g., "Couldn't RSVP. Event might be full.", "Failed to RSVP. Please try again.").
    *   Trigger error haptic feedback.
*   **Analytics:** [`flow_step: event.rsvp_attempt {event_id}`], [`flow_step: event.rsvp_success {event_id}`], [`flow_error: event.rsvp_failed {event_id, reason}`]

### 3.2 Cancel RSVP Action

*   **Trigger:** User taps the **"✓ GOING"** button on the Event Detail screen.
*   **System Action:** Open confirmation **bottom drawer** ("Cancel your RSVP?"). Actions: "Confirm", "Keep Attending".
*   **User Action:** User taps **"Confirm"** in the bottom drawer.
*   **System Action:**
    1.  Dismiss the bottom drawer.
    2.  Initiate API call to cancel the RSVP.
    3.  Provide **immediate optimistic UI update (Q4 Answer):** Yes. Button morphs back to the "RSVP" state (Gold pill).
    4.  **(Q5 Loading):** If API response delayed > ~400ms, show brief **inline loading indicator** within the button (e.g., spinner) during the morph back.
    5.  Trigger **haptic feedback** (medium pulse - "release" tone) upon tap.
    6.  Attendee count ("🔥 [N] attending") fades out/disappears.
*   **System Action (on API Success):**
    *   API confirms successful cancellation.
    *   Ensure UI remains in the "RSVP" state and count remains hidden.
    *   **(Q6 Success Feedback):** No Snackbar needed. Feedback is the UI state change, count disappearance, and haptic rebound pulse.
*   **System Action (on API Failure):**
    *   API returns an error.
    *   **Revert UI:** Button morphs back to the "✓ GOING" state, attendee count reappears.
    *   Display specific error message (Snackbar: "Failed to cancel RSVP. Please try again.").
    *   Trigger error haptic feedback.
*   **Analytics:** [`flow_step: event.rsvp_cancel_initiated {event_id}`], [`flow_step: event.rsvp_cancel_confirmed {event_id}`], [`flow_step: event.rsvp_cancel_success {event_id}`], [`flow_error: event.rsvp_cancel_failed {event_id, reason}`]

---

## 4. State Diagrams

*   **RSVPing:** Button morphs to Going (optimistic), brief inline loading *only if delayed*, haptic.
*   **RSVP Success:** Button stays Going, count appears, subtle glow (optional).
*   **RSVP Fail:** Button reverts to RSVP, error snackbar, error haptic.
*   **Cancelling:** Bottom drawer shown -> Confirm tapped -> Button morphs to RSVP (optimistic), count disappears, brief inline loading *only if delayed*, haptic.
*   **Cancel Success:** Button stays RSVP.
*   **Cancel Fail:** Button reverts to Going, count reappears, error snackbar, error haptic.

---

## 5. Error States & Recovery

*   **Trigger:** API Error during RSVP or Cancel RSVP.
    *   **State:** UI reverts to the pre-action state. Error Snackbar displayed with a clear message.
    *   **Recovery:** User can tap the button again to retry the action.
*   **Trigger:** Trying to RSVP to an event that becomes full/closed between loading details and tapping RSVP.
    *   **State:** API failure, UI reverts, Snackbar explains (e.g., "Event is now full.").
    *   **Recovery:** User cannot RSVP.

---

## 6. Acceptance Criteria

*   **Pre-conditions:** User is viewing Event Detail screen.
*   **RSVP Success:**
    *   Tapping "RSVP" optimistically updates button to "✓ GOING" state (Q1).
    *   Success confirmed via API, UI remains "✓ GOING", attendee count appears.
    *   Appropriate loading (inline, only if delayed) (Q2) and success feedback (UI change, haptics, optional glow) (Q3) provided.
*   **Cancel RSVP Success:**
    *   Tapping "✓ GOING" shows confirmation bottom drawer.
    *   Confirming cancellation optimistically updates button to "RSVP" state and hides count (Q4).
    *   Success confirmed via API, UI remains "RSVP".
    *   Appropriate loading (inline, only if delayed) (Q5) and success feedback (UI change, haptics) (Q6) provided.
*   **Failure Cases:**
    *   UI correctly reverts to the previous state upon API failure.
    *   Clear error messages are displayed via Snackbar.
*   **General:**
    *   Interaction feels responsive due to optimistic updates.

---

## 7. Metrics & Analytics

*   **RSVP Success Rate:** (`event.rsvp_success` count) / (`event.rsvp_attempt` count).
*   **Cancel RSVP Success Rate:** (`event.rsvp_cancel_success` count) / (`event.rsvp_cancel_confirmed` count).
*   **API Failure Rate (RSVP/Cancel):** Count of specific failure reasons.
*   **Analytics Events:** (Listed in Sequence section)

---

## 8. Design/UX Notes

*   Optimistic UI updates are key for perceived responsiveness.
*   Clear distinction between button states ("RSVP" vs. "✓ GOING") is essential.
*   Haptic feedback reinforces the action.
*   Error handling needs to be clear and allow retries.
*   Avoid explicit success Snackbars; rely on UI state change and subtle feedback (Q3, Q6).
*   Loading indicators are subtle, inline, and only shown if necessary (Q2, Q5).

---

## 9. API Calls & Data

*   **RSVP for Event API Call:**
    *   **Request:** User ID, Event ID.
    *   **Response (Success):** Confirmation, updated attendee count (or signal to re-fetch).
    *   **Response (Error):** Specific error code/message (e.g., `EVENT_FULL`, `USER_INELIGIBLE`, `SERVER_ERROR`).
*   **Cancel RSVP for Event API Call:**
    *   **Request:** User ID, Event ID.
    *   **Response (Success):** Confirmation, updated attendee count (or signal to re-fetch).
    *   **Response (Error):** Specific error code/message.

---

## 10. Open Questions

*   **(Resolved)** Q1: Optimistic RSVP: **Yes**.
*   **(Resolved)** Q2: RSVP Loading: **Inline (button)**, only if delayed > ~400ms.
*   **(Resolved)** Q3: RSVP Success Msg: **No Snackbar**. Rely on UI change, haptics, count, optional glow.
*   **(Resolved)** Q4: Optimistic Cancel: **Yes**.
*   **(Resolved)** Q5: Cancel Loading: **Inline (button)**, only if delayed > ~400ms.
*   **(Resolved)** Q6: Cancel Success Msg: **No Snackbar**. Rely on UI change, haptics.

*   **(Action Item):** Design the specific morphing animations between "RSVP" and "✓ GOING" states.
*   **(Action Item):** Design the subtle inline loading indicator (spinner/hex pattern) for the buttons.
*   **(Action Item):** Define the specific haptic patterns for RSVP success, Cancel success, and errors.
*   **(Action Item):** Design the optional micro-glow effect for RSVP success. 