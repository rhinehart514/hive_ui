import 'package:flutter/material.dart';
import 'package:hive_ui/models/club.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/features/spaces/presentation/screens/space_detail_screen.dart';
import 'package:hive_ui/shared/widgets/error_view.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/features/spaces/domain/mappers/space_entity_mapper.dart';

/// A transitional widget that redirects old club/space URLs to the new SpaceDetailScreen.
/// This class preserves backward compatibility while the codebase transitions to the new
/// space system. It handles both old-style club URLs and new space URLs.
///
/// This widget should be used in the router to handle:
/// - Legacy /spaces/club?id=xyz URLs
/// - Direct club/space object passing
/// - New space type-based routing
@Deprecated('Use SpaceDetailScreen directly instead. This class will be removed once transition is complete.')
class ClubSpacePage extends StatelessWidget {
  final String? clubId;
  final Club? club;
  final Space? space;
  final String? spaceType;

  const ClubSpacePage({
    super.key,
    this.clubId,
    this.club,
    this.space,
    this.spaceType,
  });

  /// Factory constructor to create from GoRouter parameters
  /// This handles both query parameters and extra data passing
  static ClubSpacePage fromGoRouterState(GoRouterState state) {
    final Map<String, dynamic>? extra = state.extra as Map<String, dynamic>?;
    
    // First try to get data from extra
    if (extra != null) {
      return ClubSpacePage(
        space: extra['space'] as Space?,
        spaceType: extra['spaceType'] as String?,
        club: extra['club'] as Club?,
      );
    }

    // Fallback to URI parameters
    final Uri uri = state.uri;
    final String? type = uri.queryParameters['type'] ?? state.pathParameters['type'];
    final String? id = uri.queryParameters['id'] ?? state.pathParameters['id'];
    
    return ClubSpacePage(
      clubId: id,
      spaceType: type,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine the spaceId and potentially spaceType
    String? resolvedSpaceId = clubId ?? club?.id;
    String? resolvedSpaceType = spaceType; // May need logic to derive from club if null
    
    // TODO: If spaceType is null and club is provided, derive spaceType from club
    if (resolvedSpaceType == null && club != null) {
       // Use the primary category as the space type if not provided
       resolvedSpaceType = club!.category; 
    }

    // If we don't have an ID, show error
    if (resolvedSpaceId == null) {
      return const ErrorView(
        message: 'Missing Space identifier.',
        icon: Icons.error_outline,
      );
    }
    
    // If we don't have a type (and couldn't derive it), show error
    // Note: The SpaceDetailScreen itself might handle fetching if type isn't needed directly
    // Commenting out for now, assuming SpaceDetailScreen can fetch details with ID alone.
    /*
    if (resolvedSpaceType == null) {
      return const ErrorView(
        message: 'Missing Space type.',
        icon: Icons.error_outline,
      );
    }
    */

    // If we have a club object, convert it to space format if needed by SpaceDetailScreen
    // Or just pass the ID and let SpaceDetailScreen fetch
    return SpaceDetailScreen(
      key: ValueKey(resolvedSpaceId), // Add key for state preservation
      spaceId: resolvedSpaceId,
    );
  }
} 