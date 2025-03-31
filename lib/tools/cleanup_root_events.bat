@echo off
echo ========================================================
echo  HIVE UI - Clean Up Root Events Collection
echo ========================================================
echo.
echo *** WARNING: This utility will DELETE ALL EVENTS
echo *** from the root events collection.
echo *** Only run this after verifying events are properly migrated!
echo.
echo Press any key to continue or CTRL+C to cancel...
pause > nul

echo.
echo Running cleanup tool...
echo.

flutter run -d windows lib/tools/cleanup_root_events.dart

echo.
echo Process completed.
echo.
pause 