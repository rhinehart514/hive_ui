@echo off
echo ========================================================
echo  HIVE UI - Clean Up Non-existent Space Documents
echo ========================================================
echo.
echo This utility will remove references to non-existent documents
echo in the spaces subcollections.
echo.
echo Starting in 3 seconds...
timeout /t 3 > nul

echo.
echo Running cleanup tool...
echo.

flutter run -d windows lib/tools/cleanup_nonexistent_spaces.dart

echo.
echo Process completed.
echo. 