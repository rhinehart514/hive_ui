import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

/// Model representing an analytics event that can be stored in Firestore
class AnalyticsEventModel {
  final String id;
  final String eventType;
  final String userId;
  final Map<String, dynamic> properties;
  final DateTime timestamp;
  
  /// Creates a new analytics event
  AnalyticsEventModel({
    String? id,
    required this.eventType,
    required this.userId,
    required this.properties,
    DateTime? timestamp,
  }) : 
    id = id ?? const Uuid().v4(),
    timestamp = timestamp ?? DateTime.now();
  
  /// Converts the event to a Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'eventType': eventType,
      'userId': userId,
      'properties': properties,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
  
  /// Creates an event from a Firestore document
  factory AnalyticsEventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return AnalyticsEventModel(
      id: doc.id,
      eventType: data['eventType'] as String,
      userId: data['userId'] as String,
      properties: data['properties'] as Map<String, dynamic>,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
} 