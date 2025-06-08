import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/network/offline_queue_manager.dart' as offline;
import 'package:hive_ui/features/profile/domain/entities/user_profile.dart';
import 'package:hive_ui/features/profile/presentation/controllers/profile_controller.dart';
import 'package:hive_ui/features/profile/presentation/widgets/offline_aware_form_components.dart';

/// A form for editing user profile information
class ProfileEditForm extends ConsumerStatefulWidget {
  /// The current user profile
  final UserProfile profile;
  
  /// Callback when form is submitted
  final Function(UserProfile updatedProfile) onSubmit;
  
  /// Constructor
  const ProfileEditForm({
    Key? key,
    required this.profile,
    required this.onSubmit,
  }) : super(key: key);
  
  @override
  ConsumerState<ProfileEditForm> createState() => _ProfileEditFormState();
}

class _ProfileEditFormState extends ConsumerState<ProfileEditForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  String? _selectedInterest;
  bool _isPublic = true;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.displayName);
    _bioController = TextEditingController(text: widget.profile.bio ?? '');
    _locationController = TextEditingController(text: widget.profile.location ?? '');
    _selectedInterest = widget.profile.interests.isNotEmpty == true 
      ? widget.profile.interests.first 
      : null;
    _isPublic = widget.profile.isPublic ?? true;
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(profileControllerProvider).isLoading;
    final pendingChanges = ref.watch(profileHasPendingChangesProvider(widget.profile.id));
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form title with offline status indicator
          Row(
            children: [
              const Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              if (pendingChanges)
                OfflineStatusIndicator(
                  resourceType: 'profile',
                  resourceId: widget.profile.id,
                  syncingLabel: 'Syncing profile...',
                ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Name field
          OfflineAwareFormField(
            resourceType: 'profile',
            resourceId: widget.profile.id,
            formField: TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                hintText: 'Enter your display name',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),
          
          // Bio field
          OfflineAwareFormField(
            resourceType: 'profile',
            resourceId: widget.profile.id,
            formField: TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Bio',
                hintText: 'Tell us about yourself',
              ),
              maxLines: 3,
            ),
          ),
          const SizedBox(height: 16),
          
          // Location field
          OfflineAwareFormField(
            resourceType: 'profile',
            resourceId: widget.profile.id,
            formField: TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'Where are you located?',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Interests dropdown
          DropdownButtonFormField<String>(
            value: _selectedInterest,
            decoration: const InputDecoration(
              labelText: 'Primary Interest',
              hintText: 'Select your main interest',
            ),
            items: const [
              DropdownMenuItem(value: 'technology', child: Text('Technology')),
              DropdownMenuItem(value: 'art', child: Text('Art')),
              DropdownMenuItem(value: 'music', child: Text('Music')),
              DropdownMenuItem(value: 'sports', child: Text('Sports')),
              DropdownMenuItem(value: 'food', child: Text('Food')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedInterest = value;
              });
            },
          ),
          const SizedBox(height: 24),
          
          // Public/Private toggle
          Row(
            children: [
              const Text('Profile Privacy:'),
              const SizedBox(width: 8),
              Switch(
                value: _isPublic,
                onChanged: (value) {
                  setState(() {
                    _isPublic = value;
                  });
                },
              ),
              Text(_isPublic ? 'Public' : 'Private'),
              
              const Spacer(),
              
              // Offline status indicator for privacy setting
              OfflineStatusIndicator(
                resourceType: 'profile',
                resourceId: widget.profile.id,
                offlineLabel: 'Privacy setting will update when online',
                showOnlyWhenOffline: true,
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Submit button
          Center(
            child: OfflineAwareButton(
              resourceType: 'profile',
              resourceId: widget.profile.id,
              onPressed: _submitForm,
              child: isLoading 
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }
  
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final updatedProfile = widget.profile.copyWith(
        displayName: _nameController.text,
        bio: _bioController.text,
        location: _locationController.text,
        interests: _selectedInterest != null ? [_selectedInterest!] : [],
        isPublic: _isPublic,
      );
      
      widget.onSubmit(updatedProfile);
    }
  }
}

/// Provider to check if a profile has pending changes
final profileHasPendingChangesProvider = Provider.family<bool, String>((ref, profileId) {
  final pendingActions = ref.watch(offline.pendingOfflineActionsProvider);
  return pendingActions.any((action) => 
    action.resourceType == 'profile' && action.resourceId == profileId);
}); 