# Suggested Friends Feature Implementation

## Overview
The suggested friends feature recommends potential friends to users based on matching criteria like major, residence, or shared interests. The implementation follows clean architecture principles and HIVE UI brand aesthetic guidelines.

## Architecture

### Domain Layer
- **Entities**: `SuggestedFriend` extends the base `Friend` model with additional matching criteria information.
- **Repositories**: The `SuggestedFriendRepository` interface defines methods for fetching suggested friends.
- **Use Cases**: `GetSuggestedFriendsUseCase` encapsulates the business logic for retrieving suggested friends.

### Data Layer
- **Repository Implementation**: `SuggestedFriendRepositoryImpl` implements the repository interface using Firestore.
- **Data Sources**: Firebase Firestore is used to query and filter users based on matching criteria.

### Presentation Layer
- **Providers**: 
  - `suggestedFriendsProvider`: Main provider for suggested friends
  - `filteredSuggestedFriendsProvider`: Provider for filtering by criteria
  - `feedSuggestedFriendsProvider`: Specialized provider for feed integration
  - `feedSingleSuggestedFriendProvider`: Provider for individual friend card in feed
- **Widgets**: 
  - `SuggestedFriendCard`: Displays an individual suggested friend with matching criteria.
  - `FeedSuggestedFriendCard`: Compact version optimized for the main feed.
  - `FeedSuggestedFriendsItem`: Container component that manages state for feed integration.

### Integration
- **Profile Tab Integration**: Enhanced `FriendsTab` displays friend count and suggested friends
- **Feed Integration**: `FeedSuggestedFriendsItem` appears periodically in the main content feed
- **Navigation**: Route `/profile/suggested-friends` provides access to full friend suggestions

## Design Implementation

The UI design follows HIVE's brand aesthetic principles:

1. **Color Palette**: Uses the HIVE color scheme with black backgrounds, white text, and gold accents.
2. **Typography**: Utilizes the Inter font with proper size hierarchy and letter spacing.
3. **Depth & Elevation**: Implements subtle shadows and card elevation following the brand guidelines.
4. **Glassmorphism**: Card backgrounds use refined glassmorphism with proper blur values and border treatments.
5. **Interactive Elements**: Yellow is reserved for interaction points like the match criteria highlight.
6. **Motion & Haptics**: Includes appropriate haptic feedback for interactions.

## Matching Criteria Logic

Suggested friends are sorted by three primary criteria:

1. **Same Major**: Connects students studying the same field.
2. **Same Residence**: Suggests people living in the same residence halls or areas.
3. **Shared Interests**: Recommends users with common interests or hobbies.

## Integration Points

### Main Feed Integration
- The `FeedSuggestedFriendCard` provides a streamlined card for the main content feed
- Random suggestions appear between content items to encourage friend connections
- Utilizes `feedSingleSuggestedFriendProvider` to manage loading states and caching

### Profile Tab Integration
- Updated `FriendsTab` displays numerical friend count with proper pluralization
- Shows status message for users with existing friends
- Maintains suggested friends section at bottom of tab
- "View All Suggestions" button links to full suggestions screen

## Friend Request Integration

The suggested friend cards integrate with the existing friend request system:

- Checks if users are already friends or have pending requests.
- Sends friend requests via the `sendFriendRequestProvider`.
- Shows appropriate UI states for "Request" vs. "Requested" vs. "Friends".

## Performance Considerations

- Implements pagination and query limits to minimize data transfer.
- Uses query filtering at the database level for efficiency.
- Handles loading, empty, and error states appropriately.
- Implements proper caching strategies with Riverpod providers.

## Future Enhancements

Potential improvements for future iterations:

1. Advanced matching algorithms with weighted criteria.
2. Mutual friends suggestions.
3. Course/class-based matching.
4. AI-powered recommendations based on user behavior.
5. "People you may know from..." contextual suggestions. 