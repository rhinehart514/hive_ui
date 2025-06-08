# HIVE UI - Consolidation Analysis Script (PowerShell)
# This script analyzes the directories to be consolidated and generates reports

Write-Host "Starting HIVE UI consolidation analysis..." -ForegroundColor Cyan

# Make sure we're in the project root
if (-not (Test-Path "lib")) {
  Write-Host "Error: Run this script from the project root directory" -ForegroundColor Red
  exit 1
}

# Create migration directories
New-Item -Path "migration/profile_consolidation" -ItemType Directory -Force | Out-Null
New-Item -Path "migration/clubs_consolidation" -ItemType Directory -Force | Out-Null

Write-Host "1. Analyzing profile and profiles directories..." -ForegroundColor Cyan

# Generate file lists for profile directories
Get-ChildItem -Path "lib/features/profile" -File -Recurse | Select-Object -ExpandProperty FullName | Out-File -FilePath "migration/profile_consolidation/profile_files.txt"
Get-ChildItem -Path "lib/features/profiles" -File -Recurse | Select-Object -ExpandProperty FullName | Out-File -FilePath "migration/profile_consolidation/profiles_files.txt"

# Count files in each directory
$PROFILE_COUNT = (Get-Content -Path "migration/profile_consolidation/profile_files.txt" | Measure-Object -Line).Lines
$PROFILES_COUNT = (Get-Content -Path "migration/profile_consolidation/profiles_files.txt" | Measure-Object -Line).Lines

Write-Host "  Found $PROFILE_COUNT files in profile/ directory" -ForegroundColor White
Write-Host "  Found $PROFILES_COUNT files in profiles/ directory" -ForegroundColor White

# Find import references to profiles directory
$profileImports = Select-String -Path "lib/*.dart", "lib/**/*.dart" -Pattern "import.*profiles" -AllMatches
$profileImports | Out-File -FilePath "migration/profile_consolidation/profiles_imports.txt"
$PROFILES_IMPORTS_COUNT = $profileImports.Count
Write-Host "  Found $PROFILES_IMPORTS_COUNT references to profiles/ directory" -ForegroundColor White

Write-Host "2. Analyzing spaces and clubs directories..." -ForegroundColor Cyan

# Generate file lists for spaces and clubs directories
Get-ChildItem -Path "lib/features/spaces" -File -Recurse | Select-Object -ExpandProperty FullName | Out-File -FilePath "migration/clubs_consolidation/spaces_files.txt"
Get-ChildItem -Path "lib/features/clubs" -File -Recurse | Select-Object -ExpandProperty FullName | Out-File -FilePath "migration/clubs_consolidation/clubs_files.txt"

# Count files in each directory
$SPACES_COUNT = (Get-Content -Path "migration/clubs_consolidation/spaces_files.txt" | Measure-Object -Line).Lines
$CLUBS_COUNT = (Get-Content -Path "migration/clubs_consolidation/clubs_files.txt" | Measure-Object -Line).Lines

Write-Host "  Found $SPACES_COUNT files in spaces/ directory" -ForegroundColor White
Write-Host "  Found $CLUBS_COUNT files in clubs/ directory" -ForegroundColor White

# Find import references to clubs directory
$clubsImports = Select-String -Path "lib/*.dart", "lib/**/*.dart" -Pattern "import.*clubs" -AllMatches
$clubsImports | Out-File -FilePath "migration/clubs_consolidation/clubs_imports.txt"
$CLUBS_IMPORTS_COUNT = $clubsImports.Count
Write-Host "  Found $CLUBS_IMPORTS_COUNT references to clubs/ directory" -ForegroundColor White

Write-Host "3. Generating class/entity lists..." -ForegroundColor Cyan

# Extract class names from profile directories for comparison
$profileClasses = Select-String -Path "lib/features/profile/*.dart", "lib/features/profile/**/*.dart" -Pattern "^class\s+(\w+)" | 
    ForEach-Object { $_.Matches.Groups[1].Value } | Sort-Object
$profileClasses | Out-File -FilePath "migration/profile_consolidation/profile_classes.txt"

$profilesClasses = Select-String -Path "lib/features/profiles/*.dart", "lib/features/profiles/**/*.dart" -Pattern "^class\s+(\w+)" |
    ForEach-Object { $_.Matches.Groups[1].Value } | Sort-Object
$profilesClasses | Out-File -FilePath "migration/profile_consolidation/profiles_classes.txt"

# Extract class names from spaces and clubs directories for comparison
$spacesClasses = Select-String -Path "lib/features/spaces/*.dart", "lib/features/spaces/**/*.dart" -Pattern "^class\s+(\w+)" |
    ForEach-Object { $_.Matches.Groups[1].Value } | Sort-Object
$spacesClasses | Out-File -FilePath "migration/clubs_consolidation/spaces_classes.txt"

$clubsClasses = Select-String -Path "lib/features/clubs/*.dart", "lib/features/clubs/**/*.dart" -Pattern "^class\s+(\w+)" |
    ForEach-Object { $_.Matches.Groups[1].Value } | Sort-Object
$clubsClasses | Out-File -FilePath "migration/clubs_consolidation/clubs_classes.txt"

Write-Host "4. Generating consolidation reports..." -ForegroundColor Cyan

# Create profile consolidation summary
$profileReport = @"
# Profile Consolidation Report

## Files Count
- profile directory: $PROFILE_COUNT files
- profiles directory: $PROFILES_COUNT files

## Import References
- $PROFILES_IMPORTS_COUNT references to profiles/ directory

## Classes in profile/ directory
$(foreach ($class in $profileClasses) { "- $class" })

## Classes in profiles/ directory
$(foreach ($class in $profilesClasses) { "- $class" })
"@

$profileReport | Out-File -FilePath "migration/profile_consolidation/report.md"

# Create clubs consolidation summary
$clubsReport = @"
# Clubs/Spaces Consolidation Report

## Files Count
- spaces directory: $SPACES_COUNT files
- clubs directory: $CLUBS_COUNT files

## Import References
- $CLUBS_IMPORTS_COUNT references to clubs/ directory

## Classes in spaces/ directory
$(foreach ($class in $spacesClasses) { "- $class" })

## Classes in clubs/ directory
$(foreach ($class in $clubsClasses) { "- $class" })
"@

$clubsReport | Out-File -FilePath "migration/clubs_consolidation/report.md"

Write-Host "Consolidation analysis completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Reports generated:" -ForegroundColor White
Write-Host "- migration/profile_consolidation/report.md" -ForegroundColor White
Write-Host "- migration/clubs_consolidation/report.md" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Review the reports to identify classes/files to migrate" -ForegroundColor White
Write-Host "2. Update the consolidation plans with specific files to migrate" -ForegroundColor White
Write-Host "3. Start implementing the consolidation plan" -ForegroundColor White 