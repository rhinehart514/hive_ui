# Flow: Student - Onboarding Profile Completion

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:** [Hive UI Product Context & Documentation Principles](../../product_context.md)
**Figma Link (Overall Flow):** [Link to Figma Frame for Onboarding Profile Flow]

---

## 1. Title & Goal

*   **Title:** Student Onboarding Profile Completion
*   **Goal:** Guide a new student user through a multi-step process to collect essential profile information (Name, Year, Major, Residence, Interests, Account Tier) after initial account creation, saving the profile and marking onboarding as complete.

---

## 2. Persona & Prerequisites

*   **Persona:** Student (New User)
*   **Prerequisites:**
    *   User has successfully completed the initial sign-up (Email/Password, Google, or Apple).
    *   User is authenticated (`FirebaseAuth.instance.currentUser` is not null).
    *   User has been navigated to the `/onboarding` route, which loads `OnboardingProfilePage`.
    *   `UserPreferencesService` has the user's email stored (from signup).
    *   Network connection is available.

---

## 3. Sequence

*(This flow utilizes a `PageView` (`lib/pages/onboarding_profile.dart`) to present sequential steps)*

1.  **Screen:** Onboarding Wrapper (Loads `OnboardingProfilePage`)
    *   **UI Elements:** AppBar (potentially with progress indicator), PageView container, Navigation buttons ("Back" / "Next" or similar).
    *   **Initial State:** Loads Page 0 (Name Page).
    *   **Analytics:** [`flow_start: onboarding.profile`]

2.  **Page 0:** Name Page (`lib/features/auth/presentation/components/onboarding/name_page.dart` - Assumed)
    *   **UI Elements:** "First Name" input, "Last Name" input, "Next" button (or equivalent).
    *   **User Action:** Enters First Name, Last Name. [`flow_step: onboarding.name_entered`]
    *   **Validation:** **(Q1 Answer):** Basic validation - First Name and Last Name must be non-empty. Avoid complex length or character restrictions.
    *   **User Action:** Taps "Next". [`flow_step: onboarding.name_submitted`]
    *   **System Action:** Validate inputs. If valid, navigate PageView to Page 1.

3.  **Page 1:** Year Page (`lib/features/auth/presentation/components/onboarding/year_page.dart` - Assumed)
    *   **UI Elements:** List/Selection widget for Academic Year (e.g., Freshman, Sophomore...), "Next" button.
    *   **User Action:** Selects Academic Year. [`flow_step: onboarding.year_selected`]
    *   **User Action:** Taps "Next". [`flow_step: onboarding.year_submitted`]
    *   **System Action:** Store selected year. Navigate PageView to Page 2.

4.  **Page 2:** Field (Major) Page (`lib/features/auth/presentation/components/onboarding/field_page.dart` - Assumed)
    *   **UI Elements:** Searchable list/selection for Major/Field of Study, "Next" button.
    *   **User Action:** Selects Major. [`flow_step: onboarding.major_selected`]
    *   **User Action:** Taps "Next". [`flow_step: onboarding.major_submitted`]
    *   **System Action:** Store selected major. Navigate PageView to Page 3.

5.  **Page 3:** Residence Page (`lib/features/auth/presentation/components/onboarding/residence_page.dart` - Assumed)
    *   **UI Elements:** List/Selection widget for Residence Status (e.g., On Campus, Off Campus...), "Next" button.
    *   **User Action:** Selects Residence. [`flow_step: onboarding.residence_selected`]
    *   **User Action:** Taps "Next". [`flow_step: onboarding.residence_submitted`]
    *   **System Action:** Store selected residence. Navigate PageView to Page 4.

6.  **Page 4:** Interests Page (`lib/features/auth/presentation/components/onboarding/interests_page.dart` - Assumed)
    *   **UI Elements:** Categorized/Searchable list of interests for selection, "Next" button.
    *   **User Action:** Selects multiple interests (min 5, max 10 enforced by code). [`flow_step: onboarding.interest_selected` (potentially logged per selection or on submit)]
    *   **Validation:** Ensure minimum number of interests selected before enabling "Next".
    *   **User Action:** Taps "Next". [`flow_step: onboarding.interests_submitted`]
    *   **System Action:** Store selected interests. Navigate PageView to Page 5.

7.  **Page 5:** Account Tier Page (`lib/features/auth/presentation/components/onboarding/account_tier_page.dart` - Assumed)
    *   **UI Elements:** Information displaying the determined Account Tier (Public, Verified, Verified+) based on user's email domain (`.edu`, `buffalo.edu`). Potentially options for verification if applicable. "Complete Profile" / "Finish" button.
    *   **System Action:** Tier is likely pre-determined based on email from `UserPreferencesService`. May offer verification steps if applicable (e.g., prompt to check `.edu` email if not yet verified).
    *   **User Action:** Taps "Complete Profile" / "Finish" button. [`flow_step: onboarding.tier_confirmed`]

8.  **System Action:** Final Submission (`_completeOnboarding` function)
    *   **State:** Display loading state. **(Q2 Answer):** Disable the final button. Change button text to "Saving..." or similar. Optionally add a subtle, non-looping pulse/shimmer animation to the button itself. Avoid spinners or overlays.
    *   **Validation:** Final check on all collected data (e.g., ensure required fields are non-null).
    *   **API Call:** Save `UserProfile` data (ID, derived username, display name, year, major, residence, tier, interests) to Firestore collection `users`. *(Note: Does NOT include Bio or Avatar URL)*.
    *   **Local Save:** Store `UserProfile` locally via `UserPreferencesService`.
    *   **Local Save:** Mark onboarding as complete via `UserPreferencesService.setOnboardingCompleted(true)`.

9.  **Branch:** Final Submission Result
    *   **IF (Success):** Proceed to Step 10.
    *   **IF (Failure):** Proceed to Step 11.

10. **Navigation (Success Path):**
    *   **System Action:** Hide loading state. **(Q3 Answer Correction):** Navigate user to the Onboarding Tutorial flow (e.g., route `/onboarding-tutorial`). *NOT* directly to `/home`.
    *   **Analytics:** [`flow_complete: onboarding.profile`]
    *   **(End of this flow - transitions to Onboarding Tutorial flow)**

11. **State:** Error Handling During Final Submission (Failure Path)
    *   **System Action:** Hide loading state. Display error message via SnackBar (e.g., "Error saving profile to server...", "Error completing onboarding...").
    *   **Analytics:** [`flow_error: onboarding.profile` (include error details)]
    *   **Recovery:** User might need to retry tapping "Complete Profile" / "Finish".

---

## 4. State Diagrams

*   **Onboarding Wrapper:** Contains `PageView`.
*   **Page States (Each Page 0-5):** Initial state, Input state (filling fields/making selections), Validation state (if applicable per page), Completed state (navigates to next page).
*   **Account Tier Page (Page 5):** Displays determined tier. Shows "Complete Profile" button.
*   **Loading State (Final Submit):** Triggered by "Complete Profile" tap. UI TBD (Q2).
*   **Error State (Final Submit):** SnackBar shown on Account Tier Page.
*   **Success State:** Navigation to `/home`.

---

## 5. Error States & Recovery

*   **Trigger:** Validation error on an individual page (e.g., Name invalid (Q1), < 5 interests selected).
    *   **State:** Inline error message or disabled "Next" button.
    *   **Recovery:** User corrects input / makes required selections.
*   **Trigger:** Failure during final submission (`_completeOnboarding`) - e.g., Firestore write error, network error.
    *   **State:** Loading state hides, SnackBar with error message appears on the Account Tier page.
    *   **Recovery:** User can retry tapping the "Complete Profile" button.
*   **Trigger:** User is not authenticated when `_completeOnboarding` is called.
    *   **State:** SnackBar with "No authenticated user found".
    *   **Recovery:** This indicates an earlier auth issue; user likely needs to restart the app/login process.

---

## 6. Acceptance Criteria

*   **Pre-conditions:** User is authenticated, new, and on the `/onboarding` route.
*   **Success Post-conditions:**
    *   `UserProfile` document created/updated in Firestore `users` collection with data from all steps.
    *   `UserProfile` saved locally via `UserPreferencesService`.
    *   Onboarding marked as complete locally via `UserPreferencesService`.
    *   User is navigated to the Home screen (`/home`).
    *   `flow_complete: onboarding.profile` event logged.
*   **Failure Post-conditions (e.g., Final Save Fails):**
    *   User remains on the last step (Account Tier Page).
    *   Error message displayed via SnackBar.
    *   `flow_error: onboarding.profile` event logged.
*   **General:**
    *   User progresses sequentially through all defined onboarding pages.
    *   Input validation is enforced where applicable (Name must be non-empty, Interests count min/max).
    *   Data selected/entered on each page persists until final submission.
    *   Account Tier is determined correctly based on email domain.
    *   Loading and error states during final submission are handled gracefully.
    *   **(Missing Fields - Q4 Answer):** Lack of unique Username, Bio, and Avatar collection is **intentional** for faster onboarding. These should be prompted/editable later via Profile Settings or other engagement triggers.

---

## 7. Metrics & Analytics

*   **Completion Rate:** (# Reaching Home Screen after starting onboarding) / (# Starting onboarding profile flow)
*   **Time-to-complete:** Median time from `flow_start: onboarding.profile` to `flow_complete` or final `flow_error`.
*   **Drop-off Rate per Step:** Track `flow_step` completions vs. starts for each page (Name, Year, Major, etc.) to identify friction points.
*   **Error Rate (Final Submit):** Frequency of errors during `_completeOnboarding`.
*   **Analytics Events:**
    *   `flow_start: onboarding.profile`
    *   `flow_step: onboarding.name_entered`
    *   `flow_step: onboarding.name_submitted`
    *   `flow_step: onboarding.year_selected`
    *   `flow_step: onboarding.year_submitted`
    *   `flow_step: onboarding.major_selected`
    *   `flow_step: onboarding.major_submitted`
    *   `flow_step: onboarding.residence_selected`
    *   `flow_step: onboarding.residence_submitted`
    *   `flow_step: onboarding.interest_selected` *(Log count?)*
    *   `flow_step: onboarding.interests_submitted`
    *   `flow_step: onboarding.tier_confirmed`
    *   `flow_step: onboarding.final_submit_tapped`
    *   `flow_complete: onboarding.profile`
    *   `flow_error: onboarding.profile` (Properties: error_message, error_location [e.g., 'final_submit'])

---

## 8. Design/UX Notes

*   Utilizes a `PageView` for step-by-step progression.
*   Requires clear progress indication (e.g., `ProgressIndicator` component noted in imports).
*   Individual page components (`NamePage`, `YearPage`, etc.) handle their specific UI and interactions.
*   Selection widgets (Year, Major, Residence, Interests) need to adhere to `hive_stylistic_system.md`.
*   Final submission loading state needs definition (Q2).
*   Error messages primarily use `SnackBar`.
*   Navigation between pages uses `PageController` animations.
*   Final navigation uses `context.go('/home')`.
*   Haptics should be applied to page transitions and final submission success/error.

---

## 9. API Calls & Data

*   **Primary API Call:** `FirebaseFirestore.instance.collection('users').doc(userId).set(profile.toJson())`
*   **Data Sources:** User inputs (Name, Year, Major, etc.), `FirebaseAuth.currentUser.uid`, `UserPreferencesService` (for email to determine tier).
*   **Data Storage:** Firestore (`users` collection), `UserPreferencesService` (profile, onboarding status, user ID, email).

---

## 10. Open Questions

*   **(Resolved)** Q1: Name validation should be non-empty only.
*   **(Resolved)** Q2: Final loading state is button text change +/- subtle animation, no spinner.
*   **(Resolved)** Q3: This flow navigates to the Tutorial flow next, not `/home`.
*   **(Resolved)** Q4: Missing Username/Bio/Avatar is intentional for initial onboarding.

*   **(Action Item):** Verify `NamePage` component code implements non-empty validation.
*   **(Action Item):** Implement the recommended button loading state visuals.
*   **(Action Item):** Update the navigation logic in `_completeOnboarding` to go to the Tutorial route instead of `/home`.
*   **(Action Item):** Plan for where/when unique Username, Bio, and Avatar *will* be collected post-onboarding. 