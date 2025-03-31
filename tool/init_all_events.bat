@echo off
echo ========================================
echo    HIVE UI - Initialize All Events
echo ========================================
echo.
echo This script will initialize all events in Firestore for cost efficiency
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause > nul

cd ..
flutter run -d windows tool/init_all_events.dart

echo.
echo Process completed.
echo.
pause 