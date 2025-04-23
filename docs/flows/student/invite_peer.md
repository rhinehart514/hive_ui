# Flow: Student - Invite Peer to Join Hive

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:** [Hive UI Product Context & Documentation Principles](../../product_context.md)
**Figma Link (Overall Flow):** [Link to Figma Frame for Invite Flow]

---

## 1. Title & Goal

*   **Title:** Student Invite Peer to Join
*   **Goal:** Allow an existing student user to generate and share an invitation link/code to encourage a peer to sign up for Hive.

---

## 2. Persona & Prerequisites

*   **Persona:** Student (Existing User, Authenticated)
*   **Prerequisites:**
    *   User is logged into the Hive app.
    *   User has navigated to the location where the "Invite Peer" action is available. ❓ **Q1:** Where is the primary entry point for this flow (e.g., Settings menu, dedicated Invite screen, Profile action)?
    *   Network connection is likely needed to generate a unique invite link/code.

---

## 3. Sequence

1.  **Screen:** Source Screen (e.g., Settings)
    *   **UI Elements:** "Invite a Peer" / "Invite Friends" button or menu item.
    *   **User Action:** Taps the "Invite" action.
    *   **Analytics:** [`flow_start: invite.peer`], [`flow_step: invite.initiate_tapped`]

2.  **Screen/Modal:** Invite Peer Interface
    *   **UI Elements:**
        *   Headline/Explanation (e.g., "Invite friends to Hive!")
        *   Generated unique invite link/code displayed prominently.
        *   "Copy Link/Code" button.
        *   "Share..." button (triggers native share sheet).
        *   (Optional) Brief description of potential referral benefits, if any. ❓ **Q2:** Are there any rewards/incentives for successful referrals?
    *   **System Action:** On loading this interface, generate or retrieve the user's unique invite link/code from the backend.
        *   ❓ **Q3:** Does the backend generate a unique link per user, or is it a code? Is it pre-generated or created on-demand? API call needed?
        *   **State:** Show a loading indicator while fetching/generating the link/code. ❓ **Q4:** What loading indicator style is used here?
    *   **Design/UX Notes:** Interface should be clean, making the link/code easy to see and copy/share.

3.  **Branch:** User chooses sharing method
    *   **Option A:** Tap "Copy Link/Code"
        *   **System Action:** Copy the link/code to the device clipboard.
        *   **UI Feedback:** Show brief confirmation message (e.g., `SnackBar` "Link Copied!").
        *   **Analytics:** [`flow_step: invite.link_copied`]
        *   **(End of Flow - User manually pastes elsewhere)**
    *   **Option B:** Tap "Share..."
        *   **System Action:** Trigger the native OS share sheet, pre-populating it with the invite link/code and potentially some default text (e.g., "Join me on Hive! [Link]").
            *   ❓ **Q5:** What is the default share text?
        *   **Analytics:** [`flow_step: invite.share_sheet_opened`]
        *   **External Interaction:** User selects app/contact within the native share sheet.
        *   **System Action (Post Share):** Return user to the Invite Peer interface.
        *   **Analytics:** [`flow_complete: invite.peer` *(Note: Completion here just means share sheet was used, not that invite was successful)*]
        *   **(End of Flow)**

---

## 4. State Diagrams

*   **Source Screen:** Initial state with Invite action available.
*   **Invite Interface (Loading):** Loading indicator shown while fetching/generating code.
*   **Invite Interface (Loaded):** Invite link/code displayed with Copy/Share buttons.
*   **Copy Confirmation:** Brief SnackBar shown.
*   **Share Sheet:** Native OS UI presented.
*   **Post-Share:** User returns to Invite Interface.

---

## 5. Error States & Recovery

*   **Trigger:** Failure to fetch/generate invite link/code from backend (e.g., network error, server error).
    *   **State:** Hide loading indicator. Display error message within the Invite Interface UI (e.g., "Could not generate invite link. Please try again."). Disable Copy/Share buttons.
    *   **Recovery:** User might retry by leaving and re-entering the flow, or a retry button could be provided.
    *   **Analytics:** [`flow_error: invite.generation_failed`]
*   **Trigger:** Error invoking native share sheet.
    *   **State:** Display error message (e.g., `SnackBar` "Could not open share options.").
    *   **Recovery:** User can try tapping "Share..." again or use the "Copy" option instead.
    *   **Analytics:** [`flow_error: invite.share_sheet_failed`]

---

## 6. Acceptance Criteria

*   **Pre-conditions:** User is logged in, on a screen with the Invite action.
*   **Success Post-conditions (Copy):**
    *   Invite link/code is successfully copied to the clipboard.
    *   User receives confirmation feedback.
    *   `flow_step: invite.link_copied` event logged.
*   **Success Post-conditions (Share):**
    *   Native share sheet is successfully presented with pre-populated invite info.
    *   User returns to the Invite interface after dismissing/using the share sheet.
    *   `flow_complete: invite.peer` event logged.
*   **Failure Post-conditions (Link Generation):**
    *   Error message is displayed within the Invite interface.
    *   Copy/Share buttons are disabled.
    *   `flow_error: invite.generation_failed` event logged.
*   **General:**
    *   A unique (or user-specific) invite link/code is displayed.
    *   Copy and Share actions function correctly.
    *   Loading and error states are handled gracefully.

---

## 7. Metrics & Analytics

*   **Invite Actions Initiated:** Count of `flow_start: invite.peer`.
*   **Shares via Copy:** Count of `flow_step: invite.link_copied`.
*   **Shares via Share Sheet:** Count of `flow_step: invite.share_sheet_opened`.
*   *(Backend Metric Needed):* Actual signups attributed to specific invite links/codes.
*   **Error Rate (Link Generation):** Frequency of `flow_error: invite.generation_failed`.
*   **Error Rate (Share Sheet):** Frequency of `flow_error: invite.share_sheet_failed`.
*   **Analytics Events:**
    *   `flow_start: invite.peer`
    *   `flow_step: invite.initiate_tapped`
    *   `flow_step: invite.link_copied`
    *   `flow_step: invite.share_sheet_opened`
    *   `flow_complete: invite.peer` *(User used share sheet)*
    *   `flow_error: invite.generation_failed`
    *   `flow_error: invite.share_sheet_failed`

---

## 8. Design/UX Notes

*   Make the invite link/code highly visible and easy to interact with.
*   Use standard platform share sheet invocation.
*   Ensure loading state (fetching link) is handled cleanly (Q4).
*   Provide clear confirmation feedback on copy action.

---

## 9. API Calls & Data

*   **Potential API Call:** `GET /user/invite-code` or similar to retrieve/generate the user's unique invite link/code (Q3).
*   **Data:** User's unique invite link/code.

---

## 10. Open Questions

1.  Where is the primary entry point/trigger for this "Invite Peer" flow located in the UI?
2.  Are there any rewards or incentives tied to successful referrals? (If so, the UI should mention them).
3.  Is the invite mechanism a unique link or a code? Is it pre-generated per user or created on demand? Does fetching/generating it require a specific API call?
4.  What loading indicator style is used while fetching/generating the invite link/code (respecting "no spinners")?
5.  What is the default share text accompanying the link/code when the native share sheet is opened? 