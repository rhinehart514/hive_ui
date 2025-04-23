# Flow: Student - Password Reset (Forgot Password)

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:** [Hive UI Product Context & Documentation Principles](../../product_context.md)
**Figma Link (Overall Flow):** [Link to Figma Frame for Password Reset Flow]

---

## 1. Title & Goal

*   **Title:** Student Password Reset (Forgot Password)
*   **Goal:** Allow a user who has forgotten their password to request a password reset link via their registered email address.

---

## 2. Persona & Prerequisites

*   **Persona:** Student (Existing User)
*   **Prerequisites:**
    *   User is on the Login screen (`/sign-in`).
    *   User has previously created an account with Email/Password.
    *   User remembers their registered email address.
    *   Network connection is available.

---

## 3. Sequence

1.  **Screen:** Login Screen (`lib/pages/auth/login_page.dart`)
    *   **UI Elements:** "Forgot Password?" link.
    *   **User Action:** Taps the "Forgot Password?" link.
    *   **Analytics:** [`flow_start: password_reset`], [`flow_step: forgot_password_tapped`]
    *   **Design/UX Notes:** [Mobile] Trigger light haptic feedback (`HapticFeedback.lightImpact()`).

2.  **UI Action:** Display Bottom Sheet (`_showResetPasswordSheet`)
    *   **UI Elements (within Bottom Sheet):**
        *   Title (e.g., "Reset Password")
        *   Instructional text (e.g., "Enter your account email to receive a reset link.")
        *   "Email Address" input field (pre-filled with email from Login screen if available).
        *   "Send Reset Link" button.
        *   Close affordance (e.g., swipe down, close icon).
    *   **Design/UX Notes:** Uses standard `showModalBottomSheet`. Background `AppColors.transparent` with custom `_AnimatedBottomSheet` likely handling actual background color (`AppColors.bottomSheetBackground` mentioned in SnackBar) and animation.

3.  **Screen:** Reset Password Bottom Sheet
    *   **User Action (Email):** Confirms or enters their registered email address. [`flow_step: reset.email_entered`]
        *   **Validation (Real-time):** Checks for valid email format (`^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$`).
        *   **Design/UX Notes:** If format is invalid, show inline error message (`_resetEmailError`).
    *   **User Action:** Taps "Send Reset Link" button. [`flow_step: reset.send_link_tapped`]
        *   **Validation (On Tap):** Checks if email field is empty or format is invalid; shows SnackBar and returns if true.
        *   **System Action:** Display Loading State. **(Q1 Answer):** Disable the button. Change button text to "Sending...". Optionally add subtle pulse/shimmer animation.
        *   **API Call:** `sendPasswordResetEmail(email)` (Handled via `ref.read(authControllerProvider.notifier).sendPasswordResetEmail`)

4.  **Branch:** API Response Handling
    *   **IF (Success - Email Sent):** Proceed to Step 5.
    *   **IF (Failure):** Proceed to Step 6.

5.  **UI Action (Success Path):**
    *   **System Action:** Hide Loading State. Dismiss the Bottom Sheet (`Navigator.pop(context)`).
    *   **UI Feedback:** Display confirmation `SnackBar` on the underlying Login Screen. Message varies slightly based on email type (e.g., "Password reset link sent to [email]").
    *   **Design/UX Notes:** [Mobile] Trigger medium haptic feedback (`HapticFeedback.mediumImpact()`).
    *   **Analytics:** [`flow_complete: password_reset`]
    *   **(End of Flow - User needs to check email)**

6.  **State:** Error Handling within Bottom Sheet (Failure Path)
    *   **System Action:** Hide Loading State. Keep Bottom Sheet visible. Re-enable "Send Reset Link" button.
    *   **Analytics:** [`flow_error: password_reset` (include error code/type)]
    *   **Handle Specific Errors:** See Section 5 below.
    *   **Design/UX Notes:** Display error via SnackBar. [Mobile] Trigger error haptic feedback (`HapticFeedback.vibrate()`).

---

## 4. State Diagrams

*   **Login Screen:** "Forgot Password?" link available.
*   **Bottom Sheet (Initial):** Email potentially pre-filled, Send button enabled (validation on tap).
*   **Bottom Sheet (Inputting):** Real-time email format validation.
*   **Bottom Sheet (Loading):** Send button tapped, loading indicator active (Q1), button disabled.
*   **Bottom Sheet (Error):** SnackBar shown *over* the bottom sheet (or on underlying screen after sheet dismissal?), Send button re-enabled.
*   **Success:** Bottom Sheet dismissed, confirmation SnackBar shown on Login screen.

---

## 5. Error States & Recovery

*   **Trigger:** Invalid email format detected on submit.
    *   **State:** SnackBar error: "Please enter a valid email address". Bottom sheet remains open.
    *   **Recovery:** User corrects email input and retries.
*   **Trigger:** API returns `FirebaseAuthException` (e.g., `user-not-found`, `invalid-email`).
    *   **State:** Display error via SnackBar: `e.message ?? "Please try again"` (e.g., "There is no user record corresponding to this identifier."). Bottom sheet remains open.
    *   **Recovery:** User corrects email (if wrong) or realizes they don't have an account with that email. User can dismiss bottom sheet.
*   **Trigger:** API returns `FirebaseAuthException` code `network-request-failed` or other server/network error.
    *   **State:** Display error via SnackBar: "Error sending reset email: [Network error message]" or similar.
    *   **Recovery:** User checks connection and retries tapping "Send Reset Link".

---

## 6. Acceptance Criteria

*   **Pre-conditions:** User is on the Login screen.
*   **Success Post-conditions:**
    *   Password reset email is successfully dispatched by Firebase to the user's registered email.
    *   User receives confirmation feedback via SnackBar.
    *   Bottom sheet is dismissed.
    *   `flow_complete: password_reset` event logged.
*   **Failure Post-conditions (e.g., User Not Found):**
    *   User remains on the Login screen with the Bottom Sheet open.
    *   Appropriate error message displayed via SnackBar.
    *   No email is sent.
    *   `flow_error: password_reset` event logged.
*   **General:**
    *   Bottom sheet appears correctly when "Forgot Password?" is tapped.
    *   Email field allows input and performs format validation.
    *   Loading and error states are handled gracefully within the bottom sheet context.

---

## 7. Metrics & Analytics

*   **Reset Requests Initiated:** Count of `flow_start: password_reset`.
*   **Reset Emails Sent:** Count of `flow_complete: password_reset`.
*   *(Backend Metric Needed):* Actual password resets completed via link.
*   **Error Rate:** Frequency of specific errors (`user-not-found`, Network, Other).
*   **Analytics Events:**
    *   `flow_start: password_reset`
    *   `flow_step: forgot_password_tapped`
    *   `flow_step: reset.email_entered`
    *   `flow_step: reset.send_link_tapped`
    *   `flow_complete: password_reset`
    *   `flow_error: password_reset` (Properties: error_code, error_message)

---

## 8. Design/UX Notes

*   Use standard `showModalBottomSheet` presentation.
*   Ensure email field validation provides clear feedback.
*   Loading state on button needs definition (Q1).
*   Error/Success feedback uses `SnackBar`.
*   [Mobile] Apply haptics: Light impact on sheet open, Medium impact on success, Error pattern on failure.
*   Ensure accessibility within the bottom sheet.

---

## 9. API Calls & Data

*   **Service Call:** `ref.read(authControllerProvider.notifier).sendPasswordResetEmail(email)`
*   **Success Response:** Email successfully sent by Firebase.
*   **Error Responses:** Handled via `FirebaseAuthException`.
*   **Data Handling:** Requires network connection.

---

## 10. Open Questions

*   **(Resolved)** Q1: Loading state is button text change +/- subtle animation, no spinner. 