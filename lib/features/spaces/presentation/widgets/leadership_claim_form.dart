import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart' as auth;
import 'package:hive_ui/features/profile/presentation/providers/profile_providers.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/presentation/providers/space_providers.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_repository_provider.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A form for claiming leadership of a space
class LeadershipClaimForm extends ConsumerStatefulWidget {
  /// The ID of the space to claim leadership of
  final String spaceId;
  
  /// Callback triggered when form submission is complete
  final VoidCallback onSubmitComplete;

  /// Constructor
  const LeadershipClaimForm({
    Key? key,
    required this.spaceId,
    required this.onSubmitComplete,
  }) : super(key: key);

  @override
  ConsumerState<LeadershipClaimForm> createState() => _LeadershipClaimFormState();
}

class _LeadershipClaimFormState extends ConsumerState<LeadershipClaimForm> {
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _credentialsController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _reasonController.dispose();
    _credentialsController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    // Validate input
    if (_reasonController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please provide a reason for claiming leadership';
      });
      return;
    }

    if (_credentialsController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please provide your credentials';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final currentUser = ref.read(auth.currentUserProvider);
      final userId = currentUser.id;
      
      // Get user profile
      final userProfileAsync = ref.read(userProfileProvider(userId));
      final userProfile = userProfileAsync.value;
      
      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      // Get the space
      final space = await ref.read(spaceRepositoryProvider).getSpaceById(widget.spaceId);
      
      if (space == null) {
        throw Exception('Space not found');
      }

      // Submit claim
      final result = await ref.read(spaceRepositoryProvider).submitLeadershipClaim(
        spaceId: widget.spaceId,
        userId: userId,
        userName: userProfile.displayName ?? '',
        email: userProfile.email ?? '',
        reason: _reasonController.text.trim(),
        credentials: _credentialsController.text.trim(),
      );

      if (!result) {
        throw Exception('Failed to submit claim');
      }

      // Refresh space data to reflect claim status
      ref.read(spacesProvider.notifier).refreshSpace(widget.spaceId);

      if (mounted) {
        widget.onSubmitComplete();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Error: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spaceAsync = ref.watch(spaceProvider(widget.spaceId));
    
    return spaceAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      ),
      error: (err, stack) => Text(
        'Error loading space: $err',
        style: TextStyle(color: Colors.red.shade300),
      ),
      data: (space) {
        if (space == null) {
          return const Text(
            'Space not found',
            style: TextStyle(color: Colors.red),
          );
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClaimInfo(space),
            const SizedBox(height: 16),
            _buildForm(),
          ],
        );
      },
    );
  }

  Widget _buildClaimInfo(SpaceEntity space) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.gold.withOpacity(0.2),
            radius: 20,
            child: Icon(
              space.icon,
              color: AppColors.gold,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  space.name,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Unclaimed Space',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final currentUser = ref.watch(auth.currentUserProvider);
    final userId = currentUser.id;
    final userProfileAsync = ref.watch(userProfileProvider(userId));
    
    return userProfileAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      ),
      error: (err, stack) => Text(
        'Error loading profile: $err',
        style: TextStyle(color: Colors.red.shade300),
      ),
      data: (profile) {
        if (profile == null) {
          return const Text(
            'User profile not found',
            style: TextStyle(color: Colors.red),
          );
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Claiming as:',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: profile.photoUrl != null 
                        ? NetworkImage(profile.photoUrl!) 
                        : null,
                    backgroundColor: profile.photoUrl == null 
                        ? AppColors.gold.withOpacity(0.2) 
                        : null,
                    radius: 16,
                    child: profile.photoUrl == null 
                        ? const Icon(
                            Icons.person,
                            color: AppColors.gold,
                            size: 16,
                          ) 
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.displayName ?? 'User',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          profile.email ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Why should you be the leader?',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _reasonController,
              style: GoogleFonts.inter(
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: 'Describe your reason for claiming leadership',
                hintStyle: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.5),
                ),
                fillColor: Colors.black.withOpacity(0.2),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.gold,
                  ),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Your credentials',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _credentialsController,
              style: GoogleFonts.inter(
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: 'Provide your position, role or connection to this space',
                hintStyle: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.5),
                ),
                fillColor: Colors.black.withOpacity(0.2),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.gold,
                  ),
                ),
              ),
              maxLines: 2,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.red.shade300,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: AppColors.gold.withOpacity(0.5),
                  disabledForegroundColor: Colors.black.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Submit Claim',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
} 