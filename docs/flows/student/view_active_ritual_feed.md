# Flow: Student - View Active Ritual (THE BRACKET) in Feed

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:**
*   [Hive UI Product Context & Documentation Principles](../../product_context.md)
*   Context: THE BRACKET (Campus Tournament Engine)

**Figma Link (Overall Flow):** [Link to Figma Frame for BRACKET Status Strip]

---

## 1. Title & Goal

*   **Title:** Student View Active Ritual (**THE BRACKET Status Strip**) in Feed
*   **Goal:** Ensure the student user clearly sees, recognizes, and understands the current *phase* of the active campus-wide **THE BRACKET** Ritual presented as a distinct, dynamic element within their main feed, prompting them to engage.

---

## 2. Persona & Prerequisites

*   **Persona:** Student (Authenticated User)
*   **Prerequisites:**
    *   User is logged in and viewing the main Home screen (`/home` - FeedPage).
    *   **THE BRACKET** Ritual is currently active.
    *   The user has potentially just completed the Onboarding Tutorial (for first view).

---

## 3. Sequence

1.  **Screen:** Home Screen / Feed (`lib/features/feed/presentation/pages/feed_page.dart` - Assumed)
    *   **System Action:** Feed data is loaded, including information about the single, active **THE BRACKET** Ritual and its *current phase*.
    *   **UI Element:** **(Q1 Answer)** A distinct, persistent, full-width animated **"BRACKET Status Strip"** component appears anchored near the top of the feed (e.g., below header/onboarding tips). Height ~72-88dp. Style: Rounded edges, subtle glowing border (`#EEB700`?), kinetic background animation (ripple/shimmer). Feels like an energetic surface.
    *   **Content within BRACKET Status Strip (Dynamic based on Phase):**
        *   **Matchup Phase Example:**
            *   Clear Title: "⚔️ THE BRACKET - Round 2"
            *   Matchup Display: "[Space A Logo/Name] vs [Space B Logo/Name]"
            *   Compelling **single-verb** Call to Action button (e.g., "Engage!", "Support!", "View Battle!").
            *   **(Q2 Answer - Liveness/Urgency):**
                *   Subtle background glow-pulse animation.
                *   Scrolling ticker text (optional): e.g., "🔥 [Space A] takes the lead!", "132 students engaged this hour!"
                *   Phase time remaining indicator (e.g., "Ends Tonight").
        *   **(Q3 Answer - Reward Display):** **Default: Reward hidden.** Focus is on competition & momentum. *(A/B test potential)*.
    *   **Initial View (Post-Onboarding):** Feed may scroll to focus on this strip; brief highlight animation.
    *   **Subsequent Views:** The Strip remains prominently displayed, dynamically updating content as the BRACKET phase changes.
    *   **User Action:** User visually identifies and reads the current BRACKET phase information.
    *   **User Action:** User performs a **single tap** on the Strip / its primary call-to-action button.
    *   **Analytics:** [`flow_step: ritual.bracket.strip_viewed {phase}`], [`flow_step: ritual.bracket.hub_opened {phase}`]
    *   **Design/UX Notes:** Maximize visibility and perceived energy/stakes. Use gold accents. CTA must be clear.
    *   **Navigation:** Tapping the element opens the **"BRACKET Engagement Hub"** modal (defined in `participate_in_ritual.md`).
    *   **(End of this specific Discovery flow - transitions to Participation flow)**

---

## 4. State Diagrams

*   **Feed Loading:** BRACKET phase data fetched.
*   **Feed Rendered:** Animated BRACKET Status Strip displayed prominently near top, showing current phase info.
*   **Phase Change:** Strip content updates dynamically without full page reload (ideally).
*   **User Interaction:** Single tap triggers opening the Engagement Hub modal.

---

## 5. Error States & Recovery

*   **Trigger:** Failure to load BRACKET phase data from backend.
    *   **State (Q4 Answer):** Display a visually distinct, softer **"Fallback Strip"** in the element's place. Text: "THE BRACKET status loading… ⏳" or similar. *(Optional: Auto-dismiss fallback strip if user scrolls past it decisively)*.
    *   **Recovery:** Feed refresh attempt, or issue resolves on next data load.
    *   **Analytics:** [`flow_error: ritual.bracket.strip_load_failed`]

---

## 6. Acceptance Criteria

*   **Pre-conditions:** User is on the main feed, THE BRACKET Ritual is active.
*   **Success Post-conditions:**
    *   The active BRACKET phase is displayed via the animated strip near the top (Q1).
    *   The strip includes phase title, relevant content (e.g., matchup), CTA, and liveness cues (Q2).
    *   Rewards are generally hidden (Q3).
    *   The strip content updates dynamically as the BRACKET progresses through phases.
    *   A single tap opens the BRACKET Engagement Hub modal.
*   **Failure Case (Load Fail - Q4):** Fallback strip is displayed appropriately.

---

## 7. Metrics & Analytics

*   **Strip Visibility Rate:** (# Users rendering BRACKET strip) / (# Users loading feed while BRACKET active).
*   **Engagement Hub Open Rate (CTR):** (`ritual.bracket.hub_opened` count) / (`ritual.bracket.strip_viewed` count).
*   **Analytics Events:**
    *   `flow_step: ritual.bracket.strip_viewed {phase}` *(Log when element is rendered)*
    *   `flow_step: ritual.bracket.hub_opened {phase}`
    *   `flow_error: ritual.bracket.strip_load_failed`

---

## 8. Design/UX Notes

*   **(Q1):** Top-anchored, full-width animated strip, persistent during BRACKET.
*   **(Q2):** Use pulse, ticker text, phase timer for energy/urgency.
*   **(Q3):** Hide rewards by default.
*   **(Q4):** Implement soft fallback state for load errors.
*   Single-tap interaction to open Engagement Hub modal.
*   Strip content must dynamically reflect the current BRACKET phase.

---

## 9. API Calls & Data

*   **Feed API Call:** Must reliably return active BRACKET Ritual ID and its *current phase* details (type, title, relevant data like matchup IDs, timer).
*   **Data:** BRACKET ID, Current Phase Type (Nomination, Matchup, Finals), Phase Title, Phase End Time, [Matchup Specific: SpaceA ID, SpaceB ID, Ticker Text].

---

## 10. Open Questions

*   **(Resolved)** All previous Qs have been refined based on THE BRACKET context.

*   **(Action Item):** Design the specific visual assets/animations for the BRACKET Status Strip and its fallback state.
*   **(Action Item):** Define how the Strip content dynamically changes for different BRACKET phases (Nomination, Matchup, Finals).
*   **(Action Item):** Ensure Feed API reliably provides current BRACKET phase data.
*   **(Action Item):** Implement the dynamic update mechanism for the Strip content. 