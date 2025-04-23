# Flow: Student - Logout

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:** [Hive UI Product Context & Documentation Principles](../../product_context.md)
**Figma Link (Overall Flow):** [Link to Figma Frame for Logout Action/Confirmation]

---

## 1. Title & Goal

*   **Title:** Student Logout
*   **Goal:** Allow an authenticated user to securely sign out of their Hive account, clearing local session data and returning them to the initial authentication screen.

---

## 2. Persona & Prerequisites

*   **Persona:** Student (Existing User, Authenticated)
*   **Prerequisites:**
    *   User is logged into the Hive app.
    *   **Q1 Answer:** User has navigated to the **Settings Screen** where the Logout action is located (likely near the bottom).

---

## 3. Sequence

1.  **Screen:** Settings Screen
    *   **UI Elements:** "Logout" button or menu item.
    *   **User Action:** Taps the "Logout" action.
    *   **Analytics:** [`flow_start: logout`], [`flow_step: logout.initiate_tapped`]

2.  **UI Action:** Display Confirmation Dialog/Modal
    *   **UI Elements:**
        *   Title (e.g., "Log Out?")
        *   Message (e.g., "Are you sure you want to log out?")
        *   "Cancel" button
        *   "Log Out" button (confirm action)
    *   **Design/UX Notes (Q2 Answer):** Use a standard system **AlertDialog**. The "Log Out" confirmation button should use platform-standard destructive action styling (e.g., red text on iOS). "Cancel" is standard style.
    *   **User Action Branch:**
        *   **IF User Taps "Cancel":** Dismiss dialog, return to Settings Screen. [`flow_step: logout.cancel_tapped`]. (End of Flow)
        *   **IF User Taps "Log Out":** Proceed to Step 3. [`flow_step: logout.confirm_tapped`].

3.  **System Action:** Perform Logout
    *   **State (Q3 Answer):** No loading indicator is shown.
    *   **Service Call:** `signOut()` (Likely via `ref.read(authControllerProvider.notifier).signOut()` or `FirebaseAuth.instance.signOut()`)
    *   **Local Data Clearing:** Clear relevant local session data/cache (e.g., `UserPreferencesService` user details, potentially Riverpod provider state reset).
    *   **Design/UX Notes:** [Mobile] Trigger appropriate haptic feedback upon confirmation tap.

4.  **Navigation:**
    *   **System Action:** Once sign out is complete and local data cleared, navigate user back to the initial authentication screen.
    *   **Target Route (Q4 Answer):** Navigate user to the **Landing Screen (`/landing`)**.
    *   **Analytics:** [`flow_complete: logout`]
    *   **(End of Flow - User is logged out)**

---

## 4. State Diagrams

*   **Source Screen:** Logout action available.
*   **Confirmation Dialog:** Displayed modally.
*   **Loading (Optional):** Brief global indicator (Q3).
*   **Final State:** User navigated to the initial authentication screen.

---

## 5. Error States & Recovery

*   **Trigger:** Failure during `signOut()` call (e.g., rare network issue during token invalidation if applicable).
    *   **State:** Hide loading indicator (if shown). Display error `SnackBar`: "Logout failed. Please try again.". User remains logged in.
    *   **Recovery:** User taps "Logout" again.
    *   **Analytics:** [`flow_error: logout.api_failed`]
*   **Trigger:** Failure during local data clearing.
    *   **State:** Logout might technically succeed on backend, but local state is inconsistent. Ideally, display error `SnackBar`: "An error occurred during logout." User might still be navigated out, but could face issues on next login.
    *   **Recovery:** Restarting the app might clear state. Requires investigation if this occurs.
    *   **Analytics:** [`flow_error: logout.clear_data_failed`]

---

## 6. Acceptance Criteria

*   **Pre-conditions:** User is logged in.
*   **Success Post-conditions:**
    *   User's session is terminated on the backend (via Firebase signout).
    *   Relevant local user data and session state are cleared.
    *   User is navigated to the designated initial authentication screen (Q4).
    *   User is effectively logged out.
    *   `flow_complete: logout` event logged.
*   **Failure Post-conditions (e.g., API Fails):**
    *   User remains logged in.
    *   Error message displayed via SnackBar.
    *   `flow_error: logout.api_failed` event logged.
*   **General:**
    *   Confirmation dialog prevents accidental logout.
    *   Navigation upon successful logout is correct.

---

## 7. Metrics & Analytics

*   **Logout Initiations:** Count of `flow_start: logout`.
*   **Logout Completions:** Count of `flow_complete: logout`.
*   **Logout Errors:** Count of `flow_error: logout.api_failed`, `flow_error: logout.clear_data_failed`.
*   **Analytics Events:**
    *   `flow_start: logout`
    *   `flow_step: logout.initiate_tapped`
    *   `flow_step: logout.confirm_tapped`
    *   `flow_step: logout.cancel_tapped`
    *   `flow_complete: logout`
    *   `flow_error: logout.api_failed`
    *   `flow_error: logout.clear_data_failed`

---

## 8. Design/UX Notes

*   Use a standard system AlertDialog for confirmation (Q2).
*   Ensure logout action is placed appropriately within Settings (Q1).
*   No loading indicator needed (Q3).
*   Provide feedback only if logout fails (SnackBar).
*   Navigation reliably returns user to the `/landing` screen (Q4).

---

## 9. API Calls & Data

*   **Service Call:** `signOut()` via Firebase Auth.
*   **Local Data:** Clear data stored in `UserPreferencesService`, potentially reset Riverpod providers related to user state.

---

## 10. Open Questions

*   **(Resolved)** Q1: Entry point is within Settings.
*   **(Resolved)** Q2: Confirmation uses standard AlertDialog with destructive styling for the confirm button.
*   **(Resolved)** Q3: No loading indicator needed.
*   **(Resolved)** Q4: Target route after logout is `/landing`.

*   **(Action Item):** Ensure Logout button exists in Settings UI.
*   **(Action Item):** Implement standard AlertDialog for confirmation.
*   **(Action Item):** Verify navigation redirects correctly to `/landing`. 