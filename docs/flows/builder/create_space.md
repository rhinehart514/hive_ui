# Flow: Builder - Create Space

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:**
*   [Hive UI Product Context & Documentation Principles](../../product_context.md)

**Figma Link (Overall Flow):** [Link to Figma Frame for Create Space Flow]

---

## 1. Title & Goal

*   **Title:** Builder Create Space
*   **Goal:** Allow a user with Builder permissions to successfully configure and create a new Space (community) within Hive.

---

## 2. Persona & Prerequisites

*   **Persona:** Builder (Authenticated User with creation permissions - Verified or Verified+)
*   **Prerequisites:**
    *   User is logged in and has Builder role/permissions.
    *   User is viewing the Spaces Discovery Hub.
*   **(Q1 Entry Point):** Builder taps the **Floating "+" Button** located top-right on the Spaces Discovery Hub screen. (Tooltip: "Start a new Space – rally your people.")

---

## 3. Sequence

*   **Trigger:** Builder taps the Floating "+" Button.
*   **System Action:** Navigate to the Create Space wizard.
*   **(Q2 Flow Structure): Multi-Step Wizard (3 Steps)**

*   **Screen: Create Space - Step 1: Basic Info**
    *   **UI Elements:**
        *   **Space Name** (Input Field). **(Q3 Validation):** Min 3 / Max 30 chars, unique across HIVE, no emojis/special chars (except hyphen), normalized to Title Case. Real-time inline availability check (✓/❌).
        *   **Space Description/Tagline** (Text Area). **(Q4 Validation):** Optional, Max 140 chars.
        *   **Space Logo/Icon Upload.** **(Q5 Required):** Yes. Types: JPG/PNG, Max 2MB. Dimensions: 1:1, Min 512x512. UI includes crop/preview circle.
        *   **Space Banner Image Upload.** **(Q6 Optional):** Yes. Types: JPG/PNG, Max 3MB. Dimensions: 3:1, Min 1200x400. Default: Random gold-on-black gradient if none provided.
        *   Navigation: "Next" button.
    *   **User Action:** Fills fields, taps "Next".

*   **Screen: Create Space - Step 2: Settings**
    *   **UI Elements:**
        *   **Visibility Toggle:** Public / Private. **(Q7 Default):** Public. Tooltip explains implications (discovery, search visibility).
        *   **(If Private) Approval Mechanism:** Radio options. **(Q8 V1 Options):**
            *   "Admin Invite Only"
            *   "Anyone Can Request — Needs Admin Approval"
            *   (V2: Invite Link Only)
        *   **Space Rules** (Text Area - Optional?).
        *   **Tags** (Input - Optional). **(Q9 V1):** Add up to 3 tags. Stored backend only for V1.
        *   Navigation: "Back", "Next" buttons.
    *   **User Action:** Configures settings, taps "Next".

*   **Screen: Create Space - Step 3: Review & Launch**
    *   **UI Elements:**
        *   Summary display of all configured details (Name, Logo, Banner Preview, Visibility, Rules, Tags).
        *   "Create Space" button (Primary action).
        *   Navigation: "Back" button.
    *   **User Action:** Reviews details, taps "Create Space".
    *   **System Action:** Process the creation request (client-side validation, API call).
        *   Show loading indicator. **(Q10 Style):** "Create Space" button animates (ripple -> hex orbit overlay), disables, shows subtle "Creating..." label.
    *   **System Action (on Success):**
        *   API confirms successful creation, returns new Space ID.
        *   Hide loading indicator.
        *   Display success feedback. **(Q11 Style):** New Space card materializes/slides in briefly, micro-confetti pulse (black/gold hexes), medium haptic feedback. Optional: Snackbar "Your Space is live." (2s fade).
        *   Navigate Builder. **(Q12 Target):** Navigate **directly to the newly created Space Detail screen** (in Builder Mode, potentially prompting first actions like Add Drop/Create Event).
    *   **System Action (on Failure):**
        *   API returns an error.
        *   Hide loading indicator.
        *   Display specific error message. **(Q13 Display):** **Inline errors** for validation (e.g., Name Taken under field). **General black Snackbar** for API/Network failures ("Something went wrong. Please try again.").
    *   **Analytics:** [`flow_step: builder.create_space_initiated`], [`flow_step: builder.create_space_step_complete {step_num}`], [`flow_step: builder.create_space_submitted`], [`flow_step: builder.create_space_success {space_id}`], [`flow_error: builder.create_space_failed {reason}`]

---

## 4. State Diagrams

*   **Initial:** Wizard Step 1 loaded.
*   **Input:** User filling out fields in Step 1, 2.
*   **Review:** Wizard Step 3 (Summary) displayed.
*   **Submitting:** Final button shows in-button loading animation (Q10).
*   **Success:** Success feedback animation/haptics (Q11), user navigated to new Space screen (Q12).
*   **Failure:** Error message shown (Inline or Snackbar per Q13), user remains on relevant wizard step.

---

## 5. Error States & Recovery

*   **Trigger:** Client-side validation failure (e.g., missing required field, invalid name, file too large).
    *   **State (Q13):** Highlight invalid fields, show **inline error messages**.
    *   **Recovery:** User corrects input and re-submits step/final confirmation.
*   **Trigger:** API Error (e.g., Space name already taken, server error).
    *   **State (Q13):** Show error message via **general black Snackbar** ("Something went wrong. Please try again.") or **inline** if directly related to a field (e.g., Name Taken).
    *   **Recovery:** User corrects issue (e.g., changes name) or retries submission.
*   **Trigger:** Network error during submission.
    *   **State (Q13):** Show network error message via **general black Snackbar**.
    *   **Recovery:** User regains connection and retries.

---

## 6. Acceptance Criteria

*   **Pre-conditions:** User is logged in with Builder permissions.
*   **Success Post-conditions:**
    *   Builder can initiate creation via Floating "+" button (Q1).
    *   Builder can navigate through the 3-step wizard (Q2).
    *   Builder can input/upload details adhering to validation rules (Q3-Q9).
    *   A new Space is created upon valid submission.
    *   In-button loading animation shown (Q10).
    *   Clear success feedback provided (animation, haptics, optional snackbar) (Q11).
    *   Builder is navigated directly to the new Space screen (Q12).
*   **Failure Post-conditions:**
    *   Validation and API errors are displayed clearly using specified methods (inline/snackbar) (Q13).
*   **General:**
    *   Wizard flow is smooth and follows HIVE design standards.

---

## 7. Metrics & Analytics

*   **Space Creation Initiated Rate:** (# Builders starting creation flow) / (# Active Builders).
*   **Space Creation Completion Rate:** (# Successful Space creations) / (# Builders starting creation flow).
*   **Avg Time to Create:** Average time spent in the creation flow.
*   **Error Rate by Step/Field:** Track where users encounter issues.
*   **Analytics Events:** (Listed in Sequence section)

---

## 8. Design/UX Notes

*   Balance providing enough customization options without overwhelming the Builder.
*   Clear validation and error feedback are crucial.
*   Consider previews for logo/banner uploads.
*   Make the public/private setting and its implications very clear.

---

## 9. API Calls & Data

*   **Create Space API Call:**
    *   **Request:** Builder User ID, Space Name, Description, Logo Data, Banner Data, Public/Private Setting, Approval Mechanism (if private), Rules, Tags/Categories (if applicable).
    *   **Response (Success):** New Space ID, confirmation.
    *   **Response (Error):** Specific error code/message (e.g., `NAME_TAKEN`, `INVALID_INPUT`, `SERVER_ERROR`).

---

## 10. Open Questions

*   **(Resolved)** Q1: Entry Point is Floating "+" button on Spaces Hub (Builders only).
*   **(Resolved)** Q2: Flow is a 3-Step Wizard.
*   **(Resolved)** Q3: Name Validation rules defined.
*   **(Resolved)** Q4: Description Limit is 140 chars.
*   **(Resolved)** Q5: Logo Upload is required, constraints defined.
*   **(Resolved)** Q6: Banner Upload is optional, constraints & default defined.
*   **(Resolved)** Q7: Visibility defaults to Public, tooltip explains.
*   **(Resolved)** Q8: Private Options for V1 defined (Admin Invite, Request+Approval).
*   **(Resolved)** Q9: Tags are optional (max 3), backend-only for V1.
*   **(Resolved)** Q10: Loading Indicator is in-button animation.
*   **(Resolved)** Q11: Success Feedback defined (animation, haptics, optional snackbar).
*   **(Resolved)** Q12: Post-Creation Navigation is direct to the new Space screen.
*   **(Resolved)** Q13: Error Display uses Inline for validation, Snackbar for general/network errors.

*   **(Action Item):** Design the 3-step wizard UI layout.
*   **(Action Item):** Implement real-time name availability check.
*   **(Action Item):** Implement image upload component with crop/preview.
*   **(Action Item):** Design the specific loading animation for the create button.
*   **(Action Item):** Design the success feedback animation (card materialize, confetti).
*   **(Action Item):** Define the initial "Builder Mode" prompt on the new Space screen. 