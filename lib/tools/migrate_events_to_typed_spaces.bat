@echo off
echo ========================================================
echo  HIVE UI - Migrate Events to Typed Spaces
echo ========================================================
echo.
echo This utility will migrate events from the original spaces collection
echo to the new type-specific space subcollections.
echo.
echo Starting in 3 seconds...
timeout /t 3 > nul

echo.
echo Running event migration tool...
echo.

flutter run -d windows lib/tools/migrate_events_to_typed_spaces.dart

echo.
echo Process completed.
echo. 