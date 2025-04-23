# Flow: Student - Save / Bookmark Content

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:**
*   [Hive UI Product Context & Documentation Principles](../../product_context.md)
*   (Potentially link to where Saved items are viewed, e.g., Profile or dedicated section)

**Figma Link (Overall Flow):** [Link to Figma Frame for Save/Bookmark Action & List]

---

## 1. Title & Goal

*   **Title:** Student Save / Bookmark Content
*   **Goal:** Allow a user to save or bookmark specific content items (posts, events, etc.) for easy retrieval later.

---

## 2. Persona & Prerequisites

*   **Persona:** Student (Logged-in User)
*   **Prerequisites:**
    *   User is viewing a piece of content eligible for saving.
    *   ❓ **Q1:** What types of content can be saved/bookmarked in V1? (e.g., Posts/Drops? Events? Specific Comments? Spaces? User Profiles?)
    *   ✅ **A1 (V1):** **Posts (Drops) and Events**. Comments, Spaces, and Profiles cannot be saved in V1.

---

## 3. Sequence

### 3.1 Saving Content
*   **Trigger:** User finds content they want to save for later reference.
*   **User Action:** User taps the "Save" or "Bookmark" action associated with the content item.
    *   ❓ **Q2:** What is the icon/button used for this action? Where is it located? (e.g., Bookmark icon 🔖? Save icon💾? In a three-dot menu?)
    *   ✅ **A2 (V1):** **Bookmark icon (🔖)** located in the **top-right corner** of the post/event card.
*   **UI State (Before Tap):** Save button is in its inactive state.
*   **System Action:** App optimistically updates the UI to the "Saved" state.
    *   ❓ **Q3:** How does the save button/icon change to indicate the item is now saved? (e.g., Icon fills in? Color change? Animation?)
    *   ✅ **A3 (V1):** The bookmark icon **fills with gold**.
*   **System Action:** App initiates API call to record the saved item for the user (User ID, Content ID, Content Type).
*   **UI Feedback (Success):**
    *   UI remains in the saved state.
    *   ❓ **Q4:** Is there confirmation feedback? (e.g., Toast/Snackbar "Saved"?)
    *   ✅ **A4 (V1):** Yes, a **Snackbar** appears: "Saved" when saving, "Removed from Saved" when unsaving.
*   **UI Feedback (Failure):**
    *   UI reverts to the inactive state.
    *   ❓ **Q5:** Is an error message shown if saving fails?
    *   ✅ **A5 (V1):** Yes, a **Snackbar** appears: "Could not save. Try again." (or similar for unsave failure).

### 3.2 Unsaving Content
*   **Trigger:** User views content they have previously saved and wishes to remove it from their saved list.
*   **User Action:** User taps the active "Save" button (Q2/Q3) again.
*   **UI State (Before Tap):** Save button is in its active/saved state.
*   **System Action:** App optimistically updates the UI back to the inactive state.
*   **System Action:** App initiates API call to remove the saved item record.
*   **Feedback (API Success):** UI remains in the inactive state. Confirmation? (Q4, e.g., "Removed from Saved") *(Addressed in A4)*
*   **Feedback (API Failure):** UI reverts to the saved state. Error message? (Q5) *(Addressed in A5)*

### 3.3 Viewing Saved Content
*   **Trigger:** User wants to access their saved/bookmarked items.
*   **User Action:** User navigates to the dedicated "Saved" or "Bookmarks" section.
    *   ❓ **Q6:** Where does the user find their saved items? (e.g., A dedicated section in their Profile? A separate tab?)
    *   ✅ **A6 (V1):** In the user's **Profile screen**, under a dedicated **"Saved" section/tab**.
*   **Screen:** Saved Items List View.
*   **UI State:** Displays a list of content items the user has saved.
    *   ❓ **Q7:** How are saved items presented in this list? (e.g., Full card previews? Compact list view?)
    *   ✅ **A7 (V1):** Displayed as **full post/event preview cards**, identical to how they appear in the feed.
    *   ❓ **Q8:** How are saved items ordered? (e.g., Most recently saved first? Oldest first? Can the user sort/filter their saved items?)
    *   ✅ **A8 (V1):** Ordered by **most recently saved first**. No user sorting or filtering options in V1.
*   **User Action:** User taps on a saved item.
*   **System Action:** Navigates the user to the detail view of that saved content item.

*   **Analytics:** [`flow_step: student.save.saved {content_type, content_id}`], [`flow_step: student.save.unsaved {content_type, content_id}`], [`flow_step: student.save.view_list`], [`flow_error: student.save.action_failed {action_type(save/unsave), reason}`]

---

## 4. State Diagrams

*   (Diagram: Inactive State -> Tap -> Saved State (Optimistic) -> API Call -> [Success: Stays Saved | Failure: Reverts to Inactive])
*   (Diagram: Saved State -> Tap -> Inactive State (Optimistic) -> API Call -> [Success: Stays Inactive | Failure: Reverts to Saved])
*   (Diagram: Navigate to Saved List -> View List -> Select Item -> View Item Detail)

---

## 5. Error States & Recovery

*   **Trigger:** API error when saving or unsaving.
    *   **State:** UI reverts optimistic state. Optional error message (Q5).
    *   **Recovery:** User can tap the save button again.
*   **Trigger:** Error loading the saved items list.
    *   **State:** Error message displayed in the Saved Items section.
    *   **Recovery:** Retry mechanism (e.g., pull-to-refresh).
*   **Trigger:** Saved content has been deleted/become inaccessible since being saved.
    *   **State:** How is this handled in the saved list (Q7)? Does it disappear automatically? Show an error state?
    *   ❓ **Q9:** How are deleted/inaccessible items handled in the saved list view?
    *   ✅ **A9 (V1):** The item remains in the list but displays as an **"Unavailable content" card** (static shell/placeholder state). Tapping it might show a message. Includes an option (e.g., within a menu on the placeholder) to **remove it** from the saved list.

---

## 6. Acceptance Criteria

*   Save action (Q2) is available for eligible content (Q1).
*   Tapping the save action toggles the visual state (Q3) optimistically.
*   Save/Unsave action correctly updates the backend state.
*   Success/Failure feedback is provided (Q4, Q5).
*   UI reverts correctly on failure.
*   Users can access their list of saved items (Q6).
*   Saved items list displays correctly (Q7) and is ordered appropriately (Q8).
*   Tapping a saved item navigates to its detail view.
*   Deleted/inaccessible saved items are handled gracefully (Q9).

---

## 7. Metrics & Analytics

*   **Save Rate:** (# Saves) / (# Content Views).
*   **Unsave Rate:** (# Unsaves) / (# Saves).
*   **Saved List View Rate:** (# Views of Saved List) / (# Active Users).
*   **Saved Item Interaction Rate:** (# Taps on items in Saved List) / (# Views of Saved List).
*   **Save/Unsave Failure Rate:** % of attempts failing.
*   **Analytics Events:** (Listed in Sequence section)

---

## 8. Design/UX Notes

*   Save action should be easily accessible.
*   Visual feedback for saved state (Q3) needs to be clear.
*   The dedicated saved items list (Q6) needs to be easy to find.
*   Consider how to handle potentially large numbers of saved items (performance, UI presentation Q7/Q8).

---

## 9. API Calls & Data

*   **Save Content API Call:**
    *   **Request:** User ID, Content ID, Content Type.
    *   **Response:** Success/Failure.
*   **Unsave Content API Call:**
    *   **Request:** User ID, Content ID, Content Type.
    *   **Response:** Success/Failure.
*   **Get Saved Content API Call:**
    *   **Request:** User ID, [Pagination Info], [Sort Order?].
    *   **Response:** List of Saved Item references (Content ID, Content Type, Saved Timestamp, Preview?), Pagination Info.

---

## 10. Open Questions

1.  **Saveable Content (V1):** What types of content can be saved?
    *   ✅ **A1 (V1):** Posts (Drops) and Events.
2.  **Save Action UI:** What icon/button is used? Where is it located?
    *   ✅ **A2 (V1):** Bookmark icon (🔖) in top-right of card.
3.  **Saved State Visuals:** How does the UI change to show an item is saved?
    *   ✅ **A3 (V1):** Icon fills gold.
4.  **Save/Unsave Feedback:** Is there confirmation feedback (Snackbar)?
    *   ✅ **A4 (V1):** Yes, Snackbar ("Saved" / "Removed from Saved").
5.  **Failure Feedback:** Is an error message shown on save/unsave failure?
    *   ✅ **A5 (V1):** Yes, Snackbar ("Could not save. Try again.").
6.  **Saved List Location:** Where does the user access their saved items?
    *   ✅ **A6 (V1):** Profile screen > "Saved" section.
7.  **Saved List Display:** How are items shown in the saved list (Cards, List)?
    *   ✅ **A7 (V1):** Full post/event preview cards.
8.  **Saved List Ordering:** How is the saved list sorted? Can user sort/filter?
    *   ✅ **A8 (V1):** Most recently saved first. No sorting/filtering in V1.
9.  **Deleted Saved Content:** How are saved items handled if the original is deleted?
    *   ✅ **A9 (V1):** Show as "Unavailable content" card with option to remove.

**All questions resolved for V1.** 