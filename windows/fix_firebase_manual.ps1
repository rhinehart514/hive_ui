# Manual Firebase CMakeLists.txt fix for Windows
Write-Host "====================================================="
Write-Host "Manual Firebase CMake Fix for Windows"
Write-Host "====================================================="

$plugin_dir = "flutter\ephemeral\.plugin_symlinks"

# 1. Fix firebase_core CMakeLists.txt
$firebase_core_cmake = @"
# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later.
cmake_minimum_required(VERSION 3.14)

# Configure platform-specific build options
if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
  # Add Windows desktop define for Firebase compatibility
  add_compile_definitions(WINDOWS_DESKTOP=1)
  add_compile_definitions(FIREBASE_STUB)
  add_compile_definitions(WINDOWS_DATABASE_SUPPORT=1)
endif()

set(PROJECT_NAME "firebase_core")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must not be changed
set(PLUGIN_NAME "firebase_core_plugin")

# Define the plugin library target. Its name must not be changed.
add_library(${PLUGIN_NAME} SHARED
  "firebase_core_plugin.cpp"
  "firebase_core_plugin.h"
  "messages.g.cpp"
  "messages.g.h"
  "include/firebase_core/firebase_core_plugin_c_api.h"
  "firebase_core_plugin_c_api.cpp"
)

# Apply a standard set of build settings that are configured in the
# application-level CMakeLists.txt. This can be removed for plugins that want
# full control over build settings.
apply_standard_settings(${PLUGIN_NAME})

# Symbols are hidden by default to reduce the chance of accidental conflicts
# between plugins. This should not be removed; any symbols that should be
# exported should be explicitly exported with the FLUTTER_PLUGIN_EXPORT macro.
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

# Source include directories and library dependencies. Add any plugin-specific
# dependencies here.
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(firebase_core_bundled_libraries
  ""
  PARENT_SCOPE
)
"@

# 2. Fix firebase_auth CMakeLists.txt
$firebase_auth_cmake = @"
# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later.
cmake_minimum_required(VERSION 3.14)

# Configure platform-specific build options
if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
  # Add Windows desktop define for Firebase compatibility
  add_compile_definitions(WINDOWS_DESKTOP=1)
  add_compile_definitions(FIREBASE_STUB)
endif()

set(PROJECT_NAME "firebase_auth")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must not be changed
set(PLUGIN_NAME "firebase_auth_plugin")

# Define the plugin library target. Its name must not be changed.
add_library(${PLUGIN_NAME} SHARED
  "firebase_auth_plugin.cpp"
  "firebase_auth_plugin.h"
  "messages.g.cpp"
  "messages.g.h"
  "include/firebase_auth/firebase_auth_plugin_c_api.h"
  "firebase_auth_plugin_c_api.cpp"
)

# Apply a standard set of build settings that are configured in the
# application-level CMakeLists.txt. This can be removed for plugins that want
# full control over build settings.
apply_standard_settings(${PLUGIN_NAME})

# Symbols are hidden by default to reduce the chance of accidental conflicts
# between plugins. This should not be removed; any symbols that should be
# exported should be explicitly exported with the FLUTTER_PLUGIN_EXPORT macro.
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

# Source include directories and library dependencies. Add any plugin-specific
# dependencies here.
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(firebase_auth_bundled_libraries
  ""
  PARENT_SCOPE
)
"@

# 3. Fix cloud_firestore CMakeLists.txt
$cloud_firestore_cmake = @"
# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later.
cmake_minimum_required(VERSION 3.14)

# Configure platform-specific build options
if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
  # Add Windows desktop define for Firebase compatibility
  add_compile_definitions(WINDOWS_DESKTOP=1)
  add_compile_definitions(FIREBASE_STUB)
endif()

set(PROJECT_NAME "cloud_firestore")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must not be changed
set(PLUGIN_NAME "cloud_firestore_plugin")

# Define the plugin library target. Its name must not be changed.
add_library(${PLUGIN_NAME} SHARED
  "cloud_firestore_plugin.cpp"
  "cloud_firestore_plugin.h"
  "messages.g.cpp"
  "messages.g.h"
  "include/cloud_firestore/cloud_firestore_plugin_c_api.h"
  "cloud_firestore_plugin_c_api.cpp"
)

# Apply a standard set of build settings that are configured in the
# application-level CMakeLists.txt. This can be removed for plugins that want
# full control over build settings.
apply_standard_settings(${PLUGIN_NAME})

# Symbols are hidden by default to reduce the chance of accidental conflicts
# between plugins. This should not be removed; any symbols that should be
# exported should be explicitly exported with the FLUTTER_PLUGIN_EXPORT macro.
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

# Source include directories and library dependencies. Add any plugin-specific
# dependencies here.
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(cloud_firestore_bundled_libraries
  ""
  PARENT_SCOPE
)
"@

# 4. Fix firebase_storage CMakeLists.txt
$firebase_storage_cmake = @"
# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later.
cmake_minimum_required(VERSION 3.14)

# Configure platform-specific build options
if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
  # Add Windows desktop define for Firebase compatibility
  add_compile_definitions(WINDOWS_DESKTOP=1)
  add_compile_definitions(FIREBASE_STUB)
endif()

set(PROJECT_NAME "firebase_storage")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must not be changed
set(PLUGIN_NAME "firebase_storage_plugin")

# Define the plugin library target. Its name must not be changed.
add_library(${PLUGIN_NAME} SHARED
  "firebase_storage_plugin.cpp"
  "firebase_storage_plugin.h"
  "messages.g.cpp"
  "messages.g.h"
  "include/firebase_storage/firebase_storage_plugin_c_api.h"
  "firebase_storage_plugin_c_api.cpp"
)

# Apply a standard set of build settings that are configured in the
# application-level CMakeLists.txt. This can be removed for plugins that want
# full control over build settings.
apply_standard_settings(${PLUGIN_NAME})

# Symbols are hidden by default to reduce the chance of accidental conflicts
# between plugins. This should not be removed; any symbols that should be
# exported should be explicitly exported with the FLUTTER_PLUGIN_EXPORT macro.
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

# Source include directories and library dependencies. Add any plugin-specific
# dependencies here.
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(firebase_storage_bundled_libraries
  ""
  PARENT_SCOPE
)
"@

# Create plugin_version.h file for firebase_core
$plugin_version_h = @"
// Auto-generated plugin version file
#define FLUTTER_PLUGIN_VERSION "2.32.0"

#include <string>

inline std::string getPluginVersion() {
  return FLUTTER_PLUGIN_VERSION;
}
"@

# Write files to disk
$plugins = @(
    @{ name = "firebase_core"; content = $firebase_core_cmake },
    @{ name = "firebase_auth"; content = $firebase_auth_cmake },
    @{ name = "cloud_firestore"; content = $cloud_firestore_cmake },
    @{ name = "firebase_storage"; content = $firebase_storage_cmake }
)

foreach ($plugin in $plugins) {
    $name = $plugin.name
    $content = $plugin.content
    
    $plugin_dir_path = Join-Path -Path $plugin_dir -ChildPath "$name\windows"
    
    if (Test-Path $plugin_dir_path) {
        Write-Host "Fixing $name CMakeLists.txt..."
        $cmake_path = Join-Path -Path $plugin_dir_path -ChildPath "CMakeLists.txt"
        
        # Create backup
        if (Test-Path $cmake_path) {
            Copy-Item $cmake_path "$cmake_path.backup" -Force
        }
        
        # Write new content
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($cmake_path, $content, $utf8NoBom)
        
        Write-Host "Fixed $name CMakeLists.txt"
    }
    else {
        Write-Host "$name plugin directory not found, skipping..."
    }
}

# Create plugin_version.h file for firebase_core
$plugin_version_dir = Join-Path -Path $plugin_dir -ChildPath "firebase_core\windows\firebase_core"

if (-not (Test-Path $plugin_version_dir)) {
    New-Item -ItemType Directory -Path $plugin_version_dir -Force | Out-Null
}

$plugin_version_file = Join-Path -Path $plugin_version_dir -ChildPath "plugin_version.h"

Write-Host "Creating plugin_version.h file..."
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($plugin_version_file, $plugin_version_h, $utf8NoBom)
Write-Host "Created plugin_version.h file"

# Fix RegisterLibrary call in firebase_core_plugin.cpp
$firebase_core_cpp = Join-Path -Path $plugin_dir -ChildPath "firebase_core\windows\firebase_core_plugin.cpp"
if (Test-Path $firebase_core_cpp) {
    Write-Host "Fixing RegisterLibrary call in firebase_core_plugin.cpp..."
    
    # Create backup
    Copy-Item $firebase_core_cpp "$firebase_core_cpp.backup" -Force
    
    # Read content
    $cpp_content = Get-Content $firebase_core_cpp -Raw
    
    # Replace RegisterLibrary call
    $fixed_cpp = $cpp_content -replace 'App::RegisterLibrary\(kLibraryName\.c_str\(\), getPluginVersion\(\)\.c_str\(\),\s*nullptr\);', @'
#if FIREBASE_VERSION_MAJOR >= 11
  // Firebase SDK 11.x+ only takes the library name
  App::RegisterLibrary(kLibraryName.c_str());
#else
  // Older Firebase SDK versions take name and version
  App::RegisterLibrary(kLibraryName.c_str(), getPluginVersion().c_str(), nullptr);
#endif
'@
    
    # Write fixed content
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($firebase_core_cpp, $fixed_cpp, $utf8NoBom)
    Write-Host "Fixed RegisterLibrary call"
}

Write-Host "====================================================="
Write-Host "All Firebase CMake files have been manually fixed"
Write-Host "You can now build your Flutter app for Windows"
Write-Host "=====================================================" 