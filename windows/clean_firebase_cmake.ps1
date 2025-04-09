# Clean up corrupted Firebase plugin CMake files
Write-Host "====================================================="
Write-Host "Cleaning corrupted Firebase plugin CMake files"
Write-Host "====================================================="

$plugin_dir = "flutter\ephemeral\.plugin_symlinks"
$plugins = @(
    @{ name = "firebase_core"; target = "firebase_core_plugin"; extras = $true; },
    @{ name = "firebase_auth"; target = "firebase_auth_plugin"; extras = $false; },
    @{ name = "cloud_firestore"; target = "cloud_firestore_plugin"; extras = $false; },
    @{ name = "firebase_storage"; target = "firebase_storage_plugin"; extras = $false; }
)

foreach ($plugin in $plugins) {
    $name = $plugin.name
    $target = $plugin.target
    $has_extras = $plugin.extras
    
    $cmake_path = Join-Path -Path $plugin_dir -ChildPath "$name\windows\CMakeLists.txt"
    
    if (Test-Path $cmake_path) {
        Write-Host "Cleaning $name CMakeLists.txt..."
        
        # Create backup
        Copy-Item $cmake_path "$cmake_path.backup" -Force
        
        # Read content and find the line with "PARENT_SCOPE"
        $content = Get-Content $cmake_path -Encoding UTF8
        $parent_scope_index = -1
        
        for ($i = 0; $i -lt $content.Length; $i++) {
            if ($content[$i] -match "PARENT_SCOPE") {
                $parent_scope_index = $i
                break
            }
        }
        
        if ($parent_scope_index -eq -1) {
            # If PARENT_SCOPE not found, find another good cutoff point
            for ($i = 0; $i -lt $content.Length; $i++) {
                if ($content[$i] -match "bundled_libraries") {
                    $parent_scope_index = $i + 2  # Go 2 lines past the bundled_libraries line
                    break
                }
            }
        }
        
        if ($parent_scope_index -eq -1) {
            Write-Host "Could not find a good cutoff point for $name, skipping..."
            continue
        }
        
        # Keep content up to the cutoff point
        $fixed_content = @()
        for ($i = 0; $i -le $parent_scope_index; $i++) {
            $fixed_content += $content[$i]
        }
        
        # Add FIREBASE_STUB define
        $fixed_content += ""
        $fixed_content += "# Add define to use stub implementation on Windows"
        $fixed_content += "target_compile_definitions($target PRIVATE FIREBASE_STUB)"
        
        # For firebase_core, add additional Windows-specific defines
        if ($has_extras) {
            $fixed_content += ""
            $fixed_content += "# Add Windows desktop define for Firebase compatibility"
            $fixed_content += "target_compile_definitions($target PRIVATE WINDOWS_DESKTOP=1)"
            
            $fixed_content += ""
            $fixed_content += "# Add Windows database support define"
            $fixed_content += "target_compile_definitions($target PRIVATE WINDOWS_DATABASE_SUPPORT=1)"
        }
        
        # Write clean content as UTF-8 without BOM
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllLines($cmake_path, $fixed_content, $utf8NoBom)
        
        Write-Host "Fixed $name CMakeLists.txt"
    }
    else {
        Write-Host "$name not found, skipping..."
    }
}

# Create plugin_version.h file for firebase_core
$plugin_version_dir = Join-Path -Path $plugin_dir -ChildPath "firebase_core\windows\firebase_core"

if (-not (Test-Path $plugin_version_dir)) {
    New-Item -ItemType Directory -Path $plugin_version_dir -Force | Out-Null
}

$plugin_version_file = Join-Path -Path $plugin_version_dir -ChildPath "plugin_version.h"

$plugin_version_content = @"
// Auto-generated plugin version file
#define FLUTTER_PLUGIN_VERSION "2.32.0"

#include <string>

inline std::string getPluginVersion() {
  return FLUTTER_PLUGIN_VERSION;
}
"@

Write-Host "Creating plugin_version.h file..."
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($plugin_version_file, $plugin_version_content, $utf8NoBom)
Write-Host "Created plugin_version.h file"

# Fix RegisterLibrary call in firebase_core_plugin.cpp
$firebase_core_cpp = Join-Path -Path $plugin_dir -ChildPath "firebase_core\windows\firebase_core_plugin.cpp"
if (Test-Path $firebase_core_cpp) {
    Write-Host "Fixing RegisterLibrary call in firebase_core_plugin.cpp..."
    
    # Create backup
    Copy-Item $firebase_core_cpp "$firebase_core_cpp.backup" -Force
    
    # Read content
    $cpp_content = Get-Content $firebase_core_cpp -Raw
    
    # Replace RegisterLibrary call
    $fixed_cpp = $cpp_content -replace 'App::RegisterLibrary\(kLibraryName\.c_str\(\), getPluginVersion\(\)\.c_str\(\),\s*nullptr\);', @'
#if FIREBASE_VERSION_MAJOR >= 11
  // Firebase SDK 11.x+ only takes the library name
  App::RegisterLibrary(kLibraryName.c_str());
#else
  // Older Firebase SDK versions take name and version
  App::RegisterLibrary(kLibraryName.c_str(), getPluginVersion().c_str(), nullptr);
#endif
'@
    
    # Write fixed content
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($firebase_core_cpp, $fixed_cpp, $utf8NoBom)
    Write-Host "Fixed RegisterLibrary call"
}

Write-Host "====================================================="
Write-Host "All Firebase files have been cleaned and fixed"
Write-Host "You can now build your Flutter app for Windows"
Write-Host "=====================================================" 