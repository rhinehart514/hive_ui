# System: Space Lifecycle (Decay & Archival) - V1

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:**
*   [Hive UI Product Context & Documentation Principles](../product_context.md)

---

## 1. Overview

This document outlines the V1 logic for handling Space inactivity (decay) and deliberate archival within the Hive platform. The goal is to maintain a healthy discovery environment by de-emphasizing inactive Spaces while giving Builders control over permanent archival.

---

## 2. States

A Space can exist in one of three primary lifecycle states in V1:

1.  **Active:** The default state for newly created and regularly used Spaces.
2.  **Decaying:** An intermediate state triggered by prolonged inactivity.
3.  **Archived:** A terminal state triggered by manual Builder action.

---

## 3. Decay Logic (V1)

### 3.1 Trigger for Decay

*   A Space transitions from **Active** to **Decaying** if **no new Post has been created** within that specific Space for a continuous period of **90 days**.
    *   *Note:* Edits to existing posts, comments, reactions, member joins/leaves, or other interactions **do not** reset the decay timer.

### 3.2 Effects of Decay

When a Space is in the **Decaying** state:

*   **Discovery:**
    *   Hidden from the main Spaces Discovery Hub for non-members.
    *   Hidden from general search results for non-members.
*   **Visibility (Members/Builders):**
    *   Remains fully visible and accessible to existing members and Builders.
    *   Appears in members' "Joined Spaces" lists.
    *   Accessible via direct links.
*   **Functionality:**
    *   The Space remains **fully functional** for members and Builders.
    *   New posts, comments, events, etc., can still be created.
    *   New members can join (respecting public/private rules).
*   **UI Indicator:**
    *   A subtle, persistent banner or indicator (e.g., text "Inactive", a specific icon) is displayed within the Space header.
    *   This indicator is visible **only to Builders** (Admins) of the Space.
*   **Revival:**
    *   Creating **any new Post** within the Decaying Space immediately transitions it back to the **Active** state.
    *   The decay timer resets.

### 3.3 Decay Notifications

*   When a Space transitions to the **Decaying** state, all users with the **Admin (Builder) role** for that Space receive an in-app notification.
*   *Example Text:* "Activity in [Space Name] has slowed down. Create a post soon to keep it active!"

---

## 4. Archival Logic (V1)

### 4.1 Trigger for Archival

*   Archival is a **manual action only** initiated by a Space **Admin (Builder)**.
*   There is **no automatic archival** based on inactivity duration in V1.
*   **Access Point:** An "Archive Space" option is located within the Space Settings screen, accessible only to Admins.

### 4.2 Effects of Archival

When a Space is **Archived**:

*   **Functionality:**
    *   The Space becomes **read-only** for all users, including Admins.
    *   No new posts, comments, reactions, or other interactions are possible.
    *   No new members can join or request to join.
    *   Existing members cannot leave.
    *   Space settings cannot be changed.
*   **Visibility:**
    *   Hidden from the main Spaces Discovery Hub and search results.
    *   Hidden from users' "Joined Spaces" lists by default.
    *   May only be accessible via direct link (if retained) or potentially a future dedicated "Archived Spaces" section (Not V1).
*   **Content:**
    *   All existing content (posts, comments, member list) is **preserved** in a read-only state.
*   **UI Indicator:**
    *   If accessed (e.g., via direct link), a prominent, persistent "Archived" banner is displayed in the Space header for all viewers.
*   **Reversal:**
    *   Archival is **irreversible** through the UI in V1. (Backend/manual admin intervention might be possible but is not a user-facing feature).

### 4.3 Archival Notifications

*   When an Admin confirms the "Archive Space" action:
    *   The initiating Admin receives a confirmation notification (e.g., "[Space Name] has been archived.").
    *   (Optional) Other Admins of the Space might also receive a notification.

---

## 5. V1 Summary Table

| State        | Trigger                                 | Effects                                                                                                  | Reversible (UI V1)? | Notifications        |
| :----------- | :-------------------------------------- | :------------------------------------------------------------------------------------------------------- | :------------------ | :----------------- |
| **Active**   | Default / New post within 90 days     | Fully functional, visible in discovery                                                                   | N/A                 | N/A                |
| **Decaying** | No new post for 90 days                 | Hidden discovery (non-members), Builder indicator, fully functional                                      | Yes (New Post)      | Builders notified  |
| **Archived** | Manual Builder Action in Space Settings | Read-only, hidden from lists, content preserved, Archived banner                                         | No                  | Builders notified  |

---

## 6. Future Considerations (V2+)

*   Automatic archival after prolonged decay (e.g., 180 days decay).
*   More sophisticated revival mechanisms for decaying spaces.
*   Clearer UI for accessing archived spaces.
*   Member notifications about impending decay/archival.
*   Ability to un-archive (potentially with limitations). 