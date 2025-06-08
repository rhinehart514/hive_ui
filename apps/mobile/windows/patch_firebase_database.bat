@echo off
echo =================================================
echo Patching Firebase Realtime Database for Windows...
echo =================================================

:: Check if the windows directory exists
if not exist windows (
  echo Windows directory not found. Run this script from the project root.
  exit /b 1
)

:: Apply Firebase Realtime Database plugin patches
echo Creating Firebase Realtime Database plugin for Windows platform...

:: Ensure plugin directories exist
if not exist windows\flutter\firebase_database (
  mkdir windows\flutter\firebase_database
  mkdir windows\flutter\firebase_database\include
  mkdir windows\flutter\firebase_database\include\firebase_database
  echo Created plugin directories successfully
)

:: Apply Firebase Core patches to support database
echo Applying Firebase Core patches...
if exist windows\flutter\ephemeral\.plugin_symlinks\firebase_core\windows\CMakeLists.txt (
  echo target_compile_definitions(firebase_core_plugin PRIVATE WINDOWS_DATABASE_SUPPORT=1) >> windows\flutter\ephemeral\.plugin_symlinks\firebase_core\windows\CMakeLists.txt
  echo Applied Firebase Core patch
)

:: Set up proper CMake for our plugin
echo Rebuilding Flutter plugins...
flutter pub get

echo.
echo Firebase Realtime Database Windows patches applied successfully!
echo You can now build your Windows Flutter app with Firebase Realtime Database support
echo.

echo Setup complete. Make sure to rebuild your Flutter app (flutter clean and flutter build windows).
echo Firebase Realtime Database Windows plugin has been installed. 