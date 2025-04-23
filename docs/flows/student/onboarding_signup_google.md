# Flow: Student - Sign Up with Google

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:** [Hive UI Product Context & Documentation Principles](../../product_context.md)
**Figma Link (Overall Flow):** [Link to Figma Frame for Google Signup Flow]

---

## 1. Title & Goal

*   **Title:** Student Sign Up / Log In with Google
*   **Goal:** Allow a new or returning user to authenticate and access their Hive account using their Google account, leading to either the onboarding profile setup (new user) or the main app interface (returning user).

---

## 2. Persona & Prerequisites

*   **Persona:** Student (New or Returning User)
*   **Prerequisites:**
    *   User has installed the Hive app (iOS, Android, or accessed Web).
    *   User is on the initial Welcome/Landing screen OR the Create Account screen OR the Login screen.
    *   User has a Google account.
    *   User has a network connection.
    *   Google Sign-In is supported on the current platform (Not fully supported on Windows Desktop according to code).

---

## 3. Sequence

1.  **Screen:** Welcome Screen / Create Account Screen / Login Screen
    *   **UI Elements:** "Sign Up with Google" / "Continue with Google" button.
    *   **User Action:** Taps the Google Sign-In button.
    *   **Analytics:** [`flow_start: signup_login.google`], [`flow_step: google_option_selected`]
    *   **Platform Check:** Code checks if Google Sign-In is supported on the platform (Web, Android, iOS). If not (e.g., Windows Desktop), show SnackBar message: "Google Sign-In is not supported... Please use email/password..." and abort flow.

2.  **System Action:** Display Loading State.
    *   **Design/UX Notes:** **Loading Indicator:** The code sets `_isLoading = true` which disables the button. No additional app-level loading indicator is shown before the native Google UI appears. [Mobile] Trigger medium haptic feedback (`HapticFeedback.mediumImpact()`).
    *   **API/Service Call:** Initiate Google Sign-In process (Handled via `ref.read(authControllerProvider.notifier).signInWithGoogle()`). This likely triggers a native Google Sign-In prompt/popup/webview.

3.  **External Interaction:** Native Google Sign-In UI
    *   **User Action:** User selects Google account, enters credentials if necessary, and approves permissions.
    *   **System Action:** Google returns authentication result (success token or error/cancellation) to the app.

4.  **Branch:** Google Sign-In Result Handling (within `signInWithGoogle` and subsequent checks)
    *   **IF (Success - Google Auth Token Received):** Proceed to Step 5.
    *   **IF (Failure - Error/Cancellation):** Proceed to Step 6.

5.  **System Action:** Firebase Authentication & User Detection (Success Path)
    *   **API Call:** Firebase backend authenticates using the Google token.
    *   **System Action:** Hide any app-level loading state. Determine if the authenticated user is new or existing (based on `createdAt` timestamp difference < 30s or missing saved `userId` in `UserPreferencesService`).
    *   **Branch (New vs Existing User):**
        *   **IF (New User):** Reset onboarding status in `UserPreferencesService`, save user ID, save email. Navigate to Onboarding Profile screen (`/onboarding`). Analytics: [`flow_step: google_new_user_detected`], [`flow_complete: signup.google`]
        *   **IF (Existing User):** Save user ID and email if needed. Navigate to Home screen (`/home`). Analytics: [`flow_step: google_existing_user_detected`], [`flow_complete: login.google`]
    *   **Design/UX Notes:** Apply appropriate navigation transition feedback (`NavigationFeedbackType.modalOpen` for new user, `pageTransition` for existing).

6.  **State:** Error Handling (Failure Path)
    *   **System Action:** Hide app-level loading state.
    *   **Analytics:** [`flow_error: signup_login.google` (include error code/type)]
    *   **Handle Specific Errors:** See Section 5 below.
    *   **Design/UX Notes:** Display error via SnackBar.

---

## 4. State Diagrams

*   **Initial Screen:** Button available.
*   **Loading:** Button potentially disabled, Google native UI may overlay the app.
*   **Google Native UI:** External process.
*   **Success (New User):** Navigate to `/onboarding`.
*   **Success (Existing User):** Navigate to `/home`.
*   **Error State:** SnackBar displayed on the initial screen.

---

## 5. Error States & Recovery

*   **Trigger:** User cancels Google Sign-In flow (closes popup/webview).
    *   **State:** Show SnackBar (Warning color): "Google Sign-In was canceled" or "Sign-in window was closed...".
    *   **Recovery:** User can tap the Google button again.
*   **Trigger:** Platform not supported (e.g., Windows Desktop).
    *   **State:** Show SnackBar (Warning color): "Google Sign-In is not supported on this platform...".
    *   **Recovery:** User must use Email/Password method.
*   **Trigger:** Network error during sign-in.
    *   **State:** Show SnackBar (Error color): "Network error during sign-in...".
    *   **Recovery:** User checks connection and retries.
*   **Trigger:** Google account already linked to a different Hive account (`FirebaseAuthException` code `credential_already_in_use` or `account-exists-with-different-credential`).
    *   **State:** Show SnackBar (Error color): "This Google account is already linked..." or "An account already exists with the same email but different sign-in method."
    *   **Recovery:** User needs to use the correct sign-in method or a different Google account.
*   **Trigger:** User's Google account is disabled (`FirebaseAuthException` code `user-disabled`).
    *   **State:** Show SnackBar (Error color): "This account has been disabled.".
    *   **Recovery:** User needs to resolve the issue with their account or use a different one.
*   **Trigger:** Other `FirebaseAuthException` or unexpected errors.
    *   **State:** Show SnackBar (Error color) with generic or specific error message (e.g., `e.message ?? 'Authentication failed'`, "Google sign-in failed").
    *   **Recovery:** User may retry.

---

## 6. Acceptance Criteria

*   **Pre-conditions:** User is on a screen with the Google Sign-In button, not logged in.
*   **Success Post-conditions (New User):**
    *   User account is created/linked via Firebase Authentication using Google credentials.
    *   Onboarding status is reset, User ID and Email are saved locally.
    *   User is navigated to the Onboarding Profile screen (`/onboarding`).
    *   `flow_complete: signup.google` event is logged.
*   **Success Post-conditions (Existing User):**
    *   User is successfully authenticated via Firebase Authentication using Google credentials.
    *   User is navigated to the Home screen (`/home`).
    *   `flow_complete: login.google` event is logged.
*   **Failure Post-conditions (e.g., User Cancelled):**
    *   User remains on the initial screen.
    *   Appropriate error message is displayed via SnackBar.
    *   No authentication state change occurs.
    *   `flow_error: signup_login.google` event is logged.
*   **General:**
    *   Platform support check prevents proceeding on unsupported platforms.
    *   Loading state (button disabled) is handled appropriately.
    *   Error states are communicated clearly via SnackBars.

---

## 7. Metrics & Analytics

*   **Conversion Rate (Signup):** (# Reaching Onboarding via Google) / (# Tapping Google Sign-In Button on Signup/Welcome)
*   **Conversion Rate (Login):** (# Reaching Home via Google) / (# Tapping Google Sign-In Button on Login)
*   **Error Rate:** Frequency of specific errors (User Cancelled, Platform Unsupported, Network, Account Exists, Disabled, Other).
*   **Analytics Events:**
    *   `flow_start: signup_login.google`
    *   `flow_step: google_option_selected`
    *   `flow_step: google_native_ui_shown` *(Implicit - occurs during service call)*
    *   `flow_step: google_auth_success` *(Implicit - occurs during service call)*
    *   `flow_step: google_new_user_detected`
    *   `flow_step: google_existing_user_detected`
    *   `flow_complete: signup.google`
    *   `flow_complete: login.google`
    *   `flow_error: signup_login.google` (Properties: error_code, error_message)

---

## 8. Design/UX Notes

*   Button style should adhere to `hive_stylistic_system.md` (OutlinedButton.icon with Google logo).
*   Error messages displayed via `SnackBar`.
*   [Mobile] Apply medium haptic feedback (`HapticFeedback.mediumImpact()`) when initiating the sign-in process.
*   Navigation transitions (`modalOpen` vs `pageTransition`) depend on new vs existing user status.
*   Handle the transition between the app and the native Google Sign-In UI smoothly.

---

## 9. API Calls & Data

*   **Service Call:** `ref.read(authControllerProvider.notifier).signInWithGoogle()` (Uses Firebase Auth backend with GoogleAuthProvider).
*   **Success Response:** User successfully authenticated in Firebase Auth.
*   **Error Responses:** Handled via exceptions caught, including `FirebaseAuthException` and potentially platform-specific exceptions from the Google Sign-In library.
*   **Data Handling:** Relies on Google's native sign-in flow. User ID and Email saved to `UserPreferencesService` upon success.

---

## 10. Open Questions

*   **(Resolved)** How should the loading state be visually represented *before* the native Google UI appears? Decision: Disabling the button is sufficient.
*   The new user detection logic seems slightly complex (checking creation time < 30s OR missing saved user ID). Is this robust enough, or should there be a more definitive backend flag? *(Recommendation: Investigate backend flag for improved robustness)* 