import 'package:cloud_firestore/cloud_firestore.dart';

/// Mock profile data that can be used for testing UI components
class MockProfileData {
  /// Generate a mock profile for "Goose Chaser"
  static Map<String, dynamic> getGooseChaserProfile() {
    return {
      'id': 'goose_chaser_123',
      'displayName': 'Goose Chaser',
      'username': 'goosechaser',
      'email': 'goosechaser@university.edu',
      'bio': 'Professional goose chaser at the university pond. CS major who loves hackathons and building apps that help connect people.',
      'profileImageUrl': 'https://images.unsplash.com/photo-1533738363-b7f9aef128ce?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=500&q=80',
      'coverImageUrl': 'https://images.unsplash.com/photo-1500462918059-b1a0cb512f1d?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1000&q=80',
      'major': 'Computer Science',
      'year': 'Junior',
      'residence': 'North Campus',
      'isVerified': true,
      'joinedAt': Timestamp.fromDate(DateTime(2022, 9, 1)),
      'lastActive': Timestamp.fromDate(DateTime.now()),
      'friendCount': 42,
      'eventCount': 15,
      'interests': [
        'Hackathons',
        'AI/ML',
        'Web Development',
        'Wildlife Photography',
        'Hiking',
        'Chess',
      ],
      'socialLinks': {
        'instagram': 'goose_chaser',
        'twitter': 'goosechaser',
        'github': 'goosechaser',
        'linkedin': 'goosechaser',
      },
      'status': 'Working on a new project! 💻',
      'settings': {
        'notificationsEnabled': true,
        'darkModeEnabled': true,
        'privacyLevel': 'public',
      },
      'achievements': [
        {
          'id': 'hackathon_winner',
          'name': 'Hackathon Champion',
          'description': 'Won first place in the University Hackathon',
          'awardedAt': Timestamp.fromDate(DateTime(2023, 3, 15)),
        },
        {
          'id': 'event_organizer',
          'name': 'Event Organizer',
          'description': 'Successfully organized 5+ campus events',
          'awardedAt': Timestamp.fromDate(DateTime(2023, 5, 10)),
        },
      ],
      'recentActivity': [
        {
          'type': 'event_created',
          'eventId': 'event123',
          'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
        },
        {
          'type': 'event_joined',
          'eventId': 'event456',
          'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5))),
        },
      ],
    };
  }

  /// Generate additional mock profiles for suggested friends
  static List<Map<String, dynamic>> getSuggestedFriendsProfiles() {
    return [
      {
        'id': 'tech_enthusiast_456',
        'displayName': 'Alex Chen',
        'username': 'alexchen',
        'email': 'alexchen@university.edu',
        'bio': 'CS major passionate about mobile development and AI. Looking to connect with like-minded students!',
        'profileImageUrl': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=500&q=80',
        'major': 'Computer Science',
        'year': 'Junior',
        'residence': 'North Campus',
        'friendCount': 37,
        'interests': [
          'Mobile Development',
          'AI/ML',
          'Robotics',
          'Gaming',
        ],
        'status': 'Looking for study buddies for the algorithms final!',
        'lastActive': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2))),
        'matchCriteria': 'major',
        'matchValue': 'Computer Science',
      },
      {
        'id': 'photo_lover_789',
        'displayName': 'Maya Johnson',
        'username': 'mayaj',
        'email': 'mayaj@university.edu',
        'bio': 'Photography major with a love for wildlife and nature photography. Always looking for new spots on campus!',
        'profileImageUrl': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=500&q=80',
        'major': 'Photography',
        'year': 'Senior',
        'residence': 'West Village',
        'friendCount': 65,
        'interests': [
          'Wildlife Photography',
          'Hiking',
          'Nature',
          'Travel',
        ],
        'status': 'Just posted a new photo gallery from the campus pond!',
        'lastActive': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 5))),
        'matchCriteria': 'interest',
        'matchValue': 'Wildlife Photography',
      },
      {
        'id': 'chess_master_101',
        'displayName': 'Daniel Park',
        'username': 'chessmaster',
        'email': 'danielp@university.edu',
        'bio': 'Economics major and chess enthusiast. Always up for a game at the student center!',
        'profileImageUrl': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=500&q=80',
        'major': 'Economics',
        'year': 'Sophomore',
        'residence': 'North Campus',
        'friendCount': 28,
        'interests': [
          'Chess',
          'Game Theory',
          'Data Analysis',
          'Reading',
        ],
        'status': 'Hosting a chess tournament this weekend! DM to join.',
        'lastActive': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
        'matchCriteria': 'interest',
        'matchValue': 'Chess',
      },
      {
        'id': 'dorm_neighbor_202',
        'displayName': 'Sophia Torres',
        'username': 'sophiat',
        'email': 'sophiat@university.edu',
        'bio': 'Biology major with a focus on ecology. Love being outdoors and exploring campus!',
        'profileImageUrl': 'https://images.unsplash.com/photo-1580489944761-15a19d654956?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=500&q=80',
        'major': 'Biology',
        'year': 'Junior',
        'residence': 'North Campus',
        'friendCount': 51,
        'interests': [
          'Ecology',
          'Hiking',
          'Environmental Activism',
          'Photography',
        ],
        'status': 'Organizing a campus cleanup this weekend!',
        'lastActive': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 12))),
        'matchCriteria': 'residence',
        'matchValue': 'North Campus',
      },
      {
        'id': 'hackathon_pro_303',
        'displayName': 'Jordan Lee',
        'username': 'hackpro',
        'email': 'jordanl@university.edu',
        'bio': 'Computer Engineering major who loves hackathons and building cool projects. Let\'s collaborate!',
        'profileImageUrl': 'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=500&q=80',
        'major': 'Computer Engineering',
        'year': 'Senior',
        'residence': 'East Village',
        'friendCount': 47,
        'interests': [
          'Hackathons',
          'IoT',
          'Web Development',
          'Entrepreneurship',
        ],
        'status': 'Working on a new IoT project for the upcoming hackathon!',
        'lastActive': Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 30))),
        'matchCriteria': 'interest',
        'matchValue': 'Hackathons',
      },
    ];
  }
  
  /// Generate data for friend requests
  static List<Map<String, dynamic>> getFriendRequests() {
    return [
      {
        'id': 'request_123',
        'senderId': 'tech_enthusiast_456',
        'receiverId': 'goose_chaser_123',
        'status': 'pending',
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
        'updatedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
      },
      {
        'id': 'request_456',
        'senderId': 'goose_chaser_123',
        'receiverId': 'hackathon_pro_303',
        'status': 'pending',
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
        'updatedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
      },
    ];
  }
  
  /// Generate data for user friends
  static List<Map<String, dynamic>> getFriends() {
    return [
      {
        'id': 'friendship_123',
        'userId1': 'goose_chaser_123',
        'userId2': 'photo_lover_789',
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30))),
      },
      {
        'id': 'friendship_456',
        'userId1': 'goose_chaser_123',
        'userId2': 'chess_master_101',
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 45))),
      },
      {
        'id': 'friendship_789',
        'userId1': 'dorm_neighbor_202',
        'userId2': 'goose_chaser_123',
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 60))),
      },
    ];
  }
  
  /// Helper method to upload all mock data to Firestore
  static Future<void> uploadMockDataToFirestore() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    
    // Upload Goose Chaser profile
    await firestore
        .collection('users')
        .doc('goose_chaser_123')
        .set(getGooseChaserProfile());
    
    // Upload suggested friends profiles
    for (var profile in getSuggestedFriendsProfiles()) {
      await firestore
          .collection('users')
          .doc(profile['id'])
          .set(profile);
    }
    
    // Upload friend requests
    for (var request in getFriendRequests()) {
      await firestore
          .collection('friendRequests')
          .doc(request['id'])
          .set(request);
    }
    
    // Upload friends
    for (var friendship in getFriends()) {
      await firestore
          .collection('friends')
          .doc(friendship['id'])
          .set(friendship);
    }
  }
} 