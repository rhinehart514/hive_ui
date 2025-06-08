import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/club.dart';
import 'package:hive_ui/providers/user_providers.dart';
import 'package:hive_ui/services/club_service.dart';

/// State class for club management
class ClubControllerState {
  final bool isLoading;
  final String? error;
  final bool? isJoiningClub;

  const ClubControllerState({
    this.isLoading = false,
    this.error,
    this.isJoiningClub,
  });

  ClubControllerState copyWith({
    bool? isLoading,
    String? error,
    bool? isJoiningClub,
    bool clearError = false,
  }) {
    return ClubControllerState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      isJoiningClub: isJoiningClub ?? this.isJoiningClub,
    );
  }
}

/// Controller for club management actions
class ClubController extends StateNotifier<ClubControllerState> {
  final Ref _ref;

  ClubController(this._ref) : super(const ClubControllerState());

  /// Toggle membership status for a club
  Future<void> toggleClubMembership(String clubId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final userData = _ref.read(userProvider);
      final isMember = userData?.joinedClubs.contains(clubId) ?? false;

      if (isMember) {
        // Use providers to leave club instead of service directly
        _ref.read(leaveClubProvider(clubId));
        state = state.copyWith(isLoading: false, isJoiningClub: false);
      } else {
        // Use providers to join club instead of service directly
        _ref.read(joinClubProvider(clubId));
        state = state.copyWith(isLoading: false, isJoiningClub: true);
      }

      // Refresh user data to reflect membership changes
      _ref.invalidate(userProvider);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update membership: ${e.toString()}',
      );
    }
  }

  /// Update club details (for club managers)
  Future<void> updateClub({
    required String clubId,
    String? name,
    String? description,
    String? logoUrl,
    String? bannerUrl,
    List<String>? tags,
    List<String>? categories,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // In a real implementation, this would call an API to update the club
      // For now, we'll just simulate success after a delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Invalidate related providers to refresh UI with updated data
      _ref.invalidate(clubByIdProvider(clubId));

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update club: ${e.toString()}',
      );
    }
  }
}

/// Provider for club controller
final clubControllerProvider =
    StateNotifierProvider<ClubController, ClubControllerState>((ref) {
  return ClubController(ref);
});

/// Provider for club byId (placeholder until it's properly defined elsewhere)
final clubByIdProvider =
    FutureProvider.family.autoDispose<Club?, String>((ref, id) async {
  return ClubService.getClubById(id);
});
