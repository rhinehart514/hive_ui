# Script to fix variant compatibility issues for Firebase Auth
Write-Host "====================================================="
Write-Host "Fixing variant compatibility for Firebase Auth plugin"
Write-Host "====================================================="

$auth_cmake_path = ".\flutter\ephemeral\.plugin_symlinks\firebase_auth\windows\CMakeLists.txt"

if (Test-Path $auth_cmake_path) {
    Write-Host "Found Firebase Auth CMakeLists.txt..."
    
    # Create backup
    Copy-Item $auth_cmake_path "$auth_cmake_path.variant_fix" -Force
    Write-Host "Created backup at $auth_cmake_path.variant_fix"
    
    # Read content
    $content = Get-Content $auth_cmake_path -Raw
    
    # Add compile definitions to fix variant compatibility issues
    if ($content -notmatch "_HAS_DEPRECATED_STDCONV=0") {
        # Find the target_compile_definitions line for INTERNAL_EXPERIMENTAL
        $pattern = "(target_compile_definitions\(\S+\s+PRIVATE\s+-DINTERNAL_EXPERIMENTAL=1\))"
        $replacement = "$1`n# Disable deprecated std conversions to fix variant compatibility issues`ntarget_compile_definitions(`${PLUGIN_NAME} PRIVATE _HAS_DEPRECATED_STDCONV=0)`ntarget_compile_definitions(`${PLUGIN_NAME} PRIVATE _SILENCE_CXX17_CODECVT_HEADER_DEPRECATION_WARNING)"
        
        $fixed_content = $content -replace $pattern, $replacement
        
        # Write fixed content
        if ($fixed_content -ne $content) {
            Set-Content -Path $auth_cmake_path -Value $fixed_content
            Write-Host "Added variant compatibility fixes to Firebase Auth CMakeLists.txt" -ForegroundColor Green
        } else {
            Write-Host "No changes were made, pattern not found" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Variant compatibility fixes already applied" -ForegroundColor Gray
    }
} else {
    Write-Host "Error: Cannot find Firebase Auth CMakeLists.txt at $auth_cmake_path" -ForegroundColor Red
}

$firebase_auth_plugin_cpp = ".\flutter\ephemeral\.plugin_symlinks\firebase_auth\windows\firebase_auth_plugin.cpp"
if (Test-Path $firebase_auth_plugin_cpp) {
    Write-Host "Found Firebase Auth plugin CPP file..."
    
    # Create backup
    Copy-Item $firebase_auth_plugin_cpp "$firebase_auth_plugin_cpp.variant_fix" -Force
    Write-Host "Created backup at $firebase_auth_plugin_cpp.variant_fix"
    
    # Read content
    $content = Get-Content $firebase_auth_plugin_cpp -Raw
    
    # Add compiler guards for variant conversion
    $includes_pattern = "#include ""firebase_auth_plugin\.h"""
    $includes_replacement = "#include ""firebase_auth_plugin.h""

// Fix for variant conversion issues
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
#endif"
    
    $fixed_content = $content -replace $includes_pattern, $includes_replacement
    
    # Fix the ConvertToEncodableValue function to avoid variant conversion issues
    $convert_value_pattern = "(case firebase::Variant::kTypeInt64:\r?\n\s*return EncodableValue\(variant\.int64_value\(\)\);\r?\n\s*case firebase::Variant::kTypeDouble:\r?\n\s*return EncodableValue\(variant\.double_value\(\)\);\r?\n\s*case firebase::Variant::kTypeBool:\r?\n\s*return EncodableValue\(variant\.bool_value\(\)\);\r?\n\s*case firebase::Variant::kTypeStaticString:\r?\n\s*return EncodableValue\(variant\.string_value\(\)\);\r?\n\s*case firebase::Variant::kTypeMutableString:\r?\n\s*return EncodableValue\(variant\.mutable_string\(\)\);\r?\n\s*case firebase::Variant::kTypeMap:\r?\n\s*return FirebaseAuthPlugin::ConvertToEncodableMap\(variant\.map\(\)\);\r?\n\s*case firebase::Variant::kTypeStaticBlob:\r?\n\s*return EncodableValue\(variant\.blob_data\(\)\);\r?\n\s*case firebase::Variant::kTypeMutableBlob:\r?\n\s*return EncodableValue\(variant\.mutable_blob_data\(\)\);)"
    
    $convert_value_replacement = @"
case firebase::Variant::kTypeInt64:
      return EncodableValue(static_cast<int64_t>(variant.int64_value()));
    case firebase::Variant::kTypeDouble:
      return EncodableValue(static_cast<double>(variant.double_value()));
    case firebase::Variant::kTypeBool:
      return EncodableValue(static_cast<bool>(variant.bool_value()));
    case firebase::Variant::kTypeStaticString:
      return EncodableValue(std::string(variant.string_value()));
    case firebase::Variant::kTypeMutableString:
      return EncodableValue(std::string(variant.mutable_string()));
    case firebase::Variant::kTypeMap: {
      // Handle map conversion with explicit type construction
      EncodableMap result;
      for (const auto& kv : variant.map()) {
        const auto& key = kv.first;
        const auto& value = kv.second;
        // Recursively convert key and value
        result[ConvertToEncodableValue(key)] = ConvertToEncodableValue(value);
      }
      return EncodableValue(result);
    }
    case firebase::Variant::kTypeStaticBlob: {
      // Convert blob to std::vector<uint8_t>
      const uint8_t* data = static_cast<const uint8_t*>(variant.blob_data());
      size_t size = variant.blob_size();
      std::vector<uint8_t> blob_vector(data, data + size);
      return EncodableValue(blob_vector);
    }
    case firebase::Variant::kTypeMutableBlob: {
      // Convert mutable blob to std::vector<uint8_t>
      const uint8_t* data = static_cast<const uint8_t*>(variant.mutable_blob_data());
      size_t size = variant.blob_size();
      std::vector<uint8_t> blob_vector(data, data + size);
      return EncodableValue(blob_vector);
    }
"@
    
    $fixed_content = $fixed_content -replace $convert_value_pattern, $convert_value_replacement
    
    # Fix the ConvertToEncodableMap function
    $convert_map_pattern = "(for \(const auto& kv : originalMap\) \{\r?\n\s*EncodableValue key = ConvertToEncodableValue\(\r?\n\s*kv\.first\);.*\r?\n\s*EncodableValue value = ConvertToEncodableValue\(\r?\n\s*kv\.second\);.*\r?\n\s*convertedMap\[key\] = value;.*\r?\n\s*\})"
    
    $convert_map_replacement = @"
for (const auto& kv : originalMap) {
    // Skip entries with incompatible key types (EncodableValue key must be a string, int, etc.)
    if (kv.first.type() != firebase::Variant::kTypeStaticString && 
        kv.first.type() != firebase::Variant::kTypeMutableString &&
        kv.first.type() != firebase::Variant::kTypeInt64) {
      continue;
    }
    
    // Convert key and value with explicit function to avoid variant constructor
    EncodableValue key = ConvertToEncodableValue(kv.first);
    EncodableValue value = ConvertToEncodableValue(kv.second);
    
    // Only add to map if key conversion succeeded (not null)
    if (!key.IsNull()) {
      convertedMap.insert({std::move(key), std::move(value)});
    }
  }
"@
    
    $fixed_content = $fixed_content -replace $convert_map_pattern, $convert_map_replacement
    
    # Also fix LogInfo issue
    $loginfo_pattern = "firebase::LogInfo\(""Firebase Auth Plugin"", ""Initializing %s version %s"",[\r\n]+\s+kLibraryName\.c_str\(\), getPluginVersion\(\)\.c_str\(\)\);"
    $loginfo_replacement = "// Just log the version info for debugging - using printf instead of LogInfo
#ifdef _DEBUG
printf(""Firebase Auth Plugin: Initializing %s version %s\n"", 
      kLibraryName.c_str(), getPluginVersion().c_str());
#endif"
    
    $fixed_content = $fixed_content -replace $loginfo_pattern, $loginfo_replacement
    
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

Write-Host ""
Write-Host "Variant compatibility fixes completed!" -ForegroundColor Green
Write-Host "=====================================================" 