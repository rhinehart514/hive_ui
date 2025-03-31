# Firebase Data Connectors

This directory contains custom Firebase data connectors for the HIVE UI application. These connectors provide a standardized interface for interacting with Firebase services.

## Available Connectors

### Default Connector

The Default Connector provides a simple interface for common Firestore operations. It's located in the `dart/default_connector` directory.

Key features:
- Document querying with filters, ordering, and limits
- Document creation, reading, updating, and deletion
- Integration with Firebase Auth

## Usage

See the README.md and example.dart files in each connector directory for detailed usage instructions.

## Custom Implementation Details

The connectors in this directory provide direct access to Firebase services without requiring the firebase_data_connect package, which had dependency conflicts with other packages in our project.

Our custom implementation provides similar functionality while maintaining compatibility with the rest of the application.

## Extending Connectors

To extend a connector with additional functionality:

1. Open the connector file (e.g., `default.dart`)
2. Add new methods for your specific use cases
3. Update the README.md and example.dart files as needed

## Integration with Firebase

These connectors assume Firebase has been properly initialized in your application using:

```dart
await Firebase.initializeApp();
```

Ensure that your Firebase configuration is properly set up before using these connectors. 