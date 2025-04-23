# Flow: Student - Profile & Social Graph (V1)

**Version:** 1.0
**Date:** YYYY-MM-DD
**Owner:** [Your Name/Team]

**Related Context:**
*   [Flow: Student - Settings & Support](./settings_support.md)
*   [Hive UI Product Context & Documentation Principles](../../product_context.md)

**Figma Link (Overall Flow):** [Link to Figma Frame for Profile View & Edit]

---

## 1. Title & Goal

*   **Title:** Student Profile & Social Graph
*   **Goal:** Define how users view their own and others' profiles, manage their profile information, and interact with the social graph (following/followers).

---

## 2. Persona & Prerequisites

*   **Persona:** Student (Logged-in User)
*   **Prerequisites:**
    *   User is logged in.
    *   Profile data exists (from onboarding or subsequent edits).

---

## 3. Sequence of Actions

### 3.1 Viewing Own Profile
*   **Trigger:** User navigates to their own profile section.
    *   *Entry Point:* Likely via a dedicated Profile tab in the main navigation or tapping their avatar.
*   **UI State:** Displays the user's own profile screen.
    *   **Displayed Info:** Avatar, Name, Bio, Interests (as tags). (Q1.11.1)
    *   **Displayed Sections/Tabs:** A tabbed or sectioned view showing user's Posts, Saved items, Joined Spaces, RSVP'd Events. (Q1.11.1)
    *   **Settings Access:** A gear icon (⚙️) provides access to the main Settings screen. (Q1.11.1)
    *   **Achievements/Badges Tab:** An "Achievements" tab exists but is empty in V1 (no badges). (Q1.11.7)

### 3.2 Viewing Another User's Profile
*   **Trigger:** User taps on another user's name or avatar (e.g., on a post, comment, member list).
*   **UI State:** Displays the other user's profile screen.
    *   **Publicly Visible Info:** Avatar, Name, Bio. (Q1.11.2)
    *   **Content:** Shows the user's public Posts. (Q1.11.2)
    *   **Follow Button:** A "Follow" / "Following" / "Unfollow" button is visible. (Q1.11.2)
    *   *Constraint:* Does NOT show the other user's Saved items or RSVP'd events. (Q1.11.2)
    *   *Privacy:* If the user has set their profile to private, non-followers might see a limited view (e.g., just avatar, name, bio, follow button, and a "This account is private" message).

### 3.3 Editing Profile Details
*   **Trigger:** User wants to modify their profile information.
*   **User Action:** User taps the "Edit Profile" action on their own profile screen. (Q1.11.3)
*   **UI State:** Opens an editing interface (likely a dedicated screen or modal).
    *   **Editable Fields:** Avatar (opens image picker), Name (text input), Bio (text input, with character limit), Interests (tag selector interface). (Q1.11.3)
*   **User Action:** User modifies fields and saves changes.
*   **System Action:** API call to update profile information.
*   **UI Feedback:** Profile screen updates with new information. Confirmation Snackbar ("Profile updated").

### 3.4 Following / Unfollowing Users
*   **Trigger:** User is viewing another user's profile.
*   **User Action:** User taps the "Follow" button.
*   **UI State (Optimistic):** Button state changes to "Following".
*   **System Action:** API call to create follow relationship.
*   **UI Feedback (Failure):** Button reverts to "Follow", potential Snackbar error.
*   **User Action:** User taps the "Following" button.
*   **UI State:** Confirmation prompt? ("Unfollow @username?") Button might change to "Unfollow" on tap, then require confirmation.
*   **User Action:** Confirms unfollow.
*   **UI State (Optimistic):** Button state changes to "Follow".
*   **System Action:** API call to remove follow relationship.
*   **UI Feedback (Failure):** Button reverts to "Following", potential Snackbar error.

### 3.5 Viewing Followers / Following Lists
*   **Trigger:** User wants to see who follows them or whom they follow.
*   **User Action:** User taps the "Followers" or "Following" count/label on their own profile or another user's profile.
*   **UI State:** Opens a screen displaying a list of users (avatar, name).
    *   *Access Control:* Users can view these lists for themselves and for other public profiles. Private profiles might restrict viewing these lists to followers only. (Q1.11.5)
*   **User Action:** User can tap on a user in the list to navigate to their profile.

### 3.6 Viewing Private Activity Trail
*   **Trigger:** User wants to review their own past interactions.
*   **User Action:** User navigates to a dedicated "Activity" or similar section, likely accessible via their own profile tab structure. (Q1.11.6)
*   **UI State:** Displays lists or sections showing content the user has Liked, Commented on, or RSVP'd to. (Q1.11.6)
    *   *Privacy:* This section is strictly private and only visible to the logged-in user.

### 3.7 Badge Showcase (Out of Scope V1)
*   While an "Achievements" tab might exist on the profile, it is empty as there is no badge system in V1. (Q1.11.7)

*   **Analytics:** [`flow_step: student.profile.view_own`], [`flow_step: student.profile.view_other {target_user_id}`], [`flow_step: student.profile.edit_initiated`], [`flow_step: student.profile.edit_saved`], [`flow_step: student.profile.follow {target_user_id}`], [`flow_step: student.profile.unfollow {target_user_id}`], [`flow_step: student.profile.view_followers {target_user_id}`], [`flow_step: student.profile.view_following {target_user_id}`], [`flow_step: student.profile.view_activity_log`], [`flow_error: student.profile.edit_failed`], [`flow_error: student.profile.follow_failed`], [`flow_error: student.profile.unfollow_failed`]

---

## 4. State Diagrams

*   (Diagram: View Own Profile -> Edit -> Save Changes)
*   (Diagram: View Other Profile -> Follow -> [Unfollow])
*   (Diagram: View Profile -> View Followers/Following List -> View User)
*   (Diagram: View Own Profile -> View Activity Log)

---

## 5. Error States & Recovery

*   **Trigger:** Error loading profile data (own or other).
    *   **State:** Error message displayed.
    *   **Recovery:** Retry mechanism.
*   **Trigger:** Error saving profile edits.
    *   **State:** Error message (Snackbar), changes not saved.
    *   **Recovery:** User retries saving.
*   **Trigger:** Error processing follow/unfollow action.
    *   **State:** UI reverts optimistic state, error message (Snackbar).
    *   **Recovery:** User retries action.
*   **Trigger:** Trying to view restricted content on a private profile.
    *   **State:** Content is hidden, potentially showing a "Private Account" message.
    *   **Recovery:** User can request to follow (if not already following/requested).

---

## 6. Acceptance Criteria

*   Users can view their own profile with correct sections (Q1.11.1).
*   Users can view other profiles with appropriate public information (Q1.11.2).
*   Users can edit specified profile fields (Q1.11.3).
*   Follow/unfollow actions function correctly with optimistic UI and error handling (Q1.11.4).
*   Follower/Following lists are viewable with correct access controls (Q1.11.5).
*   Private activity trail is accessible and displays correct interaction history (Q1.11.6).
*   Achievements/Badge section exists but is empty (Q1.11.7).
*   Profile privacy settings correctly restrict views.

---

## 7. Metrics & Analytics

*   **Profile View Rate:** (Own vs. Other).
*   **Profile Edit Rate:** % of users who edit profile post-onboarding.
*   **Follow Rate:** Average follows per user.
*   **Follower/Following List View Rate.**
*   **Activity Log View Rate.**
*   **Analytics Events:** (Listed in Sequence section)

---

## 8. Design/UX Notes

*   Profile layout needs to be clean and scannable, balancing information density.
*   Clear distinction between own profile view (with edit controls) and other profile views.
*   Make follow/unfollow actions clear and provide good feedback.
*   Privacy settings need to be respected consistently across all profile views and lists.
*   The private activity log (Q1.11.6) could be a useful tool for users to rediscover content.

---

## 9. API Calls & Data

*   **Get Profile API Call:**
    *   **Request:** User ID (viewer), Target User ID.
    *   **Response:** Profile Object (depending on viewer==target and privacy settings: Name, Avatar, Bio, Interests, Follower/Following Counts, IsFollowing Status, [Tabs: Posts, Saved, Spaces, Events, Activity?]).
*   **Update Profile API Call:**
    *   **Request:** User ID, Updated Fields (Name, Bio, Avatar URL?, Interests List).
    *   **Response:** Success/Failure, [Updated Profile Object?].
*   **Follow User API Call:**
    *   **Request:** User ID (follower), Target User ID (followed).
    *   **Response:** Success/Failure.
*   **Unfollow User API Call:**
    *   **Request:** User ID (follower), Target User ID (followed).
    *   **Response:** Success/Failure.
*   **Get Followers/Following API Call:**
    *   **Request:** User ID (viewer), Target User ID, List Type (followers/following), [Pagination Info].
    *   **Response:** List of User Summary objects (User ID, Name, Avatar), Pagination Info.
*   **Get Activity Log API Call:**
    *   **Request:** User ID, Activity Type (Likes/Comments/RSVPs), [Pagination Info].
    *   **Response:** List of relevant Content/Event objects or references.

---

## 10. Open Questions (Resolved for V1)

1.  **Own Profile Sections V1:** What info/sections on own profile?
    *   ✅ **A1.11.1:** Avatar, Name, Bio, Interests. Tabs/Sections: Posts, Saved, Joined Spaces, RSVP'd Events. Settings gear. Empty Achievements tab.
2.  **Other Profile Visibility V1:** What info visible on others' profiles?
    *   ✅ **A1.11.2:** Public: Avatar, Name, Bio, Posts. Follow button. No Saved/RSVP'd. Private profiles limit view.
3.  **Editable Fields V1:** What can users edit post-onboarding?
    *   ✅ **A1.11.3:** Avatar, Name, Bio, Interests. Entry via "Edit Profile".
4.  **Follow/Unfollow Action:** How performed? Feedback?
    *   ✅ **A1.11.4:** Tap button on profile. Optimistic UI change. Confirmation prompt for unfollow.
5.  **Follower/Following Lists V1:** Can users view these lists? For others?
    *   ✅ **A1.11.5:** Yes, can view own and others' lists (unless profile is private).
6.  **Private Activity Trail V1:** Is there a private log of user's interactions?
    *   ✅ **A1.11.6:** Yes, private-only view of Likes, Comments, RSVPs. Accessed via own Profile.
7.  **Badge Showcase V1:** Dedicated section for badges?
    *   ✅ **A1.11.7:** "Achievements" tab exists but is empty. No badges in V1.

**All questions resolved for V1.** 