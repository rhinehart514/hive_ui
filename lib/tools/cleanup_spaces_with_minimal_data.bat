@echo off
echo.
echo ===================================================
echo HIVE UI - Clean Up Spaces with Minimal Data
echo ===================================================
echo.
echo This script will identify and delete spaces that:
echo  - Have events collections (migrated from previous step)
echo  - Have minimal or no meaningful data in document fields
echo.
echo WARNING: This will delete spaces! Make sure you've:
echo  1. Already migrated events successfully
echo  2. Verified your data is backed up
echo.
set /p continue="Continue? (Y/N): "
if /i "%continue%" neq "Y" (
  echo.
  echo Operation cancelled.
  echo.
  timeout /t 3 > nul
  exit /b
)

echo.
echo Running cleanup script...
echo.

flutter run -d windows lib/tools/cleanup_spaces_with_events_only.dart

echo.
echo Batch file complete.
timeout /t 3 > nul 