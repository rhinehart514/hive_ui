# Script to fix encodable_value.h for Firebase compatibility
Write-Host "====================================================="
Write-Host "Fixing encodable_value.h for Firebase compatibility"
Write-Host "====================================================="

$encodable_value_path = ".\flutter\ephemeral\cpp_client_wrapper\include\flutter\encodable_value.h"

if (Test-Path $encodable_value_path) {
    Write-Host "Found encodable_value.h, creating backup..."
    
    # Create backup
    Copy-Item $encodable_value_path "$encodable_value_path.bak" -Force
    Write-Host "Created backup at $encodable_value_path.bak"
    
    # Read content
    $content = Get-Content $encodable_value_path -Raw
    
    # Fix the variant conversion issues
    # This adds a constructor that allows implicit conversion from different types
    $pattern = "public:\s+// Converts a custom type to a CustomEncodableValue"
    $replacement = "public:
  // Additional constructor for implicit type conversion to help with Firebase SDK compatibility
  template <typename T, 
            typename = std::enable_if_t<!std::is_same<std::decay_t<T>, EncodableValue>::value && 
                                         !std::is_constructible<std::decay_t<T>, CustomEncodableValue>::value>,
            typename = void>
  EncodableValue(T&& value) : EncodableValue(std::forward<T>(value)) {}

  // Converts a custom type to a CustomEncodableValue"
    
    $fixed_content = $content -replace $pattern, $replacement
    
    # Write fixed content
    if ($fixed_content -ne $content) {
        Set-Content -Path $encodable_value_path -Value $fixed_content
        Write-Host "Fixed encodable_value.h for Firebase compatibility" -ForegroundColor Green
    } else {
        Write-Host "No changes were needed or pattern not found" -ForegroundColor Yellow
    }
} else {
    Write-Host "Error: Cannot find encodable_value.h at $encodable_value_path" -ForegroundColor Red
} 