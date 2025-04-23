# Flow: Student - Email Verification

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:** [Hive UI Product Context & Documentation Principles](../../product_context.md)
**Figma Link (Overall Flow):** [Link to Figma Frame for Email Verification related UI - e.g., success message]

---

## 1. Title & Goal

*   **Title:** Student Email Verification
*   **Goal:** Allow a student user with a non-auto-verified email address (e.g., standard `.edu`) to verify their email via a link sent after signup, enabling potential features or tier changes associated with verification.

---

## 2. Persona & Prerequisites

*   **Persona:** Student (New User with eligible email type, e.g., `.edu`)
*   **Prerequisites:**
    *   User has completed the "Sign Up with Email/Password" flow.
    *   A verification email was sent during the signup process (as seen in `create_account.dart` logic for `.edu` emails).
    *   User can access the email account provided during signup.
    *   User has potentially completed the "Onboarding Profile Completion" flow (verification can happen concurrently or afterwards).

---

## 3. Sequence

1.  **Trigger:** User receives the verification email sent by Firebase Auth.
    *   **Email Content:** Contains a verification link (Firebase Action Link).

2.  **User Action (Out of App):** User opens their email client and clicks the verification link.

3.  **System Action (Firebase & Deep Link):**
    *   Firebase handles the action link, marks the user's email as verified in their backend (`FirebaseAuth.currentUser.emailVerified` becomes `true`).
    *   The link acts as a deep link, configured to open the Hive app.

4.  **App Launch / Deep Link Handling:**
    *   The Hive app is launched or brought to the foreground by the deep link.
    *   **Deep Link Service (`lib/core/navigation/deep_link_service.dart`):** The `initialize` method detects the incoming link.
    *   **Auth Check (`lib/core/navigation/router_config.dart` - `deepLinkAuthListenerProvider`):** The app likely ensures the user is authenticated before fully processing the link's intent (though verification itself might happen before this).
    *   **System Action:** The app needs to recognize the user's verification status has changed.
        *   **Mechanism:** This likely happens automatically via the `FirebaseAuth.instance.authStateChanges()` stream, which emits a new `User` object with `emailVerified = true`. The `authStateProvider` (`lib/core/providers/auth_provider.dart`) updates.
        *   *(Alternative/Robustness):* The `DeepLinkService` or a listener could explicitly call `FirebaseAuth.instance.currentUser?.reload()` to ensure the latest user state is fetched immediately after returning from the link.

5.  **State Update & Confirmation:**
    *   **System Action:** App recognizes the updated `emailVerified` status (via provider watching `authStateProvider` reacting to the updated User object from Firebase).
    *   **(Optional) Account Tier Update (Q1 Answer):** Assumed to happen in background service/provider layer reacting to `emailVerified = true`. UI does not trigger this directly, but will reflect the updated tier once the user profile data refreshes.
    *   **UI Feedback (Q2 Answer):** Display a short-duration `SnackBar` (Toast) with success styling. Message: "Email verified successfully".
    *   **Landing Location (Q2 Answer):** User remains on their current screen or lands on Home (`/home`) if app was relaunched.
    *   **Analytics:** [`flow_complete: email_verification.success`]

6.  **Branch:** Deep Link Handling Failure
    *   **Trigger:** Invalid link, expired link (handled by Firebase externally), or network error during app launch/state reload.
    *   **State (Q3 Answer):** For in-app errors (e.g., network), display error via `SnackBar` with error styling. Message: "Failed to confirm verification. Please restart the app."
    *   **Analytics:** [`flow_error: email_verification.failure` (Properties: error_code, error_message)]
    *   **Recovery (Q4 Answer):** No in-app resend option for V1. User may need to contact support if link issues persist.

---

## 4. State Diagrams

*   **Initial State (In App):** User is likely using the app normally, potentially with an unverified status (which might limit some features or display a prompt - TBD Q4).
*   **Out of App:** User interacts with email client.
*   **App Return via Deep Link:** App launches/resumes.
*   **Processing:** App detects link, refreshes auth state, potentially updates profile.
*   **Success State:** Confirmation message shown (Q2). User lands on designated screen (Q2). Verified status reflected in relevant parts of the app.
*   **Failure State:** Error message shown (Q3). User remains in the app, potentially still unverified.

---

## 5. Error States & Recovery

*   **Trigger:** User clicks an invalid or expired Firebase Action Link.
    *   **State:** Firebase likely shows an error webpage. If the app handles it via deep link, display an appropriate error (Q3).
    *   **Recovery:** User may need to request a resend (Q4).
*   **Trigger:** Network error when the app tries to reload user state after link click.
    *   **State:** Error message regarding network connection (Q3).
    *   **Recovery:** Retry action once connection restored, or app might auto-refresh later.
*   **Trigger:** Failure to update AccountTier in Firestore after verification.
    *   **State:** Verification successful in Auth, but tier unchanged. Display generic error `SnackBar` (Q3) if failure is detectable by the app.
    *   **Recovery:** User may need to contact support.

---

## 6. Acceptance Criteria

*   **Pre-conditions:** User has an account with an unverified email, verification email has been sent.
*   **Success Post-conditions:**
    *   `FirebaseAuth.currentUser.emailVerified` is `true`.
    *   User receives confirmation feedback within the app (Q2).
    *   (If applicable) User's `AccountTier` in Firestore is updated based on the verified email.
    *   `flow_complete: email_verification.success` event logged.
*   **Failure Post-conditions (e.g., Invalid Link):**
    *   User's `emailVerified` status remains `false`.
    *   Error message is displayed (Q3).
    *   `flow_error: email_verification.failure` event logged.
*   **General:**
    *   App correctly handles the deep link upon launch/resume.
    *   Auth state is refreshed (likely automatically via `authStateChanges`) to reflect the updated `emailVerified` status.
    *   *(Q4 Answer)* No specific UI element exists for manually checking status or resending verification email in V1.

---

## 7. Metrics & Analytics

*   **Verification Rate:** (# Users with `emailVerified = true`) / (# Users sent verification email)
*   **Time-to-Verify:** Median time from verification email sent to `flow_complete: email_verification.success`.
*   **Error Rate:** Frequency of verification failures (Invalid Link, Network Error, Tier Update Failed).
*   **Analytics Events:**
    *   `flow_start: email_verification.link_clicked` *(Approximate - triggered on app launch via link)*
    *   `flow_step: email_verification.auth_reloaded`
    *   `flow_step: email_verification.tier_updated` *(If applicable)*
    *   `flow_complete: email_verification.success`
    *   `flow_error: email_verification.failure` (Properties: error_code, error_message)

---

## 8. Design/UX Notes

*   Requires handling app launch/resume via deep links (`DeepLinkService`).
*   Success/Error feedback uses `SnackBar` (Toast).
*   Verification status should be passively reflected in relevant UI (e.g., Profile Settings) once state updates.
*   Ensure smooth transition back into the app from the email client.

---

## 9. API Calls & Data

*   **Firebase Auth:** Implicit interaction via Firebase Action Link handling. Potential explicit call to `FirebaseAuth.instance.currentUser?.reload()`.
*   **Firestore:** Potential `update` call to the user's document in the `users` collection to modify `accountTier`.
*   **Data Sources:** `FirebaseAuth.currentUser.emailVerified`.

---

## 10. Open Questions

*   **(Resolved)** Q1: Tier update logic is handled by background services reacting to auth state.
*   **(Resolved)** Q2: Success confirmation via short `SnackBar` toast; user lands on current/home screen.
*   **(Resolved)** Q3: In-app errors use `SnackBar`; external link errors handled by Firebase.
*   **(Resolved)** Q4: No in-app status check or resend UI for V1.

*   **(Action Item):** Ensure relevant providers/listeners correctly react to `emailVerified=true` to update profile data (including Tier) if necessary.
*   **(Action Item):** Implement success and error SnackBars for verification feedback.
*   **(Action Item):** Design passive UI indicators for verified status (e.g., Profile Settings badge). 