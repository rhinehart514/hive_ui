# Flow: Student - Discover Events (via Feed)

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:**
*   [Hive UI Product Context & Documentation Principles](../../product_context.md)
*   Flow assumes events are surfaced within the main Feed flow.

**Figma Link (Overall Flow):** [Link to Figma Frame for Event Card in Feed]

---

## 1. Title & Goal

*   **Title:** Student Discover Events (via Feed)
*   **Goal:** Allow the student user to encounter and identify relevant Event cards appearing within their main content feed, prompting them to view details or RSVP.

---

## 2. Persona & Prerequisites

*   **Persona:** Student (Authenticated User)
*   **Prerequisites:**
    *   User is logged in and viewing their main Home screen (`/home` - FeedPage).
    *   Relevant Events exist and are surfaced by the feed algorithm.

---

## 3. Sequence

1.  **Entry Point (Q1): Feed Integration.** User scrolls through their main content feed.
2.  **System Action:** The feed algorithm surfaces an Event relevant to the user.
3.  **UI Element: Event Card:** A distinct card appears in the feed, visually differentiated from standard posts.
    *   **(Q5 Card Content):**
        *   **Cover Image:** Full-width, 16:9 ratio.
        *   **Event Name:** Max 1.5 lines, prominent.
        *   **Date & Time:** Compact, inline format (e.g., Fri, Apr 26 · 8PM).
        *   **Location:** Compact text, shown only if physical location exists.
        *   **Host Space Name:** Subtle secondary label or logo/emoji.
        *   **Live Signal:** Glow or pulse animation if event is currently ongoing.
        *   **CTA Button:** Icon-based button (e.g., calendar icon for RSVP, eye icon for View Details) in a corner (e.g., top-right or bottom-right).
    *   **(Q2 Date Filtering):** No dedicated date filters on the card/feed for V1.
    *   **(Q3 Category Filtering):** No dedicated category filters on the card/feed for V1.
    *   **(Q4 Recommendations):** Event appearance is driven by the main feed's recommendation/sorting logic.
4.  **User Action (View Details):** User taps anywhere on the Event Card (excluding the specific CTA if it's different).
    *   **System Action:** Navigate to the "View Event Details" flow for the tapped event.
    *   **Analytics:** [`flow_step: event_card.impression {event_id}`], [`flow_step: event_card.tap_view_details {event_id}`]
5.  **User Action (CTA Tap - e.g., RSVP):** User taps the specific CTA button on the card.
    *   **System Action:** Navigate to the "View Event Details" flow OR potentially initiate RSVP flow directly (TBD in RSVP flow spec).
    *   **Analytics:** [`flow_step: event_card.tap_cta {event_id, cta_type}`]

---

## 4. State Diagrams

*   **Card Rendered:** Event card visible in feed.
*   **Card Live State:** Glow/pulse animation active if event is ongoing.
*   **(Potentially) Card RSVP State:** CTA might change if user RSVPs directly from card (if implemented).

---

## 5. Error States & Recovery

*   *(Error handling primarily belongs to the main Feed loading flow. Errors specific to rendering this card type might occur but are less likely to be user-recoverable here.)*
*   **Trigger:** Data for a specific Event Card is corrupt/missing.
    *   **State:** Card might fail to render, or show placeholder/error state within its bounds.
    *   **Recovery:** Feed refresh might load correct data.

---

## 6. Acceptance Criteria

*   **Pre-conditions:** User is viewing main feed, relevant events exist.
*   **Success Post-conditions:**
    *   Event cards appear seamlessly within the main feed (Q1).
    *   Event cards display the specified information clearly (Q5).
    *   Event cards indicate if an event is currently live.
    *   Tapping an Event card navigates the user to the Event Details screen.
    *   (V1 Scope): No date/category filters specifically for events are present in this discovery context (Q2, Q3).
    *   (V1 Scope): Event recommendations are part of the feed logic, not a separate UI element (Q4).
*   **General:**
    *   Event cards are visually distinct from other feed items.

---

## 7. Metrics & Analytics

*   **Event Card Impression Rate:** (# Event cards rendered in feed) / (# Feed views).
*   **Event Card CTR (View Details):** (`event_card.tap_view_details` count) / (`event_card.impression` count).
*   **Event Card CTR (CTA):** (`event_card.tap_cta` count) / (`event_card.impression` count).
*   **Analytics Events:** (Listed in Sequence section)

---

## 8. Design/UX Notes

*   Event card design needs to be distinct but harmonious with other feed items.
*   Key info (Name, Date/Time, Location) must be easily scannable.
*   "Live" indicator should be noticeable but not overly distracting.
*   CTA button should be clear in its intent (RSVP vs. View Details).

---

## 9. API Calls & Data

*   **Main Feed API Call:** (Defined in Feed flow)
    *   **Request:** Includes parameters for fetching mixed content types.
    *   **Response:** Includes Event objects alongside Post objects, etc. Event objects contain data needed for the preview card (ID, Name, Start/End Time, Location Summary, Host Name, Thumbnail URL, Live Status, potentially RSVP status for CTA).
*   *(No dedicated Event Search/List API needed for this specific feed-based discovery flow)*

---

## 10. Open Questions

*   **(Resolved)** Q1: Entry Point is **Feed Integration**.
*   **(Resolved)** Q2: **No** V1 Date Filtering/Calendar view in discovery context.
*   **(Resolved)** Q3: **No** V1 Category Filtering in discovery context.
*   **(Resolved)** Q4: Recommendations are part of the **main feed logic**.
*   **(Resolved)** Q5: Preview Card Info spec defined.

*   **(Action Item):** Design the Event Card UI component for the feed.
*   **(Action Item):** Define the specific icon and behavior for the card's CTA button (RSVP vs. View Details).
*   **(Action Item):** Ensure main Feed API endpoint can return mixed content including Events with necessary card data. 