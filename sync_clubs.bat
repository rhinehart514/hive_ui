@echo off
echo HIVE UI - Direct Club Sync
echo ===========================
echo.
echo Starting the sync process...
dart run tool/sync_clubs.dart 1 y
echo.
echo Process completed.
pause 