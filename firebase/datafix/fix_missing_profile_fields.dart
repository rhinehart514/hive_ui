import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// This script ensures all user profiles have the required fields.
/// It adds missing fields with default values to maintain data consistency
/// and prevent app crashes due to missing fields.
/// 
/// Required fields include:
/// - displayName: String
/// - username: String
/// - profileImageUrl: String
/// - bio: String
/// - interests: List<String>
/// - joinDate: Timestamp
/// - lastActive: Timestamp
/// - connections: Map
/// - badges: List
/// - settings: Map
void main() async {
  // Initialize Flutter for Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();
  
  print('🔧 Starting profile field fix process...');
  await fixMissingProfileFields();
  print('✅ Profile field fix process completed!');
}

/// Fixes missing fields in user profiles
Future<void> fixMissingProfileFields() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  
  try {
    // Get all users
    print('📋 Fetching all user profiles from Firestore...');
    final QuerySnapshot usersSnapshot = await firestore.collection('users').get();
    print('🔍 Found ${usersSnapshot.docs.length} user profiles to process');
    
    // Track statistics
    int totalProfiles = usersSnapshot.docs.length;
    int profilesUpdated = 0;
    Map<String, int> missingFieldCounts = {
      'displayName': 0,
      'username': 0,
      'profileImageUrl': 0,
      'bio': 0,
      'interests': 0,
      'joinDate': 0,
      'lastActive': 0,
      'connections': 0,
      'badges': 0,
      'settings': 0,
    };
    
    // Define default values for missing fields
    final Map<String, dynamic> defaultValues = {
      'displayName': 'HIVE User',
      'username': '',  // Will be handled specially
      'profileImageUrl': 'https://firebasestorage.googleapis.com/v0/b/hive-app.appspot.com/o/default_avatar.png',
      'bio': 'No bio yet',
      'interests': <String>[],
      'joinDate': FieldValue.serverTimestamp(),
      'lastActive': FieldValue.serverTimestamp(),
      'connections': {
        'following': <String>[],
        'followers': <String>[],
        'friends': <String>[],
      },
      'badges': <Map<String, dynamic>>[],
      'settings': {
        'notifications': true,
        'privateProfile': false,
        'theme': 'dark',
        'language': 'en',
      },
    };
    
    // Process each user profile
    int profileIndex = 0;
    for (final DocumentSnapshot userDoc in usersSnapshot.docs) {
      profileIndex++;
      final String userId = userDoc.id;
      final Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      
      print('🔍 Processing profile $profileIndex/$totalProfiles: User $userId');
      
      // Check for missing fields
      Map<String, dynamic> updates = {};
      bool needsUpdate = false;
      
      // Special handling for username - use userId as default if missing
      if (!userData.containsKey('username') || userData['username'] == null || userData['username'] == '') {
        updates['username'] = 'user_$userId'.substring(0, 15);  // Ensure username isn't too long
        missingFieldCounts['username'] = (missingFieldCounts['username'] ?? 0) + 1;
        needsUpdate = true;
        print('  - Adding missing username: ${updates['username']}');
      }
      
      // Check and add all other missing fields
      defaultValues.forEach((field, defaultValue) {
        if (field != 'username' && (!userData.containsKey(field) || userData[field] == null)) {
          updates[field] = defaultValue;
          missingFieldCounts[field] = (missingFieldCounts[field] ?? 0) + 1;
          needsUpdate = true;
          print('  - Adding missing field: $field');
        }
      });
      
      // Update profile if needed
      if (needsUpdate) {
        try {
          await firestore.collection('users').doc(userId).update(updates);
          profilesUpdated++;
          print('  ✅ Updated profile for user $userId');
        } catch (e) {
          print('  ❌ Error updating profile for user $userId: $e');
        }
      } else {
        print('  ✓ Profile has all required fields');
      }
    }
    
    // Check for duplicate usernames and fix if found
    print('\n🔍 Checking for duplicate usernames...');
    Map<String, List<String>> usernameToUserIds = {};
    
    // Get all users again after updates
    final QuerySnapshot updatedUsersSnapshot = await firestore.collection('users').get();
    
    // Build username to userId mapping
    for (final DocumentSnapshot userDoc in updatedUsersSnapshot.docs) {
      final String userId = userDoc.id;
      final Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      
      if (userData.containsKey('username') && userData['username'] != null) {
        final String username = userData['username'].toString();
        
        usernameToUserIds.putIfAbsent(username, () => []);
        usernameToUserIds[username]!.add(userId);
      }
    }
    
    // Fix duplicate usernames
    int duplicateUsernamesFixed = 0;
    
    for (final MapEntry<String, List<String>> entry in usernameToUserIds.entries) {
      final String username = entry.key;
      final List<String> userIds = entry.value;
      
      if (userIds.length > 1) {
        print('  ⚠️ Found duplicate username: $username used by ${userIds.length} users');
        
        // Update all but the first user with the duplicate username
        for (int i = 1; i < userIds.length; i++) {
          final String userId = userIds[i];
          final String newUsername = '${username}_$i';
          
          try {
            await firestore.collection('users').doc(userId).update({
              'username': newUsername
            });
            
            duplicateUsernamesFixed++;
            print('  ✅ Changed username for user $userId from $username to $newUsername');
          } catch (e) {
            print('  ❌ Error updating username for user $userId: $e');
          }
        }
      }
    }
    
    // Print summary
    print('\n📊 Summary:');
    print('  - Total profiles processed: $totalProfiles');
    print('  - Profiles updated: $profilesUpdated');
    print('  - Duplicate usernames fixed: $duplicateUsernamesFixed');
    print('\n  Missing field counts:');
    missingFieldCounts.forEach((field, count) {
      print('    - $field: $count');
    });
    
  } catch (e) {
    print('❌ Error fixing missing profile fields: $e');
  }
} 