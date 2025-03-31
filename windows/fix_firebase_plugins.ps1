# Script to fix Firebase plugin CMake files for Windows
Write-Host "====================================================="
Write-Host "Fixing Firebase plugin CMake files for Windows"
Write-Host "====================================================="

# Use the correct path for plugins
$plugins_dir = ".\flutter\ephemeral\.plugin_symlinks"
$firebase_plugins = @(
    "firebase_core",
    "firebase_auth", 
    "cloud_firestore",
    "firebase_storage",
    "firebase_messaging"
)

foreach ($plugin in $firebase_plugins) {
    $cmake_path = "$plugins_dir\$plugin\windows\CMakeLists.txt"
    
    if (Test-Path $cmake_path) {
        Write-Host "Checking $plugin CMakeLists.txt..."
        
        # Read file content
        $content = Get-Content $cmake_path -Raw
        
        # Create backup
        Copy-Item $cmake_path "$cmake_path.bak" -Force
        Write-Host "  Created backup at $cmake_path.bak"
        
        # Fix common issues
        $fixed_content = $content
        
        # Fix 1: Remove duplicate target_compile_definitions for WINDOWS_DESKTOP
        $pattern = "target_compile_definitions\(\S+\s+PRIVATE\s+WINDOWS_DESKTOP=1(?!\))"
        if ($fixed_content -match $pattern) {
            Write-Host "  Found missing closing parenthesis in target_compile_definitions"
            # Remove all instances of the problematic lines
            $fixed_content = $fixed_content -replace "target_compile_definitions\(\S+\s+PRIVATE\s+WINDOWS_DESKTOP=1(?!\))[^\r\n]*[\r\n]+", ""
            
            # Add correct definition at the end of the file
            if ($fixed_content -notmatch "target_compile_definitions\(\S+\s+PRIVATE\s+WINDOWS_DESKTOP=1\)") {
                $fixed_content = $fixed_content.TrimEnd()
                $fixed_content += "`n`n# Add Windows desktop define for Firebase compatibility`ntarget_compile_definitions(${plugin}_plugin PRIVATE WINDOWS_DESKTOP=1)`n"
            }
        }
        
        # Write fixed content back if changes were made
        if ($fixed_content -ne $content) {
            Set-Content -Path $cmake_path -Value $fixed_content
            Write-Host "  Fixed issues in $plugin CMakeLists.txt" -ForegroundColor Green
        } else {
            Write-Host "  No issues found in $plugin CMakeLists.txt" -ForegroundColor Gray
        }
    } else {
        Write-Host "Skipping $plugin (not found)" -ForegroundColor Yellow
    }
}

# Fix Firebase Auth RegisterLibrary issue for SDK 11.x+
$auth_plugin_cpp = ".\flutter\ephemeral\.plugin_symlinks\firebase_auth\windows\firebase_auth_plugin.cpp"
if (Test-Path $auth_plugin_cpp) {
    Write-Host "Fixing RegisterLibrary incompatibility in Firebase Auth plugin..."
    
    # Create backup
    Copy-Item $auth_plugin_cpp "$auth_plugin_cpp.registerlib_fix" -Force
    Write-Host "Created backup at $auth_plugin_cpp.registerlib_fix"
    
    # Read content
    $content = Get-Content $auth_plugin_cpp -Raw
    
    # Replace RegisterLibrary call
    $pattern = "(^\s+binaryMessenger = registrar->messenger\(\);[\r\n]+)\s+// Register for platform logging[\r\n]+\s+App::RegisterLibrary\(kLibraryName\.c_str\(\), getPluginVersion\(\)\.c_str\(\),[\r\n]+\s+nullptr\);"
    $replacement = "$1
  // Firebase SDK 11.x+ no longer has RegisterLibrary method
  // App::RegisterLibrary(kLibraryName.c_str(), getPluginVersion().c_str(),
  //                     nullptr);
  
  // Just log the version info for debugging
  firebase::LogInfo(""Firebase Auth Plugin"", ""Initializing %s version %s"",
                    kLibraryName.c_str(), getPluginVersion().c_str());"
    
    $fixed_content = $content -replace $pattern, $replacement
    
    # Write fixed content
    if ($fixed_content -ne $content) {
        Set-Content -Path $auth_plugin_cpp -Value $fixed_content
        Write-Host "Fixed RegisterLibrary incompatibility in Firebase Auth plugin" -ForegroundColor Green
    } else {
        Write-Host "No changes were needed or pattern not found in Firebase Auth plugin" -ForegroundColor Yellow
    }
} else {
    Write-Host "Firebase Auth plugin not found at $auth_plugin_cpp" -ForegroundColor Red
}

Write-Host ""
Write-Host "Firebase plugin fixes completed!" -ForegroundColor Green
Write-Host "=====================================================" 