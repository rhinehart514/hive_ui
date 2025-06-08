import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for handling email operations
class EmailService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  EmailService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Sends a verification email to the current user
  /// 
  /// This triggers a Cloud Function that will send an actual email
  /// with a verification code
  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;
    
    if (user == null) {
      throw Exception('No user is currently signed in');
    }
    
    if (user.email == null || user.email!.isEmpty) {
      throw Exception('User does not have an email address');
    }
    
    // Generate a random 6-digit verification code (in production, this should be more secure)
    final verificationCode = (100000 + DateTime.now().microsecond % 900000).toString();
    
    // Store the verification code and request in Firestore
    // This will trigger a Cloud Function to send the actual email
    await _firestore.collection('emailVerifications').add({
      'userId': user.uid,
      'email': user.email,
      'code': verificationCode,
      'type': 'verification',
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(minutes: 30)),
      ),
      'status': 'pending',
    });
    
    return;
  }

  /// Verifies an email using the provided verification code
  Future<void> verifyEmailWithCode(String code) async {
    final user = _auth.currentUser;
    
    if (user == null) {
      throw Exception('No user is currently signed in');
    }
    
    // Query the verification codes for this user
    final querySnapshot = await _firestore
        .collection('emailVerifications')
        .where('userId', isEqualTo: user.uid)
        .where('code', isEqualTo: code)
        .where('status', isEqualTo: 'pending')
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt', descending: true)
        .limit(1)
        .get();
    
    if (querySnapshot.docs.isEmpty) {
      throw Exception('Invalid or expired verification code');
    }
    
    final verificationDoc = querySnapshot.docs.first;
    
    // Mark verification as completed
    await verificationDoc.reference.update({
      'status': 'verified',
      'verifiedAt': FieldValue.serverTimestamp(),
    });
    
    // Update user verification status in the users collection
    await _firestore.collection('users').doc(user.uid).update({
      'verificationLevel': 1, // 1 = Verified
      'emailVerified': true,
    });
    
    // Trigger a Firebase function to update auth claims
    await _firestore.collection('claimUpdates').add({
      'userId': user.uid,
      'verificationLevel': 1,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    return;
  }
} 