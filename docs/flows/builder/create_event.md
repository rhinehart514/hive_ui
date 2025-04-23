# Flow: Builder - Create Event

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:**
*   [Hive UI Product Context & Documentation Principles](../../product_context.md)

**Figma Link (Overall Flow):** [Link to Figma Frame for Create Event Flow]

---

## 1. Title & Goal

*   **Title:** Builder Create Event
*   **Goal:** Allow a user with Builder permissions within a specific Space to successfully configure and publish a new Event hosted by that Space.

---

## 2. Persona & Prerequisites

*   **Persona:** Builder (Authenticated User with Admin role for the host Space)
*   **Prerequisites:**
    *   User is logged in and has Admin permissions for at least one Space.
    *   User is viewing the specific Space they want the event to be hosted by.
*   **(Q1 Entry Point):** Builder taps the **"+ Add Event" button** likely located prominently within the Space's main view/feed (visible only to Builders of that Space).

---

## 3. Sequence

*   **Trigger:** Builder taps the "+ Add Event" button within a Space.
*   **System Action:** Navigate to the Create Event form.
*   **(Q2 Flow Structure): Single Form Page** (Scrollable).
*   **Screen:** Create Event Form
    *   **UI Elements:**
        *   **Event Name** (Input Field). **(Q3 Validation):** Min 3 / Max 60 chars, no emojis/symbols (except hyphen). Real-time inline validation hints.
        *   **Event Description** (Text Area). **(Q4 Validation):** Max 500 chars, plain text only V1. Character count shown after 200 chars.
        *   **Cover Image Upload.** **(Q5 Optional):** Yes. Required Aspect Ratio: 16:9 (min 1200x675). Types: JPG/PNG, Max 3MB. UI shows crop/preview. Default: Auto-generated gradient with Space icon watermark.
        *   **Host Space:** **(Q6 Auto-set):** Displayed non-editably, based on the Space where creation was initiated.
        *   **Start Date & Time Picker.** (Requires validation: cannot be in the past).
        *   **End Date & Time Picker.** (Requires validation: must be after Start Date/Time).
        *   **Location** (Input Field). **(Q7 V1 Input):** Simple free text field (e.g., "Student Union 302"). No V1 map integration.
        *   **Visibility** (Toggle Chips). **(Q8 Options):** Public (🌐 Default), Space Members Only (🛡️), Unlisted (👁️‍🗨️ via link). Tooltips explain implications.
        *   **Tags** (Input - Optional). **(Q9 V1):** Add up to 3 freeform tags. Stored backend only V1.
        *   **RSVP Limit** (Numeric Input - Optional?).
        *   **"Publish Event" Button** (Primary action).
    *   **User Action:** Builder fills out the required fields.
    *   **User Action:** Builder taps the "Publish Event" button.
    *   **System Action:** Process the creation request (client-side validation, API call).
        *   Show loading indicator. **(Q10 Style):** Button shows in-button orbiting hex spinner, label changes to "Publishing...", button disables.
    *   **System Action (on Success):**
        *   API confirms successful creation, returns new Event ID.
        *   Hide loading indicator.
        *   Display success feedback. **(Q11 Style):** Hex ripple from button, black/gold confetti pulse animation (from top edge?), medium haptic pulse. (Optional brief Snackbar).
        *   Navigate Builder. **(Q12 Target):** Navigate **immediately to the new Event Detail screen**.
    *   **System Action (on Failure):**
        *   API returns an error.
        *   Hide loading indicator, re-enable button.
        *   Display specific error message. **(Q13 Display):** **Inline errors** for field validation/duplicates (e.g., Name Taken). **General black Snackbar** for API/Network failures.
    *   **Analytics:** [`flow_step: builder.create_event_initiated {host_space_id}`], [`flow_step: builder.create_event_submitted {host_space_id}`], [`flow_step: builder.create_event_success {event_id, host_space_id}`], [`flow_error: builder.create_event_failed {host_space_id, reason}`]

---

## 4. State Diagrams

*   **Initial:** Create Event form loaded.
*   **Input:** User filling out fields.
*   **Submitting:** Publish button shows in-button loading animation (Q10).
*   **Success:** Success feedback animation/haptics (Q11), user navigated to new Event Detail screen (Q12).
*   **Failure:** Error message shown (Inline or Snackbar per Q13), user remains on form.

---

## 5. Error States & Recovery

*   **Trigger:** Client-side validation failure (e.g., missing name, invalid date/time logic, length limits).
    *   **State (Q13):** Highlight invalid fields, show **inline error messages** in red text.
    *   **Recovery:** User corrects input and re-submits.
*   **Trigger:** API Error (e.g., server error, potentially duplicate name if not caught client-side).
    *   **State (Q13):** Show error message via **general black Snackbar** or **inline** for specific issues like Name Taken.
    *   **Recovery:** User corrects issue or retries submission.
*   **Trigger:** Network error during submission.
    *   **State (Q13):** Show network error message via **general black Snackbar**.
    *   **Recovery:** User regains connection and retries.

---

## 6. Acceptance Criteria

*   **Pre-conditions:** User is Admin of a Space and initiates creation from within that Space (Q1).
*   **Success Post-conditions:**
    *   Builder interacts with a single-page form (Q2).
    *   Builder can input/upload details adhering to validation rules (Q3-Q9).
    *   Host Space is correctly auto-assigned (Q6).
    *   A new Event is created upon valid submission.
    *   In-button loading animation shown (Q10).
    *   Clear success feedback provided (animation, haptics) (Q11).
    *   Builder is navigated directly to the new Event Detail screen (Q12).
*   **Failure Post-conditions:**
    *   Validation and API errors are displayed clearly using specified methods (inline/snackbar) (Q13).
*   **General:**
    *   Form is intuitive, efficient, and follows HIVE design standards.

---

## 7. Metrics & Analytics

*   **Event Creation Initiated Rate:** (# Builders starting creation flow) / (# Active Builders).
*   **Event Creation Completion Rate:** (# Successful Event creations) / (# Builders starting creation flow).
*   **Avg Time to Create:** Average time spent in the creation flow.
*   **Error Rate by Step/Field:** Track where users encounter issues.
*   **Analytics Events:** (Listed in Sequence section)

---

## 8. Design/UX Notes

*   Single-page form prioritizes speed for event creation.
*   Date/Time pickers should be native or well-integrated.
*   Location input is simple free text for V1.
*   Host Space is implicit, reinforcing context.
*   Validation for time logic (End after Start) is critical.
*   Visibility options should use clear iconography.

---

## 9. API Calls & Data

*   **Create Event API Call:**
    *   Request: Builder User ID, Host Space ID (implicit from context), Event Name, Description, Cover Image Data (optional), Start Time, End Time, Location Text, Visibility Setting, RSVP Limit (optional), Tags (optional).
    *   Response (Success): New Event ID, confirmation.
    *   Response (Error): Specific error code/message.

---

## 10. Open Questions

*   **(Resolved)** Q1: Entry Point is contextual **"+ Add Event" button within a managed Space**.
*   **(Resolved)** Q2: Flow Structure is a **Single Form Page**.
*   **(Resolved)** Q3: Name Validation rules defined (3-60 chars, no emoji/symbols except hyphen).
*   **(Resolved)** Q4: Description Limit is **500 chars**.
*   **(Resolved)** Q5: Cover Image is **optional** (16:9, gradient default).
*   **(Resolved)** Q6: Host Space is **auto-set** based on context, non-editable V1.
*   **(Resolved)** Q7: Location Input is **simple free text** for V1.
*   **(Resolved)** Q8: Event Visibility options are **Public (Default), Space Members Only, Unlisted**.
*   **(Resolved)** Q9: Tags are **optional (max 3)**, backend only for V1.
*   **(Resolved)** Q10: Loading Indicator is **in-button (hex spinner)**.
*   **(Resolved)** Q11: Success Feedback is **ripple + confetti + haptic**.
*   **(Resolved)** Q12: Post-Creation Navigation is **direct to Event Detail screen**.
*   **(Resolved)** Q13: Error Display uses **Inline for validation/duplicates, Snackbar for general/network**.

*   **(Action Item):** Design the single-page Create Event form layout.
*   **(Action Item):** Design the Visibility toggle chips (🌐, 🛡️, 👁️‍🗨️).
*   **(Action Item):** Implement image upload component for cover image (optional).
*   **(Action Item):** Design the in-button loading animation.
*   **(Action Item):** Design the success feedback animation (ripple, confetti).
*   **(Action Item):** Implement robust date/time picker and validation logic. 