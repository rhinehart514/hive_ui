# Flow: Student - Like / Unlike Content

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:**
*   [Hive UI Product Context & Documentation Principles](../../product_context.md)

**Figma Link (Overall Flow):** [Link to Figma Frame for Like Button Interaction]

---

## 1. Title & Goal

*   **Title:** Student Like / Unlike Content
*   **Goal:** Define the simple interaction for a user expressing appreciation (liking) for a piece of content and subsequently removing that appreciation (unliking).

---

## 2. Persona & Prerequisites

*   **Persona:** Student (Logged-in User)
*   **Prerequisites:**
    *   User is viewing a piece of content that supports liking.
    *   ❓ **Q1:** What types of content support likes in V1? (e.g., Posts/Drops? Events? Comments? Ritual Updates?)

---

## 3. Sequence of Actions

*   **Trigger:** User is viewing content that can be liked.
    *   ❓ **Q1:** What types of content can be liked in V1? (e.g., Posts, Events, Comments, Spaces?)
    *   ✅ **A1 (V1):** Users can like **Posts** and **Events**. Liking Comments, Spaces, or other entities is not supported in V1.
*   **UI State (Initial):** The content card displays an affordance for liking (e.g., a heart icon) and potentially the current like count (if > 0).
    *   ❓ **Q2:** What is the specific UI element for liking? (e.g., Heart icon? Thumbs up? Location on the card?)
    *   ✅ **A2 (V1):** A **heart icon (♡/❤️)** located in a consistent position on the content card (e.g., bottom-left interaction row).
*   **User Action:** User taps the "Like" icon.
*   **UI Feedback (Immediate):**
    *   ❓ **Q3:** What immediate visual feedback occurs on tap? (e.g., Icon changes state - outline to filled, color change? Animation - scale, bounce?)
    *   ✅ **A3 (V1):** The heart icon **changes state** (e.g., outline to filled gold ❤️). A subtle **animation** (e.g., scale pulse) occurs.
    *   ❓ **Q4:** Is the like count updated optimistically in the UI, or only after backend confirmation?
    *   ✅ **A4 (V1):** The like count is **updated optimistically** in the UI immediately upon tapping Like/Unlike.
*   **System Action (Async):** App sends a request to the backend to record the "like" interaction (associating the user ID with the content ID).
*   **System Action (Success):** Backend confirms the like has been recorded.
    *   *No explicit UI feedback needed if optimistic update was successful.*
*   **System Action (Failure):** Backend indicates the like could not be recorded (e.g., network error, server issue).
    *   ❓ **Q5:** How is a failure to record the like handled in the UI? (e.g., Revert the icon state? Revert the count? Show an error message? Retry?)
    *   ✅ **A5 (V1):** The UI **silently reverts** the icon state and the optimistic count back to their pre-tap state. No error message is shown to the user for this specific action in V1 to keep the experience lightweight.
*   **User Action (Unlike):** User taps the "Like" icon again on content they have already liked.
*   **UI Feedback (Immediate):** Icon changes back to the unliked state (e.g., filled to outline), count decrements optimistically.
*   **System Action (Async):** App sends a request to the backend to remove the "like" interaction.
*   **System Action (Success/Failure):** Handled similarly to liking (silent revert on failure).

*   **Analytics:** [`interaction: student.content.like {content_id, content_type}`], [`interaction: student.content.unlike {content_id, content_type}`], [`flow_error: student.content.like_failed {content_id, reason}`], [`flow_error: student.content.unlike_failed {content_id, reason}`]

---

## 4. State Diagrams

*   (Simple Diagram: Inactive State -> Tap -> Liked State (Optimistic) -> API Call -> [Success: Stays Liked | Failure: Reverts to Inactive])
*   (Simple Diagram: Liked State -> Tap -> Inactive State (Optimistic) -> API Call -> [Success: Stays Inactive | Failure: Reverts to Liked])

---

## 5. Error States & Recovery

*   **Trigger:** API error when trying to like or unlike.
    *   **State:** UI optimistically changes, then reverts upon API failure. Optional error message (Q5).
    *   **Recovery:** User can tap the like button again.
*   **Trigger:** Content no longer exists when like/unlike is attempted.
    *   **State:** API call fails, UI reverts.
    *   **Recovery:** N/A (Content is gone).

---

## 6. Acceptance Criteria

*   Like action (Q2) is present on eligible content types (Q1).
*   Tapping the like action toggles the visual state (Q3) and like count (Q4) optimistically.
*   Like/Unlike action correctly updates the backend state.
*   UI reverts correctly if the backend action fails.
*   Error feedback (Q5) is provided if defined.

---

## 7. Metrics & Analytics

*   **Like Rate:** (# Likes) / (# Content Views).
*   **Unlike Rate:** (# Unlikes) / (# Likes).
*   **Likes per User:** Average likes per active user.
*   **Like Action Failure Rate:** % of like/unlike taps resulting in failure/reversion.
*   **Analytics Events:** (Listed in Sequence section)

---

## 8. Design/UX Notes

*   The like action should be immediate and satisfying (optimistic updates + animation).
*   Icon choice (Q2) and active state visual (Q3) should be clear and align with HIVE branding.
*   Displaying the like count (Q4) provides social proof.
*   Error handling (Q5) should generally be silent reversion unless failure is persistent.

---

## 9. API Calls & Data

*   **Like Content API Call:**
    *   **Request:** User ID, Content ID, Content Type.
    *   **Response:** Success/Failure.
*   **Unlike Content API Call:**
    *   **Request:** User ID, Content ID, Content Type.
    *   **Response:** Success/Failure.

---

## 10. Open Questions

1.  **Likable Content Types:** What items can users like in V1?
    *   ✅ **A1 (V1):** Posts and Events.
2.  **Like UI Element:** What is the specific icon/button? Where is it positioned?
    *   ✅ **A2 (V1):** Heart icon (♡/❤️), bottom-left interaction row of card.
3.  **Immediate Feedback:** What visual change/animation happens instantly on tap?
    *   ✅ **A3 (V1):** Icon state change (outline to filled gold ❤️), subtle scale pulse animation.
4.  **Optimistic Update:** Is the like count updated immediately or after confirmation?
    *   ✅ **A4 (V1):** Count updated optimistically.
5.  **Failure Handling:** How are failures communicated/handled (icon state, count, error message)?
    *   ✅ **A5 (V1):** Silent revert of icon state and optimistic count. No error message.

**All questions resolved for V1.** 