# Firebase Windows Compatibility Fixes

This directory contains patches and scripts to fix compilation issues with Firebase plugins on Windows.

## PigeonUserDetails and std::variant Issue

The primary issue addressed is a C++ compilation error related to `std::variant` in the Firebase Auth plugin:

```
error C2665: 'std::variant<...>::variant': no overloaded function could convert all the argument types
```

This occurs due to incompatibilities between the Firebase C++ SDK and Flutter's C++ wrapper code.

## How the Fix Works

1. **Compiler Flags**: We add several MSVC-specific compiler flags to suppress warnings and fix compatibility issues:
   - `/bigobj`: Increases the number of sections an object file can contain
   - `/wd4996`: Disables deprecated function warnings
   - `/wd4267`, `/wd4244`, `/wd4305`: Disable conversion warnings

2. **Preprocessor Definitions**: We add definitions to handle C++17 compatibility issues:
   - `_SILENCE_ALL_CXX17_DEPRECATION_WARNINGS`
   - `_HAS_STD_BYTE=0`
   - `_HAS_DEPRECATED_STDCONV=0`
   - `_ALLOW_DEPRECATED_STDCONV`

3. **Auto-Patching**: The CMake build process automatically runs `apply_firebase_fixes.ps1` which patches the Firebase Auth plugin's CMakeLists.txt file at build time.

## Maintaining the Fix

If you update the Firebase plugins, you may need to run the fix script again or adjust it based on new issues. The script checks if the patch has already been applied to avoid duplicate modifications.

To manually apply the fixes, run:

```powershell
cd windows
powershell -ExecutionPolicy Bypass -File apply_firebase_fixes.ps1
``` 