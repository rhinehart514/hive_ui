import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Enum representing different types of offline actions
enum OfflineActionType {
  /// Create a new resource
  create,
  
  /// Update an existing resource
  update,
  
  /// Delete an existing resource
  delete,
  
  /// Custom action type
  custom,
}

/// Status of an offline action
enum OfflineActionStatus {
  /// Action is pending execution
  pending,
  
  /// Action is currently being executed
  executing,
  
  /// Action completed successfully
  completed,
  
  /// Action failed to execute
  failed,
  
  /// Action was canceled
  canceled,
}

/// A class representing an action that will be executed when connectivity is restored
class OfflineAction {
  /// Unique identifier for the action
  final String id;
  
  /// Type of action to be performed
  final OfflineActionType type;
  
  /// Resource type being operated on (e.g., "profile", "event", "space")
  final String resourceType;
  
  /// ID of the resource (if applicable)
  final String? resourceId;
  
  /// Timestamp when the action was created
  final DateTime createdAt;
  
  /// Priority of the action (higher numbers have higher priority)
  final int priority;
  
  /// Current status of the action
  final OfflineActionStatus status;
  
  /// Error message if the action failed
  final String? errorMessage;
  
  /// Number of retry attempts made
  final int retryCount;
  
  /// Maximum number of retry attempts
  final int maxRetries;
  
  /// JSON-serializable payload data for the action
  final Map<String, dynamic> payload;

  /// Constructor
  OfflineAction({
    String? id,
    required this.type,
    required this.resourceType,
    this.resourceId,
    DateTime? createdAt,
    this.priority = 0,
    this.status = OfflineActionStatus.pending,
    this.errorMessage,
    this.retryCount = 0,
    this.maxRetries = 3,
    required this.payload,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now();
  
  /// Create a copy of this action with updated properties
  OfflineAction copyWith({
    String? id,
    OfflineActionType? type,
    String? resourceType,
    String? resourceId,
    DateTime? createdAt,
    int? priority,
    OfflineActionStatus? status,
    String? errorMessage,
    int? retryCount,
    int? maxRetries,
    Map<String, dynamic>? payload,
  }) {
    return OfflineAction(
      id: id ?? this.id,
      type: type ?? this.type,
      resourceType: resourceType ?? this.resourceType,
      resourceId: resourceId ?? this.resourceId,
      createdAt: createdAt ?? this.createdAt,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
      payload: payload ?? Map<String, dynamic>.from(this.payload),
    );
  }
  
  /// Mark the action as executing
  OfflineAction markExecuting() {
    return copyWith(
      status: OfflineActionStatus.executing,
    );
  }
  
  /// Mark the action as completed
  OfflineAction markCompleted() {
    return copyWith(
      status: OfflineActionStatus.completed,
    );
  }
  
  /// Mark the action as failed
  OfflineAction markFailed(String error) {
    return copyWith(
      status: OfflineActionStatus.failed,
      errorMessage: error,
      retryCount: retryCount + 1,
    );
  }
  
  /// Mark the action as canceled
  OfflineAction markCanceled() {
    return copyWith(
      status: OfflineActionStatus.canceled,
    );
  }
  
  /// Check if the action can be retried
  bool get canRetry => status == OfflineActionStatus.failed && retryCount < maxRetries;
  
  /// Convert the action to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'resourceType': resourceType,
      'resourceId': resourceId,
      'createdAt': createdAt.toIso8601String(),
      'priority': priority,
      'status': status.toString().split('.').last,
      'errorMessage': errorMessage,
      'retryCount': retryCount,
      'maxRetries': maxRetries,
      'payload': payload,
    };
  }
  
  /// Create an action from a JSON map
  factory OfflineAction.fromJson(Map<String, dynamic> json) {
    return OfflineAction(
      id: json['id'],
      type: _parseActionType(json['type']),
      resourceType: json['resourceType'],
      resourceId: json['resourceId'],
      createdAt: DateTime.parse(json['createdAt']),
      priority: json['priority'],
      status: _parseActionStatus(json['status']),
      errorMessage: json['errorMessage'],
      retryCount: json['retryCount'],
      maxRetries: json['maxRetries'],
      payload: Map<String, dynamic>.from(json['payload']),
    );
  }
  
  /// Parse an action type from a string
  static OfflineActionType _parseActionType(String typeString) {
    switch (typeString) {
      case 'create':
        return OfflineActionType.create;
      case 'update':
        return OfflineActionType.update;
      case 'delete':
        return OfflineActionType.delete;
      case 'custom':
        return OfflineActionType.custom;
      default:
        debugPrint('Unknown action type: $typeString, defaulting to custom');
        return OfflineActionType.custom;
    }
  }
  
  /// Parse an action status from a string
  static OfflineActionStatus _parseActionStatus(String statusString) {
    switch (statusString) {
      case 'pending':
        return OfflineActionStatus.pending;
      case 'executing':
        return OfflineActionStatus.executing;
      case 'completed':
        return OfflineActionStatus.completed;
      case 'failed':
        return OfflineActionStatus.failed;
      case 'canceled':
        return OfflineActionStatus.canceled;
      default:
        debugPrint('Unknown action status: $statusString, defaulting to pending');
        return OfflineActionStatus.pending;
    }
  }
} 