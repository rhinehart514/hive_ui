# Flow: Student - Boost / Repost (Within Space)

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:**
*   [Flow: Student - Main Feed Loading & Refresh](./feed_loading_refresh.md)
*   [Hive UI Product Context & Documentation Principles](../../product_context.md)

**Figma Link (Overall Flow):** [Link to Figma Frame for Repost UI/Modal]

---

## 1. Title & Goal

*   **Title:** Student Boost / Repost (Within Space)
*   **Goal:** Allow a user to share or amplify a piece of content (likely a Post/Drop) from one Space into the feed of another Space they are a member of.

---

## 2. Persona & Prerequisites

*   **Persona:** Student (Logged-in User)
*   **Prerequisites:**
    *   User is viewing content eligible for reposting.
        *   ❓ **Q1:** What content types are eligible for reposting in V1? (e.g., Standard Posts/Drops only? Events?)
        *   ✅ **A1 (V1):** **Standard Drops (Posts), Events, and Ritual Updates** (if structured as feed items). Comments/replies, polls/prompts are not boostable in V1.
    *   User is a member of at least one *other* Space where they have permission to post/repost.

---

## 3. Sequence

*   **Trigger:** User finds an eligible content item (Q1) they wish to share in another Space.
*   **User Action:** User taps the "Boost" or "Repost" action associated with the content item.
    *   ❓ **Q2:** What is the icon/button used for this action, and where is it located on the content card/detail view?
    *   ✅ **A2 (V1):** Custom **HIVE-styled hex/arrow icon (🔁)**. Located on feed cards (right of like/reaction row) and detail views (near comment/like buttons). Let's consistently call the action "Boost".
*   **System Action:** App presents an interface for selecting the target Space(s).
    *   ❓ **Q3:** How is the list of potential target Spaces presented? (e.g., A searchable list? A simple list if the user has few spaces?)
    *   ✅ **A3 (V1):** A **modal overlay** animates up, showing a scrollable list (Space icon + name) of Spaces the user is a member/Builder of. Includes search if user is in >10 Spaces.
    *   ❓ **Q4:** Can the user repost to multiple target Spaces simultaneously in V1?
    *   ✅ **A4 (V1):** **No.** User must select exactly one target Space per boost action.
*   **User Action:** User selects the target Space(s).
    *   *(V1: Selects exactly one target Space)*
*   **User Action:** [Optional Step - Add Commentary?]
    *   ❓ **Q5:** Can the user add their own comment or context when reposting (similar to a quote-tweet)? If yes, how is this input captured?
    *   ✅ **A5 (V1):** **No.** Boosts are silent amplifications. No user commentary added.
*   **User Action:** User confirms the repost action.
*   **System Action:** App initiates API call(s) to create the repost entry in the target Space(s), linking it back to the original content.
*   **UI Feedback (Success):**
    *   ❓ **Q6:** How is successful reposting confirmed to the user? (e.g., Toast/Snackbar: "Reposted to [Space Name]"? Visual change on the action button?)
    *   ✅ **A6 (V1):** **Snackbar** appears ("Boosted to [Space Name]") and fades after ~2.5s. The boost icon (A2) changes to an **active state** (e.g., solid gold hex pulse).
    *   ❓ **Q7:** Does the original content item visually update to show it has been reposted (e.g., incrementing a repost counter)?
    *   ✅ **A7 (V1):** **Yes.** If repost count ≥ 1, a subtle indicator appears below the original post (e.g., "Boosted by 3 Spaces" or "Boosted in 🔁 [Space Name] +2").
*   **UI State (Target Feed):**
    *   ❓ **Q8:** How does the reposted item appear in the target Space's feed? (e.g., Embedded preview of the original? Clear label "Reposted by [User] from [Original Space]"? Does it link back to the original?)
    *   ✅ **A8 (V1):** Includes a **header strip** ("Boosted by [User] from [Original Space Name]"), a full **visual embed** of the original content card, a **footer link** back to the original Space/item, and its **own reaction row** (reactions are specific to the boost within the target Space).

*   **Analytics:** [`flow_step: student.feed.repost.initiated {original_content_type, original_content_id}`], [`flow_step: student.feed.repost.target_selected {target_space_count}`] `(V1: always 1)`, [`flow_step: student.feed.repost.confirmed {with_comment}`] `(V1: always false)`, [`flow_step: student.feed.repost.success {target_space_ids}`], [`flow_error: student.feed.repost.failed {reason(permission/api_error/rate_limit)}`]

---

## 4. State Diagrams

*   (Diagram showing transitions: Viewing Content -> Taps Repost -> Selects Target(s) -> [Adds Comment?] -> Confirms -> Processing -> Success/Error Feedback)

---

## 5. Error States & Recovery

*   **Trigger:** User tries to repost to a Space they don't have permission for (should be prevented by Q3 list ideally).
    *   **State:** Error message during target selection or upon confirmation.
    *   **Recovery:** User selects a different target.
*   **Trigger:** API error during repost creation.
    *   **State:** Error message (Snackbar/Toast).
    *   **Recovery:** User can attempt to repost again.
*   **Trigger:** Rate limiting (if implemented).
    *   **State:** Error message indicating temporary restriction.
    *   **Recovery:** User tries again later.

---

## 6. Acceptance Criteria

*   Eligible content items (Q1) display the boost action (Q2).
*   User is presented with a list of valid target Spaces (Q3).
*   User can select one target Space (Q4) without commentary (Q5).
*   Successful boost provides clear feedback (Q6) and updates the original item (Q7).
*   Boosted content appears correctly in the target feed, indicating its origin and embedding original content (Q8).
*   Errors (permissions, API) are handled gracefully.

---

## 7. Metrics & Analytics

*   **Repost Rate:** (# Reposts Created) / (# Content Views or Interactions).
*   **Cross-Space Interaction:** Frequency of reposts between different types of Spaces.
*   **Reposts with Commentary:** % of reposts that include added user comments.
*   **Analytics Events:** (Listed in Sequence section)

---

## 8. Design/UX Notes

*   The term "Boost" vs "Repost" should be used consistently. ("Repost" might be clearer?).
*   Make it clear where the content will be shared.
*   Adding commentary significantly increases complexity but also potential value.
*   Consider how to prevent spammy or excessive reposting.
*   Ensure the visual representation of a repost in the target feed is distinct but clearly links to the source.

---

## 9. API Calls & Data

*   **Get Target Spaces API Call (Potentially):**
    *   **Request:** User ID.
    *   **Response:** List of Space IDs/Names user can post to.
*   **Create Repost API Call:**
    *   **Request:** User ID, Original Content ID, Original Content Type, Target Space ID(s), [Optional: User Commentary].
    *   **Response:** Success/Failure indication for each target.

---

## 10. Open Questions

1.  **Eligible Content:** What types of content can be reposted in V1?
    *   ✅ **A1 (V1):** Standard Drops, Events, Ritual Updates (as feed items). Not comments/replies/polls.
2.  **Repost Action UI:** What icon/button initiates reposting and where is it?
    *   ✅ **A2 (V1):** Custom hex/arrow icon (🔁), right of reactions. Action verb: "Boost".
3.  **Target Selection UI:** How is the list of target Spaces presented?
    *   ✅ **A3 (V1):** Modal overlay, scrollable list (icon+name), search if >10 spaces.
4.  **Multi-Target Repost (V1):** Can users repost to multiple Spaces at once?
    *   ✅ **A4 (V1):** No, single target Space selection only.
5.  **Add Commentary (V1):** Can users add their own text when reposting?
    *   ✅ **A5 (V1):** No, boosts are silent amplifications.
6.  **Success Feedback:** How is a successful repost confirmed?
    *   ✅ **A6 (V1):** Snackbar confirmation + icon state change (active gold pulse).
7.  **Original Item Update:** Does the original content show a repost count or indicator?
    *   ✅ **A7 (V1):** Yes, subtle count/indicator below post if count ≥ 1.
8.  **Repost Appearance:** How does a repost look in the target Space's feed?
    *   ✅ **A8 (V1):** Header strip (origin user/space) + full embed + footer link + own reaction row.

**All questions resolved for V1.** 