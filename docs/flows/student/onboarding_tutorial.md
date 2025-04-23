# Flow: Student - Onboarding Highlights / Tutorial

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:** [Hive UI Product Context & Documentation Principles](../../product_context.md)
**Figma Link (Overall Flow):** [Link to Figma Frame for Onboarding Tutorial]

---

## 1. Title & Goal

*   **Title:** Student Onboarding Highlights / Tutorial
*   **Goal:** Briefly introduce the new user to the core concepts and value propositions of Hive (Feed, Rituals, Events, Spaces) immediately after profile completion, guiding them towards their first interaction (joining a Ritual).

---

## 2. Persona & Prerequisites

*   **Persona:** Student (New User)
*   **Prerequisites:**
    *   User has successfully completed the "Onboarding Profile Completion" flow.
    *   User has been navigated to the designated Tutorial route (e.g., `/onboarding-tutorial`).
    *   User is authenticated.
    *   Network connection is available (to check for live Rituals).

---

## 3. Sequence

*(Assumes a simple, swipeable card-based tutorial interface - Max 4 cards)*

1.  **Screen:** Tutorial Card 1 - Feed Introduction
    *   **UI Elements:** Card content (Text, minimal graphics), Progress indicator (e.g., dots), "Next"/Swipe affordance.
    *   **Content:**
        *   Headline: "Welcome to Your Hive Feed"
        *   Body: "This isn't just noise. See what matters now - live Rituals, trending events, key updates. No need to follow anyone to get started."
    *   **User Action:** Taps "Next" or swipes left.
    *   **Analytics:** [`flow_start: onboarding.tutorial`], [`flow_step: tutorial.feed_intro_viewed`]
    *   **Design/UX Notes:** Fast, crisp transition (`brand_aesthetic.md`), haptic feedback ([Mobile]).

2.  **Screen:** Tutorial Card 2 - Rituals Introduction
    *   **UI Elements:** Card content, Progress indicator, "Next"/Swipe affordance.
    *   **Content:**
        *   Headline: "Join Live Rituals"
        *   Body: "Rituals are timed campus moments. Participate, earn badges, and see what happens next. Your first one is waiting in the feed!"
        *   **(Conditional Content):** IF a major known Ritual (e.g., "Campus Madness") is active, adapt text: *"The [Ritual Name] is heating up! Join the action now right from your feed."*
    *   **User Action:** Taps "Next" or swipes left.
    *   **Analytics:** [`flow_step: tutorial.rituals_intro_viewed`]
    *   **Design/UX Notes:** Fast transition, haptic feedback ([Mobile]).

3.  **Screen:** Tutorial Card 3 - Events Introduction
    *   **UI Elements:** Card content, Progress indicator, "Next"/Swipe affordance.
    *   **Content:**
        *   Headline: "Discover Events Easily"
        *   Body: "Forget endless scrolling. Trending events and RSVP opportunities appear right in your feed, sometimes unlocking Rituals."
    *   **User Action:** Taps "Next" or swipes left.
    *   **Analytics:** [`flow_step: tutorial.events_intro_viewed`]
    *   **Design/UX Notes:** Fast transition, haptic feedback ([Mobile]).

4.  **Screen:** Tutorial Card 4 - Spaces Introduction
    *   **UI Elements:** Card content, Progress indicator, "Got It" / "Let's Go" button.
    *   **Content:**
        *   Headline: "Find Your Groups in Spaces"
        *   Body: "Spaces are where clubs and orgs live. We've pre-loaded your campus directory. Browse anytime, join later when you're ready."
        *   *(Optional Graphic):* Minimal representation of a few Space logos/names.
    *   **User Action:** Taps "Got It" / "Let's Go".
    *   **Analytics:** [`flow_step: tutorial.spaces_intro_viewed`], [`flow_step: tutorial.finish_tapped`]
    *   **Design/UX Notes:** Final card transition should feel conclusive. Button uses Primary style. Fast transition, haptic feedback ([Mobile]).

5.  **Navigation:**
    *   **System Action:** Upon tapping the final button, navigate user to the Home screen (`context.go('/home')`).
    *   **System Action (Post-Navigation):** Once the Home screen (Feed) loads, **automatically scroll to and highlight/focus** the top-most active Ritual card. (Implementation detail: Needs coordination with Feed loading and state).
    *   **Analytics:** [`flow_complete: onboarding.tutorial`]
    *   **(End of this flow - transitions to Home/Feed with Ritual focus)**

---

## 4. State Diagrams

*   **Tutorial Screen:** Displays current card (1-4).
*   **State:** Progress indicator updates with each card.
*   **Final Card:** Shows final action button.
*   **Completion:** Navigates to `/home`.

---

## 5. Error States & Recovery

*   Minimal error states expected in this simple UI flow.
*   If navigation to `/home` fails (unlikely), user might be stuck on the final tutorial card. Recovery: Restart app.

---

## 6. Acceptance Criteria

*   **Pre-conditions:** User has completed Profile Completion, navigated to Tutorial route.
*   **Success Post-conditions:**
    *   User has viewed all 4 tutorial cards.
    *   User is navigated to the Home screen (`/home`).
    *   Upon Home screen load, view scrolls to/highlights the top active Ritual.
    *   `flow_complete: onboarding.tutorial` event logged.
*   **General:**
    *   Tutorial displays correct content for Feed, Rituals, Events, Spaces.
    *   Tutorial content adapts if a major Ritual is active.
    *   Transitions between cards are fast and include haptic feedback ([Mobile]).
    *   Progress is clearly indicated.

---

## 7. Metrics & Analytics

*   **Completion Rate:** (# Users reaching Home screen after starting tutorial) / (# Users starting tutorial)
*   **Time-to-complete:** Median time from `flow_start: onboarding.tutorial` to `flow_complete`.
*   **Analytics Events:**
    *   `flow_start: onboarding.tutorial`
    *   `flow_step: tutorial.feed_intro_viewed`
    *   `flow_step: tutorial.rituals_intro_viewed`
    *   `flow_step: tutorial.events_intro_viewed`
    *   `flow_step: tutorial.spaces_intro_viewed`
    *   `flow_step: tutorial.finish_tapped`
    *   `flow_complete: onboarding.tutorial`

---

## 8. Design/UX Notes

*   Keep content concise and focused on the core value prop of each feature.
*   Use minimal, brand-aligned graphics if necessary.
*   Ensure transitions match the "Tactile, Fast, Invisible" principle (`brand_aesthetic.md`). Fast snap, tactile pop ([Mobile]).
*   Progress indicators should be subtle (e.g., dots).
*   Final button should clearly indicate completion.
*   Post-navigation focus on the Ritual in the feed is crucial for driving the first action.

---

## 9. API Calls & Data

*   No direct API calls within this flow.
*   May need to check for active major Rituals (e.g., Campus Madness) to adapt Card 2 content. This check should ideally happen *before* the tutorial starts.

---

## 10. Open Questions

*   **(Resolved)** This flow comes *after* Profile Completion and *before* landing on the main Feed.
*   **(Resolved)** What specific UI component will be used for the tutorial cards? Decision: Standard `PageView` with `Card` widgets and a standard dot indicator package (e.g., `dots_indicator`). Avoid custom components unless essential.
*   **(Resolved)** How exactly will the post-navigation scroll/highlight of the Ritual card be implemented? Decision: The destination screen (`/home` - `FeedPage`) is responsible. After loading its data and identifying the first Ritual, it will programmatically scroll to it and apply a brief highlight animation. 