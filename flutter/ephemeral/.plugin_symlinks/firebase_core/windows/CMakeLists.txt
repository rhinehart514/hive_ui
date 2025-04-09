# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later.
cmake_minimum_required(VERSION 3.14)

set(PROJECT_NAME "firebase_core")
project( LANGUAGES CXX)

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
add_library( STATIC
  "include/firebase_core/firebase_core_plugin_c_api.h"
  "firebase_core_plugin_c_api.cpp"
  
)

apply_standard_settings()

# Symbols are hidden by default to reduce the chance of accidental conflicts
# between plugins. This should not be removed; any symbols that should be
# exported should be explicitly exported with the FLUTTER_PLUGIN_EXPORT macro.
set_target_properties( PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions( PRIVATE FLUTTER_PLUGIN_IMPL)

# Source include directories and library dependencies. Add any plugin-specific
# dependencies here.
target_include_directories( INTERFACE
  "/include")
target_link_libraries( PRIVATE flutter flutter_wrapper_plugin)

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(firebase_core_bundled_libraries
  ""
  PARENT_SCOPE
)

# Add define to use stub implementation on Windows
target_compile_definitions( PRIVATE FIREBASE_STUB)

# Add Windows desktop define for Firebase compatibility
target_compile_definitions( PRIVATE WINDOWS_DESKTOP=1)

# Add Windows database support define
target_compile_definitions( PRIVATE WINDOWS_DATABASE_SUPPORT=1)