@echo off
echo ==================================================
echo   HIVE UI - Migrate Events to Spaces
echo ==================================================
echo.

set INTERACTIVE_MODE=
if "%1"=="--interactive" set INTERACTIVE_MODE=--interactive

if "%INTERACTIVE_MODE%"=="" (
  echo Running in automatic mode without confirmation.
) else (
  echo This batch file will run the event migration script in interactive mode.
  echo You will be prompted for confirmation.
  echo.
)

cd %~dp0..\..
echo Running migration script...
echo.
flutter run -d windows lib/tools/migrate_events_to_spaces.dart %INTERACTIVE_MODE%

echo.
echo Process completed.
echo. 