@echo off
title HIVE UI - Deploy Migration Rules

echo ==================================================
echo   HIVE UI - Deploy Migration Rules for Migration
echo ==================================================
echo.
echo This will deploy temporary Firestore rules to allow
echo the migration script to write to nested space collections.
echo.
echo Press any key to continue or CTRL+C to cancel...
pause > nul

cd %~dp0..\..
flutter run -d windows lib/tools/deploy_migration_rules.dart

echo Process complete.
pause 