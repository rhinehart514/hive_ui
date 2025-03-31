@echo off
title HIVE UI - Fix Space Types

echo ==================================================
echo   HIVE UI - Fix Space Types
echo ==================================================
echo.
echo This utility will analyze all spaces in the spaces collection
echo and update their spaceType field based on name and description.
echo.
echo Press any key to continue or CTRL+C to cancel...
pause > nul

cd %~dp0..\..
flutter run -d windows lib/tools/fix_space_types.dart

echo Process complete.
pause 