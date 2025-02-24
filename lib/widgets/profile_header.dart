import 'package:flutter/material.dart';
import 'package:hive_ui/theme.dart';
import 'hexagon_avatar.dart';
import 'profile_setup_flow.dart';

class ProfileHeader extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String? classLevel;
  final String? fieldOfStudy;
  final String? residentialStatus;
  final ImageProvider? profileImage;
  final VoidCallback? onEditProfile;
  final bool isEditing;
  final Function(String firstName, String lastName)? onNameSubmitted;
  final Function(String classLevel)? onClassLevelSelected;
  final Function(String fieldOfStudy)? onFieldOfStudySelected;
  final Function(String residence)? onResidenceSelected;

  const ProfileHeader({
    super.key,
    required this.firstName,
    required this.lastName,
    this.classLevel,
    this.fieldOfStudy,
    this.residentialStatus,
    this.profileImage,
    this.onEditProfile,
    this.isEditing = false,
    this.onNameSubmitted,
    this.onClassLevelSelected,
    this.onFieldOfStudySelected,
    this.onResidenceSelected,
  });

  bool get isProfileComplete => 
    classLevel != null && 
    fieldOfStudy != null && 
    residentialStatus != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isEditing && !isProfileComplete)
            ProfileSetupFlow(
              initialFirstName: firstName,
              initialLastName: lastName,
              initialClassLevel: classLevel,
              initialFieldOfStudy: fieldOfStudy,
              initialResidence: residentialStatus,
              onNameSubmitted: onNameSubmitted ?? (_, __) {},
              onClassLevelSelected: onClassLevelSelected ?? (_) {},
              onFieldOfStudySelected: onFieldOfStudySelected ?? (_) {},
              onResidenceSelected: onResidenceSelected ?? (_) {},
            )
          else
            _buildProfileInfo(),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            HexagonAvatar(
              size: 80,
              image: profileImage,
              onTap: isEditing ? onEditProfile : null,
              isEditing: isEditing,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$firstName $lastName',
                    style: AppTextStyle.headlineLarge.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (!isProfileComplete) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Complete your profile to unlock features',
                      style: AppTextStyle.bodyMedium.copyWith(
                        color: AppColors.gold.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isEditing)
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: onEditProfile,
              ),
          ],
        ),
        const SizedBox(height: 32),
        _buildRequiredBadges(),
      ],
    );
  }

  Widget _buildRequiredBadges() {
    return Row(
      children: [
        Expanded(
          child: _buildBadge(
            icon: Icons.school_outlined,
            label: 'Class Level',
            value: classLevel,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBadge(
            icon: Icons.psychology_outlined,
            label: 'Field of Study',
            value: fieldOfStudy,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBadge(
            icon: Icons.home_outlined,
            label: 'Residence',
            value: residentialStatus,
          ),
        ),
      ],
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    String? value,
  }) {
    final isComplete = value != null;
    final color = isComplete ? Colors.white : AppColors.gold;
    final opacity = isComplete ? 0.7 : 0.5;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color.withOpacity(opacity),
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyle.bodyMedium.copyWith(
              color: color.withOpacity(opacity),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (isComplete) ...[
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTextStyle.bodyMedium.copyWith(
                color: color.withOpacity(opacity),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
} 