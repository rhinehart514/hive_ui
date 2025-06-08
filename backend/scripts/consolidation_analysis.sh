#!/bin/bash

# HIVE UI - Consolidation Analysis Script
# This script analyzes the directories to be consolidated and generates reports

echo "Starting HIVE UI consolidation analysis..."

# Make sure we're in the project root
if [ ! -d "lib" ]; then
  echo "Error: Run this script from the project root directory"
  exit 1
fi

# Create migration directories
mkdir -p migration/profile_consolidation
mkdir -p migration/clubs_consolidation

echo "1. Analyzing profile and profiles directories..."

# Generate file lists for profile directories
find lib/features/profile -type f > migration/profile_consolidation/profile_files.txt
find lib/features/profiles -type f > migration/profile_consolidation/profiles_files.txt

# Count files in each directory
PROFILE_COUNT=$(wc -l < migration/profile_consolidation/profile_files.txt)
PROFILES_COUNT=$(wc -l < migration/profile_consolidation/profiles_files.txt)

echo "  Found $PROFILE_COUNT files in profile/ directory"
echo "  Found $PROFILES_COUNT files in profiles/ directory"

# Find import references to profiles directory
grep -r "import.*profiles" lib --include="*.dart" > migration/profile_consolidation/profiles_imports.txt
PROFILES_IMPORTS_COUNT=$(wc -l < migration/profile_consolidation/profiles_imports.txt)
echo "  Found $PROFILES_IMPORTS_COUNT references to profiles/ directory"

echo "2. Analyzing spaces and clubs directories..."

# Generate file lists for spaces and clubs directories
find lib/features/spaces -type f > migration/clubs_consolidation/spaces_files.txt
find lib/features/clubs -type f > migration/clubs_consolidation/clubs_files.txt

# Count files in each directory
SPACES_COUNT=$(wc -l < migration/clubs_consolidation/spaces_files.txt)
CLUBS_COUNT=$(wc -l < migration/clubs_consolidation/clubs_files.txt)

echo "  Found $SPACES_COUNT files in spaces/ directory"
echo "  Found $CLUBS_COUNT files in clubs/ directory"

# Find import references to clubs directory
grep -r "import.*clubs" lib --include="*.dart" > migration/clubs_consolidation/clubs_imports.txt
CLUBS_IMPORTS_COUNT=$(wc -l < migration/clubs_consolidation/clubs_imports.txt)
echo "  Found $CLUBS_IMPORTS_COUNT references to clubs/ directory"

echo "3. Generating class/entity lists..."

# Extract class names from profile directories for comparison
grep -r "^class\s" lib/features/profile --include="*.dart" | awk '{print $2}' | cut -d '{' -f 1 > migration/profile_consolidation/profile_classes.txt
grep -r "^class\s" lib/features/profiles --include="*.dart" | awk '{print $2}' | cut -d '{' -f 1 > migration/profile_consolidation/profiles_classes.txt

# Extract class names from spaces and clubs directories for comparison
grep -r "^class\s" lib/features/spaces --include="*.dart" | awk '{print $2}' | cut -d '{' -f 1 > migration/clubs_consolidation/spaces_classes.txt
grep -r "^class\s" lib/features/clubs --include="*.dart" | awk '{print $2}' | cut -d '{' -f 1 > migration/clubs_consolidation/clubs_classes.txt

echo "4. Generating consolidation reports..."

# Create profile consolidation summary
echo "# Profile Consolidation Report" > migration/profile_consolidation/report.md
echo "" >> migration/profile_consolidation/report.md
echo "## Files Count" >> migration/profile_consolidation/report.md
echo "- profile directory: $PROFILE_COUNT files" >> migration/profile_consolidation/report.md
echo "- profiles directory: $PROFILES_COUNT files" >> migration/profile_consolidation/report.md
echo "" >> migration/profile_consolidation/report.md
echo "## Import References" >> migration/profile_consolidation/report.md
echo "- $PROFILES_IMPORTS_COUNT references to profiles/ directory" >> migration/profile_consolidation/report.md
echo "" >> migration/profile_consolidation/report.md
echo "## Classes in profile/ directory" >> migration/profile_consolidation/report.md
cat migration/profile_consolidation/profile_classes.txt | sort | awk '{print "- " $0}' >> migration/profile_consolidation/report.md
echo "" >> migration/profile_consolidation/report.md
echo "## Classes in profiles/ directory" >> migration/profile_consolidation/report.md
cat migration/profile_consolidation/profiles_classes.txt | sort | awk '{print "- " $0}' >> migration/profile_consolidation/report.md

# Create clubs consolidation summary
echo "# Clubs/Spaces Consolidation Report" > migration/clubs_consolidation/report.md
echo "" >> migration/clubs_consolidation/report.md
echo "## Files Count" >> migration/clubs_consolidation/report.md
echo "- spaces directory: $SPACES_COUNT files" >> migration/clubs_consolidation/report.md
echo "- clubs directory: $CLUBS_COUNT files" >> migration/clubs_consolidation/report.md
echo "" >> migration/clubs_consolidation/report.md
echo "## Import References" >> migration/clubs_consolidation/report.md
echo "- $CLUBS_IMPORTS_COUNT references to clubs/ directory" >> migration/clubs_consolidation/report.md
echo "" >> migration/clubs_consolidation/report.md
echo "## Classes in spaces/ directory" >> migration/clubs_consolidation/report.md
cat migration/clubs_consolidation/spaces_classes.txt | sort | awk '{print "- " $0}' >> migration/clubs_consolidation/report.md
echo "" >> migration/clubs_consolidation/report.md
echo "## Classes in clubs/ directory" >> migration/clubs_consolidation/report.md
cat migration/clubs_consolidation/clubs_classes.txt | sort | awk '{print "- " $0}' >> migration/clubs_consolidation/report.md

echo "Consolidation analysis completed!"
echo ""
echo "Reports generated:"
echo "- migration/profile_consolidation/report.md"
echo "- migration/clubs_consolidation/report.md"
echo ""
echo "Next steps:"
echo "1. Review the reports to identify classes/files to migrate"
echo "2. Update the consolidation plans with specific files to migrate"
echo "3. Start implementing the consolidation plan" 