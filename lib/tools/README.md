# HIVE UI - Admin Tools

This directory contains one-time use tools to help with specific administrative tasks.

## Space Duplicate Merger Tool

### Purpose

The `space_merger_tool.dart` is a one-time use tool that addresses the issue of duplicate spaces across different space types. When the app navigates to `spaces/TYPE_OF_SPACES/spaces/spaceID`, it was showing duplicates of spaces that were running in different types of spaces.

This tool:

1. Identifies spaces that exist across multiple space type collections
2. Merges data from duplicate spaces into a single space
3. Ensures that:
   - If a space was auto-created from "lost event migration", it's merged with the preexisting space
   - All spaces have the same fields with proper values
   - Duplicate spaces are removed from the database

### How to Use

There are two ways to run the tool:

#### 1. Command Line (Recommended)

Run the command-line script:

```bash
flutter run -t lib/tools/run_space_merger.dart
```

This executes the merger process directly with console output and no UI.

#### 2. Interactive UI

Run the UI-based tool:

```bash
flutter run -t lib/tools/space_merger_tool.dart
```

In the UI:
- Click the "Run Space Merger" button
- Monitor the process in the log panel
- Wait for completion message

### Merger Logic

The tool follows these rules when merging spaces:

1. **Primary Space Selection**:
   - Non-auto-created spaces are preferred over auto-created ones
   - Spaces with more fields are preferred
   - Spaces with more recent updates are preferred

2. **Data Merging**:
   - Lists (tags, eventIds, moderators, admins) are combined without duplicates
   - Numeric metrics use the maximum values from all duplicates
   - Boolean flags use OR logic (true if any duplicate has true)
   - Timestamps use most recent for updatedAt and earliest for createdAt
   - Custom data fields are preserved from the primary space

### Code Structure

- `space_duplicate_merger.dart` - Contains the logic for identifying and merging duplicates
- `space_merger_tool.dart` - Interactive UI for running the merger process
- `run_space_merger.dart` - Command-line entry point for running the merger

### Warning

This tool makes destructive changes to the database by removing duplicate spaces after merging. Only run it once and verify results before making additional changes.

## Other Tools

Additional tools may be added to this directory as needed for other administrative tasks.

## Event Migration Tools

### Extract Spaces from Events

The `extract_spaces_from_events.dart` script analyzes events in Firestore and creates spaces based on the organizer names. It categorizes spaces into different types:

- Student Organizations
- University Organizations
- Campus Living
- Fraternity & Sorority
- Other

**Usage:**
```
flutter run -d windows lib/tools/extract_spaces_from_events.dart
```

Alternatively, on Windows, you can run the batch file:
```
lib/tools/extract_spaces_from_events.bat
```

### Migrate Events to Spaces

The `migrate_events_to_spaces.dart` script migrates events from the flat events collection to be properly nested within their respective spaces in Firestore. It creates a hierarchical structure:

```
spaces -> type of spaces -> space ID -> events -> event ID
```

This maintains the original events collection while adding the events to their respective spaces.

**Authentication Required:**

This script requires Firebase authentication to access your Firestore database. You must provide a valid email and password for a user with appropriate permissions.

**Usage:**

The script runs in automatic mode by default (no user confirmation required):
```
flutter run -d windows lib/tools/migrate_events_to_spaces.dart --email=your@email.com --password=yourpassword
```

To run with confirmation in interactive mode:
```
flutter run -d windows lib/tools/migrate_events_to_spaces.dart --interactive --email=your@email.com --password=yourpassword
```

On Windows, you can run the batch file which will prompt for credentials:
```
lib/tools/migrate_events_to_spaces.bat
```

For interactive mode with the batch file:
```
lib/tools/migrate_events_to_spaces.bat --interactive
```

**Performance Optimizations:**
- The script pre-loads all spaces in a single query to minimize Firestore reads
- Events are processed in batches to manage memory usage
- Batch writes are used for efficient database operations
- The script has been optimized to reduce the number of database reads

**Important Notes:**
1. Make sure Firebase is properly configured before running the scripts.
2. These operations modify your Firestore database, so it's recommended to back up your data first.
3. Both scripts preserve the original events collection.
4. The migration is one-way and will add the events to their respective spaces without removing them from the original collection.
5. The user account you authenticate with must have read access to the 'events' and 'spaces' collections and write access to the nested space collections.

## Firestore Security Rules

For the migration script to work, your Firestore security rules must allow:

1. Reading from the root 'events' collection
2. Reading from the root 'spaces' collection
3. Writing to the nested collections under 'spaces'

Here's an example of minimal rules to permit the migration:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read all events
    match /events/{eventId} {
      allow read: if request.auth != null;
    }
    
    // Allow authenticated users to read all spaces
    match /spaces/{spaceId} {
      allow read: if request.auth != null;
      
      // Allow authenticated users to write to nested collections
      match /{collection}/{docId} {
        allow read, write: if request.auth != null;
        
        // Also allow access to events collection
        match /events/{eventDocId} {
          allow read, write: if request.auth != null;
        }
      }
    }
  }
}
```

## Best Practices for Adding New Tools

When creating new tools:

1. Place them in the `lib/tools` directory
2. Create a descriptive name for the script file
3. Document the script's purpose at the top of the file
4. Include clear instructions on how to run the script
5. Consider adding a batch file for Windows users
6. Update this README with information about the new tool

# HIVE UI Maintenance Tools

This directory contains utility scripts for maintaining the HIVE UI application.

## Space Validation Tool

The Space Validation Tool ensures that all spaces in Firestore have the proper field structure required by the application. This helps prevent runtime errors caused by missing fields.

### Features

- Validates all spaces in the correct hierarchical structure (`spaces/typesofspaces/spaces/spaceID`)
- Checks for and fixes missing required fields
- Migrates spaces from the root collection to the proper type collection
- Ensures consistent structure across all spaces

### Required Fields

The tool validates and fixes these required fields:

**Top-level fields:**
- `id`: Space identifier
- `name`: Display name
- `description`: Text description
- `spaceType`: Type category (studentOrg, universityOrg, etc.)
- `createdAt`: Creation timestamp
- `updatedAt`: Last update timestamp
- `tags`: Array of tag strings
- `eventIds`: Array of linked event IDs
- `moderators`: Array of moderator user IDs
- `admins`: Array of admin user IDs
- `relatedSpaceIds`: Array of related space IDs
- `customData`: Map for additional data
- `quickActions`: Map of action keys to action values
- `isJoined`: Boolean for user join state
- `isPrivate`: Boolean privacy flag
- `metrics`: Nested object containing metrics data

**Metrics fields:**
- `memberCount`: Number of members
- `activeMembers`: Number of active members
- `weeklyEvents`: Event count for current week
- `monthlyEngagements`: Engagement count for current month
- `engagementScore`: Floating point engagement rating
- `hasNewContent`: Boolean flag for new content
- `isTrending`: Boolean flag for trending status
- `isTimeSensitive`: Boolean for time-sensitive content
- `category`: String category (suggested, active, etc.)
- `size`: String size descriptor (small, medium, large)
- `spaceId`: The ID of the parent space

### Usage

To run the validation tool:

```bash
# Navigate to project directory
cd path/to/hive_ui

# Run with Flutter
flutter run -d chrome lib/tools/run_validate_spaces.dart
```

The tool will:
1. Scan for spaces in each type collection
2. Check for missing fields
3. Fix any found issues
4. Migrate improperly located spaces
5. Report on the validation results 