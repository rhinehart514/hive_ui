# Flow: Student - Edit / Delete Post

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:**
*   [Flow: Student - Create Text Post](./create_text_post.md)
*   [Flow: Student - Create Media Post](./create_media_post.md)
*   [Hive UI Product Context & Documentation Principles](../../product_context.md)

**Figma Link (Overall Flow):** [Link to Figma Frame for Edit/Delete Options & UI]

---

## 1. Title & Goal

*   **Title:** Student Edit / Delete Post
*   **Goal:** Allow a user to modify the content or settings of their own previously created posts (Drops), or to permanently remove them.

---

## 2. Persona & Prerequisites

*   **Persona:** Student (Logged-in User)
*   **Prerequisites:**
    *   User is viewing a post they authored.
    *   ❓ **Q1:** Can users edit/delete posts indefinitely, or is there a time limit after posting?

---

## 3. Sequence

### 3.1 Accessing Edit/Delete Options
*   **Trigger:** User wants to modify or remove their own post.
*   **User Action:** User accesses the management options for their post.
    *   ❓ **Q2:** Where are the "Edit Post" and "Delete Post" actions located? (e.g., In a three-dot menu on the post card/detail view?)

### 3.2 Editing a Post
*   **Trigger:** User is viewing their own post.
*   ❓ **Q1:** Is there a time limit for editing posts after creation?
    *   ✅ **A1 (V1):** **No time limit** for editing posts in V1.
*   **User Action:** User initiates the "Edit" action.
    *   ❓ **Q2:** Where is the "Edit" action located? (e.g., Three-dot menu on the post card? A dedicated icon?)
    *   ✅ **A2 (V1):** Accessible via the **three-dot menu (...)** on the user's own post card.
*   **System Action:** Opens the Post Composer view, pre-filled with the existing post content.
    *   ❓ **Q3:** Does editing open the same composer used for creating new posts?
    *   ✅ **A3 (V1):** Yes, the **same composer component** is used, pre-filled with the post data.
*   **User Action:** User modifies the post content (text, adds/removes media).
    *   ❓ **Q4:** What fields can be edited? (e.g., Text only? Media? Target Space? Visibility?)
    *   ✅ **A4 (V1):** User can edit the **text content** and **add/remove/replace media**. Target **Space** and **Visibility** are **locked** after initial posting in V1.
*   **User Action:** User confirms the changes (e.g., taps "Update" or "Save").
*   **System Action:** Submits the updated post data to the backend.
*   **UI Feedback (Success):**
    *   ❓ **Q5:** What feedback is given on successful edit? (e.g., Snackbar "Post updated"? Post visually refreshes in the feed?)
    *   ✅ **A5 (V1):** A **Snackbar** confirms "Post updated successfully." The post content in the feed/detail view **refreshes** to show the changes.
    *   ❓ **Q6:** Is there any visual indicator on the post that it has been edited (e.g., "(edited)" timestamp)?
    *   ✅ **A6 (V1):** Yes, a subtle **"(edited)" label** appears near the post timestamp.
*   **UI Feedback (Failure):**
    *   ❓ **Q7:** How are edit failures handled? (e.g., Error message? Option to retry? Changes lost?)
    *   ✅ **A7 (V1):** A **Snackbar** indicates "Failed to update post. Please try again." The composer **remains open with the attempted changes**, allowing the user to retry. An automatic retry might happen in the background.

### 3.3 Deleting a Post
*   **Trigger:** User is viewing their own post.
*   **User Action:** User initiates the "Delete" action (likely from the same menu as Edit - Q2).
    *   ❓ **Q8:** Is there a confirmation dialog before deleting? (e.g., "Delete this post permanently?")
    *   ✅ **A8 (V1):** Yes, a standard confirmation **dialog**: "**Delete this post?** This action cannot be undone." Options: [Delete] [Cancel].
    *   ❓ **Q9:** What is the styling/emphasis for the confirmation options? (e.g., Destructive action styling for "Delete"?)
    *   ✅ **A9 (V1):** The **"Delete" button** should have **destructive action styling** (e.g., red text or a distinct destructive button style within the app's theme).
*   **User Action:** User confirms deletion.
*   **System Action:** Sends a delete request to the backend for the specific post ID.
*   **UI Feedback (Success):**
    *   ❓ **Q10:** What happens visually after successful deletion? (e.g., Post disappears from feed? Snackbar confirmation?)
    *   ✅ **A10 (V1):** The post is immediately **removed** from the UI (feed, profile, etc.). A **Snackbar** confirms "Post deleted."
*   **UI Feedback (Failure):**
    *   ❓ **Q11:** How are deletion failures handled? (e.g., Error message? Post remains visible?)
    *   ✅ **A11 (V1):** A **Snackbar** indicates "Failed to delete post. Please try again." The post **remains visible** in the UI. The user can attempt deletion again.

*   **Analytics:** [`flow_step: student.post.manage.edit_initiated`], [`flow_step: student.post.manage.edit_success`], [`flow_error: student.post.manage.edit_failed {reason}`], [`flow_step: student.post.manage.delete_initiated`], [`flow_step: student.post.manage.delete_confirmed`], [`flow_step: student.post.manage.delete_success`], [`flow_error: student.post.manage.delete_failed {reason}`]

---

## 4. State Diagrams

*   (Diagram: View Post -> Options -> Edit -> Modify -> Save -> Update Success/Fail)
*   (Diagram: View Post -> Options -> Delete -> Confirm -> Delete Success/Fail)

---

## 5. Error States & Recovery

*   **Trigger:** Trying to edit/delete a post that isn't theirs (should be prevented by UI).
    *   **State:** Options (Q2) should not be visible.
*   **Trigger:** API error during save/update (Edit).
    *   **State:** Error message displayed (Q7).
    *   **Recovery:** User can retry saving.
*   **Trigger:** API error during deletion.
    *   **State:** Error message displayed (Q11).
    *   **Recovery:** User can retry deletion.
*   **Trigger:** Post deleted by other means while user is attempting edit/delete.
    *   **State:** API call fails, error message shown.

---

## 6. Acceptance Criteria

*   Users can access Edit/Delete options (Q2) only for their own posts, within the allowed timeframe (Q1).
*   Edit action opens the correct interface (Q3) with existing content.
*   Users can modify permitted fields (Q4) and save changes.
*   Successful edit updates the post and provides feedback (Q5, Q6).
*   Edit failures are handled gracefully (Q7).
*   Delete action requires confirmation (Q8, Q9).
*   Successful deletion removes the post and provides feedback (Q10).
*   Delete failures are handled gracefully (Q11).

---

## 7. Metrics & Analytics

*   **Edit Rate:** (# Posts Edited) / (# Posts Created).
*   **Delete Rate:** (# Posts Deleted) / (# Posts Created).
*   **Edit Failure Rate:** % of edit attempts failing.
*   **Delete Failure Rate:** % of delete attempts failing.
*   **Analytics Events:** (Listed in Sequence section)

---

## 8. Design/UX Notes

*   Edit/Delete options should be easily accessible for owned posts but not intrusive.
*   Confirmation for deletion is critical to prevent accidental data loss.
*   Consider implications if an edited/deleted post was already reposted or interacted with.
*   Indicating edited status (Q6) can be important for transparency.

---

## 9. API Calls & Data

*   **Update Post API Call:**
    *   **Request:** User ID, Post ID, Updated Content Fields (Text, Media Refs?, Visibility?).
    *   **Response:** Success/Failure, [Updated Post Object?].
*   **Delete Post API Call:**
    *   **Request:** User ID, Post ID.
    *   **Response:** Success/Failure.

---

## 10. Open Questions

1.  **Edit/Delete Time Limit:** Is there a time limit after posting?
    *   ✅ **A1 (V1):** No time limit.
2.  **Action Location:** Where are the Edit/Delete actions found?
    *   ✅ **A2 (V1):** Three-dot menu on own post card.
3.  **Edit Interface:** Same as composer? Different UI?
    *   ✅ **A3 (V1):** Yes, same composer, pre-filled.
4.  **Editable Fields (V1):** What can be changed (Text, Media, Visibility, Space)?
    *   ✅ **A4 (V1):** Text content, media. Space & Visibility locked.
5.  **Edit Success Feedback:** How is successful edit confirmed?
    *   ✅ **A5 (V1):** Snackbar "Post updated", UI refresh.
6.  **Edited Indicator:** Is an "(edited)" label shown on modified posts?
    *   ✅ **A6 (V1):** Yes, "(edited)" label near timestamp.
7.  **Edit Failure Handling:** How are save failures handled in the UI?
    *   ✅ **A7 (V1):** Snackbar error, composer stays open with changes, allows retry.
8.  **Delete Confirmation Text:** What is the confirmation dialog text/labels?
    *   ✅ **A8 (V1):** Yes, dialog "Delete this post?"
9.  **Delete Confirmation Styling:** What styling for the destructive delete button?
    *   ✅ **A9 (V1):** "Delete" button has destructive styling.
10. **Delete Success Feedback:** How is successful deletion confirmed?
    *   ✅ **A10 (V1):** Post removed from UI, Snackbar "Post deleted".
11. **Delete Failure Handling:** How are delete failures shown?
    *   ✅ **A11 (V1):** Snackbar error, post remains visible.

**All questions resolved for V1.** 