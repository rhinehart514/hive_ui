# HIVE vBETA Technical Architecture

_Last Updated: January 2025_  
_Status: Implementation Ready_

## 1. System Architecture Overview

### Four-System Technical Design

HIVE vBETA is architected around four distinct but interconnected systems, each with specific technical requirements and data models.

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   PROFILE   │    │   SPACES    │    │  HIVELAB    │    │    FEED     │
│             │    │             │    │             │    │             │
│ Personal    │◄──►│ Group       │◄──►│ Builder     │◄──►│ Discovery   │
│ Dashboard   │    │ Containers  │    │ Engine      │    │ Layer       │
│             │    │             │    │             │    │             │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │                   │
       └───────────────────┼───────────────────┼───────────────────┘
                           │                   │
                    ┌─────────────┐    ┌─────────────┐
                    │  FIREBASE   │    │   FLUTTER   │
                    │  BACKEND    │    │  FRONTEND   │
                    └─────────────┘    └─────────────┘
```

### Core Technical Stack

**Frontend:** Flutter 3.x (iOS, Android, Web)
**State Management:** Riverpod with system-specific providers
**Backend:** Firebase (Firestore, Cloud Functions, Authentication, Storage)
**Navigation:** go_router with system-based routing
**Data Layer:** Clean Architecture with feature-based repositories
**Caching:** Client-side using Hive for offline support
**Analytics:** Firebase Analytics + Custom event tracking

## 2. Data Architecture & Firestore Schema

### Core Collections

```firestore
/users/{userId}
├── profile: UserProfile
├── settings: UserSettings
├── motionLog: MotionEntry[]
├── joinedSpaces: string[]
├── builderStatus: BuilderProfile?
└── calendarData: CalendarEntry[]

/spaces/{spaceId}
├── metadata: SpaceMetadata
├── members: string[]
├── tools: PlacedTool[]
├── events: string[]
├── posts: string[]
└── activation: ActivationStatus

/tools/{toolId}
├── metadata: ToolMetadata
├── creator: string
├── placements: ToolPlacement[]
├── usage: ToolUsageStats
└── elements: ToolElement[]

/events/{eventId}
├── metadata: EventMetadata
├── attendees: string[]
├── rsvps: RSVP[]
├── parentSpace: string?
└── source: EventSource

/builders/{userId}
├── profile: BuilderProfile
├── createdTools: string[]
├── placedTools: ToolPlacement[]
├── reputation: BuilderReputation
└── activity: BuilderActivity[]
```

### Data Models

```dart
// Core User Profile
class UserProfile {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? username;
  final String? avatar;
  final String? bio;
  final UserYear year;
  final String major;
  final String residence;
  final List<String> interests;
  final AccountTier tier;
  final DateTime createdAt;
  final DateTime lastActive;
}

// Space Container
class Space {
  final String id;
  final String name;
  final String description;
  final SpaceType type;
  final SpaceVisibility visibility;
  final List<String> members;
  final List<PlacedTool> tools;
  final ActivationStatus activation;
  final String? pinnedMessage;
  final DateTime createdAt;
  final String? createdBy;
}

// Tool System
class Tool {
  final String id;
  final String name;
  final String description;
  final ToolType type;
  final String creatorId;
  final List<ToolElement> elements;
  final ToolConfiguration config;
  final ToolUsageStats usage;
  final DateTime createdAt;
  final bool isTemplate;
}

// Builder Profile
class BuilderProfile {
  final String userId;
  final BuilderTier tier;
  final List<String> createdTools;
  final List<ToolPlacement> placements;
  final BuilderReputation reputation;
  final DateTime becameBuilder;
  final bool isActive;
}
```

## 3. System-Specific Technical Implementation

### SYSTEM 1: PROFILE Technical Specs

**Core Components:**
- **Calendar Tool:** Integration with personal schedules and campus events
- **Stack Tools:** Personal productivity tool collection
- **Motion Log:** Chronological activity tracking
- **Now Panel:** Real-time campus context and personal status

**Technical Requirements:**
```dart
// Profile State Management
class ProfileProvider extends StateNotifier<ProfileState> {
  // Calendar Tool integration
  Future<void> syncCalendarData() async;
  
  // Stack Tools management
  Future<void> addStackTool(StackTool tool) async;
  Future<void> removeStackTool(String toolId) async;
  
  // Motion Log tracking
  Future<void> logMotion(MotionEntry entry) async;
  
  // Now Panel updates
  Stream<NowPanelData> getNowPanelStream();
}

// Calendar Tool Implementation
class CalendarTool {
  final CalendarRepository repository;
  
  Future<List<CalendarEvent>> getWeekView(DateTime week) async;
  Future<void> addPersonalEvent(PersonalEvent event) async;
  Future<void> rsvpToEvent(String eventId, RSVPStatus status) async;
  Stream<List<CalendarEvent>> getCalendarStream();
}
```

**Performance Requirements:**
- Calendar Tool: <100ms load time for week view
- Stack Tools: Offline-first operation with sync
- Motion Log: Real-time updates with 1-second latency
- Now Panel: Live data with 30-second refresh

### SYSTEM 2: SPACES Technical Specs

**Core Components:**
- **Space Container:** Group data management and member tracking
- **Tool Placement:** Builder-driven Space activation
- **Event Integration:** RSS feeds and Tool-generated events
- **Member Management:** Auto-assignment and manual joining

**Technical Requirements:**
```dart
// Spaces State Management
class SpacesProvider extends StateNotifier<SpacesState> {
  // Space discovery and joining
  Future<List<Space>> getDiscoverableSpaces() async;
  Future<void> joinSpace(String spaceId) async;
  Future<void> leaveSpace(String spaceId) async;
  
  // Tool placement and activation
  Future<void> placeTool(String spaceId, Tool tool) async;
  Future<void> activateSpace(String spaceId) async;
  
  // Event management
  Stream<List<Event>> getSpaceEvents(String spaceId);
  Future<void> createEvent(String spaceId, Event event) async;
}

// Space Activation Logic
class SpaceActivationService {
  Future<bool> canActivateSpace(String spaceId, String userId) async;
  Future<void> activateWithTool(String spaceId, Tool tool) async;
  Future<ActivationStatus> getActivationStatus(String spaceId) async;
}
```

**Auto-Assignment Logic:**
```dart
class AutoAssignmentService {
  Future<void> assignUserToSpaces(UserProfile user) async {
    // Residential assignment
    final dormSpace = await findDormSpace(user.residence);
    await assignToSpace(user.id, dormSpace.id);
    
    // Academic assignment
    final majorSpace = await findMajorSpace(user.major);
    await assignToSpace(user.id, majorSpace.id);
    
    // Interest-based suggestions
    final interestSpaces = await findInterestSpaces(user.interests);
    await suggestSpaces(user.id, interestSpaces);
  }
}
```

### SYSTEM 3: HIVELAB Technical Specs

**Core Components:**
- **Tool Composer:** Visual tool building interface
- **Element System:** Modular tool components
- **Builder Console:** Management dashboard for Builders
- **Attribution System:** Tool creator recognition and tracking

**Technical Requirements:**
```dart
// HiveLAB State Management
class HiveLabProvider extends StateNotifier<HiveLabState> {
  // Tool creation and management
  Future<Tool> createTool(ToolBlueprint blueprint) async;
  Future<Tool> forkTool(String toolId) async;
  Future<void> updateTool(String toolId, ToolUpdate update) async;
  
  // Builder management
  Future<void> requestBuilderAccess(String userId) async;
  Future<void> grantBuilderAccess(String userId) async;
  
  // Platform experiments
  Future<List<Experiment>> getActiveExperiments() async;
  Future<void> joinExperiment(String experimentId) async;
}

// Tool Composition Engine
class ToolComposer {
  final List<ToolElement> availableElements;
  
  Future<Tool> composeFromElements(List<ToolElement> elements) async;
  Future<bool> validateToolComposition(ToolBlueprint blueprint) async;
  Future<Tool> previewTool(ToolBlueprint blueprint) async;
}

// Builder Attribution System
class AttributionService {
  Future<void> attributeToolUsage(String toolId, String userId) async;
  Future<BuilderReputation> calculateReputation(String builderId) async;
  Future<void> updateToolSurge(String toolId, int usageCount) async;
}
```

**Element System Architecture:**
```dart
abstract class ToolElement {
  String get id;
  String get name;
  ElementType get type;
  Map<String, dynamic> get config;
  
  Widget render(BuildContext context);
  Future<void> execute(Map<String, dynamic> params);
}

class PollElement extends ToolElement {
  final List<String> options;
  final bool allowMultiple;
  final DateTime? expiresAt;
  
  @override
  Widget render(BuildContext context) => PollWidget(this);
  
  @override
  Future<void> execute(Map<String, dynamic> params) async {
    // Poll execution logic
  }
}
```

### SYSTEM 4: FEED Technical Specs (Deferred)

**Status:** Architecture defined, implementation deferred
**Planned Components:**
- Content aggregation from Systems 1-3
- Real-time activity streaming
- Personalization and filtering
- Progressive revelation system

## 4. State Management Architecture

### Riverpod Provider Structure

```dart
// System-level providers
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(ref.read(profileRepositoryProvider));
});

final spacesProvider = StateNotifierProvider<SpacesNotifier, SpacesState>((ref) {
  return SpacesNotifier(ref.read(spacesRepositoryProvider));
});

final hiveLabProvider = StateNotifierProvider<HiveLabNotifier, HiveLabState>((ref) {
  return HiveLabNotifier(ref.read(hiveLabRepositoryProvider));
});

// Feature-specific providers
final calendarToolProvider = Provider<CalendarTool>((ref) {
  return CalendarTool(ref.read(calendarRepositoryProvider));
});

final toolComposerProvider = Provider<ToolComposer>((ref) {
  return ToolComposer(ref.read(elementsRepositoryProvider));
});

// Real-time stream providers
final nowPanelStreamProvider = StreamProvider<NowPanelData>((ref) {
  return ref.read(profileProvider.notifier).getNowPanelStream();
});

final spaceActivationStreamProvider = StreamProvider.family<ActivationStatus, String>((ref, spaceId) {
  return ref.read(spacesProvider.notifier).getActivationStream(spaceId);
});
```

### State Synchronization Strategy

```dart
class StateSyncService {
  final FirebaseFirestore firestore;
  final HiveInterface localStorage;
  
  // Offline-first with Firebase sync
  Future<void> syncProfileData(String userId) async {
    try {
      final remoteData = await firestore.collection('users').doc(userId).get();
      final localData = await localStorage.get('profile_$userId');
      
      if (remoteData.exists && shouldUpdateLocal(remoteData, localData)) {
        await localStorage.put('profile_$userId', remoteData.data());
      }
    } catch (e) {
      // Graceful degradation to local data
      return localStorage.get('profile_$userId');
    }
  }
  
  // Real-time updates for critical data
  Stream<T> getRealtimeStream<T>(String collection, String docId) {
    return firestore.collection(collection).doc(docId).snapshots()
        .map((snapshot) => T.fromJson(snapshot.data()!));
  }
}
```

## 5. Performance & Scalability

### Performance Requirements

**Target Metrics:**
- App launch: <2 seconds cold start
- Page transitions: <300ms
- Tool interactions: <150ms response
- Calendar Tool: <100ms week view load
- Real-time updates: <1 second latency

**Optimization Strategies:**
```dart
// Lazy loading for large datasets
class LazyLoadingService {
  Future<List<T>> loadPage<T>(String collection, int page, int size) async {
    return firestore.collection(collection)
        .limit(size)
        .startAfter(getLastDocument(page))
        .get()
        .then((snapshot) => snapshot.docs.map((doc) => T.fromJson(doc.data())).toList());
  }
}

// Caching strategy
class CacheManager {
  final HiveInterface cache;
  final Duration defaultTTL = Duration(hours: 1);
  
  Future<T?> get<T>(String key) async {
    final cached = await cache.get(key);
    if (cached != null && !isExpired(cached)) {
      return T.fromJson(cached['data']);
    }
    return null;
  }
  
  Future<void> set<T>(String key, T data, {Duration? ttl}) async {
    await cache.put(key, {
      'data': data.toJson(),
      'expires': DateTime.now().add(ttl ?? defaultTTL).millisecondsSinceEpoch,
    });
  }
}
```

### Scalability Architecture

**Horizontal Scaling Strategy:**
- Firestore automatic scaling for database operations
- Cloud Functions for serverless compute scaling
- CDN for static asset delivery
- Client-side caching to reduce server load

**Data Partitioning:**
```dart
// Space-based data partitioning
class DataPartitionService {
  String getSpacePartition(String spaceId) {
    final hash = spaceId.hashCode;
    return 'spaces_${hash % 10}'; // 10 partitions
  }
  
  String getUserPartition(String userId) {
    final hash = userId.hashCode;
    return 'users_${hash % 10}'; // 10 partitions
  }
}
```

## 6. Security & Privacy

### Authentication & Authorization

```dart
class AuthService {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  
  // .edu email verification
  Future<bool> verifyEduEmail(String email) async {
    return email.endsWith('.edu') && await sendVerificationEmail(email);
  }
  
  // Account tier management
  Future<void> setAccountTier(String userId, AccountTier tier) async {
    await auth.setCustomUserClaims(userId, {'tier': tier.name});
  }
  
  // Builder access control
  Future<bool> canAccessHiveLab(String userId) async {
    final user = await auth.getUser(userId);
    final claims = user.customClaims;
    return claims?['tier'] == 'verified_plus' || claims?['builder'] == true;
  }
}
```

### Data Privacy Controls

```dart
class PrivacyService {
  // User data visibility controls
  Future<void> updatePrivacySettings(String userId, PrivacySettings settings) async {
    await firestore.collection('users').doc(userId).update({
      'privacy': settings.toJson(),
    });
  }
  
  // Anonymous data aggregation
  Future<Map<String, dynamic>> getAnonymizedUsageStats() async {
    // Aggregate usage data without personal identifiers
    return {
      'total_tool_usage': await getTotalToolUsage(),
      'space_activation_rate': await getSpaceActivationRate(),
      'builder_activity': await getBuilderActivity(),
    };
  }
}
```

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User profile access
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null && isVerifiedUser(request.auth);
    }
    
    // Space access based on membership
    match /spaces/{spaceId} {
      allow read: if request.auth != null && isSpaceMember(spaceId, request.auth.uid);
      allow write: if request.auth != null && isSpaceBuilder(spaceId, request.auth.uid);
    }
    
    // Builder-only access to HiveLAB
    match /builders/{userId} {
      allow read, write: if request.auth != null && 
                          request.auth.uid == userId && 
                          isBuilder(request.auth);
    }
    
    // Tool access and attribution
    match /tools/{toolId} {
      allow read: if request.auth != null && isVerifiedUser(request.auth);
      allow write: if request.auth != null && isBuilder(request.auth);
    }
  }
}
```

## 7. Development & Deployment

### CI/CD Pipeline

```yaml
# GitHub Actions workflow
name: HIVE vBETA CI/CD
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
      - run: flutter test integration_test/

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build apk --release
      - run: flutter build ios --release --no-codesign
      - run: flutter build web --release

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Deploy to Firebase App Distribution
        run: firebase appdistribution:distribute
      - name: Deploy Cloud Functions
        run: firebase deploy --only functions
      - name: Deploy Firestore Rules
        run: firebase deploy --only firestore:rules
```

### Environment Configuration

```dart
class EnvironmentConfig {
  static const String environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
  
  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';
  static bool get isProduction => environment == 'production';
  
  static String get firebaseProjectId {
    switch (environment) {
      case 'production':
        return 'hive-vbeta-prod';
      case 'staging':
        return 'hive-vbeta-staging';
      default:
        return 'hive-vbeta-dev';
    }
  }
}
```

### Monitoring & Analytics

```dart
class AnalyticsService {
  final FirebaseAnalytics analytics;
  
  // System-specific event tracking
  Future<void> trackProfileInteraction(String action, Map<String, dynamic> parameters) async {
    await analytics.logEvent(
      name: 'profile_$action',
      parameters: parameters,
    );
  }
  
  Future<void> trackToolUsage(String toolId, String spaceId) async {
    await analytics.logEvent(
      name: 'tool_usage',
      parameters: {
        'tool_id': toolId,
        'space_id': spaceId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
  
  Future<void> trackSpaceActivation(String spaceId, String builderId) async {
    await analytics.logEvent(
      name: 'space_activation',
      parameters: {
        'space_id': spaceId,
        'builder_id': builderId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
}
```

---

**Note:** This technical architecture prioritizes modularity, scalability, and maintainability while supporting the unique behavioral platform requirements of HIVE vBETA. The system is designed to evolve with student usage patterns and scale from summer pilot to full campus deployment. 