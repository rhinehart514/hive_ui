# Flow: Student - Create Text-Only Post

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:**
*   [Flow: Student - Post Draft Handling](./post_draft_handling.md)
*   [Hive UI Product Context & Documentation Principles](../../product_context.md)

**Figma Link (Overall Flow):** [Link to Figma Frame for Text Post Composer]

---

## 1. Title & Goal

*   **Title:** Student Create Text-Only Post (Drop)
*   **Goal:** Allow a user to compose and publish a text-based post (Drop) to a specific Space they are a member of.

---

## 2. Persona & Prerequisites

*   **Persona:** Student (Logged-in User)
*   **Prerequisites:**
    *   User is logged in.
    *   User is a member of at least one Space where they have permission to post.

---

## 3. Sequence

### 3.1 Initiating Post Creation
*   **Trigger:** User wants to share a text update.
*   **User Action:** User taps the primary "Create Post" / "+" action button.
    *   ❓ **Q1:** Where is the primary create action button located? (e.g., Floating Action Button on feed? Button in header? Tab bar?)
    *   ✅ **A1 (V1):** A **Floating Action Button (FAB)** '+' is present on the main **Feed** and also contextually **within Space views**.
*   **System Action:** Opens the post composer interface.
    *   ❓ **Q2:** What does the default composer screen look like? Does it default to text input?
    *   ✅ **A2 (V1):** Opens to a **blank composer screen** with the **text input field immediately focused**.

### 3.2 Composing Text
*   **User Action:** User types their post content into the main text input area.
    *   ❓ **Q3:** Is there a character limit for text posts? If yes, what is it, and how is it indicated?
    *   ✅ **A3 (V1):** Yes, **500 characters**. A live counter (e.g., `480/500`) is shown near the text input area, likely bottom-right.
    *   ❓ **Q4:** Does the composer support any text formatting (e.g., bold, italics, lists - likely no for V1)? Does it support @mentions or #hashtags?
    *   ✅ **A4 (V1):** **No formatting** (bold, italics, etc.). **Supports @mentions and #hashtags** based on simple string matching (`@username`, `#topic`); no advanced lookup/validation in V1.
*   **UI State:** Text appears in the input field. Character count updates if applicable.

### 3.3 Selecting Target Space
*   **Trigger:** User needs to specify which Space the post belongs to.
*   **UI State:** Composer shows the currently selected target Space, or prompts selection if none chosen.
    *   ❓ **Q5:** How is the target Space selected? (e.g., A dropdown menu? A dedicated button opening a Space list? Is it pre-selected if creating from within a Space view?)
    *   ✅ **A5 (V1):** A **dropdown menu** or button that opens a list displays available Spaces. If the composer was opened via the **'+' button within a specific Space view, that Space is pre-selected**.
*   **User Action:** User selects the desired target Space from a list of spaces they have posting permissions in.
*   **UI State:** Selected Space name/icon is displayed in the composer.

### 3.4 Configuring Visibility (Integrated Question)
*   **User Action:** User potentially configures who can see the post.
    *   ❓ **Q6:** What visibility options are available for posts within a Space in V1? (e.g., Always visible to all Space members? Options like "Members Only" vs. potentially "Public Link" if the Space allows?)
    *   ✅ **A6 (V1):** Strictly **"Space members only"** for V1. There are no other visibility options for posts.
    *   ❓ **Q7:** How are visibility settings selected in the composer UI?
    *   ✅ **A7 (V1):** Displayed as a **non-editable chip/label** (e.g., "Visible to Space Members") below the Space selector. Since it's the only option in V1, it's informational and not interactive.

### 3.5 Publishing the Post
*   **User Action:** User taps the "Post" / "Drop" button.
    *   ❓ **Q8:** Is the Post button enabled only when minimum requirements are met (e.g., text entered, Space selected)?
    *   ✅ **A8 (V1):** Yes, the Post button is **enabled only once both text has been entered AND a target Space has been selected**.
*   **UI State (Processing):**
    *   ❓ **Q9:** What feedback is shown while the post is being submitted? (e.g., Disable post button? Loading indicator?)
    *   ✅ **A9 (V1):** The **Post button disables** and shows a **spinner animation inside the button** itself.
*   **System Action:** App initiates API call to create the post record (User ID, Space ID, Text Content, Visibility Settings).
*   **UI Feedback (Success):**
    *   Composer closes.
    *   User sees the new post appear in the relevant feed(s) (e.g., the target Space feed, potentially their main feed).
    *   ❓ **Q10:** Is there explicit success confirmation? (e.g., Snackbar "Post created"?)
    *   ✅ **A10 (V1):** Yes, a **Snackbar** confirms success: "Posted to [Space Name]".
*   **UI Feedback (Failure):**
    *   ❓ **Q11:** How are posting errors handled? (e.g., Error message within composer? Post button re-enabled? Draft saved? Option to retry?)
    *   ✅ **A11 (V1):** A **Snackbar** displays the error (e.g., "Post failed. Retrying..."). The composer remains open, the post button remains disabled during the **automatic retry**. The **draft is saved locally** (as per Draft Handling flow). If retry fails persistently, the button might re-enable with the error state indicated.

*   **Analytics:** [`flow_step: student.post.create_text.initiated`], [`flow_step: student.post.create_text.space_selected {space_id}`], [`flow_step: student.post.create_text.publish_attempt`], [`flow_step: student.post.create_text.publish_success {post_id, space_id}`], [`flow_error: student.post.create_text.publish_failed {reason}`]

---

## 4. State Diagrams

*   (Diagram: Initiate Composer -> Enter Text -> Select Space -> [Set Visibility] -> Publish -> Processing -> Success/Fail)

---

## 5. Error States & Recovery

*   **Trigger:** User tries to post without selecting a target Space (if required and not contextual).
    *   **State:** Post button disabled, or error message shown upon tap.
    *   **Recovery:** User selects a Space.
*   **Trigger:** User tries to post empty content.
    *   **State:** Post button disabled, or error message shown.
    *   **Recovery:** User enters text.
*   **Trigger:** API error during post creation.
    *   **State:** Error message displayed (Q11).
    *   **Recovery:** Retry mechanism? Draft potentially saved.
*   **Trigger:** No permission to post in selected Space (should be prevented by Q5 list ideally).
    *   **State:** Error message upon attempting to post.
    *   **Recovery:** User selects a different Space.

---

## 6. Acceptance Criteria

*   User can access the post composer (Q1, Q2).
*   User can input text content, respecting limits (Q3, Q4).
*   User can select a valid target Space (Q5).
*   User can configure visibility if applicable (Q6, Q7).
*   Post button state reflects readiness (Q8).
*   Appropriate feedback is shown during processing (Q9).
*   Successful post creation results in the post appearing in feeds with confirmation (Q10).
*   Post creation errors are handled gracefully with recovery options (Q11).

---

## 7. Metrics & Analytics

*   **Text Post Creation Rate:** (# Text Posts Created) / (# Composer Sessions Initiated).
*   **Post Length Distribution:** Average and distribution of character counts.
*   **Post Creation Success/Failure Rate:** % of attempts succeeding/failing.
*   **Space Selection Patterns:** Distribution of posts across different Spaces.
*   **Analytics Events:** (Listed in Sequence section)

---

## 8. Design/UX Notes

*   Composer entry (Q1) should be prominent and easy.
*   Selecting the target Space (Q5) needs to be clear, especially if not creating contextually from within a Space.
*   Character limits (Q3) should be clearly indicated as the user approaches them.
*   Feedback during posting (Q9) and upon success/failure (Q10, Q11) manages user expectation.

---

## 9. API Calls & Data

*   **Create Post API Call:**
    *   **Request:** User ID, Target Space ID, Text Content, Visibility Settings.
    *   **Response:** Success/Failure, [New Post Object].
*   **Get Postable Spaces API Call (Potentially for Q5):**
    *   **Request:** User ID.
    *   **Response:** List of Space IDs/Names user can post to.

---

## 10. Open Questions

1.  ~~**Entry Point:** Where is the primary create action located?~~
    *   ✅ **A1 (V1):** FAB '+' on Feed and within Spaces.
2.  ~~**Default Composer:** What does the initial composer screen look like?~~
    *   ✅ **A2 (V1):** Blank composer, text field focused.
3.  ~~**Character Limit:** Is there a limit? How is it shown?~~
    *   ✅ **A3 (V1):** 500 chars, live counter `XXX/500`.
4.  ~~**Formatting/Mentions:** Any text formatting? @mentions? #hashtags?~~
    *   ✅ **A4 (V1):** No formatting. Basic string match @mentions/#hashtags supported.
5.  ~~**Target Space Selection:** How is the target Space chosen?~~
    *   ✅ **A5 (V1):** Dropdown/Button list. Pre-selected if creating from within a Space.
6.  ~~**Visibility Options (V1):** What post visibility settings are available?~~
    *   ✅ **A6 (V1):** Space members only.
7.  ~~**Visibility UI:** How are visibility settings selected?~~
    *   ✅ **A7 (V1):** Non-editable info chip/label below Space selector.
8.  ~~**Post Button State:** When is the post button enabled?~~
    *   ✅ **A8 (V1):** Enabled when text is entered AND Space is selected.
9.  ~~**Processing Feedback:** What feedback during submission?~~
    *   ✅ **A9 (V1):** Post button disables + spinner inside.
10. ~~**Success Feedback:** How is successful posting confirmed?~~
    *   ✅ **A10 (V1):** Snackbar: "Posted to [Space Name]".
11. ~~**Failure Handling:** How are posting errors handled? Retry? Draft?~~
    *   ✅ **A11 (V1):** Snackbar error, auto-retry, local draft saved. Composer stays open.

**All questions resolved for V1.** 