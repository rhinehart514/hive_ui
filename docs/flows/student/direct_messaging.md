# Flow: Student - Direct Messaging (V1)

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:**
*   [Hive UI Product Context & Documentation Principles](../../product_context.md)

**Figma Link (Overall Flow):** [Link to Figma Frame for DM Chat List & Conversation View]

---

## 1. Title & Goal

*   **Title:** Student Direct Messaging (DM)
*   **Goal:** Allow users to engage in private, one-on-one text conversations with other verified users.

---

## 2. Persona & Prerequisites

*   **Persona:** Student (Logged-in User)
*   **Prerequisites:**
    *   User is logged in.
    *   Recipient user is searchable/available.

---

## 3. Sequence of Actions

### 3.1 Viewing Chat List
*   **Trigger:** User navigates to the main Direct Messaging section of the app.
*   **UI State:** Displays the chat list screen.
    *   **Presentation:** Scrollable list of existing conversations.
    *   **Ordering:** Sorted by the timestamp of the most recent message in each conversation, newest at the top. (Q1.8.1)
    *   **Item Display:** Each list item shows recipient's avatar, name, preview of the last message, and timestamp of the last message. (Q1.8.1)
*   **User Action (Optional):** User swipes left on a conversation item.
*   **System Action:** Archives the conversation locally. (Q1.8.2)
*   **User Action (Optional):** User long-presses on a conversation item.
*   **System Action:** Opens a context menu with options: [Archive], [Report]. (Q1.8.2)

### 3.2 Starting a New DM
*   **Trigger:** User wants to initiate a new private conversation.
*   **User Action:** User taps the "Create New Message" Floating Action Button (+) on the Chat List screen OR taps the "Message" button on another user's profile page. (Q1.8.3)
*   **System Action:** Opens a recipient selection interface (if initiated from FAB) or directly opens the conversation screen (if initiated from profile).
*   **User Action (if selecting):** User searches for the recipient using the global user search. (Q1.8.4)
*   **System Action:** User search filters verified users. User selects the desired recipient.
    *   *Constraint:* Only one-on-one conversations are supported in V1. No group DMs. (Q1.8.4)
*   **UI State:** Navigates to the conversation screen for the selected recipient.

### 3.3 Sending & Receiving Messages
*   **Trigger:** User is viewing an active DM conversation screen.
*   **UI State:** Displays the history of messages in the conversation (chronological). A text input field is present.
*   **User Action:** User types a message into the input field.
    *   *Constraint:* Text-only messages are supported in V1. No images, videos, or other attachments. (Q1.8.5)
*   **User Action:** User taps the "Send" button.
*   **System Action (Optimistic):** Message appears immediately in the conversation history UI.
*   **System Action (Async):** Message is sent to the backend via WebSocket connection. (Q1.8.7)
*   **System Action (Backend):** Message is delivered to the recipient via WebSocket. Backend stores the message.
*   **UI State (Recipient):** New message appears in real-time in the recipient's conversation view and updates their chat list preview/order.
    *   *Constraint:* No read receipts are displayed in V1. (Q1.8.6)
*   **System Action (Error):** If sending fails, the optimistically added message in the sender's UI might show a "failed" state, with an option to retry.

### 3.4 Archiving a Conversation
*   **Trigger:** User wants to hide a conversation from the main chat list without deleting it.
*   **User Action:** User swipes left on the conversation in the chat list OR long-presses and selects "Archive". (Q1.8.2, Q1.8.9)
*   **System Action:** Conversation is removed from the main chat list view locally. (Q1.8.9)
    *   *Note:* There is no separate "Archived Chats" view in V1.
*   **System Action (Unarchive):** If a new message is received in an archived conversation, the conversation reappears in the main chat list. (Q1.8.9)

### 3.5 Deleting a Conversation
*   **Trigger:** User wants to permanently remove a conversation from their view.
*   **User Action:** User accesses conversation options (e.g., via a menu within the DM screen - *needs clarification, assuming from a '...' menu*). User selects "Delete Conversation".
*   **System Action:** Confirmation prompt: "Delete this conversation? This will only remove it for you." Options: [Delete] [Cancel].
*   **User Action:** User confirms deletion.
*   **System Action:** Conversation is permanently removed from the user's local storage and chat list. This action does *not* affect the other participant's view of the conversation. (Q1.8.8, Q1.8.9)

### 3.6 Reporting a Conversation
*   **Trigger:** User encounters problematic behavior within a DM conversation.
*   **User Action:** User taps the options menu (e.g., three-dot menu '...') within the DM conversation screen. (Q1.8.10)
*   **User Action:** User selects "Report Conversation".
*   **UI State:** Report modal appears.
*   **User Action:** User selects a reason: [Spam], [Harassment], [Threats], [Inappropriate Content], [Other]. (Q1.8.10 - *Note: 'Threats' added based on user input*)
*   **User Action:** User submits the report.
*   **System Action:** Report is logged for admin review, including relevant context (e.g., recent messages, involved user IDs).
*   **UI Feedback:** Confirmation Snackbar/Toast: "Report submitted."

*   **Analytics:** [`flow_step: student.dm.view_list`], [`flow_step: student.dm.start_new`], [`flow_step: student.dm.send_message`], [`flow_step: student.dm.receive_message`], [`flow_step: student.dm.archive_convo`], [`flow_step: student.dm.unarchive_convo`], [`flow_step: student.dm.delete_convo`], [`flow_step: student.dm.report_convo {reason}`], [`flow_error: student.dm.send_failed`], [`flow_error: student.dm.report_failed`]

---

## 4. State Diagrams

*   (Diagram: Chat List -> Select Convo / Start New -> View Convo -> Send/Receive Messages -> [Archive/Delete/Report])

---

## 5. Error States & Recovery

*   **Trigger:** Failed to load chat list or conversation history (network error).
    *   **State:** Error message displayed (e.g., "Couldn't load messages").
    *   **Recovery:** Retry mechanism (e.g., pull-to-refresh, retry button).
*   **Trigger:** Failed to send a message (network error, WebSocket disconnect).
    *   **State:** Message marked as "Failed" in UI.
    *   **Recovery:** User can tap to retry sending. System might retry automatically on reconnect.
*   **Trigger:** Failed to archive/delete/report (network error).
    *   **State:** Snackbar error: "Action failed. Please try again."
    *   **Recovery:** User retries the action.

---

## 6. Acceptance Criteria

*   Chat list displays correctly, ordered by recent activity (Q1.8.1).
*   Archive action via swipe/menu functions correctly (Q1.8.2, Q1.8.9).
*   Users can initiate new DMs via FAB and profile page (Q1.8.3).
*   Recipient selection works via global search; one-on-one only (Q1.8.4).
*   Text-only messages can be sent and received in real-time (Q1.8.5, Q1.8.7).
*   No read receipts are present (Q1.8.6).
*   Conversations can be deleted (for the user only) (Q1.8.8, Q1.8.9).
*   Conversations can be reported with appropriate reasons (Q1.8.10).
*   Network errors are handled gracefully with retry options.

---

## 7. Metrics & Analytics

*   **DM Sent Rate:** (# DMs Sent) / (# Active Users).
*   **DM Conversation Initiated:** (# New Conversations Started).
*   **DM Engagement:** Average messages per active conversation.
*   **DM Report Rate:** (# DM Reports Submitted).
*   **Analytics Events:** (Listed in Sequence section)

---

## 8. Design/UX Notes

*   Real-time updates (Q1.8.7) are crucial for a good chat experience.
*   Clear distinction between Archive (local hide) and Delete (local remove) (Q1.8.9).
*   Ensure user search for new DMs (Q1.8.4) is performant and accurate.
*   Swipe actions (Q1.8.2) provide quick access to common functions.

---

## 9. API Calls & Data (Illustrative - likely WebSocket events)

*   **Get Chat List:**
    *   **Request:** User ID, [Pagination Info].
    *   **Response:** List of Conversation objects (Convo ID, Participant Info, Last Message Preview, Timestamp).
*   **Get Conversation History:**
    *   **Request:** User ID, Conversation ID, [Pagination Info].
    *   **Response:** List of Message objects (Message ID, Sender ID, Text, Timestamp).
*   **Send Message (WebSocket Emit):**
    *   **Payload:** Sender ID, Conversation ID/Recipient ID, Text Content.
*   **Receive Message (WebSocket Listen):**
    *   **Payload:** Message object.
*   **Archive/Delete Conversation (API Call):**
    *   *(Note: Archive might be purely local state. Delete is local)*
*   **Report Conversation (API Call):**
    *   **Request:** Reporter User ID, Conversation ID, Report Reason, [Context?].
    *   **Response:** Success/Failure.

---

## 10. Open Questions (Resolved for V1)

1.  **Chat List Presentation/Ordering:** How is the chat list shown and sorted?
    *   ✅ **A1.8.1:** Scrollable list, most recent first. Shows avatar, name, preview, timestamp.
2.  **Chat List Actions:** What actions are available from the list item (swipe, long-press)?
    *   ✅ **A1.8.2:** Swipe left = archive. Long-press = Archive/Report menu.
3.  **New DM Entry Points:** How is a new DM started?
    *   ✅ **A1.8.3:** FAB on chat list; "Message" button on profile.
4.  **Recipient Selection/Group DMs:** How are recipients chosen? Group DMs?
    *   ✅ **A1.8.4:** Global user search. One-on-one only V1.
5.  **Message Types V1:** Text only or media allowed?
    *   ✅ **A1.8.5:** Text-only V1.
6.  **Read Receipts V1:** Are read receipts implemented?
    *   ✅ **A1.8.6:** No read receipts V1.
7.  **Real-time Updates:** Expected or manual refresh?
    *   ✅ **A1.8.7:** Real-time via WebSockets.
8.  **Deletion Granularity:** Delete messages or conversations?
    *   ✅ **A1.8.8:** Only full conversations.
9.  **Archive vs. Delete:** What's the difference? Where do archived chats go?
    *   ✅ **A1.8.9:** Archive = hides locally, reappears on new message. Delete = removes locally for user only. No separate archive view.
10. **Report Mechanism/Reasons:** How are DMs reported? What reasons?
    *   ✅ **A1.8.10:** Via '...' menu in DM screen. Reasons: Spam, Harassment, Threats, Inappropriate, Other.

**All questions resolved for V1.** 