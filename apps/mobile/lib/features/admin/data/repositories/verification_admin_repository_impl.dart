import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/features/admin/domain/entities/verification_request.dart';
import 'package:hive_ui/features/admin/domain/repositories/verification_admin_repository.dart';

class VerificationAdminRepositoryImpl implements VerificationAdminRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  
  // Collection references
  final CollectionReference _requestsCollection;
  final CollectionReference _auditLogCollection;
  
  VerificationAdminRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : 
    _firestore = firestore ?? FirebaseFirestore.instance,
    _auth = auth ?? FirebaseAuth.instance,
    _requestsCollection = (firestore ?? FirebaseFirestore.instance).collection('verification_requests'),
    _auditLogCollection = (firestore ?? FirebaseFirestore.instance).collection('verification_audit_logs');
  
  @override
  Stream<List<VerificationRequest>> getPendingRequests() {
    return _requestsCollection
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VerificationRequest.fromFirestore(doc))
            .toList());
  }
  
  @override
  Stream<List<VerificationRequest>> getAllRequests({
    VerificationRequestStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) {
    Query query = _requestsCollection.orderBy('createdAt', descending: true);
    
    if (status != null) {
      query = query.where('status', isEqualTo: status.toString().split('.').last);
    }
    
    if (startDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    
    if (endDate != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => VerificationRequest.fromFirestore(doc))
        .toList());
  }
  
  @override
  Future<VerificationRequest?> getRequestById(String requestId) async {
    try {
      final doc = await _requestsCollection.doc(requestId).get();
      if (!doc.exists) {
        return null;
      }
      return VerificationRequest.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error fetching verification request: $e');
      return null;
    }
  }
  
  @override
  Future<void> approveRequest({
    required String requestId,
    required String adminId,
    String? notes,
  }) async {
    final batch = _firestore.batch();
    final requestRef = _requestsCollection.doc(requestId);
    
    // Get the current request
    final requestDoc = await requestRef.get();
    if (!requestDoc.exists) {
      throw Exception('Verification request not found');
    }
    
    final request = VerificationRequest.fromFirestore(requestDoc);
    
    // Update the request status
    batch.update(requestRef, {
      'status': 'approved',
      'updatedAt': FieldValue.serverTimestamp(),
      'reviewedBy': adminId,
    });
    
    // Update the user's verification status
    final userRef = _firestore.collection('users').doc(request.userId);
    batch.update(userRef, {
      'verificationStatus': 'verified',
      'verificationLevel': request.role == 'Student' ? 'verified' : 'verified_plus',
      'verificationDate': FieldValue.serverTimestamp(),
    });
    
    // Log the action
    final auditRef = _auditLogCollection.doc();
    batch.set(auditRef, {
      'action': 'approve',
      'requestId': requestId,
      'adminId': adminId,
      'userId': request.userId,
      'notes': notes,
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    // Commit the batch
    await batch.commit();
  }
  
  @override
  Future<void> rejectRequest({
    required String requestId,
    required String adminId,
    required String reason,
  }) async {
    final batch = _firestore.batch();
    final requestRef = _requestsCollection.doc(requestId);
    
    // Get the current request
    final requestDoc = await requestRef.get();
    if (!requestDoc.exists) {
      throw Exception('Verification request not found');
    }
    
    final request = VerificationRequest.fromFirestore(requestDoc);
    
    // Update the request status
    batch.update(requestRef, {
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
      'reviewedBy': adminId,
      'rejectionReason': reason,
    });
    
    // Log the action
    final auditRef = _auditLogCollection.doc();
    batch.set(auditRef, {
      'action': 'reject',
      'requestId': requestId,
      'adminId': adminId,
      'userId': request.userId,
      'notes': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    // Commit the batch
    await batch.commit();
  }
  
  @override
  Future<void> flagRequestForReview({
    required String requestId,
    required String adminId,
    required String notes,
  }) async {
    final batch = _firestore.batch();
    final requestRef = _requestsCollection.doc(requestId);
    
    // Get the current request
    final requestDoc = await requestRef.get();
    if (!requestDoc.exists) {
      throw Exception('Verification request not found');
    }
    
    final request = VerificationRequest.fromFirestore(requestDoc);
    
    // Update the request to add a flag
    batch.update(requestRef, {
      'flagged': true,
      'flaggedBy': adminId,
      'flagNotes': notes,
      'flaggedAt': FieldValue.serverTimestamp(),
    });
    
    // Log the action
    final auditRef = _auditLogCollection.doc();
    batch.set(auditRef, {
      'action': 'flag',
      'requestId': requestId,
      'adminId': adminId,
      'userId': request.userId,
      'notes': notes,
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    // Commit the batch
    await batch.commit();
  }
  
  @override
  Future<List<Map<String, dynamic>>> getVerificationAuditLog({
    DateTime? startDate,
    DateTime? endDate,
    String? adminId,
    int? limit,
  }) async {
    Query query = _auditLogCollection.orderBy('timestamp', descending: true);
    
    if (startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    
    if (endDate != null) {
      query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }
    
    if (adminId != null) {
      query = query.where('adminId', isEqualTo: adminId);
    }
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }
} 