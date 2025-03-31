import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'validate_space_fields.dart' as validator;

/// Simple runner for the space validation tool
/// Provides a command-line interface with options
void main() async {
  // Initialize Flutter for proper framework functionality
  WidgetsFlutterBinding.ensureInitialized();

  print('=================================================');
  print('  HIVE UI - Space Field Validation Tool');
  print('=================================================');
  print('');
  print('This tool will validate and fix all spaces in Firestore');
  print(
      'ensuring they have all required fields for the app to work correctly.');
  print('');

  bool shouldProceed = await promptYesNo('Do you want to proceed?');
  if (!shouldProceed) {
    print('Operation cancelled.');
    exit(0);
  }

  print('');
  print('Starting validation...');
  print('');

  try {
    // Run the validator - we import it as a library and execute it
    // rather than calling main() directly
    validator.validateSpaces();
  } catch (e) {
    print('An error occurred: $e');
    exit(1);
  }
}

/// Prompt the user for a yes/no response
Future<bool> promptYesNo(String message) async {
  print('$message (y/n)');

  final completer = Completer<bool>();

  stdin.listen((List<int> data) {
    final input = String.fromCharCodes(data).trim().toLowerCase();
    if (input == 'y' || input == 'yes') {
      completer.complete(true);
    } else if (input == 'n' || input == 'no') {
      completer.complete(false);
    } else {
      print('Please enter "y" or "n"');
    }
  });

  return completer.future;
}
