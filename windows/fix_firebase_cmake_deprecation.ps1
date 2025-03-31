# Script to fix CMake deprecation warning in Firebase C++ SDK
Write-Host "====================================================="
Write-Host "Fixing CMake deprecation warning in Firebase C++ SDK"
Write-Host "====================================================="

$firebase_sdk_cmake = "..\build\windows\x64\extracted\firebase_cpp_sdk_windows\CMakeLists.txt"

if (Test-Path $firebase_sdk_cmake) {
    Write-Host "Found Firebase SDK CMakeLists.txt..."
    
    # Create backup
    Copy-Item $firebase_sdk_cmake "$firebase_sdk_cmake.bak" -Force
    Write-Host "Created backup at $firebase_sdk_cmake.bak"
    
    # Read content
    $content = Get-Content $firebase_sdk_cmake -Raw
    
    # Replace the cmake_minimum_required line
    $pattern = "cmake_minimum_required\(VERSION 3\.1\)"
    $replacement = "cmake_minimum_required(VERSION 3.5...3.27)"
    
    $fixed_content = $content -replace $pattern, $replacement
    
    # Write fixed content
    if ($fixed_content -ne $content) {
        Set-Content -Path $firebase_sdk_cmake -Value $fixed_content
        Write-Host "Fixed CMake deprecation warning in Firebase SDK" -ForegroundColor Green
    } else {
        Write-Host "No changes were made, pattern not found" -ForegroundColor Yellow
    }
} else {
    Write-Host "Error: Cannot find Firebase SDK CMakeLists.txt at $firebase_sdk_cmake" -ForegroundColor Red
}

Write-Host ""
Write-Host "CMake deprecation fix completed!" -ForegroundColor Green
Write-Host "=====================================================" 