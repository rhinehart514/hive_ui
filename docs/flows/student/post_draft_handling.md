# Flow: Student - Post Draft Auto-Save & Resume

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:**
*   [Flow: Student - Create Text Post](./create_text_post.md)
*   [Flow: Student - Create Media Post](./create_media_post.md)
*   [Hive UI Product Context & Documentation Principles](../../product_context.md)

**Figma Link (Overall Flow):** [Link to Figma Frame for Draft Handling UI]

---

## 1. Title & Goal

*   **Title:** Student Post Draft Auto-Save & Resume
*   **Goal:** Define how the app automatically saves a user's progress when composing a post (Drop) and allows them to resume editing an unfinished draft later.

---

## 2. Persona & Prerequisites

*   **Persona:** Student (Logged-in User)
*   **Prerequisites:**
    *   User has initiated the post creation flow (Text or Media).

---

## 3. Sequence

### 3.1 Automatic Draft Saving
*   **Trigger:** User is actively composing a post (text or media) but hasn't submitted it.
*   **System Action:** App automatically saves the current state of the composer content periodically or on certain events.
    *   ❓ **Q1:** When is a draft automatically saved? (e.g., On every significant change? After a period of inactivity? On navigating away?)
    *   ✅ **A1 (V1):** Draft is saved **on significant change** (e.g., adding/removing media, typing > 5 words) AND **after 10 seconds of inactivity** in the composer.
    *   ❓ **Q2:** Where are drafts stored? (e.g., Locally on device? Synced to backend?)
    *   ✅ **A2 (V1):** **Local device storage only** for V1. No backend sync.
    *   ❓ **Q3:** What content is included in the draft? (e.g., Text? Media references? Selected Space? Visibility settings?)
    *   ✅ **A3 (V1):** Saves **text content**, references to **locally selected media file paths** (not uploaded URLs), selected **target Space ID**, and chosen **visibility option**.
    *   ❓ **Q4:** Is there any UI indication that a draft has been saved?
    *   ✅ **A4 (V1):** A subtle, non-blocking **toast/chip** appears briefly at the bottom: "Draft saved".

### 3.2 Manual Draft Discard/Cancel
*   **User Action:** User taps a "Cancel" or "Back" button while composing.
*   **System Action:** App prompts the user to confirm discarding changes if a draft exists.
    *   ❓ **Q5:** What happens if the user cancels? Is there a confirmation prompt (e.g., "Discard draft?")?
    *   ✅ **A5 (V1):** If changes have been made since the last save/opening, a confirmation **dialog** appears: "**Discard changes?** Your progress will be lost." with options [Discard] [Cancel]. If no changes, it closes immediately.

### 3.3 Resuming a Draft
*   **Trigger:** User initiates the "Create Post" action (e.g., taps the FAB).
*   **System Action:** App checks if a locally saved draft exists.
    *   ❓ **Q6:** How does the system check for an existing draft when the user starts creating a new post?
    *   ✅ **A6 (V1):** Before opening the blank composer, the system checks the designated local storage location for a draft file.
*   **UI State (Draft Found):** If a draft exists, the system prompts the user.
    *   ❓ **Q7:** How is the user prompted if a draft is found? (e.g., Dialog "Resume draft or start new?")
    *   ✅ **A7 (V1):** A **dialog** appears: "**Resume unsaved draft?** You have a previous draft. Would you like to continue editing it or start a new post?" Options: [Resume Draft] [Start New] [Delete Draft].
*   **User Action (Resume):** User chooses to resume the draft.
*   **System Action:** Composer opens, pre-populated with the saved draft content (text, media previews, Space, visibility).
*   **User Action (Start New):** User chooses to discard the draft and start fresh.
*   **System Action:** Saved draft is deleted. Composer opens blank.

### 3.4 Draft Limits and Overwriting
*   ❓ **Q8:** Can a user have multiple drafts saved, or only the most recent one?
    *   ✅ **A8 (V1):** Only **one draft maximum** is supported in V1. Starting a new post creation flow implicitly offers to overwrite or discard the existing one if found.

### 3.5 Handling Draft Save Failures
*   ❓ **Q9:** What happens if the automatic draft save fails (e.g., disk full, permissions)?
    *   ✅ **A9 (V1):** Fails **silently** in V1. The system might attempt a retry in the background, but no explicit error is shown to the user to avoid disruption. The primary goal is successful posting; drafts are a convenience.

*   **Analytics:** [`flow_step: student.post.draft.auto_saved`], [`flow_step: student.post.draft.discard_prompt`], [`flow_step: student.post.draft.discarded`], [`flow_step: student.post.draft.resume_prompt`], [`flow_step: student.post.draft.resumed`], [`flow_step: student.post.draft.deleted`], [`flow_error: student.post.draft.save_failed {reason}`]

---

## 4. State Diagrams

*   (Diagram: Composing -> [Auto-Save] -> Interrupt -> Draft Exists -> Resume Trigger -> Prompt -> Load Draft / Start New)

---

## 5. Error States & Recovery

*   **Trigger:** Error saving draft (e.g., storage full if local, network error if synced).
    *   **State:** Potentially show a transient error ("Failed to save draft"). Content might be lost if user navigates away before successful save.
    *   ❓ **Q9:** How critical is draft saving? Should failure block navigation away from the composer?
*   **Trigger:** Error loading/resuming draft.
    *   **State:** Show error message. Composer likely opens in empty state.
    *   **Recovery:** User starts a new post.

---

## 6. Acceptance Criteria

*   Drafts are auto-saved based on defined trigger/frequency (Q1, Q2).
*   Saved drafts include appropriate content (Q3).
*   Users are notified of save status if applicable (Q4).
*   Explicit discard action behaves as expected (Q5).
*   Users are prompted to resume existing drafts upon re-entering composer flow (Q6, Q7).
*   Resuming correctly restores saved content.
*   Multiple drafts (if supported) are handled correctly (Q8).
*   Save/resume errors are handled (Q9).

---

## 7. Metrics & Analytics

*   **Draft Save Rate:** (# Drafts Saved) / (# Composer Sessions Initiated).
*   **Draft Resume Rate:** (# Drafts Resumed) / (# Drafts Saved).
*   **Draft Discard Rate:** (# Drafts Explicitly Discarded) / (# Drafts Saved).
*   **Draft Save/Resume Failure Rate:** % of save/resume attempts failing.
*   **Analytics Events:** (Listed in Sequence section)

---

## 8. Design/UX Notes

*   Auto-save should be frequent enough to prevent significant data loss but not so frequent as to impact performance.
*   Saving locally (Q2) is simpler but risks data loss if app is deleted. Syncing is more robust but complex.
*   The resume flow (Q7) should be clear and minimize friction.
*   Handling multiple drafts (Q8) adds complexity but might be needed if users frequently switch contexts.

---

## 9. API Calls & Data

*   **Save Draft API Call (If Synced):**
    *   **Request:** User ID, Draft ID (if exists), Draft Content (Text, Media Refs, Target Space, Visibility?).
    *   **Response:** Success/Failure, [Draft ID].
*   **Get Draft API Call (If Synced):**
    *   **Request:** User ID.
    *   **Response:** List of [Draft Summary] or [Full Draft Content].
*   **Delete Draft API Call (If Synced & Explicit Discard):**
    *   **Request:** User ID, Draft ID.
    *   **Response:** Success/Failure.

---

## 10. Open Questions

1.  ~~**Auto-Save Trigger:** When are drafts saved automatically?~~
    *   ✅ **A1 (V1):** On significant change (>5 words, media added/removed) AND after 10s inactivity.
2.  ~~**Storage Location:** Local device or backend synced?~~
    *   ✅ **A2 (V1):** Local device storage only.
3.  ~~**Draft Content:** What exactly is saved in the draft?~~
    *   ✅ **A3 (V1):** Text, local media paths, Space ID, visibility option.
4.  ~~**Save Indication:** Any UI feedback when a draft is saved?~~
    *   ✅ **A4 (V1):** Subtle toast/chip: "Draft saved".
5.  ~~**Cancel Behavior:** Confirmation prompt on cancel/back?~~
    *   ✅ **A5 (V1):** Yes, dialog "Discard changes?" if changes exist.
6.  ~~**Draft Check:** How/when does the system check for existing drafts?~~
    *   ✅ **A6 (V1):** Checks local storage before opening composer on FAB tap.
7.  ~~**Resume Prompt:** How is the user prompted if a draft is found?~~
    *   ✅ **A7 (V1):** Dialog: "Resume unsaved draft?" [Resume Draft] [Start New] [Delete Draft].
8.  ~~**Draft Limit:** Multiple drafts allowed, or only one?~~
    *   ✅ **A8 (V1):** One draft maximum.
9.  ~~**Save Failure:** How are draft save errors handled?~~
    *   ✅ **A9 (V1):** Silent failure, potential background retry.

**All questions resolved for V1.** 