# HIVE UI

[![Flutter Test](https://github.com/your-username/hive_ui/actions/workflows/flutter-test.yml/badge.svg)](https://github.com/your-username/hive_ui/actions/workflows/flutter-test.yml)

A beautiful, modern Flutter application for event discovery and social networking.

## Overview

HIVE UI is a Flutter-based mobile application that helps users discover, create, and engage with events. The application follows a clean architecture pattern and embraces a sleek dark theme with gold accents for a premium feel.

## Features

- **Event Discovery**: Browse events categorized by time (Today, This Week, Upcoming)
- **Advanced Filtering**: Filter events by category, source, and search terms
- **User Events**: Create, RSVP to, and repost events
- **Social Integration**: Connect with clubs and event organizers
- **Clean UI**: Enjoy a beautiful glassmorphic design with fluid animations
- **Real-time Messaging**: Chat with users and groups with instant message delivery
- **Deep Linking**: Open various content types within the app

## Architecture

The application follows a clean architecture pattern with clear separation of concerns:

### Layers

- **Presentation**: UI components, screens, and state management
- **Domain**: Business logic and entity models
- **Data**: Repositories, services, and data sources

### State Management

- **Riverpod**: Used for dependency injection and state management
- **AsyncValue**: Handles loading, error, and data states
- **StateNotifierProvider**: Manages complex state with operations

## Project Structure

```
lib/
├── components/           # Reusable UI components
├── extensions/           # Extension methods
├── models/               # Data models and entities
├── pages/                # Screen implementations
├── providers/            # Riverpod providers
├── services/             # Business logic and API integration
├── theme/                # App theme and styling
└── main.dart             # Application entry point
```

## UI Components

### Feed Structure

The main feed is organized into time-based sections:

1. **Today's Events**: Horizontal scrollable list of today's events
2. **This Week's Events**: Horizontal scrollable list of events this week
3. **Upcoming Events**: Vertical list of future events

### State Handling

The application handles various states gracefully:

- **Loading State**: Animated skeleton screens during data fetching
- **Error State**: User-friendly error messages with retry options
- **Empty State**: Informative placeholders when no content is available

### UI Patterns

- **Glassmorphism**: Frosted glass effect for cards and modals
- **Gold Accents**: Highlights important actions and selected items
- **Dark Theme**: Sleek black backgrounds with high contrast elements

## Getting Started

### Prerequisites

- Flutter SDK (2.8.0 or higher)
- Dart SDK (2.15.0 or higher)
- Android Studio or VS Code with Flutter plugins

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/hive_ui.git
   ```

2. Install dependencies:
   ```
   cd hive_ui
   flutter pub get
   ```

3. Run the application:
   ```
   flutter run
   ```

### Windows Build with Firebase

Building for Windows with Firebase requires additional steps due to compatibility issues with the Firebase plugins:

1. Clean and get dependencies:
   ```
   flutter clean
   flutter pub get
   ```

2. Run the Firebase fix script:
   ```
   cd windows
   .\fix_firebase_windows.bat
   ```
   
   This script addresses common issues with Firebase plugins when building for Windows, including:
   - Incorrect CMake configurations
   - C++ variant compatibility issues
   - Deprecated standard conversion warnings

3. Build the Windows application:
   ```
   flutter build windows
   ```

See `windows/README.md` for detailed information about the fixes and troubleshooting.

## Development Workflow

### Adding New Features

1. Create model classes in the `/models` directory
2. Implement services in the `/services` directory
3. Create providers in the `/providers` directory
4. Build UI components in the `/components` directory
5. Assemble screens in the `/pages` directory

### Code Style

The project follows the Dart style guide with some additional conventions:

- Use `PascalCase` for classes and enums
- Use `camelCase` for variables, functions, and methods
- Use `snake_case` for file names
- Add documentation comments for all public APIs

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- [Flutter](https://flutter.dev/)
- [Riverpod](https://riverpod.dev/)
- [Material Design](https://material.io/design)

### Messaging Features

The app now includes a full-featured real-time messaging system powered by Firebase:

- **Real-time updates**: Messages appear instantly without needing to refresh
- **Chat creation**: Create direct messages or group chats
- **Read receipts**: See when messages have been read by recipients
- **Typing indicators**: See when someone is typing a response
- **Media sharing**: Share images, videos, and files in conversations
- **Message reactions**: React to messages with emojis

### Deep Linking

HIVE supports deep linking to various content types within the app:

- Events: `hive://events/{id}` - Open event details
- Spaces: `hive://spaces/{type}/spaces/{id}` - Open space details
- Profiles: `hive://profiles/{id}` - View a user profile
- Chats: `hive://messages/chat/{id}` - Open direct chat
- Group Chats: `hive://messages/group/{id}` - Open group chat
- Posts: `hive://posts/{id}` - View a specific post
- Search: `hive://search?q={query}` - Open search results
- Organizations: `hive://organizations/{id}` - View organization details
- Event Check-ins: `hive://events/{id}/check-in` - Go to event check-in

Links can be shared externally and will open the app to the correct content. Authentication is required for all deep links.
