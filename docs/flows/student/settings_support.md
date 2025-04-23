# Flow: Student - Settings & Support (V1)

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:**
*   [Flow: Student - Notifications](./notifications.md)
*   [Flow: Student - Profile & Social Graph](./profile_social.md)
*   [Hive UI Product Context & Documentation Principles](../../product_context.md)

**Figma Link (Overall Flow):** [Link to Figma Frame for Settings Screens]

---

## 1. Title & Goal

*   **Title:** Student Settings & Support
*   **Goal:** Define how users access and manage their account settings, privacy preferences, notifications, accessibility options, and help/support resources.

---

## 2. Persona & Prerequisites

*   **Persona:** Student (Logged-in User)
*   **Prerequisites:**
    *   User is logged in.

---

## 3. Sequence of Actions

### 3.1 Accessing Settings
*   **Trigger:** User wants to configure their account or app behavior.
*   **User Action:** User taps the Settings access point.
    *   *Entry Point:* Typically a gear icon (⚙️) on the user's own profile screen (Ref: `profile_social.md`).
*   **UI State:** Displays the main Settings screen, likely organized into sections.

### 3.2 Managing Account Settings
*   **Trigger:** User navigates to the "Account" section within Settings.
*   **User Action:** User selects "Change Email" or "Change Password".
*   **System Action:** Initiates the respective flow (likely involves verification steps, e.g., entering current password, confirming new email via link).
    *   *Constraint:* Full flows for email/password change need separate documentation if complex, but confirm they are accessible here. (Q1.12.1)
*   **User Action:** User selects "Sign Out".
*   **System Action:** Initiates the Logout flow (Ref: `logout.md`). (Q1.12.1)

### 3.3 Managing Privacy & Visibility
*   **Trigger:** User navigates to the "Privacy" section within Settings.
*   **User Action:** User interacts with available privacy controls.
    *   **Private Profile Toggle:** User toggles the switch to make their profile private/public. (Q1.12.2)
    *   **DM Controls:** User selects who can send them Direct Messages: [Anyone] or [Followers Only]. (Q1.12.2)
    *   *Constraint:* No post-level visibility settings are available in V1 beyond the Space context. (Q1.12.2)
*   **System Action:** Saves the selected privacy preferences.

### 3.4 Managing Notification Preferences
*   **Trigger:** User navigates to the "Notifications" section within Settings.
*   **System Action:** Displays the notification preferences screen (as defined in `notifications.md`). (Q1.12.3)
*   **User Action:** User adjusts preferences (type-based toggles, push vs. in-app, global mute).
*   **System Action:** Saves preferences.

### 3.5 Managing Accessibility Options
*   **Trigger:** User navigates to the "Accessibility" section within Settings.
*   **UI State:** Displays available accessibility options.
    *   **Options V1:** A toggle for **"Reduced Motion"**. (Q1.12.4)
    *   *Constraint:* Respects OS-level settings by default. No in-app font size selector in V1. (Q1.12.4)
*   **User Action:** User toggles "Reduced Motion".
*   **System Action:** Saves the preference and applies it to app animations/transitions.

### 3.6 Accessing Help & Support
*   **Trigger:** User navigates to the "Help" or "Support" section within Settings.
*   **User Action:** User selects "FAQ" or "Help Center".
*   **System Action:** Opens a link to an **external knowledge base/website** in a web view or browser. (Q1.12.5)
*   **User Action:** User selects "Contact Support" or "Report a Problem".
*   **System Action:** Opens an **in-app form**. (Q1.12.6)
*   **User Action:** User fills out the form (e.g., Subject, Message Body).
*   **User Action:** User submits the form.
*   **System Action:** Form data is sent to the designated support channel/backend.
*   **UI Feedback:** Confirmation message ("Support request sent").

*   **Analytics:** [`flow_step: student.settings.view_main`], [`flow_step: student.settings.account_change {type(email/password)}`], [`flow_step: student.settings.privacy_change {setting, value}`], [`flow_step: student.settings.accessibility_change {setting, value}`], [`flow_step: student.settings.view_faq`], [`flow_step: student.settings.contact_support_submitted`], [`flow_error: student.settings.save_failed {section}`], [`flow_error: student.settings.contact_support_failed`]

---

## 4. State Diagrams

*   (Diagram: Profile -> Settings Icon -> Settings Main -> Select Section [Account/Privacy/Notifications/Accessibility/Help] -> Modify/View -> [Save])

---

## 5. Error States & Recovery

*   **Trigger:** Error saving settings changes (Account, Privacy, Notifications, Accessibility).
    *   **State:** Error message (Snackbar), UI reverts to previous state.
    *   **Recovery:** User retries saving.
*   **Trigger:** Error opening external FAQ link.
    *   **State:** Error message or browser error.
    *   **Recovery:** User checks connection, potentially tries later.
*   **Trigger:** Error submitting Contact Support form.
    *   **State:** Error message (Snackbar), form data remains.
    *   **Recovery:** User retries submission.

---

## 6. Acceptance Criteria

*   Settings screen is accessible from the profile.
*   Users can initiate email/password change flows (Q1.12.1).
*   Sign out action works correctly (Q1.12.1).
*   Privacy settings (Private Profile, DM Control) can be configured (Q1.12.2).
*   Notification settings screen is accessible and functions as defined elsewhere (Q1.12.3).
*   Accessibility options (Reduced Motion) can be toggled (Q1.12.4).
*   Help/FAQ links to external resource (Q1.12.5).
*   Contact Support uses an in-app form (Q1.12.6).
*   Settings changes are saved correctly, with appropriate error handling.

---

## 7. Metrics & Analytics

*   **Settings Access Rate:** % of users accessing settings.
*   **Feature Usage:** Rate of change for each setting (Privacy, Notifications, Accessibility).
*   **Support Request Rate:** (# Support Forms Submitted) / (# Active Users).
*   **FAQ Access Rate.**
*   **Analytics Events:** (Listed in Sequence section)

---

## 8. Design/UX Notes

*   Settings should be clearly organized into logical sections.
*   Explanations for privacy and accessibility settings should be clear and concise.
*   Ensure easy access to help and support channels.
*   Password/Email change flows require security considerations (verification).

---

## 9. API Calls & Data

*   **Update User Settings API Call:**
    *   **Request:** User ID, Map of changed settings (e.g., `{'is_profile_private': true, 'dm_preference': 'followers_only', 'reduced_motion': true}`).
    *   **Response:** Success/Failure.
*   **(Email/Password Change APIs):** Separate APIs likely exist for these secure flows.
*   **Submit Support Request API Call:**
    *   **Request:** User ID, Subject, Message Body, [Device Info?].
    *   **Response:** Success/Failure.

---

## 10. Open Questions (Resolved for V1)

1.  **Account Settings Access:** Confirm change email/password flows accessible?
    *   ✅ **A1.12.1:** Yes, change email and password flows are accessible. Sign out is also here.
2.  **Privacy Controls V1:** What specific privacy settings are available?
    *   ✅ **A1.12.2:** Toggle for private profile; DM controls ("Anyone" / "Followers Only"). No post-level visibility.
3.  **Notification Link:** Confirm this links to the defined notification settings?
    *   ✅ **A1.12.3:** Yes, links to the settings defined in Q1.10.7 / `notifications.md`.
4.  **Accessibility Options V1:** Specific in-app accessibility settings?
    *   ✅ **A1.12.4:** Respects OS settings. In-app toggle for Reduced Motion only. No font size selector.
5.  **Help/FAQ Method:** External link or in-app viewer?
    *   ✅ **A1.12.5:** Linked externally (website/knowledge base).
6.  **Contact Support Method:** In-app form or external link?
    *   ✅ **A1.12.6:** In-app form (Subject + Message).

**All questions resolved for V1.** 