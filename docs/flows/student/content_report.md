# Flow: Student - Report Content or User

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:**
*   [Flow: Admin - View Reports & Appeals](../admin/view_reports_appeals.md) (Where reports are handled)
*   [Hive UI Product Context & Documentation Principles](../../product_context.md)
*   (Link to Community Guidelines/Reporting Policy)

**Figma Link (Overall Flow):** [Link to Figma Frame for Report Modal/Form]

---

## 1. Title & Goal

*   **Title:** Student Report Content or User
*   **Goal:** Allow a user to report a piece of content (post, comment, event, potentially user profile) that they believe violates community guidelines or terms of service.

---

## 2. Persona & Prerequisites

*   **Persona:** Student (Logged-in User)
*   **Prerequisites:**
    *   User is viewing a piece of content.
    *   ❓ **Q1:** What specific items can be reported in V1? (Posts, Comments, Events, Spaces, User Profiles?)

---

## 3. Sequence of Actions

*   **Trigger:** User encounters content (Post, Comment, Event, Space) or a User Profile they believe violates HIVE's community guidelines or terms of service.
    *   ❓ **Q1:** What specific items can be reported in V1? (Posts, Comments, Events, Spaces, User Profiles?)
    *   ✅ **A1 (V1):** All listed items: **Posts, Comments, Events, Spaces, and User Profiles** can be reported.
*   **User Action:** User initiates the reporting process for the specific item.
    *   ❓ **Q2:** How is reporting initiated? (e.g., An option in a three-dot menu? A dedicated 'Report' flag icon?)
    *   ✅ **A2 (V1):** Reporting is initiated via an option within the **three-dot (...) menu** associated with the content or profile.
*   **UI State (Report Modal/Sheet):** A modal bottom sheet or dedicated screen appears, prompting the user to select a reason for the report.
    *   ❓ **Q3:** What are the predefined report reasons available in V1? (e.g., Spam, Harassment, Hate Speech, Nudity, Misinformation, Impersonation, Other)
    *   ✅ **A3 (V1):** Predefined reasons include: **Spam/Scam, Harassment/Bullying, Hate Speech, Inappropriate Content (Nudity/Violence), Misinformation, Impersonation, Other**. This list can be refined.
*   **User Action:** User selects a reason from the list.
*   **UI State (Conditional - Details):**
    *   ❓ **Q4:** Is there an option to provide additional details? Is it always shown, or only for specific reasons (like 'Other')?
    *   ✅ **A4 (V1):** An optional text field to provide additional details is available, but **only required/prompted if the user selects 'Other'**. For other predefined reasons, it's optional or potentially hidden to streamline the process.
*   **User Action:** User confirms and submits the report.
*   **System Action:** The report is logged in the backend system, associated with the reported item/user and the reporter (anonymously from the reported user's perspective).
*   **UI Feedback (Success):**
    *   ❓ **Q5:** What feedback does the user receive upon successful submission? (e.g., Snackbar/Toast "Report submitted"? A confirmation screen?)
    *   ✅ **A5 (V1):** A confirmation **Snackbar/Toast** is displayed (e.g., "Report submitted successfully. Thank you.").
*   **System Action (Optional - Content Hiding):**
    *   ❓ **Q6:** Does reporting automatically hide the content from the reporter's view? Is this configurable?
    *   ✅ **A6 (V1):** Yes, upon successful report submission, the reported content (Post, Comment, Event) is **automatically hidden from the reporter's view locally**. This is not configurable by the user in V1. Reported Spaces/Profiles are not hidden, but the report is logged.
*   **System Action (Duplicate Handling):**
    *   ❓ **Q7:** What happens if a user tries to report the same item multiple times?
    *   ✅ **A7 (V1):** The system prevents duplicate reports from the same user for the same item. If attempted, a **Snackbar/Toast** will indicate that they have already reported it (e.g., "You've already reported this content.").

*   **Analytics:** [`flow_step: student.report.initiated {content_type, content_id}`], [`flow_step: student.report.reason_selected {reason}`], [`flow_step: student.report.submitted {with_details}`], [`flow_error: student.report.submit_failed {reason}`]

---

## 4. State Diagrams

*   (Diagram: Viewing Content -> Taps Report Action -> Selects Reason -> [Enters Details] -> Submits -> Success/Error Feedback)

---

## 5. Error States & Recovery

*   **Trigger:** API error during report submission.
    *   **State:** Error message displayed (e.g., Snackbar: "Failed to submit report").
    *   **Recovery:** User can retry submitting the report.
*   **Trigger:** Trying to report already reported content (by the same user).
    *   **State:** System might prevent re-reporting or simply update the existing report, potentially showing a message like "You've already reported this".
    *   ❓ **Q7:** How are duplicate reports from the same user handled?

---

## 6. Acceptance Criteria

*   Users can initiate the report action (Q2) on eligible content types (Q1).
*   A clear list of reporting reasons is presented (Q3).
*   Users can provide additional details if applicable (Q4).
*   Successful submission provides clear feedback (Q5).
*   Reported content is potentially hidden from the reporter's view (Q6).
*   Duplicate reports are handled gracefully (Q7).
*   Errors during submission are handled with recovery options.

---

## 7. Metrics & Analytics

*   **Report Rate:** (# Reports Submitted) / (# Content Views).
*   **Report Reason Distribution:** Breakdown of reports by selected reason.
*   **Reports with Details:** % of reports that include additional text details.
*   **Report Submission Success Rate:** % of initiated reports successfully submitted.
*   **Analytics Events:** (Listed in Sequence section)

---

## 8. Design/UX Notes

*   Make the report action accessible but not easily triggered accidentally.
*   Reporting reasons should be clear, concise, and cover expected violation types.
*   Balance the need for details (Q4) with the friction it adds.
*   Provide reassurance that the report has been received (Q5).
*   Consider the user experience after reporting (hiding content, Q6).

---

## 9. API Calls & Data

*   **Submit Report API Call:**
    *   **Request:** Reporter User ID, Target Content ID, Target Content Type, Report Reason Category, [Optional: Details Text].
    *   **Response:** Success/Failure.

---

## 10. Open Questions

1.  ~~**Reportable Items (V1):** What can be reported?~~
    *   ✅ **A1 (V1):** Posts, Comments, Events, Spaces, User Profiles.
2.  ~~**Initiation Point:** How does a user start the report process?~~
    *   ✅ **A2 (V1):** Three-dot (...) menu option.
3.  ~~**Report Reasons (V1):** What are the predefined categories?~~
    *   ✅ **A3 (V1):** Spam/Scam, Harassment/Bullying, Hate Speech, Inappropriate Content, Misinformation, Impersonation, Other.
4.  ~~**Additional Details:** Is a free-text field available? Always or conditional?~~
    *   ✅ **A4 (V1):** Optional text field, prompted only for 'Other'.
5.  ~~**Success Feedback:** How is successful submission confirmed?~~
    *   ✅ **A5 (V1):** Snackbar/Toast confirmation.
6.  ~~**Content Hiding:** Is reported content hidden from the reporter? Configurable?~~
    *   ✅ **A6 (V1):** Yes, content (Post, Comment, Event) is hidden locally for the reporter automatically. Not configurable in V1.
7.  ~~**Duplicate Reports:** How are multiple reports from the same user handled?~~
    *   ✅ **A7 (V1):** Prevented, with a Snackbar/Toast notification.

**All questions resolved for V1.** 