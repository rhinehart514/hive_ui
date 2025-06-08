import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/widgets/common/role_restricted_feature.dart';
import 'package:hive_ui/features/profile/presentation/providers/profile_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A page for creating a new space, with role-based access control
class CreateSpacePage extends ConsumerWidget {
  /// Constructor
  const CreateSpacePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get current user's verification status
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final currentUserAsyncValue = ref.watch(userProfileProvider(currentUserId ?? ''));
    
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Create Space',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: currentUserAsyncValue.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.gold,
          ),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Error loading profile: $err',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text(
                'User profile not found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          
          final verificationStatus = user.isVerifiedPlus
              ? VerificationStatus.verifiedPlus
              : user.isVerified
                  ? VerificationStatus.verified
                  : VerificationStatus.none;
          
          // If user is verified, show the create space form
          if (user.isVerified || user.isVerifiedPlus) {
            return _buildCreateSpaceForm(context);
          }
          
          // If user is not verified, show the restricted feature
          return _buildRestrictedView(context, verificationStatus);
        },
      ),
    );
  }
  
  /// Build the create space form for verified users
  Widget _buildCreateSpaceForm(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create a New Space',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a space to bring people together around shared interests, clubs, or events.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),
          
          // Space name field
          Text(
            'Space Name',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            decoration: InputDecoration(
              hintText: 'Enter space name',
              hintStyle: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.5),
              ),
              fillColor: Colors.black.withOpacity(0.3),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.gold,
                ),
              ),
            ),
            style: GoogleFonts.inter(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          
          // Space description field
          Text(
            'Description',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            decoration: InputDecoration(
              hintText: 'Describe your space',
              hintStyle: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.5),
              ),
              fillColor: Colors.black.withOpacity(0.3),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.gold,
                ),
              ),
            ),
            style: GoogleFonts.inter(
              color: Colors.white,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          
          // Space privacy setting
          Text(
            'Privacy',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: 'public',
                dropdownColor: Colors.black,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                isExpanded: true,
                items: [
                  DropdownMenuItem(
                    value: 'public',
                    child: Text(
                      'Public (Anyone can join)',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'private',
                    child: Text(
                      'Private (Invitation only)',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  // Handle privacy change
                },
              ),
            ),
          ),
          const SizedBox(height: 40),
          
          // Create button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                // Handle space creation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Space creation would happen here'),
                    backgroundColor: AppColors.dark,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Create Space',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build the restricted view for unverified users
  Widget _buildRestrictedView(BuildContext context, VerificationStatus status) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon indicating restriction
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.groups_outlined,
                color: AppColors.gold,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            
            // Title and explanation
            Text(
              'Create Your Own Space',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Spaces let you bring people together around shared interests, organizations, or events.',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            // Role restricted component
            RoleRestrictedFeature(
              currentStatus: status,
              requiredStatus: VerificationStatus.verified,
              featureName: 'Space Creation',
              featureDescription: 
                  'Creating spaces requires verification to ensure community quality and prevent misuse. '
                  'Verify your account to start building communities.',
              featureIcon: Icons.groups,
            ),
          ],
        ),
      ),
    );
  }
} 