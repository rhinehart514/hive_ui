// This file implements the FirebaseDataConnect class and related functionality
// that's required by the default connector

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart' as rtdb;
import 'package:firebase_auth/firebase_auth.dart';

/// Configuration for a connector
class ConnectorConfig {
  final String region;
  final String connectorId;
  final String projectId;

  ConnectorConfig(this.region, this.connectorId, this.projectId);
}

/// Enum representing the type of SDK calling the connector
enum CallerSDKType {
  generated,
  custom,
  admin
}

/// Main class to handle Firebase data connections
class FirebaseDataConnect {
  final ConnectorConfig connectorConfig;
  final CallerSDKType sdkType;
  final FirebaseFirestore _firestore;
  final rtdb.FirebaseDatabase _database;
  final FirebaseAuth _auth;

  FirebaseDataConnect._({
    required this.connectorConfig,
    required this.sdkType,
    FirebaseFirestore? firestore,
    rtdb.FirebaseDatabase? database,
    FirebaseAuth? auth,
  }) : 
    _firestore = firestore ?? FirebaseFirestore.instance,
    _database = database ?? rtdb.FirebaseDatabase.instance,
    _auth = auth ?? FirebaseAuth.instance;

  /// Get an instance of FirebaseDataConnect for a specific connector configuration
  static FirebaseDataConnect instanceFor({
    required ConnectorConfig connectorConfig,
    required CallerSDKType sdkType,
    FirebaseFirestore? firestore,
    rtdb.FirebaseDatabase? database,
    FirebaseAuth? auth,
  }) {
    return FirebaseDataConnect._(
      connectorConfig: connectorConfig,
      sdkType: sdkType,
      firestore: firestore,
      database: database,
      auth: auth,
    );
  }

  /// Execute a Firestore query
  Future<QuerySnapshot> executeQuery(CollectionReference collection, {
    List<Object> conditions = const [],
    int? limit,
    Object? startAfter,
    String? orderBy,
    bool descending = false,
  }) async {
    Query query = collection;
    
    // Apply conditions
    // This is a simplified implementation
    
    // Apply ordering
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }
    
    // Apply pagination
    if (limit != null) {
      query = query.limit(limit);
    }
    
    if (startAfter != null) {
      query = query.startAfter([startAfter]);
    }
    
    return query.get();
  }

  /// Get a Firestore document reference
  DocumentReference document(String path) {
    return _firestore.doc(path);
  }

  /// Get a Firestore collection reference
  CollectionReference collection(String path) {
    return _firestore.collection(path);
  }

  /// Get a reference to a Realtime Database node
  rtdb.DatabaseReference databaseReference(String path) {
    return _database.ref(path);
  }
} 