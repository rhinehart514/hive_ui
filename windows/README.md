# Firebase Windows Fixes

This directory contains scripts to fix various issues with Firebase plugins when building for Windows.

## Overview

Building Flutter apps for Windows with Firebase plugins often encounters several compiler errors and compatibility issues. These scripts address common problems related to:

1. Incorrect CMake configurations in Firebase plugins
2. Type compatibility issues with C++ variants
3. Deprecated standard conversion warnings
4. Linking errors in Firebase Core

## Scripts and Files

### Main Script

- `fix_firebase_all.ps1`: Master script that runs all fixes in the correct order

### Individual Fix Scripts

- `fix_firebase_plugins.ps1`: Fixes common issues in all Firebase plugin CMake files
- `manual_fix_firebase_core.ps1`: Specifically fixes issues in the Firebase Core CMakeLists.txt
- `fix_encodable_variant.ps1`: Fixes variant compatibility issues in encodable_value.h
- `fix_variant_compatibility.ps1`: Adds compiler flags to Firebase Auth plugin to fix variant issues
- `disable_windows_firebase_compile_errors.cmake`: CMake module with compiler flags to suppress errors

## How to Use

1. Run `flutter clean` to clean your project
2. Run `flutter pub get` to fetch dependencies
3. From the Windows directory, run the master script:
   ```
   cd windows
   .\fix_firebase_all.ps1
   ```
4. Build your Flutter app for Windows:
   ```
   flutter build windows
   ```

## What the Fixes Address

### 1. CMakeLists.txt Fixes

The scripts correct several issues in the Firebase plugins' CMakeLists.txt files:
- Missing target_compile_definitions
- Incomplete platform definitions
- Missing WINDOWS_DESKTOP=1 flag

### 2. Variant Compatibility Issues

Addresses C2665 errors related to variant type conversions in the Firebase Auth plugin by:
- Adding preprocessor definitions to disable deprecated standard conversions
- Fixing encodable_value.h conversions
- Adding compiler flags to suppress specific warnings

### 3. Project-wide Compiler Options

Adds Windows-specific compiler options to the project CMakeLists.txt to:
- Disable specific warnings that occur with Firebase
- Set compatibility modes for C++ standards
- Ensure consistent compilation across all plugins

### CMake Deprecation Warning

The Firebase C++ SDK uses an older format for specifying minimum CMake version requirements:

```
CMake Deprecation Warning at [...]/firebase_cpp_sdk_windows/CMakeLists.txt:17 (cmake_minimum_required):
  Compatibility with CMake < 3.5 will be removed from a future version of
  CMake.
```

**Fix**: The script updates the CMake version requirement to use the modern range format:
```cmake
cmake_minimum_required(VERSION 3.5...3.27)
```

### Macro Redefinition Errors

When compiling the Firebase Auth plugin, you may encounter macro redefinition errors:

```
error C2220: the following warning is treated as an error
warning C4005: '_SILENCE_CXX17_CODECVT_HEADER_DEPRECATION_WARNING': macro redefinition
warning C4005: '_SILENCE_ALL_CXX17_DEPRECATION_WARNINGS': macro redefinition
warning C4005: '_ALLOW_DEPRECATED_STDCONV': macro redefinition
```

**Fix**: The script adds proper `#ifndef` guards around the macro definitions to prevent redefinition.

### LogInfo Function Not Found

The Firebase Auth plugin attempts to use a non-existent `firebase::LogInfo` function:

```
error C2039: 'LogInfo': is not a member of 'firebase' 
error C3861: 'LogInfo': identifier not found
```

**Fix**: The script replaces the `LogInfo` call with a standard `printf` debug message wrapped in an `#ifdef _DEBUG` block.

### Std::Variant Conversion Error (C2665)

The Flutter encodable_value.h file has a template constructor that causes compatibility issues with Firebase's variant types:

```
error C2665: 'std::variant<...>::variant': no overloaded function could convert all the argument types
```

This error occurs because the Firebase Variant types don't properly convert to Flutter EncodableValue variants.

**Fix**: The script applies two levels of fixes:

1. **EncodableValue constructor fix**:
   - Uses `std::forward<T>(t)` to properly handle argument forwarding
   - Adds a special case constructor for std::variant types

2. **Firebase Variant conversion fix**:
   - Modifies the `ConvertToEncodableValue` function to use explicit static casts
   - Wraps blob/map conversions in proper type-safe containers
   - Improves the `ConvertToEncodableMap` function to skip incompatible key types
   - Uses `std::move` semantics for better performance

## Known Issues and Fixes

### Firebase Auth RegisterLibrary Error

The Firebase Auth plugin tries to call `App::RegisterLibrary()` which doesn't exist in Firebase C++ SDK 11.x+. This results in a compilation error:

```
error C2039: 'RegisterLibrary': is not a member of 'firebase::App'
```

**Fix**: The script patches firebase_auth_plugin.cpp to replace the RegisterLibrary call with a compatible logging alternative.

## Troubleshooting

If you encounter additional issues:

1. Check that all scripts were executed successfully
2. Verify that the Flutter ephemeral directory contains the plugin symlinks
3. Run `flutter clean` and try again
4. For persistent issues, check the CMake build logs for specific errors

## Note on Plugin Updates

These fixes may need to be reapplied after updating Firebase plugins. When updating:

1. Run `flutter clean` and `flutter pub get` to update dependencies
2. Re-run the fix script: `.\fix_firebase_all.ps1` 