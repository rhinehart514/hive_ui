# Script to directly fix the variant error in encodable_value.h
Write-Host "====================================================="
Write-Host "Directly fixing variant error in encodable_value.h"
Write-Host "====================================================="

$encodable_value_path = ".\flutter\ephemeral\cpp_client_wrapper\include\flutter\encodable_value.h"

if (Test-Path $encodable_value_path) {
    Write-Host "Found encodable_value.h, creating backup..."
    
    # Create backup
    Copy-Item $encodable_value_path "$encodable_value_path.bak" -Force
    Write-Host "Created backup at $encodable_value_path.bak"
    
    # Read file
    $content = Get-Content $encodable_value_path -Raw
    
    # Add preprocessor definitions at the top
    if ($content -notmatch "#define _HAS_DEPRECATED_STDCONV 0") {
        $pattern = "(#ifndef FLUTTER_SHELL_PLATFORM_COMMON_CLIENT_WRAPPER_INCLUDE_FLUTTER_ENCODABLE_VALUE_H_)"
        $replacement = "$1

// Fix for Firebase variant compatibility issues
#ifndef _HAS_DEPRECATED_STDCONV
#define _HAS_DEPRECATED_STDCONV 0
#endif
#ifndef _SILENCE_CXX17_CODECVT_HEADER_DEPRECATION_WARNING
#define _SILENCE_CXX17_CODECVT_HEADER_DEPRECATION_WARNING
#endif
#ifndef _SILENCE_ALL_CXX17_DEPRECATION_WARNINGS
#define _SILENCE_ALL_CXX17_DEPRECATION_WARNINGS
#endif"
        $fixed_content = $content -replace $pattern, $replacement
    } else {
        $fixed_content = $content
    }
    
    # Fix the variant constructor to use std::forward
    $constructor_pattern = "(template <class T>\r?\n\s*constexpr explicit EncodableValue\(T&&\s+t\)\s+noexcept\s*:?\s*super\(t\)\s*\{\})"
    $constructor_replacement = "template <class T>
  constexpr explicit EncodableValue(T&& t) noexcept 
      : super(std::forward<T>(t)) {}

  // Block implicit conversion from variant types that are incompatible with flutter::EncodableValue
  // This prevents C2665 errors when firebase::Variant is silently converted to std::variant
  template <typename... Args>
  EncodableValue(const std::variant<Args...>& v) = delete;"
    
    $fixed_content = $fixed_content -replace $constructor_pattern, $constructor_replacement
    
    # Write fixed content
    if ($fixed_content -ne $content) {
        Set-Content -Path $encodable_value_path -Value $fixed_content
        Write-Host "Fixed variant error in encodable_value.h" -ForegroundColor Green
    } else {
        Write-Host "No changes were made, pattern not found" -ForegroundColor Yellow
    }
} else {
    Write-Host "Error: Cannot find encodable_value.h at $encodable_value_path" -ForegroundColor Red
}

# Also create a helper header file that can be included in Firebase plugins
$helper_header_path = ".\flutter\ephemeral\cpp_client_wrapper\include\flutter\firebase_variant_fix.h"
$helper_content = @"
// Auto-generated helper header to fix Firebase variant compatibility issues
#pragma once

// Disable deprecated conversions in variants
#ifndef _HAS_DEPRECATED_STDCONV
#define _HAS_DEPRECATED_STDCONV 0
#endif

// Silence codecvt deprecation warnings
#ifndef _SILENCE_CXX17_CODECVT_HEADER_DEPRECATION_WARNING
#define _SILENCE_CXX17_CODECVT_HEADER_DEPRECATION_WARNING
#endif

// Silence all C++17 deprecation warnings
#ifndef _SILENCE_ALL_CXX17_DEPRECATION_WARNINGS
#define _SILENCE_ALL_CXX17_DEPRECATION_WARNINGS
#endif

// Mark Windows desktop explicitly
#ifndef WINDOWS_DESKTOP
#define WINDOWS_DESKTOP 1
#endif
"@

# Create directory if it doesn't exist
$helper_dir = Split-Path $helper_header_path
if (-not (Test-Path $helper_dir)) {
    New-Item -ItemType Directory -Path $helper_dir -Force | Out-Null
}

# Write helper header
Set-Content -Path $helper_header_path -Value $helper_content
if (Test-Path $helper_header_path) {
    Write-Host "Created helper header at $helper_header_path" -ForegroundColor Green
} else {
    Write-Host "Failed to create helper header" -ForegroundColor Red
}

Write-Host ""
Write-Host "Variant fix completed!" -ForegroundColor Green
Write-Host "=====================================================" 