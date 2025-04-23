# HIVE Backend API Contracts

_This document details the Cloud Functions exposed by the HIVE backend._

## Function Namespaces

Functions are organized into namespaces based on their primary domain:

*   `verification`: User verification and role management.
*   `events`: Event lifecycle and state management.
*   `spaces`: Space-related operations (e.g., member counts).
*   `notifications`: User notification generation and management.
*   `events_sync`: Synchronization tasks related to events.
*   `user_engagement`: Tracking user activity and engagement metrics.
*   `recommendations`: Content and connection recommendations.
*   `analytics`: Event tracking for analytics platforms.
*   `moderation`: Content moderation and reporting.
*   `social_graph`: Managing user relationships (follows, etc.).

---

## Global Functions

### `healthCheck`

*   **Type:** `https.onRequest` (Publicly accessible HTTP endpoint)
*   **Description:** Simple check to confirm the functions deployment is alive.
*   **Request Parameters:** None.
*   **Authentication:** None required.
*   **Response (Success - 200):**
    ```
    Firebase Functions for HIVE UI are running
    ```
*   **Response (Error):** Standard Firebase Functions HTTP errors.

---

## Verification (`verification`)

### `processEmailVerification`

*   **Type:** `firestore.onCreate` (Triggered by Firestore document creation)
*   **Trigger Path:** `emailVerifications/{requestId}`
*   **Description:** Automatically sends a verification email when a new document is added to the `emailVerifications` collection with `status: 'pending'`. Updates the document status to `'sent'` on success or `'error'` on failure.
*   **Input Data (Trigger):** Expects the created document (`snapshot.data()`) to contain `email` (string) and `code` (string).
*   **Authentication:** N/A (Triggered by backend event).
*   **Side Effects:** Sends email via Nodemailer (requires `email` config in functions environment), updates the triggering Firestore document (`status`, `sentAt`/`error`, `updatedAt`).
*   **Return Value (Internal):** `{ success: true }` or `{ success: false, error: errorMessage }`.

### `submitVerificationCode`

*   **Type:** `https.onCall` (Callable function invoked from the client)
*   **Description:** Allows an authenticated user to submit an email verification code. Validates the code against pending requests for that user, checks expiration, and marks the request as `'completed'` if valid. Triggers a role claim update (`claimUpdates` collection) to grant 'Verified' status (level 1).
*   **Request Parameters:**
    *   `data`: `{ code: string }` - The verification code entered by the user.
*   **Authentication:** Required (User must be authenticated via Firebase Auth).
*   **Response (Success):** `{ success: true, message: 'Email successfully verified.' }`
*   **Response (Error):** Throws `functions.https.HttpsError` with codes:
    *   `unauthenticated`: If the user is not logged in.
    *   `invalid-argument`: If `code` is missing or invalid.
    *   `not-found`: If the code is invalid, expired, or doesn't match a pending request for the user.
    *   `internal`: For other server errors.
*   **Side Effects:** Updates the corresponding document in `emailVerifications` collection (`status`, `completedAt`), creates a new document in `claimUpdates` collection.

### `cleanupExpiredVerifications`

*   **Type:** `pubsub.schedule` (Scheduled function)
*   **Schedule:** `0 0 * * *` (Daily at midnight)
*   **Description:** Finds email verification requests (`emailVerifications` collection) that are past their `expiresAt` timestamp and still have `status: 'pending'`. Updates their status to `'expired'`.
*   **Input Data:** N/A (Scheduled trigger).
*   **Authentication:** N/A (Triggered by schedule).
*   **Side Effects:** Updates documents in the `emailVerifications` collection (`status`, `updatedAt`).
*   **Return Value:** None explicit (Logs the number of cleaned-up requests).

### `updateUserRoleClaims`

*   **Type:** `firestore.onCreate` (Triggered by Firestore document creation)
*   **Trigger Path:** `claimUpdates/{updateId}`
*   **Description:** Updates a user's custom claims in Firebase Auth (`roles`, `verificationLevel`) based on a new document in the `claimUpdates` collection. It also writes to `user_metadata/{userId}` to help force client-side token refresh.
*   **Input Data (Trigger):** Expects the created document (`snapshot.data()`) to contain `userId` (string) and `verificationLevel` (number: 0=public, 1=verified, 2=verified+).
*   **Authentication:** N/A (Triggered by backend event).
*   **Side Effects:** Modifies Firebase Auth custom claims for the specified `userId`, updates the triggering `claimUpdates` document (`processed`, `processedAt`, `success`, `error`), writes/merges data into `user_metadata/{userId}` (`refreshTime`).
*   **Return Value (Internal):** `{ success: true }` or `{ success: false, error: errorMessage }`.

### `processVerificationStatusChange`

*   **Type:** `firestore.onUpdate` (Triggered by Firestore document update)
*   **Trigger Path:** `verificationRequests/{requestId}`
*   **Description:** Handles the consequences of a verification request being approved or rejected. If approved, it updates the user's verification status in `user_verifications`, triggers a claim update via `claimUpdates`, potentially adds the user as a leader to a space (if Verified+), and sends an approval notification. If rejected, it updates `user_verifications` and sends a rejection notification.
*   **Input Data (Trigger):** Triggered when a `verificationRequests` document's `status` changes to `'approved'` or `'rejected'`. Reads `userId`, `requestedLevel`, `spaceId` (if applicable), `approvedBy`, `rejectedBy`, `rejectionReason` from the updated document (`change.after.data()`).
*   **Authentication:** N/A (Triggered by backend event).
*   **Side Effects:** Writes/updates documents in `user_verifications`, creates documents in `claimUpdates`, creates documents in `notifications`, potentially updates the `leaders` array in a `spaces` document.
*   **Return Value (Internal):** `{ success: true }` or `{ success: false, error: errorMessage }`.

### `requestVerifiedPlusClaim`

*   **Type:** `https.onCall` (Callable function invoked from the client)
*   **Description:** Allows an authenticated and 'Verified' user to request 'Verified+' status for a specific Space. Creates a 'pending' request document in the `verificationRequests` collection.
*   **Request Parameters:**
    *   `data`: `{ spaceId: string, evidence?: string }` - The ID of the space for the request and optional supporting evidence.
*   **Authentication:** Required (User must be authenticated via Firebase Auth and have the `verified` custom claim).
*   **Response (Success):** `{ success: true, requestId: string, message: 'Verified+ request submitted successfully.' }`
*   **Response (Error):** Throws `functions.https.HttpsError` with codes:
    *   `unauthenticated`: If the user is not logged in.
    *   `permission-denied`: If the user is not 'Verified'.
    *   `invalid-argument`: If `spaceId` is missing or invalid.
    *   `not-found`: If the specified `spaceId` doesn't exist.
    *   `already-exists`: If a pending or approved request already exists for this user/space.
    *   `internal`: For other server errors.
*   **Side Effects:** Creates a new document in the `verificationRequests` collection.

### `approveVerifiedPlusClaim`

*   **Type:** `https.onCall` (Callable function invoked from the client)
*   **Description:** Allows an authenticated Admin user (HIVE Staff) to approve a pending 'Verified+' request. Updates the status of the specified request document in `verificationRequests` to `'approved'`. The actual granting of claims/roles is handled by the `processVerificationStatusChange` trigger.
*   **Request Parameters:**
    *   `data`: `{ requestId: string }` - The ID of the `verificationRequests` document to approve.
*   **Authentication:** Required (User must be authenticated via Firebase Auth and have the `admin` custom claim).
*   **Response (Success):** `{ success: true, message: 'Verified+ request approved successfully.' }`
*   **Response (Error):** Throws `functions.https.HttpsError` with codes:
    *   `permission-denied`: If the user is not an Admin.
    *   `invalid-argument`: If `requestId` is missing or invalid.
    *   `not-found`: If the specified `requestId` doesn't exist.
    *   `failed-precondition`: If the request is not 'pending' or not for level 2 (Verified+).
    *   `internal`: For other server errors.
*   **Side Effects:** Updates a document in the `verificationRequests` collection (`status`, `approvedBy`, `updatedAt`).

---

## Events (`events`)

*(The function `handleEventStateTransitions` referenced in index.ts appears outdated. Documenting functions found in `event_state_transitions.ts` instead.)*

### `updateEventStates`

*   **Type:** `pubsub.schedule` (Scheduled function)
*   **Schedule:** `every 15 minutes`
*   **Description:** Automatically updates event states based on their `startDate` and `endDate` relative to the current time. Handles transitions: Published -> Live (when `startDate` <= now), Live -> Completed (when `endDate` <= now), Completed -> Archived (when `endDate` <= now - 12 hours).
*   **Input Data:** N/A (Scheduled trigger).
*   **Authentication:** N/A (Triggered by schedule).
*   **Side Effects:** Updates `state`, `stateUpdatedAt`, and `stateHistory` fields in relevant documents within the `events` collection. Logs the number of updates made.
*   **Return Value:** None explicit.

### `validateEventCreation`

*   **Type:** `firestore.onCreate` (Triggered by Firestore document creation)
*   **Trigger Path:** `events/{eventId}`
*   **Description:** Ensures that a newly created event document has a valid initial state. If `state` is missing, it sets it to `PUBLISHED` if `published: true` exists, otherwise `DRAFT`. Initializes `stateUpdatedAt` and `stateHistory`.
*   **Input Data (Trigger):** Reads the newly created event document (`snapshot.data()`) including the optional `published` flag.
*   **Authentication:** N/A (Triggered by backend event).
*   **Side Effects:** Updates the triggering `events` document (`state`, `stateUpdatedAt`, `stateHistory`) if the state was initially missing.
*   **Return Value:** None explicit.

### `transitionEventState`

*   **Type:** `https.onCall` (Callable function invoked from the client)
*   **Description:** Allows an authenticated user to manually change the state of an event, subject to permissions. Creators can move between `DRAFT` and `PUBLISHED` (if event hasn't started). Admins can make any transition, including to `ARCHIVED`.
*   **Request Parameters:**
    *   `data`: `{ eventId: string, targetState: EventLifecycleState }` - ID of the event and the desired state (e.g., 'published', 'draft').
*   **Authentication:** Required (User must be authenticated). Permissions are checked based on event `createdBy` field and user's `role` ('admin' or other) from the `users` collection.
*   **Response (Success):** `{ success: true, message: 'Event state transitioned successfully.' }`
*   **Response (Error):** Throws `functions.https.HttpsError` with codes:
    *   `unauthenticated`: If the user is not logged in.
    *   `invalid-argument`: If `eventId` or `targetState` are missing or `targetState` is invalid.
    *   `not-found`: If the user or event document doesn't exist.
    *   `permission-denied`: If the user lacks permission for the requested transition.
    *   `internal`: For other server errors.
*   **Side Effects:** Updates the specified `events` document (`state`, `stateUpdatedAt`, `stateHistory`, `updatedBy`).

---

## Spaces (`spaces`)

### `updateSpaceMemberCount`

*   **Type:** `firestore.onWrite` (Triggered by Firestore document write - create, update, delete)
*   **Trigger Path:** `spaces/{spaceId}/members/{memberId}`
*   **Description:** Updates the `public_member_count` field on the parent `spaces/{spaceId}` document whenever a document is created or deleted in its `members` subcollection. Increments the count on creation, decrements on deletion. Ignores updates to existing member documents.
*   **Input Data (Trigger):** Detects creation (`!change.before.exists && change.after.exists`) or deletion (`change.before.exists && !change.after.exists`) of a member document.
*   **Authentication:** N/A (Triggered by backend event).
*   **Side Effects:** Updates the `public_member_count` field on the corresponding `spaces/{spaceId}` document using `FieldValue.increment()`.
*   **Return Value (Internal):** `{ success: true }` or `{ success: false, error: errorMessage }`.

---

## Notifications

*(Details to be added based on analysis of `./notifications.ts`)*

---

## Events Sync

*(Details to be added based on analysis of `./events_sync.ts`)*

---

## User Engagement

*(Details to be added based on analysis of `./user_engagement.ts`)*

---

## Recommendations

*(Details to be added based on analysis of `./recommendations.ts`)*

---

## Analytics

*(Details to be added based on analysis of `./analytics.ts`)*

---

## Moderation

### `processContentReport`

*   **Type:** `firestore.onDocumentCreated` (Triggered by Firestore document creation)
*   **Trigger Path:** `content_reports/{reportId}`
*   **Description:** Processes a newly created content report. Checks if the reported content (`contentId`, `contentType`) already exists in the `moderation_queue`. If yes, increments the `reportCount` and updates timestamps/priority on the existing queue item. If no, it fetches the reported content (post, comment, event, etc.), checks if it exists, and creates a new item in `moderation_queue` with details like `contentText`, `contentCreatorId`, `reportCount: 1`, `status: 'pending'`. It then triggers an asynchronous content analysis (`analyzeContent` helper) for the new queue item. If the reported content doesn't exist, the report status is set to `'dismissed'`.
*   **Input Data (Trigger):** Reads the created `ContentReport` document (`snapshot.data()`), expecting `contentId`, `contentType`, `reporterId`, `createdAt`. Reads existing `moderation_queue` items and the actual reported content document.
*   **Authentication:** N/A (Triggered by backend event).
*   **Side Effects:** Creates or updates documents in `moderation_queue`. May update the triggering `content_reports` document status. Calls `analyzeContent` helper.
*   **Return Value:** None explicit.

### `moderateContent`

*   **Type:** `https.onCall` (Callable function invoked from the client)
*   **Description:** Allows an authenticated user with the 'moderator' role to take action on a moderation queue item. Updates the status of the `moderation_queue/{moderationId}` document and associated `content_reports` to 'reviewed'. Performs actions on the content based on the specified `action` parameter ('hide', 'restore', 'delete', 'warn_author', or implicitly 'dismiss' if no action affects content). 'hide' sets `isHidden: true` on content. 'restore' sets `isHidden: false`. 'delete' backs up the content to `deleted_content` collection and then deletes the original. 'warn_author' creates a document in `user_warnings`.
*   **Request Parameters:**
    *   `data`: `{ moderationId: string, action: string, notes?: string }` - ID of the `moderation_queue` item, the action taken (e.g., 'hide', 'delete', 'dismiss', 'restore', 'warn_author'), and optional moderator notes.
*   **Authentication:** Required (User must be authenticated and have 'moderator' role in their `user_profiles` document's `roles` array).
*   **Response (Success):** `{ success: true }`
*   **Response (Error):** Throws `functions.https.HttpsError` with codes:
    *   `unauthenticated`: If the user is not logged in.
    *   `permission-denied`: If the user is not a moderator.
    *   `invalid-argument`: If `moderationId` or `action` are missing.
    *   `not-found`: If the `moderation_queue` item doesn't exist.
    *   `internal`: For other server errors.
*   **Side Effects:** Updates the specified `moderation_queue` document. Updates related `content_reports` documents. May update the moderated content document (hide/restore/delete). May create documents in `deleted_content` or `user_warnings`.

*(Note: The `analyzeContent` and `autoHideContent` functions are internal helpers triggered by `processContentReport` based on simple text analysis and thresholds. They update the `moderation_queue` item with scores and can automatically set `isHidden: true` on content if a high threshold is met.)*

---

## Social Graph

*(Details to be added based on analysis of `./social_graph.ts`)* 