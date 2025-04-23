# Flow: Student - Feed Content Preview to Detail Drill-In

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:**
*   [Flow: Student - Main Feed Loading & Refresh](./feed_loading_refresh.md)
*   [Hive UI Product Context & Documentation Principles](../../product_context.md)
*   (Links to specific detail view flows like [View Event Details](./view_event_details.md) will be relevant)

**Figma Link (Overall Flow):** [Link to Figma Frame showing Feed Card Tap & Transition]

---

## 1. Title & Goal

*   **Title:** Student Feed Content Preview to Detail Drill-In
*   **Goal:** Define the user interaction for tapping on a summarized content item (post, event card, ritual strip, etc.) in the main feed and transitioning to its full detail view.

---

## 2. Persona & Prerequisites

*   **Persona:** Student (Logged-in User)
*   **Prerequisites:**
    *   User is viewing the main feed.
    *   Feed contains at least one content item (post, event, etc.).

---

## 3. Sequence

*   **Trigger:** User identifies a content item of interest in the feed (e.g., a Post card, an Event card).
*   **User Action:** User taps on the content item.
    *   ❓ **Q1:** What is the primary tap target on a feed card to trigger navigation to the detail view? (e.g., The entire card? Specific elements like title/image?)
    *   ✅ **A1 (V1):** The **main content area** of the card (e.g., text body, primary image/media), excluding specific interactive elements like profile pictures/names, like/comment/share buttons, or explicit CTAs.
*   **System Action:** App initiates navigation to the corresponding detail screen for that specific content item (e.g., Post Detail Screen, Event Detail Screen).
    *   The specific content ID is passed to the detail screen.
*   **UI State (Transition):**
    *   ❓ **Q2:** What screen transition animation is used when navigating from the feed card to the detail view? (e.g., Standard slide-in? Hero transition animating the card? Fade?)
    *   ✅ **A2 (V1):** **Standard platform slide-in** animation (e.g., slides in from right).
*   **Screen:** The relevant detail screen is displayed (e.g., `EventDetailScreen`, `PostDetailScreen`). Content specific to the tapped item ID is loaded/displayed.
*   **User Action (Return):** User performs the standard back navigation gesture/action.
    *   ❓ **Q3:** What happens when the user navigates back from the detail screen? Do they return to the exact same scroll position in the feed? Is the transition animation the reverse of Q2?
    *   ✅ **A3 (V1):** **Yes**, back navigation returns the user to the **exact previous scroll position** in the feed. The exit animation is the standard reverse of the entry animation (e.g., slides out to right).

*   **Analytics:** [`flow_step: student.feed.drill_in.initiated {content_type, content_id}`], [`flow_step: student.feed.drill_in.success {content_type, content_id}`], [`flow_error: student.feed.drill_in.failed {content_type, content_id, reason(navigation_error/content_not_found)}`]

---

## 4. State Diagrams

*   (Simple diagram: Viewing Feed -> Taps Card -> Transitioning -> Viewing Detail -> Navigates Back -> Viewing Feed)

---

## 5. Error States & Recovery

*   **Trigger:** Tapped content item is no longer available (e.g., deleted just before tap completes, race condition).
    *   **State:** Navigation might fail, or the detail screen loads an error state (e.g., "Content not found").
        *   ❓ **Q4:** How should this specific error (navigating to non-existent content) be handled? Stay on feed with an error message? Navigate to detail screen showing an error?
        *   ✅ **A4 (V1):** **Navigate to the detail screen structure**, but display a dedicated **"Content Unavailable" / "Post Not Found" state** within that screen if the content associated with the ID cannot be fetched. This state should allow easy back navigation.
    *   **Recovery:** User dismisses error/navigates back to feed.
*   **Trigger:** Unexpected navigation error.
    *   **State:** App might remain on feed, potentially show a generic error (Snackbar?).
    *   **Recovery:** User retries tapping the item.

---

## 6. Acceptance Criteria

*   Tapping the defined target area (Q1) on a feed item initiates navigation.
*   The correct detail screen for the specific content type and ID is loaded.
*   An appropriate screen transition is used (Q2).
*   Navigating back returns the user to their previous scroll position in the feed (Q3).
*   Errors during navigation or loading the detail view are handled gracefully (Q4).

---

## 7. Metrics & Analytics

*   **Drill-In Rate:** (# Detail Views Initiated from Feed) / (# Feed Views).
*   **Content Type Engagement:** Drill-in rates broken down by content type (Post, Event, Ritual, etc.).
*   **Navigation Failure Rate:** % of drill-in attempts resulting in an error.
*   **Analytics Events:** (Listed in Sequence section)

---

## 8. Design/UX Notes

*   Tap target should be clear and generous.
*   Transition should feel smooth and contextual (Hero transitions can be effective if performant).
*   Maintaining scroll position upon return is crucial for user orientation.
*   Consider how interactions *on* the card (like tapping a profile picture, like button, etc.) are differentiated from the drill-in tap.

---

## 9. API Calls & Data

*   No direct API calls for the navigation itself, but the *target* detail screen will likely make its own API calls to fetch full content based on the passed ID.

---

## 10. Open Questions

1.  **Tap Target:** What area(s) of a feed card trigger navigation to the detail view?
    *   ✅ **A1 (V1):** Main content area (body, primary media), excluding buttons, profile links, etc.
2.  **Transition Animation:** What animation is used for the feed-to-detail screen transition?
    *   ✅ **A2 (V1):** Standard platform slide-in animation.
3.  **Back Navigation:** Does back navigation restore the exact feed scroll position? Is the return animation the reverse of the entry animation?
    *   ✅ **A3 (V1):** Yes, restores exact scroll position. Exit animation is reverse of entry.
4.  **Content Not Found Error:** How is the error handled if the tapped content doesn't exist when the detail screen tries to load?
    *   ✅ **A4 (V1):** Navigate to detail screen structure, display "Content Unavailable" state within it.

**All questions resolved for V1.** 