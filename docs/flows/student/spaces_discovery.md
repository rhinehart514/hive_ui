# Flow: Student - Discover Spaces

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:**
*   [Hive UI Product Context & Documentation Principles](../../product_context.md)

**Figma Link (Overall Flow):** [Link to Figma Frame for Spaces Discovery/Search Screen]

---

## 1. Title & Goal

*   **Title:** Student Discover Spaces (Browse & Search)
*   **Goal:** Allow the student user to find relevant Spaces (communities) within Hive through browsing categories, viewing recommendations, and performing keyword searches.

---

## 2. Persona & Prerequisites

*   **Persona:** Student (Authenticated User)
*   **Prerequisites:**
    *   User is logged in.
    *   Spaces exist in the system.

---

## 3. Sequence

1.  **Entry Point:** User navigates to the dedicated "Spaces" tab/section of the app.
    *   **(Q1 Answer):** Located in the **Bottom Navigation Bar** (likely index 1, based on `lib/shell.dart`).
2.  **Screen:** Spaces Discovery Hub (`lib/features/spaces/presentation/pages/spaces_page.dart` is likely the implementation).
    *   **UI Elements:**
        *   **Search Bar:** Prominently displayed at the top.
        *   **(Q2 Answer):** No predefined categories for V1 browsing.
        *   **(Q3 Answer):** **Recommended Spaces Section:** Yes, driven by logic considering friends' memberships, popularity, and user profile (major/residence). (`lib/features/recommendation/.../get_personalized_recommendations_usecase.dart`)
        *   **List/Grid of Spaces:** Displays Space cards.
            *   **(Q4 Answer - Card Content):**
                *   **Core:** Space Icon/Logo, Space Name, Public/Private Indicator.
                *   **Dynamic Metric/Status (Priority Order):**
                    1.  If active in THE BRACKET (Top 64): Show Current Rank.
                    2.  Else if Tagline exists: Show Tagline.
                    3.  Else: Show Member Count.
            *   **(Q4 Answer - Card Interactions):**
                *   **Tap:** Navigate to "View Space Details" flow.
                *   **Tap & Hold:** Trigger "Quick Preview Flyout" (Shows expanded tagline, recent Drop count - *Details TBD*).
                *   **Swipe Left:** Reveal context menu (Actions: Preview, Report, Mute - *Details TBD*).
        *   **(Optional) "Create Space" Button/Link:** For users with Builder permissions.
    *   **User Action (Browse):** User scrolls through the list/grid.
        *   **System Action:** Filter/update the displayed list of Spaces based on category selection.
    *   **User Action (Search):** User taps the Search Bar.
        *   **System Action:** Keyboard appears, UI might transition to a dedicated search results view or filter the current view.
    *   **User Action (Search Input):** User types a search query (e.g., "Chess Club", "Hiking").
        *   **System Action:** As the user types (debounce recommended), fetch and display matching Spaces based on name, description, tags, etc.
        *   **UI:** Search results update dynamically.
    *   **User Action (View Details):** User taps on a specific Space card (from browsing or search results).
        *   **System Action:** Navigate to the "View Space Details" flow.
        *   **Analytics:** [`flow_step: spaces.discovery_viewed`], [`flow_step: spaces.search_initiated`], [`flow_step: spaces.search_performed {query}`], [`flow_step: spaces.category_browsed {category}`], [`flow_step: spaces.details_view_tapped {space_id}`]

---

## 4. State Diagrams

*   **Initial:** Discovery Hub loaded, showing default view (e.g., recommendations or all public spaces).
*   **Browsing Category:** List filtered by selected category.
*   **Search Active:** Keyboard visible, search results potentially shown.
*   **Search Results:** List filtered by search query.

---

## 5. Error States & Recovery

*   **Trigger:** Failure to load initial list of Spaces / recommendations.
    *   **State:** Show loading indicator initially, then display an error message (e.g., "Couldn't load Spaces. Pull to refresh.") with a retry option.
    *   **Recovery:** User pulls to refresh or taps retry button.
    *   **Analytics:** [`flow_error: spaces.discovery_load_failed`]
*   **Trigger:** Failure to load search results.
    *   **State:** Show loading indicator in search results area, then display an error message (e.g., "Search failed. Please try again.").
    *   **Recovery:** User modifies query or tries again.
    *   **Analytics:** [`flow_error: spaces.search_load_failed`]
*   **Trigger:** No search results found.
    *   **State:** Display a clear "No results found for '[query]'" message.
    *   **Recovery:** User modifies search query.
*   **Trigger:** Network error during browsing/searching.
    *   **State:** Display appropriate offline/error indicator (e.g., Snackbar).
    *   **Recovery:** User regains connection and retries.

---

## 6. Acceptance Criteria

*   **Pre-conditions:** User is logged in.
*   **Success Post-conditions:**
    *   User can access the Spaces Discovery Hub (Q1).
    *   User can browse available Spaces (potentially by category - Q2).
    *   User can see recommended Spaces (Q3).
    *   User can successfully search for Spaces by keyword.
    *   Relevant Space information is displayed on preview cards (Q4).
    *   User can tap a Space card to navigate to its details view.
*   **General:**
    *   Loading and error states are handled gracefully.
    *   Search is responsive.

---

## 7. Metrics & Analytics

*   **Discovery Hub Visit Rate:** (# Users visiting Spaces Discovery Hub) / (# Active Users).
*   **Search Usage Rate:** (# Users performing a search) / (# Users visiting Discovery Hub).
*   **Category Browse Rate:** (# Users tapping a category) / (# Users visiting Discovery Hub).
*   **Space Detail View CTR:** (# Users tapping a Space card) / (# Users viewing Discovery Hub).
*   **Search Success Rate:** (# Searches resulting in at least one click) / (# Total Searches).
*   **Analytics Events:** (Listed in Sequence section)

---

## 8. Design/UX Notes

*   Discovery interface should be visually appealing and easy to scan.
*   Search needs to be prominent and fast.
*   Recommendations (if used) should feel relevant.
*   Clear distinction between public and private Spaces on cards.
*   Consider loading states for lists and search results.

---

## 9. API Calls & Data

*   **Get Spaces List/Recommendations API Call:**
    *   **Request:** May include pagination parameters, user ID (for recommendations), category filter.
    *   **Response:** Paginated list of Space objects (ID, Name, Member Count, Description, Public/Private status, Banner/Logo URL).
*   **Search Spaces API Call:**
    *   **Request:** Search query, pagination parameters.
    *   **Response:** Paginated list of matching Space objects.

---

## 10. Open Questions

*   **(Resolved)** Q1: The primary entry point is an item in the **Bottom Navigation Bar**.
    *   *Codebase Ref:* `lib/shell.dart`, `lib/features/spaces/presentation/pages/spaces_page.dart`.
*   **(Resolved)** Q2: V1 will **not** include predefined frontend categories for browsing.
*   **(Resolved)** Q3: V1 **will** include recommended Spaces, driven by friends, popularity, and profile data.
    *   *Codebase Ref:* `lib/features/recommendation/domain/usecases/get_personalized_recommendations_usecase.dart`.
*   **(Resolved)** Q4: Space preview card shows **Icon, Name, Public/Private status, and a dynamic metric (Rank > Tagline > Member Count)**. Includes **Tap** (Details), **Tap & Hold** (Flyout Preview - *TBD*), and **Swipe Left** (Context Menu - *TBD*) interactions.

*   **(Action Item):** Define the specific content and behavior of the "Quick Preview Flyout" triggered by Tap & Hold.
*   **(Action Item):** Define the specific actions and behavior of the context menu revealed by Swipe Left.
*   **(Action Item):** Implement the dynamic logic for displaying Rank/Tagline/Member Count on the Space card. 