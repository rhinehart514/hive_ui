import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/navigation/routes.dart';
import 'package:hive_ui/core/navigation/transitions.dart';

/// Global navigator key used for navigating without context
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Provider for the root navigator key
final rootNavigatorKeyProvider = Provider<GlobalKey<NavigatorState>>(
  (ref) => _rootNavigatorKey,
);

/// Provider for the async navigation service
final asyncNavigationServiceProvider = Provider<AsyncNavigationService>(
  (ref) => AsyncNavigationService(ref),
);

/// Service for performing navigation operations safely across async gaps,
/// without requiring a BuildContext
class AsyncNavigationService {
  /// The reference to the provider container
  final ProviderRef _ref;
  
  /// Router instance cached for performance
  GoRouter? _cachedRouter;

  /// Constructor
  AsyncNavigationService(this._ref);

  /// Get the router instance
  GoRouter get _router {
    // Cache the router for performance
    _cachedRouter ??= _ref.read(routerProvider);
    return _cachedRouter!;
  }

  /// Navigate to a route with a GO operation (clears navigation stack)
  /// Safe to use across async gaps
  void go(String location, {Object? extra}) {
    _applyTransition(NavigationFeedbackType.pageTransition);
    _router.go(location, extra: extra);
  }

  /// Navigate to a route with a PUSH operation (adds to navigation stack)
  /// Safe to use across async gaps
  void push(String location, {Object? extra}) {
    _applyTransition(NavigationFeedbackType.modalOpen);
    _router.push(location, extra: extra);
  }
  
  /// Replace the current route with a new one
  /// Safe to use across async gaps
  void replace(String location, {Object? extra}) {
    _applyTransition(NavigationFeedbackType.pageTransition);
    _router.replace(location, extra: extra);
  }

  /// Pop the current route if possible
  /// Safe to use across async gaps
  void pop<T extends Object?>([T? result]) {
    if (_router.canPop()) {
      _applyTransition(NavigationFeedbackType.modalDismiss);
      _router.pop(result);
    }
  }

  /// Apply navigation transition feedback with the appropriate feedback type
  void _applyTransition(NavigationFeedbackType type) {
    NavigationTransitions.applyNavigationFeedback(type: type);
  }

  /// Navigate to home screen (Feed)
  /// Safe to use across async gaps
  void goToHome() {
    go(AppRoutes.home);
  }

  /// Navigate to spaces screen
  /// Safe to use across async gaps
  void goToSpaces() {
    go(AppRoutes.spaces);
  }

  /// Navigate to profile screen
  /// Safe to use across async gaps
  void goToProfile() {
    go(AppRoutes.profile);
  }

  /// Navigate to event details
  /// Safe to use across async gaps
  void goToEventDetails(String eventId, {Object? extra}) {
    push('/home/event/$eventId', extra: extra);
  }

  /// Navigate to space details
  /// Safe to use across async gaps
  void goToSpaceDetails(String spaceId, {Object? extra}) {
    push('/spaces/details/$spaceId', extra: extra);
  }

  /// Navigate to create event screen
  /// Safe to use across async gaps
  void goToCreateEvent({Object? extra}) {
    push(AppRoutes.createEvent, extra: extra);
  }

  /// Navigate to create space screen
  /// Safe to use across async gaps
  void goToCreateSpace() {
    push(AppRoutes.createSpace);
  }

  /// Navigate to messaging
  /// Safe to use across async gaps
  void goToMessaging() {
    go(AppRoutes.messaging);
  }

  /// Navigate to a specific chat
  /// Safe to use across async gaps
  void goToChat(String chatId, {required String chatName, String? chatAvatar, bool isGroupChat = false}) {
    push('/messaging/chat/$chatId', extra: {
      'chatName': chatName,
      'chatAvatar': chatAvatar,
      'isGroupChat': isGroupChat,
    });
  }
}

/// Extension to access the AsyncNavigationService from a BuildContext
extension AsyncNavigationExtension on BuildContext {
  /// Get the async navigation service
  AsyncNavigationService get asyncNavigation => 
      ProviderScope.containerOf(this).read(asyncNavigationServiceProvider);
}

/// Import provider from router_config.dart
/// This is a forward declaration to avoid circular imports
final routerProvider = Provider<GoRouter>((ref) {
  throw UnimplementedError('This provider should be overridden by the actual implementation');
}); 