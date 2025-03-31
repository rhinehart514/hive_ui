import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/core/navigation/routes.dart';
import 'package:hive_ui/core/navigation/transitions.dart';
import 'package:hive_ui/shell.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/models/space.dart';

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
import 'package:hive_ui/features/clubs/presentation/pages/club_space_page.dart';
import 'package:hive_ui/models/organization.dart';
import 'package:hive_ui/features/messaging/presentation/screens/group_members_screen.dart';
import 'package:hive_ui/features/messaging/presentation/screens/chat_list_screen.dart';
import 'package:hive_ui/features/messaging/presentation/screens/chat_screen.dart';
import 'package:hive_ui/features/messaging/presentation/screens/chat_creation_screen.dart';
import 'package:hive_ui/features/spaces/presentation/pages/spaces_page.dart';
import 'package:hive_ui/features/spaces/presentation/pages/spaces_page_revamp.dart';
import 'package:hive_ui/features/spaces/presentation/pages/create_space_page.dart';
import 'package:hive_ui/features/spaces/presentation/pages/create_space_splash_page.dart';
import 'package:hive_ui/features/events/presentation/pages/create_event_page.dart';
import 'package:hive_ui/screens/admin/verification_requests_screen.dart';
import 'package:hive_ui/services/admin_service.dart';
import 'package:hive_ui/pages/quote_repost_page.dart';
import 'package:hive_ui/models/event.dart';
// Settings pages
import 'package:hive_ui/pages/settings/settings_page.dart' as old_settings;
import 'package:hive_ui/pages/settings/account_settings_page.dart';
import 'package:hive_ui/pages/settings/privacy_settings_page.dart';
import 'package:hive_ui/pages/settings/notification_settings_page.dart';
import 'package:hive_ui/pages/settings/appearance_settings_page.dart';
import 'package:hive_ui/features/feed/presentation/pages/event_detail_page.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/pages/photo_view_page.dart';
import 'package:hive_ui/features/settings/presentation/pages/settings_page.dart';
import 'package:hive_ui/pages/main_feed.dart';
import 'package:hive_ui/features/friends/presentation/screens/suggested_friends_screen.dart';
import 'package:hive_ui/features/profile/presentation/pages/profile_photo_page.dart';
// Test pages
import 'package:hive_ui/components/event_card/event_card_test_page.dart';

/// Error display page for navigation errors
class ErrorDisplayPage extends StatelessWidget {
  final String message;

  const ErrorDisplayPage({super.key, this.message = 'Page not found'});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Error',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => GoRouter.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Router configuration for the application
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.landing,
  debugLogDiagnostics: true,
  routes: [
    // Auth routes - outside the shell
    GoRoute(
      path: AppRoutes.landing,
      pageBuilder: _buildPageTransition(
        (context, state) => const LandingPage(),
        type: TransitionType.fade,
      ),
    ),
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
        // Custom transition for onboarding
        return CustomTransitionPage<void>(
          key: state.pageKey,
          child: const OnboardingProfilePage(),
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

    // Settings routes
    GoRoute(
      path: AppRoutes.settings,
      name: 'settings',
      pageBuilder: _buildPageTransition(
        (context, state) => const SettingsPage(),
        type: TransitionType.cupertinoPush,
      ),
      routes: [
        // Add nested routes under settings to fix navigation issue
        GoRoute(
          path: 'account',
          name: 'account_settings',
          pageBuilder: _buildPageTransition(
            (context, state) => const AccountSettingsPage(),
            type: TransitionType.cupertinoPush,
          ),
        ),
        GoRoute(
          path: 'privacy',
          name: 'privacy_settings',
          pageBuilder: _buildPageTransition(
            (context, state) => const PrivacySettingsPage(),
            type: TransitionType.cupertinoPush,
          ),
        ),
        GoRoute(
          path: 'notifications',
          name: 'notification_settings',
          pageBuilder: _buildPageTransition(
            (context, state) => const NotificationSettingsPage(),
            type: TransitionType.cupertinoPush,
          ),
        ),
        GoRoute(
          path: 'appearance',
          name: 'appearance_settings',
          pageBuilder: _buildPageTransition(
            (context, state) => const AppearanceSettingsPage(),
            type: TransitionType.cupertinoPush,
          ),
        ),
      ],
    ),
    
    // Quote repost page route
    GoRoute(
      path: AppRoutes.quoteRepost,
      name: AppRoutes.quoteRepost.substring(1).replaceAll('-', '_'),
      pageBuilder: _buildPageTransition(
        (context, state) {
          final event = state.extra as Event;
          return QuoteRepostPage(
            event: event,
            onComplete: (state.uri.queryParameters['onComplete'] == 'true') 
                ? (bool success) {} 
                : null,
          );
        },
        type: TransitionType.cupertinoPush,
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
            // Home route using MainFeed component from main_feed.dart
            GoRoute(
              path: AppRoutes.home,
              pageBuilder: _buildPageTransition(
                (context, state) => const MainFeed(),
              ),
              routes: [
                // Event detail route
                GoRoute(
                  path: 'event/:eventId',
                  pageBuilder: _buildPageTransition(
                    (context, state) {
                      final String eventId = state.pathParameters['eventId']!;
                      // Get event from arguments
                      final args = state.extra as Map<String, dynamic>?;
                      final event = args?['event'] as Event?;

                      if (event == null) {
                        return const ErrorDisplayPage(
                          message: 'Event not found',
                        );
                      }

                      final heroTag =
                          args?['heroTag'] as String? ?? 'event_$eventId';

                      return EventDetailPage(
                        event: event,
                        heroTag: heroTag,
                      );
                    },
                    // Using fade transition for smoother hero animation
                    type: TransitionType.fade,
                  ),
                ),
                // Nested routes under home
                GoRoute(
                  path: 'organizations',
                  pageBuilder: _buildPageTransition(
                    (context, state) => const OrganizationsPage(),
                  ),
                ),
                GoRoute(
                  path: 'organizations/:organizationId',
                  pageBuilder: _buildPageTransition(
                    (context, state) {
                      final String organizationId =
                          state.pathParameters['organizationId']!;
                      final organization = Organization(
                        id: organizationId,
                        name: 'Organization $organizationId',
                        description:
                            'This is a placeholder for organization details.',
                        category: 'General',
                        memberCount: 0,
                        status: 'active',
                        icon: Icons.business,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );
                      return OrganizationProfilePage(
                          organization: organization.toClub());
                    },
                  ),
                ),
                GoRoute(
                  path: 'hivelab',
                  pageBuilder: _buildPageTransition(
                    (context, state) => const HiveLabPage(),
                  ),
                ),
                GoRoute(
                  path: 'photo/:photoId',
                  pageBuilder: _buildPageTransition(
                    (context, state) {
                      final String photoId = state.pathParameters['photoId']!;
                      final args = state.extra as Map<String, dynamic>?;
                      final imageUrl = args?['imageUrl'] as String?;
                      final heroTag =
                          args?['heroTag'] as String? ?? 'photo_$photoId';

                      if (imageUrl == null) {
                        return const ErrorDisplayPage(
                          message: 'Photo not found',
                        );
                      }

                      return PhotoViewPage(
                        imageUrl: imageUrl,
                        heroTag: heroTag,
                      );
                    },
                    type: TransitionType.cupertinoFullscreenModal,
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
                (context, state) {
                  // Check if we should show the new spaces page
                  final useRevampedUI =
                      state.uri.queryParameters['revamped'] == 'true';

                  return useRevampedUI
                      ? const SpacesPageRevamp()
                      : const SpacesPage();
                },
              ),
              routes: [
                // Nested routes under spaces
                GoRoute(
                  path: 'club',
                  pageBuilder: _buildPageTransition(
                    (context, state) {
                      final clubId = state.uri.queryParameters['id'];
                      final spaceType = state.uri.queryParameters['type'] ??
                          'student_organizations';

                      if (clubId == null || clubId.isEmpty) {
                        return const ErrorDisplayPage(
                          message: 'Club ID is required in query parameter',
                        );
                      }

                      return ClubSpacePage(
                        clubId: Uri.decodeComponent(clubId),
                        spaceType: spaceType,
                      );
                    },
                    type: TransitionType.cupertinoModal,
                  ),
                ),
                // New route for the revamped spaces page
                GoRoute(
                  path: 'revamp',
                  pageBuilder: _buildPageTransition(
                    (context, state) => const SpacesPageRevamp(),
                    type: TransitionType.fade,
                  ),
                ),
                // Add route for creating a new space
                GoRoute(
                  path: 'create',
                  pageBuilder: _buildPageTransition(
                    (context, state) => const CreateSpaceSplashPage(),
                    type: TransitionType.cupertinoModal,
                  ),
                ),
                // Direct route to CreateSpacePage (used by the splash page for redirection)
                GoRoute(
                  path: 'create-direct',
                  pageBuilder: _buildPageTransition(
                    (context, state) => const CreateSpacePage(),
                    type: TransitionType.fade,
                  ),
                ),
                // Add route for creating a new event
                GoRoute(
                  path: 'create-event',
                  pageBuilder: _buildPageTransition(
                    (context, state) {
                      final extra = state.extra as Map<String, dynamic>?;
                      final space = extra?['space'] as Space?;
                      
                      if (space == null) {
                        return const ErrorDisplayPage(
                          message: 'Space is required for event creation',
                        );
                      }
                      
                      return CreateEventPage(selectedSpace: space);
                    },
                    type: TransitionType.cupertinoModal,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Profile branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              pageBuilder: _buildPageTransition(
                (context, state) => const ProfilePage(),
              ),
              routes: [
                // Dynamic user profile route
                GoRoute(
                  path: ':userId',
                  pageBuilder: _buildPageTransition(
                    (context, state) {
                      final userId = state.pathParameters['userId'];
                      final args = state.extra as Map<String, dynamic>?;
                      final username = args?['username'] as String?;

                      if (userId == null || userId.isEmpty) {
                        return const ErrorDisplayPage(
                          message: 'User ID is required',
                        );
                      }

                      return ProfilePage(
                        userId: userId,
                      );
                    },
                    type: TransitionType.cupertinoPush,
                  ),
                ),
                
                // Suggested friends route
                GoRoute(
                  path: 'suggested-friends',
                  pageBuilder: _buildPageTransition(
                    (context, state) => const SuggestedFriendsScreen(),
                    type: TransitionType.cupertinoPush,
                  ),
                ),
                
                // Profile photo picker route
                GoRoute(
                  path: 'photo',
                  pageBuilder: _buildPageTransition(
                    (context, state) => const ProfilePhotoPage(),
                    type: TransitionType.fade,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // Messaging routes (outside the shell)
    GoRoute(
      path: AppRoutes.messaging,
      pageBuilder: _buildPageTransition(
        (context, state) => const ChatListScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.chat,
      pageBuilder: _buildPageTransition(
        (context, state) {
          final chatId = state.pathParameters['chatId'];
          if (chatId == null || chatId.isEmpty) {
            return const ErrorDisplayPage(
              message: 'Chat ID is required',
            );
          }
          final extra = state.extra as Map<String, dynamic>?;
          return ChatScreen(
            chatId: chatId,
            chatName: extra?['chatName'] as String? ?? '',
            chatAvatar: extra?['chatAvatar'] as String?,
            isGroupChat: extra?['isGroupChat'] as bool? ?? false,
          );
        },
        type: TransitionType.cupertinoModal,
      ),
    ),
    GoRoute(
      path: AppRoutes.createChat,
      pageBuilder: _buildPageTransition(
        (context, state) => const ChatCreationScreen(),
        type: TransitionType.cupertinoFullscreenModal,
      ),
    ),
    GoRoute(
      path: AppRoutes.groupMembers,
      pageBuilder: _buildPageTransition(
        (context, state) {
          final chatId = state.pathParameters['chatId'];
          if (chatId == null || chatId.isEmpty) {
            return const ErrorDisplayPage(
              message: 'Chat ID is required',
            );
          }
          return GroupMembersScreen(chatId: chatId);
        },
      ),
    ),

    // Admin routes - only available to admin users, but hidden from route table for non-admins
    // Security is enforced through global redirect function
    GoRoute(
      path: AppRoutes.adminVerificationRequests,
      pageBuilder: _buildPageTransition(
        (context, state) => const VerificationRequestsScreen(),
        type: TransitionType.cupertinoPush,
      ),
    ),

    // Developer Tools route
    GoRoute(
      path: AppRoutes.developerTools,
      pageBuilder: _buildPageTransition(
        (context, state) => const DeveloperToolsPage(),
        type: TransitionType.fade,
      ),
    ),

    // Test route for event card
    GoRoute(
      path: AppRoutes.eventCardTest,
      pageBuilder: _buildPageTransition(
        (context, state) => const EventCardTestPage(),
        type: TransitionType.fade,
      ),
    ),
  ],
  errorBuilder: (context, state) => const ErrorDisplayPage(),
  redirect: _handleRedirect,
);

/// Builds a page transition with the default animation
Page<dynamic> Function(BuildContext, GoRouterState) _buildPageTransition(
    Widget Function(BuildContext, GoRouterState) builder,
    {TransitionType type = TransitionType.cupertinoPush}) {
  return (context, state) {
    return NavigationTransitions.buildAppleTransition(
      state: state,
      context: context,
      child: builder(context, state),
      type: type,
    );
  };
}

// Cache for admin status to avoid repeated Firestore calls
bool? _cachedAdminStatus;

/// Global navigation guard
Future<String?> _handleRedirect(
    BuildContext context, GoRouterState state) async {
  try {
    // Block access to admin routes for non-admin users
    if (state.uri.path.startsWith('/admin')) {
      try {
        // Check admin status (using cache if available)
        _cachedAdminStatus ??= await AdminService.isUserAdmin();

        // Redirect non-admin users silently to home page - they should never know admin routes exist
        if (_cachedAdminStatus != true) {
          debugPrint(
              'Non-admin attempted to access admin route: ${state.uri.path}');
          return AppRoutes.home;
        }
      } catch (e) {
        // For any error checking admin status, redirect to home for safety
        debugPrint('Error checking admin status: $e');
        return AppRoutes.home;
      }
    }

    // Add other authentication and navigation guards here
    // For example:
    // final isAuthenticated = context.read<AuthProvider>().isAuthenticated;
    // if (!isAuthenticated && !_isPublicRoute(state.location)) {
    //   return AppRoutes.signIn;
    // }

    return null;
  } catch (e) {
    // Global error handler for navigation guards
    debugPrint('Error in navigation guard: $e');
    // Default to home page for any unexpected errors
    return AppRoutes.home;
  }
}

/// Checks if a route is public (doesn't require authentication)
/// This function will be used when implementing authentication guards
bool _isPublicRoute(String location) {
  return location == AppRoutes.landing ||
      location == AppRoutes.signIn ||
      location == AppRoutes.createAccount ||
      location == AppRoutes.onboarding;
}
