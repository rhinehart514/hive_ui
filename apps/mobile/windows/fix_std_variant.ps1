# Script to fix std::variant compatibility issues for Firebase Auth plugin
Write-Host "====================================================="
Write-Host "Fixing std::variant compatibility in Firebase Auth"
Write-Host "====================================================="

$auth_cmake_path = ".\flutter\ephemeral\.plugin_symlinks\firebase_auth\windows\CMakeLists.txt"

if (Test-Path $auth_cmake_path) {
    Write-Host "Found Firebase Auth CMakeLists.txt..."
    
    # Create backup
    Copy-Item $auth_cmake_path "$auth_cmake_path.variant_fix_full" -Force
    Write-Host "Created backup at $auth_cmake_path.variant_fix_full"
    
    # Read content
    $content = Get-Content $auth_cmake_path -Raw
    
    # Add comprehensive set of compiler flags to fix variant compatibility
    if ($content -notmatch "_SILENCE_ALL_CXX17_DEPRECATION_WARNINGS") {
        # Find the target_compile_definitions line
        $pattern = "(target_compile_definitions\(\S+\s+PRIVATE\s+-DINTERNAL_EXPERIMENTAL=1\))"
        $replacement = "$1`n
# Disable deprecated std conversions to fix variant compatibility issues
target_compile_definitions(`${PLUGIN_NAME} PRIVATE _HAS_DEPRECATED_STDCONV=0)
target_compile_definitions(`${PLUGIN_NAME} PRIVATE _SILENCE_CXX17_CODECVT_HEADER_DEPRECATION_WARNING)
target_compile_definitions(`${PLUGIN_NAME} PRIVATE _SILENCE_ALL_CXX17_DEPRECATION_WARNINGS)
target_compile_definitions(`${PLUGIN_NAME} PRIVATE _ALLOW_DEPRECATED_STDCONV)

# Add additional C++17 flags
target_compile_options(`${PLUGIN_NAME} PRIVATE /std:c++17)
target_compile_options(`${PLUGIN_NAME} PRIVATE /wd4996)
"
        
        $fixed_content = $content -replace $pattern, $replacement
        
        # Write fixed content
        if ($fixed_content -ne $content) {
            Set-Content -Path $auth_cmake_path -Value $fixed_content
            Write-Host "Added comprehensive variant compatibility fixes to Firebase Auth CMakeLists.txt" -ForegroundColor Green
        } else {
            Write-Host "No changes were made, pattern not found" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Variant compatibility fixes already applied" -ForegroundColor Gray
    }
} else {
    Write-Host "Error: Cannot find Firebase Auth CMakeLists.txt at $auth_cmake_path" -ForegroundColor Red
}

# Check for plugin source files
$firebase_auth_plugin_cpp = ".\flutter\ephemeral\.plugin_symlinks\firebase_auth\windows\firebase_auth_plugin.cpp"
if (Test-Path $firebase_auth_plugin_cpp) {
    Write-Host "Found Firebase Auth plugin CPP file..."
    
    # Create backup
    Copy-Item $firebase_auth_plugin_cpp "$firebase_auth_plugin_cpp.variant_fix_full" -Force
    Write-Host "Created backup at $firebase_auth_plugin_cpp.variant_fix_full"
    
    # Read content
    $content = Get-Content $firebase_auth_plugin_cpp -Raw
    
    # Add compiler guards for variant conversion
    $includes_pattern = "#include ""firebase_auth_plugin\.h"""
    $includes_replacement = "#include ""firebase_auth_plugin.h""

// Fix for variant conversion issues
#define _HAS_DEPRECATED_STDCONV 0
#define _SILENCE_CXX17_CODECVT_HEADER_DEPRECATION_WARNING
#define _SILENCE_ALL_CXX17_DEPRECATION_WARNINGS
#define _ALLOW_DEPRECATED_STDCONV
"
    
    $fixed_content = $content -replace $includes_pattern, $includes_replacement
    
    # Write fixed content
    if ($fixed_content -ne $content) {
        Set-Content -Path $firebase_auth_plugin_cpp -Value $fixed_content
        Write-Host "Added variant compatibility fixes to Firebase Auth plugin CPP file" -ForegroundColor Green
    } else {
        Write-Host "No changes were made to CPP file, pattern not found" -ForegroundColor Yellow
    }
} else {
    Write-Host "Error: Cannot find Firebase Auth plugin CPP file at $firebase_auth_plugin_cpp" -ForegroundColor Red
}

# Create a file to patch the flutter embedder
$flutter_embedder_dir = ".\flutter\ephemeral\cpp_client_wrapper\include\flutter"
$flutter_embedder_patch_path = "$flutter_embedder_dir\additional_variant_fixes.h"

if (-not (Test-Path $flutter_embedder_patch_path)) {
    # Ensure the directory exists
    if (-not (Test-Path $flutter_embedder_dir)) {
        Write-Host "Creating directory structure $flutter_embedder_dir..."
        New-Item -ItemType Directory -Path $flutter_embedder_dir -Force | Out-Null
    }

    Write-Host "Creating additional variant fixes header file..."
    
    $patch_content = @"
// Auto-generated header to fix variant compatibility issues
#pragma once

#ifndef _HAS_DEPRECATED_STDCONV
#define _HAS_DEPRECATED_STDCONV 0
#endif

#ifndef _SILENCE_CXX17_CODECVT_HEADER_DEPRECATION_WARNING
#define _SILENCE_CXX17_CODECVT_HEADER_DEPRECATION_WARNING
#endif

#ifndef _SILENCE_ALL_CXX17_DEPRECATION_WARNINGS
#define _SILENCE_ALL_CXX17_DEPRECATION_WARNINGS
#endif

#ifndef _ALLOW_DEPRECATED_STDCONV
#define _ALLOW_DEPRECATED_STDCONV
#endif
"@
    
    Set-Content -Path $flutter_embedder_patch_path -Value $patch_content
    Write-Host "Created additional variant fixes header file at $flutter_embedder_patch_path" -ForegroundColor Green
    
    # Patch encodable_value.h to include our fixes
    $encodable_value_h = ".\flutter\ephemeral\cpp_client_wrapper\include\flutter\encodable_value.h"
    if (Test-Path $encodable_value_h) {
        Write-Host "Patching encodable_value.h..."
        
        # Create backup
        Copy-Item $encodable_value_h "$encodable_value_h.backup" -Force
        
        # Read content
        $content = Get-Content $encodable_value_h -Raw
        
        # Add include for our fixes at the beginning of the file
        $fixed_content = $content -replace "(#pragma once)", "$1`n`n#include ""additional_variant_fixes.h"""
        
        # Write fixed content
        if ($fixed_content -ne $content) {
            Set-Content -Path $encodable_value_h -Value $fixed_content
            Write-Host "Added include for variant fixes to encodable_value.h" -ForegroundColor Green
        } else {
            Write-Host "No changes were made to encodable_value.h" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "Comprehensive variant compatibility fixes completed!" -ForegroundColor Green
Write-Host "=====================================================" 
Write-Host "Next step: Clean and rebuild your project"
Write-Host "Run: flutter clean && flutter pub get && flutter build windows" 