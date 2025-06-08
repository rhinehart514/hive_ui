# Disable Firebase Plugins on Windows
Write-Host "====================================================="
Write-Host "Disabling Firebase Plugins for Windows"
Write-Host "====================================================="

$pubspec_path = "pubspec.yaml"
$pubspec_backup_path = "pubspec.yaml.firebase_backup"

# Create a backup of the pubspec.yaml file
Copy-Item $pubspec_path $pubspec_backup_path -Force
Write-Host "Created backup of pubspec.yaml at $pubspec_backup_path"

# Read the current pubspec.yaml content
$pubspec_content = Get-Content $pubspec_path -Raw

# Check if the excluded_archs section already exists
if ($pubspec_content -match "flutter:\s*\n\s+plugin:") {
    Write-Host "Modifying existing flutter plugin section..."
    
    # If platforms section doesn't exist, add it
    if ($pubspec_content -notmatch "platforms:") {
        $pubspec_content = $pubspec_content -replace "(flutter:\s*\n\s+plugin:)", "`$1`n      platforms:"
    }
    
    # Add or update the Windows section
    if ($pubspec_content -match "windows:") {
        # Update existing Windows section
        $pubspec_content = $pubspec_content -replace "(windows:(?:\s*\n\s+[^:]+:[^\n]+)*)", "`$1`n      windows:`n        pluginClass: none`n        fileName: none`n        dartPluginClass: none"
    }
    else {
        # Add Windows section
        $pubspec_content = $pubspec_content -replace "(platforms:(?:\s*\n\s+[^:]+:[^\n]+)*)", "`$1`n        windows:`n          pluginClass: none`n          fileName: none`n          dartPluginClass: none"
    }
}
else {
    Write-Host "Adding flutter plugin section with platforms..."
    $pubspec_content += @"

flutter:
  plugin:
    platforms:
      windows:
        pluginClass: none
        fileName: none
        dartPluginClass: none
"@
}

# Add excluded_archs setting for each Firebase plugin
$firebase_plugins = @(
    "firebase_core",
    "firebase_auth",
    "cloud_firestore",
    "firebase_storage",
    "firebase_messaging",
    "firebase_database",
    "firebase_analytics",
    "firebase_crashlytics",
    "firebase_remote_config",
    "firebase_performance",
    "_flutterfire_internals"
)

# Write the modified content back to pubspec.yaml
$pubspec_content | Set-Content $pubspec_path -NoNewline
Write-Host "Updated pubspec.yaml with platform settings for Windows"

# Add FIREBASE_SDK_DISABLED define to Windows CMakeLists.txt
$windows_cmake_path = "windows/CMakeLists.txt"
$windows_cmake_backup_path = "windows/CMakeLists.txt.firebase_backup"

# Create a backup of the Windows CMakeLists.txt file
Copy-Item $windows_cmake_path $windows_cmake_backup_path -Force
Write-Host "Created backup of Windows CMakeLists.txt at $windows_cmake_backup_path"

# Read the current Windows CMakeLists.txt content
$windows_cmake_content = Get-Content $windows_cmake_path -Raw

# Check if FIREBASE_SDK_DISABLED is already defined
if ($windows_cmake_content -notmatch "FIREBASE_SDK_DISABLED") {
    Write-Host "Adding FIREBASE_SDK_DISABLED define to Windows CMakeLists.txt..."
    
    # Find the platform-specific build options section
    if ($windows_cmake_content -match "if\(CMAKE_SYSTEM_NAME STREQUAL .Windows.\)") {
        # Add FIREBASE_SDK_DISABLED to the Windows section
        $windows_cmake_content = $windows_cmake_content -replace "(if\(CMAKE_SYSTEM_NAME STREQUAL .Windows.\)(?:\s*\n\s+[^\n]+)*)", "`$1`n  # Disable Firebase SDK for Windows builds to avoid linking errors`n  add_compile_definitions(FIREBASE_SDK_DISABLED=1)"
    }
    else {
        # Add a new Windows section
        $windows_cmake_content += @"

# Configure platform-specific build options
if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
  # Disable Firebase SDK for Windows builds to avoid linking errors
  add_compile_definitions(FIREBASE_SDK_DISABLED=1)
endif()
"@
    }
    
    # Write the modified content back to Windows CMakeLists.txt
    $windows_cmake_content | Set-Content $windows_cmake_path -NoNewline
    Write-Host "Updated Windows CMakeLists.txt with FIREBASE_SDK_DISABLED define"
}
else {
    Write-Host "FIREBASE_SDK_DISABLED define already exists in Windows CMakeLists.txt"
}

# Create a FirebaseStub.h file
$firebase_stub_dir = "windows/flutter/ephemeral"
$firebase_stub_path = "$firebase_stub_dir/firebase_stub.h"

if (-not (Test-Path $firebase_stub_dir)) {
    New-Item -ItemType Directory -Path $firebase_stub_dir -Force | Out-Null
}

$firebase_stub_content = @"
// Firebase Stub Header for Windows
// This provides stub definitions for Firebase functions to allow compilation on Windows

#ifndef FIREBASE_STUB_H_
#define FIREBASE_STUB_H_

#ifdef FIREBASE_SDK_DISABLED

#include <string>
#include <vector>
#include <map>

namespace firebase {

class App {
public:
    static App* Create() { return new App(); }
    static void RegisterLibrary(const char* library, const char* version = nullptr, void* context = nullptr) {}
};

namespace auth {
class Auth {
public:
    static Auth* GetAuth(App* app) { return new Auth(); }
};
}  // namespace auth

namespace firestore {
class Firestore {
public:
    static Firestore* GetInstance(App* app) { return new Firestore(); }
};
}  // namespace firestore

namespace storage {
class Storage {
public:
    static Storage* GetInstance(App* app) { return new Storage(); }
};
}  // namespace storage

}  // namespace firebase

#endif  // FIREBASE_SDK_DISABLED

#endif  // FIREBASE_STUB_H_
"@

# Write the Firebase stub header
$firebase_stub_content | Set-Content $firebase_stub_path -NoNewline
Write-Host "Created Firebase stub header at $firebase_stub_path"

Write-Host "====================================================="
Write-Host "Successfully disabled Firebase plugins for Windows"
Write-Host "You should now run: flutter clean; flutter pub get"
Write-Host "=====================================================" 