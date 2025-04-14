import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/navigation/routes.dart';
import 'package:hive_ui/core/navigation/deep_link_service.dart';
import 'package:hive_ui/core/navigation/transitions.dart';
import 'package:hive_ui/core/navigation/not_found_screen.dart';
import 'package:hive_ui/core/navigation/async_navigation_service.dart';
import 'package:hive_ui/core/navigation/error_display_page.dart';
import 'package:hive_ui/shell.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/features/profile/presentation/pages/verification_admin_page.dart';
import 'package:hive_ui/features/messaging/domain/entities/message_attachment.dart';
import 'package:hive_ui/features/examples/presentation/pages/card_lifecycle_demo_page.dart';

// Page imports
import 'package:hive_ui/pages/landing_page.dart';
import 'package:hive_ui/pages/auth/login_page.dart';
import 'package:hive_ui/pages/auth/create_account.dart';
import 'package:hive_ui/pages/onboarding_profile.dart';
import 'package:hive_ui/pages/profile_page.dart';
import 'package:hive_ui/pages/organizations_page.dart';
import 'package:hive_ui/pages/organization_profile_page.dart';
import 'package:hive_ui/pages/hive_lab_page.dart';
import 'package:hive_ui/pages/developer_tools_page.dart';
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
import 'package:hive_ui/main.dart'; // Import main to access appInitializationProvider
import 'package:hive_ui/features/auth/providers/user_preferences_provider.dart';
import 'package:hive_ui/features/events/presentation/pages/check_in_success_page.dart';
import 'package:hive_ui/features/auth/presentation/pages/privacy_policy_page.dart';
import 'package:hive_ui/features/messaging/presentation/screens/attachment_viewer_screen.dart';
import 'package:hive_ui/features/auth/presentation/pages/splash_gate_page.dart';

/// Provider for the DeepLinkService
final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  return DeepLinkService(ref);
});

/// Provider for storing pending deep links
final pendingDeepLinkProvider = StateProvider<String?>((ref) => null);

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
    initialLocation: AppRoutes.landing,
    debugLogDiagnostics: true,
    refreshListenable: authStateListenable, 
    navigatorKey: navigatorKey, // Use the root navigator key
    observers: [
      // Add an observer to update the current path
      _GoRouterObserver(currentPathNotifier),
    ],
    // Add error builder to handle 404s with our custom screen
    errorBuilder: (context, state) {
      // Log the error
      debugPrint('404 Error: Unable to navigate to ${state.uri.path}');
      
      // Return our custom NotFoundScreen
      return NotFoundScreen(path: state.uri.path);
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
            child: OnboardingProfilePage(skipToDefaults: skipPreferences),
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
                   // Route for Space Detail Screen
                  GoRoute(
                     path: ':spaceId/:spaceType',
                     name: 'space_detail',
                     pageBuilder: (context, state) {
                         final spaceId = state.pathParameters['spaceId'];
                         final spaceType = state.pathParameters['spaceType'];
                         final space = state.extra as Space?;

                         if (spaceId == null || spaceType == null) {
                            return _buildPageTransition(
                               (context, state) => const ErrorDisplayPage(message: 'Missing space details'),
                            )(context, state);
                         }

                         return _buildPageTransition(
                           (context, state) => SpaceDetailScreen(
                             spaceId: spaceId,
                             spaceType: spaceType,
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
                             final space = state.extra as Space?;
                              if (space == null) {
                               return const ErrorDisplayPage(message: 'Space information missing for event creation.');
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
      GoRoute(
         path: AppRoutes.developerTools,
         name: 'developer_tools',
        pageBuilder: _buildPageTransition(
           (context, state) => const DeveloperToolsPage(),
           type: TransitionType.cupertinoPush,
        ),
      ),
      GoRoute(
         path: '/test/event_card',
         name: 'test_event_card',
        pageBuilder: _buildPageTransition(
           (context, state) => const EventCardTestPage(),
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
    ], // End of main routes list

    // REDIRECT LOGIC - Final attempt
   redirect: (context, state) async {
      final String location = state.uri.path;
      final Map<String, String> queryParams = state.uri.queryParameters;
      
      debugPrint("🚀 Router Redirect Check Triggered for Location: $location");
      
      // --- 1. Check App Initialization Status ---
      final appInitState = ref.read(appInitializationProvider);
      
      if (appInitState is AsyncLoading) {
        debugPrint("⏳ Redirect Check: App initializing, deferring redirect.");
        return null;
      } else if (appInitState is AsyncError) {
        debugPrint("❌ Redirect Check: App initialization failed: ${appInitState.error}. Allowing navigation, but app might be broken.");
        return null;
      }
      
      // App is initialized, proceed
      debugPrint("✅ Redirect Check: App Initialized. Proceeding with auth checks.");
      
      // --- 2. Check Authentication Status ---
      final authState = ref.read(auth_features.authStateProvider);
      
      if (authState is AsyncLoading) {
        debugPrint("⏳ Redirect Check: Auth provider loading, deferring redirect.");
        return null;
      } else if (authState is AsyncError) {
        debugPrint("❌ Redirect Check: Error in Auth provider: ${authState.error}. Allowing navigation.");
        return null;
      }
      
      final bool loggedIn = authState.valueOrNull?.isNotEmpty ?? false;
      
      // --- 3. Check Terms Acceptance Status ---
      final prefsState = ref.read(userPreferencesProvider);
      final hasAcceptedTerms = prefsState.hasAcceptedTerms;
      
      // --- 4. Check Onboarding Status ---
      final onboardingComplete = UserPreferencesService.hasCompletedOnboarding();
      
      // Check role status
      final roleState = ref.read(currentUserRoleProvider);
      UserRole role = UserRole.public;
      
      if (roleState is AsyncLoading) {
        debugPrint("⏳ Redirect Check: Role provider loading, using default.");
      } else if (roleState is AsyncError) {
        debugPrint("❌ Redirect Check: Role provider error (${roleState.error}), using default.");
      } else if (roleState is AsyncData<UserRole>) {
        role = roleState.value;
      }
      
      debugPrint(
        "ℹ️ Redirect Check State: loggedIn=$loggedIn, onboardingComplete=$onboardingComplete, hasAcceptedTerms=$hasAcceptedTerms, role=$role, currentLocation=$location"
      );
      
      // --- 5. Apply Redirect Logic ---
      
      // Handle auth source tracking for social auth redirects
      final String? authSource = queryParams['auth_source'];
      final String? returnTo = queryParams['return_to'];
      
      // Not logged in
      if (!loggedIn) {
        debugPrint("🔐 Redirect Check: User NOT logged in.");
        
        // If on auth or terms page, allow access
        if (location == AppRoutes.signIn || 
            location == AppRoutes.createAccount ||
            location == AppRoutes.landing ||
            location == '/terms') {
          debugPrint("✅ Redirect: Allowed on Auth/Terms Page ($location)");
          return null;
        }
        
        // Otherwise redirect to landing
        debugPrint("🛑 Redirect => Landing (Not Logged In, Not on Auth/Terms Page)");
        return AppRoutes.landing;
      }
      
      // Logged in cases
      debugPrint("🔓 Redirect Check: User IS logged in.");
      
      // 1. Terms not accepted
      if (!hasAcceptedTerms) {
        debugPrint("📜 Redirect Check: Terms NOT accepted.");
        
        // If on terms page, allow access
        if (location == '/terms') {
          debugPrint("✅ Redirect: Allowed on Terms Page ($location)");
          return null;
        }
        
        // Otherwise redirect to terms
        debugPrint("🛑 Redirect => Terms (Logged In, Terms Not Accepted)");
        return '/terms';
      }
      
      // 2. Onboarding not complete
      if (!onboardingComplete) {
        debugPrint("🧑‍🎓 Redirect Check: Onboarding NOT complete.");
        
        // If on onboarding page, allow access
        if (location == AppRoutes.onboarding) {
          debugPrint("✅ Redirect: Allowed on Onboarding Page ($location)");
          return null;
        }
        
        // Otherwise redirect to onboarding
        debugPrint("🛑 Redirect => Onboarding (Logged In, Terms Accepted, Onboarding Not Complete)");
        return AppRoutes.onboarding;
      }
      
      // 3. Setup complete
      debugPrint("✅ Redirect Check: Setup Complete (Logged In, Terms Accepted, Onboarding Complete).");
      
      // If user is fully set up and trying to access an auth/setup page, redirect them 
      if (location == AppRoutes.signIn || location == AppRoutes.createAccount || 
          location == AppRoutes.landing || location == AppRoutes.onboarding || 
          location == '/terms') {
        
        // Check if this is a redirect from social auth with return_to parameter
        if (authSource != null && authSource.contains('social') && returnTo != null && returnTo.isNotEmpty) {
          debugPrint("🔀 Redirect => $returnTo (Social Auth Redirect)");
          return returnTo;
        }
        
        debugPrint("🛑 Redirect => Home (Setup Complete, but on Auth/Setup Page)");
        return AppRoutes.home;
      }
      
      // The admin check is handled in the route definition's redirect block.
      
      // If none of the above conditions triggered a redirect, allow access
      debugPrint("✅ Redirect: No redirect needed for $location");
      return null;
    },
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
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _updatePath(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _updatePath(newRoute);
  }

  void _updatePath(Route<dynamic>? route) {
    final path = route?.settings.name;
    currentPathNotifier.value = path;
    // debugPrint("NAV OBSERVER: Path changed to $path");
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
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) {
         // debugPrint("GoRouterRefreshStream: Notifying listeners due to stream update.");
         notifyListeners();
      },
      onError: (error) {
        debugPrint("GoRouterRefreshStream: Error in stream: $error");
      },
       onDone: () {
          debugPrint("GoRouterRefreshStream: Stream closed.");
       }
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}





