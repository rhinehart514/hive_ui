# Manual fix for firebase_core CMake file
Write-Host "Manually fixing firebase_core CMake file..."

$cmake_path = ".\flutter\ephemeral\.plugin_symlinks\firebase_core\windows\CMakeLists.txt"

if (Test-Path $cmake_path) {
    # Read content
    $content = Get-Content $cmake_path -Raw
    
    # Create backup 
    Copy-Item $cmake_path "$cmake_path.manual_backup" -Force
    Write-Host "Created backup at $cmake_path.manual_backup"
    
    # Fix the specific issue by removing redundant lines and ensuring proper closure
    $fixed_content = $content -replace "target_compile_definitions\(firebase_core_plugin PRIVATE WINDOWS_DESKTOP=1(?!\))[^\r\n]*[\r\n]+", ""
    
    # Ensure there's exactly one correct definition at the end
    if ($fixed_content -notmatch "target_compile_definitions\(firebase_core_plugin PRIVATE WINDOWS_DESKTOP=1\)") {
        $fixed_content = $fixed_content.TrimEnd()
        $fixed_content += "`n`n# Add Windows desktop define for Firebase compatibility`ntarget_compile_definitions(firebase_core_plugin PRIVATE WINDOWS_DESKTOP=1)`n"
    }
    
    # Write fixed content
    Set-Content -Path $cmake_path -Value $fixed_content
    Write-Host "Finished fixing firebase_core CMake file" -ForegroundColor Green
    
    # Verify fix
    $verification = Get-Content $cmake_path -Raw
    if ($verification -match "target_compile_definitions\(firebase_core_plugin PRIVATE WINDOWS_DESKTOP=1\)[^\r\n]*[\r\n]") {
        Write-Host "Verification passed: Fix applied correctly" -ForegroundColor Green
    } else {
        Write-Host "Verification failed: Fix may not have been applied correctly" -ForegroundColor Red
    }
} else {
    Write-Host "Error: Cannot find firebase_core CMake file at $cmake_path" -ForegroundColor Red
} 