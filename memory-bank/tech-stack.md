# HIVE Technical Stack

This document outlines the core technologies and architectural patterns used in the HIVE platform.

## Core Stack

*   **Frontend Framework:** Flutter 3.x
    *   **Navigation:** `go_router` (declarative routing)
    *   **Networking:** `dio` package (feature-rich client with interceptors)
*   **Backend Platform (BaaS):** Google Firebase
    *   Authentication: Firebase Auth
    *   Database: Firestore
    *   File Storage: Firebase Storage
    *   Serverless Functions: Cloud Functions (TypeScript)
    *   Analytics: Firebase Analytics

## Architecture & Patterns

*   **Application Architecture:** Clean Architecture (Presentation → Domain → Data)
*   **State Management:** Riverpod
*   **Security:** Firebase Auth Custom Claims (for user tiers), Firestore Security Rules

## Development & Operations (DevOps)

*   **Version Control:** Git / GitHub
*   **CI/CD:** GitHub Actions deploying to Firebase App Distribution
*   **Code Quality:** `flutter_lints` package, Code Formatting (`dart format`)
*   **Testing:** `flutter_test` (Unit/Widget), `integration_test` 