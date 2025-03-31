@echo off
echo ========================================================
echo  HIVE UI - Clean Up Empty Space Documents
echo ========================================================
echo.
echo This utility will remove empty space documents (with no fields)
echo from the type subcollections - these are likely duplicates.
echo.
echo Starting in 3 seconds...
timeout /t 3 > nul

echo.
echo Running cleanup tool...
echo.

flutter run -d windows lib/tools/cleanup_empty_spaces.dart

echo.
echo Process completed.
echo. 