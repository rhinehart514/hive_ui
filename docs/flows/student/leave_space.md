# Flow: Student - Leave Space

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:**
*   [Flow: Student - View Space Details](./view_space_details.md)
*   [Hive UI Product Context & Documentation Principles](../../product_context.md)

**Figma Link (Overall Flow):** [Link to Figma Frame for Leave Space Confirmation]

---

## 1. Title & Goal

*   **Title:** Student Leave Space
*   **Goal:** Allow a student user to confirm their decision and successfully leave a Space they are currently a member of.

---

## 2. Persona & Prerequisites

*   **Persona:** Student (Authenticated User)
*   **Prerequisites:**
    *   User is currently a member of the target Space.
    *   User has initiated the Leave action from the Space Detail screen (e.g., via Swipe Left on the "JOINED" button and tapping the revealed "Leave Space ❌" action, as defined in `view_space_details.md`).

---

## 3. Sequence

*   **Trigger:** User taps the revealed "Leave Space ❌" action on the Space Detail screen.
*   **System Action:** Display a confirmation dialog.
    *   **UI Element:** Standard HIVE `AlertDialog`.
    *   **Content:**
        *   Title: "Leave [Space Name]?"
        *   **(Q1 Answer - Body Text V1):**
            ```
            You'll lose access to this Space's posts, rituals, and chats.
            If you hold any roles, they'll be removed automatically.
            
            Are you sure?
            ```
        *   Actions:
            *   **Confirm Button:** "Leave Space". **(Q2 Styling):** HIVE Destructive Style - Matte charcoal base, deep red-gold text. Hover/Press: Crimson-gold ripple/glow. Tap Animation: Fades black -> spinning hexagon -> closes modal.
            *   **Cancel Button:** "Cancel" (Standard HIVE tertiary/text button style).
*   **User Action:** User taps the **"Leave"** button.
    *   **System Action:** Initiate API call to leave the Space. **(Q3 Loading/Transition):**
        1.  "Leave" button animates inward (shrink/fade).
        2.  Button label briefly replaced by subtle hex-loading spinner (⭮).
        3.  Dialog *simultaneously* dims and fades out smoothly (~400-500ms).
        4.  (Optional: Subtle audio cue + haptic tick during fade).
    *   **System Action (on Success):**
        *   API confirms successful leave (Ideally response arrives *during* fade-out).
        *   Update the UI on the underlying Space Detail screen *immediately* as dialog fully disappears to reflect non-member status (button changes back to "Join" or "Request to Join").
        *   **(Q4 Answer - Success Feedback):** No Snackbar confirmation needed. The UI update is the primary feedback. (Optional: Brief ambient glow on updated element or hex-pulse icon flash if roles lost).
    *   **System Action (on Failure):**
        *   API returns an error (during or after fade attempt).
        *   Ensure dialog is fully dismissed.
        *   Display error message (e.g., Snackbar: "Failed to leave Space. Please try again."). The underlying screen still shows the user as a member.
*   **User Action:** User taps the **"Cancel"** button.
    *   **System Action:** Dismiss the dialog. No further action occurs. The user remains on the Space Detail screen as a member.
*   **Analytics:** [`flow_step: space.leave_confirm_shown {space_id}`], [`flow_step: space.leave_confirmed {space_id}`], [`flow_step: space.leave_cancelled {space_id}`], (Success/Failure events are in `view_space_details.md` but could be duplicated here for clarity: `space.leave_success {space_id}`, `flow_error: space.action_failed {space_id, action_type: 'leave', reason}`)

---

## 4. State Diagrams

*   **Initial:** Confirmation Dialog visible.
*   **Submitting:** Dialog fading out, button briefly shows spinner (transition state).
*   **Success:** Dialog dismissed, underlying UI updated instantly (primary feedback).
*   **Failure:** Dialog dismissed, error feedback shown.
*   **Cancelled:** Dialog dismissed, no change to membership status.

---

## 5. Error States & Recovery

*   **Trigger:** Failure during Leave API call (after confirmation).
    *   **State:** Loading indicator hidden, error message shown (e.g., Snackbar).
    *   **Recovery:** User may need to re-initiate the Leave process from the Space Detail screen.
    *   **Analytics:** `flow_error: space.action_failed {space_id, action_type: 'leave', reason}`

---

## 6. Acceptance Criteria

*   **Pre-conditions:** User is a member and initiates the leave action.
*   **Success Post-conditions:**
    *   Confirmation dialog is displayed with correct text and actions (Q1, Q2).
    *   User can confirm leaving the Space.
    *   Upon successful leave, the user's membership status is updated in the UI and backend.
    *   Appropriate loading (Q3) and success feedback (Q4) are provided.
*   **Cancel Post-conditions:**
    *   User can cancel the leave action from the dialog.
    *   User remains a member of the Space.
*   **General:**
    *   Destructive action is clearly indicated.

---

## 7. Metrics & Analytics

*   **Leave Confirmation Rate:** (# Users confirming Leave) / (# Users shown Leave confirmation dialog).
*   **Leave Success Rate:** (# Successful Leave actions) / (# Users confirming Leave).
*   **Analytics Events:** (Listed in Sequence section)

---

## 8. Design/UX Notes

*   Confirmation step is crucial to prevent accidental leaves.
*   Destructive action styling must be clear **using the HIVE charcoal/red-gold approach, avoiding standard red**.
*   Loading state is handled via a smooth transition ripple (button animation + dialog fade), not a static indicator.
*   Optional: Consider brief ambient glow on the updated UI element or a hex-pulse icon flash if roles/progress were lost.
*   **(V2 Suggestion):** Consider dynamically inserting context-specific warning lines into the confirmation dialog based on user role/status (e.g., Builder, Ritual participant).
*   Success feedback relies on the immediate UI state change, avoiding redundant Snackbars.

---

## 9. API Calls & Data

*   **Leave Space API Call:** (Defined in `view_space_details.md`)
    *   **Request:** Space ID, User ID.
    *   **Response:** Success/Failure confirmation.

---

## 10. Open Questions

*   **(Resolved)** Q1: Confirmation Dialog body text defined (V1: Lose access to posts/rituals/chats, roles removed automatically).
*   **(Resolved)** Q2: Confirmation Dialog styling defined (HIVE Destructive: Charcoal base, red-gold text, specific tap animation; Cancel: Standard tertiary).
*   **(Resolved)** Q3: Loading Indicator handled via integrated animation (button morph + dialog fade-out), no static spinner shown after dialog closes.
*   **(Resolved)** Q4: Success Feedback relies on immediate UI update (no Snackbar). Optional ambient feedback possible.

*   **(Action Item):** Design the specific HIVE AlertDialog confirmation appearance.
*   **(Action Item):** Implement the Leave button destructive styling and animation.
*   **(Action Item):** Implement the integrated loading/dialog fade transition.
*   **(Action Item):** Design optional ambient success feedback (glow/pulse) on the updated UI. 