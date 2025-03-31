@echo off
echo =================================================
echo Patching Firebase plugins for Windows compatibility
echo =================================================

:: Check if the ephemeral directory exists
set PLUGIN_DIR=flutter\ephemeral\.plugin_symlinks

if not exist %PLUGIN_DIR% (
  echo Plugin directory not found. Run 'flutter pub get' first.
  exit /b 1
)

:: Create a backup of the original files
echo Creating backups of original files...
if exist %PLUGIN_DIR%\firebase_core\windows\CMakeLists.txt (
  copy %PLUGIN_DIR%\firebase_core\windows\CMakeLists.txt %PLUGIN_DIR%\firebase_core\windows\CMakeLists.txt.bak
)

:: Add Windows specific definitions to Firebase Core
echo Patching Firebase Core...
if exist %PLUGIN_DIR%\firebase_core\windows\CMakeLists.txt (
  echo target_compile_definitions(firebase_core_plugin PRIVATE WINDOWS_DESKTOP=1) >> %PLUGIN_DIR%\firebase_core\windows\CMakeLists.txt
  echo Patched Firebase Core
)

echo.
echo Firebase patches applied successfully!
echo You can now build your Windows Flutter app with Firebase support
echo. 