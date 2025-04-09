# Offline-Aware Form Components

This module provides UI components that display offline status and pending sync status for forms and form fields in the HIVE UI application. These components are designed to provide a consistent user experience when working with data that might be updated while offline.

## Components

### OfflineAwareFormField

Wraps a form field to display an indicator when there are pending changes that haven't been synced with the server yet.

```dart
OfflineAwareFormField(
  resourceType: 'profile', // The type of resource being edited
  resourceId: userId,       // The ID of the resource
  formField: TextFormField(
    controller: nameController,
    decoration: const InputDecoration(
      labelText: 'Display Name',
      hintText: 'Enter your display name',
    ),
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'Please enter your name';
      }
      return null;
    },
  ),
)
```

### OfflineAwareButton

A button that shows the offline/pending sync status and provides appropriate feedback to the user.

```dart
OfflineAwareButton(
  resourceType: 'profile',
  resourceId: userId,
  offlineLabel: 'Changes will sync when online',
  onPressed: handleSubmit,
  child: const Text('Save Changes'),
)
```

### OfflineStatusIndicator

A small indicator that shows whether a resource has pending changes that haven't been synced.

```dart
OfflineStatusIndicator(
  resourceType: 'profile',
  resourceId: userId,
  syncingLabel: 'Syncing profile...',
  offlineLabel: 'Will update when online',
  showOnlyWhenOffline: true,
)
```

## Usage Guidelines

1. **Resource Type and ID**: Always provide both the `resourceType` (e.g., 'profile', 'post', 'comment') and the `resourceId` to identify what resource is being edited.

2. **Offline Status**: The components automatically detect offline status and display appropriate indicators.

3. **Form Integration**: These components are designed to work with regular Flutter form widgets and can be used inside a standard `Form` widget.

4. **Styling**: The components follow HIVE UI's dark theme with gold accent colors.

## Example

```dart
Form(
  key: formKey,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Form title with offline status indicator
      Row(
        children: [
          const Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          OfflineStatusIndicator(
            resourceType: 'profile',
            resourceId: userId,
            syncingLabel: 'Syncing profile...',
          ),
        ],
      ),
      const SizedBox(height: 24),
      
      // Name field with offline awareness
      OfflineAwareFormField(
        resourceType: 'profile',
        resourceId: userId,
        formField: TextFormField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Display Name',
          ),
        ),
      ),
      
      // Submit button with offline awareness
      OfflineAwareButton(
        resourceType: 'profile',
        resourceId: userId,
        onPressed: submitForm,
        child: const Text('Save Changes'),
      ),
    ],
  ),
)
``` 