# Script to patch Firebase plugin files for Windows build compatibility

Write-Host "Starting Firebase plugin patching..." -ForegroundColor Cyan

# Check if the ephemeral directory exists
$pluginDir = "flutter/ephemeral/.plugin_symlinks/firebase_auth/windows"
if (-not (Test-Path $pluginDir)) {
    Write-Host "Plugin directory not found. Run 'flutter pub get' first." -ForegroundColor Red
    exit 1
}

# Patch firebase_auth_plugin.cpp
$authPluginFile = "$pluginDir/firebase_auth_plugin.cpp"
if (Test-Path $authPluginFile) {
    Write-Host "Patching $authPluginFile..." -ForegroundColor Green
    
    # Read the file content
    $content = Get-Content $authPluginFile -Raw
    
    # Replace UpdateEmailAsync with UpdateEmail
    $content = $content -replace "UpdateEmailAsync", "UpdateEmail"
    
    # Replace UpdatePasswordAsync with UpdatePassword
    $content = $content -replace "UpdatePasswordAsync", "UpdatePassword"
    
    # Write back the patched content
    Set-Content -Path $authPluginFile -Value $content
    
    Write-Host "Patched $authPluginFile successfully!" -ForegroundColor Green
} else {
    Write-Host "File $authPluginFile not found!" -ForegroundColor Yellow
}

# Patch firebase_auth CMakeLists.txt to disable warnings
$cmakeFile = "$pluginDir/CMakeLists.txt"
if (Test-Path $cmakeFile) {
    Write-Host "Patching $cmakeFile..." -ForegroundColor Green
    
    # Read the file content
    $content = Get-Content $cmakeFile -Raw
    
    # Add compiler option to disable deprecated warnings if not already present
    if (-not ($content -match "target_compile_options\(\$\{PLUGIN_NAME\} PRIVATE.*/wd4996")) {
        $content = $content -replace "apply_standard_settings\(\$\{PLUGIN_NAME\}\)",`
            "apply_standard_settings(`${PLUGIN_NAME})`n`n# Disable deprecated warnings to prevent compilation errors`ntarget_compile_options(`${PLUGIN_NAME} PRIVATE `"/wd4996`")"
    }
    
    # Write back the patched content
    Set-Content -Path $cmakeFile -Value $content
    
    Write-Host "Patched $cmakeFile successfully!" -ForegroundColor Green
} else {
    Write-Host "File $cmakeFile not found!" -ForegroundColor Yellow
}

# Patch main CMakeLists.txt to disable warnings globally
$mainCmakeFile = "../CMakeLists.txt"
if (Test-Path $mainCmakeFile) {
    Write-Host "Patching $mainCmakeFile..." -ForegroundColor Green
    
    # Read the file content
    $content = Get-Content $mainCmakeFile -Raw
    
    # Add compiler option to disable deprecated warnings in the APPLY_STANDARD_SETTINGS function
    if (-not ($content -match "target_compile_options\(\$\{TARGET\} PRIVATE /wd`"4996`"\)")) {
        $content = $content -replace "target_compile_definitions\(\$\{TARGET\} PRIVATE `"\$<\$\<CONFIG:Debug\>:_DEBUG\>`"\)",`
            "target_compile_options(`${TARGET} PRIVATE /wd`"4996`") # Disable deprecated warnings`n  target_compile_definitions(`${TARGET} PRIVATE `"`$<`$<CONFIG:Debug>:_DEBUG>`")"
    }
    
    # Write back the patched content
    Set-Content -Path $mainCmakeFile -Value $content
    
    Write-Host "Patched $mainCmakeFile successfully!" -ForegroundColor Green
} else {
    Write-Host "File $mainCmakeFile not found!" -ForegroundColor Yellow
}

Write-Host "Firebase plugin patching completed!" -ForegroundColor Cyan 