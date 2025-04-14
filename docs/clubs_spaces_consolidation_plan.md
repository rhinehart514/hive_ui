# Clubs/Spaces Consolidation Plan

This document details the specific steps to consolidate the duplicate `clubs/` and `spaces/` directories in the HIVE UI codebase.

## Overview

The codebase currently contains two directories with similar community/group functionality:
- `lib/features/spaces/` - The main implementation with more complete clean architecture structure
- `lib/features/clubs/` - A secondary implementation with partial functionality

The goal is to consolidate all unique functionality into the `lib/features/spaces/` directory, update import references throughout the codebase, and eventually remove the `clubs/` directory.

## Analysis and Inventory

### Spaces Directory (Target)
- **Structure**: More complete implementation with data, domain, presentation, and application layers
- **Key Files**: 
  - `spaces.dart` (exports for the module)
  - README.md with architecture documentation
  - Full clean architecture structure

### Clubs Directory (To Consolidate)
- **Structure**: Partial implementation with domain and presentation layers
- **Key Files**: To be analyzed and identified

## Migration Steps

### Step 1: File Inventory and Comparison

Run the file comparison to identify unique files in `clubs/` directory:

```bash
# Create a directory for the migration plan
mkdir -p migration/clubs_consolidation

# Generate file lists for both directories
find lib/features/spaces -type f > migration/clubs_consolidation/spaces_files.txt
find lib/features/clubs -type f > migration/clubs_consolidation/clubs_files.txt

# Compare the contents of key files to identify unique functionality
```

### Step 2: Migration of Unique Functionality

For each unique file or functionality in `clubs/`:

1. Identify target location in `spaces/` directory
2. Copy or merge the functionality
3. Update imports within the migrated files
4. Document the migration in a log file

### Step 3: Import Reference Updates

1. Identify all files that import from `clubs/` directory:

```bash
grep -r "import.*clubs" lib --include="*.dart" > migration/clubs_consolidation/clubs_imports.txt
```

2. For each reference:
   - Update the import path to reference `spaces/` directory
   - Verify that the referenced class/function exists in the new location
   - Test the updated file to ensure it still works correctly

### Step 4: Deprecation and Testing

1. Add deprecation comments to all files in `clubs/` directory:

```dart
// DEPRECATED: This file is deprecated and will be removed.
// The functionality has been migrated to lib/features/spaces/...
// Please update your imports to use the new location.
```

2. Run the application and verify:
   - All club/space-related functionality works correctly
   - No runtime errors related to club/space functionality
   - All UI elements render correctly

3. Run tests to ensure no regressions:
   - Unit tests
   - Widget tests
   - Integration tests

### Step 5: Final Removal

After sufficient testing and verification:

1. Remove the `clubs/` directory
2. Update documentation to reflect the consolidation
3. Update the app_completion_plan.md to mark this task as completed

## Special Considerations

### UI Component Consistency

The consolidation should ensure that UI components from both implementations maintain a consistent look and feel. The documentation in `lib/docs/club_space_design_system.md` indicates there are shared components like:

- `ClubHeaderCard` - Card-style drop-down header
- `ClubSpaceTileFactory` - Factory for creating consistent tiles

These components should be carefully migrated to maintain visual consistency.

### Terminology Standardization

As part of the consolidation, we should standardize terminology:
- Decide whether to use "Space" or "Club" consistently in the code and UI
- Update class names, method names, and comments to reflect the chosen terminology
- Document the terminology standards for future development

## Identified Files to Migrate

The following files from `clubs/` have been identified for migration:

*[This section will be populated after the inventory and comparison step]*

## Import References to Update

The following files contain imports that need to be updated:

*[This section will be populated after the grep search step]*

## Testing Checklist

- [ ] Spaces/Clubs list loads correctly
- [ ] Space/Club details display correctly
- [ ] Joining/leaving a space/club works
- [ ] All space/club-related UI components render correctly
- [ ] No console errors related to space/club functionality
- [ ] All unit tests pass
- [ ] All widget tests pass
- [ ] All integration tests pass 