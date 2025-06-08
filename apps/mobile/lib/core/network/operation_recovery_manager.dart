import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/event_bus/app_event_bus.dart';
import 'package:hive_ui/core/network/connectivity_service.dart';
import 'package:hive_ui/core/network/offline_queue_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Status of an operation in progress
enum OperationStatus {
  /// Operation is in progress
  inProgress,
  
  /// Operation was interrupted
  interrupted,
  
  /// Operation failed with an error
  failed,
  
  /// Operation completed successfully
  completed,
  
  /// Operation was canceled
  canceled,
}

/// Record of an operation in progress
class OperationRecord {
  /// Unique identifier for the operation
  final String id;
  
  /// Type of operation (e.g., 'profile_update', 'event_creation')
  final String operationType;
  
  /// Resource type related to the operation
  final String resourceType;
  
  /// ID of the resource being operated on (if applicable)
  final String? resourceId;
  
  /// User-friendly description of the operation
  final String description;
  
  /// Current status of the operation
  final OperationStatus status;
  
  /// Timestamp when the operation started
  final DateTime startedAt;
  
  /// Timestamp when the operation was last updated
  final DateTime updatedAt;
  
  /// Error message if the operation failed
  final String? errorMessage;
  
  /// Number of retry attempts
  final int retryCount;
  
  /// Maximum number of retry attempts
  final int maxRetries;
  
  /// Associated offline action ID (if applicable)
  final String? offlineActionId;
  
  /// Additional data for the operation
  final Map<String, dynamic> metadata;
  
  /// Constructor
  OperationRecord({
    required this.id,
    required this.operationType,
    required this.resourceType,
    this.resourceId,
    required this.description,
    required this.status,
    required this.startedAt,
    required this.updatedAt,
    this.errorMessage,
    this.retryCount = 0,
    this.maxRetries = 3,
    this.offlineActionId,
    this.metadata = const {},
  });
  
  /// Create a copy of this record with updated properties
  OperationRecord copyWith({
    String? id,
    String? operationType,
    String? resourceType,
    String? resourceId,
    String? description,
    OperationStatus? status,
    DateTime? startedAt,
    DateTime? updatedAt,
    String? errorMessage,
    int? retryCount,
    int? maxRetries,
    String? offlineActionId,
    Map<String, dynamic>? metadata,
  }) {
    return OperationRecord(
      id: id ?? this.id,
      operationType: operationType ?? this.operationType,
      resourceType: resourceType ?? this.resourceType,
      resourceId: resourceId ?? this.resourceId,
      description: description ?? this.description,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      updatedAt: updatedAt ?? DateTime.now(),
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
      offlineActionId: offlineActionId ?? this.offlineActionId,
      metadata: metadata ?? Map<String, dynamic>.from(this.metadata),
    );
  }
  
  /// Mark the operation as interrupted
  OperationRecord markInterrupted([String? error]) {
    return copyWith(
      status: OperationStatus.interrupted,
      errorMessage: error,
    );
  }
  
  /// Mark the operation as failed
  OperationRecord markFailed(String error) {
    return copyWith(
      status: OperationStatus.failed,
      errorMessage: error,
      retryCount: retryCount + 1,
    );
  }
  
  /// Mark the operation as completed
  OperationRecord markCompleted() {
    return copyWith(
      status: OperationStatus.completed,
    );
  }
  
  /// Mark the operation as canceled
  OperationRecord markCanceled() {
    return copyWith(
      status: OperationStatus.canceled,
    );
  }
  
  /// Check if the operation can be retried
  bool get canRetry => 
      (status == OperationStatus.interrupted || status == OperationStatus.failed) 
      && retryCount < maxRetries;
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operationType': operationType,
      'resourceType': resourceType,
      'resourceId': resourceId,
      'description': description,
      'status': status.toString().split('.').last,
      'startedAt': startedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'errorMessage': errorMessage,
      'retryCount': retryCount,
      'maxRetries': maxRetries,
      'offlineActionId': offlineActionId,
      'metadata': metadata,
    };
  }
  
  /// Create from JSON
  factory OperationRecord.fromJson(Map<String, dynamic> json) {
    return OperationRecord(
      id: json['id'],
      operationType: json['operationType'],
      resourceType: json['resourceType'],
      resourceId: json['resourceId'],
      description: json['description'],
      status: _parseStatus(json['status']),
      startedAt: DateTime.parse(json['startedAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      errorMessage: json['errorMessage'],
      retryCount: json['retryCount'],
      maxRetries: json['maxRetries'],
      offlineActionId: json['offlineActionId'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
  
  /// Parse operation status from string
  static OperationStatus _parseStatus(String status) {
    switch (status) {
      case 'inProgress':
        return OperationStatus.inProgress;
      case 'interrupted':
        return OperationStatus.interrupted;
      case 'failed':
        return OperationStatus.failed;
      case 'completed':
        return OperationStatus.completed;
      case 'canceled':
        return OperationStatus.canceled;
      default:
        return OperationStatus.failed;
    }
  }
}

/// Signature for a function that retries an operation
typedef OperationRetryHandler = Future<bool> Function(OperationRecord record);

/// A manager for tracking and recovering operations that might be interrupted
class OperationRecoveryManager {
  final _records = <String, OperationRecord>{};
  final _retryHandlers = <String, OperationRetryHandler>{};
  final ConnectivityService _connectivityService;
  final OfflineQueueManager _offlineQueueManager;
  final AppEventBus _eventBus;
  final _recordStreamController = StreamController<List<OperationRecord>>.broadcast();
  static const _storageKey = 'operation_records';
  bool _isRecovering = false;
  
  /// Stream of all operation records
  Stream<List<OperationRecord>> get recordsStream => _recordStreamController.stream;
  
  /// Get all operation records
  List<OperationRecord> get records => _records.values.toList();
  
  /// Get all interrupted operations
  List<OperationRecord> get interruptedOperations => 
      _records.values.where((r) => 
          r.status == OperationStatus.interrupted || 
          (r.status == OperationStatus.failed && r.canRetry)).toList();
  
  /// Constructor
  OperationRecoveryManager({
    required ConnectivityService connectivityService,
    required OfflineQueueManager offlineQueueManager,
    required AppEventBus eventBus,
  }) : 
    _connectivityService = connectivityService,
    _offlineQueueManager = offlineQueueManager,
    _eventBus = eventBus {
    _init();
  }
  
  /// Initialize the manager
  Future<void> _init() async {
    await _loadRecords();
    
    // Set up connectivity listener for automatic recovery
    _connectivityService.statusStream.listen((status) {
      if (_connectivityService.hasConnectivity && !_isRecovering && interruptedOperations.isNotEmpty) {
        _recoverInterruptedOperations();
      }
    });
    
    // Check for interrupted operations on startup
    if (interruptedOperations.isNotEmpty) {
      debugPrint('🔄 Recovery: Found ${interruptedOperations.length} interrupted operations');
      
      // Try to recover operations if we have connectivity
      if (_connectivityService.hasConnectivity) {
        _recoverInterruptedOperations();
      }
    }
  }
  
  /// Track a new operation
  Future<OperationRecord> trackOperation({
    required String operationType,
    required String resourceType,
    String? resourceId,
    required String description,
    String? offlineActionId,
    Map<String, dynamic> metadata = const {},
  }) async {
    final record = OperationRecord(
      id: '${operationType}_${resourceType}_${resourceId ?? DateTime.now().millisecondsSinceEpoch}',
      operationType: operationType,
      resourceType: resourceType,
      resourceId: resourceId,
      description: description,
      status: OperationStatus.inProgress,
      startedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      offlineActionId: offlineActionId,
      metadata: metadata,
    );
    
    _records[record.id] = record;
    _notifyListeners();
    await _saveRecords();
    
    debugPrint('🔄 Recovery: Started tracking operation ${record.id}');
    return record;
  }
  
  /// Update an operation's status
  Future<void> updateOperation(String id, OperationStatus status, [String? errorMessage]) async {
    final record = _records[id];
    if (record == null) {
      debugPrint('🔄 Recovery: Cannot update unknown operation: $id');
      return;
    }
    
    OperationRecord updatedRecord;
    
    switch (status) {
      case OperationStatus.completed:
        updatedRecord = record.markCompleted();
        debugPrint('🔄 Recovery: Operation completed: $id');
        break;
      case OperationStatus.failed:
        updatedRecord = record.markFailed(errorMessage ?? 'Unknown error');
        debugPrint('🔄 Recovery: Operation failed: $id - $errorMessage');
        break;
      case OperationStatus.interrupted:
        updatedRecord = record.markInterrupted(errorMessage);
        debugPrint('🔄 Recovery: Operation interrupted: $id - $errorMessage');
        break;
      case OperationStatus.canceled:
        updatedRecord = record.markCanceled();
        debugPrint('🔄 Recovery: Operation canceled: $id');
        break;
      default:
        updatedRecord = record.copyWith(
          status: status,
          errorMessage: errorMessage,
        );
        break;
    }
    
    _records[id] = updatedRecord;
    _notifyListeners();
    await _saveRecords();
  }
  
  /// Register a retry handler for an operation type
  void registerRetryHandler(String operationType, OperationRetryHandler handler) {
    _retryHandlers[operationType] = handler;
    debugPrint('🔄 Recovery: Registered retry handler for $operationType');
  }
  
  /// Recover interrupted operations
  Future<void> _recoverInterruptedOperations() async {
    if (_isRecovering || interruptedOperations.isEmpty) {
      return;
    }
    
    _isRecovering = true;
    debugPrint('🔄 Recovery: Starting recovery of ${interruptedOperations.length} operations');
    
    for (final record in interruptedOperations) {
      if (!_connectivityService.hasConnectivity) {
        debugPrint('🔄 Recovery: Lost connectivity during recovery, stopping');
        break;
      }
      
      await _recoverOperation(record);
    }
    
    _isRecovering = false;
    debugPrint('🔄 Recovery: Recovery process completed');
  }
  
  /// Recover a specific operation
  Future<bool> _recoverOperation(OperationRecord record) async {
    debugPrint('🔄 Recovery: Attempting to recover operation ${record.id}');
    
    // If the operation has an associated offline action, check if it's still pending
    if (record.offlineActionId != null) {
      final pendingActions = _offlineQueueManager.pendingActions
          .where((a) => a.id == record.offlineActionId)
          .toList();
          
      if (pendingActions.isEmpty) {
        // Action is no longer pending, it might have been processed already
        _records[record.id] = record.markCompleted();
        _notifyListeners();
        await _saveRecords();
        
        debugPrint('🔄 Recovery: Associated offline action was already processed');
        return true;
      }
    }
    
    // Look for a retry handler for this operation type
    final handler = _retryHandlers[record.operationType];
    if (handler == null) {
      debugPrint('🔄 Recovery: No retry handler found for ${record.operationType}');
      return false;
    }
    
    try {
      // Apply exponential backoff for retries
      final backoffDelay = _calculateBackoff(record.retryCount);
      if (backoffDelay > Duration.zero) {
        debugPrint('🔄 Recovery: Applying backoff delay of ${backoffDelay.inMilliseconds}ms before retry');
        await Future.delayed(backoffDelay);
      }
      
      // Apply recovery strategy based on error type
      final recoveryStrategy = _determineRecoveryStrategy(record);
      debugPrint('🔄 Recovery: Using ${recoveryStrategy.name} strategy for operation ${record.id}');
      
      // Update metadata with recovery info
      final updatedMetadata = Map<String, dynamic>.from(record.metadata);
      updatedMetadata['recoveryStrategy'] = recoveryStrategy.name;
      updatedMetadata['lastRetryAttempt'] = DateTime.now().toIso8601String();
      
      // Update the record with retry information before executing
      _records[record.id] = record.copyWith(
        metadata: updatedMetadata,
        updatedAt: DateTime.now(),
      );
      _notifyListeners();
      await _saveRecords();
      
      // Execute the retry handler
      final success = await handler(record);
      
      if (success) {
        _records[record.id] = record.markCompleted();
        debugPrint('🔄 Recovery: Successfully recovered operation ${record.id}');
      } else {
        _records[record.id] = record.markFailed('Retry handler returned false');
        debugPrint('🔄 Recovery: Failed to recover operation ${record.id}');
      }
      
      _notifyListeners();
      await _saveRecords();
      
      return success;
    } catch (e) {
      // Categorize and log the error
      final errorType = _categorizeError(e);
      debugPrint('🔄 Recovery: Error type: ${errorType.name} while recovering operation ${record.id}: $e');
      
      // Update metadata with error information
      final updatedMetadata = Map<String, dynamic>.from(record.metadata);
      updatedMetadata['lastErrorType'] = errorType.name;
      updatedMetadata['lastErrorTimestamp'] = DateTime.now().toIso8601String();
      
      // For certain error types, we might mark as permanently failed
      if (errorType == RecoveryErrorType.permanent || 
          record.retryCount >= record.maxRetries) {
        _records[record.id] = record.copyWith(
          status: OperationStatus.failed,
          errorMessage: 'Permanent error: $e',
          metadata: updatedMetadata,
          updatedAt: DateTime.now(),
        );
        debugPrint('🔄 Recovery: Marked operation ${record.id} as permanently failed');
      } else {
        _records[record.id] = record.markFailed(e.toString());
      }
      
      _notifyListeners();
      await _saveRecords();
      
      debugPrint('🔄 Recovery: Error recovering operation ${record.id}: $e');
      return false;
    }
  }
  
  /// Calculate backoff delay based on retry count
  Duration _calculateBackoff(int retryCount) {
    if (retryCount <= 0) return Duration.zero;
    
    // Exponential backoff: 2^retryCount * 500ms, capped at 30 seconds
    // 1st retry: 1 second
    // 2nd retry: 2 seconds
    // 3rd retry: 4 seconds
    // 4th retry: 8 seconds
    // 5th retry: 16 seconds
    // 6th+ retry: 30 seconds
    final backoffMs = min(
      pow(2, retryCount) * 500, 
      30 * 1000
    ).toInt();
    
    // Add some jitter to prevent thundering herd
    final jitter = Random().nextInt(backoffMs ~/ 4);
    return Duration(milliseconds: backoffMs + jitter);
  }
  
  /// Determine the recovery strategy based on operation metadata and error
  RecoveryStrategy _determineRecoveryStrategy(OperationRecord record) {
    // Check if we have a previous error type
    final lastErrorType = record.metadata['lastErrorType'] as String?;
    
    // Network errors should use incremental retry
    if (lastErrorType == RecoveryErrorType.network.name) {
      return RecoveryStrategy.incrementalRetry;
    }
    
    // For user data operations, prefer conflict resolution
    if (record.resourceType.contains('profile') || 
        record.resourceType.contains('user')) {
      return RecoveryStrategy.conflictResolution;
    }
    
    // For create operations, prefer idempotent retry
    if (record.operationType == 'create') {
      return RecoveryStrategy.idempotentRetry;
    }
    
    // Default strategy
    return RecoveryStrategy.standardRetry;
  }
  
  /// Categorize an error to determine how to handle it
  RecoveryErrorType _categorizeError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Network errors
    if (errorString.contains('network') || 
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('socket')) {
      return RecoveryErrorType.network;
    }
    
    // Authentication errors
    if (errorString.contains('auth') || 
        errorString.contains('permission') ||
        errorString.contains('unauthorized') ||
        errorString.contains('forbidden')) {
      return RecoveryErrorType.auth;
    }
    
    // Resource errors
    if (errorString.contains('not found') || 
        errorString.contains('deleted') ||
        errorString.contains('already exists')) {
      return RecoveryErrorType.resource;
    }
    
    // Validation errors - these are usually permanent
    if (errorString.contains('valid') || 
        errorString.contains('schema') ||
        errorString.contains('constraint')) {
      return RecoveryErrorType.permanent;
    }
    
    // Default to transient
    return RecoveryErrorType.transient;
  }
  
  /// Manually retry an operation
  Future<bool> retryOperation(String id) async {
    final record = _records[id];
    if (record == null || !record.canRetry) {
      debugPrint('🔄 Recovery: Cannot retry operation $id: not found or not retryable');
      return false;
    }
    
    if (!_connectivityService.hasConnectivity) {
      debugPrint('🔄 Recovery: Cannot retry operation $id: no connectivity');
      return false;
    }
    
    return _recoverOperation(record);
  }
  
  /// Cancel an operation
  Future<void> cancelOperation(String id) async {
    final record = _records[id];
    if (record == null) {
      return;
    }
    
    // If there's an associated offline action, cancel it too
    if (record.offlineActionId != null) {
      await _offlineQueueManager.cancelAction(record.offlineActionId!);
    }
    
    _records[id] = record.markCanceled();
    _notifyListeners();
    await _saveRecords();
    
    debugPrint('🔄 Recovery: Canceled operation $id');
  }
  
  /// Check if an operation is in progress
  bool isOperationInProgress(String operationType, String resourceType, [String? resourceId]) {
    return _records.values.any((record) => 
        record.status == OperationStatus.inProgress && 
        record.operationType == operationType &&
        record.resourceType == resourceType &&
        record.resourceId == resourceId);
  }
  
  /// Load records from storage
  Future<void> _loadRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recordsJson = prefs.getString(_storageKey);
      
      if (recordsJson != null) {
        final recordsList = jsonDecode(recordsJson) as List;
        
        _records.clear();
        for (final item in recordsList) {
          final record = OperationRecord.fromJson(item);
          _records[record.id] = record;
        }
        
        debugPrint('🔄 Recovery: Loaded ${_records.length} operation records');
        _notifyListeners();
      }
    } catch (e) {
      debugPrint('🔄 Recovery: Error loading operation records: $e');
    }
  }
  
  /// Save records to storage
  Future<void> _saveRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recordsList = _records.values.map((r) => r.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(recordsList));
    } catch (e) {
      debugPrint('🔄 Recovery: Error saving operation records: $e');
    }
  }
  
  /// Clean up completed and canceled operations older than the specified duration
  Future<void> cleanupOldRecords({Duration maxAge = const Duration(days: 7)}) async {
    final now = DateTime.now();
    final cutoff = now.subtract(maxAge);
    
    _records.removeWhere((id, record) => 
        (record.status == OperationStatus.completed || record.status == OperationStatus.canceled) && 
        record.updatedAt.isBefore(cutoff));
    
    _notifyListeners();
    await _saveRecords();
    
    debugPrint('🔄 Recovery: Cleaned up old operation records');
  }
  
  /// Notify listeners of changes
  void _notifyListeners() {
    if (!_recordStreamController.isClosed) {
      _recordStreamController.add(records);
    }
  }
  
  /// Dispose the manager
  void dispose() {
    _recordStreamController.close();
  }
}

/// Provider for the operation recovery manager
final operationRecoveryManagerProvider = Provider<OperationRecoveryManager>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  final offlineQueueManager = ref.watch(offlineQueueManagerProvider);
  final eventBus = AppEventBus();
  
  final manager = OperationRecoveryManager(
    connectivityService: connectivityService,
    offlineQueueManager: offlineQueueManager,
    eventBus: eventBus,
  );
  
  ref.onDispose(() {
    manager.dispose();
  });
  
  return manager;
});

/// Provider to watch all operation records
final operationRecordsProvider = StreamProvider<List<OperationRecord>>((ref) {
  final manager = ref.watch(operationRecoveryManagerProvider);
  return manager.recordsStream;
});

/// Provider to watch interrupted operations
final interruptedOperationsProvider = Provider<List<OperationRecord>>((ref) {
  final recordsAsync = ref.watch(operationRecordsProvider);
  return recordsAsync.when(
    data: (records) => records
        .where((r) => 
            r.status == OperationStatus.interrupted || 
            (r.status == OperationStatus.failed && r.canRetry))
        .toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Types of errors for categorization and recovery
enum RecoveryErrorType {
  /// Network-related errors
  network,
  
  /// Authentication or permission errors
  auth,
  
  /// Resource-related errors (not found, already exists)
  resource,
  
  /// Transient errors that might resolve with time
  transient,
  
  /// Permanent errors that won't be fixed by retrying
  permanent,
}

/// Strategies for recovering operations
enum RecoveryStrategy {
  /// Standard retry with no special handling
  standardRetry,
  
  /// Incremental retry with backoff
  incrementalRetry,
  
  /// Retry that handles idempotency concerns
  idempotentRetry,
  
  /// Retry with conflict resolution
  conflictResolution,
} 