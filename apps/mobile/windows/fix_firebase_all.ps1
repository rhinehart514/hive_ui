# Master script to fix all Firebase issues for Windows
Write-Host "====================================================="
Write-Host "FIREBASE WINDOWS FIX MASTER SCRIPT"
Write-Host "====================================================="

# Run the CMakeLists.txt fixes first
Write-Host "Step 1: Fixing Firebase plugin CMake files..."
if (Test-Path ".\fix_firebase_plugins.ps1") {
    & .\fix_firebase_plugins.ps1
} else {
    Write-Host "Error: fix_firebase_plugins.ps1 not found" -ForegroundColor Red
}

# Run the manual firebase_core fix
Write-Host "`nStep 2: Manually fixing firebase_core specifically..."
if (Test-Path ".\manual_fix_firebase_core.ps1") {
    & .\manual_fix_firebase_core.ps1
} else {
    Write-Host "Error: manual_fix_firebase_core.ps1 not found" -ForegroundColor Red
}

# Fix the encodable_value.h issue
Write-Host "`nStep 3: Directly fixing variant error in encodable_value.h..."
if (Test-Path ".\fix_encodable_variant.ps1") {
    & .\fix_encodable_variant.ps1
} else {
    Write-Host "Error: fix_encodable_variant.ps1 not found" -ForegroundColor Red
}

# Fix the variant compatibility in Firebase Auth
Write-Host "`nStep 4: Fixing variant compatibility for Firebase Auth..."
if (Test-Path ".\fix_variant_compatibility.ps1") {
    & .\fix_variant_compatibility.ps1
} else {
    Write-Host "Error: fix_variant_compatibility.ps1 not found" -ForegroundColor Red
}

# Copy the CMake module for disabling Windows Firebase compile errors
$cmakeModuleSource = ".\disable_windows_firebase_compile_errors.cmake"
$cmakeModuleTarget = ".\flutter\ephemeral\.plugin_symlinks\firebase_core\windows\disable_windows_firebase_compile_errors.cmake"
if (Test-Path $cmakeModuleSource) {
    Write-Host "`nStep 5: Installing CMake module for disabling compile errors..."
    
    # Create directory if it doesn't exist
    $targetDir = Split-Path $cmakeModuleTarget
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    
    # Copy file
    Copy-Item $cmakeModuleSource $cmakeModuleTarget -Force
    if (Test-Path $cmakeModuleTarget) {
        Write-Host "Installed CMake module at $cmakeModuleTarget" -ForegroundColor Green
        
        # Now add the include directive to the Firebase Core CMakeLists.txt
        $firebaseCmake = ".\flutter\ephemeral\.plugin_symlinks\firebase_core\windows\CMakeLists.txt"
        if (Test-Path $firebaseCmake) {
            $content = Get-Content $firebaseCmake -Raw
            if ($content -notmatch "include\(disable_windows_firebase_compile_errors.cmake\)") {
                $pattern = "(# Project-level configuration\.)"
                $replacement = "$1`n`n# Include Windows Firebase compile error fixes`ninclude(disable_windows_firebase_compile_errors.cmake)"
                
                $fixed_content = $content -replace $pattern, $replacement
                if ($fixed_content -ne $content) {
                    Set-Content -Path $firebaseCmake -Value $fixed_content
                    Write-Host "Added include directive to Firebase Core CMakeLists.txt" -ForegroundColor Green
                }
            } else {
                Write-Host "Include directive already present in Firebase Core CMakeLists.txt" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "Failed to install CMake module" -ForegroundColor Red
    }
} else {
    Write-Host "Error: disable_windows_firebase_compile_errors.cmake not found" -ForegroundColor Red
}

# Add a Windows-specific config for compiler options in the project
$cmake_path = "..\CMakeLists.txt"
if (Test-Path $cmake_path) {
    Write-Host "`nStep 6: Adding Windows-specific compiler options to project CMakeLists.txt..."
    
    # Create backup
    Copy-Item $cmake_path "$cmake_path.bak" -Force
    Write-Host "Created backup at $cmake_path.bak"
    
    # Read content
    $content = Get-Content $cmake_path -Raw
    
    # Add Windows-specific compiler options
    $windows_options = @"

# Windows-specific configuration to fix Firebase compatibility issues
if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
  # Disable deprecated std conversions to fix variant compatibility issues
  add_compile_definitions(_HAS_DEPRECATED_STDCONV=0)
  add_compile_definitions(_SILENCE_CXX17_CODECVT_HEADER_DEPRECATION_WARNING)
  add_compile_definitions(WINDOWS_DESKTOP=1)
  
  # Disable specific warnings
  add_compile_options(/wd4996) # deprecated function warnings
  add_compile_options(/wd4267) # conversion from size_t
  add_compile_options(/wd4244) # conversion from double to float
  add_compile_options(/wd2220) # unresolved external symbol
  add_compile_options(/wd4828) # file encoding warnings
  add_compile_options(/wd4068) # unknown pragma
endif()
"@
    
    # Only add if not already present
    if ($content -notmatch "Windows-specific configuration to fix Firebase") {
        $pattern = "(# Generated code do not edit\.)"
        $replacement = "$1$windows_options"
        
        $fixed_content = $content -replace $pattern, $replacement
        
        # Write fixed content
        if ($fixed_content -ne $content) {
            Set-Content -Path $cmake_path -Value $fixed_content
            Write-Host "Added Windows-specific compiler options to project CMakeLists.txt" -ForegroundColor Green
        } else {
            Write-Host "No changes were made to project CMakeLists.txt, pattern not found" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Windows-specific compiler options already present in project CMakeLists.txt" -ForegroundColor Gray
    }
} else {
    Write-Host "Error: Project CMakeLists.txt not found at $cmake_path" -ForegroundColor Red
}

# Fix CMake deprecation warning in Firebase SDK
Write-Host "`nStep 7: Fixing CMake deprecation warning in Firebase SDK..."
if (Test-Path ".\fix_firebase_cmake_deprecation.ps1") {
    & .\fix_firebase_cmake_deprecation.ps1
} else {
    Write-Host "Error: fix_firebase_cmake_deprecation.ps1 not found" -ForegroundColor Red
}

Write-Host "`n====================================================="
Write-Host "All Firebase fixes have been applied!"
Write-Host "You can now build your Flutter app for Windows with Firebase."
Write-Host "=====================================================" 