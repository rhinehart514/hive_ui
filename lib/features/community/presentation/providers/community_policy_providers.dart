import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/community/data/repositories/community_policy_repository_impl.dart';
import 'package:hive_ui/features/community/domain/repositories/community_policy_repository.dart';
import 'package:hive_ui/features/community/domain/entities/community_policy.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Provider for the community policy repository
final communityPolicyRepositoryProvider = Provider<CommunityPolicyRepository>((ref) {
  return CommunityPolicyRepositoryImpl();
});

/// Provider for the current community policy
final currentPolicyProvider = FutureProvider<CommunityPolicy?>((ref) async {
  final repository = ref.watch(communityPolicyRepositoryProvider);
  final result = await repository.getCurrentPolicy();
  return result.fold(
    (failure) => null,
    (policy) => policy,
  );
});

/// Provider for policy updates stream
final policyUpdatesProvider = StreamProvider<CommunityPolicy?>((ref) {
  final repository = ref.watch(communityPolicyRepositoryProvider);
  return repository.policyUpdates().map(
    (result) => result.fold(
      (failure) => null,
      (policy) => policy,
    ),
  );
});

/// Provider for checking if current user has accepted latest policy
final hasPolicyAcceptanceProvider = FutureProvider.family<bool, String>((ref, userId) async {
  final repository = ref.watch(communityPolicyRepositoryProvider);
  final result = await repository.hasUserAcceptedLatestPolicy(userId);
  return result.fold(
    (failure) => false,
    (hasAccepted) => hasAccepted,
  );
});

/// Provider for space-specific policy rules
final spacePolicyRulesProvider = FutureProvider.family<List<PolicyRule>, String>((ref, spaceId) async {
  final repository = ref.watch(communityPolicyRepositoryProvider);
  final result = await repository.getSpacePolicyRules(spaceId);
  return result.fold(
    (failure) => [],
    (rules) => rules,
  );
});

/// Provider for content compliance checking
final contentComplianceProvider = FutureProvider.family<bool, ({String contentId, String contentType, String? spaceId})>((ref, params) async {
  final repository = ref.watch(communityPolicyRepositoryProvider);
  final result = await repository.checkContentCompliance(
    contentId: params.contentId,
    contentType: params.contentType,
    spaceId: params.spaceId,
  );
  return result.fold(
    (failure) => true, // Default to allowing content if check fails
    (isCompliant) => isCompliant,
  );
}); 