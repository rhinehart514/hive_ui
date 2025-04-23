# Flow: Student - Create Media Post (Image/Video)

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:**
*   [Flow: Student - Create Text Post](./create_text_post.md)
*   [Flow: Student - Post Draft Handling](./post_draft_handling.md)
*   [Hive UI Product Context & Documentation Principles](../../product_context.md)

**Figma Link (Overall Flow):** [Link to Figma Frame for Media Post Composer]

---

## 1. Title & Goal

*   **Title:** Student Create Rich Media Post (Drop)
*   **Goal:** Allow a user to create and publish a post (Drop) that includes attached images or videos, along with optional text, to a specific Space.

---

## 2. Persona & Prerequisites

*   **Persona:** Student (Logged-in User)
*   **Prerequisites:**
    *   User is logged in.
    *   User is a member of at least one Space where they have permission to post.
    *   User has granted necessary permissions (camera, photo library access).

---

## 3. Sequence

### 3.1 Initiating Media Post Creation
*   **Trigger:** User wants to create a post with media.
*   **User Action:** From the post composer (text-focused), user taps an "Add Media" / attachment icon (e.g., 📎).
    *   ❓ **Q1:** Is the entry point the same composer as text posts, just with an additional action?
    *   ✅ **A1 (V1):** Yes, it's the **same composer screen** initiated for text posts. The user taps an **attachment (📎) icon** within that composer.
*   **System Action:** Opens the device's native media picker (gallery/camera).
    *   ❓ **Q2:** Does it open a native gallery picker, or an in-app browser?
    *   ✅ **A2 (V1):** Opens the **native OS media picker** (gallery/camera).

### 3.2 Selecting Media
*   **User Action:** User selects one or more images/videos from the picker.
    *   ❓ **Q3:** What are the limits on the number and type of media files allowed per post in V1? (e.g., Max 4 images? 1 video? Mix allowed?)
    *   ✅ **A3 (V1):** Max **4 images** OR **1 video** per post. No mixing images and video in the same post for V1.
    *   ❓ **Q4:** Are there file size or format restrictions (e.g., max 20MB, JPG/PNG/MP4 only)?
    *   ✅ **A4 (V1):** Yes. **JPG, PNG** for images, **MP4** for video. **Max 20MB** total upload size.
*   **System Action:** Selected media files are prepared for preview in the composer.

### 3.3 Previewing and Editing Media
*   **UI State:** Composer displays thumbnails or previews of the selected media.
    *   ❓ **Q5:** How is selected media previewed? (e.g., Grid of thumbnails? Carousel?)
    *   ✅ **A5 (V1):** A **grid preview** of thumbnails is shown below the text input area.
*   **User Action (Optional):** User may remove selected media items.
    *   ❓ **Q6:** How can users remove a selected media item before posting?
    *   ✅ **A6 (V1):** Each thumbnail in the grid preview has a **small 'X' icon** in its corner. Tapping it removes the item.
*   **User Action (Optional):** User may perform basic edits on media (e.g., crop, rotate - likely minimal for V1).
    *   ❓ **Q7:** What basic media editing capabilities are available in V1? (e.g., Crop? Rotate? Filters?)
    *   ✅ **A7 (V1):** **Minimal native editing only**, likely just what the OS picker provides (e.g., basic crop/zoom before selection). No in-app filters or advanced editing for V1.

### 3.4 Adding Text Caption
*   **User Action:** User adds optional text content to accompany the media.
    *   ❓ **Q8:** Is the text limit the same as for text-only posts?
    *   ✅ **A8 (V1):** Yes, the **same 500-character limit** applies to the text caption accompanying media.
*   **UI State:** Text appears in the input field.

### 3.5 Selecting Target Space & Visibility
*   **User Action:** User selects the target Space (if not pre-selected) and confirms visibility.
    *   ❓ **Q9:** Are the Space selection and visibility options/UI identical to the text post flow?
    *   ✅ **A9 (V1):** Yes, **identical** to the text post flow (Dropdown/Button for Space, pre-filled if contextual, non-editable "Space members only" visibility chip).
*   **UI State:** Selected Space and visibility info are displayed.

### 3.6 Uploading and Publishing
*   **User Action:** User taps the "Post" / "Drop" button.
*   **UI State (Processing):**
    *   ❓ **Q10:** How is upload progress indicated, especially for larger video files?
    *   ✅ **A10 (V1):** A **progress bar or circular indicator** is shown overlaid on the media thumbnails during upload. The Post button remains **disabled with an internal spinner**.
*   **System Action:** App initiates media upload to storage (e.g., Firebase Storage) and then creates the post record via API, linking the media URLs.
*   **UI Feedback (Success):**
    *   ❓ **Q11:** Is success feedback the same as text posts?
    *   ✅ **A11 (V1):** Yes, **identical** success feedback: Composer closes, post appears in feed, **Snackbar** confirms "Posted to [Space Name]".
*   **UI Feedback (Failure):**
    *   ❓ **Q12:** How are upload/post failures handled? (e.g., Specific error for upload vs. API? Retry mechanism? Draft saving?)
    *   ✅ **A12 (V1):** **Snackbar** indicates failure (e.g., "Upload failed. Retrying..." or "Post failed. Retrying..."). **Automatic retry** is attempted. The **draft is saved locally** with references to the selected local media files (not the uploaded URLs). Composer remains open during retry.

*   **Analytics:** [`flow_step: student.post.create_media.initiated`], [`flow_step: student.post.create_media.selected {count, type}`], [`flow_step: student.post.create_media.upload_attempt`], [`flow_step: student.post.create_media.upload_success`], [`flow_error: student.post.create_media.upload_failed {reason}`], [`flow_step: student.post.create_media.publish_attempt`], [`flow_step: student.post.create_media.publish_success {post_id, space_id, media_count, media_type}`], [`flow_error: student.post.create_media.publish_failed {reason}`]

---

## 4. State Diagrams

*   (Diagram: Initiate -> Attach Media -> [Add Text] -> Select Space -> Publish -> Uploading -> Processing -> Success/Fail)

---

## 5. Error States & Recovery

*   **Trigger:** No storage/camera permissions.
    *   **State:** User prompted to grant permissions or action fails with message.
    *   **Recovery:** User grants permissions via OS settings.
*   **Trigger:** Media selection/capture cancelled.
    *   **State:** Composer remains open, no media attached.
    *   **Recovery:** User can try attaching media again.
*   **Trigger:** Media upload fails (network, server error, size limit).
    *   **State:** Error message displayed (Q12).
    *   **Recovery:** Retry mechanism? Discard media? Save draft?
*   **Trigger:** Post creation API call fails.
    *   **State:** Error message displayed (Q12).
    *   **Recovery:** Retry? Draft saved?

---

## 6. Acceptance Criteria

*   User can initiate media post creation (Q1, Q2).
*   User can attach media from library or camera (Q3, Q4).
*   Media previews are displayed correctly and can be managed (Q5).
*   User can add optional text (Q8) and configure Space/Visibility (Q9).
*   Appropriate feedback is shown during upload/processing (Q10).
*   Successful post creation results in the post appearing in feeds with success feedback (Q11).
*   Upload and creation errors are handled gracefully with recovery options (Q12).

---

## 7. Metrics & Analytics

*   **Media Post Rate:** (# Media Posts Created) / (# Total Posts Created).
*   **Media Attachment Source:** % Library vs. % Camera.
*   **Multi-Media Post Rate:** % of media posts with >1 item.
*   **Upload Success/Failure Rate:** Breakdown by reason.
*   **Post Creation Success/Failure Rate:** After successful upload.
*   **Analytics Events:** (Listed in Sequence section)

---

## 8. Design/UX Notes

*   Media selection/capture should be seamless.
*   Handling uploads (especially large videos) requires clear progress indication and robust error handling.
*   Consider background uploading to allow the user to navigate away while processing completes.
*   Ensure media previews (Q5) are representative and easy to manage.

---

## 9. API Calls & Data

*   **(Media Upload Service):** Handles file uploads, returns media references/URLs.
*   **Create Post API Call:**
    *   **Request:** User ID, Target Space ID, [Optional: Text Content], **List of Media References/URLs**, [Visibility Settings].
    *   **Response:** Success/Failure, [New Post Object].

---

## 10. Open Questions

1.  **Entry Point:** Same composer as text posts?
    *   ✅ **A1 (V1):** Yes, via attachment 📎 icon in text composer.
2.  **Media Picker:** Native OS picker or in-app?
    *   ✅ **A2 (V1):** Native OS picker.
3.  **Media Limits (V1):** Max number/type of files?
    *   ✅ **A3 (V1):** Max 4 images OR 1 video. No mixing.
4.  **File Restrictions:** Size/format limits?
    *   ✅ **A4 (V1):** JPG/PNG/MP4, 20MB total max.
5.  **Media Preview:** How is selected media shown?
    *   ✅ **A5 (V1):** Grid preview of thumbnails below text input.
6.  **Remove Media:** How to remove selected items?
    *   ✅ **A6 (V1):** Small 'X' icon on each thumbnail preview.
7.  **Editing (V1):** Basic media editing capabilities?
    *   ✅ **A7 (V1):** Minimal native editing via OS picker only (e.g., basic crop/zoom). No in-app edits.
8.  **Text Caption Limit:** Same as text posts?
    *   ✅ **A8 (V1):** Yes, 500 characters.
9.  **Space/Visibility:** Same UI/options as text posts?
    *   ✅ **A9 (V1):** Yes, identical.
10. **Upload Progress:** How is progress indicated?
    *   ✅ **A10 (V1):** Progress indicator over thumbnails. Post button disabled + internal spinner.
11. **Success Feedback:** Same as text posts?
    *   ✅ **A11 (V1):** Yes, identical (Snackbar).
12. **Failure Handling:** Upload vs. API errors? Retry? Draft?
    *   ✅ **A12 (V1):** Snackbar error, auto-retry, local draft saved with local media refs. Composer stays open.

**All questions resolved for V1.**


</rewritten_file> 