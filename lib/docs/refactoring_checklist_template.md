# Refactoring Checklist Template

Use this template to evaluate and track refactoring progress for each page or major component in the Hive UI codebase.

## Component Information

- **File Name**: `example_page.dart`
- **Path**: `lib/pages/example_page.dart`
- **Primary Purpose**: [Brief description of what this component does]
- **Current Line Count**: [Number of lines in current file]
- **Target Line Count**: [Goal for refactored file size]

## Issues Assessment

- [ ] File exceeds 300 lines
- [ ] Contains mixed responsibilities (UI + business logic)
- [ ] Has deeply nested widgets
- [ ] Contains duplicate logic found elsewhere
- [ ] Lacks proper state management
- [ ] Missing error handling
- [ ] Has unused imports or code
- [ ] Other issues: [List any other issues]

## UI Component Extraction

Identify UI components that should be extracted to their own files:

| Component | New File Location | Status |
|-----------|------------------|--------|
| Example Component | `widgets/example/example_component.dart` | ⬜ Not Started |

## Business Logic Extraction

Identify business logic that should be moved to providers:

| Logic | Provider Location | Status |
|-------|------------------|--------|
| Example Logic | `providers/example_provider.dart` | ⬜ Not Started |

## State Management Improvements

- [ ] Replace direct state with Riverpod providers
- [ ] Implement proper AsyncValue pattern for async operations
- [ ] Add error handling for async operations
- [ ] Consolidate animation controllers
- [ ] Move complex state logic to providers

## Code Organization

- [ ] Group imports by category
- [ ] Remove unused imports
- [ ] Organize methods in a logical order
- [ ] Add proper documentation
- [ ] Apply consistent naming patterns

## Styling Consistency

- [ ] Apply glassmorphism consistently
- [ ] Use theme colors instead of hard-coded values
- [ ] Standardize spacing and layout
- [ ] Apply consistent animation patterns

## Testing Strategy

- [ ] Identify key functionality to maintain
- [ ] Plan for visual regression testing
- [ ] Unit test extracted business logic
- [ ] Widget tests for complex components

## Implementation Notes

[Add any specific notes about implementation details, challenges, or considerations]

## Refactoring Progress

- ⬜ Not Started
- ⬜ In Progress - Component Extraction
- ⬜ In Progress - Business Logic Extraction
- ⬜ In Progress - State Management
- ⬜ In Progress - Code Organization
- ⬜ In Progress - Final Cleanup
- ⬜ Completed
- ⬜ Verified

## Dependencies on Other Components

[List any other components that need to be refactored first or that will be affected by this refactoring]

## Pre/Post Metrics

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Line count | | | |
| Number of components | | | |
| Number of providers | | | |
| Build time | | | |
| Other metrics | | | | 