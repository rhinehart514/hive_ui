@echo off
title HIVE UI - Restore Firestore Rules

echo ==================================================
echo   HIVE UI - Restore Original Firestore Rules
echo ==================================================
echo.
echo This will restore the original Firestore security rules
echo after the migration process is complete.
echo.
echo IMPORTANT: Make sure you have reverted the changes in
echo firestore.rules file before running this script.
echo.
echo Press any key to continue or CTRL+C to cancel...
pause > nul

cd %~dp0..\..
flutter run -d windows lib/tools/restore_firestore_rules.dart

echo Process complete.
pause 