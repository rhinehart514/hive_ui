@echo off
echo ========================================================
echo  HIVE UI - Clean Up Original Spaces and Events
echo ========================================================
echo.
echo *** WARNING: This utility will DELETE original space documents
echo *** and their events from the root spaces collection.
echo *** Only run this after verifying successful migration!
echo.
echo Press any key to continue or CTRL+C to cancel...
pause > nul

echo.
echo Running cleanup tool...
echo.

flutter run -d windows lib/tools/cleanup_original_spaces_and_events.dart

echo.
echo Process completed.
echo.
pause 