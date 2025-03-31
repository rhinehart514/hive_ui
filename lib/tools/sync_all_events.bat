@echo off
echo ==================================================
echo   HIVE UI - Sync All RSS Events to Firestore Tool
echo ==================================================
echo.
echo This batch file will run the tool to sync all RSS events to Firestore.
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause > nul

cd ..\..
flutter run -d windows lib/tools/sync_all_events.dart

echo.
echo Process completed.
echo.
pause 