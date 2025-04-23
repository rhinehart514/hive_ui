# Flow: Student - View Space Details

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:**
*   [Flow: Student - Discover Spaces](./spaces_discovery.md)
*   [Hive UI Product Context & Documentation Principles](../../product_context.md)

**Figma Link (Overall Flow):** [Link to Figma Frame for Space Detail Screen]

---

## 1. Title & Goal

*   **Title:** Student View Space Details
*   **Goal:** Allow the student user to view comprehensive information about a specific Space, understand its purpose and activity, and decide whether to join (if applicable).

---

## 2. Persona & Prerequisites

*   **Persona:** Student (Authenticated User)
*   **Prerequisites:**
    *   User has tapped on a Space preview card from the Spaces Discovery Hub or another entry point (e.g., link in a post, notification).
    *   The target Space exists.

---

## 3. Sequence

*   **Trigger:** User taps a Space preview card.
*   **System Action:** Navigate to the Space Detail Screen for the selected Space ID.
    *   Fetch detailed data for the Space.
*   **Screen:** Space Detail Screen (`lib/features/spaces/presentation/pages/space_detail_page.dart` - *Potential location*)
    *   **UI Elements:**
        *   **Header:** Space Banner Image (if available), Space Logo/Icon, Space Name.
        *   **Membership Status/Actions & Button States:**
            *   **State: Public & Not Joined:**
                *   Button: Displays "JOIN" button. **(Q1 Style):** Pill shape, gold outline on black, soft hover-pulse/ripple.
                *   User Action: Tap "JOIN".
                *   System Feedback: Button pulses inward (0.2s), morphs to "Joined" state (see below), haptic tap, ambient success feedback (e.g., toast/badge animation).
            *   **State: Private & Not Joined:**
                *   Button: Displays "REQUEST TO JOIN" button. **(Q2 Style):** Pill shape, includes Lock icon.
                *   User Action: Tap "REQUEST TO JOIN".
                *   System Feedback: Button morphs to "Pending Request" state (see below), haptic tap.
            *   **State: Joined:**
                *   Indicator: **(Q3 Style):** "Hive logo lock-on" symbol displayed near Space name/banner.
                *   Button: Displays "JOINED" button. **(Q3 Style):** Pill shape, filled gold, black text "JOINED ✅".
                *   User Action: **Swipe Left** on the "JOINED" button.
                *   System Feedback: Reveals "Leave Space ❌" action (red accent).
                *   User Action: Tap "Leave Space ❌". -> Triggers Leave sequence (confirmation dialog, etc.).
            *   **State: Pending Request:**
                *   Button: Displays "REQUESTED" button. **(Q2/Q4 Style):** Pill shape, low-opacity gold, text "REQUESTED ⏳", small rotating hexagon icon. Button is slightly grayed out, tap disabled. Slow glowing ring background animation.
                *   Subtext: "Pending approval by Space admins" displayed below button.
                *   User Action: **Tap-and-hold** (2s) the "REQUESTED" button.
                *   System Feedback: Reveals "Cancel Request" action.
                *   User Action: Tap "Cancel Request".
                *   System Feedback: Process cancellation, button reverts to "Request to Join" state.
        *   **Key Info:** Member Count, Public/Private status indicator, Space Description/About section.
        *   **(Optional) Rules:** Section displaying Space rules.
        *   **(Optional) Tags/Categories:** Associated tags.
        *   **(Optional) Admin/Moderator List:** Displaying key members.
        *   **Content Feed:** **(Q5 Answer): Inline Feed.** A feed displaying posts/content specifically from this Space is shown directly on this screen, scrollable below the header/membership section.
    *   **User Action (View Content):** User scrolls/interacts with the inline Space content feed.
    *   **User Action (Leave - Triggered by Swipe Action):**
        *   System Action: Show confirmation dialog ("Leave [Space Name]?").
        *   User Action: Confirms leave.
        *   System Action: Process leave request (API call).
        *   Update UI (Button/Indicator reverts to relevant Not Joined state).
    *   **Analytics:** [`flow_step: space.details_viewed {space_id}`], [`flow_step: space.join_attempt {space_id}`], ..., [`flow_step: space.request_cancel_attempt {space_id}`], [`flow_step: space.request_cancel_success {space_id}`]

---

## 4. State Diagrams

*   **Initial (Not Joined):** Screen loaded, shows Space info, Join/Request button visible.
*   **Initial (Joined):** Screen loaded, shows Space info, "Hive lock-on" indicator visible, Joined button visible (swipe reveals Leave).
*   **Initial (Pending):** Screen loaded, shows Space info, Requested button visible (tap-hold reveals Cancel).
*   **Joining:** Button shows loading/morphing state briefly after tap.
*   **Requesting:** Button morphs to Pending state after tap.
*   **Join Success:** UI updates to Joined state (Indicator + Button).
*   **Request Success:** UI updates to Pending state.
*   **Leaving:** Confirmation dialog shown after swipe+tap.
*   **Leave Success:** UI updates to Not Joined state.
*   **Cancelling Request:** Cancel action revealed on tap-hold.
*   **Cancel Request Success:** UI updates to Not Joined (Private) state.

---

## 5. Error States & Recovery

*   **Trigger:** Failure to load Space details.
    *   **State:** Show loading indicator, then full-screen error message (e.g., "Couldn't load Space details. Try again.") with a back/retry option.
    *   **Recovery:** User taps retry or navigates back.
    *   **Analytics:** [`flow_error: space.details_load_failed {space_id}`]
*   **Trigger:** Failure during Join/Request/Leave API call.
    *   **State:** Show error message (e.g., via Snackbar: "Failed to join. Please try again."). Button resets to previous state.
    *   **Recovery:** User retries the action.
    *   **Analytics:** [`flow_error: space.action_failed {space_id, action_type, reason}`]
*   **Trigger:** Trying to view details of a non-existent/deleted Space (e.g., from old link).
    *   **State:** API returns 404. Display a "Space not found" error screen.
    *   **Recovery:** User navigates back.

---

## 6. Acceptance Criteria

*   **Pre-conditions:** User taps a valid Space preview card/link.
*   **Success Post-conditions:**
    *   User sees the detailed information for the selected Space (Header, Key Info, Description).
    *   User sees the correct membership status UI (Button states, Indicator) and can perform actions (Join, Request, Cancel Request, Leave via Swipe) (Q1-Q4).
    *   User can successfully initiate Join/Request/Leave/Cancel actions.
    *   User can view the Space's content feed inline (Q5).
*   **General:**
    *   Loading and error states are handled gracefully.
    *   UI clearly distinguishes public/private spaces.

---

## 7. Metrics & Analytics

*   **Space Detail View Rate:** (# Users viewing any Space Detail screen) / (# Active Users).
*   **Join/Request Rate:** (# Successful Join/Request actions) / (# Views of non-member Space Detail screens).
*   **Leave Rate:** (# Successful Leave actions) / (# Views of member Space Detail screens).
*   **Cancel Request Rate:** (# Successful Cancel Request actions) / (# Views of Pending Request Space Detail screens).
*   **Content Engagement Rate (within Space Inline Feed):** (Defined by interactions with inline posts).
*   **Analytics Events:** (Listed in Sequence section)

---

## 8. Design/UX Notes

*   Header (Banner/Logo/Name) should be visually impactful.
*   Membership button states (Join, Request, Pending, Joined) need distinct visual treatments and smooth transitions (morphing).
*   Feedback for actions (haptics, ambient success) should be immediate.
*   Interaction for Leave (Swipe Left) and Cancel Request (Tap & Hold) must be discoverable but intentional.
*   **(Q5):** Inline feed design needs to integrate smoothly below the header/info section.

---

## 9. API Calls & Data

*   **Get Space Details API Call:**
    *   **Request:** Space ID, User ID (to determine membership status).
    *   **Response:** Detailed Space object (ID, Name, Description, Banner/Logo URL, Member Count, Public/Private, Rules, Tags, Admins, Current User Membership Status [None, Member, Pending]).
*   **Join Space API Call:**
    *   **Request:** Space ID, User ID.
    *   **Response:** Success/Failure confirmation.
*   **Request to Join Space API Call:**
    *   **Request:** Space ID, User ID.
    *   **Response:** Success/Failure confirmation.
*   **Leave Space API Call:**
    *   **Request:** Space ID, User ID.
    *   **Response:** Success/Failure confirmation.
*   **Cancel Join Request API Call:**
    *   **Request:** Space ID, User ID.
    *   **Response:** Success/Failure confirmation.
*   **Get Space Content Feed API Call:** (Called by Space Detail Screen)
    *   **Request:** Space ID, Pagination parameters.
    *   **Response:** Paginated list of Post objects specific to this Space.

---

## 10. Open Questions

*   **(Resolved)** Q1: Join Button style and behavior defined (Gold outline -> Filled Gold Morph + Haptic + Ambient Feedback).
*   **(Resolved)** Q2: Request Button style defined (Lock icon, morphs to Pending state).
*   **(Resolved)** Q3: Joined State indicated by filled gold "JOINED" button + "Hive lock-on" symbol. Leave action via **Swipe Left** on button.
*   **(Resolved)** Q4: Pending Request state defined (Low-opacity gold, "REQUESTED ⏳", subtext). Cancel via **Tap & Hold** (2s).
*   **(Resolved)** Q5: Content Feed is **Inline** on the main details screen.

*   **(Action Item):** Design the specific button styles and morphing animations for Join/Request/Pending/Joined states.
*   **(Action Item):** Design the "Hive logo lock-on" symbol.
*   **(Action Item):** Design the ambient success feedback for Join.
*   **(Action Item):** Design the Swipe Left reveal for the Leave action.
*   **(Action Item):** Design the Tap & Hold reveal for the Cancel Request action.
*   **(Action Item):** Design the inline feed presentation within the Space Detail screen. 