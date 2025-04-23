# Flow: Student - Share Content Externally (Copy Link)

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:**
*   [Hive UI Product Context & Documentation Principles](../../product_context.md)

**Figma Link (Overall Flow):** [Link to Figma Frame for Share Action/UI]

---

## 1. Title & Goal

*   **Title:** Student Share Content Externally (Copy Link)
*   **Goal:** Allow a user to easily copy a direct link to a specific piece of shareable content within HIVE, enabling them to share it outside the app (e.g., via text message, email, other social media).

---

## 2. Persona & Prerequisites

*   **Persona:** Student (Logged-in User)
*   **Prerequisites:**
    *   User is viewing a piece of content that is eligible for external sharing via a link.
    *   ❓ **Q1:** What types of content can be shared externally in V1? (e.g., Public Posts? Public Events? Specific Spaces? User Profiles?)
    *   ✅ **A1 (V1):** Users can share **Public Posts**, **Public Events**, and **Public Spaces**. User profiles are not directly shareable via a dedicated share button in V1, though their content might be.
    *   ❓ **Q2:** What happens if the content is *not* public (e.g., a members-only event, an unlisted post)? Is the share option hidden, disabled, or does it lead to an access-denied page for the recipient?
    *   ✅ **A2 (V1):** The share option is still **visible**. The generated link will lead to a landing page. If the recipient **does not have access** (not logged in, not a member, etc.), they will see a generic preview (if possible) and a prompt to **log in or sign up** (or potentially request access, depending on the content type - TBD, assume login/signup for V1). If they **do have access**, the link resolves correctly within the app.

---

## 3. Sequence

*   **Trigger:** User finds a piece of content they wish to share outside of the HIVE app.
    *   ❓ **Q1:** What types of content can be shared externally in V1? (e.g., Public Posts? Public Events? Specific Spaces? User Profiles?)
    *   ✅ **A1 (V1):** Users can share **Public Posts**, **Public Events**, and **Public Spaces**. User profiles are not directly shareable via a dedicated share button in V1, though their content might be.
    *   ❓ **Q2:** What happens if the content is *not* public (e.g., a members-only event, an unlisted post)? Is the share option hidden, disabled, or does it lead to an access-denied page for the recipient?
    *   ✅ **A2 (V1):** The share option is still **visible**. The generated link will lead to a landing page. If the recipient **does not have access** (not logged in, not a member, etc.), they will see a generic preview (if possible) and a prompt to **log in or sign up** (or potentially request access, depending on the content type - TBD, assume login/signup for V1). If they **do have access**, the link resolves correctly within the app.
*   **User Action:** User activates the share action for the content.
    *   ❓ **Q3:** How does the user initiate the share action? (e.g., A dedicated share icon [↗️]? An option within a three-dot menu?)
    *   ✅ **A3 (V1):** The primary method is via an option within the **three-dot (...) menu** associated with the content. A dedicated share icon might be considered for specific cards later, but the menu is the consistent entry point for V1.
*   **System Action:** The application prepares the shareable link and invokes the native OS sharing mechanism.
    *   ❓ **Q4:** Does HIVE use the native OS share sheet, or a custom sharing interface?
    *   ✅ **A4 (V1):** HIVE uses the **native OS share sheet** (iOS Share Sheet, Android Sharesheet) for maximum compatibility and user familiarity.
*   **UI State (OS Share Sheet):** The native share sheet appears, pre-populated with the shareable link and potentially some default text (e.g., "Check out this event on HIVE: [link]").
*   **User Action:** User selects a target app or action from the OS share sheet (e.g., Messages, Copy Link, AirDrop).
*   **System Action:** The OS handles the sharing process to the selected target.
*   **UI Feedback (Optional):**
    *   ❓ **Q5:** Does the HIVE app provide any feedback after the share sheet is dismissed? (e.g., A subtle toast "Link Copied" if that action was chosen?)
    *   ✅ **A5 (V1):** Yes, a simple **Snackbar/Toast** confirms the action, like "Link copied" if the copy action was used, or potentially a generic "Shared" confirmation for other actions.

*   **Analytics:** [`flow_step: student.share.initiated {content_type, content_id}`], [`flow_step: student.share.copy_link {content_type, content_id}`], [`flow_error: student.share.generate_link_failed {reason}`]

---

## 4. State Diagrams

*   (Simple Diagram: Viewing Content -> Taps Share -> Selects Copy Link -> Link Copied Feedback)

---

## 5. Error States & Recovery

*   **Trigger:** Error generating the shareable link.
    *   **State:** Error message (Snackbar/Toast: "Could not generate share link").
    *   **Recovery:** User can try the share action again.
*   **Trigger:** Content is not shareable (e.g., private content, Q1).
    *   **State:** The Share action might be disabled/hidden, or tapping it shows a message "This content cannot be shared".
    *   **Recovery:** N/A.

---

## 6. Acceptance Criteria

*   Share action (Q3) is available for eligible content types (Q1).
*   User can successfully trigger the share flow.
*   The flow provides a clear way to copy the direct link (Q4).
*   Successful copy action provides user feedback (Q5).
*   Generated links correctly deep-link to the content within HIVE.
*   Access control for shared links (Q2) functions as defined.
*   Errors during link generation or for non-shareable content are handled gracefully.

---

## 7. Metrics & Analytics

*   **Share Action Rate:** (# Share Actions Initiated) / (# Content Views).
*   **Copy Link Rate:** (# Links Copied) / (# Share Actions Initiated).
*   **Shared Content Types:** Breakdown of copied links by content type.
*   **Link Generation Failure Rate:** % of attempts that fail to generate a link.
*   **Analytics Events:** (Listed in Sequence section)

---

## 8. Design/UX Notes

*   Make the share action easily accessible for shareable content.
*   Ensure the copied link is robust and correctly handles deep-linking.
*   Consider the experience for recipients of the link (Q2) - requires careful thought about public previews vs. login walls.
*   Using the native OS share sheet (Q4) is often the most familiar pattern for users.

---

## 9. API Calls & Data

*   **Generate Share Link API Call (Potentially):** May not require a dedicated API call if links follow a predictable pattern, but could be used for short links or tracking.
    *   **Request:** Content ID, Content Type.
    *   **Response:** Shareable URL.

---

## 10. Open Questions

1.  **Shareable Content (V1):** What content types can be shared via link?
    *   ✅ **A1 (V1):** Public Posts, Public Events, Public Spaces.
2.  **Link Recipient Experience:** What happens when someone without access clicks a link?
    *   ✅ **A2 (V1):** Share option visible. Link leads to preview/login/signup prompt if no access, resolves correctly if access exists.
3.  **Share Action Location:** Where is the Share action located?
    *   ✅ **A3 (V1):** Three-dot (...) menu option primarily.
4.  **Share Options UI:** What happens when Share is tapped (Direct copy? OS Share Sheet?)?
    *   ✅ **A4 (V1):** Native OS share sheet.
5.  **Copy Feedback:** How is successful link copying confirmed?
    *   ✅ **A5 (V1):** Yes, Snackbar/Toast confirmation (e.g., "Link copied").

**All questions resolved for V1.** 