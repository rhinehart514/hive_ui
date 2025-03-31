@echo off
echo ========================================================
echo  HIVE UI - Clean Up Event-Only Spaces
echo ========================================================
echo.
echo *** WARNING: This utility will identify and delete spaces
echo *** that have no useful data but have events.
echo *** Only run this after confirming events are properly migrated!
echo.
echo Press any key to continue or CTRL+C to cancel...
pause > nul

echo.
echo Running cleanup tool...
echo.

flutter run -d windows lib/tools/cleanup_spaces_with_events_only.dart

echo.
echo Process completed.
echo.
pause 