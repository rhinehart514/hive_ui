# HIVE Main Feed Redesign Specification

## Overview
This document outlines the redesign of the HIVE main feed experience, focusing on mobile-first design principles, integration with existing database structures, and a premium UX aligned with HIVE's brand aesthetic.

---

## 1. Design Philosophy & Database Integration

### Brand Aesthetic
- **Dark theme** with **gold accents** as focal points (using `AppColors.gold` and `AppColors.cardBackground`)
- **Glassmorphism** for elevated components (leveraging existing `glassmorphism_guide.dart`)
- **Typography**: Outfit for headlines, Inter for body text (from existing implementation)
- **Rich blacks** (`Color(0xFF121212)` for backgrounds, not pure black) for better depth perception

### Database Integration Points
- **Events collection** in Firestore (`events/[eventId]`) 
- **Spaces collection** for community recommendations (`spaces/[spaceId]`)
- **User interactions** stored in `interactions` collection for personalization
- **Feed state** managed through existing `FeedNotifier` and `FeedController`

### Inspirations
- **Instagram's** content density and infinite scroll
- **Spotify's** card-based UI with clear visual hierarchy
- **Discord's** dark mode implementation with accent colors
- **Apple Music's** glassmorphism and subtle animations

---

## 2. Feed Structure & Components

### Feed Header
```dart
// Integration with existing FeedState
// Header reacts to scroll position using _blurController
Container(
  decoration: BoxDecoration(
    color: Colors.black.withOpacity(0.7),
    // Use existing glassmorphism extension
    boxShadow: GlassmorphismGuide.kHeaderShadow,
  ),
  child: SafeArea(
    // Header content
  ),
)
```

### Content Stream Implementation
```dart
// Leveraging existing FeedController for data fetching
CustomScrollView(
  controller: _scrollController,
  physics: const BouncingScrollPhysics(),
  slivers: [
    // Feed content based on FeedState
    _renderFeedContent(feedState),
  ],
)

// Database connection through FeedState
Widget _renderFeedContent(FeedState feedState) {
  // Render appropriate content based on feed state
  // Used with: ref.watch(feedStateProvider)
}
```

### Floating Action Button
- **Position**: 32dp above nav bar using `FloatingActionButtonLocation.centerDocked`
- **Style**: Gold circular FAB with white plus icon
- **Integration**: Connect to existing navigation and event creation flow
- **Animation**: Scale animation tied to scroll controller

### Mobile-Optimized Pull-to-Refresh
- **RefreshIndicator** with custom styling to match HIVE brand
- **Connection**: Calls `feedController.refreshFeed()` method
- **Performance**: Throttled refresh calls to prevent API hammering

---

## 3. Card Components & Database Connectivity

### Event Card
```dart
// EventCard connects to Event model from database
// lib/models/event.dart is the source model
class EventCard extends StatelessWidget {
  final Event event; // Direct connection to database model
  
  // Used with events from FeedState.allEvents or FeedState.forYouEvents
}
```

**Key Features**:
- **Elevation hierarchy** using Flutter's Material elevation system
- **Rich image area** loading from `event.imageUrl` with caching
- **Data display**:
  - Title from `event.title`
  - Date/time from `event.startDate` formatted with existing utilities
  - Location from `event.location`
  - Organizer from `event.organizerName`
  - Category/tags from `event.tags` and `event.category`

### Space Recommendation Card
```dart
// SpaceCard connects to Space model
// lib/models/space.dart is the source model
class SpaceRecommendationCard extends StatelessWidget {
  final Space space; // Direct connection to database model
  
  // Used with spaces from FeedState.spaceRecommendations
}
```

### User Interaction Tracking
```dart
// Leverage existing InteractionService to track user behavior
void _logEventView(Event event) {
  InteractionService.logInteraction(
    userId: currentUser.id,
    entityId: event.id,
    entityType: EntityType.event,
    action: InteractionAction.view,
  );
}
```

---

## 4. Mobile-First Interaction Design

### Gesture System
- **Tap**: View details (navigate to `EventDetailsPage`)
- **Long press**: Quick actions menu using `showModalBottomSheet`
- **Double tap**: Quick RSVP (updating `event.isRsvped` in database)
- **Swipe actions**: Using `Dismissible` widget for quick interactions

### Mobile Transitions
```dart
// Hero animations connecting feed to details
Hero(
  tag: 'event_${event.id}',
  child: EventImage(url: event.imageUrl),
)

// Navigation with shared element transition
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => EventDetailsPage(
      event: event,
      heroTag: 'event_${event.id}',
    ),
  ),
);
```

### Haptic Feedback Implementation
```dart
// Use HapticFeedback for tactile response on mobile
void _handleRsvp(Event event) {
  HapticFeedback.mediumImpact();
  _profileNotifier.rsvpToEvent(event);
  
  // Update local UI optimistically while database updates
  setState(() => _localRsvpState[event.id] = true);
}
```

---

## 5. Performance Optimization for Mobile

### Rendering Efficiency
- **Sliver-based lists** for memory efficiency with large datasets
- **CachedNetworkImage** for image loading and caching
- **Debounced search** to prevent excessive database queries
- **Pagination** using `FeedState.pagination` properties

### Database Query Optimization
```dart
// Leverage existing Firebase query optimization
// Use compound queries with proper indexing
final optimizedQuery = FirebaseFirestore.instance
    .collection('events')
    .where('startDate', isGreaterThan: DateTime.now())
    .orderBy('startDate')
    .limit(feedState.pagination.pageSize);
```

### Perceived Performance Techniques
- **Skeleton loading states** during initial load
- **Optimistic UI updates** before database confirmation
- **Background prefetching** during idle moments
- **Progressive image loading** (blur up technique)

---

## 6. Personalization Engine Integration

### Discovery Algorithm
- **Integration**: Connect to `FeedPersonalizationEngine` for content scoring
- **Database**: Read user interests from `UserInterests` collection
- **UI indicators**: Visual clues for personalized content in feed

### User Preference Management
```dart
// Store and retrieve user preferences
// Using existing UserPreferencesService
void _saveUserFeedPreferences() {
  _prefsService.setFeedPreferences(
    FeedPreferences(
      categories: selectedCategories,
      dateRange: selectedDateRange,
      sources: selectedSources,
    ),
  );
}
```

---

## 7. Empty & Error States

### Empty Feed UI
```dart
// Empty state with branding and CTA
Widget _buildEmptyFeedContent() {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.event_note, size: 64, color: AppColors.gold),
        Text('Your feed is waiting to be filled',
          style: AppTheme.heading4,
        ),
        ElevatedButton(
          onPressed: _feedController.refreshFeed,
          child: Text('Discover Events'),
        ),
      ],
    ),
  );
}
```

### Error Handling Strategy
```dart
// Error state with retry capability
// Connected to FeedState.errorMessage
Widget _buildErrorState(String message) {
  return ErrorStateWidget(
    message: message,
    onRetry: _feedController.refreshFeed,
  );
}
```

---

## 8. Mobile Accessibility Considerations

- **Touch targets**: Minimum 48dp size (Flutter's `kMinInteractiveDimension`)
- **Text scaling**: Support for OS text size settings
- **Color contrast**: Meet WCAG AA standards (validate with Contrast Analyzer)
- **Screen reader support**: Semantic labels for all interactive elements

---

## 9. Implementation Guidelines & Database Connectivity

### Component Architecture
```dart
// Example implementation pattern for feed items
Widget _buildFeedItem(FeedItem item) {
  // Pattern match on item type from database
  if (item is EventItem) {
    return EventCard(
      event: item.event,
      onTap: () => _navigateToEventDetail(item.event),
      onRsvp: () => _handleRsvp(item.event),
      onShare: () => _shareEvent(item.event),
    );
  } else if (item is SpaceRecommendation) {
    return SpaceRecommendationCard(
      space: item.space,
      onJoin: () => _joinSpace(item.space),
    );
  }
  return const SizedBox.shrink();
}
```

### State Management
- **StreamProvider** for reactive updates from Firestore
- **StateNotifierProvider** for complex state with operations
- **Provider scoping** to prevent unnecessary rebuilds

### Database Query Strategy
```dart
// Efficient data fetching strategy
Future<void> _initializeFeed() async {
  // 1. Load cached data first for instant display
  final cachedEvents = await _feedController.getCachedEvents();
  
  // 2. Update UI with cached content
  if (cachedEvents.isNotEmpty) {
    _feedStateNotifier.updateEvents(cachedEvents, isFromCache: true);
  }
  
  // 3. Fetch fresh data in background
  _feedController.refreshFeed();
}
```

---

## 10. Technical Requirements & Mobile Considerations

### Device Support
- **Target platforms**: iOS 13+, Android 8.0+
- **Screen sizes**: Optimize for 4.7" to 6.7" displays
- **Performance target**: 60fps smooth scrolling on mid-range devices

### Technical Dependencies
- **Firebase SDK**: For Firestore database integration
- **Cached Network Image**: For optimized image loading
- **Flutter Riverpod**: For state management
- **Shared Preferences**: For local preferences storage

### Development Workflow
1. Create UI components with mock data
2. Implement database integration via providers
3. Add interaction handling and animations
4. Implement performance optimizations
5. Add error handling and edge cases

---

## Implementation Timeline

### Phase 1: Core Feed Structure
- Header component with search integration
- Basic feed rendering with existing database models
- Empty and loading states

### Phase 2: Card Components
- Enhanced EventCard with proper data binding
- Space recommendation cards
- Interaction tracking integration

### Phase 3: Interactions & Polish
- Gesture system implementation
- Animation and transition refinement
- Final performance optimization

---

## Key Technical Constraints

1. **Database structure**: Must work with existing Firestore collections
2. **State management**: Must integrate with Riverpod providers
3. **Performance**: Must maintain <100ms response time for interactions
4. **Battery usage**: Minimize background processing and network calls
5. **Offline support**: Basic functionality when offline using cached data

---

*This specification is subject to review and iteration during implementation. All components must be tested on actual mobile devices before deployment.* 