import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/constants/year_options.dart';
import 'package:hive_ui/constants/residence_options.dart';
import 'package:hive_ui/constants/interest_options.dart';

/// An inline editor for profile fields
/// Allows editing fields directly in the profile page without navigating to a new screen
class InlineProfileEditor extends ConsumerStatefulWidget {
  final UserProfile profile;
  final void Function(UserProfile) onProfileUpdated;

  const InlineProfileEditor({
    super.key,
    required this.profile,
    required this.onProfileUpdated,
  });

  @override
  ConsumerState<InlineProfileEditor> createState() =>
      _InlineProfileEditorState();
}

class _InlineProfileEditorState extends ConsumerState<InlineProfileEditor> {
  late TextEditingController _usernameController;
  late TextEditingController _bioController;

  // Define dropdown values
  String? _selectedYear;
  String? _selectedMajor;
  String? _selectedResidence;
  List<String> _selectedInterests = [];

  bool _isProcessing = false;

  // For tracking which fields have been changed
  final Map<String, bool> _fieldChanged = {
    'username': false,
    'year': false,
    'residence': false,
    'bio': false,
    'interests': false,
    // Removed 'major' since it's locked
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
    _selectedYear = widget.profile.year;
    _selectedMajor = widget.profile.major;
    _selectedResidence = widget.profile.residence;
    _selectedInterests = widget.profile.interests?.toList() ?? [];

    // Add listeners to track changes
    _usernameController.addListener(() => _updateFieldChanged('username'));
    _bioController.addListener(() => _updateFieldChanged('bio'));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // Track which fields have been changed
  void _updateFieldChanged(String field) {
    switch (field) {
      case 'username':
        setState(() {
          _fieldChanged[field] =
              _usernameController.text != widget.profile.username;
        });
        break;
      case 'year':
        setState(() {
          _fieldChanged[field] = _selectedYear != widget.profile.year;
        });
        break;
      case 'residence':
        setState(() {
          _fieldChanged[field] = _selectedResidence != widget.profile.residence;
        });
        break;
      case 'bio':
        setState(() {
          _fieldChanged[field] =
              _bioController.text != (widget.profile.bio ?? '');
        });
        break;
      case 'interests':
        setState(() {
          final currentInterests = widget.profile.interests ?? [];
          // Check if lists have different lengths or different items
          _fieldChanged[field] =
              currentInterests.length != _selectedInterests.length ||
                  !currentInterests.every(_selectedInterests.contains);
        });
        break;
      // Removed case for 'major' since it's locked
    }
  }

  // Check if any fields have been changed
  bool get _hasChanges => _fieldChanged.values.any((changed) => changed);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.black, // Updated to match brand
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.gold.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Profile',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Update your profile information',
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Username field
            _buildTextField(
              controller: _usernameController,
              label: 'Username',
              isChanged: _fieldChanged['username'] ?? false,
              maxLength: 30,
            ),
            const SizedBox(height: 16),

            // Bio field
            _buildTextField(
              controller: _bioController,
              label: 'Bio',
              isChanged: _fieldChanged['bio'] ?? false,
              maxLength: 150,
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Year dropdown
            _buildDropdown(
              label: 'Year',
              value: _selectedYear,
              items: _years
                  .map((year) => DropdownMenuItem(
                        value: year,
                        child: Text(year),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedYear = value;
                  _updateFieldChanged('year');
                });
              },
              isChanged: _fieldChanged['year'] ?? false,
            ),
            const SizedBox(height: 16),

            // Major field (read-only)
            _buildReadOnlyField(
              label: 'Major',
              value: _selectedMajor ?? 'Not specified',
            ),
            const SizedBox(height: 16),

            // Residence dropdown
            _buildDropdown(
              label: 'Residence',
              value: _selectedResidence,
              items: _residences
                  .map((residence) => DropdownMenuItem(
                        value: residence,
                        child: Text(residence),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedResidence = value;
                  _updateFieldChanged('residence');
                });
              },
              isChanged: _fieldChanged['residence'] ?? false,
            ),
            const SizedBox(height: 24),

            // Interests/tags section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Interests',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInterestsSelector(),
              ],
            ),
            const SizedBox(height: 24),

            // Action buttons
            SafeArea(
              child: Row(
                children: [
                  // Cancel button
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white.withOpacity(0.7),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Save button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed:
                          _hasChanges && !_isProcessing ? _saveProfile : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            )
                          : Text(
                              'Save Changes',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build a read-only field for displaying locked values
  Widget _buildReadOnlyField({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock,
                    size: 12,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Locked',
                    style: GoogleFonts.outfit(
                      color: Colors.grey[400],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[700]!,
              width: 1,
            ),
          ),
          child: Text(
            value,
            style: GoogleFonts.outfit(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  // Build a text field with label
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isChanged = false,
    int? maxLength,
    int? maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isChanged ? AppColors.gold : Colors.grey[800]!,
              width: isChanged ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            maxLength: maxLength,
            maxLines: maxLines,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: InputBorder.none,
              counterText: maxLength != null
                  ? '${controller.text.length}/$maxLength'
                  : null,
              counterStyle: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
              hintText: 'Enter your $label',
              hintStyle: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.3),
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Build a dropdown field with consistent styling
  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    required bool isChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isChanged) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Modified',
                  style: GoogleFonts.outfit(
                    color: AppColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isChanged ? AppColors.gold : Colors.transparent,
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: items,
              onChanged: onChanged,
              dropdownColor: Colors.grey[900],
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Add interests/tags selector widget
  Widget _buildInterestsSelector() {
    return Wrap(
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
                _selectedInterests.add(interest);
              } else {
                _selectedInterests.remove(interest);
              }
              _updateFieldChanged('interests');
            });
          },
          backgroundColor: Colors.grey[800],
          selectedColor: AppColors.gold,
          checkmarkColor: Colors.black,
          labelStyle: GoogleFonts.inter(
            color: isSelected ? Colors.black : Colors.white,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      }).toList(),
    );
  }

  // Save changes to the profile
  void _saveProfile() {
    if (!_hasChanges) return;

    setState(() {
      _isProcessing = true;
    });

    // Create updated profile
    final updatedProfile = widget.profile.copyWith(
      username: _usernameController.text,
      bio: _bioController.text.isEmpty ? null : _bioController.text,
      year: _selectedYear,
      residence: _selectedResidence,
      interests: _selectedInterests,
      updatedAt: DateTime.now(),
    );

    widget.onProfileUpdated(updatedProfile);
  }
}

/// Shows an inline profile editor dialog
void showInlineProfileEditor(
  BuildContext context,
  UserProfile profile,
  void Function(UserProfile) onProfileUpdated,
) {
  showDialog(
    context: context,
    barrierDismissible: true, // Allow dismissing by tapping outside
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: InlineProfileEditor(
          profile: profile,
          onProfileUpdated: (updatedProfile) {
            // Close the dialog
            Navigator.of(context).pop();
            // Trigger callback
            onProfileUpdated(updatedProfile);
          },
        ),
      );
    },
  );
}
