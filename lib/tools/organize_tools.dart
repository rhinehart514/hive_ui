import 'dart:io';

/// A utility script to organize the one-time migration tools
/// by moving them to an archive folder.
///
/// This script will:
/// 1. Create a 'migration_archive' folder in lib/tools
/// 2. Move all one-time migration scripts and batch files to that folder
/// 3. Create a README.md in the archive folder explaining the scripts
///
/// Run with: flutter run -d windows lib/tools/organize_tools.dart

void main() async {
  print('==================================================');
  print('  HIVE UI - Organize Migration Tools');
  print('==================================================');
  print('');
  print('This utility will move all one-time migration scripts');
  print('to an archive folder for future reference.');
  print('');

  print('Starting in 3 seconds (CTRL+C to cancel)...');
  await Future.delayed(const Duration(seconds: 3));

  // Create the archive folder
  final archiveDir = Directory('lib/tools/migration_archive');
  if (!await archiveDir.exists()) {
    await archiveDir.create();
    print('Created archive directory: ${archiveDir.path}');
  }

  // List of files to archive
  final filesToArchive = [
    // Migration scripts
    'migrate_events_to_spaces.dart',
    'migrate_events_to_spaces.bat',
    'migrate_events_to_typed_spaces.dart',
    'migrate_events_to_typed_spaces.bat',
    'migrate_root_events_to_spaces.dart',
    'migrate_root_events_to_spaces.bat',

    // Cleanup scripts
    'cleanup_empty_spaces.dart',
    'cleanup_empty_spaces.bat',
    'cleanup_migrated_spaces.dart',
    'cleanup_migrated_spaces.bat',
    'cleanup_nonexistent_spaces.dart',
    'cleanup_nonexistent_spaces.bat',
    'cleanup_original_spaces_and_events.dart',
    'cleanup_original_spaces_and_events.bat',
    'cleanup_root_events.dart',
    'cleanup_root_events.bat',
    'cleanup_spaces_with_events_only.dart',
    'cleanup_spaces_with_events_only.bat',
    'cleanup_spaces_with_minimal_data.dart',
    'cleanup_spaces_with_minimal_data.bat',

    // Other migration tools
    'deploy_migration_rules.dart',
    'deploy_migration_rules.bat',
    'firestore_migration_rules.md',
  ];

  // Archive each file
  int succeeded = 0;
  int failed = 0;

  for (final fileName in filesToArchive) {
    final sourceFile = File('lib/tools/$fileName');

    if (await sourceFile.exists()) {
      try {
        final targetFile = File('lib/tools/migration_archive/$fileName');
        await sourceFile.copy(targetFile.path);
        await sourceFile.delete();
        print('Archived: $fileName');
        succeeded++;
      } catch (e) {
        print('Failed to archive $fileName: $e');
        failed++;
      }
    } else {
      print('File not found, skipping: $fileName');
    }
  }

  // Create README.md
  const readmeContent = '''
# Firestore Migration Archive

This folder contains scripts used for one-time data migration of the Hive app's Firestore database.

## Migration Process

The migration process involved:

1. Reorganizing spaces from a flat collection into typed subcollections
2. Moving events from a root collection to be nested within their respective spaces
3. Cleaning up empty spaces and orphaned documents

## Script Descriptions

### Migration Scripts
- `migrate_events_to_spaces.dart` - Initial script to move events under spaces
- `migrate_events_to_typed_spaces.dart` - Script to migrate events to the typed space structure
- `migrate_root_events_to_spaces.dart` - Script to migrate events from root to specific spaces

### Cleanup Scripts
- `cleanup_empty_spaces.dart` - Removes empty space documents
- `cleanup_migrated_spaces.dart` - Removes original spaces after migration
- `cleanup_nonexistent_spaces.dart` - Cleans up references to non-existent spaces
- `cleanup_original_spaces_and_events.dart` - Cleans original spaces and events
- `cleanup_root_events.dart` - Removes the original events collection
- `cleanup_spaces_with_events_only.dart` - Cleans spaces with only events
- `cleanup_spaces_with_minimal_data.dart` - Cleans spaces with minimal data

### Other Tools
- `deploy_migration_rules.dart` - Script to deploy temporary Firestore rules
- `firestore_migration_rules.md` - Firestore rules used during migration

These scripts are kept for reference purposes but are not intended to be run again.
''';

  final readmeFile = File('lib/tools/migration_archive/README.md');
  await readmeFile.writeAsString(readmeContent);
  print('Created README.md in archive folder');

  // Create new README for tools directory
  const toolsReadmeContent = '''
# Hive UI Tools

This directory contains utility scripts for the Hive UI application.

## Development Tools

Add new development tools here as needed.

## Notes

One-time migration scripts have been moved to the `migration_archive` folder for reference.
''';

  final toolsReadmeFile = File('lib/tools/README.md');
  await toolsReadmeFile.writeAsString(toolsReadmeContent);
  print('Created README.md in tools folder');

  // Print summary
  print('');
  print('Archive operation completed:');
  print('- Successfully archived: $succeeded files');
  print('- Failed to archive: $failed files');
  print('');
  print(
      'All one-time migration scripts have been moved to: lib/tools/migration_archive');
  print('You may safely continue with UI development.');
  print('');
  print('Exiting in 3 seconds...');
  await Future.delayed(const Duration(seconds: 3));
  exit(0);
}
