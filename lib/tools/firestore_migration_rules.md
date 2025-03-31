# Temporary Firestore Rules for Migration

Copy these rules to your Firebase console (Firestore Database → Rules) while running the migration. **Restore your original rules afterward for security.**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Temporary rules to allow migration script to work without authentication
    
    // Allow read access to spaces and events collections
    match /spaces/{spaceId} {
      allow read: if true;
      
      // Allow write access to nested space collections
      match /{spaceType}/{typeId} {
        allow read, write: if true;
        
        match /spaces/{nestedSpaceId} {
          allow read, write: if true;
          
          match /events/{eventId} {
            allow read, write: if true;
          }
        }
      }
    }
    
    // Allow read access to events collection
    match /events/{eventId} {
      allow read: if true;
    }
    
    // Keep other collections secure
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Steps for Event Migration

1. Copy the rules above to your Firebase console temporarily
2. Run the migration tool:
   ```
   flutter run -d windows lib/tools/migrate_events_to_spaces.dart
   ```
   Or use the batch file on Windows:
   ```
   lib/tools/migrate_events_to_spaces.bat
   ```
3. Wait for the migration to complete
4. Restore your original security rules immediately afterward

## Checking Migration Results

After migration, you can check the results in the Firebase console:
1. Go to Firestore Database
2. Navigate to the "spaces" collection
3. You should see documents for each space type ("student_organizations", "university_organizations", etc.)
4. Within each type, you'll find a "spaces" collection with your spaces
5. Each space will have an "events" collection containing the migrated events 