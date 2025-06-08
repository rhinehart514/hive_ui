import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/community/domain/repositories/community_policy_repository.dart';
import 'package:hive_ui/features/community/domain/usecases/handle_rule_violations_usecase.dart';
import 'package:hive_ui/features/community/domain/usecases/manage_community_policy_usecase.dart';

/// Provider for the community policy repository
final communityPolicyRepositoryProvider = Provider<CommunityPolicyRepository>((ref) {
  // This should return the actual implementation once it's available
  throw UnimplementedError('Community policy repository implementation not available yet');
  // Will be implemented as:
  // return CommunityPolicyRepositoryImpl(
  //   firestore: ref.watch(firestoreProvider),
  //   auth: ref.watch(authProvider),
  // );
});

/// Provider for the ManageCommunityPolicyUseCase
final manageCommunityPolicyUseCaseProvider = Provider<ManageCommunityPolicyUseCase>((ref) {
  final repository = ref.watch(communityPolicyRepositoryProvider);
  return ManageCommunityPolicyUseCase(repository);
});

/// Provider for the HandleRuleViolationsUseCase
final handleRuleViolationsUseCaseProvider = Provider<HandleRuleViolationsUseCase>((ref) {
  final repository = ref.watch(communityPolicyRepositoryProvider);
  return HandleRuleViolationsUseCase(repository);
}); 