# Social Profile Data Merging

This document explains how social authentication profile data is merged with user profiles in the Hive UI app.

## Overview

When users sign in with social providers (Google, Apple, Facebook), we receive profile information from these providers that we want to use to enhance the user's profile in our app. The social profile data merging system allows us to intelligently combine this data with existing user profiles.

## Components

The system consists of the following components:

1. **SocialAuthHelper**: A utility class that handles profile data merging
2. **FirebaseAuthRepository**: Implementation of social authentication methods
3. **UserPreferencesService**: Local storage for user profiles

## How It Works

### 1. Data Collection from Social Providers

Each social provider returns different data:

**Google:**
- Display name
- Email
- Profile photo URL

**Apple:**
- First name
- Last name
- Email (only on first sign-in)

**Facebook:**
- Display name
- Email
- Profile photo URL

### 2. Merging Strategy

The merging process follows these rules:

1. **New Users**: A full profile is created with:
   - Basic information (display name, email, photo)
   - Default values for required fields (year, major, residence)
   - Account tier based on email domain (.edu emails are verified)

2. **Existing Users**: Profile is updated selectively:
   - Display name: Only updated if current value is empty or default
   - Profile image: Only updated if current value is empty
   - Email: Only updated if current value is empty
   - First/last name: Only updated if current values are empty
   - Authentication provider: Always added to the list of providers

### 3. Storage

The merged profile is stored in two places:

1. **Firestore**: The primary source of user data
2. **Local Storage**: For offline access and faster loading

## Implementation Details

### Key Methods

**mergeSocialProfileData():**
- Checks if user has an existing profile
- Creates a new profile if needed
- Merges and updates fields based on the rules above
- Updates both Firestore and local storage

**updateLocalProfileCache():**
- Updates the local copy of user profile data
- Creates a new profile or updates an existing one

### Error Handling

The system includes robust error handling:
- Firebase errors are caught and translated to user-friendly messages
- Network issues are handled without blocking the auth flow
- Local storage is used as a fallback when Firestore is unavailable

## Usage Example

```dart
// Get additional user information from Google
final Map<String, dynamic> socialData = {
  'displayName': googleUser.displayName,
  'email': googleUser.email,
  'photoUrl': googleUser.photoUrl,
  'provider': 'google.com',
};

// Merge the social profile data with the user's profile
await SocialAuthHelper.mergeSocialProfileData(
  user: user,
  socialData: socialData,
  firestore: _firestore,
  createUserProfile: _createUserProfile,
  saveUserProfileLocally: _saveUserProfileLocally,
);
```

## Benefits

1. **Complete User Profiles**: Users don't need to manually enter all their information
2. **Non-Destructive**: Doesn't overwrite user-customized data
3. **Efficient**: Only updates what's needed, avoiding unnecessary writes
4. **Resilient**: Works across network interruptions and app restarts

## Future Improvements

- Support for more social providers (Twitter, LinkedIn, etc.)
- More intelligent merging of profile photos (quality comparison)
- Enhanced verification based on social provider reputation
- User control over which social data to import 