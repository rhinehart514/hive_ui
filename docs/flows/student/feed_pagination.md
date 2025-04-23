# Flow: Student - Main Feed Infinite Scroll / Pagination

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:**
*   [Flow: Student - Main Feed Loading & Refresh](./feed_loading_refresh.md)
*   [Hive UI Product Context & Documentation Principles](../../product_context.md)

**Figma Link (Overall Flow):** [Link to Figma Frame for Main Feed Pagination/Loading]

---

## 1. Title & Goal

*   **Title:** Student Main Feed Infinite Scroll / Pagination
*   **Goal:** Define how older content is dynamically loaded into the main feed as the user scrolls down, providing a seamless infinite scrolling experience.

---

## 2. Persona & Prerequisites

*   **Persona:** Student (Logged-in User)
*   **Prerequisites:**
    *   User is viewing the main feed.
    *   The initial set of feed items has been loaded.
    *   There is potentially more historical content available on the server than initially loaded.

---

## 3. Sequence

*   **Trigger:** User scrolls down the feed towards the bottom.
    *   ❓ **Q1:** How close to the bottom does the user need to scroll to trigger the loading of the next page/batch of content? (e.g., When the last N items are visible? When X pixels from the bottom?)
    *   ✅ **A1 (V1):** Triggered when the user scrolls down and there are **3 posts/items remaining** visible at the bottom of the currently loaded list.
*   **System Action:** App detects the scroll position has passed the trigger threshold.
*   **System Action:** App checks if a pagination request is already in progress to prevent duplicate calls.
*   **System Action:** App initiates API call to fetch the *next* set/page of older feed items, using pagination info (cursor, page number, timestamp) from the previous API response.
*   **UI State (Loading Next Page):**
    *   ❓ **Q2:** What visual indicator, if any, is shown at the bottom of the feed while the next page is loading? (e.g., Subtle spinner? Skeleton loader for one item? Nothing?)
    *   ✅ **A2 (V1):** Yes. A **mini HIVE hex spinner (approx. 16px)** with a subtle orbit/micro-glow animation is displayed centered at the bottom of the list. Fades in when triggered, fades out when content loads/fails.
*   **System Action:** API returns the next page of feed data (or indicates end of feed/error).
*   **UI State (Success - More Content):** Newly fetched older items are appended seamlessly to the bottom of the existing feed content.
*   **UI State (Success - End of Feed):**
    *   ❓ **Q3:** What happens when the user reaches the absolute end of all available feed content? Is there any visual indication? (e.g., A message like "You've reached the beginning"? Just stops loading?)
    *   ✅ **A3 (V1):** Yes. A subtle visual indicator appears at the absolute bottom: Text "**That's everything for now.**" (subtle gray/gold). Optionally, a dim hex fade-out icon.

*   **Analytics:** [`flow_step: student.feed.paginate.start`], [`flow_step: student.feed.paginate.success {item_count}`], [`flow_step: student.feed.paginate.end_of_feed`], [`flow_error: student.feed.paginate.failed {reason}`]

---

## 4. State Diagrams

*   (Diagram showing transitions: Displaying Content -> Scrolled Near Bottom -> Loading More -> Appending Content / End of Feed / Error)

---

## 5. Error States & Recovery

*   **Trigger:** API error during pagination request.
    *   **State:** Loading indicator (if any, Q2) disappears. Potentially show a temporary error message at the bottom?
        *   ❓ **Q4:** How are pagination errors displayed? Inline message at the bottom? Snackbar/Toast? Should there be a "Tap to retry" option?
        *   ✅ **A4 (V1):** Handled **inline at the bottom**. A small card appears where the loader was: "**Couldn't load more. Tap to retry.**". Tapping this area triggers a retry of the failed page load. Haptic feedback provided on retry success/fail.
    *   **Recovery:** User scrolls near the bottom again later to retry, or taps the inline retry mechanism.
*   **Trigger:** Poor network connectivity during pagination.
    *   **State:** Loading indicator may persist longer, eventually time out to error state.
    *   **Recovery:** User tries again when connectivity improves.

---

## 6. Acceptance Criteria

*   Scrolling near the bottom triggers loading of the next page (Q1).
*   Appropriate loading indicator is displayed if defined (Q2).
*   Newly loaded older content is appended correctly to the bottom of the feed.
*   Duplicate pagination requests are prevented.
*   The end of the feed is handled gracefully (Q3).
*   Pagination errors are handled with potential recovery options (Q4).

---

## 7. Metrics & Analytics

*   **Pagination Load Time:** Average time from trigger to content append.
*   **Pagination Failure Rate:** % of pagination attempts resulting in error.
*   **Feed Depth Reached:** Average number of pages loaded per session.
*   **End-of-Feed Rate:** % of sessions where users scroll to the absolute end.
*   **Analytics Events:** (Listed in Sequence section)

---

## 8. Design/UX Notes

*   Pagination should feel seamless and responsive.
*   Loading indicator (if used) should be minimal and unobtrusive.
*   Handling the end-of-feed state prevents user confusion.
*   Ensure smooth performance even with a large number of loaded items.
*   Consider pre-fetching the next page slightly before the user hits the absolute bottom.

---

## 9. API Calls & Data

*   **Get Feed API Call (Paginated):**
    *   **Request:** User ID, **Pagination Cursor/Timestamp/Page Number** (from previous response).
    *   **Response:** List of *older* Feed Item objects, **New Pagination Info** (for the *next* older page), Indication if this is the last page.

---

## 10. Open Questions

1.  ~~**Trigger Threshold:** How close to the bottom triggers the next page load?~~
    *   ✅ **A1 (V1):** 3 posts remaining visible at the bottom.
2.  ~~**Loading Indicator:** Is there a visual indicator at the bottom while loading the next page? If so, what?~~
    *   ✅ **A2 (V1):** Yes, a mini HIVE hex spinner (16px) with orbit/glow animation.
3.  ~~**End of Feed UI:** How is the absolute end of the feed indicated to the user?~~
    *   ✅ **A3 (V1):** Yes, subtle text "That's everything for now." at the absolute bottom.
4.  ~~**Pagination Error UI:** How are pagination errors displayed? Is there a retry mechanism?~~
    *   ✅ **A4 (V1):** Yes, inline card at the bottom: "Couldn't load more. Tap to retry."

**All questions resolved for V1.** 