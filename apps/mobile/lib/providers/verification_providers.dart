import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/verification_request.dart';
import 'package:hive_ui/services/verification_service.dart';

/// Provider for verification requests made by the current user
final userVerificationRequestsProvider =
    FutureProvider<List<VerificationRequest>>((ref) async {
  return VerificationService.getUserVerificationRequests();
});

/// Provider for pending verification requests (admin only)
final pendingVerificationRequestsProvider =
    FutureProvider<List<VerificationRequest>>((ref) async {
  return VerificationService.getAllPendingRequests();
});

/// Provider for specific object verification requests
final objectVerificationRequestsProvider =
    FutureProvider.family<List<VerificationRequest>, String>(
        (ref, objectId) async {
  return VerificationService.getObjectVerificationRequests(objectId);
});

/// Provider to check if a user can request verification for an object
final canRequestVerificationProvider =
    FutureProvider.family<bool, ({String objectId, String objectType})>(
        (ref, params) async {
  return VerificationService.canRequestVerification(
      params.objectId, params.objectType);
});

/// Notifier to manage verification request state and actions
class VerificationRequestNotifier extends StateNotifier<AsyncValue<void>> {
  VerificationRequestNotifier() : super(const AsyncValue.data(null));

  /// Submit a new verification request
  Future<bool> submitRequest({
    required String objectId,
    required String objectType,
    required String name,
    String? message,
    VerificationType verificationType = VerificationType.standard,
    Map<String, String>? additionalDocuments,
  }) async {
    state = const AsyncValue.loading();
    try {
      await VerificationService.submitVerificationRequest(
        objectId: objectId,
        objectType: objectType,
        name: name,
        message: message,
        verificationType: verificationType,
        additionalDocuments: additionalDocuments,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  /// Cancel a verification request
  Future<bool> cancelRequest(String requestId) async {
    state = const AsyncValue.loading();
    try {
      final result =
          await VerificationService.cancelVerificationRequest(requestId);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  /// Approve a verification request (admin only)
  Future<bool> approveRequest(String requestId,
      {bool grantVerifiedPlus = false}) async {
    state = const AsyncValue.loading();
    try {
      final result = await VerificationService.approveVerificationRequest(
        requestId,
        grantVerifiedPlus: grantVerifiedPlus,
      );
      state = const AsyncValue.data(null);
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  /// Reject a verification request (admin only)
  Future<bool> rejectRequest(String requestId,
      {String? rejectionReason}) async {
    state = const AsyncValue.loading();
    try {
      final result = await VerificationService.rejectVerificationRequest(
        requestId,
        rejectionReason: rejectionReason,
      );
      state = const AsyncValue.data(null);
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

/// Provider for verification request actions
final verificationRequestNotifierProvider =
    StateNotifierProvider<VerificationRequestNotifier, AsyncValue<void>>((ref) {
  return VerificationRequestNotifier();
});
