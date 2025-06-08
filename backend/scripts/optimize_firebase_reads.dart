import 'dart:io';

/// This script helps automate the migration from ClubService to OptimizedClubAdapter
/// Run with: dart scripts/optimize_firebase_reads.dart

void main() async {
  print('Starting Firebase reads optimization migration...');

  // Directories to check for ClubService usage
  final List<String> dirsToCheck = [
    'lib/pages',
    'lib/features',
    'lib/widgets',
    'lib/services',
    'lib/providers',
  ];

  // Find files that import or use ClubService
  final Map<String, List<String>> filesWithClubService =
      await findFilesWithPattern(
    dirsToCheck,
    [
      'import \'package:hive_ui/services/club_service.dart\'',
      'ClubService.',
    ],
  );

  // Print results
  print('\n== Files that need updating ==');
  int totalReferences = 0;

  filesWithClubService.forEach((file, lines) {
    print('\n$file (${lines.length} references):');
    for (final line in lines) {
      print('  - $line');
    }
    totalReferences += lines.length;
  });

  print('\nTotal files to update: ${filesWithClubService.length}');
  print('Total ClubService references: $totalReferences');

  // Add imports to files
  if (askConfirmation(
      'Would you like to add the optimized service imports to all files?')) {
    await addImportsToFiles(filesWithClubService.keys.toList());
  }

  print('''
Migration steps:
1. Review the implementation guide at lib/services/IMPLEMENTATION_GUIDE.md
2. Update main.dart to initialize the optimized services
3. Update high-impact files like onboarding_profile.dart and explore_page.dart
4. Test the app thoroughly after each change
5. Monitor Firebase read operations in the Firebase console
''');
}

/// Find files containing specific patterns
Future<Map<String, List<String>>> findFilesWithPattern(
  List<String> directories,
  List<String> patterns,
) async {
  final Map<String, List<String>> filesWithMatches = {};

  for (final dir in directories) {
    final Directory directory = Directory(dir);
    if (!directory.existsSync()) {
      print('Warning: Directory $dir does not exist.');
      continue;
    }

    await for (final FileSystemEntity entity
        in directory.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final String content = await File(entity.path).readAsString();
        final List<String> matchingLines = [];

        final lines = content.split('\n');
        for (int i = 0; i < lines.length; i++) {
          final line = lines[i];
          for (final pattern in patterns) {
            if (line.contains(pattern)) {
              matchingLines.add('Line ${i + 1}: ${line.trim()}');
              break;
            }
          }
        }

        if (matchingLines.isNotEmpty) {
          filesWithMatches[entity.path] = matchingLines;
        }
      }
    }
  }

  return filesWithMatches;
}

/// Add optimized service imports to files
Future<void> addImportsToFiles(List<String> filePaths) async {
  // Define import statements
  const importStatements = '''
import 'package:hive_ui/services/optimized_club_adapter.dart';
import 'package:hive_ui/services/service_initializer.dart';''';

  int filesUpdated = 0;

  for (final filePath in filePaths) {
    final File file = File(filePath);
    if (!file.existsSync()) continue;

    String content = await file.readAsString();

    // Only add imports if they don't already exist
    if (!content.contains('optimized_club_adapter.dart') &&
        !content.contains('service_initializer.dart')) {
      // Find the last import statement to add ours after it
      const importPrefixPattern = "import '";
      final allImports = [];

      final lines = content.split('\n');
      int lastImportLine = -1;

      for (int i = 0; i < lines.length; i++) {
        if (lines[i].trim().startsWith(importPrefixPattern)) {
          lastImportLine = i;
          allImports.add(i);
        }
      }

      if (lastImportLine >= 0) {
        // Insert after the last import
        lines.insert(lastImportLine + 1, importStatements);
        final newContent = lines.join('\n');
        await file.writeAsString(newContent);
        filesUpdated++;
        print('Updated imports in $filePath');
      }
    }
  }

  print('Added imports to $filesUpdated files.');
}

/// Ask for user confirmation
bool askConfirmation(String question) {
  print('$question (y/n)');
  final input = stdin.readLineSync()?.toLowerCase();
  return input == 'y' || input == 'yes';
}
