# Flow: Student - Participate in Ritual (V1: THE BRACKET)

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:**
*   [Flow: Student - View Active Ritual (Feed Element)](./view_active_ritual_feed.md)
*   [Hive UI Product Context & Documentation Principles](../../product_context.md)

**Figma Link (Overall Flow):** [Link to Figma Frame for Bracket View & Interactions]

---

## 1. Title & Goal

*   **Title:** Student Participate in Ritual (V1: THE BRACKET)
*   **Goal:** Define how users view progress and understand the status of the single, platform-wide ritual: "THE BRACKET".

*Note: V1 focuses solely on THE BRACKET. No other rituals, HiveLab experiments, or badges exist.* 

---

## 2. Persona & Prerequisites

*   **Persona:** Student (Logged-in User)
*   **Prerequisites:**
    *   User is logged in.
    *   THE BRACKET ritual is active platform-wide.
    *   The user is part of a Space participating in THE BRACKET.

---

## 3. Sequence of Actions

### 3.1 Discovering & Viewing THE BRACKET
*   **Trigger:** User opens the main feed while THE BRACKET is active.
*   **UI State:** A prominent, pinned **Ritual Feed Strip** is displayed at the top of the Main Feed, showcasing THE BRACKET. (Ref: `view_active_ritual_feed.md`)
*   **User Action:** User taps on the Ritual Feed Strip.
*   **System Action:** Navigates the user to the dedicated "Bracket View" screen.
*   **UI State (Bracket View):** Displays the current state of THE BRACKET.
    *   **Content:** Shows the user's Space's current status (e.g., "Competing in Round 3", "Eliminated in Quarterfinals", "Winner!").
    *   **Matchups:** Displays the current round's live matchups, highlighting the user's Space if applicable.
    *   **Progression:** Visually represents the bracket structure and advancing Spaces. (Q1.9.1)

### 3.2 Viewing Leaderboard / Bracket Progress
*   **Trigger:** User is on the Bracket View screen.
*   **UI State:** The Bracket View *is* the leaderboard, showing live matchups and advancing Spaces. (Q1.9.2)
    *   **Data Shown:** Space names, round status/matchup results. (Q1.9.2)
    *   *Constraint:* No individual user rankings or participation scores are displayed in V1. (Q1.9.2)

### 3.3 Ritual Completion & Rewards (THE BRACKET)
*   **Trigger:** THE BRACKET ritual concludes.
*   **System Action:** The platform determines the winning Space.
*   **UI Feedback (Winning Space):**
    *   The winning Space receives a **"Crowned" designation**, visually indicated (e.g., a gold crown icon 👑) on their Space card/profile wherever it appears. (Q1.9.4 - *Note: No badge system V1*)
    *   A **system-generated victory post** is automatically published to the winning Space's feed. (Q1.9.5)
*   **UI Feedback (Other Participants):** The Bracket View updates to show the final results.

### 3.4 Builder Creation / Badge Sharing (Out of Scope V1)
*   Builders **cannot** create or configure rituals in V1. All rituals (i.e., THE BRACKET) are platform-seeded. (Q1.9.3)
*   There is **no badge system** in V1. (Q1.9.4)
*   There is **no explicit badge sharing** functionality in V1. (Q1.9.5)

*   **Analytics:** [`flow_step: student.ritual.bracket.view_feed_strip`], [`flow_step: student.ritual.bracket.view_detail`], [`event: system.ritual.bracket.completed {winning_space_id}`], [`event: system.ritual.bracket.victory_post_generated {space_id}`]

---

## 4. State Diagrams

*   (Diagram: View Feed -> See Bracket Strip -> Tap -> View Bracket Detail [Shows Space Status, Matchups] -> [Ritual Ends] -> See Final Results / Crowned Space)

---

## 5. Error States & Recovery

*   **Trigger:** Error loading Bracket View data.
    *   **State:** Error message displayed within the view.
    *   **Recovery:** Retry mechanism (e.g., pull-to-refresh).
*   **Trigger:** User not part of a participating Space.
    *   **State:** Bracket View might show the overall bracket but without highlighting a specific user Space.
    *   **Recovery:** N/A (User needs to join a participating Space to be 'involved').

---

## 6. Acceptance Criteria

*   The Bracket feed strip is visible when the ritual is active.
*   Tapping the strip navigates to the dedicated Bracket View (Q1.9.1).
*   Bracket View correctly displays the user's Space status and current matchups (Q1.9.1).
*   The view functions as the leaderboard, showing advancing Spaces (Q1.9.2).
*   No user-specific rankings are displayed (Q1.9.2).
*   The winning Space receives the "Crowned" visual designation (Q1.9.4).
*   A victory post is auto-generated for the winner (Q1.9.5).
*   No badges are awarded or shared (Q1.9.4, Q1.9.5).
*   Builders cannot create rituals (Q1.9.3).
*   Errors loading the view are handled gracefully.

---

## 7. Metrics & Analytics

*   **Bracket View Rate:** (# Views of Bracket Detail Screen) / (# Feed Views).
*   **Ritual Engagement:** (Metrics TBD based on actual bracket mechanics if any user interaction beyond viewing is added later).
*   **Analytics Events:** (Listed in Sequence section)

---

## 8. Design/UX Notes

*   The feed strip needs to be highly visible and engaging.
*   The Bracket View needs to clearly communicate complex information (matchups, progression, status) concisely.
*   The "Crowned" designation should be a clear and desirable visual reward.

---

## 9. API Calls & Data

*   **Get Bracket State API Call:**
    *   **Request:** User ID (to determine user's space).
    *   **Response:** Current Round Info, List of Matchups (Space IDs, Scores/Status), User's Space Status, [Winner Info if applicable].

---

## 10. Open Questions (Resolved for V1)

1.  **View Own Progress:** Where does the user view their progress?
    *   ✅ **A1.9.1:** Within the Ritual feed element (strip) and the full Bracket view screen accessed via tap-through.
2.  **Leaderboard V1:** Is there a public leaderboard? How accessed? What data? Anonymous?
    *   ✅ **A1.9.2:** Yes, the Bracket View *is* the leaderboard. Shows live matchups & advancing Spaces (Space names, round status). No user rankings.
3.  **Builder Creation V1:** Can Builders create rituals?
    *   ✅ **A1.9.3:** No, THE BRACKET is platform-seeded.
4.  **Badge Awarding V1:** How are badges awarded/claimed?
    *   ✅ **A1.9.4:** No badge system in V1. Winner gets "Crowned" Space designation.
5.  **Badge Sharing V1:** How can users share badges?
    *   ✅ **A1.9.5:** No badge sharing. Victory post auto-generated in winning Space feed.

**All questions resolved for V1.** 