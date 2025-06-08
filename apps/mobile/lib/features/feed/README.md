# HIVE UI Feed

## Overview
The Feed tab is one of the three main tabs in the HIVE application. It serves as the primary discovery mechanism for users, showcasing events, space activity, and user interactions in a dynamic feed format.

## Key Components

### Feed Strip
- Horizontal scrollable strip at the top of the feed
- Shows dynamic content like Space Heat cards, Time Markers, and Friend Motion cards
- Implements smooth animations and haptic feedback
- Uses glassmorphism design for a premium feel

### Feed Content Cards
- Event cards with glassmorphism styling
- Repost cards showing shared events with attribution
- Quote cards with commentary
- Space suggestion cards
- Friend Motion cards showing social activity

### Engagement Actions
- RSVP functionality for events
- Repost mechanism with attribution
- Quote functionality with commentary
- Boost action for builders (special role)

### Feed Intelligence
- Content ranking algorithm
- Personalization based on user Trail
- Time-sensitive content prioritization

## Implementation Details

### State Management
- Uses Riverpod for state management
- Implements providers for different content types and actions
- Properly separates presentation, domain, and data layers

### User Experience
- Consistent interaction patterns
- Haptic feedback on all interactions
- Visual feedback for all actions
- Role-based permissions (builder vs. regular user)

### Data Flow
- Stream-based feed repository
- Efficient data fetching with pagination
- Proper caching and refresh mechanisms

## Usage

### Feed Page
The main feed page is the entry point for users and is set as the default tab. It displays a dynamic list of content cards and provides various interaction options:

```dart
FeedPage(
  onNavigateToEvent: (event) => context.push('/events/${event.id}'),
)
```

### Engagement Components
Users can interact with feed content through:

- `RsvpButton` - For attending events
- `RepostButton` - For sharing content
- `QuotePostButton` - For sharing with commentary
- `BoostButton` - For builders to highlight content

## Architecture

The feed feature follows clean architecture principles:

- `data/` - Repositories, DTOs, and services
- `domain/` - Entities, models, and business logic
- `presentation/` - Widgets, pages, and providers

## Future Improvements

- Add additional card variants for special events
- Implement more advanced feed algorithms
- Add better offline support
- Enhance analytics and tracking 