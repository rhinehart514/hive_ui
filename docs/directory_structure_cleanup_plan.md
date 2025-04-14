# HIVE UI - Directory Structure Cleanup Plan

## Overview
This document outlines the plan to clean up and consolidate the directory structure of the HIVE UI codebase, addressing technical debt identified in the app_completion_plan.md.

## Current Issues

1. **Duplicate Profile Implementations**:
   - Two directories: `profile/` and `profiles/` with overlapping functionality
   - `profile/` appears to be the more complete implementation

2. **Duplicate Space/Club Implementations**:
   - Two directories: `spaces/` and `clubs/` with similar functionality
   - `spaces/` appears to be the more complete/modern implementation

3. **Template Directory**:
   - `template_feature/` directory exists but appears unused

4. **Debug Directory**:
   - Contains development utilities that may no longer be needed

## Consolidation Plan

### 1. Profile/Profiles Consolidation

#### Step 1: Inventory and Analysis
- Review unique files/functionality in `profiles/` not present in `profile/`
- Create mapping of files to migrate

#### Step 2: Migration
- Move any unique functionality from `profiles/` to `profile/`
- Update imports in migrated files

#### Step 3: Reference Updates
- Locate all imports referencing `profiles/` in the codebase
- Update import statements to reference `profile/` implementation

#### Step 4: Deprecation
- Add deprecation notice to `profiles/` files indicating they are deprecated
- Plan for removal after ensuring no runtime issues

### 2. Clubs/Spaces Consolidation

#### Step 1: Inventory and Analysis
- Review unique files/functionality in `clubs/` not present in `spaces/`
- Create mapping of files to migrate

#### Step 2: Migration
- Move any unique functionality from `clubs/` to `spaces/`
- Ensure `spaces/` maintains clean architecture structure
- Update imports in migrated files

#### Step 3: Reference Updates
- Locate all imports referencing `clubs/` in the codebase
- Update import statements to reference `spaces/` implementation

#### Step 4: Deprecation
- Add deprecation notice to `clubs/` files indicating they are deprecated
- Plan for removal after ensuring no runtime issues

### 3. Template Feature Removal

#### Step 1: Validation
- Confirm `template_feature/` is indeed an unused template
- Check for any imports referencing it

#### Step 2: Backup and Removal
- Create backup reference (if needed) in `docs/templates/`
- Remove `template_feature/` directory

### 4. Debug Directory Cleanup

#### Step 1: Analysis
- Review contents of `debug/` directory
- Determine if any functionality is still needed

#### Step 2: Migration/Documentation
- If functionality is needed, move to appropriate place
- If functionality should be preserved for reference, document in appropriate location

#### Step 3: Cleanup
- Remove unnecessary files

## Implementation Sequence

1. Start with **Template Feature Removal** as it's likely the simplest
2. Proceed with **Debug Directory Cleanup**
3. Implement **Profile/Profiles Consolidation**
4. Complete **Clubs/Spaces Consolidation**

## Testing Strategy

After each consolidation:
1. Run the application locally to verify no runtime errors
2. Verify affected features work correctly
3. Run any existing tests

## Rollback Plan

Before implementing changes:
1. Create a branch for each consolidation task
2. Document implementation process
3. If issues occur, revert to original branch

## Success Criteria

1. All duplicate directories consolidated
2. No unnecessary directories remain
3. All features continue to function correctly
4. Directory structure is consistent with clean architecture guidelines
5. Import references are updated throughout the codebase 