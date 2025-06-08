# Fixed Firebase CMake Syntax for Windows
Write-Host "====================================================="
Write-Host "Fixing Firebase CMake Function Syntax for Windows"
Write-Host "====================================================="

$plugin_dir = "flutter\ephemeral\.plugin_symlinks"

# Fix plugin CMakeLists.txt files with correct function syntax
$plugins = @(
    @{
        name = "firebase_core";
        target_name = "firebase_core_plugin";
        bundle_name = "firebase_core_bundled_libraries";
        cmake_content = @"
# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later.
cmake_minimum_required(VERSION 3.14)

set(PROJECT_NAME "firebase_core")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must not be changed
set(PLUGIN_NAME "firebase_core_plugin")

# Any new source files that you add to the plugin should be added here.
list(APPEND PLUGIN_SOURCES
  "firebase_core_plugin.cpp"
  "firebase_core_plugin.h"
  "messages.g.cpp"
  "messages.g.h"
)

# Define the plugin library target. Its name must not be changed.
add_library(${PLUGIN_NAME} STATIC
  "include/firebase_core/firebase_core_plugin_c_api.h"
  "firebase_core_plugin_c_api.cpp"
  ${PLUGIN_SOURCES}
)

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

# Add define to use stub implementation on Windows
target_compile_definitions(${PLUGIN_NAME} PRIVATE FIREBASE_STUB)

# Add Windows desktop define for Firebase compatibility
target_compile_definitions(${PLUGIN_NAME} PRIVATE WINDOWS_DESKTOP=1)

# Add Windows database support define
target_compile_definitions(${PLUGIN_NAME} PRIVATE WINDOWS_DATABASE_SUPPORT=1)
"@
    },
    @{
        name = "firebase_auth";
        target_name = "firebase_auth_plugin";
        bundle_name = "firebase_auth_bundled_libraries";
        cmake_content = @"
# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later.
cmake_minimum_required(VERSION 3.14)

set(PROJECT_NAME "firebase_auth")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must not be changed
set(PLUGIN_NAME "firebase_auth_plugin")

# Any new source files that you add to the plugin should be added here.
list(APPEND PLUGIN_SOURCES
  "firebase_auth_plugin.cpp"
  "firebase_auth_plugin.h"
  "messages.g.cpp"
  "messages.g.h"
)

# Define the plugin library target. Its name must not be changed.
add_library(${PLUGIN_NAME} STATIC
  "include/firebase_auth/firebase_auth_plugin_c_api.h"
  "firebase_auth_plugin_c_api.cpp"
  ${PLUGIN_SOURCES}
)

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

# Add define to use stub implementation on Windows
target_compile_definitions(${PLUGIN_NAME} PRIVATE FIREBASE_STUB)

# Add Windows desktop define for Firebase compatibility
target_compile_definitions(${PLUGIN_NAME} PRIVATE WINDOWS_DESKTOP=1)
"@
    },
    @{
        name = "cloud_firestore";
        target_name = "cloud_firestore_plugin";
        bundle_name = "cloud_firestore_bundled_libraries";
        cmake_content = @"
# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later.
cmake_minimum_required(VERSION 3.14)

set(PROJECT_NAME "cloud_firestore")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must not be changed
set(PLUGIN_NAME "cloud_firestore_plugin")

# Any new source files that you add to the plugin should be added here.
list(APPEND PLUGIN_SOURCES
  "cloud_firestore_plugin.cpp"
  "cloud_firestore_plugin.h"
  "messages.g.cpp"
  "messages.g.h"
)

# Define the plugin library target. Its name must not be changed.
add_library(${PLUGIN_NAME} STATIC
  "include/cloud_firestore/cloud_firestore_plugin_c_api.h"
  "cloud_firestore_plugin_c_api.cpp"
  ${PLUGIN_SOURCES}
)

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

# Add define to use stub implementation on Windows
target_compile_definitions(${PLUGIN_NAME} PRIVATE FIREBASE_STUB)

# Add Windows desktop define for Firebase compatibility
target_compile_definitions(${PLUGIN_NAME} PRIVATE WINDOWS_DESKTOP=1)
"@
    },
    @{
        name = "firebase_storage";
        target_name = "firebase_storage_plugin";
        bundle_name = "firebase_storage_bundled_libraries";
        cmake_content = @"
# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later.
cmake_minimum_required(VERSION 3.14)

set(PROJECT_NAME "firebase_storage")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must not be changed
set(PLUGIN_NAME "firebase_storage_plugin")

# Any new source files that you add to the plugin should be added here.
list(APPEND PLUGIN_SOURCES
  "firebase_storage_plugin.cpp"
  "firebase_storage_plugin.h"
  "messages.g.cpp"
  "messages.g.h"
)

# Define the plugin library target. Its name must not be changed.
add_library(${PLUGIN_NAME} STATIC
  "include/firebase_storage/firebase_storage_plugin_c_api.h"
  "firebase_storage_plugin_c_api.cpp"
  ${PLUGIN_SOURCES}
)

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

# Add define to use stub implementation on Windows
target_compile_definitions(${PLUGIN_NAME} PRIVATE FIREBASE_STUB)

# Add Windows desktop define for Firebase compatibility
target_compile_definitions(${PLUGIN_NAME} PRIVATE WINDOWS_DESKTOP=1)
"@
    }
)

# Create plugin_version.h file
$plugin_version_h = @"
// Auto-generated plugin version file
#define FLUTTER_PLUGIN_VERSION "2.32.0"

#include <string>

inline std::string getPluginVersion() {
  return FLUTTER_PLUGIN_VERSION;
}
"@

# Process each plugin
foreach ($plugin in $plugins) {
    $name = $plugin.name
    $cmake_content = $plugin.cmake_content
    
    $plugin_dir_path = Join-Path -Path $plugin_dir -ChildPath "$name\windows"
    
    if (Test-Path $plugin_dir_path) {
        Write-Host "Fixing $name CMakeLists.txt with correct function syntax..."
        $cmake_path = Join-Path -Path $plugin_dir_path -ChildPath "CMakeLists.txt"
        
        # Create backup
        if (Test-Path $cmake_path) {
            Copy-Item $cmake_path "$cmake_path.syntax_backup" -Force
        }
        
        # Write new content
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($cmake_path, $cmake_content, $utf8NoBom)
        
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
    Copy-Item $firebase_core_cpp "$firebase_core_cpp.syntax_backup" -Force
    
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
Write-Host "All Firebase CMake files have been fixed with correct syntax"
Write-Host "You can now build your Flutter app for Windows"
Write-Host "=====================================================" 