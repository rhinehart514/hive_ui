import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'space_membership_state.dart';
// import 'package:hive_ui/services/firestore_service.dart'; // Placeholder

class SpaceMembershipNotifier extends StateNotifier<SpaceMembershipState> {
  final String _spaceId;
  // final FirestoreService _firestoreService; // TODO: Inject actual service

  SpaceMembershipNotifier(this._spaceId /*, this._firestoreService*/)
      : super(const SpaceMembershipState()) {
    _checkInitialMembership();
  }

  Future<void> _checkInitialMembership() async {
    state = state.copyWith(status: SpaceMembershipStatus.loading);
    try {
      // TODO: Replace with actual membership check
      // final isMember = await _firestoreService.isMemberOfSpace(_spaceId);
      // final canCreate = await _firestoreService.canCreateEventsInSpace(_spaceId);
      await Future.delayed(const Duration(milliseconds: 200)); // Simulate check
      final isMember = true; // Placeholder
      final canCreate = true; // Placeholder

      state = state.copyWith(
        status: isMember ? SpaceMembershipStatus.joined : SpaceMembershipStatus.notJoined,
        canCreateEvents: canCreate,
      );
    } catch (e) {
      state = state.copyWith(
        status: SpaceMembershipStatus.error,
        errorMessage: 'Failed to check membership',
      );
    }
  }

  Future<void> joinSpace() async {
    if (state.status == SpaceMembershipStatus.joined ||
        state.status == SpaceMembershipStatus.loading) return;

    state = state.copyWith(status: SpaceMembershipStatus.loading);
    try {
      // TODO: Replace with actual join logic
      // await _firestoreService.joinSpace(_spaceId);
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate join

      // Re-fetch permissions in case they change upon joining (optional)
      // final canCreate = await _firestoreService.canCreateEventsInSpace(_spaceId);
      final canCreate = true; // Placeholder

      state = state.copyWith(
        status: SpaceMembershipStatus.joined,
        canCreateEvents: canCreate,
        errorMessage: null, // Clear previous error
      );
      // TODO: Add Haptic Feedback (Confirmation)
    } catch (e) {
      state = state.copyWith(
        status: SpaceMembershipStatus.notJoined, // Revert status on error
        errorMessage: 'Failed to join space',
      );
       // TODO: Add Haptic Feedback (Error)
    }
  }

  Future<void> leaveSpace() async {
     if (state.status == SpaceMembershipStatus.notJoined ||
         state.status == SpaceMembershipStatus.loading) return;

    state = state.copyWith(status: SpaceMembershipStatus.loading);
    try {
      // TODO: Replace with actual leave logic
      // await _firestoreService.leaveSpace(_spaceId);
       await Future.delayed(const Duration(milliseconds: 500)); // Simulate leave

      state = state.copyWith(
        status: SpaceMembershipStatus.notJoined,
        canCreateEvents: false, // Assume leaving revokes creation rights
        errorMessage: null, // Clear previous error
      );
       // TODO: Add Haptic Feedback (Confirmation)
    } catch (e) {
      state = state.copyWith(
        status: SpaceMembershipStatus.joined, // Revert status on error
        errorMessage: 'Failed to leave space',
      );
      // TODO: Add Haptic Feedback (Error)
    }
  }
} 