import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/constants/year_options.dart';
import 'package:hive_ui/constants/residence_options.dart';
import 'package:hive_ui/constants/interest_options.dart';
import 'package:hive_ui/theme/app_text_styles.dart';
import 'package:hive_ui/widgets/common/glass_container.dart';

/// Enhanced profile editor with full glassmorphism styling and modern UX
/// Follows HIVE brand aesthetic guidelines
class EnhancedProfileEditor extends ConsumerStatefulWidget {
  final UserProfile profile;
  final Future<void> Function(UserProfile) onProfileUpdated;

  const EnhancedProfileEditor({
    super.key,
    required this.profile,
    required this.onProfileUpdated,
  });

  @override
  ConsumerState<EnhancedProfileEditor> createState() => _EnhancedProfileEditorState();
}

class _EnhancedProfileEditorState extends ConsumerState<EnhancedProfileEditor> {
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _displayNameController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  
  String? _selectedYear;
  String? _selectedResidence;
  List<String> _selectedInterests = [];
  
  bool _isProcessing = false;
  File? _profileImageFile;
  
  final _formKey = GlobalKey<FormState>();
  
  // For tracking which fields have been changed
  final Map<String, bool> _fieldChanged = {
    'username': false,
    'displayName': false,
    'firstName': false,
    'lastName': false,
    'bio': false,
    'year': false,
    'residence': false,
    'interests': false,
    'profileImage': false,
  };
  
  // Lists for dropdowns from shared constants
  final List<String> _years = YearOptions.options;
  final List<String> _residences = ResidenceOptions.options;
  final List<String> _interestOptions = InterestOptions.options;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with current values
    _usernameController = TextEditingController(text: widget.profile.username);
    _bioController = TextEditingController(text: widget.profile.bio ?? '');
    _displayNameController = TextEditingController(text: widget.profile.displayName);
    _firstNameController = TextEditingController(text: widget.profile.firstName);
    _lastNameController = TextEditingController(text: widget.profile.lastName);
    
    _selectedYear = widget.profile.year;
    _selectedResidence = widget.profile.residence;
    _selectedInterests = widget.profile.interests.toList();
    
    // Add listeners to track changes
    _usernameController.addListener(() => _updateFieldChanged('username'));
    _bioController.addListener(() => _updateFieldChanged('bio'));
    _displayNameController.addListener(() => _updateFieldChanged('displayName'));
    _firstNameController.addListener(() => _updateFieldChanged('firstName'));
    _lastNameController.addListener(() => _updateFieldChanged('lastName'));
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _displayNameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }
  
  void _updateFieldChanged(String field) {
    bool changed = false;
    
    switch (field) {
      case 'username':
        changed = _usernameController.text != widget.profile.username;
        break;
      case 'bio':
        changed = _bioController.text != (widget.profile.bio ?? '');
        break;
      case 'displayName':
        changed = _displayNameController.text != widget.profile.displayName;
        break;
      case 'firstName':
        changed = _firstNameController.text != widget.profile.firstName;
        break;
      case 'lastName':
        changed = _lastNameController.text != widget.profile.lastName;
        break;
      case 'year':
        changed = _selectedYear != widget.profile.year;
        break;
      case 'residence':
        changed = _selectedResidence != widget.profile.residence;
        break;
      case 'interests':
        changed = !_listsEqual(_selectedInterests, widget.profile.interests);
        break;
      case 'profileImage':
        changed = _profileImageFile != null;
        break;
    }
    
    if (_fieldChanged[field] != changed) {
      setState(() {
        _fieldChanged[field] = changed;
      });
    }
  }
  
  bool _listsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }
  
  bool get _hasChanges => _fieldChanged.values.any((changed) => changed);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        title: Text('Edit Profile', style: AppTextStyles.titleLarge),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isProcessing ? null : _saveProfile,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.yellow,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ).copyWith(
                overlayColor: MaterialStateProperty.resolveWith<Color?>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.pressed)) {
                      return AppColors.yellow.withOpacity(0.15);
                    }
                    return null;
                  },
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: AppColors.yellow,
                        strokeWidth: 2,
                      ),
                    )
                  : Text('Save', style: AppTextStyles.labelLarge),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.black,
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 24),
              _buildProfileImageSection(),
              const SizedBox(height: 24),
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildBioSection(),
              const SizedBox(height: 24),
              _buildAcademicInfoSection(),
              const SizedBox(height: 24),
              _buildInterestsSection(),
              const SizedBox(height: 32),
              _buildPrivacySection(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildProfileImageSection() {
    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                image: _profileImageFile != null
                    ? DecorationImage(
                        image: FileImage(_profileImageFile!),
                        fit: BoxFit.cover,
                      )
                    : widget.profile.profileImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(widget.profile.profileImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
              ),
              child: widget.profile.profileImageUrl == null && _profileImageFile == null
                  ? Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white.withOpacity(0.2),
                    )
                  : null,
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.yellow,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.edit, size: 18, color: AppColors.black),
              onPressed: _pickImage,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBasicInfoSection() {
    return GlassContainer(
      blur: 5,
      opacity: 0.1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _displayNameController,
              label: 'Display Name',
              hint: 'How you\'ll appear to others',
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _firstNameController,
                    label: 'First Name',
                    hint: 'First name',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _lastNameController,
                    label: 'Last Name',
                    hint: 'Last name',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _usernameController,
              label: 'Username',
              hint: 'Your unique @username',
              prefixText: '@',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Username is required';
                }
                if (value.contains(' ')) {
                  return 'Username cannot contain spaces';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBioSection() {
    return GlassContainer(
      blur: 5,
      opacity: 0.1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bio',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _bioController,
              label: 'About you',
              hint: 'Tell people a little about yourself',
              maxLines: 4,
              maxLength: 150,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAcademicInfoSection() {
    return GlassContainer(
      blur: 5,
      opacity: 0.1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Academic Information',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Year',
              value: _selectedYear,
              items: _years,
              onChanged: (value) {
                setState(() {
                  _selectedYear = value;
                  _updateFieldChanged('year');
                });
              },
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Residence',
              value: _selectedResidence,
              items: _residences,
              onChanged: (value) {
                setState(() {
                  _selectedResidence = value;
                  _updateFieldChanged('residence');
                });
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInterestsSection() {
    return GlassContainer(
      blur: 5,
      opacity: 0.1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Interests',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Select up to 5 topics you\'re interested in',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _interestOptions.map((interest) {
                final isSelected = _selectedInterests.contains(interest);
                return FilterChip(
                  label: Text(interest),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        if (_selectedInterests.length < 5) {
                          _selectedInterests.add(interest);
                        } else {
                          // Show toast that max 5 interests can be selected
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'You can select up to 5 interests',
                                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                              ),
                              backgroundColor: Colors.black.withOpacity(0.8),
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            ),
                          );
                          return;
                        }
                      } else {
                        _selectedInterests.remove(interest);
                      }
                      _updateFieldChanged('interests');
                    });
                  },
                  selectedColor: AppColors.yellow.withOpacity(0.3),
                  checkmarkColor: AppColors.yellow,
                  backgroundColor: Colors.grey[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.yellow
                          : Colors.white.withOpacity(0.1),
                      width: isSelected ? 1 : 0.5,
                    ),
                  ),
                  labelStyle: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected ? AppColors.yellow : Colors.white,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPrivacySection() {
    return GlassContainer(
      blur: 5,
      opacity: 0.1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Make profile public',
                    style: AppTextStyles.bodyLarge,
                  ),
                ),
                Switch(
                  value: widget.profile.isPublic,
                  onChanged: (value) {
                    // This would need to be handled separately as it's a direct account setting
                    // For now we'll just show a message that this needs to be changed in settings
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Profile privacy can be changed in Account Settings',
                          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                        ),
                        backgroundColor: Colors.black.withOpacity(0.8),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      ),
                    );
                  },
                  activeColor: AppColors.yellow,
                  activeTrackColor: AppColors.yellow.withOpacity(0.3),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'When public, your profile can be discovered by others',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? prefixText,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium,
            prefixText: prefixText,
            prefixStyle: AppTextStyles.bodyLarge,
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.yellow,
                width: 1,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.red[400]!,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.red[400]!,
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          maxLines: maxLines,
          maxLength: maxLength,
          validator: validator,
          onChanged: (_) {},
        ),
      ],
    );
  }
  
  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            onChanged: onChanged,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            dropdownColor: const Color(0xFF1C1C1E),
            style: AppTextStyles.bodyLarge,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
            ),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
  
  Future<void> _pickImage() async {
    HapticFeedback.mediumImpact();
    
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
      maxHeight: 800,
    );
    
    if (pickedFile != null) {
      setState(() {
        _profileImageFile = File(pickedFile.path);
        _fieldChanged['profileImage'] = true;
      });
    }
  }
  
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasChanges) return;

    HapticFeedback.mediumImpact();
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      // Handle display name, first name, last name sync
      final displayName = _displayNameController.text;
      String firstName = _firstNameController.text;
      String lastName = _lastNameController.text;
      
      // If first/last name fields are empty, derive from display name
      if (firstName.isEmpty || lastName.isEmpty) {
        final nameParts = displayName.split(' ');
        if (nameParts.length > 1) {
          firstName = firstName.isEmpty ? nameParts.first : firstName;
          lastName = lastName.isEmpty ? nameParts.last : lastName;
        } else {
          firstName = firstName.isEmpty ? displayName : firstName;
          lastName = lastName.isEmpty ? '' : lastName;
        }
      }
      
      final updatedProfile = widget.profile.copyWith(
        username: _usernameController.text,
        displayName: displayName,
        firstName: firstName,
        lastName: lastName,
        bio: _bioController.text.isEmpty ? null : _bioController.text,
        year: _selectedYear,
        residence: _selectedResidence,
        interests: _selectedInterests,
        tempProfileImageFile: _profileImageFile,
        updatedAt: DateTime.now(),
      );
      
      // Simulate network delay for better UX feedback
      await Future.delayed(const Duration(milliseconds: 500));
      
      await widget.onProfileUpdated(updatedProfile);
      
      if (mounted) {
        HapticFeedback.lightImpact();
        Navigator.of(context).pop();
      }
    } catch (e) {
      HapticFeedback.vibrate();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error updating profile: ${e.toString()}',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}

/// A reusable function to show the enhanced profile editor
void showEnhancedProfileEditor(
  BuildContext context,
  UserProfile profile,
  Future<void> Function(UserProfile) onProfileUpdated,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.6),
    enableDrag: true,
    builder: (context) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: FractionallySizedBox(
          heightFactor: 0.9,
          child: EnhancedProfileEditor(
            profile: profile,
            onProfileUpdated: onProfileUpdated,
          ),
        ),
      );
    },
  );
} 