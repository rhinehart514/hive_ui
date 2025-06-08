# Fix all Firebase plugin CMake files for Windows compatibility
Write-Host "====================================================="
Write-Host "Fixing all Firebase plugin CMake files for Windows"
Write-Host "====================================================="

$plugin_dir = "flutter\ephemeral\.plugin_symlinks"

# Check if plugin directory exists
if (-not (Test-Path $plugin_dir)) {
    Write-Host "Plugin directory not found. Run 'flutter pub get' first."
    exit 1
}

$plugins = @("firebase_core", "firebase_auth", "cloud_firestore", "firebase_storage", "firebase_messaging")

foreach ($plugin in $plugins) {
    $plugin_path = Join-Path -Path $plugin_dir -ChildPath $plugin
    $cmake_path = Join-Path -Path $plugin_path -ChildPath "windows\CMakeLists.txt"
    
    if (Test-Path $cmake_path) {
        Write-Host "Processing $plugin..."
        
        # Create backup
        Copy-Item $cmake_path "$cmake_path.backup" -Force
        
        # Read content up to the last endif() or apply_standard_settings line
        $content = Get-Content $cmake_path
        $end_marker = $content | Select-String -Pattern "endif\(\)|apply_standard_settings" | Select-Object -Last 1
        
        if (-not $end_marker) {
            Write-Host "Could not find a suitable end marker in $plugin CMakeLists.txt, skipping..."
            continue
        }
        
        $end_marker_index = $end_marker.LineNumber
        
        # Keep content up to the marker and add our custom definitions
        $fixed_content = $content[0..($end_marker_index - 1)]
        $fixed_content += ""
        
        # Add FIREBASE_STUB define
        $fixed_content += "# Add define to use stub implementation on Windows"
        
        # Different plugins have different target names
        $target_name = "$($plugin)_plugin"
        $fixed_content += "target_compile_definitions($target_name PRIVATE FIREBASE_STUB)"
        
        # For firebase_core, add additional Windows-specific defines
        if ($plugin -eq "firebase_core") {
            $fixed_content += ""
            $fixed_content += "# Add Windows desktop define for Firebase compatibility"
            $fixed_content += "target_compile_definitions($target_name PRIVATE WINDOWS_DESKTOP=1)"
            
            $fixed_content += ""
            $fixed_content += "# Add Windows database support define"
            $fixed_content += "target_compile_definitions($target_name PRIVATE WINDOWS_DATABASE_SUPPORT=1)"
        }
        
        # Write fixed content with UTF-8 encoding (no BOM)
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllLines($cmake_path, $fixed_content, $utf8NoBom)
        
        Write-Host "Fixed $plugin CMakeLists.txt"
    }
    else {
        Write-Host "$plugin not found, skipping..."
    }
}

# Create plugin_version.h file for firebase_core
$firebase_core_path = Join-Path -Path $plugin_dir -ChildPath "firebase_core"
if (Test-Path $firebase_core_path) {
    $plugin_version_dir = Join-Path -Path $firebase_core_path -ChildPath "windows\firebase_core"
    
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
    $firebase_core_cpp = Join-Path -Path $firebase_core_path -ChildPath "windows\firebase_core_plugin.cpp"
    if (Test-Path $firebase_core_cpp) {
        Write-Host "Fixing RegisterLibrary call in firebase_core_plugin.cpp..."
        
        # Create backup
        Copy-Item $firebase_core_cpp "$firebase_core_cpp.backup" -Force
        
        $cpp_content = Get-Content $firebase_core_cpp -Raw
        $fixed_cpp = $cpp_content -replace 'App::RegisterLibrary\(kLibraryName\.c_str\(\), getPluginVersion\(\)\.c_str\(\),\s*nullptr\);', @'
#if FIREBASE_VERSION_MAJOR >= 11
  // Firebase SDK 11.x+ only takes the library name
  App::RegisterLibrary(kLibraryName.c_str());
#else
  // Older Firebase SDK versions take name and version
  App::RegisterLibrary(kLibraryName.c_str(), getPluginVersion().c_str(), nullptr);
#endif
'@
        
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($firebase_core_cpp, $fixed_cpp, $utf8NoBom)
        Write-Host "Fixed RegisterLibrary call"
    }
}

Write-Host "====================================================="
Write-Host "All Firebase CMake files have been fixed"
Write-Host "You can now build your Flutter app for Windows"
Write-Host "=====================================================" 