import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_async_providers.dart';

/// Provider to handle space navigation state and logic
final spaceNavigationProvider = Provider((ref) => SpaceNavigator(ref));

class SpaceNavigator {
  final ProviderRef _ref;

  SpaceNavigator(this._ref);

  /// Navigate to a space detail page
  void navigateToSpace(BuildContext context, {
    required String spaceId,
    required String spaceType,
    Space? space,
  }) {
    // Set the space type in the provider before navigation
    _ref.read(spaceTypeProvider(spaceId).notifier).state = spaceType;
    
    // Navigate to the space using the correct URL structure
    context.push(
      '/spaces/$spaceType/spaces/$spaceId',
      extra: space != null ? {'space': space} : null,
    );
  }
} 