# HIVE UI Feed System Documentation

## Overview

The HIVE UI Feed System is a comprehensive solution for delivering personalized, engaging content to users. It combines multiple content types (events, reposts, inspirational messages, space recommendations, and HIVE lab items) into a cohesive social feed experience that gets more relevant over time as users interact with it.

## Key Components

The feed system follows clean architecture principles and consists of four main components:

### 1. FeedService (Data Layer)
- **Location**: `lib/services/feed/feed_service.dart`
- **Responsibility**: Handles data operations like fetching, caching, and filtering events.
- **Key Features**:
  - Implements caching with expiration to improve performance
  - Provides pagination for efficient data loading
  - Tracks user interactions for personalization

### 2. FeedPrioritizer (Domain Layer)
- **Location**: `lib/services/feed/feed_prioritizer.dart`
- **Responsibility**: Analyzes and organizes feed content for optimal engagement.
- **Key Features**:
  - Scores and ranks events based on multiple personalization factors
  - Distributes different content types throughout the feed
  - Generates personalized reposts from popular events

### 3. FeedAnalytics (Data Layer)
- **Location**: `lib/services/feed/feed_analytics.dart`
- **Responsibility**: Tracks user interactions to enable feed personalization.
- **Key Features**:
  - Records event views, interactions, and feed refreshes
  - Aggregates category, organizer, and tag preferences
  - Provides engagement statistics for optimization

### 4. FeedController (Presentation Layer)
- **Location**: `lib/controllers/feed_controller.dart`
- **Responsibility**: Coordinates between UI, state management, and services.
- **Key Features**:
  - Orchestrates the data flow between services and UI
  - Maintains feed state via Riverpod
  - Processes user actions (RSVP, search, etc.)

## Personalized Relevance Scoring System

The FeedPrioritizer implements a sophisticated scoring algorithm that considers multiple factors:

### Time Relevance (0-10 points)
- Events happening today: 10 points
- Events in next 7 days: 3-9 points (based on proximity)
- Events beyond 7 days: 0-3 points (declining with distance)
- Past events: 1-2 points (recent past events score higher)

### Popularity (0-5 points)
- Based on attendance count (higher attendance = higher score)

### Interest Match (0-8 points)
- Category matches user interests: up to 5 points
- Tag matches user interests: up to 3 points
- Historical category interaction data: variable points

### Organizer/Space Match (0-6 points)
- Events from spaces the user has joined: 6 points
- Historical organizer interaction data: variable points

### Educational Relevance (0-4 points)
- Major relevance: up to 2 points (matching the user's field of study)
- Year relevance: up to 2 points (content targeted to user's academic year)

### Location Relevance (0-3 points)
- Same building/area as user's residence: 3 points
- Same campus area: 1.5 points

### Social Factors (0-5 points)
- User has RSVPed to the event: 5 points
- Friends attending the event: up to 3 points (scales with number of friends)

### Boosted Status (0-3 points)
- Officially promoted events: 3 points

## Content Mixing Strategy

The feed combines multiple content types for an engaging experience:

1. **Primary Content**: Events relevant to the user
2. **Social Content**: Reposts from other users
3. **Discovery Content**: Space recommendations based on interests
4. **Inspirational Content**: Motivational messages and milestones
5. **Product Updates**: HIVE Lab items for feature announcements

These are distributed throughout the feed in a carefully designed pattern that ensures variety while prioritizing the most relevant content.

## Integration with UI

The MainFeed widget (`lib/pages/main_feed.dart`) integrates all these components to display the feed. It uses the FeedController to:

1. Initialize and load the feed
2. Handle user interactions (RSVP, search, etc.)
3. Implement infinite scrolling
4. Track feed view time for analytics

## Usage Example

```dart
// In a widget that needs access to the feed
final feedController = ref.read(feedControllerProvider);

// Initialize the feed
@override
void initState() {
  super.initState();
  feedController.initializeFeed();
}

// Refresh the feed
void onRefresh() async {
  await feedController.refreshFeed(showLoading: true);
}

// RSVP to an event
void onRsvp(Event event) async {
  await feedController.rsvpToEvent(event);
}

// Track analytics when leaving
@override
void dispose() {
  feedController.dispose(); // This tracks view time
  super.dispose();
}
```

## Future Enhancements

1. **Machine Learning Integration**: Improve personalization using ML-based predictions
2. **A/B Testing Framework**: Test different feed algorithms and presentations
3. **Content Diversity Controls**: Allow users to adjust content type ratios
4. **Expanded Content Types**: Add polls, questions, and user-generated content
5. **Enhanced Social Features**: Comments, reactions, and sharing options 