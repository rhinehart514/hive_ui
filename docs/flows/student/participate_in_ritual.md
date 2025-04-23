# Flow: Student - Participate in Active Ritual (THE BRACKET)

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:**
*   [Flow: Student - View Active Ritual (THE BRACKET) in Feed](./view_active_ritual_feed.md)
*   [Hive UI Product Context & Documentation Principles](../../product_context.md)
*   Context: THE BRACKET (Campus Tournament Engine)

**Figma Link (Overall Flow):** [Link to Figma Frame for BRACKET Engagement Hub Modal]

---

## 1. Title & Goal

*   **Title:** Student Participate in Active Ritual (**THE BRACKET Engagement Hub**)
*   **Goal:** Allow the student user to engage with the *current phase* of THE BRACKET Ritual (e.g., support a Space in a matchup, nominate) via a dedicated modal interface.

---

## 2. Persona & Prerequisites

*   **Persona:** Student (Authenticated User)
*   **Prerequisites:**
    *   User has tapped the active **BRACKET Status Strip** in the main feed.
    *   **THE BRACKET** Ritual is active.
    *   The specific mechanics of the *current phase* are defined (e.g., matchup engagement, nomination).

---

## 3. Sequence

*   **Trigger:** User taps the BRACKET Status Strip feed element.
*   **System Action:** Present the **BRACKET Engagement Hub**.
    *   **(Q1 Answer):** Present as a **Full-Screen Modal Dialog Route** using a **fast vertical slide-up** or **centered scale/fade-in transition** (~250-350ms).
*   **Screen:** BRACKET Engagement Hub Modal (Content varies by phase)
    *   **UI Elements (Example: Matchup Phase):**
        *   `(Component: RitualHeader)` Title "THE BRACKET - Round X", current competing Spaces, phase timer.
        *   **`(Component: LiveMomentumMeter)` Visual representation of current engagement score/lead between the two Spaces.**
        *   **`(Component: EngagementActions)` Buttons/Prompts:** "Support [Space A/B]" actions like:
            *   "Add Post" (Opens post creation focused on this matchup)
            *   "Comment in Thread" (Opens/navigates to a dedicated comment section for the matchup)
            *   "React Now" (Adds a reaction contributing to the score)
            *   "Invite Members" (Opens share/invite flow)
        *   **(Optional)** Mini-feed showing recent engagement actions for this matchup.
        *   Manual Dismiss Control (e.g., close button 'X', swipe down gesture).
    *   **User Action:** User interacts with `EngagementActions` (posts, comments, reacts, invites).
    *   **System Action:** Process the specific engagement action (client-side validation, API call).
        *   Show loading indicator **(Q3 Answer):** Loading state integrated **within the specific action button** (e.g., comment button shows spinner).
    *   **System Action (on Engagement Success):**
        *   API confirms successful engagement action.
        *   Display success feedback. **(Q4 Refined Answer):** Primarily **immediate, contextual feedback**: Post appears, comment added, reaction shown. Crucially, the **`LiveMomentumMeter` updates** visually (potentially with a subtle animation) to reflect the contribution. **Success haptics** on action completion.
        *   **(No automatic navigation)** User remains in the modal to potentially perform more actions.
    *   **System Action (on Engagement Failure):**
        *   API returns an error for the specific action.
        *   Display specific error message. **(Q6 Answer):** Use **Inline Errors** for validation (e.g., post too long), **Snackbar** for retryable API/network errors, **Modal Dialog (AlertDialog)** for non-retryable errors (e.g., rate limited, commenting disabled).
    *   **User Action:** User manually dismisses the modal (swipe/button).
        *   **(Q5 Refined Answer):** Navigation is **manual dismissal** by the user.
    *   **Analytics:** [`flow_step: ritual.bracket.engage_action {phase, action_type}`], [`flow_step: ritual.bracket.engage_success {phase, action_type}`], [`flow_error: ritual.bracket.engage_failed {phase, action_type, reason}`]

---

## 4. State Diagrams

*   **Initial State:** BRACKET Engagement Hub Modal loaded, displaying current phase info (e.g., matchup, meter).
*   **Engaging State:** User interacts with engagement actions.
*   **Submitting State:** Specific action button shows loading state (Q3).
*   **Success State:** Action completes, UI updates (e.g., comment appears), Momentum Meter potentially updates (Q4). User remains in modal.
*   **Error State:** Error message shown for failed action (Inline, Snackbar, or Dialog per Q6).
*   **Dismissed State:** User manually closes the modal (Q5).

---

## 5. Error States & Recovery

*   **Trigger:** Invalid input for an engagement action (e.g., comment validation).
    *   **State (Q6):** Input fields highlighted, error message shown **inline**.
    *   **Recovery:** User corrects input and re-submits the action.
*   **Trigger:** API Error for an engagement action (server issue, network error).
    *   **State (Q6):** **Snackbar** shown (e.g., "Couldn't post comment. Please try again."). Loading indicator hidden.
    *   **Recovery:** User taps "Retry" action on Snackbar.
*   **Trigger:** Specific API Error for an action (e.g., Rate Limited, Banned from commenting).
    *   **State (Q6):** **Modal Dialog (AlertDialog)** shown with specific message.
    *   **Recovery:** User taps "Got it"/"Okay", dialog dismissed. User remains in the Engagement Hub modal.
*   **Trigger:** Loss of network *before* submitting an action.
    *   **State:** Relevant action button potentially disabled or shows offline state.
    *   **Recovery:** User regains connection.

---

## 6. Acceptance Criteria

*   **Pre-conditions:** User has tapped the BRACKET Status Strip.
*   **Success Post-conditions:**
    *   User is presented with the BRACKET Engagement Hub modal showing the correct phase info (Q1).
    *   Relevant UI components for the current phase are displayed (e.g., Momentum Meter, Engagement Actions) (Q2).
    *   User can successfully perform engagement actions relevant to the phase.
    *   Loading state is shown on the specific action button (Q3).
    *   User receives immediate contextual feedback for successful actions, including updates to the Momentum Meter (Q4).
    *   User can manually dismiss the modal (Q5).
    *   Engagement data is correctly recorded.
*   **Failure Post-conditions:**
    *   User receives specific and actionable error messages for failed actions via the correct mechanism (Q6).
*   **General:**
    *   Interface clearly communicates the current phase's goal and engagement methods.

---

## 7. Metrics & Analytics

*   **Engagement Rate (by Phase):** (# Users performing any engagement action in phase) / (# Users viewing the Engagement Hub in phase).
*   **Engagement Frequency (by Phase):** Avg # of engagement actions per user per phase.
*   **Action Distribution (by Phase):** Breakdown of engagement action types (comments vs posts vs reacts).
*   **Error Rate (by Action Type):** (# Failed actions) / (# Attempted actions) for each type.
*   **Analytics Events:**
    *   `flow_step: ritual.bracket.hub_viewed {phase}`
    *   `flow_step: ritual.bracket.engage_action {phase, action_type}`
    *   `flow_step: ritual.bracket.engage_success {phase, action_type}`
    *   `flow_error: ritual.bracket.engage_failed {phase, action_type, reason}`

---

## 8. Design/UX Notes

*   Modal must clearly reflect the *current phase* of the long-running BRACKET.
*   **(Q2):** Define core components like `LiveMomentumMeter` and `EngagementActions` container.
*   **(Q4):** Focus on immediate, contextual feedback and meter updates rather than big celebratory animations for micro-engagements.
*   **(Q5):** Ensure easy manual dismissal.
*   Prioritize clarity on how user actions influence the *current phase's* outcome.

---

## 9. API Calls & Data

*   **Get BRACKET Phase Details API Call:** (Called when opening modal) Fetches detailed data for the current phase (matchup details, current scores for meter, rules, engagement options).
*   **Submit Engagement Action API Call(s):** Specific endpoints for each type of engagement (posting, commenting, reacting, inviting) tied to THE BRACKET context.
    *   **Request:** User ID, BRACKET ID, Phase ID, Action Data.
    *   **Response (Success):** Confirmation, potentially updated score/state for the Momentum Meter.
    *   **Response (Error):** Specific error code/message.

---

## 10. Open Questions

*   **(Resolved)** All previous Qs have been refined based on THE BRACKET context.

*   **(Action Item):** Design/Implement the `LiveMomentumMeter` component.
*   **(Action Item):** Design/Implement the `EngagementActions` container and its dynamic content based on phase.
*   **(Action Item):** Define the visual feedback loop for engagement actions impacting the `LiveMomentumMeter` (Q4).
*   **(Action Item):** Implement the manual dismissal interaction for the modal (Q5).
*   **(Action Item):** Define API endpoints for fetching phase details and submitting various engagement actions. 