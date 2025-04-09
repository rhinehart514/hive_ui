import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/core/navigation/routes.dart';
import 'package:hive_ui/core/navigation/transitions.dart';

/// Parameters for club space route navigation
class ClubSpaceRouteParams {
  final String? id;
  final String? type;

  const ClubSpaceRouteParams({
    this.id,
    this.type = 'student_organizations',
  });

  Map<String, String> toQueryParameters() {
    final Map<String, String> params = {};
    if (id != null) params['id'] = id!;
    if (type != null) params['type'] = type!;
    return params;
  }
}

/// Centralized navigation service for the application
/// This service provides consistent navigation methods and applies
/// appropriate transitions and haptic feedback for all navigation actions
class NavigationService {
  /// Private constructor to prevent instantiation
  const NavigationService._();

  /// Navigate to the landing page
  static void goToLanding(BuildContext context) {
    _applyTransition(NavigationFeedbackType.pageTransition);
    GoRouter.of(context).go(AppRoutes.landing);
  }

  /// Navigate to the sign in page
  static void goToSignIn(BuildContext context) {
    _applyTransition(NavigationFeedbackType.modalOpen);
    GoRouter.of(context).push(AppRoutes.signIn);
  }

  /// Navigate to the create account page
  static void goToCreateAccount(BuildContext context) {
    _applyTransition(NavigationFeedbackType.modalOpen);
    GoRouter.of(context).push(AppRoutes.createAccount);
  }

  /// Navigate to the onboarding page
  static void goToOnboarding(BuildContext context) {
    _applyTransition(NavigationFeedbackType.pageTransition);
    GoRouter.of(context).go(AppRoutes.onboarding);
  }

  /// Navigate to the home screen
  static void goToHome(BuildContext context) {
    _applyTransition(NavigationFeedbackType.pageTransition);
    GoRouter.of(context).go(AppRoutes.home);
  }

  /// Navigate to the spaces screen
  static void goToSpaces(BuildContext context) {
    _applyTransition(NavigationFeedbackType.tabChange);
    GoRouter.of(context).go(AppRoutes.spaces);
  }

  /// Navigate to a specific club space
  static void goToClubSpace(BuildContext context, ClubSpaceRouteParams params) {
    _applyTransition(NavigationFeedbackType.modalOpen);
    final queryParams = params.toQueryParameters();
    final uri = Uri(
      path: AppRoutes.clubSpace,
      queryParameters: queryParams,
    );
    GoRouter.of(context).push(uri.toString());
  }

  /// Navigate to profile page
  static void goToProfile(BuildContext context) {
    _applyTransition(NavigationFeedbackType.tabChange);
    GoRouter.of(context).go(AppRoutes.profile);
  }

  /// Navigate to messaging page
  static void goToMessaging(BuildContext context) {
    _applyTransition(NavigationFeedbackType.tabChange);
    GoRouter.of(context).go(AppRoutes.messaging);
  }

  /// Navigate to a specific chat
  static void goToChat(
    BuildContext context,
    String chatId, {
    required String chatName,
    String? chatAvatar,
    bool isGroupChat = false,
  }) {
    _applyTransition(NavigationFeedbackType.modalOpen);
    GoRouter.of(context).push('/messaging/chat/$chatId', extra: {
      'chatName': chatName,
      'chatAvatar': chatAvatar,
      'isGroupChat': isGroupChat,
    });
  }

  /// Navigate to chat creation screen
  static void goToChatCreation(BuildContext context, {String? initialUserId}) {
    _applyTransition(NavigationFeedbackType.modalOpen);
    GoRouter.of(context).push(AppRoutes.createChat, extra: {
      'initialUserId': initialUserId,
    });
  }

  /// Apply navigation transition feedback with the appropriate feedback type
  static void _applyTransition(NavigationFeedbackType type) {
    NavigationTransitions.applyNavigationFeedback(type: type);
  }

  /// Pop the current route
  static void pop(BuildContext context) {
    if (GoRouter.of(context).canPop()) {
      _applyTransition(NavigationFeedbackType.modalDismiss);
      GoRouter.of(context).pop();
    }
  }

  /// Pop to a specific route
  static void popUntil(BuildContext context, String routeName) {
    final router = GoRouter.of(context);
    while (router.canPop() && 
           !router.routeInformationProvider.value.location.startsWith(routeName)) {
      _applyTransition(NavigationFeedbackType.modalDismiss);
      router.pop();
    }
  }
}
