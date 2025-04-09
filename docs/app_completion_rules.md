# HIVE UI App Completion Rules

## Overview

This document outlines the mandatory rules and processes for implementing new features in the HIVE UI application. These rules ensure consistency, proper architecture adherence, and high-quality code that integrates seamlessly with existing systems.

## 1. Requirement Verification and Clarification

### 1.1 Always Ask for Context
- **MANDATORY**: Before implementing any feature, ALWAYS ask the user for specific business requirements and user experience expectations
- Verify feature scope, target users, and success criteria
- Confirm priority and relationship to other features
- Clarify any ambiguities in the requirements before proceeding
- Do not assume functionality or behavior without explicit confirmation

### 1.2 User Story Verification
- Request or develop a user story for each feature
- Confirm user flow and feature boundaries
- Identify edge cases and verify handling approach
- Document expected outcomes for different scenarios
- Validate user story against existing features to avoid conflicts

### 1.3 Acceptance Criteria Confirmation
- Document clear, testable acceptance criteria
- Get explicit approval on acceptance criteria before implementation
- Clarify any technical constraints or performance requirements
- Verify feature scope against the app completion plan priorities
- Document any future extensions or enhancements out of current scope

## 2. Database Verification and Integration

### 2.1 Mandatory Database Review
- **MANDATORY**: ALWAYS review the database schema before implementing any feature
- Verify Firestore collection structure and field definitions
- Check existing indexes and security rules for compatibility
- Identify any schema updates needed to support the feature
- Confirm data access patterns against existing repository implementations

### 2.2 Data Layer Integration
- Verify feature requirements against existing data models and DTOs
- Confirm repository methods needed for the feature
- Review Firebase query patterns for efficient data access
- Ensure offline support and cache invalidation strategies are considered
- Validate data validation and transformation requirements

### 2.3 Data Consistency and Synchronization
- Confirm AppEventBus integration for state synchronization
- Verify cache management strategy for new data
- Document transactions and data consistency requirements
- Ensure proper error handling for data operations
- Validate optimistic UI updates for better user experience

## 3. Architecture Compliance

### 3.1 Layer Separation
- Maintain strict separation between data, domain, and presentation layers
- Verify interfaces and implementations are in the correct directories
- Use mappers to transform between layer-specific models
- Ensure unidirectional dependencies (presentation → domain → data)
- Verify correct provider registration for dependency injection

### 3.2 Feature Structure
- Organize code into proper feature modules
- Follow established naming conventions and file structure
- Ensure proper test coverage at each layer
- Document feature dependencies and integration points
- Validate architectural decisions against the coding standards document

### 3.3 Clean Architecture Verification
- Validate use case implementations for business logic
- Ensure entities contain domain rules and validation
- Verify repository interfaces define clear contracts
- Confirm presentation layer doesn't contain business logic
- Document any architectural exceptions with justification

## 4. Implementation Process

### 4.1 Planning Phase
- Create implementation plan covering all three layers
- Document required new files and modifications to existing files
- Identify potential refactoring needs
- Verify test strategy and coverage targets
- Confirm implementation against performance requirements

### 4.2 Implementation Sequence
1. Implement data layer components first (models, repositories)
2. Implement domain layer entities and use cases
3. Implement presentation layer components and providers
4. Implement tests for each layer
5. Verify integration and end-to-end functionality

### 4.3 Testing Requirements
- Implement unit tests for business logic and repositories
- Create widget tests for UI components
- Verify integration tests for critical flows
- Document test coverage and gaps
- Validate error handling and edge cases

## 5. Handling Ambiguity

### 5.1 Ambiguity Resolution Protocol
- **MANDATORY**: When encountering ambiguity, ALWAYS ask for clarification rather than making assumptions
- Document ambiguous requirements and proposed interpretations
- Present multiple options with pros and cons when applicable
- Get explicit approval on the chosen approach before implementation
- Document final decisions for future reference

### 5.2 Technical Decisions
- For technical implementation details, present trade-offs
- Document performance implications of different approaches
- Consider maintainability and future extensibility
- Verify alignment with existing patterns in the codebase
- Confirm approach is compatible with Flutter and Firebase best practices

## 6. Documentation and Handoff

### 6.1 Implementation Documentation
- Document feature architecture and components
- Create inline documentation for public APIs and complex logic
- Update relevant architecture documentation
- Document known limitations or future enhancements
- Verify documentation follows established standards

### 6.2 Feature Completion Checklist
- Verify all acceptance criteria are met
- Confirm test coverage meets requirements
- Validate performance against targets
- Verify compatibility with existing features
- Document any technical debt or future refactoring needs

## Conclusion

Following these rules ensures that new features are implemented correctly, integrate seamlessly with the existing codebase, and maintain the architectural integrity of the HIVE UI application. The emphasis on clarification, database verification, and handling ambiguity reduces rework and ensures high-quality implementations.

**ALWAYS remember**: Ask for context, verify with the database, and resolve ambiguities before implementation. 