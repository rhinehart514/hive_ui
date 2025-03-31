import 'dart:io';

/// Deploy temporary Firestore rules for migration
///
/// This script uses the Firebase CLI to deploy the temporary
/// Firestore rules that allow writing to the nested space structure.
///
/// Instructions:
/// 1. Make sure you have the Firebase CLI installed
/// 2. Run this script with: flutter run -d windows lib/tools/deploy_migration_rules.dart
/// 3. After migration, restore the original rules with: firebase deploy --only firestore:rules
///
/// Or run this command directly if you have the Firebase CLI: firebase deploy --only firestore:rules

void main() async {
  print('==================================================');
  print('  HIVE UI - Deploy Migration Rules');
  print('==================================================');
  print('');
  print('This script will deploy temporary Firestore rules that');
  print('allow writing to the nested space structure.');
  print('');
  print('You should restore the original rules after migration by using:');
  print('firebase deploy --only firestore:rules');
  print('');

  print('Deploying temporary Firestore rules...');

  // Run the deploy command
  final result =
      await Process.run('firebase', ['deploy', '--only', 'firestore:rules']);

  if (result.exitCode == 0) {
    print('');
    print('Success! Temporary rules have been deployed.');
    print('');
    print('You can now run the migration script:');
    print('flutter run -d windows lib/tools/migrate_events_to_spaces.dart');
    print('');
    print('After migration completes, restore the original rules by:');
    print('1. Reverting the changes in firestore.rules');
    print('2. Running: firebase deploy --only firestore:rules');
  } else {
    print('');
    print('Error deploying rules:');
    print(result.stderr);
    print('');
    print(
        'Make sure you have the Firebase CLI installed and you are logged in.');
    print('You can install it with: npm install -g firebase-tools');
    print('And login with: firebase login');
  }

  // Wait for user input before exiting
  print('');
  print('Press any key to exit...');
  await stdin.first;
  exit(0);
}
