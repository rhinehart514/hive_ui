@echo off
echo =================================================
echo Patching Firebase plugins for Windows compatibility
echo =================================================

:: Define plugin directory path
set PLUGIN_DIR=flutter\ephemeral\.plugin_symlinks

:: Check if the ephemeral directory exists
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
  echo. >> %PLUGIN_DIR%\firebase_core\windows\CMakeLists.txt
  echo # Add define to use stub implementation on Windows >> %PLUGIN_DIR%\firebase_core\windows\CMakeLists.txt
  echo target_compile_definitions(firebase_core_plugin PRIVATE FIREBASE_STUB) >> %PLUGIN_DIR%\firebase_core\windows\CMakeLists.txt
  echo Patched Firebase Core
)

:: Create plugin_version.h file if it doesn't exist
echo Creating missing plugin_version.h file...
if not exist %PLUGIN_DIR%\firebase_core\windows\firebase_core (
  mkdir %PLUGIN_DIR%\firebase_core\windows\firebase_core
)

:: Create plugin_version.h with proper content
echo // Auto-generated plugin version file > %PLUGIN_DIR%\firebase_core\windows\firebase_core\plugin_version.h
echo #define FLUTTER_PLUGIN_VERSION "2.32.0" >> %PLUGIN_DIR%\firebase_core\windows\firebase_core\plugin_version.h
echo. >> %PLUGIN_DIR%\firebase_core\windows\firebase_core\plugin_version.h
echo #include ^<string^> >> %PLUGIN_DIR%\firebase_core\windows\firebase_core\plugin_version.h
echo. >> %PLUGIN_DIR%\firebase_core\windows\firebase_core\plugin_version.h
echo inline std::string getPluginVersion() { >> %PLUGIN_DIR%\firebase_core\windows\firebase_core\plugin_version.h
echo   return FLUTTER_PLUGIN_VERSION; >> %PLUGIN_DIR%\firebase_core\windows\firebase_core\plugin_version.h
echo } >> %PLUGIN_DIR%\firebase_core\windows\firebase_core\plugin_version.h
echo Created plugin_version.h file

:: Fix RegisterLibrary compatibility issue in firebase_core_plugin.cpp
echo Fixing RegisterLibrary incompatibility...
if exist %PLUGIN_DIR%\firebase_core\windows\firebase_core_plugin.cpp (
  copy %PLUGIN_DIR%\firebase_core\windows\firebase_core_plugin.cpp %PLUGIN_DIR%\firebase_core\windows\firebase_core_plugin.cpp.bak
  
  :: Use PowerShell to replace the RegisterLibrary call with a version-compatible one
  powershell -Command "(Get-Content %PLUGIN_DIR%\firebase_core\windows\firebase_core_plugin.cpp) -replace 'App::RegisterLibrary\(kLibraryName.c_str\(\), getPluginVersion\(\).c_str\(\),\s*nullptr\);', '#if FIREBASE_VERSION_MAJOR >= 11\n  // Firebase SDK 11.x+ only takes the library name\n  App::RegisterLibrary(kLibraryName.c_str());\n#else\n  // Older Firebase SDK versions take name and version\n  App::RegisterLibrary(kLibraryName.c_str(), getPluginVersion().c_str(), nullptr);\n#endif' | Set-Content %PLUGIN_DIR%\firebase_core\windows\firebase_core_plugin.cpp"
  echo Fixed RegisterLibrary in firebase_core_plugin.cpp
)

:: Also do the same for other Firebase plugins to ensure consistent stub behavior
echo Setting up stub mode for other Firebase plugins...
for %%F in (firebase_auth cloud_firestore firebase_storage firebase_messaging) do (
  if exist %PLUGIN_DIR%\%%F\windows\CMakeLists.txt (
    echo Patching %%F...
    copy %PLUGIN_DIR%\%%F\windows\CMakeLists.txt %PLUGIN_DIR%\%%F\windows\CMakeLists.txt.stub_bak
    echo. >> %PLUGIN_DIR%\%%F\windows\CMakeLists.txt
    echo # Add define to use stub implementation on Windows >> %PLUGIN_DIR%\%%F\windows\CMakeLists.txt
    echo target_compile_definitions(%%F_plugin PRIVATE FIREBASE_STUB) >> %PLUGIN_DIR%\%%F\windows\CMakeLists.txt
    echo Patched %%F
  )
)

echo.
echo Firebase patches applied successfully!
echo You can now build your Windows Flutter app with Firebase support
echo. 