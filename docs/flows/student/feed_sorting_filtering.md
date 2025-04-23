# Flow: Student - Main Feed Sorting & Filtering

**Version:** 1.0 (V1 Definition)
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:**
*   [Flow: Student - Main Feed Loading & Refresh](./feed_loading_refresh.md)
*   [Flow: Student - Main Feed Infinite Scroll / Pagination](./feed_pagination.md)
*   [Hive UI Product Context & Documentation Principles](../../product_context.md)

**Figma Link (Overall Flow):** [Link to Figma Frame for Sorting/Filtering UI]

---

## 1. Title & Goal

*   **Title:** Student Main Feed Sorting & Filtering
*   **Goal:** Define how a user can apply sorting options and filters to customize the content displayed in their main feed. *(Revised for V1: Define the V1 approach, which relies on algorithmic sorting/filtering without user controls).*

---

## 2. Persona & Prerequisites

*   **Persona:** Student (Logged-in User)
*   **Prerequisites:**
    *   User is viewing the main feed.

---

## 3. Sequence

*   **Trigger:** User wants to change the order or type of content shown in the feed.
*   **User Action:** User interacts with the sorting/filtering controls.
    *   ❓ **Q1:** Where is the entry point to access sorting and filtering options located? (e.g., A dedicated button/icon in the header? A dropdown menu? Swipe gesture?)
    *   ✅ **A1 (V1):** **Not Applicable.** V1 does not offer user-facing controls for sorting or filtering the main feed.
*   **UI State (Options Display):** A modal, bottom sheet, panel, or dropdown appears, presenting available options.
    *   ❓ **Q2:** What sorting options are available in V1? (e.g., Default (algorithmic/recent?), Most Recent, Popularity (by likes/comments?), Upcoming Events?)
    *   ✅ **A2 (V1):** **Not Applicable.** V1 uses a default algorithmic sort based on content type relevance (Rituals Pinned > Relevant Events > Space Drops + Boosted Content > Onboarding Prompts). No user-selectable sort options.
    *   ❓ **Q3:** What filtering options are available in V1? (e.g., By Content Type (Posts, Events, Rituals)? By Source (My Spaces only)? By Timeframe?)
    *   ✅ **A3 (V1):** **Not Applicable.** V1 feed displays a mix of content types based on relevance and algorithm. No user-selectable filters.
*   **User Action:** User selects desired sorting option(s) and/or filter(s).
*   **User Action:** User confirms or applies the changes.
*   **System Action:** App initiates an API call to fetch feed content based on the *new* sorting/filtering parameters. The existing feed content is typically cleared.
    *   *(V1 Note: API call uses default parameters)*
*   **UI State (Loading):** The feed displays a loading state (similar to initial load - Q2 from Loading flow?).
*   **System Action:** API returns the filtered/sorted feed data.
    *   *(V1 Note: Data is based on default algorithm)*
*   **UI State (Success):** Feed content is rendered based on the applied criteria.
*   **UI State (Active Filters/Sort):**
    *   ❓ **Q4:** How is the user made aware that non-default sorting or active filters are applied? (e.g., Persistent chips/labels? Button state changes? Header text?)
    *   ✅ **A4 (V1):** **Not Applicable.** The feed always displays the default algorithmic view.

### 3.1 Clearing Filters / Resetting Sort
*   **Trigger:** User wants to return to the default feed view.
*   **User Action:** User interacts with a "Clear" or "Reset" mechanism.
    *   ❓ **Q5:** How does the user clear all applied filters and reset sorting to default? (e.g., A button within the filter options? Tapping active filter chips?)
    *   ✅ **A5 (V1):** **Not Applicable.** No filters/sorts to clear.
*   **System Action:** App reverts to default sorting/filtering parameters and fetches the default feed view (triggers load/refresh sequence).

*   **Analytics:** [`flow_step: student.feed.sort_filter.open_options`], [`flow_step: student.feed.sort_filter.apply {sort_option, filter_options}`], [`flow_step: student.feed.sort_filter.clear`], [`flow_error: student.feed.sort_filter.apply_failed {reason}`]

---

## 4. State Diagrams

*   (Diagram showing transitions: Viewing Feed -> Opens Options -> Selects Options -> Applies -> Loading Filtered Feed -> Viewing Filtered Feed -> Clears Options -> Loading Default Feed -> Viewing Feed)

---

## 5. Error States & Recovery

*   **Trigger:** API error when fetching filtered/sorted feed.
    *   *(V1 Note: This applies to errors fetching the default feed view)*
    *   **State:** Feed displays the standard full-screen error state (similar to initial load error - Q7 from Loading flow).
*   **Recovery:** User uses the "Retry" button or clears filters. *(V1 Note: Retry button or refresh gesture)*

---

## 6. Acceptance Criteria

*   User can access sorting/filtering options via the defined entry point (Q1). *(V1: N/A)*
*   Available V1 sorting (Q2) and filtering (Q3) options are presented clearly. *(V1: N/A)*
*   Applying options triggers a reload of the feed with the correct parameters. *(V1: N/A)*
*   Active filters/sorts are indicated to the user (Q4). *(V1: N/A)*
*   User can clear filters and reset sorting to default (Q5). *(V1: N/A)*
*   Feed correctly displays content based on the default V1 algorithmic criteria (Pinned Rituals, Events, Drops, Boosted, Onboarding).
*   Errors during default feed loads are handled gracefully.

---

## 7. Metrics & Analytics

*   **Sort/Filter Usage:** Frequency of applying specific sorts or filters.
*   **Common Filter Combinations:** Which filters are often used together?
*   **Filter Application Time:** Time taken from applying filter to feed render.
*   **Filter Clear Rate:** How often users clear filters vs. leaving them applied.
*   **Analytics Events:** (Listed in Sequence section)

---

## 8. Design/UX Notes

*   Entry point should be easily discoverable but not obtrusive.
*   Clearly differentiate between sorting (ordering) and filtering (inclusion/exclusion).
*   Applying filters/sorts should feel responsive.
*   Provide clear indication of the currently active state. *(V1: N/A)*
*   Make clearing filters/resetting easy. *(V1: N/A)*
*   ❓ **Q6:** How do sorting/filtering choices persist? (e.g., Session only? Persist until manually cleared?)
*   ✅ **A6 (V1):** **Not Applicable.** No user choices to persist.

---

## 9. API Calls & Data

*   **Get Feed API Call (with Sort/Filter):**
    *   *(V1 Note: Request uses default sort/filter parameters implied by the backend algorithm)*
    *   **Request:** User ID, [Pagination Info] ~~, **Sort Parameter**, **Filter Parameters**~~.
    *   **Response:** List of Feed Item objects matching criteria, Pagination info.

---

## 10. Open Questions

1.  ~~**Entry Point:** Where are the sort/filter controls accessed from?~~
    *   ✅ **A1 (V1):** N/A. No user controls in V1.
2.  ~~**Sort Options (V1):** What sorting methods are available?~~
    *   ✅ **A2 (V1):** N/A. Uses default algorithm.
3.  ~~**Filter Options (V1):** What filtering criteria are available?~~
    *   ✅ **A3 (V1):** N/A. Feed shows mix based on relevance.
4.  ~~**Active State Indication:** How are active sorts/filters shown?~~
    *   ✅ **A4 (V1):** N/A.
5.  ~~**Clear/Reset Mechanism:** How does the user return to the default view?~~
    *   ✅ **A5 (V1):** N/A.
6.  ~~**Persistence:** Do sort/filter choices persist across sessions?~~
    *   ✅ **A6 (V1):** N/A.

**All questions resolved: V1 has no user-facing sort/filter controls for the main feed.** 