import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/core/navigation/routes.dart';
import 'package:hive_ui/core/navigation/deep_link_schemes.dart';
import 'package:uni_links/uni_links.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart' as auth_features;
import 'package:hive_ui/features/auth/providers/user_preferences_provider.dart';
import 'package:hive_ui/services/user_preferences_service.dart';

/// Service for handling deep links throughout the app
class DeepLinkService {
  final Ref _ref;
  StreamSubscription? _linkSubscription;
  bool _isInitialized = false;
  bool _isHandlingDeepLink = false;

  DeepLinkService(this._ref);

  /// Initialize the deep link service and start listening for links
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Handle links that opened the app
    try {
      final initialLink = await getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } on PlatformException catch (e) {
      debugPrint('DeepLinkService: Platform exception getting initial link: $e');
    } on MissingPluginException catch (e) {
      debugPrint('DeepLinkService: Missing plugin for uni_links (normal during hot reload): $e');
      // Don't prevent app from continuing if plugin is missing
      _isInitialized = true;
      return;
    } catch (e) {
      debugPrint('DeepLinkService: Unexpected error getting initial link: $e');
    }

    // Handle links opened while the app is running
    try {
      _linkSubscription = linkStream.listen((String? link) {
        if (link != null) {
          _handleDeepLink(link);
        }
      }, onError: (error) {
        debugPrint('DeepLinkService: Error processing link: $error');
      });
    } on MissingPluginException catch (e) {
      debugPrint('DeepLinkService: Missing plugin for link stream (normal during hot reload): $e');
      // Don't prevent app from continuing if plugin is missing
    } catch (e) {
      debugPrint('DeepLinkService: Error setting up link stream: $e');
    }

    _isInitialized = true;
  }

  /// Process any deep link that comes into the app
  Future<void> _handleDeepLink(String link) async {
    // Prevent re-entrant deep link handling
    if (_isHandlingDeepLink) {
      debugPrint('DeepLinkService: Already handling a deep link, ignoring this one');
      return;
    }
    
    _isHandlingDeepLink = true;
    debugPrint('DeepLinkService: Processing link: $link');
    
    try {
      // Process the URI
      final uri = Uri.parse(link);
      
      // Check the scheme
      if (uri.scheme != kCustomScheme && uri.host != 'hiveapp.com') {
        debugPrint('DeepLinkService: Invalid scheme or host: ${uri.scheme}');
        _isHandlingDeepLink = false;
        return;
      }

      // Check authentication state first
      final isAuthenticated = await _checkAuthenticationState();
      
      if (!isAuthenticated) {
        debugPrint('DeepLinkService: User not authenticated, saving deep link for after login');
        _saveDeepLinkForLaterProcessing(link);
        _navigateToAuthIfNeeded();
        _isHandlingDeepLink = false;
        return;
      }
      
      // Check if terms are accepted and onboarding is complete
      final prefsState = _ref.read(userPreferencesProvider);
      final hasAcceptedTerms = prefsState.hasAcceptedTerms;
      final onboardingComplete = UserPreferencesService.hasCompletedOnboarding();
      
      if (!hasAcceptedTerms || !onboardingComplete) {
        debugPrint('DeepLinkService: User setup not complete, saving deep link for later processing');
        _saveDeepLinkForLaterProcessing(link);
        _isHandlingDeepLink = false;
        return;
      }

      // Now process the link based on its path
      _processAuthenticatedDeepLink(uri);
    } catch (e) {
      debugPrint('DeepLinkService: Error processing deep link: $e');
    } finally {
      _isHandlingDeepLink = false;
    }
  }

  /// Check if the user is authenticated
  Future<bool> _checkAuthenticationState() async {
    try {
      final authState = _ref.read(auth_features.authStateProvider);
      
      // Handle loading and error states
      if (authState is AsyncLoading) {
        // Wait for auth state to load
        await Future.delayed(const Duration(milliseconds: 500));
        return _checkAuthenticationState(); // Retry
      } else if (authState is AsyncError) {
        debugPrint('DeepLinkService: Auth state error: ${authState.error}');
        return false;
      }
      
      final user = FirebaseAuth.instance.currentUser;
      return user != null;
    } catch (e) {
      debugPrint('DeepLinkService: Error checking auth state: $e');
      return false;
    }
  }

  /// Navigate to authentication screen if needed
  void _navigateToAuthIfNeeded() {
    try {
      final navKey = _ref.read(navigatorKeyProvider);
      final context = navKey.currentContext;
      
      if (context != null) {
        final router = GoRouter.of(context);
        router.go(AppRoutes.landing);
      }
    } catch (e) {
      debugPrint('DeepLinkService: Error navigating to auth: $e');
    }
  }

  /// Save deep link for processing after authentication/onboarding
  void _saveDeepLinkForLaterProcessing(String link) {
    // Store link in shared preferences or memory for later processing
    _ref.read(pendingDeepLinkProvider.notifier).state = link;
  }

  /// Process a deep link when the user is authenticated
  void _processAuthenticatedDeepLink(Uri uri) {
    // Process based on path
    // Events: hive://events/{id} or https://hiveapp.com/events/{id}
    if (_isEventLink(uri)) {
      _handleEventLink(uri);
    }
    // Spaces: hive://spaces/{type}/spaces/{id} or https://hiveapp.com/spaces/{type}/spaces/{id}
    else if (_isSpaceLink(uri)) {
      _handleSpaceLink(uri);
    }
    // Profiles: hive://profiles/{id} or https://hiveapp.com/profiles/{id}
    else if (_isProfileLink(uri)) {
      _handleProfileLink(uri);
    }
    // Messages: hive://messages/chat/{id} or https://hiveapp.com/messages/chat/{id}
    else if (_isChatLink(uri)) {
      _handleChatLink(uri);
    }
    // Group Messages: hive://messages/group/{id} or https://hiveapp.com/messages/group/{id}
    else if (_isGroupChatLink(uri)) {
      _handleGroupChatLink(uri);
    }
    // Posts: hive://posts/{id} or https://hiveapp.com/posts/{id}
    else if (_isPostLink(uri)) {
      _handlePostLink(uri);
    }
    // Search: hive://search?q={query} or https://hiveapp.com/search?q={query}
    else if (_isSearchLink(uri)) {
      _handleSearchLink(uri);
    }
    // Organizations: hive://organizations/{id} or https://hiveapp.com/organizations/{id}
    else if (_isOrganizationLink(uri)) {
      _handleOrganizationLink(uri);
    }
    // Event Check-in: hive://events/{id}/check-in/{code} or https://hiveapp.com/events/{id}/check-in/{code}
    else if (_isEventCheckInLink(uri)) {
      _handleEventCheckInLink(uri);
    }
    else {
      debugPrint('DeepLinkService: Unknown link format: ${uri.toString()}');
      _handleUnknownDeepLink(uri);
    }
  }

  /// Handle an unknown deep link format
  void _handleUnknownDeepLink(Uri uri) {
    try {
      final context = _ref.read(navigatorKeyProvider).currentContext;
      if (context == null) return;
      
      // Navigate to the 404 screen with deep link error flag
      final router = GoRouter.of(context);
      router.goNamed(
        'not_found', 
        queryParameters: {
          'path': uri.toString(),
          'isDeepLink': 'true',
        },
      );
      
      // Log the event for analytics
      debugPrint('DeepLinkService: Redirected invalid link to 404 page: ${uri.toString()}');
    } catch (e) {
      debugPrint('DeepLinkService: Error handling unknown deep link: $e');
    }
  }

  /// Check if the URI is an event link
  bool _isEventLink(Uri uri) {
    final pathSegments = uri.pathSegments;
    return pathSegments.isNotEmpty && pathSegments[0] == 'events' && 
           (pathSegments.length < 3 || pathSegments[1] != 'check-in');
  }

  /// Handle navigation to an event
  void _handleEventLink(Uri uri) {
    final pathSegments = uri.pathSegments;
    
    if (pathSegments.length < 2) {
      debugPrint('DeepLinkService: Invalid event link format');
      _handleUnknownDeepLink(uri);
      return;
    }
    
    final eventId = pathSegments[1];
    debugPrint('DeepLinkService: Navigating to event: $eventId');
    
    // Get the router context
    final context = _ref.read(navigatorKeyProvider).currentContext;
    if (context == null) {
      debugPrint('DeepLinkService: No context available for navigation');
      return;
    }
    
    final router = GoRouter.of(context);
    
    // Navigate to the event
    // Since we don't have the event object here, we'll need to fetch it in the route handler
    router.pushNamed('event_detail', pathParameters: {'eventId': eventId});
  }

  /// Check if the URI is a space link
  bool _isSpaceLink(Uri uri) {
    final pathSegments = uri.pathSegments;
    return pathSegments.isNotEmpty && 
           pathSegments[0] == 'spaces' && 
           pathSegments.length >= 3 && 
           pathSegments[2] == 'spaces';
  }

  /// Handle navigation to a space
  void _handleSpaceLink(Uri uri) {
    final pathSegments = uri.pathSegments;
    
    if (pathSegments.length < 4) {
      debugPrint('DeepLinkService: Invalid space link format');
      _handleUnknownDeepLink(uri);
      return;
    }
    
    final spaceType = pathSegments[1];
    final spaceId = pathSegments[3];
    
    debugPrint('DeepLinkService: Navigating to space: $spaceType/$spaceId');
    
    // Get the router context
    final context = _ref.read(navigatorKeyProvider).currentContext;
    if (context == null) {
      debugPrint('DeepLinkService: No context available for navigation');
      return;
    }
    
    final router = GoRouter.of(context);
    
    // Navigate to the space
    router.push(AppRoutes.getSpaceDetailPath(spaceType, spaceId));
  }

  /// Check if the URI is a profile link
  bool _isProfileLink(Uri uri) {
    final pathSegments = uri.pathSegments;
    return pathSegments.isNotEmpty && pathSegments[0] == 'profiles';
  }

  /// Handle navigation to a profile
  void _handleProfileLink(Uri uri) {
    final pathSegments = uri.pathSegments;
    
    if (pathSegments.length < 2) {
      debugPrint('DeepLinkService: Invalid profile link format');
      _handleUnknownDeepLink(uri);
      return;
    }
    
    final profileId = pathSegments[1];
    debugPrint('DeepLinkService: Navigating to profile: $profileId');
    
    // Get the router context
    final context = _ref.read(navigatorKeyProvider).currentContext;
    if (context == null) {
      debugPrint('DeepLinkService: No context available for navigation');
      return;
    }
    
    final router = GoRouter.of(context);
    
    // Navigate to the profile
    router.push('${AppRoutes.profile}/$profileId');
  }
  
  /// Check if the URI is a chat link
  bool _isChatLink(Uri uri) {
    final pathSegments = uri.pathSegments;
    return pathSegments.length >= 2 && 
           pathSegments[0] == 'messages' && 
           pathSegments[1] == 'chat';
  }
  
  /// Handle navigation to a chat
  void _handleChatLink(Uri uri) {
    final pathSegments = uri.pathSegments;
    
    if (pathSegments.length < 3) {
      debugPrint('DeepLinkService: Invalid chat link format');
      _handleUnknownDeepLink(uri);
      return;
    }
    
    final chatId = pathSegments[2];
    debugPrint('DeepLinkService: Navigating to chat: $chatId');
    
    // Get the router context
    final context = _ref.read(navigatorKeyProvider).currentContext;
    if (context == null) {
      debugPrint('DeepLinkService: No context available for navigation');
      return;
    }
    
    final router = GoRouter.of(context);
    
    // Navigate to the chat
    router.push('/messaging/chat/$chatId');
  }
  
  /// Check if the URI is a group chat link
  bool _isGroupChatLink(Uri uri) {
    final pathSegments = uri.pathSegments;
    return pathSegments.length >= 2 && 
           pathSegments[0] == 'messages' && 
           pathSegments[1] == 'group';
  }
  
  /// Handle navigation to a group chat
  void _handleGroupChatLink(Uri uri) {
    final pathSegments = uri.pathSegments;
    
    if (pathSegments.length < 3) {
      debugPrint('DeepLinkService: Invalid group chat link format');
      _handleUnknownDeepLink(uri);
      return;
    }
    
    final groupId = pathSegments[2];
    debugPrint('DeepLinkService: Navigating to group chat: $groupId');
    
    // Get the router context
    final context = _ref.read(navigatorKeyProvider).currentContext;
    if (context == null) {
      debugPrint('DeepLinkService: No context available for navigation');
      return;
    }
    
    final router = GoRouter.of(context);
    
    // Navigate to the group chat
    router.push('/messaging/chat/$groupId', extra: {'isGroupChat': true});
  }
  
  /// Check if the URI is a post link
  bool _isPostLink(Uri uri) {
    final pathSegments = uri.pathSegments;
    return pathSegments.isNotEmpty && pathSegments[0] == 'posts';
  }
  
  /// Handle navigation to a post
  void _handlePostLink(Uri uri) {
    final pathSegments = uri.pathSegments;
    
    if (pathSegments.length < 2) {
      debugPrint('DeepLinkService: Invalid post link format');
      _handleUnknownDeepLink(uri);
      return;
    }
    
    final postId = pathSegments[1];
    debugPrint('DeepLinkService: Navigating to post: $postId');
    
    // Get the router context
    final context = _ref.read(navigatorKeyProvider).currentContext;
    if (context == null) {
      debugPrint('DeepLinkService: No context available for navigation');
      return;
    }
    
    final router = GoRouter.of(context);
    
    // Navigate to the post
    router.push('/posts/$postId');
  }
  
  /// Check if the URI is a search link
  bool _isSearchLink(Uri uri) {
    final pathSegments = uri.pathSegments;
    return pathSegments.isNotEmpty && pathSegments[0] == 'search';
  }
  
  /// Handle navigation to search results
  void _handleSearchLink(Uri uri) {
    final queryParams = uri.queryParameters;
    final searchQuery = queryParams['q'];
    
    if (searchQuery == null || searchQuery.isEmpty) {
      debugPrint('DeepLinkService: Invalid search link - missing query');
      _handleUnknownDeepLink(uri);
      return;
    }
    
    debugPrint('DeepLinkService: Navigating to search results for: $searchQuery');
    
    // Get the router context
    final context = _ref.read(navigatorKeyProvider).currentContext;
    if (context == null) {
      debugPrint('DeepLinkService: No context available for navigation');
      return;
    }
    
    final router = GoRouter.of(context);
    
    // Navigate to search results with query parameters
    router.push('/search', extra: {'query': searchQuery, 'filters': queryParams});
  }
  
  /// Check if the URI is an organization link
  bool _isOrganizationLink(Uri uri) {
    final pathSegments = uri.pathSegments;
    return pathSegments.isNotEmpty && pathSegments[0] == 'organizations';
  }
  
  /// Handle navigation to an organization
  void _handleOrganizationLink(Uri uri) {
    final pathSegments = uri.pathSegments;
    
    if (pathSegments.length < 2) {
      debugPrint('DeepLinkService: Invalid organization link format');
      _handleUnknownDeepLink(uri);
      return;
    }
    
    final organizationId = pathSegments[1];
    debugPrint('DeepLinkService: Navigating to organization: $organizationId');
    
    // Get the router context
    final context = _ref.read(navigatorKeyProvider).currentContext;
    if (context == null) {
      debugPrint('DeepLinkService: No context available for navigation');
      return;
    }
    
    final router = GoRouter.of(context);
    
    // Navigate to the organization
    router.push(AppRoutes.getOrganizationProfilePath(organizationId));
  }
  
  /// Check if the URI is an event check-in link
  bool _isEventCheckInLink(Uri uri) {
    final pathSegments = uri.pathSegments;
    return pathSegments.length >= 3 && 
           pathSegments[0] == 'events' && 
           pathSegments[2] == 'check-in';
  }
  
  /// Handle navigation to an event check-in
  void _handleEventCheckInLink(Uri uri) {
    final pathSegments = uri.pathSegments;
    
    if (pathSegments.length < 4) {
      debugPrint('DeepLinkService: Invalid event check-in link format');
      _handleUnknownDeepLink(uri);
      return;
    }
    
    final eventId = pathSegments[1];
    final checkInCode = pathSegments[3];
    
    debugPrint('DeepLinkService: Navigating to event check-in: $eventId with code $checkInCode');
    
    // Get the router context
    final context = _ref.read(navigatorKeyProvider).currentContext;
    if (context == null) {
      debugPrint('DeepLinkService: No context available for navigation');
      return;
    }
    
    final router = GoRouter.of(context);
    
    // Navigate to the event with check-in code
    router.pushNamed('event_detail', pathParameters: {'eventId': eventId}, extra: {'checkInCode': checkInCode});
  }
  
  /// Dispose the service
  void dispose() {
    _linkSubscription?.cancel();
  }
  
  /// Process any pending deep links
  void processPendingDeepLink() {
    final pendingLink = _ref.read(pendingDeepLinkProvider);
    if (pendingLink != null && pendingLink.isNotEmpty) {
      debugPrint('DeepLinkService: Processing pending deep link: $pendingLink');
      _ref.read(pendingDeepLinkProvider.notifier).state = null;
      _handleDeepLink(pendingLink);
    }
  }

  /// Navigate to a deep link
  static void navigateToDeepLink(String deepLink, BuildContext context) {
    try {
      // Parse the URI
      final uri = Uri.parse(deepLink);
      
      // Extract the path and query parameters
      final path = uri.path;
      final params = uri.queryParameters;
      
      // Navigate to the path with parameters
      context.go(path, extra: params);
    } catch (e) {
      debugPrint('Error navigating to deep link: $e');
      // Navigate to not found page with the deepLink as parameter
      context.go('/not-found?path=$deepLink&isDeepLink=true');
    }
  }
  
  /// Navigate to login with a return path after social authentication
  static void navigateToSocialAuth(BuildContext context, String returnToPath) {
    try {
      // Apply haptic feedback for interactive elements
      HapticFeedback.selectionClick();
      
      // Encode the return path if it contains special characters
      final encodedReturnPath = Uri.encodeComponent(returnToPath);
      
      // Navigate to login with the return path and auth source as query parameters
      context.push('${AppRoutes.signIn}?auth_source=social&return_to=$encodedReturnPath');
    } catch (e) {
      debugPrint('Error navigating to social auth: $e');
      // Fallback to regular login
      context.push(AppRoutes.signIn);
    }
  }
}

/// Provider for navigator key used by the deep link service
final navigatorKeyProvider = Provider<GlobalKey<NavigatorState>>((ref) {
  return GlobalKey<NavigatorState>();
});

/// Provider for storing pending deep links
final pendingDeepLinkProvider = StateProvider<String?>((ref) => null);

/// Provider for the deep link service
final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  final service = DeepLinkService(ref);
  return service;
}); 