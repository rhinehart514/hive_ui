import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/event_bus/app_event_bus.dart';
import 'package:hive_ui/core/network/conflict_resolver.dart';
import 'package:hive_ui/core/network/connectivity_service.dart';
import 'package:hive_ui/core/network/offline_action.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Signature for a function that executes an offline action
typedef ActionExecutor = Future<bool> Function(OfflineAction action);

/// Signature for a function that retrieves remote data for conflict resolution
typedef RemoteDataFetcher = Future<Map<String, dynamic>?> Function(OfflineAction action);

/// Signature for a function that resolves conflicts when executing an action
typedef ConflictHandler = Future<Map<String, dynamic>> Function(
  OfflineAction action,
  Map<String, dynamic>? remoteData,
  ConflictResolver resolver,
);

/// Configuration for a resource type executor
class ExecutorConfig {
  /// The function that executes the action
  final ActionExecutor executor;
  
  /// The function that fetches remote data for conflict resolution (optional)
  final RemoteDataFetcher? remoteFetcher;
  
  /// The function that handles conflicts (optional)
  final ConflictHandler? conflictHandler;
  
  /// The strategy to use for resolving conflicts
  final ConflictStrategy conflictStrategy;
  
  /// Constructor
  ExecutorConfig({
    required this.executor,
    this.remoteFetcher,
    this.conflictHandler,
    this.conflictStrategy = ConflictStrategy.preferLocal,
  });
}

/// A manager for handling offline actions that need to be performed when connectivity is restored
class OfflineQueueManager {
  final _actions = <String, OfflineAction>{};
  final _executors = <String, ExecutorConfig>{};
  final ConnectivityService _connectivityService;
  final AppEventBus _eventBus;
  final ConflictResolver _conflictResolver;
  bool _isProcessing = false;
  Timer? _processingTimer;
  final _actionStreamController = StreamController<List<OfflineAction>>.broadcast();
  static const _storageKey = 'offline_actions';
  
  /// Stream of all actions in the queue
  Stream<List<OfflineAction>> get actionsStream => _actionStreamController.stream;
  
  /// Get all actions in the queue
  List<OfflineAction> get actions => _actions.values.toList();
  
  /// Get all pending actions in the queue
  List<OfflineAction> get pendingActions => _actions.values
      .where((action) => action.status == OfflineActionStatus.pending)
      .toList();
  
  /// Constructor
  OfflineQueueManager({
    required ConnectivityService connectivityService,
    required AppEventBus eventBus,
    required ConflictResolver conflictResolver,
  }) : 
    _connectivityService = connectivityService,
    _eventBus = eventBus,
    _conflictResolver = conflictResolver {
    _init();
  }
  
  /// Initialize the queue manager
  Future<void> _init() async {
    await _loadActions();
    
    // Listen for connectivity changes
    _connectivityService.statusStream.listen((status) {
      if (_connectivityService.hasConnectivity) {
        _startProcessingQueue();
      } else {
        _stopProcessingQueue();
      }
    });
    
    // Start queue processing if we have connectivity
    if (_connectivityService.hasConnectivity) {
      _startProcessingQueue();
    }
  }
  
  /// Add an action to the queue
  Future<void> enqueueAction(OfflineAction action) async {
    _actions[action.id] = action;
    _notifyListeners();
    await _saveActions();
    
    // Process queue immediately if online
    if (_connectivityService.hasConnectivity && !_isProcessing) {
      _startProcessingQueue();
    }
  }
  
  /// Register an executor for a specific resource type
  void registerExecutor(
    String resourceType,
    ActionExecutor executor, {
    RemoteDataFetcher? remoteFetcher,
    ConflictHandler? conflictHandler,
    ConflictStrategy conflictStrategy = ConflictStrategy.preferLocal,
  }) {
    _executors[resourceType] = ExecutorConfig(
      executor: executor,
      remoteFetcher: remoteFetcher,
      conflictHandler: conflictHandler,
      conflictStrategy: conflictStrategy,
    );
    debugPrint('⏱️ OfflineQueueManager: Registered executor for $resourceType');
  }
  
  /// Start processing the queue
  void _startProcessingQueue() {
    if (_isProcessing || pendingActions.isEmpty) {
      return;
    }
    
    _isProcessing = true;
    debugPrint('⏱️ OfflineQueueManager: Started processing queue with ${pendingActions.length} pending actions');
    
    _processQueue();
    
    // Set up periodic processing
    _processingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _processQueue();
    });
  }
  
  /// Stop processing the queue
  void _stopProcessingQueue() {
    _isProcessing = false;
    _processingTimer?.cancel();
    _processingTimer = null;
    debugPrint('⏱️ OfflineQueueManager: Stopped processing queue');
  }
  
  /// Process the pending actions in the queue
  Future<void> _processQueue() async {
    if (pendingActions.isEmpty) {
      debugPrint('⏱️ OfflineQueueManager: No pending actions to process');
      _stopProcessingQueue();
      return;
    }
    
    if (!_connectivityService.hasConnectivity) {
      debugPrint('⏱️ OfflineQueueManager: No connectivity, delaying queue processing');
      _stopProcessingQueue();
      return;
    }
    
    debugPrint('⏱️ OfflineQueueManager: Processing ${pendingActions.length} pending actions');
    
    // Sort actions by priority (higher priority first)
    final actions = pendingActions
        .where((action) => _executors.containsKey(action.resourceType))
        .toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
    
    for (final action in actions) {
      if (!_connectivityService.hasConnectivity) {
        debugPrint('⏱️ OfflineQueueManager: Lost connectivity during processing, stopping');
        _stopProcessingQueue();
        return;
      }
      
      await _executeAction(action);
    }
    
    // Clean up completed actions older than 24 hours
    _cleanupCompletedActions();
    
    if (pendingActions.isEmpty) {
      _stopProcessingQueue();
    }
  }
  
  /// Execute a specific action
  Future<void> _executeAction(OfflineAction action) async {
    if (action.status != OfflineActionStatus.pending) {
      return;
    }
    
    final executorConfig = _executors[action.resourceType];
    if (executorConfig == null) {
      debugPrint('⏱️ OfflineQueueManager: No executor found for ${action.resourceType}');
      return;
    }
    
    debugPrint('⏱️ OfflineQueueManager: Executing action ${action.id} (${action.resourceType})');
    
    // Update action to executing
    _actions[action.id] = action.markExecuting();
    _notifyListeners();
    await _saveActions();
    
    try {
      // Fetch remote data for conflict resolution if needed
      Map<String, dynamic>? remoteData;
      if (executorConfig.remoteFetcher != null) {
        remoteData = await executorConfig.remoteFetcher!(action);
      }
      
      // Handle any conflicts
      var payloadToUse = action.payload;
      if (remoteData != null && (executorConfig.conflictHandler != null || action.type == OfflineActionType.update)) {
        if (executorConfig.conflictHandler != null) {
          // Use custom conflict handler
          payloadToUse = await executorConfig.conflictHandler!(action, remoteData, _conflictResolver);
          debugPrint('⏱️ OfflineQueueManager: Used custom conflict handler for ${action.id}');
        } else {
          // Use automatic conflict resolution
          final (result, resolvedData) = await _conflictResolver.resolveConflict(
            action: action,
            remoteData: remoteData,
            strategy: executorConfig.conflictStrategy,
          );
          
          payloadToUse = resolvedData;
          
          switch (result) {
            case ConflictResolutionResult.usedLocal:
              debugPrint('⏱️ OfflineQueueManager: Used local data for action ${action.id}');
              break;
            case ConflictResolutionResult.usedRemote:
              debugPrint('⏱️ OfflineQueueManager: Used remote data for action ${action.id}');
              break;
            case ConflictResolutionResult.merged:
              debugPrint('⏱️ OfflineQueueManager: Used merged data for action ${action.id}');
              break;
            case ConflictResolutionResult.unresolved:
              // Use local data but log a warning
              debugPrint('⚠️ OfflineQueueManager: Conflict unresolved for action ${action.id}, using local data');
              break;
            case ConflictResolutionResult.noConflict:
              debugPrint('⏱️ OfflineQueueManager: No conflict detected for action ${action.id}');
              break;
          }
        }
      }
      
      // Create a new action with the resolved payload
      final resolvedAction = action.copyWith(payload: payloadToUse);
      
      // Execute the action
      final success = await executorConfig.executor(resolvedAction);
      
      if (success) {
        _actions[action.id] = action.markCompleted();
        debugPrint('⏱️ OfflineQueueManager: Action ${action.id} completed successfully');
      } else {
        _actions[action.id] = action.markFailed('Execution returned false');
        debugPrint('⏱️ OfflineQueueManager: Action ${action.id} failed');
      }
    } catch (e) {
      _actions[action.id] = action.markFailed(e.toString());
      debugPrint('⏱️ OfflineQueueManager: Action ${action.id} failed with error: $e');
    }
    
    _notifyListeners();
    await _saveActions();
  }
  
  /// Clean up completed actions older than 24 hours
  void _cleanupCompletedActions() {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(hours: 24));
    
    _actions.removeWhere((id, action) => 
        action.status == OfflineActionStatus.completed && 
        action.createdAt.isBefore(cutoff));
    
    _notifyListeners();
    _saveActions();
  }
  
  /// Load actions from persistent storage
  Future<void> _loadActions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final actionsJson = prefs.getString(_storageKey);
      
      if (actionsJson != null) {
        final actionsList = jsonDecode(actionsJson) as List;
        
        _actions.clear();
        for (final item in actionsList) {
          final action = OfflineAction.fromJson(item);
          _actions[action.id] = action;
        }
        
        debugPrint('⏱️ OfflineQueueManager: Loaded ${_actions.length} actions from storage');
        _notifyListeners();
      }
    } catch (e) {
      debugPrint('⏱️ OfflineQueueManager: Error loading actions: $e');
    }
  }
  
  /// Save actions to persistent storage
  Future<void> _saveActions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final actionsList = _actions.values.map((a) => a.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(actionsList));
    } catch (e) {
      debugPrint('⏱️ OfflineQueueManager: Error saving actions: $e');
    }
  }
  
  /// Retry a failed action
  Future<void> retryAction(String actionId) async {
    final action = _actions[actionId];
    if (action != null && action.canRetry) {
      _actions[actionId] = action.copyWith(
        status: OfflineActionStatus.pending,
      );
      
      _notifyListeners();
      await _saveActions();
      
      if (_connectivityService.hasConnectivity && !_isProcessing) {
        _startProcessingQueue();
      }
    }
  }
  
  /// Cancel an action
  Future<void> cancelAction(String actionId) async {
    final action = _actions[actionId];
    if (action != null && action.status == OfflineActionStatus.pending) {
      _actions[actionId] = action.markCanceled();
      _notifyListeners();
      await _saveActions();
    }
  }
  
  /// Clear all actions from the queue
  Future<void> clearActions() async {
    _actions.clear();
    _notifyListeners();
    await _saveActions();
    debugPrint('⏱️ OfflineQueueManager: All actions cleared');
  }
  
  /// Remove a specific action from the queue
  Future<void> removeAction(String actionId) async {
    _actions.remove(actionId);
    _notifyListeners();
    await _saveActions();
  }
  
  /// Notify listeners of changes
  void _notifyListeners() {
    if (!_actionStreamController.isClosed) {
      _actionStreamController.add(actions);
    }
  }
  
  /// Dispose the manager
  void dispose() {
    _stopProcessingQueue();
    _actionStreamController.close();
  }
}

/// Provider for the offline queue manager
final offlineQueueManagerProvider = Provider<OfflineQueueManager>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  final eventBus = AppEventBus();
  final conflictResolver = ref.watch(conflictResolverProvider);
  
  final manager = OfflineQueueManager(
    connectivityService: connectivityService,
    eventBus: eventBus,
    conflictResolver: conflictResolver,
  );
  
  ref.onDispose(() {
    manager.dispose();
  });
  
  return manager;
});

/// Provider to watch all actions in the queue
final offlineActionsProvider = StreamProvider<List<OfflineAction>>((ref) {
  final manager = ref.watch(offlineQueueManagerProvider);
  return manager.actionsStream;
});

/// Provider to watch pending actions in the queue
final pendingOfflineActionsProvider = Provider<List<OfflineAction>>((ref) {
  final actionsAsync = ref.watch(offlineActionsProvider);
  return actionsAsync.when(
    data: (actions) => actions
        .where((a) => a.status == OfflineActionStatus.pending)
        .toList(),
    loading: () => [],
    error: (_, __) => [],
  );
}); 