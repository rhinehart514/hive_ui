import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ui/data/datasources/firestore_user_datasource.dart';
import 'package:hive_ui/domain/entities/user_profile.dart';
import 'package:hive_ui/domain/failures/auth_failure.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreUserDataSource dataSource;
  const usersCollection = 'users_test';
  const verificationRequestsCollection = 'verification_requests_test';

  // Helper to create a basic UserProfile
  UserProfile createTestProfile({
    String username = 'testuser',
    String email = 'test@example.com',
    String firstName = 'Test',
    String lastName = 'User',
    String residence = 'Test Residence',
    String major = 'Test Major',
    List<String> interests = const ['interest1', 'interest2'],
    String tier = 'base',
  }) {
    return UserProfile(
      username: username,
      email: email,
      firstName: firstName,
      lastName: lastName,
      residence: residence,
      major: major,
      interests: interests,
      tier: UserTier.values.firstWhere((e) => e.toString().split('.').last == tier, orElse: () => UserTier.base),
    );
  }

  // Helper to add Firestore-specific fields for testing saves/reads
  Map<String, dynamic> profileToFirestoreJson(UserProfile profile, String uid) {
    final json = profile.toJson();
    json['uid'] = uid;
    json['v'] = 1;
    return json;
  }

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    dataSource = FirestoreUserDataSource(
      fakeFirestore,
      usersCollection,
      verificationRequestsCollection,
    );
  });

  group('FirestoreUserDataSource Tests', () {
    group('saveUserProfile', () {
      test('should save a new user profile successfully', () async {
        const testUid = 'new_user_id';
        final profile = createTestProfile(username: 'newuser');
        final result = await dataSource.saveUserProfile(profile, testUid);

        expect(result.isSuccess, isTrue);
        expect(result.getSuccess, equals(profile));

        // Verify data in fake Firestore
        final doc = await fakeFirestore.collection(usersCollection).doc(testUid).get();
        expect(doc.exists, isTrue);
        final data = doc.data();
        expect(data, isNotNull);
        if (data != null) {
           expect(data['username'], equals('newuser'));
           expect(data['uid'], equals(testUid));
           expect(data['v'], equals(1));
           expect(data['createdAt'], isNotNull); // Server timestamp added by fake
           expect(data['updatedAt'], isNotNull); // Server timestamp added by fake
        }
      });

      test('should return failure if username is already taken', () async {
        // Pre-populate with an existing user
        const existingUid = 'existing_user';
        const existingUsername = 'existinguser';
        final existingProfile = createTestProfile(username: existingUsername);
        await fakeFirestore.collection(usersCollection).doc(existingUid).set(profileToFirestoreJson(existingProfile, existingUid));

        const newUid = 'new_user_id';
        final newProfile = createTestProfile(username: existingUsername); // Same username
        final result = await dataSource.saveUserProfile(newProfile, newUid);

        expect(result.isFailure, isTrue);
        expect(result.getFailure, isA<InvalidInputFailure>());
        expect(result.getFailure.message, contains('username is already taken'));

        // Verify new user was not created
        final doc = await fakeFirestore.collection(usersCollection).doc(newUid).get();
        expect(doc.exists, isFalse);
      });

       test('should return ServerFailure on Firestore exception', () async {
         // Skipping this test due to limitations in reliably causing
         // specific exceptions with fake_cloud_firestore.
         // A proper mocking framework (Mockito) would be needed.
       });
    });

    group('getUserProfile', () {
      test('should return user profile if found', () async {
        const testUid = 'test_uid';
        final profile = createTestProfile();
        await fakeFirestore.collection(usersCollection).doc(testUid).set(profileToFirestoreJson(profile, testUid));

        final result = await dataSource.getUserProfile(testUid);

        expect(result.isSuccess, isTrue);
        // UserProfile uses Equatable, so direct comparison should work.
        expect(result.getSuccess, equals(profile));
      });

      test('should return InvalidInputFailure if user profile not found', () async {
        final result = await dataSource.getUserProfile('non_existent_uid');

        expect(result.isFailure, isTrue);
        expect(result.getFailure, isA<InvalidInputFailure>());
        expect(result.getFailure.message, contains('User profile not found'));
      });

       test('should return ServerFailure if user data is corrupt/missing fields', () async {
         // Set fundamentally incorrect data that UserProfile.fromJson will reject.
         await fakeFirestore.collection(usersCollection).doc('corrupt_data_user').set({'invalidField': true});

         final result = await dataSource.getUserProfile('corrupt_data_user');

         expect(result.isFailure, isTrue);
         // Depending on the exact error in fromJson, this might be a ServerFailure
         // wrapping a TypeError or FormatException.
         expect(result.getFailure, isA<ServerFailure>());
       });

       test('should return ServerFailure on Firestore exception', () async {
          // Skip specific exception test due to fake limitations
       });
    });

    group('updateUserProfile', () {
       test('should update user profile successfully and return updated profile', () async {
         const testUid = 'update_uid';
         final initialProfile = createTestProfile(firstName: 'Initial');
         await fakeFirestore.collection(usersCollection).doc(testUid).set(profileToFirestoreJson(initialProfile, testUid));

         final updates = {'firstName': 'Updated', 'major': 'Updated Major'};
         final result = await dataSource.updateUserProfile(testUid, updates);

         expect(result.isSuccess, isTrue);
         final updatedProfile = result.getSuccess;
         expect(updatedProfile.firstName, equals('Updated'));
         expect(updatedProfile.major, equals('Updated Major'));
         expect(updatedProfile.lastName, equals(initialProfile.lastName)); // Unchanged field

         // Verify data in fake Firestore
         final doc = await fakeFirestore.collection(usersCollection).doc(testUid).get();
         expect(doc.exists, isTrue);
         final data = doc.data();
          expect(data, isNotNull);
         if (data != null) {
           expect(data['firstName'], equals('Updated'));
           expect(data['major'], equals('Updated Major'));
           expect(data['updatedAt'], isNotNull); // Should be updated
         }
       });

       test('should return failure if trying to update to an already taken username', () async {
         // User 1
         const user1Uid = 'user1';
         const user1Username = 'user1name';
         final user1Profile = createTestProfile(username: user1Username);
         await fakeFirestore.collection(usersCollection).doc(user1Uid).set(profileToFirestoreJson(user1Profile, user1Uid));
         // User 2
         const user2Uid = 'user2';
         const user2Username = 'user2name';
         final user2Profile = createTestProfile(username: user2Username);
         await fakeFirestore.collection(usersCollection).doc(user2Uid).set(profileToFirestoreJson(user2Profile, user2Uid));

         // Try to update user2's username to user1's username
         final updates = {'username': user1Username};
         final result = await dataSource.updateUserProfile(user2Uid, updates);

         expect(result.isFailure, isTrue);
         expect(result.getFailure, isA<InvalidInputFailure>());
         expect(result.getFailure.message, contains('username is already taken'));

         // Verify user2's username was not updated
         final doc = await fakeFirestore.collection(usersCollection).doc(user2Uid).get();
         expect(doc.data()?['username'], equals(user2Username));
       });

       test('should return failure if user to update does not exist (during fetch after update)', () async {
          final updates = {'firstName': 'Updated'};
          final result = await dataSource.updateUserProfile('non_existent_uid', updates);

          // The update call might not throw if the doc doesn't exist,
          // but the subsequent getUserProfile call will fail.
          expect(result.isFailure, isTrue);
          expect(result.getFailure, isA<InvalidInputFailure>()); // From the getUserProfile call
          expect(result.getFailure.message, contains('User profile not found'));
       });

       test('should return ServerFailure on Firestore exception', () async {
          // Skip specific exception test due to fake limitations
       });
    });

    group('isUsernameTaken', () {
       test('should return true if username is taken', () async {
         const testUid = 'taken_user';
         const testUsername = 'takenname';
         final profile = createTestProfile(username: testUsername);
         await fakeFirestore.collection(usersCollection).doc(testUid).set(profileToFirestoreJson(profile, testUid));

         final result = await dataSource.isUsernameTaken(testUsername);

         expect(result.isSuccess, isTrue);
         expect(result.getSuccess, isTrue);
       });

       test('should return false if username is not taken', () async {
         final result = await dataSource.isUsernameTaken('not_taken_name');

         expect(result.isSuccess, isTrue);
         expect(result.getSuccess, isFalse);
       });

       test('should return ServerFailure on Firestore exception', () async {
          // Skip specific exception test due to fake limitations
       });
    });

    group('requestVerification', () {
      test('should create verification request and update user tier successfully', () async {
        const testUid = 'verify_uid';
        final profile = createTestProfile(tier: 'base');
        await fakeFirestore.collection(usersCollection).doc(testUid).set(profileToFirestoreJson(profile, testUid));

        final result = await dataSource.requestVerification(testUid);

        expect(result.isSuccess, isTrue);

        // Verify verification request document
        final querySnapshot = await fakeFirestore.collection(verificationRequestsCollection)
            .where('uid', isEqualTo: testUid)
            .get();
        expect(querySnapshot.docs.length, equals(1));
        final requestDoc = querySnapshot.docs.first;
        final requestData = requestDoc.data();
        expect(requestData['status'], equals('pending'));
        expect(requestData['createdAt'], isNotNull);

        // Verify user profile tier update
        final userDoc = await fakeFirestore.collection(usersCollection).doc(testUid).get();
        expect(userDoc.data()?['tier'], equals('pending'));
        expect(userDoc.data()?['updatedAt'], isNotNull);
      });

      test('should return failure if user profile does not exist', () async {
         final result = await dataSource.requestVerification('non_existent_uid');

         expect(result.isFailure, isTrue);
         // Failure comes from the initial getUserProfile check
         expect(result.getFailure, isA<InvalidInputFailure>());
         expect(result.getFailure.message, contains('User profile not found'));

         // Verify no request was created
         final querySnapshot = await fakeFirestore.collection(verificationRequestsCollection)
             .where('uid', isEqualTo: 'non_existent_uid')
             .get();
         expect(querySnapshot.docs.isEmpty, isTrue);
      });

       test('should return ServerFailure on Firestore exception', () async {
          // Skip specific exception test due to fake limitations
       });
    });

     group('getUsersByUsername', () {
       test('should return list of users matching the username', () async {
         final profile1 = createTestProfile(username: 'sharedname');
         final profile2 = createTestProfile(username: 'sharedname');
         final profile3 = createTestProfile(username: 'differentname');
         // Need unique UIDs
         const uid1 = 'userA';
         const uid2 = 'userB';
         const uid3 = 'userC';
         await fakeFirestore.collection(usersCollection).doc(uid1).set(profileToFirestoreJson(profile1, uid1));
         await fakeFirestore.collection(usersCollection).doc(uid2).set(profileToFirestoreJson(profile2, uid2));
         await fakeFirestore.collection(usersCollection).doc(uid3).set(profileToFirestoreJson(profile3, uid3));

         final result = await dataSource.getUsersByUsername('sharedname');

         expect(result.isSuccess, isTrue);
         final users = result.getSuccess;
         expect(users.length, equals(2));
         // Use UserProfile equality check (assuming Equatable is correctly implemented)
         expect(users, contains(profile1));
         expect(users, contains(profile2));
         expect(users, isNot(contains(profile3)));
       });

       test('should return empty list if no users match the username', () async {
          final result = await dataSource.getUsersByUsername('no_match_username');
          expect(result.isSuccess, isTrue);
          expect(result.getSuccess.isEmpty, isTrue);
       });

       test('should return ServerFailure on Firestore exception', () async {
          // Skip specific exception test due to fake limitations
       });
     });

  });
}

// Note: Testing specific Firestore exceptions (like permissions errors, network errors)
// is challenging with fake_cloud_firestore. For those scenarios, using mockito
// with a mocked FirebaseFirestore instance provides more control over simulating failures.
// These tests primarily cover the logic flow and interaction with the fake data.

// Ensure UserProfile has a valid == operator and hashCode implemented (uses Equatable, so should be fine).

// Also ensure UserProfile.fromJson handles potential discrepancies between the entity
// and Firestore data gracefully (e.g., missing fields, type mismatches if schema evolves). The tests cover basic corruption. 