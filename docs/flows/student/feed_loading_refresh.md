# Flow: Student - Main Feed Loading & Refresh

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:**
*   [Hive UI Product Context & Documentation Principles](../../product_context.md)

**Figma Link (Overall Flow):** [Link to Figma Frame for Main Feed]

---

## 1. Title & Goal

*   **Title:** Student Main Feed Loading & Refresh
*   **Goal:** Define how the main content feed initially loads when accessed by a student and how they can manually refresh it to fetch newer content.

---

## 2. Persona & Prerequisites

*   **Persona:** Student (Logged-in User)
*   **Prerequisites:**
    *   User is logged in.
    *   User has access to the main feed view (e.g., primary tab).

---

## 3. Sequence

### 3.1 Initial Load
*   **Trigger:** User navigates to the main feed view (e.g., opens app, switches to feed tab).
    *   ❓ **Q1:** What is the precise trigger for the *initial* feed load?
    *   ✅ **A1 (V1):** Triggered only when the Feed tab becomes visible *and* the local cache (A8) is non-existent or expired (>2 mins old). Not triggered if valid cache exists or user just switches away and back quickly.
*   **System Action:** App initiates API call to fetch the initial set of feed items.
*   **UI State (Loading):**
    *   ❓ **Q2:** What does the user see while the initial feed is loading? (e.g., Skeleton loaders matching post structure? Simple spinner? Branded loading animation?)
    *   ✅ **A2 (V1):** Custom HIVE animation: **Centered, black & gold hexagonal ripple loader** with a subtle pulse. Short loop. No generic spinners or skeletons.
*   **System Action:** API returns feed data (or empty state/error).
*   **UI State (Success):** Feed content is rendered. Oldest items at the bottom, newest at the top.
*   **UI State (Empty Feed):**
    *   ❓ **Q3:** What is displayed if the feed is empty? (e.g., For a brand new user, or if there's genuinely no content matching their criteria). Specific message? Illustration? Call to action?
    *   ✅ **A3 (V1):** Custom HIVE-branded empty state: **Abstract floating gold hex illustration** with dim glow. Headline: "It's quiet here...". Primary CTA button: "Explore Spaces". For first-day users, rotate suggested CTAs (Join Ritual, Browse Events, Start Drop).

### 3.2 Manual Refresh
*   **Trigger:** User performs a refresh gesture.
    *   ❓ **Q4:** What is the standard refresh gesture? (e.g., Pull-to-refresh from the top?)
    *   ✅ **A4 (V1):** Standard **pull-to-refresh** gesture from the top edge of the feed.
*   **System Action:** App initiates API call to fetch newer feed items since the last load/refresh.
*   **UI State (Refreshing):**
    *   ❓ **Q5:** What visual feedback indicates the refresh is in progress? (e.g., Standard pull-to-refresh spinner? Custom animation?)
    *   ✅ **A5 (V1):** Custom HIVE animation: **Gold hex spinner with ripple animation** (not linear spin) overlays the top bar area during the refresh.
*   **System Action:** API returns new feed items (or indication of no new items/error).
*   **UI State (New Content):** New items are prepended to the top of the existing feed content.
    *   ❓ **Q6:** Is there any visual indication that new items have been loaded and inserted? (e.g., Subtle animation? A small separator? A toast/chip notification at the top saying "X new posts"?)
    *   ✅ **A6 (V1):** New posts **slide in from the top** with a subtle spring animation. If 3+ new posts load, a temporary, semi-translucent chip appears briefly at the top: "X new posts" (fades on scroll/timer).
*   **UI State (No New Content):** Refresh indicator dismisses, feed remains unchanged.

*   **Analytics:** [`flow_step: student.feed.load_initial.start`], [`flow_step: student.feed.load_initial.success {item_count}`], [`flow_step: student.feed.load_initial.empty`], [`flow_error: student.feed.load_initial.failed {reason}`], [`flow_step: student.feed.refresh.start`], [`flow_step: student.feed.refresh.success {new_item_count}`], [`flow_error: student.feed.refresh.failed {reason}`]

---

## 4. State Diagrams

*   (Diagram showing transitions: Idle -> Loading -> Displaying Content / Empty / Error -> Refreshing -> Displaying Content / Error)

---

## 5. Error States & Recovery

*   **Trigger:** API error during initial load.
    *   **State:** Display an error message/view.
        *   ❓ **Q7:** What does the error state look like? Full screen message? Inline within the feed area? Include a "Retry" button?
        *   ✅ **A7 (V1):** **Full-screen error view** replacing the feed content. Message: "Couldn't load the Feed". Includes a prominent **"Retry" button**. Pull-to-refresh is also enabled as a retry mechanism from this state.
    *   **Recovery:** User taps "Retry" button or performs refresh gesture.
*   **Trigger:** API error during refresh.
    *   **State:** Refresh indicator dismisses, **Snackbar** appears briefly: "Refresh failed. Try again."
    *   **Recovery:** User performs refresh gesture again later.
*   **Trigger:** Poor network connectivity during load/refresh.
    *   **State:** Loading/refresh indicator may persist longer, eventually time out to error state.
    *   **Recovery:** User tries again when connectivity improves.

---

## 6. Acceptance Criteria

*   **Initial Load:**
    *   Feed initiates loading upon defined trigger (Q1).
    *   Appropriate loading state is displayed (Q2).
    *   Feed content renders correctly upon successful load.
    *   Empty state is handled gracefully (Q3).
    *   Load errors are handled with recovery options (Q7).
*   **Manual Refresh:**
    *   Refresh can be triggered by the defined gesture (Q4).
    *   Appropriate refreshing indicator is displayed (Q5).
    *   New content is prepended correctly.
    *   Indication of new content is provided if applicable (Q6).
    *   Refresh errors are handled gracefully.

---

## 7. Metrics & Analytics

*   **Feed Load Time (Initial & Refresh):** Average time from trigger to content render.
*   **Feed Load Failure Rate:** % of loads/refreshes resulting in error.
*   **Refresh Frequency:** Average number of refreshes per session.
*   **Empty Feed Rate:** % of initial loads resulting in an empty feed.
*   **Analytics Events:** (Listed in Sequence section)

---

## 8. Design/UX Notes

*   Loading state should feel fast and integrated (skeleton loaders often preferred over spinners).
*   Refresh should provide clear feedback without being intrusive.
*   Empty state is an opportunity for guidance or engagement.
*   Error states should be informative and offer clear recovery paths.
*   Consider caching strategies to improve perceived load times and handle offline scenarios (though offline is a separate flow).
    *   ❓ **Q8:** What is the basic caching strategy for the feed? (e.g., Cache last loaded state? How long is cache valid?)
    *   ✅ **A8 (V1):** **Smart short-term local cache:** Store the last successfully loaded feed payload. **Cache expires after 2 minutes.** If valid cache exists on load trigger (A1), display cached data *immediately* and initiate a background refresh. If cache is stale on cold start, show loader (A2).

---

## 9. API Calls & Data

*   **Get Feed API Call:**
    *   **Request:** User ID, [Optional: Timestamp/Cursor for pagination/refresh], [Optional: Filters/Sort criteria].
    *   **Response:** List of Feed Item objects (Posts, Events, Rituals, etc.), Pagination info (next cursor/page), [Optional: Timestamp of latest item].

---

## 10. Open Questions

1.  ~~**Initial Load Trigger:** What action precisely triggers the first feed load?~~
    *   ✅ **A1 (V1):** Feed tab becomes visible + cache expired (>2 min) or non-existent.
2.  ~~**Initial Loading UI:** What visual state is shown during initial load (Skeleton, spinner, etc.)?~~
    *   ✅ **A2 (V1):** Custom HIVE hexagonal ripple loader (black & gold).
3.  ~~**Empty Feed UI:** How is an empty feed presented (Message, illustration, CTA)?~~
    *   ✅ **A3 (V1):** Custom illustration, "It's quiet here...", "Explore Spaces" CTA (rotates for new users).
4.  ~~**Refresh Gesture:** What gesture triggers a manual refresh (Pull-to-refresh?)?~~
    *   ✅ **A4 (V1):** Standard pull-to-refresh from top.
5.  ~~**Refreshing UI:** What visual feedback indicates a refresh is in progress?~~
    *   ✅ **A5 (V1):** Custom gold hex spinner overlay with ripple animation.
6.  ~~**New Content Indication:** How are newly loaded items indicated after a refresh?~~
    *   ✅ **A6 (V1):** Posts slide in from top. Temporary "X new posts" chip if 3+ new items.
7.  ~~**Load/Refresh Error UI:** How are network/API errors displayed during load and refresh? Is there a retry option?~~
    *   ✅ **A7 (V1):** Full-screen error with Retry button for initial load fail. Snackbar for refresh fail.
8.  ~~**Caching Strategy:** What is the basic caching approach for the feed (if any)?~~
    *   ✅ **A8 (V1):** Cache last payload, 2-minute expiration. Show cache immediately, refresh in background if valid.

**All questions resolved for V1.** 