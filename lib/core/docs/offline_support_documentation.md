# HIVE UI - Offline Support System

## Overview

The HIVE UI app includes a robust offline support system that allows users to continue using the app and performing operations even when they lose internet connectivity. This document provides a comprehensive overview of the offline support architecture, components, and implementation guidelines.

## Key Components

### 1. Connectivity Monitoring

The `ConnectivityService` monitors the device's network status and provides real-time updates on connectivity changes. It uses the `connectivity_plus` package to detect different types of connections (WiFi, mobile data, etc.) and exposes a stream of connectivity status updates that other components can listen to.

```dart
// Example of using ConnectivityService
final connectivityService = ref.watch(connectivityServiceProvider);
final hasConnectivity = connectivityService.hasConnectivity;

// Stream-based usage
connectivityService.statusStream.listen((status) {
  if (status == ConnectivityResult.none) {
    // Device is offline, handle accordingly
  } else {
    // Device is online
  }
});
```

### 2. Offline Queue Management

The `OfflineQueueManager` manages operations that need to be performed when the device is online. When offline, operations are stored in a queue and executed automatically when connectivity is restored.

```dart
// Enqueueing an action
final action = OfflineAction(
  type: OfflineActionType.update,
  resourceType: 'profile',
  resourceId: userId,
  priority: 1,
  payload: updatedProfileData,
);
await offlineQueueManager.enqueueAction(action);
```

#### Offline Action Types

- `create`: Creating a new resource
- `update`: Updating an existing resource
- `delete`: Deleting a resource

### 3. Conflict Resolution

The `ConflictResolver` handles data conflicts that occur when local offline changes conflict with remote changes made since the device went offline. It supports various resolution strategies:

- `preferLocal`: Always use the local (offline) version
- `preferRemote`: Always use the remote (server) version
- `preferRecent`: Use the most recent version based on timestamps
- `customMerge`: Merge the data with custom logic

The enhanced smart merge functionality can handle complex nested objects and lists with appropriate field-level resolution strategies.

```dart
// Example of using conflict resolution with a custom merge function
final conflictResolver = ref.read(conflictResolverProvider);
final result = await conflictResolver.resolveConflict(
  action: offlineAction,
  remoteData: serverData,
  strategy: ConflictStrategy.customMerge,
  customMerge: (local, remote) => conflictResolver.smartMerge(
    local, 
    remote,
    fieldStrategies: {
      'name': ConflictStrategy.preferLocal,
      'timestamp': ConflictStrategy.preferRemote,
      'tags': ConflictStrategy.customMerge,
    },
  ),
);
```

### 4. Operation Recovery

The `OperationRecoveryManager` tracks operations and handles recovery of interrupted operations. It supports various recovery strategies:

- `standardRetry`: Simple retry of the operation
- `incrementalRetry`: Retry with exponential backoff
- `idempotentRetry`: Retry that handles idempotency concerns
- `conflictResolution`: Retry with conflict resolution

```dart
// Track an operation
final operationRecord = await operationRecoveryManager.trackOperation(
  operationType: 'update_profile',
  resourceType: 'profile',
  resourceId: userId,
  description: 'Updating user profile',
);

try {
  // Perform operation
  await profileRepository.updateProfile(userId, updatedProfile);
  
  // Mark as completed
  await operationRecoveryManager.updateOperation(
    operationRecord.id,
    OperationStatus.completed,
  );
} catch (e) {
  // Mark as failed
  await operationRecoveryManager.updateOperation(
    operationRecord.id,
    OperationStatus.failed,
    e.toString(),
  );
}
```

### 5. UI Components for Offline Status

The app includes several UI components to indicate offline status to users:

1. `OfflineStatusBanner`: A banner displayed at the top of the screen when the device is offline or has pending operations.
2. `OfflineStatusIndicator`: A smaller inline indicator that can be used within forms and other components.
3. `OfflineAwareButton`: A button that displays an indicator when the operation will be performed offline.
4. `OfflineAwareFormField`: A form field wrapper that shows offline status for field changes.

```dart
// Example of using offline UI components
OfflineStatusIndicator(
  resourceType: 'profile',
  resourceId: userId,
  offlineLabel: 'Will be saved when online',
  syncingLabel: 'Syncing...',
);

OfflineAwareButton(
  resourceType: 'profile',
  resourceId: userId,
  onPressed: () => saveProfile(),
  child: Text('Save Changes'),
);
```

## Implementation Pattern

### Repository Mixin

The `OfflineRepositoryMixin` can be applied to repository classes to add offline support. It provides methods for creating, updating, and deleting resources with automatic offline handling.

```dart
class OfflineProfileRepository with OfflineRepositoryMixin implements ProfileRepository {
  // Implementation details...
  
  @override
  Future<bool> updateProfile(String userId, UserProfile profile) async {
    return updateResource<UserProfile>(
      resourceType: 'profile',
      resourceId: userId,
      data: profile.toJson(),
      onlineOperation: () => _delegate.updateProfile(userId, profile),
      cacheKeyPrefix: 'user:$userId:profile',
    );
  }
}
```

## Error Handling & Recovery

The offline system includes comprehensive error handling and recovery mechanisms:

1. **Error Categorization**: Errors are categorized as network, authentication, resource, transient, or permanent.
2. **Exponential Backoff**: Retries use exponential backoff with jitter to prevent thundering herd.
3. **Recovery Strategies**: Different recovery strategies are applied based on the error type and operation.

## Best Practices

1. **Always Use Repository Pattern**: Implement offline support at the repository level.
2. **Handle UI State**: Always update UI based on offline status and pending operations.
3. **Use Optimistic Updates**: Apply local changes immediately while queuing for server sync.
4. **Provide Clear Feedback**: Always indicate to users when they're working offline.
5. **Test Offline Scenarios**: Thoroughly test the app's behavior under various connectivity conditions.

## Implementation Guidelines

### Adding Offline Support to a Feature

1. Create a repository that implements your feature's interface and uses the `OfflineRepositoryMixin`.
2. Register executors for each resource type in the `registerExecutors` method.
3. Implement optimistic updates for a seamless user experience.
4. Use offline-aware UI components to provide visual feedback.

### Resolving Conflicts

1. Identify fields that may cause conflicts.
2. Choose appropriate conflict resolution strategies for each field.
3. Implement custom merge logic for complex data structures if needed.
4. Test conflict scenarios thoroughly.

## Conclusion

The offline support system enables a seamless user experience regardless of connectivity. By implementing proper error handling, conflict resolution, and recovery strategies, the HIVE UI can provide reliable operation even in challenging network environments. 