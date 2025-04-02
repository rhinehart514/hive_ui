import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A simplified user model for the application
class UserData {
  final String? id;
  final String? name;
  final String? email;
  final List<String> joinedClubs;
  final List<String> attendedEvents;
  final List<String> interests;

  const UserData({
    this.id,
    this.name,
    this.email,
    this.joinedClubs = const [],
    this.attendedEvents = const [],
    this.interests = const [],
  });

  /// Check if the user is a member of a specific club
  bool isMemberOf(String clubId) => joinedClubs.contains(clubId);

  /// Check if the user has attended an event
  bool hasAttendedEvent(String eventId) => attendedEvents.contains(eventId);

  /// Create a new UserData with updated joined clubs
  UserData joinClub(String clubId) {
    if (joinedClubs.contains(clubId)) {
      debugPrint('joinClub: Club $clubId already in joinedClubs, not adding again');
      return this;
    }
    debugPrint('joinClub: Adding club $clubId to joinedClubs');
    return UserData(
      id: id,
      name: name,
      email: email,
      joinedClubs: [...joinedClubs, clubId],
      attendedEvents: attendedEvents,
      interests: interests,
    );
  }

  /// Create a new UserData with the specified club removed
  UserData leaveClub(String clubId) {
    if (!joinedClubs.contains(clubId)) {
      debugPrint('leaveClub: Club $clubId not in joinedClubs, nothing to remove');
      return this;
    }
    debugPrint('leaveClub: Removing club $clubId from joinedClubs');
    return UserData(
      id: id,
      name: name,
      email: email,
      joinedClubs: joinedClubs.where((id) => id != clubId).toList(),
      attendedEvents: attendedEvents,
      interests: interests,
    );
  }

  /// Add an interest to the user's profile
  UserData addInterest(String interest) {
    if (interests.contains(interest)) return this;
    return UserData(
      id: id,
      name: name,
      email: email,
      joinedClubs: joinedClubs,
      attendedEvents: attendedEvents,
      interests: [...interests, interest],
    );
  }

  /// Remove an interest from the user's profile
  UserData removeInterest(String interest) {
    if (!interests.contains(interest)) return this;
    return UserData(
      id: id,
      name: name,
      email: email,
      joinedClubs: joinedClubs,
      attendedEvents: attendedEvents,
      interests: interests.where((i) => i != interest).toList(),
    );
  }

  /// Calculate how well an event's details match user interests (0.0-1.0)
  double calculateInterestMatchScore(
      String title, String description, List<String> tags) {
    if (interests.isEmpty) return 0.0;

    // Combine all event text data for matching
    final eventText =
        ("$title $description ${tags.join(" ")}").toLowerCase();

    // Count how many interests match the event content
    int matchCount = 0;
    for (final interest in interests) {
      if (eventText.contains(interest.toLowerCase())) {
        matchCount++;
      }
    }

    // Calculate score based on the percentage of interests matched
    return matchCount / interests.length;
  }
  
  /// Create a UserData object from Firebase data
  factory UserData.fromFirebase(User? firebaseUser, Map<String, dynamic>? userData) {
    if (firebaseUser == null) {
      return const UserData();
    }
    
    List<String> joinedClubs = [];
    List<String> attendedEvents = [];
    List<String> interests = [];
    
    if (userData != null) {
      // Get joined clubs - check both fields for compatibility
      if (userData['followedSpaces'] != null && userData['followedSpaces'] is List) {
        joinedClubs = List<String>.from(userData['followedSpaces']);
      } else if (userData['joinedClubs'] != null && userData['joinedClubs'] is List) {
        joinedClubs = List<String>.from(userData['joinedClubs']);
      }
      
      // Get attended events
      if (userData['attendedEvents'] != null && userData['attendedEvents'] is List) {
        attendedEvents = List<String>.from(userData['attendedEvents']);
      }
      
      // Get interests
      if (userData['interests'] != null && userData['interests'] is List) {
        interests = List<String>.from(userData['interests']);
      }
    }
    
    return UserData(
      id: firebaseUser.uid,
      name: firebaseUser.displayName,
      email: firebaseUser.email,
      joinedClubs: joinedClubs,
      attendedEvents: attendedEvents,
      interests: interests.isEmpty ? [
        'music', 'tech', 'ai', 'dance', 'science', 'engineering',
        'art', 'film', 'literature', 'sports', 'basketball', 'robotics', 'hackathon'
      ] : interests,
    );
  }
}

/// Class to manage user data state
class UserDataNotifier extends StateNotifier<UserData?> {
  UserDataNotifier() : super(null) {
    _initializeUserData();
  }
  
  Future<void> _initializeUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      debugPrint('UserDataNotifier: No authenticated user found');
      state = null;
      return;
    }
    
    debugPrint('UserDataNotifier: Authenticated user found - ${user.uid}');
    
    // Initialize with basic data from Firebase Auth
    state = UserData(
      id: user.uid,
      name: user.displayName,
      email: user.email,
    );
    
    try {
      // Fetch extended user data from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
          
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        debugPrint('UserDataNotifier: Got Firestore data for user ${user.uid}');
        
        // Get joined clubs/spaces
        List<String> joinedClubs = [];
        if (data['followedSpaces'] != null && data['followedSpaces'] is List) {
          joinedClubs = List<String>.from(data['followedSpaces']);
          debugPrint('UserDataNotifier: User has ${joinedClubs.length} followed spaces');
        } else if (data['joinedClubs'] != null && data['joinedClubs'] is List) {
          joinedClubs = List<String>.from(data['joinedClubs']);
          debugPrint('UserDataNotifier: User has ${joinedClubs.length} joined clubs');
        }
        
        // Get attended events
        List<String> attendedEvents = [];
        if (data['attendedEvents'] != null && data['attendedEvents'] is List) {
          attendedEvents = List<String>.from(data['attendedEvents']);
        }
        
        // Get interests
        List<String> interests = [];
        if (data['interests'] != null && data['interests'] is List) {
          interests = List<String>.from(data['interests']);
        }
        
        // Update state with complete user data
        state = UserData(
          id: user.uid,
          name: user.displayName,
          email: user.email,
          joinedClubs: joinedClubs,
          attendedEvents: attendedEvents,
          interests: interests.isEmpty ? [
            'music', 'tech', 'ai', 'dance', 'science', 'engineering',
            'art', 'film', 'literature', 'sports', 'basketball', 'robotics', 'hackathon'
          ] : interests,
        );
      }
    } catch (error) {
      debugPrint('UserDataNotifier: Error fetching user data: $error');
    }
  }
  
  // Methods to update user data
  void joinClub(String clubId) {
    if (state == null) return;
    
    final updatedState = state!.joinClub(clubId);
    state = updatedState;
    
    // Also update Firestore
    if (state?.id != null) {
      // Get the current followedSpaces array length to update clubCount
      FirebaseFirestore.instance.collection('users').doc(state!.id).get().then((doc) {
        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            List<String> followedSpaces = [];
            if (data['followedSpaces'] is List) {
              followedSpaces = List<String>.from(data['followedSpaces']);
            }
            
            // Add the club if it's not already in the list
            if (!followedSpaces.contains(clubId)) {
              followedSpaces.add(clubId);
            }
            
            // Update both followedSpaces and clubCount
            FirebaseFirestore.instance.collection('users').doc(state!.id).update({
              'followedSpaces': FieldValue.arrayUnion([clubId]),
              'clubCount': followedSpaces.length,
              'updatedAt': FieldValue.serverTimestamp(),
            }).catchError((error) {
              debugPrint('UserDataNotifier: Error updating Firestore: $error');
            });
          }
        }
      }).catchError((error) {
        debugPrint('UserDataNotifier: Error getting user document: $error');
      });
    }
  }
  
  void leaveClub(String clubId) {
    if (state == null) return;
    
    final updatedState = state!.leaveClub(clubId);
    state = updatedState;
    
    // Also update Firestore
    if (state?.id != null) {
      // Get the current followedSpaces array length to update clubCount
      FirebaseFirestore.instance.collection('users').doc(state!.id).get().then((doc) {
        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            List<String> followedSpaces = [];
            if (data['followedSpaces'] is List) {
              followedSpaces = List<String>.from(data['followedSpaces']);
            }
            
            // Remove the club if it's in the list
            if (followedSpaces.contains(clubId)) {
              followedSpaces.remove(clubId);
            }
            
            // Update both followedSpaces and clubCount
            FirebaseFirestore.instance.collection('users').doc(state!.id).update({
              'followedSpaces': FieldValue.arrayRemove([clubId]),
              'clubCount': followedSpaces.length,
              'updatedAt': FieldValue.serverTimestamp(),
            }).catchError((error) {
              debugPrint('UserDataNotifier: Error updating Firestore: $error');
            });
          }
        }
      }).catchError((error) {
        debugPrint('UserDataNotifier: Error getting user document: $error');
      });
    }
  }
  
  void addInterest(String interest) {
    if (state == null) return;
    
    final updatedState = state!.addInterest(interest);
    state = updatedState;
    
    // Also update Firestore
    if (state?.id != null) {
      FirebaseFirestore.instance.collection('users').doc(state!.id).update({
        'interests': FieldValue.arrayUnion([interest]),
        'updatedAt': FieldValue.serverTimestamp(),
      }).catchError((error) {
        debugPrint('UserDataNotifier: Error updating Firestore: $error');
      });
    }
  }
  
  void removeInterest(String interest) {
    if (state == null) return;
    
    final updatedState = state!.removeInterest(interest);
    state = updatedState;
    
    // Also update Firestore
    if (state?.id != null) {
      FirebaseFirestore.instance.collection('users').doc(state!.id).update({
        'interests': FieldValue.arrayRemove([interest]),
        'updatedAt': FieldValue.serverTimestamp(),
      }).catchError((error) {
        debugPrint('UserDataNotifier: Error updating Firestore: $error');
      });
    }
  }
  
  // Refresh user data from Firestore
  Future<void> refreshUserData() async {
    await _initializeUserData();
  }
  
  /// Update user data with new data and save to Firestore
  void updateUserData(UserData userData) {
    if (userData.id == null) {
      debugPrint('UserDataNotifier: Cannot update user data without id');
      return;
    }
    
    // Update local state
    state = userData;
    debugPrint('UserDataNotifier: Updated user data for ${userData.id}');
    
    // Update Firestore document
    try {
      FirebaseFirestore.instance.collection('users').doc(userData.id).update({
        'followedSpaces': userData.joinedClubs,
        'attendedEvents': userData.attendedEvents,
        'interests': userData.interests,
        'updatedAt': FieldValue.serverTimestamp(),
      }).catchError((error) {
        debugPrint('UserDataNotifier: Error updating Firestore: $error');
      });
    } catch (error) {
      debugPrint('UserDataNotifier: Error updating user data in Firestore: $error');
    }
  }
}

/// Provider for the current user data
final userProvider = StateNotifierProvider<UserDataNotifier, UserData?>((ref) {
  return UserDataNotifier();
});

/// Provider to join a club
final joinClubProvider = Provider.family<void, String>((ref, clubId) {
  ref.read(userProvider.notifier).joinClub(clubId);
});

/// Provider to leave a club
final leaveClubProvider = Provider.family<void, String>((ref, clubId) {
  ref.read(userProvider.notifier).leaveClub(clubId);
});

/// Provider to add a user interest
final addInterestProvider = Provider.family<void, String>((ref, interest) {
  ref.read(userProvider.notifier).addInterest(interest);
});

/// Provider to remove a user interest
final removeInterestProvider = Provider.family<void, String>((ref, interest) {
  ref.read(userProvider.notifier).removeInterest(interest);
});
