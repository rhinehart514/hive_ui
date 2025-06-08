# Spaces Feature

This directory contains the implementation of the Spaces feature in HIVE UI, following clean architecture principles.

## Architecture

The spaces feature is organized following clean architecture:

```
spaces/
  ├── data/           # Data sources, repositories, and DTOs (future implementation)
  ├── domain/         # Entities and business logic 
  ├── presentation/   # UI and state management
  │    ├── pages/     # Screen implementations
  │    ├── widgets/   # Reusable UI components 
  │    ├── providers/ # State management with Riverpod
```

## Implementation

### Data Layer

Uses Firestore directly through the `SpaceService` to fetch and manage spaces.

### Domain Layer

Utilizes the existing domain models:
- `Space` - Represents a space/community
- `SpaceMetrics` - Contains metrics and analytics data for spaces

### Presentation Layer

- **Controllers**: `SpacesController` handles UI logic and user interactions
- **Providers**: Various providers to manage state with Riverpod
- **UI Components**: Reusable widgets like `SpaceCard` and `SpaceGrid`
- **Pages**: `SpacesPage` - Main page implementing the UI

## Key Features

1. **Real-time Firestore Integration**: Spaces are loaded directly from Firebase Firestore
2. **Efficient Caching**: Optimized data loading with minimal Firestore reads
3. **Search Functionality**: Live searching of spaces by name and tags
4. **Tab-based Navigation**: "My Spaces" and "Discover" tabs with proper state management
5. **Error Handling**: Graceful error states and loading indicators

## Usage

The Spaces feature is accessible through the main navigation. It allows users to:

- Browse available spaces
- Join spaces of interest
- View their joined spaces
- Search for specific spaces

## Analytics

User interactions with spaces are tracked for analytics purposes:
- Space views
- Space joins
- Tab changes
- Search queries

## Future Enhancements

1. Implement complete data layer with repository pattern
2. Add space creation functionality
3. Enhance search with filtering options
4. Add space recommendations based on user interests
5. Implement space administrators dashboard 