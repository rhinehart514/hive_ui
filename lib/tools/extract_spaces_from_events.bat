@echo off
echo =============================================
echo  HIVE UI - Extract Spaces from Events
echo =============================================
echo.
echo This script will run the space extraction process
echo to create spaces from events in Firestore.
echo.
echo Press any key to continue or CTRL+C to cancel...
pause > nul

echo.
echo Running space extraction script...
echo.

cd %~dp0..\..
flutter run -d windows lib/tools/extract_spaces_from_events.dart

echo.
echo Process complete.
echo.
pause 