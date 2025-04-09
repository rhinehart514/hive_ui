# HIVE Essential User Flow Tests

This directory contains end-to-end tests for critical user flows in the HIVE application. These tests ensure that core functionalities continue to work as expected across app updates.

## Test Plan

### 1. Registration and Onboarding Flow
- Account creation with email
- Email verification
- Profile setup (basic information)
- Interest selection
- Initial space recommendations

### 2. Profile Management Flow
- View profile
- Edit profile information
- Change profile visibility settings
- Upload profile picture
- View and manage analytics

### 3. Space Discovery and Joining
- Browse spaces
- Search for spaces by name/category
- View space details
- Join a space
- Leave a space
- View space members and message board

### 4. Event Creation and RSVP Process
- Create a new event
- Edit event details
- RSVP to an event
- Cancel RSVP
- View event attendees
- Share an event

### 5. Content Creation and Sharing
- Create a post
- Upload media to post
- Edit post
- Delete post
- Repost content
- Interact with content (like, comment)

## Implementation Strategy

For each user flow:
1. Create a separate test file
2. Implement the test using the `integration_test` package
3. Include screenshots at key points in the flow
4. Add assertions to verify expected behavior
5. Handle test cleanup (account deletion, data cleanup)

## Running Tests

To run all integration tests:
```
flutter test integration_test
```

To run a specific test:
```
flutter test integration_test/onboarding_test.dart
```

## Best Practices

- Keep tests independent from each other
- Clean up any created test data
- Use descriptive test names
- Add comments for complex test logic
- Take screenshots for visual verification
- Test both happy paths and error conditions 