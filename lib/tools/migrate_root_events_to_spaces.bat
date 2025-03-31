@echo off
echo ========================================================
echo  HIVE UI - Migrate Root Events to Spaces
echo ========================================================
echo.
echo This utility will migrate events from the root events collection
echo to their appropriate spaces based on the event organizer.
echo Only events whose spaces have actual data will be migrated.
echo.
echo Starting in 3 seconds...
timeout /t 3 > nul

echo.
echo Running event migration tool...
echo.

flutter run -d windows lib/tools/migrate_root_events_to_spaces.dart

echo.
echo Process completed.
echo. 