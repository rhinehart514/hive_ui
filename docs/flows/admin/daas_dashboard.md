# Flow: Admin - Data as a Service (DaaS) Dashboard (V1)

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:**
*   [Hive UI Product Context & Documentation Principles](../../product_context.md)

**Figma Link (Overall Flow):** [Link to Figma Frame for DaaS Web Dashboard]

---

## 1. Title & Goal

*   **Title:** Admin Data as a Service (DaaS) Dashboard
*   **Goal:** Provide authorized university administrators with a web-based dashboard to view key platform metrics and export relevant data.

---

## 2. Persona & Prerequisites

*   **Persona:** University Administrator (Authorized User)
*   **Prerequisites:**
    *   Admin user account has been manually provisioned and granted access. (Q1.13.1 - No self-serve V1)
    *   Admin user logs in via a secure web portal.

---

## 3. Sequence of Actions

### 3.1 Admin Onboarding & Login
*   **Trigger:** Admin needs to access the data dashboard.
*   **System Action:** Admin account is manually invited/created by the platform team. (Q1.13.1)
*   **User Action:** Admin receives credentials/invitation and navigates to the DaaS web portal login page.
*   **User Action:** Admin logs in using provided credentials.
*   **UI State:** Displays the main DaaS dashboard view.

### 3.2 Viewing the Dashboard
*   **Trigger:** Admin successfully logs in.
*   **UI State:** Presents a lightweight web dashboard displaying key metrics.
    *   **V1 Metrics:** Daily Active Users (DAU), Event RSVPs count, Number of Active Spaces, Basic Engagement Curve (e.g., posts/comments over time). (Q1.13.2)
    *   **Presentation:** Data likely shown via simple charts and key number callouts.

### 3.3 Exporting Data
*   **Trigger:** Admin needs raw data for specific areas.
*   **User Action:** Admin navigates to a data export section or selects an export option associated with a specific metric/dashboard section.
*   **UI State:** Presents options for data export.
    *   **V1 Export Options:** Allow CSV export for different sections like Events (RSVP list?), Users (basic list?), Spaces (activity?). (Q1.13.4)
*   **User Action:** Admin selects the data type and initiates the CSV export.
*   **System Action:** Generates the CSV file and initiates download in the admin's browser.
*   **UI Feedback:** Confirmation that the export has started/completed.

### 3.4 Configuration & Management (Out of Scope V1)
*   **Custom Reports/Alerts:** Admins **cannot** configure custom reports or automated alerts in V1. (Q1.13.3)
*   **API Access:** There is **no API access** for university admins in V1. (Q1.13.4)
*   **Seat/Permission Management:** Admins **cannot** manage other admin roles, seats, or permissions within their institution in V1. All admin roles are single-seat and managed by the platform team. (Q1.13.5)

*   **Analytics:** [`flow_step: admin.daas.login`], [`flow_step: admin.daas.view_dashboard`], [`flow_step: admin.daas.export_data {type}`], [`flow_error: admin.daas.login_failed`], [`flow_error: admin.daas.export_failed`]

---

## 4. State Diagrams

*   (Diagram: Login -> View Dashboard -> [Select Export Section] -> Initiate Export -> Download CSV)

---

## 5. Error States & Recovery

*   **Trigger:** Invalid login credentials.
    *   **State:** Login error message displayed.
    *   **Recovery:** Admin corrects credentials or uses a password reset mechanism (if available for admins).
*   **Trigger:** Error loading dashboard data.
    *   **State:** Error message displayed on dashboard.
    *   **Recovery:** Retry loading, contact platform support if persistent.
*   **Trigger:** Error generating data export.
    *   **State:** Error message displayed.
    *   **Recovery:** Admin retries export, contact platform support if persistent.
*   **Trigger:** Unauthorized access attempt.
    *   **State:** Access denied page.
    *   **Recovery:** N/A.

---

## 6. Acceptance Criteria

*   Manually provisioned admins can log into the DaaS web portal.
*   Dashboard displays the defined V1 key metrics (DAU, RSVPs, Active Spaces, Engagement) (Q1.13.2).
*   Admins can trigger CSV data exports for defined sections (Users, Events, Spaces) (Q1.13.4).
*   Exported CSV files contain relevant data.
*   No functionality exists for self-serve admin signup (Q1.13.1), custom reports/alerts (Q1.13.3), API access (Q1.13.4), or seat management (Q1.13.5).
*   Login and data loading/export errors are handled gracefully.

---

## 7. Metrics & Analytics

*   **Admin Login Rate:** Frequency of admin logins.
*   **Dashboard View Frequency.**
*   **Data Export Rate:** Frequency and type of data exports.
*   **(Internal) Dashboard Load Time & Error Rates.**
*   **Analytics Events:** (Listed in Sequence section)

---

## 8. Design/UX Notes

*   The dashboard should prioritize clarity and ease of understanding for the key V1 metrics.
*   Data export should be straightforward and provide useful, well-formatted CSVs.
*   Security is paramount for the admin login and data access.

---

## 9. API Calls & Data

*   **(DaaS Backend APIs - Internal):**
    *   API for Admin Authentication.
    *   API to retrieve aggregated dashboard metrics (DAU, RSVPs, etc.).
    *   API to generate and stream CSV export data based on requested type.

---

## 10. Open Questions (Resolved for V1)

1.  **Admin Onboarding V1:** Self-serve signup/verification?
    *   ✅ **A1.13.1:** No, admins manually invited/provisioned by platform team in V1.
2.  **Dashboard Metrics V1:** Web dashboard included? Key metrics?
    *   ✅ **A1.13.2:** Yes, lightweight web dashboard. Metrics: DAU, Event RSVPs, Active Spaces, Engagement curve.
3.  **Custom Reports/Alerts V1:** Can admins configure reports/alerts?
    *   ✅ **A1.13.3:** No, not in V1.
4.  **Data Export/API V1:** Data export or API access available?
    *   ✅ **A1.13.4:** CSV export per section (events, users, etc.). No API access in V1.
5.  **Seat/Permission Management V1:** Can admins manage seats/permissions?
    *   ✅ **A1.13.5:** No, all admin roles single-seat, managed by platform team in V1.

**All questions resolved for V1.** 