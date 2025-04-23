# Flow: Student - Comment on Content / View Thread

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:**
*   [Flow: Student - Feed Content Preview to Detail Drill-In](./feed_content_drill_in.md)
*   [Hive UI Product Context & Documentation Principles](../../product_context.md)

**Figma Link (Overall Flow):** [Link to Figma Frame for Comment Input/Thread View]

---

## 1. Title & Goal

*   **Title:** Student Comment on Content / View Thread
*   **Goal:** Define how a user can view existing comments on a piece of content and add their own comment or reply to an existing one, fostering discussion.

---

## 2. Persona & Prerequisites

*   **Persona:** Student (Logged-in User)
*   **Prerequisites:**
    *   User is viewing a piece of content that allows comments.
    *   ❓ **Q1:** What types of content can be commented on in V1? (e.g., Posts, Events, Ritual Updates?)
    *   ✅ **A1 (V1):** Users can comment on **Posts**, **Events**, and **Ritual Updates**. Commenting on other entities (e.g., direct comments, Spaces) is not supported in V1.
    *   ❓ **Q2:** Is commenting always enabled, or are there restrictions (e.g., host disabled comments, locked posts)?
    *   ✅ **A2 (V1):** Commenting is **always enabled** on supported content types. There is no feature for hosts to disable or lock comments in V1.

---

## 3. Sequence

### 3.1 Viewing Comments
*   **Trigger:** User wants to see or participate in the discussion around a piece of content.
*   **User Action:** User taps the "Comment" icon/action or the comment count displayed on the content card/detail view.
    *   ❓ **Q3:** What is the specific UI element for initiating a comment or viewing comments? (e.g., Speech bubble icon 💬? Location on card?)
    *   ✅ **A3 (V1):** A **speech bubble icon (💬)** and/or the comment count, located in a consistent position (e.g., bottom-left interaction row, next to the like icon).
*   **System Action:** Navigates to or reveals the comment thread view for that content item.
    *   ❓ **Q4:** How is the comment thread presented? (e.g., A separate screen? A bottom sheet sliding up? Inline expansion?)
    *   ✅ **A4 (V1):** A **modal bottom sheet** slides up, displaying existing comments and a text input field at the bottom.
*   **UI State (Comment Thread):** Displays existing comments.
    *   ❓ **Q5:** How are comments ordered? (e.g., Oldest first? Newest first? Algorithmic ranking?)
    *   ✅ **A5 (V1):** Comments are sorted **Newest first**.
    *   ❓ **Q6:** Are threaded replies supported (replies nested under specific comments)? If yes, how many levels deep?
    *   ✅ **A6 (V1):** Only **flat comments** are supported. There are no nested replies.
    *   ❓ **Q7:** Is pagination/lazy loading used for long comment threads?
    *   ✅ **A7 (V1):** Yes, **lazy loading/pagination** is implemented. A reasonable number (e.g., 20) are loaded initially, with more loaded as the user scrolls up.

### 3.2 Adding a New Top-Level Comment
*   **User Action:** User focuses on the comment input field (usually at the bottom or top of the thread view).
    *   ❓ **Q8:** Where is the input field for adding a *new* comment located?
    *   ✅ **A8 (V1):** A **sticky text input field** is located at the **bottom** of the bottom sheet.
*   **User Action:** User types their comment text.
    *   ❓ **Q9:** Are there character limits for comments? Any formatting support (e.g., bold, italics - likely no for V1)?
    *   ✅ **A9 (V1):** There is a character limit (e.g., **280 characters**). **No formatting** options (bold, italic) are available in V1. Basic `@mention` or `#hashtag` text might be recognized later but isn't explicitly supported by formatting tools now.
*   **User Action:** User taps the "Post" or "Send" button.
*   **System Action:** App initiates API call to create the new comment, associating it with the parent content and the user.
*   **UI Feedback (Success):**
    *   The new comment appears in the thread (optimistically?).
    *   ❓ **Q10:** How does the new comment appear? (e.g., Instantly added? Subtle animation? Highlighted temporarily?)
    *   ✅ **A10 (V1):** The comment is added to the list **optimistically** at the top (or bottom, depending on scroll position relative to newest). A subtle visual cue (e.g., background **glow fade-out**) indicates it's been added. The input field clears. The comment count on the original content card also increments optimistically.
*   **UI Feedback (Failure):**
    *   ❓ **Q11:** How are comment posting errors handled? (e.g., Error message near input field? Snackbar? Option to retry?)
    *   ✅ **A11 (V1):** The optimistically added comment is removed (or potentially marked with an error state). A **Snackbar/Toast** message indicates the failure. The original text **remains in the input field** allowing the user to easily **retry** sending.

### 3.3 Replying to an Existing Comment (If Q6=Yes)
*   **User Action:** User taps a "Reply" action associated with a specific comment.
*   **System Action:** Comment input field (Q8) might gain focus, potentially pre-filled with `@mention` of the user being replied to.
*   **User Action:** User types their reply text.
*   **User Action:** User taps "Post" or "Send".
*   **System Action:** API call to create the reply, associating it with the parent *comment*.
*   **UI Feedback (Success):** Reply appears nested under the parent comment (Q10).
*   **UI Feedback (Failure):** Handled similarly to Q11.

*   **Analytics:** [`flow_step: student.comment.view_thread {content_type, content_id}`], [`flow_step: student.comment.add_new {content_type, content_id}`], [`flow_step: student.comment.add_reply {parent_comment_id}`], [`flow_error: student.comment.post_failed {reason}`]

---

## 4. State Diagrams

*   (Diagram: View Content -> View Thread -> [Scroll/Paginate] -> Enter Comment -> Post -> Comment Appears -> [Enter Reply] -> Post Reply -> Reply Appears)

---

## 5. Error States & Recovery

*   **Trigger:** Error loading comment thread.
    *   **State:** Error message within the comment view area.
    *   **Recovery:** Retry mechanism (e.g., pull-to-refresh within comment view?).
*   **Trigger:** Error posting a comment/reply.
    *   **State:** Error message displayed (Q11).
    *   **Recovery:** User can retry posting.
*   **Trigger:** Commenting disabled (Q2) or content deleted.
    *   **State:** Comment input field disabled/hidden or error shown upon attempting to view/post.
    *   **Recovery:** N/A.

---

## 6. Acceptance Criteria

*   Users can access the comment thread for eligible content (Q1, Q3).
*   Comment thread displays correctly, including ordering and nesting (Q5, Q6, Q7).
*   Users can add new top-level comments (Q8, Q9).
*   Users can reply to existing comments if supported (Q6).
*   Posted comments/replies appear correctly with appropriate feedback (Q10).
*   Errors during loading or posting are handled gracefully with recovery options (Q11).
*   Comment controls respect disabled states (Q2).

---

## 7. Metrics & Analytics

*   **Comment View Rate:** (# Comment Threads Viewed) / (# Content Views).
*   **Commenting Rate:** (# Comments + Replies Posted) / (# Comment Threads Viewed).
*   **Reply Rate:** (# Replies) / (# Top-Level Comments).
*   **Average Comments per Item:** Total comments on items with comments enabled.
*   **Comment Post Failure Rate:** % of attempts resulting in error.
*   **Analytics Events:** (Listed in Sequence section)

---

## 8. Design/UX Notes

*   Make accessing comments intuitive.
*   Comment input should be readily available within the thread view.
*   Visual nesting (Q6) is key for readability if replies are supported.
*   Consider real-time updates (e.g., via WebSockets) for a more dynamic feel, or rely on manual refresh/re-entry.
*   Optimistic updates (Q10) improve perceived performance.

---

## 9. API Calls & Data

*   **Get Comments API Call:**
    *   **Request:** Content ID, Content Type, [Pagination Info], [Sort Order].
    *   **Response:** List of Comment objects (Comment ID, Author Info, Text, Timestamp, Reply Count?, Parent Comment ID?), Pagination Info.
*   **Create Comment API Call:**
    *   **Request:** User ID, Content ID, Content Type, Comment Text, [Optional: Parent Comment ID for replies].
    *   **Response:** Success/Failure, [New Comment Object?].

---

## 10. Open Questions

1.  **Commentable Content (V1):** What content types support comments?
    *   ✅ **A1 (V1):** Posts, Events, Ritual Updates.
2.  **Commenting Disabled:** Can authors/hosts disable comments?
    *   ✅ **A2 (V1):** No, commenting is always enabled.
3.  **Entry Point:** Where is the action to view/add comments?
    *   ✅ **A3 (V1):** Speech bubble icon (💬) and/or comment count.
4.  **Thread Presentation:** How is the comment thread displayed (Screen, Sheet, Inline)?
    *   ✅ **A4 (V1):** Modal bottom sheet.
5.  **Comment Ordering:** How are comments sorted?
    *   ✅ **A5 (V1):** Newest first.
6.  **Threaded Replies (V1):** Are nested replies supported? How deep?
    *   ✅ **A6 (V1):** No, only flat comments.
7.  **Pagination:** Is lazy loading used for long threads?
    *   ✅ **A7 (V1):** Yes, lazy loading/pagination.
8.  **New Comment Input:** Where is the input field located?
    *   ✅ **A8 (V1):** Sticky at the bottom of the sheet.
9.  **Comment Limits/Format:** Character limits? Formatting support?
    *   ✅ **A9 (V1):** 280 characters, no formatting V1.
10. **Success Feedback (Post):** How does a newly posted comment appear?
    *   ✅ **A10 (V1):** Yes, optimistic add to top, subtle glow fade-out, input clears, count updates.
11. **Error Handling (Post):** How are posting errors shown? Retry?
    *   ✅ **A11 (V1):** Remove optimistic comment (or mark with error), show Snackbar, keep text in input for retry.

**All questions resolved for V1.** 