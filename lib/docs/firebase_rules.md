# Firebase Rules and Best Practices for HIVE UI

This document establishes standardized rules and best practices for working with Firebase in the HIVE UI application. It's designed to complement the existing `.cursorrules` with more specific Firebase guidance.

## 1. Firebase Architecture

### 1.1 Service Layer Structure
- Implement Firebase functionality through a service layer that follows interface segregation
- Use the repository pattern to abstract Firebase implementation details
- Each Firebase service should have a corresponding interface and implementation:
  ```dart
  abstract class AuthRepository {
    Future<User?> signIn(String email, String password);
    Future<void> signOut();
    Stream<User?> get authStateChanges;
    // ...
  }
  
  class FirebaseAuthRepository implements AuthRepository {
    final FirebaseAuth _firebaseAuth;
    // Implementation...
  }
  ```

### 1.2 Dependency Injection
- Register Firebase services as singletons in GetIt
- Initialize Firebase in a controlled fashion in main.dart
- Provide mock implementations for testing environments
- Example service registration:
  ```dart
  void setupFirebaseServices() {
    // Register auth repository
    getIt.registerLazySingleton<AuthRepository>(
      () => FirebaseAuthRepository(FirebaseAuth.instance)
    );
    
    // Register firestore repository
    getIt.registerLazySingleton<DatabaseRepository>(
      () => FirestoreRepository(FirebaseFirestore.instance)
    );
  }
  ```

## 2. Firestore Data Management

### 2.1 Data Structure
- Use typed models for all Firestore data
- Implement toJson() and fromJson() methods for all models
- Use consistent collection naming (lowercase, snake_case)
- Structure collections hierarchically when appropriate
- Example model:
  ```dart
  class ClubModel {
    final String id;
    final String name;
    final String description;
    final List<String> tags;
    final DateTime createdAt;
    
    // Constructor and serialization methods
    Map<String, dynamic> toJson() => {
      'id': id,
      'name': name,
      'description': description,
      'tags': tags,
      'created_at': Timestamp.fromDate(createdAt),
    };
    
    factory ClubModel.fromJson(Map<String, dynamic> json) => ClubModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: (json['created_at'] as Timestamp).toDate(),
    );
  }
  ```

### 2.2 Query Best Practices
- Create indexes for all complex queries
- Limit query results to prevent excessive data transfer
- Use compound queries instead of client-side filtering
- Cache frequently accessed data
- Implement pagination for large collections
- Example efficient query:
  ```dart
  Future<List<ClubModel>> getClubsByTags(List<String> tags, {int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection('clubs')
          .where('tags', arrayContainsAny: tags)
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();
          
      return querySnapshot.docs
          .map((doc) => ClubModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      logError('Failed to fetch clubs by tags', e);
      rethrow;
    }
  }
  ```

### 2.3 Data Validation
- Validate data before writing to Firestore
- Use server-side Firestore security rules for enforcing data integrity
- Implement client-side validation for fast feedback
- Handle schema migrations gracefully

## 3. Firebase Authentication

### 3.1 Authentication Flow
- Implement a centralized AuthController for managing authentication state
- Use Riverpod to provide authentication state throughout the app
- Handle all authentication errors with user-friendly messages
- Support multiple auth methods consistently (email/password, social)
- Example auth controller:
  ```dart
  final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
    return AuthController(ref.read(authRepositoryProvider));
  });
  
  class AuthController extends StateNotifier<AuthState> {
    final AuthRepository _authRepository;
    
    AuthController(this._authRepository) : super(const AuthState.initial()) {
      _authRepository.authStateChanges.listen(_handleAuthStateChange);
    }
    
    void _handleAuthStateChange(User? user) {
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = const AuthState.unauthenticated();
      }
    }
    
    Future<void> signIn(String email, String password) async {
      state = const AuthState.loading();
      try {
        await _authRepository.signIn(email, password);
        // State will be updated by the auth state listener
      } catch (e) {
        state = AuthState.error(_mapAuthError(e));
      }
    }
    
    // Additional methods...
  }
  ```

### 3.2 User Management
- Store minimal user data in Firebase Authentication
- Keep detailed user profiles in Firestore
- Handle user deletion and data cleanup properly
- Implement proper role-based access control

## 4. Firebase Storage

### 4.1 File Organization
- Organize files in logical folders by resource type
- Use user IDs in storage paths for access control
- Example storage structure:
  ```
  /users/{userId}/profile_picture.jpg
  /clubs/{clubId}/banner.jpg
  /clubs/{clubId}/gallery/{imageId}.jpg
  ```

### 4.2 Upload Management
- Show upload progress using StreamBuilder
- Compress images before upload when appropriate
- Validate file types and sizes before uploading
- Implement proper error handling for failed uploads
- Example upload implementation:
  ```dart
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      // Generate a compressed image if needed
      final compressedFile = await _compressImage(imageFile);
      
      // Create a reference to the file path
      final storageRef = _storage.ref().child('users/$userId/profile_picture.jpg');
      
      // Start upload task
      final uploadTask = storageRef.putFile(compressedFile);
      
      // Get download URL when complete
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      logError('Failed to upload profile image', e);
      rethrow;
    }
  }
  ```

## 5. Firebase Security

### 5.1 Security Rules
- Implement strict Firestore security rules for all collections
- Test security rules thoroughly before deployment
- Update security rules whenever data model changes
- Example Firestore security rules:
  ```
  service cloud.firestore {
    match /databases/{database}/documents {
      // User profiles - users can only read/write their own data
      match /users/{userId} {
        allow read: if request.auth != null && request.auth.uid == userId;
        allow write: if request.auth != null && request.auth.uid == userId;
      }
      
      // Clubs - members can read, owners can update
      match /clubs/{clubId} {
        allow read: if true;
        allow create: if request.auth != null;
        allow update: if request.auth != null && 
          exists(/databases/$(database)/documents/clubs/$(clubId)) && 
          get(/databases/$(database)/documents/clubs/$(clubId)).data.ownerId == request.auth.uid;
        allow delete: if false; // Only admins can delete via functions
      }
      
      // Club members
      match /clubs/{clubId}/members/{memberId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null && 
          (request.auth.uid == memberId || 
          get(/databases/$(database)/documents/clubs/$(clubId)).data.ownerId == request.auth.uid);
      }
    }
  }
  ```

### 5.2 Data Access Control
- Implement row-level security with user IDs in documents
- Use Firebase Admin SDK for privileged operations in Cloud Functions
- Never store sensitive information in client-accessible locations
- Validate all user input before writing to Firebase

## 6. Cross-Platform Considerations

### 6.1 Platform-Specific Issues
- Handle Windows-specific Firebase auth issues
- Initialize Firebase differently for each platform when needed
- Test Firebase functionality across all supported platforms
- Example platform-specific initialization:
  ```dart
  Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Windows-specific fixes
      if (Platform.isWindows) {
        // Apply Windows fixes for Firebase Auth
        await WindowsFirebaseFix.apply();
      }
      
      // Additional platform-specific setup
      if (kIsWeb) {
        // Web-specific configuration
      }
    } catch (e) {
      logError('Failed to initialize Firebase', e);
      // Handle gracefully for terminal testing
    }
  }
  ```

### 6.2 Terminal Testing
- Gracefully handle Firebase initialization failures in tests
- Implement mock Firebase services for testing
- Use dependency injection to swap real services with mocks

## 7. Error Handling

### 7.1 Firebase Exceptions
- Create typed exceptions for different Firebase error scenarios
- Map Firebase error codes to user-friendly messages
- Log detailed error information for debugging
- Example error mapping:
  ```dart
  String _mapAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'email-already-in-use':
          return 'This email is already registered.';
        default:
          return 'Authentication failed: ${error.message}';
      }
    }
    
    return 'An unexpected error occurred. Please try again.';
  }
  ```

### 7.2 Recovery Strategies
- Implement retry logic for transient errors
- Cache data locally to handle offline scenarios
- Use Firebase persistence for offline capabilities
- Provide clear user feedback during error situations

## 8. Performance Optimization

### 8.1 Query Optimization
- Use Firestore query cursor pagination instead of offset pagination
- Cache frequently accessed data locally
- Use transactions for atomic operations
- Batch writes for multiple document updates
- Example optimized pagination:
  ```dart
  Future<List<EventModel>> getEventsForClub(String clubId, {
    DocumentSnapshot? lastDocument,
    int pageSize = 10,
  }) async {
    try {
      var query = _firestore
          .collection('events')
          .where('clubId', isEqualTo: clubId)
          .orderBy('startTime', descending: true)
          .limit(pageSize);
          
      // Apply pagination using startAfterDocument
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      final querySnapshot = await query.get();
      
      // Store last document for next pagination call
      _lastEventDocument = querySnapshot.docs.isNotEmpty 
          ? querySnapshot.docs.last 
          : null;
          
      return querySnapshot.docs
          .map((doc) => EventModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      logError('Failed to fetch events for club', e);
      rethrow;
    }
  }
  ```

### 8.2 Offline Support
- Enable Firestore offline persistence
- Implement proper conflict resolution for offline changes
- Provide clear UI indicators for offline status
- Test offline scenarios thoroughly

## 9. Analytics and Monitoring

### 9.1 Analytics Implementation
- Track meaningful user events with Firebase Analytics
- Use consistent naming conventions for events and parameters
- Avoid tracking personally identifiable information
- Example analytics tracking:
  ```dart
  void trackClubJoined(String clubId, String clubName) {
    FirebaseAnalytics.instance.logEvent(
      name: 'club_joined',
      parameters: {
        'club_id': clubId,
        'club_name': clubName,
      },
    );
  }
  ```

### 9.2 Crash Reporting
- Integrate Firebase Crashlytics for crash reporting
- Add custom keys for debugging context
- Log non-fatal errors for tracking issues
- Review crash reports regularly

## 10. Testing Firebase Integration

### 10.1 Unit Testing
- Use mock implementations for Firebase services in tests
- Test error handling and edge cases
- Validate data transformations and mapping functions
- Example unit test:
  ```dart
  void main() {
    group('FirebaseAuthRepository', () {
      late MockFirebaseAuth mockFirebaseAuth;
      late FirebaseAuthRepository authRepository;
      
      setUp(() {
        mockFirebaseAuth = MockFirebaseAuth();
        authRepository = FirebaseAuthRepository(mockFirebaseAuth);
      });
      
      test('signIn should correctly authenticate user', () async {
        // Arrange
        final testUser = MockUser(
          uid: 'test-uid',
          email: 'test@example.com',
        );
        when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        )).thenAnswer((_) async => MockUserCredential(user: testUser));
        
        // Act
        final result = await authRepository.signIn(
          'test@example.com',
          'password123',
        );
        
        // Assert
        expect(result!.id, equals('test-uid'));
        expect(result.email, equals('test@example.com'));
      });
    });
  }
  ```

### 10.2 Integration Testing
- Test Firebase integration end-to-end with actual Firebase services
- Use Firebase Emulator Suite for integration testing
- Validate security rules with rule testing
- Ensure proper cleanup after tests

## 11. Deployment and Versioning

### 11.1 Firebase Deployment
- Use Firebase CLI for deployment to Firestore, Storage, and Functions
- Version control your Firebase configuration
- Test changes in a development environment before production deployment
- Document migration steps for data model changes

### 11.2 Security Review
- Conduct security reviews before major releases
- Audit Firestore security rules
- Review authentication flows
- Check for exposed sensitive data

## 12. Documentation

### 12.1 Firebase Configuration
- Document the Firebase project structure
- Provide setup instructions for new developers
- Include troubleshooting guides for common issues
- Keep documentation updated with Firebase SDK version changes

### 12.2 Architectural Decisions
- Document Firebase integration architecture decisions
- Explain data model design choices
- Record security rule decisions and reasoning
- Maintain a changelog of Firebase-related changes 