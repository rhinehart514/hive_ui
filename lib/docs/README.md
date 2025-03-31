# HIVE UI Documentation

Welcome to the HIVE UI documentation directory. This folder contains important information about the application's architecture, setup, and usage.

## Available Documentation

- [Firebase Setup](./firebase_setup.md) - How to set up and configure Firebase for the HIVE UI project

## Project Structure

The HIVE UI project follows clean architecture principles with the following structure:

```
lib/
  ├── common/            # Shared components and utilities
  ├── docs/              # Documentation
  ├── features/          # Feature modules
  │    ├── feature_name/
  │    │    ├── data/           # Data sources, repositories, and DTOs
  │    │    ├── domain/         # Entities and use cases
  │    │    └── presentation/   # UI components, controllers, and screens
  ├── pages/             # Main pages of the application
  ├── services/          # Application-wide services
  ├── theme/             # Theme configuration
  ├── widgets/           # Shared widgets
  └── main.dart          # Application entry point
```

## Firebase Integration

Firebase is used in this project for various features:

1. **Authentication** - User sign-in and account management
2. **Firestore** - Cloud database for storing application data
3. **Storage** - Cloud storage for user-generated content
4. **Analytics** - Tracking user behavior and application performance
5. **Messaging** - Push notifications

See [Firebase Setup](./firebase_setup.md) for detailed setup instructions.

## Development Workflow

1. Make sure to install all dependencies: `flutter pub get`
2. Configure Firebase using the FlutterFire CLI
3. Follow the coding standards outlined in the project
4. Run tests before submitting code changes 