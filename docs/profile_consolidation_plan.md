# Profile/Profiles Consolidation Plan

This document details the specific steps to consolidate the duplicate `profile/` and `profiles/` directories in the HIVE UI codebase.

## Overview

The codebase currently contains two directories with profile-related functionality:
- `lib/features/profile/` - The main implementation with complete clean architecture structure
- `lib/features/profiles/` - A secondary implementation with partial functionality

The goal is to consolidate all unique functionality into the `lib/features/profile/` directory, update import references throughout the codebase, and eventually remove the `profiles/` directory.

## Analysis and Inventory

### Profile Directory (Target)
- **Structure**: Complete clean architecture with data, domain, and presentation layers
- **Key Files**: 
  - `profile_page.dart` (18KB, 496 lines)
  - `profile_tab_view.dart` (17KB, 477 lines)
  - `verified_plus_request_page.dart` (27KB, 841 lines)
  - Several provider implementations in `presentation/providers/`

### Profiles Directory (To Consolidate)
- **Structure**: Partial implementation with domain and presentation layers
- **Key Files**: To be analyzed and identified

## Migration Steps

### Step 1: File Inventory and Comparison

Run the file comparison to identify unique files in `profiles/` directory:

```bash
# Create a directory for the migration plan
mkdir -p migration/profile_consolidation

# Generate file lists for both directories
find lib/features/profile -type f > migration/profile_consolidation/profile_files.txt
find lib/features/profiles -type f > migration/profile_consolidation/profiles_files.txt

# Compare the contents of key files to identify unique functionality
```

### Step 2: Migration of Unique Functionality

For each unique file or functionality in `profiles/`:

1. Identify target location in `profile/` directory
2. Copy or merge the functionality
3. Update imports within the migrated files
4. Document the migration in a log file

### Step 3: Import Reference Updates

1. Identify all files that import from `profiles/` directory:

```bash
grep -r "import.*profiles" lib --include="*.dart" > migration/profile_consolidation/profiles_imports.txt
```

2. For each reference:
   - Update the import path to reference `profile/` directory
   - Verify that the referenced class/function exists in the new location
   - Test the updated file to ensure it still works correctly

### Step 4: Deprecation and Testing

1. Add deprecation comments to all files in `profiles/` directory:

```dart
// DEPRECATED: This file is deprecated and will be removed.
// The functionality has been migrated to lib/features/profile/...
// Please update your imports to use the new location.
```

2. Run the application and verify:
   - All profile-related functionality works correctly
   - No runtime errors related to profile functionality
   - All UI elements render correctly

3. Run tests to ensure no regressions:
   - Unit tests
   - Widget tests
   - Integration tests

### Step 5: Final Removal

After sufficient testing and verification:

1. Remove the `profiles/` directory
2. Update documentation to reflect the consolidation
3. Update the app_completion_plan.md to mark this task as completed

## Identified Files to Migrate

The following files from `profiles/` have been identified for migration:

*[This section will be populated after the inventory and comparison step]*

## Import References to Update

The following files contain imports that need to be updated:

*[This section will be populated after the grep search step]*

## Testing Checklist

- [ ] Profile page loads correctly
- [ ] Profile editing works
- [ ] Profile data is saved and retrieved correctly
- [ ] All profile-related UI components render correctly
- [ ] No console errors related to profile functionality
- [ ] All unit tests pass
- [ ] All widget tests pass
- [ ] All integration tests pass 