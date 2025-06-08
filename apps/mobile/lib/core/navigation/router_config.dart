import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/navigation/routes.dart';
import 'package:hive_ui/core/navigation/deep_link_service.dart';
import 'package:hive_ui/core/navigation/transitions.dart';
import 'package:hive_ui/core/navigation/not_found_screen.dart';
import 'package:hive_ui/core/navigation/async_navigation_service.dart';
import 'package:hive_ui/core/widgets/component_test_page.dart' show DesignTokensTestPage;
import 'package:hive_ui/shell.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/features/profile/presentation/pages/verification_admin_page.dart';
import 'package:hive_ui/features/messaging/domain/entities/message_attachment.dart';
import 'package:hive_ui/features/examples/presentation/pages/card_lifecycle_demo_page.dart';
import 'package:hive_ui/features/events/presentation/routing/event_routes.dart';

// Page imports
import 'package:hive_ui/features/auth/presentation/pages/landing_page.dart';
import 'package:hive_ui/features/auth/presentation/pages/login_page.dart';
import 'package:hive_ui/features/auth/presentation/pages/create_account.dart';
import 'package:hive_ui/pages/profile_page.dart';
import 'package:hive_ui/pages/organizations_page.dart';
import 'package:hive_ui/pages/organization_profile_page.dart';
import 'package:hive_ui/pages/hive_lab_page.dart';
// import 'package:hive_ui/pages/developer_tools_page.dart'; // Removed - file no longer exists
import 'package:hive_ui/models/club.dart';
import 'package:hive_ui/features/messaging/presentation/screens/group_members_screen.dart';
import 'package:hive_ui/features/messaging/presentation/screens/chat_list_screen.dart';
import 'package:hive_ui/features/messaging/presentation/screens/chat_screen.dart';
import 'package:hive_ui/features/messaging/presentation/screens/chat_creation_screen.dart';
import 'package:hive_ui/features/spaces/presentation/pages/spaces_page.dart';
import 'package:hive_ui/features/spaces/presentation/pages/create_space_page.dart';
import 'package:hive_ui/features/spaces/presentation/pages/create_space_splash_page.dart';
import 'package:hive_ui/features/events/presentation/pages/create_event_page.dart';
import 'package:hive_ui/screens/admin/verification_requests_screen.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/features/feed/presentation/pages/event_detail_page.dart';
import 'package:hive_ui/pages/photo_view_page.dart';
import 'package:hive_ui/features/feed/presentation/pages/feed_page.dart';
import 'package:hive_ui/features/friends/presentation/screens/suggested_friends_screen.dart';
import 'package:hive_ui/features/post/presentation/pages/create_post_page.dart';
// Test pages
import 'package:hive_ui/components/event_card/event_card_test_page.dart';
import 'package:hive_ui/features/clubs/presentation/widgets/space_detail/space_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:hive_ui/features/auth/presentation/pages/terms_acceptance_page.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart' as auth_features;
import 'dart:async'; // Import for StreamSubscription
import 'package:hive_ui/core/services/role_checker.dart'; 
import 'package:hive_ui/core/providers/role_checker_provider.dart'; 
// Import main to access appInitializationProvider
import 'package:hive_ui/features/auth/providers/user_preferences_provider.dart';
import 'package:hive_ui/features/events/presentation/pages/check_in_success_page.dart';
import 'package:hive_ui/features/auth/presentation/pages/privacy_policy_page.dart';
import 'package:hive_ui/features/messaging/presentation/screens/attachment_viewer_screen.dart';
import 'package:hive_ui/features/auth/presentation/pages/splash_gate_page.dart';
import 'package:hive_ui/features/auth/presentation/pages/registration_page.dart';
import 'package:hive_ui/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:hive_ui/features/auth/presentation/pages/verified_email_page.dart'; // Import new page
import 'package:hive_ui/features/auth/presentation/pages/verification_error_page.dart'; // Import new page
import 'package:hive_ui/features/auth/presentation/pages/password_reset_page.dart';
import 'package:hive_ui/features/auth/presentation/pages/password_reset_sent_page.dart';
import 'package:hive_ui/features/auth/presentation/pages/magic_link_sent_page.dart';
import 'package:hive_ui/features/auth/presentation/pages/verification_request_page.dart';
import 'package:hive_ui/features/auth/presentation/pages/verify_identity_page.dart'; // New
import 'package:hive_ui/features/auth/presentation/pages/access_pass_page.dart'; // New onboarding
import 'package:hive_ui/features/auth/presentation/pages/campus_dna_page.dart'; // New onboarding
import 'package:hive_ui/pages/admin/review_verification_page.dart'; // New admin
import 'package:hive_ui/core/routing/app_router.dart'; // Import for HiveRouteObserver

/// Provider for the DeepLinkService
final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  return DeepLinkService(ref);
});

/// Provider for storing pending deep links
final pendingDeepLinkProvider = StateProvider<String?>((ref) => null);

// _getInitialRoute function removed - was unused

/// Provider for tracking authentication state changes to check for pending deep links
final deepLinkAuthListenerProvider = Provider<void>((ref) {
  // Watch auth changes to trigger deep link processing
  ref.watch(auth_features.authStateProvider);
  
  // Check for and process any pending deep links
  final pendingDeepLink = ref.read(pendingDeepLinkProvider);
  if (pendingDeepLink != null) {
    // Get the deep link service
    final deepLinkService = ref.read(deepLinkServiceProvider);
    
    // Clear the pending deep link
    ref.read(pendingDeepLinkProvider.notifier).state = null;
    
    // Process the pending deep link
    deepLinkService.handleIncomingLink(pendingDeepLink);
  }
});

/// Provider for the app router
@override
final routerProvider = Provider<GoRouter>((ref) {
  // Listenable that refreshes the router when auth state changes
  final authStateListenable = GoRouterRefreshStream(
    ref.watch(auth_features.authStateProvider.stream),
  );

  // Watch auth changes to handle deep links (won't affect the result but will trigger the provider)
  ref.watch(deepLinkAuthListenerProvider);

  // Get the navigator key from our rootNavigatorKeyProvider
  final navigatorKey = ref.watch(rootNavigatorKeyProvider);

  // Get the current path notifier for listening to route changes
  final currentPathNotifier = ValueNotifier<String?>(null);
  
  // Initialize DeepLinkService when router is created
  final deepLinkService = ref.watch(deepLinkServiceProvider);
  Future.microtask(() async {
    await deepLinkService.initialize();
  });

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: authStateListenable, 
    navigatorKey: navigatorKey, // Use the root navigator key
    observers: [
      // Add an observer to update the current path
      _GoRouterObserver(currentPathNotifier),
      HiveRouteObserver(), // Add HiveRouteObserver
    ],
    // Add error builder to handle 404s with our custom screen
    errorBuilder: (context, state) {
      // Log the error
      debugPrint('404 Error: Unable to navigate to ${state.uri.path}');
      
      // Return our custom NotFoundScreen
      return NotFoundScreen(path: state.uri.path);
    },
    // Add redirect to enforce onboarding flow
    redirect: (BuildContext context, GoRouterState state) {
      // Check if the user is authenticated
      final auth = fb_auth.FirebaseAuth.instance;
      final isAuthenticated = auth.currentUser != null;
      
      // Define paths that don't require onboarding
      final noOnboardingPaths = [
        AppRoutes.landing, 
        AppRoutes.signIn, 
        AppRoutes.register, 
        AppRoutes.createAccount,
        '/terms',
        '/privacy',
        '/not-found',
        '/onboarding',
        '/verified-email',
        '/verification-error',
        AppRoutes.requestVerification,
        AppRoutes.requestVerifiedPlus,
        AppRoutes.uiComponentsTest,
      ];
      
      // Paths for auth but not onboarding
      final authOnlyPaths = [
        '/terms',
        '/privacy',
        AppRoutes.uiComponentsTest,
      ];
      
      // Get the current path
      final path = state.uri.path;
      
      // Handle splash page (/) - redirect based on auth state
      if (path == '/') {
        if (isAuthenticated) {
          final hasCompletedOnboarding = UserPreferencesService.hasCompletedOnboarding();
          if (hasCompletedOnboarding) {
            debugPrint('Router: Splash → authenticated and onboarded → home');
            return AppRoutes.home;
          } else {
            debugPrint('Router: Splash → authenticated but needs onboarding');
            return AppRoutes.onboarding;
          }
        } else {
          debugPrint('Router: Splash → not authenticated → landing');
          return AppRoutes.landing;
        }
      }
      
      // If the user is not authenticated, redirect to login except for paths that don't require auth
      if (!isAuthenticated && !noOnboardingPaths.contains(path)) {
        debugPrint('Router: User not authenticated, redirecting to sign in from $path');
        // Allow access to test page even if not authenticated
        if (path == AppRoutes.uiComponentsTest) {
          return null; // Don't redirect from test page
        }
        return AppRoutes.signIn;
      }
      
      // If the user is authenticated, check if they need to complete onboarding
      if (isAuthenticated) {
        // Check for terms acceptance and onboarding completion
        final hasCompletedOnboarding = UserPreferencesService.hasCompletedOnboarding();
        final isOnboardingPath = path == '/onboarding';
        final isTermsPath = path == '/terms';
        final isSignInPath = path == AppRoutes.signIn || path == AppRoutes.register || path == AppRoutes.createAccount;
        
        // Redirect authenticated users away from auth screens if they have completed onboarding
        if (isSignInPath && hasCompletedOnboarding) {
          debugPrint('Router: User already authenticated and onboarded, redirecting to home');
          return AppRoutes.home;
        }
        
        // Check if the user has accepted terms
        // Note: We directly access the provider state here to avoid reactive errors
        final hasAcceptedTerms = ref.read(userPreferencesProvider).hasAcceptedTerms;
        
        // If user hasn't accepted terms and isn't on the terms page, redirect to terms
        if (!hasAcceptedTerms && !isTermsPath && !authOnlyPaths.contains(path)) {
          debugPrint('Router: User has not accepted terms, redirecting to terms');
          return '/terms';
        }
        
        // If onboarding is not completed and the user has accepted terms and
        // is not on the onboarding path OR an auth path, redirect to onboarding
        if (!hasCompletedOnboarding && !isOnboardingPath && !isSignInPath && !authOnlyPaths.contains(path)) {
          debugPrint('Router: User needs to complete onboarding, redirecting to onboarding flow');
          return AppRoutes.onboarding;
        }
        
        // If onboarding is already completed and user tries to access onboarding page,
        // redirect them to home page instead
        if (hasCompletedOnboarding && isOnboardingPath) {
          debugPrint('Router: User already completed onboarding, redirecting to home');
          return AppRoutes.home;
        }
      }
      
      return null; // No redirect
    },
    routes: [
      // Root route - splash screen
      GoRoute(
        path: '/',
        pageBuilder: _buildPageTransition(
          (context, state) => const SplashGatePage(),
          type: TransitionType.fade,
        ),
      ),
      // Landing page - separate from root
      GoRoute(
        path: AppRoutes.landing,
        pageBuilder: _buildPageTransition(
          (context, state) => const LandingPage(),
          type: TransitionType.fade,
        ),
      ),
      // Auth routes - outside the shell
      GoRoute(
        path: AppRoutes.signIn,
        pageBuilder: _buildPageTransition(
          (context, state) => const LoginPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: _buildPageTransition(
          (context, state) => const RegistrationPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.createAccount,
        pageBuilder: _buildPageTransition(
          (context, state) => const CreateAccountPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) {
          // Check if skip parameter is present to enable auto-skip option
          final skipPreferences = state.uri.queryParameters['skip'] == 'true';
          
          // Custom transition for onboarding
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: OnboardingPage(skipToDefaults: skipPreferences),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              // Combine fade and slide animations for smoother transition
              const begin = Offset(0.0, 0.05);
              const end = Offset.zero;
              final tween = Tween(begin: begin, end: end);
              final offsetAnimation = animation.drive(tween);

              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: offsetAnimation,
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
          );
        },
      ),
      GoRoute(
        path: '/terms',
         name: 'terms_acceptance',
        pageBuilder: _buildPageTransition(
          (context, state) => const TermsAcceptancePage(),
           type: TransitionType.fade,
        ),
      ),
      
      // ADDED: Email verification success page
      GoRoute(
        path: '/verified-email',
        name: 'verified_email',
        pageBuilder: _buildPageTransition(
          (context, state) => const VerifiedEmailPage(),
          type: TransitionType.fade,
        ),
      ),

      // ADDED: Email verification error page
      GoRoute(
        path: '/verification-error',
        name: 'verification_error',
        pageBuilder: _buildPageTransition(
          (context, state) => const VerificationErrorPage(),
          type: TransitionType.fade,
        ),
      ),

      // Not Found route for deep links and 404 errors
      GoRoute(
        path: '/not-found',
        name: 'not_found',
        pageBuilder: _buildPageTransition(
          (context, state) {
            final path = state.uri.queryParameters['path'];
            final isDeepLink = state.uri.queryParameters['isDeepLink'] == 'true';
            return NotFoundScreen(
              path: path,
              isDeepLinkError: isDeepLink,
            );
          },
          type: TransitionType.fade,
        ),
      ),

      // Event routes
      ...EventRoutes.getRoutes(),

      // Shell route for bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Shell(navigationShell: navigationShell);
        },
        branches: [
          // Feed branch
          StatefulShellBranch(
            routes: [
              // Home route
              GoRoute(
                path: AppRoutes.home,
                pageBuilder: _buildPageTransition(
                  (context, state) => const FeedPage(),
                ),
                routes: [
                  // Event detail route
                  GoRoute(
                    path: 'event/:eventId',
                    name: 'event_detail',
                    pageBuilder: _buildPageTransition(
                      (context, state) {
                        final String eventId = state.pathParameters['eventId']!;
                        final args = state.extra as Map<String, dynamic>?;
                        final event = args?['event'] as Event?;
                        final heroTag = args?['heroTag'] as String? ?? 'event_$eventId';
                        if (event == null) {
                           return const ErrorDisplayPage(message: 'Event data missing. Cannot display details.');
                        }
                        return EventDetailPage(
                          event: event,
                          heroTag: heroTag,
                        );
                      },
                       type: TransitionType.cupertinoPush,
                    ),
                  ),
                   // Photo view route
                  GoRoute(
                    path: 'photo',
                    name: 'photo_view',
                    pageBuilder: _buildPageTransition(
                       (context, state) {
                          final args = state.extra as Map<String, dynamic>?;
                          final imageUrl = args?['imageUrl'] as String?;
                          final heroTag = args?['heroTag'] as String?;
                          if (imageUrl == null) {
                             return const ErrorDisplayPage(message: 'Image URL missing.');
                          }
                          // Ensure both parameters are non-nullable with meaningful defaults
                          final String nonNullImageUrl = imageUrl;
                          final String nonNullHeroTag = heroTag ?? 'photo_${DateTime.now().millisecondsSinceEpoch}';
                          return PhotoViewPage(
                            imageUrl: nonNullImageUrl, 
                            heroTag: nonNullHeroTag
                          );
                       },
                       type: TransitionType.fade,
                    ),
                  ),
                   // Suggested friends route
                  GoRoute(
                     path: 'suggested_friends',
                     name: 'suggested_friends',
                    pageBuilder: _buildPageTransition(
                       (context, state) => const SuggestedFriendsScreen(),
                       type: TransitionType.cupertinoPush,
                    ),
                  ),
                  // Profile Photo Page
                  GoRoute(
                    path: 'profile_photo',
                    name: 'profile_photo',
                    pageBuilder: _buildPageTransition(
                       (context, state) {
                         final args = state.extra as Map<String, dynamic>?;
                         final imageUrl = args?['imageUrl'] as String?;
                         final heroTag = args?['heroTag'] as String?;
                         if (imageUrl == null) {
                           return const ErrorDisplayPage(message: 'Image URL missing for profile photo.');
                         }
                         // Ensure both parameters are non-nullable with meaningful defaults
                         final String nonNullImageUrl = imageUrl;
                         final String nonNullHeroTag = heroTag ?? 'profile_photo_${DateTime.now().millisecondsSinceEpoch}';
                         return PhotoViewPage(
                           imageUrl: nonNullImageUrl, 
                           heroTag: nonNullHeroTag
                         );
                       },
                       type: TransitionType.fade,
                    ),
                  ),
                   // Create Post Page
                  GoRoute(
                     path: 'create_post',
                    name: 'create_post',
                    pageBuilder: _buildPageTransition(
                      (context, state) => const CreatePostPage(),
                      type: TransitionType.cupertinoModal,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Spaces branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.spaces,
                pageBuilder: _buildPageTransition(
                  (context, state) => const SpacesPage(),
                ),
                routes: [
                  GoRoute(
                     path: 'create_splash',
                     name: 'create_space_splash',
                    pageBuilder: _buildPageTransition(
                      (context, state) => const CreateSpaceSplashPage(),
                        type: TransitionType.cupertinoModal,
                    ),
                  ),
                  GoRoute(
                     path: 'create',
                     name: 'create_space',
                    pageBuilder: _buildPageTransition(
                      (context, state) => const CreateSpacePage(),
                        type: TransitionType.cupertinoModal,
                    ),
                  ),
                   // Route for Space Detail Screen - Using AppRoutes definition
                  GoRoute(
                     path: AppRoutes.spaceDetail, // Use definition from AppRoutes: ':type/spaces/:id'
                     name: 'space_detail',
                     pageBuilder: (context, state) {
                         final spaceId = state.pathParameters['id']; // Use 'id' as defined in AppRoutes
                         final spaceType = state.pathParameters['type']; // Use 'type' as defined in AppRoutes
                         final space = state.extra as Space?; 

                         if (spaceId == null || spaceType == null) {
                            return _buildPageTransition(
                               (context, state) => const ErrorDisplayPage(message: 'Missing space ID or Type'),
                            )(context, state);
                         }

                         // Pass both spaceId and spaceType to SpaceDetailScreen
                         return _buildPageTransition(
                           (context, state) => SpaceDetailScreen(
                             spaceId: spaceId,
                             spaceType: spaceType, // Pass spaceType again
                             space: space, 
                           ),
                           type: TransitionType.cupertinoPush,
                         )(context, state);
                      },
                    routes: [
                       // Nested route for creating an event
                       GoRoute(
                         path: 'create_event',
                         name: 'create_event_for_space',
                         pageBuilder: _buildPageTransition(
                           (context, state) {
                             // Get params from the parent route's parameters
                             final spaceId = state.pathParameters['id']; 
                             final spaceType = state.pathParameters['type'];
                             final space = state.extra as Space?; 

                             if (spaceId == null || spaceType == null) {
                                return const ErrorDisplayPage(message: 'Missing space ID/Type for event creation.');
                             }
                             
                             // If space object isn't passed directly, you might need to fetch it based on spaceId/Type
                             if (space == null) {
                               // TODO: Potentially fetch space details here if needed by CreateEventPage
                               return const ErrorDisplayPage(message: 'Space data missing for event creation.');
                             }
                              return CreateEventPage(selectedSpace: space);
                           },
                           type: TransitionType.cupertinoModal,
                         ),
                       ),
                    ]
                  ),
                ],
              ),
            ],
          ),

          // Profile branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                 path: AppRoutes.profile,
                pageBuilder: _buildPageTransition(
                    (context, state) {
                      final auth = _getAuthInstance();
                      final userId = state.pathParameters['userId'] ?? auth.currentUser?.uid;
                      if (userId == null) {
                         return const ErrorDisplayPage(message: 'User not found.');
                      }
                      return ProfilePage(userId: userId);
                    }
                ),
                routes: [
                    // Allow viewing other profiles
                  GoRoute(
                    path: ':userId',
                       name: 'user_profile',
                    pageBuilder: _buildPageTransition(
                      (context, state) {
                        final userId = state.pathParameters['userId'];
                            if (userId == null) {
                              return const ErrorDisplayPage(message: 'User ID missing.');
                            }
                             return ProfilePage(userId: userId);
                      },
                      type: TransitionType.cupertinoPush,
                    ),
                       routes: [
                         // Nested route for profile photo view
                  GoRoute(
                    path: 'photo',
                           name: 'user_profile_photo',
                    pageBuilder: _buildPageTransition(
                              (context, state) {
                                final args = state.extra as Map<String, dynamic>?;
                                final imageUrl = args?['imageUrl'] as String?;
                                final heroTag = args?['heroTag'] as String?;
                                if (imageUrl == null) {
                                   return const ErrorDisplayPage(message: 'Image URL missing.');
                                }
                                // Ensure both parameters are non-nullable with meaningful defaults
                                final String nonNullImageUrl = imageUrl;
                                final String nonNullHeroTag = heroTag ?? 'user_photo_${DateTime.now().millisecondsSinceEpoch}';
                                return PhotoViewPage(
                                  imageUrl: nonNullImageUrl, 
                                  heroTag: nonNullHeroTag
                                );
                              },
                      type: TransitionType.fade,
                    ),
                  ),
                ],
                    ),
                     // Verification Admin Page
                     GoRoute(
                       path: 'verification_admin',
                       name: 'verification_admin',
                       pageBuilder: _buildPageTransition(
                         (context, state) => const VerificationAdminPage(),
                         type: TransitionType.cupertinoPush,
                       ),
                     ),
                  ]
              ),
            ],
          ),
        ],
      ),

       // Standalone routes
      GoRoute(
          path: '/photo_view',
          name: 'global_photo_view',
        pageBuilder: _buildPageTransition(
             (context, state) {
                final args = state.extra as Map<String, dynamic>?;
                final imageUrl = args?['imageUrl'] as String?;
                final heroTag = args?['heroTag'] as String?;
                if (imageUrl == null) {
                   return const ErrorDisplayPage(message: 'Image URL missing.');
                }
                // Ensure both parameters are non-nullable with meaningful defaults
                final String nonNullImageUrl = imageUrl;
                final String nonNullHeroTag = heroTag ?? 'global_photo_${DateTime.now().millisecondsSinceEpoch}';
                return PhotoViewPage(
                  imageUrl: nonNullImageUrl, 
                  heroTag: nonNullHeroTag
                );
             },
             type: TransitionType.fade,
        ),
      ),
      GoRoute(
         path: '/event/:eventId',
         name: 'global_event_detail',
        pageBuilder: _buildPageTransition(
          (context, state) {
                final String? eventId = state.pathParameters['eventId'];
                 if (eventId == null) {
                    return const ErrorDisplayPage(message: 'Event ID missing.');
                 }
                final args = state.extra as Map<String, dynamic>?;
                final event = args?['event'] as Event?;
                final heroTag = args?['heroTag'] as String? ?? 'event_$eventId';
                 if (event == null) {
                   return const ErrorDisplayPage(message: 'Event data missing.');
                }
                 return EventDetailPage(event: event, heroTag: heroTag);
             },
             type: TransitionType.cupertinoPush,
          ),
       ),
      GoRoute(
          path: AppRoutes.createPost,
          name: 'global_create_post',
          pageBuilder: _buildPageTransition(
             (context, state) => const CreatePostPage(),
          type: TransitionType.cupertinoModal,
          ),
       ),
      // Developer tools route removed - page no longer exists
      GoRoute(
         path: '/test/event_card',
         name: 'test_event_card',
        pageBuilder: _buildPageTransition(
           (context, state) => const EventCardTestPage(),
           type: TransitionType.cupertinoPush,
        ),
      ),
      GoRoute(
         path: AppRoutes.uiComponentsTest,
         name: 'ui_components_test',
        pageBuilder: _buildPageTransition(
           (context, state) => const DesignTokensTestPage(),
           type: TransitionType.cupertinoPush,
        ),
      ),
      GoRoute(
        path: CardLifecycleDemoPage.routeName,
        name: 'card_lifecycle_demo',
        pageBuilder: _buildPageTransition(
          (context, state) => const CardLifecycleDemoPage(),
          type: TransitionType.cupertinoPush,
        ),
      ),
      GoRoute(
         path: AppRoutes.adminVerificationRequests,
         name: 'admin_verification_requests',
         pageBuilder: _buildPageTransition(
           (context, state) => const VerificationRequestsScreen(),
           type: TransitionType.cupertinoPush,
         ),
         redirect: (context, state) async {
            final roleChecker = ref.read(roleCheckerProvider);
            final isAdmin = await roleChecker.hasRole(UserRole.admin);
            if (!isAdmin) {
               debugPrint("Redirect Check: User is not admin, redirecting from /admin/verification_requests");
               return AppRoutes.home;
            }
            return null;
         },
       ),
      GoRoute(
         path: '/messaging/group/:chatId/members',
         name: 'group_members',
        pageBuilder: _buildPageTransition(
          (context, state) {
            final chatId = state.pathParameters['chatId'];
             if (chatId == null) {
               return const ErrorDisplayPage(message: 'Chat ID missing.');
            }
            return GroupMembersScreen(chatId: chatId);
          },
           type: TransitionType.cupertinoPush,
        ),
      ),
      GoRoute(
         path: AppRoutes.messaging,
         name: 'messaging',
        pageBuilder: _buildPageTransition(
           (context, state) => const ChatListScreen(),
          type: TransitionType.cupertinoPush,
        ),
         routes: [
      GoRoute(
             path: ':chatId',
             name: 'chat_screen',
        pageBuilder: _buildPageTransition(
               (context, state) {
                 final chatId = state.pathParameters['chatId'];
                 if (chatId == null) {
                   return const ErrorDisplayPage(message: 'Chat ID missing.');
                 }
                 final args = state.extra as Map<String, dynamic>?;
                 final chatName = args?['chatName'] as String? ?? 'Chat';
                 final isGroupChat = args?['isGroupChat'] as bool? ?? false;
                 final chatAvatar = args?['chatAvatar'] as String?;

                 return ChatScreen(
                   chatId: chatId,
                   chatName: chatName,
                   isGroupChat: isGroupChat,
                   chatAvatar: chatAvatar,
                  );
               },
          type: TransitionType.cupertinoPush,
        ),
      ),
      GoRoute(
             path: 'create',
             name: 'chat_creation',
        pageBuilder: _buildPageTransition(
               (context, state) => const ChatCreationScreen(),
               type: TransitionType.cupertinoModal,
             ),
           ),
      GoRoute(
        path: 'attachment_viewer',
        name: 'attachment_viewer',
        pageBuilder: _buildPageTransition(
          (context, state) {
            final args = state.extra as Map<String, dynamic>?;
            if (args == null || args['attachment'] == null) {
              return const ErrorDisplayPage(message: 'Missing attachment data');
            }
            
            final attachment = args['attachment'] as MessageAttachment;
            final allAttachments = args['allAttachments'] as List<MessageAttachment>?;
            
            return AttachmentViewerScreen(
              attachment: attachment,
              allAttachments: allAttachments,
            );
          },
          type: TransitionType.cupertinoPush,
        ),
      ),
         ],
       ),
      GoRoute(
         path: '/organizations',
         name: 'organizations',
        pageBuilder: _buildPageTransition(
           (context, state) => const OrganizationsPage(),
           type: TransitionType.cupertinoPush,
         ),
          routes: [
      GoRoute(
               path: ':orgId',
               name: 'organization_profile',
        pageBuilder: _buildPageTransition(
                 (context, state) {
                    final orgId = state.pathParameters['orgId'];
                    if (orgId == null) {
                       return const ErrorDisplayPage(message: 'Organization ID missing.');
                    }
                    final organizationData = state.extra;
                    if (organizationData is Club) {
                      return OrganizationProfilePage(organization: organizationData);
                    } else {
                      debugPrint(
                          "Router Error: OrganizationProfilePage navigated without a valid Club object in extra. Received: ${organizationData?.runtimeType}, OrgId: $orgId");
                      return ErrorDisplayPage(
                        message:
                            'Organization details are missing or invalid. Cannot display profile.',
                        error: 'Expected Club object in extra, but received ${organizationData?.runtimeType}',
                      );
                    }
                 },
                 type: TransitionType.cupertinoPush,
               ),
             ),
          ],
       ),
      GoRoute(
         path: AppRoutes.hiveLab,
         name: 'hive_lab',
        pageBuilder: _buildPageTransition(
           (context, state) => const HiveLabPage(),
           type: TransitionType.cupertinoPush,
         ),
       ),
      GoRoute(
         path: '/event/:eventId/check_in_success',
         name: 'event_check_in_success',
        pageBuilder: _buildPageTransition(
          (context, state) {
            final String? eventId = state.pathParameters['eventId'];
            if (eventId == null) {
              return const ErrorDisplayPage(message: 'Event ID missing');
            }
            
            final args = state.extra as Map<String, dynamic>?;
            final event = args?['event'] as Event?;
            final checkInTime = args?['checkInTime'] as DateTime?;
            
            if (event == null) {
              return const ErrorDisplayPage(message: 'Event data missing');
            }
            
            return CheckInSuccessPage(
              event: event,
              checkInTime: checkInTime ?? DateTime.now(),
            );
          },
          type: TransitionType.fade,
        ),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        name: 'privacy_policy',
        pageBuilder: _buildPageTransition(
          (context, state) => const PrivacyPolicyPage(isOnboarding: false),
          type: TransitionType.cupertinoPush,
        ),
      ),
      // Add Password Reset Route
      GoRoute(
        path: AppRoutes.passwordReset,
        name: 'password_reset',
        pageBuilder: _buildPageTransition(
          (context, state) => const PasswordResetPage(),
        ),
      ),
      // Add Password Reset Sent Route
      GoRoute(
        path: AppRoutes.passwordResetSent,
        name: 'password_reset_sent',
        pageBuilder: _buildPageTransition(
          (context, state) => const PasswordResetSentPage(),
        ),
      ),
      // Add Magic Link Sent Route
      GoRoute(
        path: AppRoutes.magicLinkSent,
        name: 'magic_link_sent',
        pageBuilder: _buildPageTransition(
          (context, state) => const MagicLinkSentPage(),
        ),
      ),
      // Add verification request routes
      GoRoute(
        path: AppRoutes.requestVerification,
        name: 'verification_request',
        pageBuilder: _buildPageTransition(
          (context, state) => const VerificationRequestPage(),
          type: TransitionType.cupertinoPush,
        ),
      ),
      GoRoute(
        path: AppRoutes.requestVerifiedPlus,
        name: 'verification_request_upgrade',
        pageBuilder: _buildPageTransition(
          (context, state) => const VerificationRequestPage(),
          type: TransitionType.cupertinoPush,
        ),
      ),
      GoRoute(
        path: AppRoutes.verifyIdentity, // Use correct constant
        name: 'verify_identity', // Added name
        pageBuilder: _buildPageTransition(
          (context, state) => const VerifyIdentityPage(),
          type: TransitionType.cupertinoPush,
        ),
      ),
      GoRoute(
        path: AppRoutes.onboardingAccessPass, // Use correct constant
        name: 'onboarding_access_pass', // Added name
        pageBuilder: _buildPageTransition(
          (context, state) => const AccessPassPage(),
          type: TransitionType.cupertinoPush,
        ),
      ),
      GoRoute(
        path: AppRoutes.onboardingCampusDna, // Use correct constant
        name: 'onboarding_campus_dna', // Added name
        pageBuilder: _buildPageTransition(
          (context, state) => const CampusDnaPage(),
          type: TransitionType.cupertinoPush,
        ),
      ),
      GoRoute(
        path: AppRoutes.adminReviewVerification, // Use correct constant
        name: 'admin_review_verification', // Added name and admin guard
        pageBuilder: _buildPageTransition(
          (context, state) => const AdminReviewVerificationPage(),
          type: TransitionType.cupertinoPush,
        ),
        redirect: (context, state) async { // Added admin guard redirect
          final roleChecker = ref.read(roleCheckerProvider);
          final isAdmin = await roleChecker.hasRole(UserRole.admin);
          if (!isAdmin) {
             debugPrint("Redirect Check: User is not admin, redirecting from /admin/review-verification");
             return AppRoutes.home; // Redirect non-admins
          }
          return null; // Allow admins
       },
      ),
    ], // End of main routes list
  );
});

// Helper function for transitions using NavigationTransitions.buildAppleTransition
Page<dynamic> Function(BuildContext, GoRouterState) _buildPageTransition(
  Widget Function(BuildContext, GoRouterState) childBuilder, {
  TransitionType type = TransitionType.cupertinoPush, // Default type
}) {
  return (context, state) {
    return NavigationTransitions.buildAppleTransition(
      context: context,
      state: state,
      child: childBuilder(context, state),
      type: type, // Pass the type to the builder
    );
  };
}

// Define transition types enum (ensure it matches the one in transitions.dart)
// enum TransitionType { ... } // Removed duplicate definition

// GoRouter observer to track route changes
class _GoRouterObserver extends NavigatorObserver {
  final ValueNotifier<String?> currentPathNotifier;

  _GoRouterObserver(this.currentPathNotifier);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _updatePath(route);
    debugPrint("NAVIGATION: PUSH to ${route.settings.name} from ${previousRoute?.settings.name}");
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _updatePath(previousRoute);
    debugPrint("NAVIGATION: POP from ${route.settings.name} to ${previousRoute?.settings.name}");
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _updatePath(newRoute);
    debugPrint("NAVIGATION: REPLACE ${oldRoute?.settings.name} with ${newRoute?.settings.name}");
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint("NAVIGATION: REMOVE ${route.settings.name}");
  }

  void _updatePath(Route<dynamic>? route) {
    final path = route?.settings.name;
    currentPathNotifier.value = path;
    debugPrint("NAVIGATION: Current path is now $path");
  }
}


// Helper function to get the correct FirebaseAuth instance
fb_auth.FirebaseAuth _getAuthInstance() {
   return fb_auth.FirebaseAuth.instance;
}

/// Helper widget to display errors gracefully
class ErrorDisplayPage extends StatelessWidget {
  final String message;
  final Object? error;

  const ErrorDisplayPage({super.key, required this.message, this.error});

  @override
  Widget build(BuildContext context) {
    debugPrint("Router Error: $message. Details: $error");
    return Scaffold(
      appBar: AppBar(title: const Text("Error")),
          body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
            child: Column(
            mainAxisSize: MainAxisSize.min,
              children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                    textAlign: TextAlign.center,
                   style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
               const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (GoRouter.of(context).canPop()) {
                       GoRouter.of(context).pop();
                    } else {
                       GoRouter.of(context).go(AppRoutes.home);
                    }
                  },
                 child: const Text('Go Home'),
                ),
              ],
          ),
        ),
      ),
    );
  }
}

// Helper class to bridge Stream changes to Listenable for GoRouter refresh
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners(); // Initial notification
    _subscription = stream.asBroadcastStream().listen((dynamic _) {
        notifyListeners();
        debugPrint("GoRouterRefreshStream: Auth state changed, notified listeners.");
    }, onError: (error) {
       debugPrint("GoRouterRefreshStream: Error in auth stream: $error");
       // Optionally notify on error as well, depending on desired behavior
       // notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}





