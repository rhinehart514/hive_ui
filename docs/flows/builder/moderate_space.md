# Flow: Builder - Moderate Space Content & Members

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:**
*   [Hive UI Product Context & Documentation Principles](../../product_context.md)

**Figma Link (Overall Flow):** [Link to Figma Frame for Space Moderation Tools]

---

## 1. Title & Goal

*   **Title:** Builder Moderate Space Content & Members
*   **Goal:** Allow Space Builders (Admins/Moderators) to manage content (posts, comments) and members (approve requests, manage roles, remove/ban users) within their Space.

---

## 2. Persona & Prerequisites

*   **Persona:** Builder (Authenticated User with Admin/Moderator role within a specific Space)
*   **Prerequisites:**
    *   User is logged in and has appropriate permissions for the target Space.
    *   User is viewing the Space (e.g., Space Detail screen, Space Settings).
*   **(Q1 Entry Points):**
    *   **Content Moderation:** Accessed via menu on individual Post/Comment items.
    *   **Member Moderation:** Accessed via the **"Members & Roles"** screen within **Space Settings**.

---

## 3. Sequence (High-Level - Specific actions detailed below)

*   **Trigger:** Builder identifies content or member requiring action.
*   **System Action:** Builder accesses moderation tools/options via specified entry points (Q1).
*   **User Action:** Builder selects a specific moderation action (e.g., Remove Post, Approve Member Request, Ban User).
*   **System Action:** Presents confirmation/options dialog specific to the action.
*   **User Action:** Builder confirms the action, potentially provides reason/duration.
*   **System Action:** Processes request (API call), provides feedback.

--- 

### 3.1 Content Moderation (Posts/Comments)

*   **Trigger:** Builder views a specific Post or Comment within their Space's feed.
*   **Access:** Builder taps the **ellipsis ("...") menu** located in the **top-right corner** of the content item (Q2).
*   **UI Element:** Moderation options appear in the menu/bottom sheet.
    *   **(Q3 V1 Options):** "Remove Content", "Pin Post".
*   **Action: Remove Content**
    *   User taps "Remove Content".
    *   System Action: Show confirmation dialog ("Remove this post/comment?"). Options: Remove, Cancel.
    *   User confirms "Remove".
    *   System Action: API call to remove. UI updates (content disappears or shows "Removed" state).
    *   Feedback: Subtle confirmation (e.g., Snackbar "Content removed").
*   **Action: Pin Post**
    *   User taps "Pin Post".
    *   System Action: API call to pin. UI updates (post moves to top or gets pinned indicator).
    *   Feedback: Subtle confirmation.

### 3.2 Member Moderation

*   **Access:** Builder navigates to **Space Settings** and selects the **"Members & Roles"** screen (Q4).
*   **Screen:** Members & Roles
    *   **UI Elements:** Tabs/Sections for "Members", "Pending Requests" (if private/approval required).
        *   Lists display users with current role/status.
        *   Each item has associated actions accessible via tap or menu.
*   **Action: Approve Join Request** (Private Spaces - Pending Requests tab)
    *   User taps "Approve" next to a pending request.
    *   System Action: API call to approve. UI updates (request removed, user added to Members list).
    *   Feedback: Subtle confirmation.
*   **Action: Deny Join Request** (Private Spaces - Pending Requests tab)
    *   User taps "Deny" next to a pending request.
    *   System Action: Show confirmation dialog ("Deny request from [User]?"). Options: Deny, Cancel.
    *   User confirms "Deny".
    *   System Action: API call to deny. UI updates (request removed).
*   **Action: Manage Member Role** (Members tab)
    *   User taps on a current member in the list.
    *   System Action: Show member options menu/dialog.
    *   User selects "Change Role".
    *   **(Q5 V1 Roles):** Options presented are **Admin** / **Member**.
    *   System Action: Presents role selection options. User confirms new role.
    *   System Action: API call to update role. UI updates (role indicator changes in list).
*   **Action: Remove Member** (Members tab)
    *   User taps on a member -> selects "Remove Member" option.
    *   System Action: Show confirmation dialog ("Remove [User] from the Space?"). Options: Remove, Cancel.
    *   User confirms "Remove".
    *   System Action: API call to remove member. UI updates (user removed from list).
*   **(Action: Ban Member - Deferred to V2+)** (Q6)
*   **Analytics:** [`flow_step: builder.moderate_action_initiated {space_id, action_type}`], [`flow_step: builder.moderate_action_success {space_id, action_type}`], [`flow_error: builder.moderate_action_failed {space_id, action_type, reason}`]

---

## 4. State Diagrams

*   (Diagrams would be specific to each sub-flow: Content Removal, Member Approval, Role Change, Ban, etc.)

---

## 5. Error States & Recovery

*   **Trigger:** API error during any moderation action.
    *   **State:** Show error message (Snackbar: "Failed to [action]. Please try again."). UI reverts if necessary.
    *   **Recovery:** Builder retries the action.
*   **Trigger:** Attempting action without sufficient permission (e.g., Mod trying Admin action).
    *   **State:** Action might be disabled/hidden, or API returns permission denied error.
    *   **Recovery:** N/A or contact Admin.

---

## 6. Acceptance Criteria

*   **Pre-conditions:** User is a Builder for the Space.
*   **Success Post-conditions:**
    *   Builder can access moderation tools via defined entry points (Q1, Q2, Q4).
    *   Builder can successfully perform V1 content moderation actions (Remove, Pin) (Q3).
    *   Builder can successfully manage member join requests (Approve/Deny).
    *   Builder can manage member roles (Member <-> Admin) (Q5).
    *   Builder can remove members.
    *   **(V1 Scope):** Ban functionality is not present (Q6).
    *   UI updates correctly reflect moderation actions.
*   **General:**
    *   Actions require confirmation where appropriate.
    *   Error states are handled gracefully.

---

## 7. Metrics & Analytics

*   **Moderation Action Frequency:** Count of each moderation action type per Space/Builder.
*   **Join Request Resolution Time:** Avg time from request to Approve/Deny.
*   **Content Removal Rate:** (# Content items removed) / (# Content items created) per Space.
*   **Analytics Events:** (Listed in Sequence section)

---

## 8. Design/UX Notes

*   Moderation actions should be easily accessible but not obstructive to normal viewing.
*   Confirmation dialogs are essential for destructive actions (Remove, Deny, Ban).
*   Clearly differentiate between roles (Admin, Mod, Member).
*   Provide clear feedback after each moderation action.

---

## 9. API Calls & Data

*   **Content Moderation API Calls:** (`RemovePost`, `RemoveComment`, `PinPost`)
    *   Request: Builder User ID, Space ID, Content ID, (Optional: Reason).
    *   Response: Success/Failure.
*   **Member Moderation API Calls:** (`ApproveJoinRequest`, `DenyJoinRequest`, `UpdateMemberRole`, `RemoveMember`)
    *   Request: Builder User ID, Space ID, Target User ID, (Optional: Role).
    *   Response: Success/Failure.
*   **Get Member List / Pending Requests API Call:**
    *   Request: Space ID, Filter (Members/Pending).
    *   Response: Paginated list of User objects with roles/status.

---

## 10. Open Questions

*   **(Resolved)** Q1: Entry Points defined (Content: on item menu; Members: Space Settings -> "Members & Roles" screen).
*   **(Resolved)** Q2: Content Menu is top-right ellipsis ("...") on the item.
*   **(Resolved)** Q3: V1 Content Actions are Remove Content, Pin Post.
*   **(Resolved)** Q4: Member Management access is via Space Settings -> "Members & Roles" screen.
*   **(Resolved)** Q5: V1 Roles are Member, Admin. Managed via "Members & Roles" screen.
*   **(Resolved)** Q6: Banning functionality is deferred (Not V1).

*   **(Action Item):** Design the content item menu for Builders.
*   **(Action Item):** Design the "Members & Roles" screen layout (including tabs for Members/Pending Requests).
*   **(Action Item):** Design the UI for changing member roles.
*   **(Action Item):** Design confirmation dialogs for Remove Content, Deny Request, Remove Member.
*   **(Action Item):** Implement permission checks (e.g., only Admins can change roles/remove other Admins?). 