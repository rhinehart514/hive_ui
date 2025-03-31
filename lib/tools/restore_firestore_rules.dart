import 'dart:io';

/// Restore original Firestore rules after migration
///
/// This script helps to restore the original Firestore security rules
/// after the migration process is complete.
///
/// Instructions:
/// 1. First, revert the changes in firestore.rules to the original rules
/// 2. Run this script with: flutter run -d windows lib/tools/restore_firestore_rules.dart
///
/// Or run this command directly if you have the Firebase CLI: firebase deploy --only firestore:rules

void main() async {
  print('==================================================');
  print('  HIVE UI - Restore Original Firestore Rules');
  print('==================================================');
  print('');
  print('This script will restore the original Firestore security rules');
  print('after the migration process is complete.');
  print('');

  // Check if the file is restored
  final rulesFile = File('firestore.rules');
  final content = await rulesFile.readAsString();

  if (content.contains('match /spaces/{document=**} {') &&
      content.contains('allow read, write: if true;')) {
    print(
        'ERROR: The firestore.rules file still contains the temporary migration rules.');
    print('');
    print(
        'Please revert the changes in firestore.rules to restore the original rules:');
    print('1. Uncomment the original spaces rules');
    print('2. Remove the temporary spaces rules');
    print('');
    print('Press any key to exit...');
    await stdin.first;
    exit(1);
  }

  print(
      'Firestore rules file appears to have been reverted to original rules.');
  print('Deploying original Firestore rules...');

  // Run the deploy command
  final result =
      await Process.run('firebase', ['deploy', '--only', 'firestore:rules']);

  if (result.exitCode == 0) {
    print('');
    print('Success! Original rules have been restored.');
    print('');
    print(
        'Your Firestore database now has the original security rules in place.');
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
