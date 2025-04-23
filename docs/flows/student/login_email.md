# Flow: Student - Log In with Email/Password

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:** [Hive UI Product Context & Documentation Principles](../../product_context.md)
**Figma Link (Overall Flow):** [Link to Figma Frame for Email Login Flow]

---

## 1. Title & Goal

*   **Title:** Student Log In with Email/Password
*   **Goal:** Allow an existing student user to authenticate and access their Hive account using their registered email address and password.

---

## 2. Persona & Prerequisites

*   **Persona:** Student (Existing User)
*   **Prerequisites:**
    *   User has previously created a Hive account with Email/Password.
    *   User is logged out or their session has expired.
    *   User is on the Login screen (`/sign-in` or potentially redirected from Welcome screen).
    *   Network connection is available.

---

## 3. Sequence

1.  **Screen:** Login Screen (`lib/pages/auth/login_page.dart`)
    *   **UI Elements:** App Logo, "Email Address" input field, "Password" input field (secure entry), "Log In" button, "Forgot Password?" link, Social login buttons (Google, Apple), "Don't have an account? Sign Up" link.
    *   **User Action (Email):** Enters registered email address into "Email Address" field. [`flow_step: login.email_entered`]
        *   **Validation (Real-time):** Checks if input is a valid email format (`^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$`).
        *   **Design/UX Notes:** If format is invalid, show inline error message below field.
    *   **User Action (Password):** Enters password into "Password" field. [`flow_step: login.password_entered`]
        *   **Design/UX Notes:** Secure text entry by default. Provide toggle icon to show/hide password.
    *   **System Action (Button Enablement - Q1 Answer):** Currently, the button is enabled unless `_isLoading` is true. *(Recommendation: Button should be disabled until Email field is non-empty, Password field is non-empty, AND Email format validation passes)*.
    *   **User Action:** Taps "Log In" button. [`flow_step: login.login_tapped`]
        *   **Validation (On Tap):** Code checks if fields are empty or email format is invalid; shows SnackBar and returns if true.
        *   **System Action:** Display Loading State.
        *   **Design/UX Notes (Loading - Q2 Answer):** Button shows a `CircularProgressIndicator` (spinner) when loading. Button is disabled. *(Note: Conflicts with "no spinners" guideline. Recommend changing to button text change, e.g., "Signing In...", +/- subtle pulse)*.
        *   **Design/UX Notes:** [Mobile] Trigger medium haptic feedback (`HapticFeedback.mediumImpact()`).
        *   **API Call:** `signInWithEmailPassword(email, password)` (Handled via `ref.read(authControllerProvider.notifier).signInWithEmailPassword`)

2.  **Branch:** API Response Handling
    *   **IF (Success - User Authenticated):** Proceed to Step 3.
    *   **IF (Failure):** Proceed to Step 4.

3.  **Navigation (Success Path):**
    *   **System Action (Profile Fetch - Q3 Answer):** Hide Loading State. Code checks `UserPreferencesService.hasCompletedOnboarding()`. Profile data is assumed to be updated/fetched automatically by state listeners reacting to the auth change. Navigate user to Home screen (`/home`) or Onboarding (`/onboarding`) based on completion status.
    *   **Analytics:** [`flow_complete: login.email`]
    *   **(End of Flow - User is logged in and on Home/Onboarding screen)**

4.  **State:** Error Handling on Login Screen (Failure Path)
    *   **System Action:** Hide Loading State. Re-enable "Log In" button.
    *   **Analytics:** [`flow_error: login.email` (include error code/type)]
    *   **Handle Specific Errors:** See Section 5 below.
    *   **Design/UX Notes:** Display error via SnackBar. [Mobile] Trigger error haptic feedback (`HapticFeedback.vibrate()`).

---

## 4. State Diagrams

*   **Login Screen (Initial):** Fields empty, Log In button enabled (but validation occurs on tap).
*   **Login Screen (Inputting):** Fields being filled, real-time email validation.
*   **Login Screen (Loading):** Log In button tapped, `CircularProgressIndicator` shown in button, button disabled.
*   **Login Screen (Error):** SnackBar message displayed, Log In button re-enabled.
*   **Success State:** Navigation to `/home` or `/onboarding`.

---

## 5. Error States & Recovery

*   **Trigger:** Invalid email format detected on submit.
    *   **State:** SnackBar error: "Please enter a valid email address".
    *   **Recovery:** User corrects email input and retries.
*   **Trigger:** API returns `FirebaseAuthException` codes `user-not-found`, `wrong-password`, `invalid-credential`.
    *   **State (Q4 Answer):** Display specific error via SnackBar: "No account found with this email" or "Incorrect password" or "Invalid login credentials".
    *   **Recovery:** User corrects credentials and retries. User can tap "Forgot Password?" link.
*   **Trigger:** API returns `FirebaseAuthException` code `user-disabled`.
    *   **State:** Display error via SnackBar: "This account has been disabled."
    *   **Recovery:** User needs to contact support.
*   **Trigger:** API returns `FirebaseAuthException` code `too-many-requests`.
    *   **State:** Display error via SnackBar: "Too many attempts. Please try again later".
    *   **Recovery:** User waits and retries later.
*   **Trigger:** API returns `FirebaseAuthException` code `network-request-failed` or other server/network error.
    *   **State:** Display error via SnackBar: "Network error. Please check your connection and try again." or generic "Authentication failed".
    *   **Recovery:** User checks connection and retries.

---

## 6. Acceptance Criteria

*   **Pre-conditions:** User is logged out, on the Login screen.
*   **Success Post-conditions:**
    *   User is successfully authenticated via Firebase.
    *   User session is established.
    *   User is navigated to the correct screen (`/home` or `/onboarding`) based on onboarding status.
    *   `flow_complete: login.email` event logged.
*   **Failure Post-conditions (e.g., Invalid Password):**
    *   User remains on the Login screen.
    *   Appropriate error message displayed via SnackBar.
    *   User session is not established.
    *   `flow_error: login.email` event logged.
*   **General:**
    *   Email field validates format correctly (real-time).
    *   Password field uses secure text entry with visibility toggle.
    *   "Log In" button triggers validation and API call.
    *   Loading and error states handled gracefully (Loading indicator in button, specific errors via SnackBar).
    *   "Forgot Password?" link is functional.
    *   "Sign Up" link is functional.

---

## 7. Metrics & Analytics

*   **Login Success Rate:** (# Reaching Home/Onboarding Screen after email login) / (# Tapping "Log In" button)
*   **Time-to-Login:** Median time from tapping "Log In" to `flow_complete` or final `flow_error`.
*   **Error Rate:** Frequency of specific `FirebaseAuthException` codes.
*   **Analytics Events:**
    *   `flow_start: login.email` *(Can trigger on screen view or first interaction)*
    *   `flow_step: login.email_entered`
    *   `flow_step: login.password_entered`
    *   `flow_step: login.login_tapped`
    *   `flow_complete: login.email`
    *   `flow_error: login.email` (Properties: error_code, error_message)

---

## 8. Design/UX Notes

*   Adhere to component styles (Buttons, Inputs) from `hive_stylistic_system.md`.
*   Use secure text entry for password field with visibility toggle.
*   Implement loading state on button using `CircularProgressIndicator`. *(Action Item: Consider changing to align with "no spinners" guideline)*.
*   Error feedback via SnackBar using specific messages.
*   [Mobile] Apply haptics: Medium impact on successful login, Error pattern (`vibrate`) on failure.
*   Ensure accessibility (labels, focus indicators, contrast).
*   Ensure "Forgot Password?" and "Sign Up" links are clear and functional.
*   *(Action Item: Recommend disabling Log In button until fields are non-empty and email format is valid)*.

---

## 9. API Calls & Data

*   **Service Call:** `ref.read(authControllerProvider.notifier).signInWithEmailPassword(email, password)`
*   **Success Response:** User authenticated via Firebase.
*   **Error Responses:** Handled via `FirebaseAuthException`.
*   **Data Handling:** Requires network connection. Reads `UserPreferencesService.hasCompletedOnboarding()`.

---

## 10. Open Questions

*   **(Resolved)** Q1: Button currently enabled unless loading. Recommend disabling until valid input.
*   **(Resolved)** Q2: Loading uses `CircularProgressIndicator` (violates guideline).
*   **(Resolved)** Q3: Profile data assumed fetched by state listeners, not explicitly post-login.
*   **(Resolved)** Q4: Specific error messages *are* used for different failure types.

*   **(Action Item):** Implement recommendation to disable button until input is valid.
*   **(Action Item):** Consider changing loading indicator to align with brand guidelines. 