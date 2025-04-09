import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/core/widgets/offline_action_status.dart';
import 'package:hive_ui/core/widgets/optimistic_action_builder.dart';
import 'package:hive_ui/features/profile/data/profile_repository.dart' as repo;
import 'package:hive_ui/core/network/offline_action.dart';
import 'package:hive_ui/core/network/offline_queue_manager.dart';
import 'package:hive_ui/core/network/connectivity_service.dart';
import 'package:hive_ui/theme/app_colors.dart';

// Provider to get the current profile
final currentProfileProvider = FutureProvider<repo.UserProfile?>((ref) async {
  final repository = ref.watch(repo.profileRepositoryProvider);
  return repository.getProfile();
});

// Provider for the edit profile controller
final editProfileControllerProvider = StateNotifierProvider.autoDispose<
    EditProfileController, AsyncValue<repo.UserProfile?>>((ref) {
  final repository = ref.watch(repo.profileRepositoryProvider);
  return EditProfileController(repository: repository);
});

// Controller for edit profile
class EditProfileController extends StateNotifier<AsyncValue<repo.UserProfile?>> {
  final repo.ProfileRepository repository;

  EditProfileController({required this.repository})
      : super(const AsyncValue.loading()) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    state = const AsyncValue.loading();
    try {
      final profile = await repository.getProfile();
      state = AsyncValue.data(profile);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    try {
      final currentProfile = state.valueOrNull;
      if (currentProfile == null) {
        throw Exception("Can't update profile: profile not loaded");
      }

      // Immediately update the UI optimistically
      final updatedProfile = currentProfile.copyWith(
        displayName: updates['displayName'],
        bio: updates['bio'],
      );

      // Set state to loading but with the updated data (optimistic update)
      state = AsyncValue.data(updatedProfile);

      // Perform the actual update
      await repository.updateProfile(updates);
    } catch (e) {
      // Revert to previous state and show error
      _loadProfile(); // Reload original state
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

/// Edit Profile Page with offline support
class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _formChanged = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFormValues();
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _initFormValues() {
    final profileState = ref.read(editProfileControllerProvider);
    profileState.whenData((profile) {
      if (profile != null) {
        _displayNameController.text = profile.displayName;
        _bioController.text = profile.bio ?? '';
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final updates = {
      'displayName': _displayNameController.text,
      'bio': _bioController.text,
    };

    try {
      await ref.read(editProfileControllerProvider.notifier).updateProfile(updates);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(editProfileControllerProvider);
    final connectivityStatus = ref.watch(connectivityStatusProvider);
    final pendingActions = ref.watch(pendingOfflineActionsProvider);
    
    // Check if there are pending profile actions
    final hasProfilePendingActions = pendingActions.any((action) => 
      action.resourceType == 'profile' &&
      action.status == OfflineActionStatus.pending
    );
    
    final isOffline = connectivityStatus.maybeWhen(
      data: (result) => result.name == 'none',
      orElse: () => true,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _formChanged ? _submitForm : null,
            child: const Text('Save'),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found'));
          }
          
          return OptimisticActionBuilder<repo.UserProfile>(
            resourceType: 'profile',
            resourceId: profile.id,
            remoteData: profile,
            updateDataBuilder: (currentData, action) {
              final payload = action.payload;
              return currentData.copyWith(
                displayName: payload['displayName'],
                bio: payload['bio'],
              );
            },
            builder: (context, displayData, isPending) {
              return Form(
                key: _formKey,
                onChanged: () {
                  setState(() {
                    _formChanged = true;
                  });
                },
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Offline indicator
                    if (isOffline || isPending || hasProfilePendingActions)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isOffline 
                              ? Colors.red.withOpacity(0.1) 
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isOffline ? Colors.red.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isOffline ? Icons.wifi_off : Icons.sync,
                              color: isOffline ? Colors.red : Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isOffline 
                                    ? 'You are offline. Changes will be saved when you reconnect.' 
                                    : 'Changes are being synced...',
                                style: TextStyle(
                                  color: isOffline ? Colors.red : Colors.orange,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                    // Profile picture
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: displayData.photoUrl != null
                                ? NetworkImage(displayData.photoUrl!)
                                : null,
                            child: displayData.photoUrl == null
                                ? const Icon(Icons.person, size: 50)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.gold,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.black,
                                size: 20,
                              ),
                            ),
                          ),
                          // Pending indicator
                          if (isPending)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: PendingActionBadge(
                                isPending: true,
                                size: 12,
                                color: isOffline ? Colors.red : Colors.orange,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Display name field
                    TextFormField(
                      controller: _displayNameController,
                      decoration: InputDecoration(
                        labelText: 'Display Name',
                        border: const OutlineInputBorder(),
                        suffixIcon: isPending ? const Icon(
                          Icons.sync,
                          color: Colors.orange,
                          size: 16,
                        ) : null,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a display name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Bio field
                    TextFormField(
                      controller: _bioController,
                      decoration: InputDecoration(
                        labelText: 'Bio',
                        border: const OutlineInputBorder(),
                        suffixIcon: isPending ? const Icon(
                          Icons.sync,
                          color: Colors.orange,
                          size: 16,
                        ) : null,
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),
                    
                    // Save button
                    ElevatedButton(
                      onPressed: _formChanged ? _submitForm : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        isOffline ? 'Save for later' : 'Save',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    // Pending status text
                    if (isPending || hasProfilePendingActions)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Center(
                          child: PendingActionText(
                            isPending: true,
                            style: OfflineStatusTextStyle.prominent,
                            pendingText: isOffline
                                ? 'Changes will sync when you reconnect'
                                : 'Changes are syncing...',
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
} 