import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/huge_icons.dart';
import 'package:hive_ui/constants/year_options.dart';
import 'package:hive_ui/constants/residence_options.dart';

/// Shows a fullscreen profile editor
void showModernProfileEditor(
  BuildContext context,
  UserProfile profile,
  Function(UserProfile) onProfileUpdated,
) {
  HapticFeedback.mediumImpact();

  Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => ModernProfileEditor(
        profile: profile,
        onProfileUpdated: onProfileUpdated,
      ),
    ),
  );
}

/// A modern profile editor with improved UI
class ModernProfileEditor extends ConsumerStatefulWidget {
  final UserProfile profile;
  final Function(UserProfile) onProfileUpdated;

  const ModernProfileEditor({
    super.key,
    required this.profile,
    required this.onProfileUpdated,
  });

  @override
  ConsumerState<ModernProfileEditor> createState() =>
      _ModernProfileEditorState();
}

class _ModernProfileEditorState extends ConsumerState<ModernProfileEditor> {
  // UI constants
  static const double _borderRadius = 16.0;
  static const double _verticalSpacing = 24.0;
  static const Duration _animationDuration = Duration(milliseconds: 500);
  static const EdgeInsets _contentPadding =
      EdgeInsets.fromLTRB(20, 12, 20, 120);

  // Fields for form state
  late TextEditingController _usernameController;
  String? _selectedYear;
  String? _selectedMajor;
  String? _selectedResidence;

  bool _isProcessing = false;

  // Lists for dropdowns from shared constants
  final List<String> _years = YearOptions.options;
  final List<String> _residences = ResidenceOptions.options;

  @override
  void initState() {
    super.initState();
    _initializeFormValues();
  }

  void _initializeFormValues() {
    _usernameController = TextEditingController(text: widget.profile.username);
    _selectedYear = widget.profile.year;
    _selectedMajor = widget.profile.major;
    _selectedResidence = widget.profile.residence;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      extendBody: true,
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Stack(
          children: [
            _buildMainContent(),
            if (_isProcessing) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      title: Text(
        'Edit Profile',
        style: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        TextButton(
          onPressed: _hasChanges() ? _saveProfile : null,
          child: Text(
            'Save',
            style: GoogleFonts.outfit(
              color: _hasChanges()
                  ? AppColors.gold
                  : AppColors.gold.withOpacity(0.5),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: _contentPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedField(
              index: 0,
              child: _buildUsernameField(),
            ),
            const SizedBox(height: _verticalSpacing),
            _buildAnimatedField(
              index: 1,
              child: _buildYearField(),
            ),
            const SizedBox(height: _verticalSpacing),
            _buildAnimatedField(
              index: 2,
              child: _buildMajorField(),
            ),
            const SizedBox(height: _verticalSpacing),
            _buildAnimatedField(
              index: 3,
              child: _buildResidenceField(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.gold,
        ),
      ),
    );
  }

  Widget _buildUsernameField() {
    return _FormField(
      title: 'Username',
      child: _buildTextField(
        controller: _usernameController,
        hintText: 'Add a username',
        icon: HugeIcons.user,
        maxLength: 30,
      ),
    );
  }

  Widget _buildYearField() {
    return _FormField(
      title: 'Year',
      child: _buildDropdown(
        items: _years,
        selectedValue: _selectedYear,
        onChanged: (value) {
          setState(() {
            _selectedYear = value;
          });
        },
        icon: HugeIcons.strokeRoundedMortarboard02,
      ),
    );
  }

  Widget _buildMajorField() {
    return _FormField(
      title: 'Major (Cannot be changed)',
      child: _buildReadOnlyField(
        value: _selectedMajor ?? 'Not specified',
        icon: HugeIcons.strokeRoundedBook02,
      ),
    );
  }

  Widget _buildResidenceField() {
    return _FormField(
      title: 'Residence',
      child: _buildDropdown(
        items: _residences,
        selectedValue: _selectedResidence,
        onChanged: (value) {
          setState(() {
            _selectedResidence = value;
          });
        },
        icon: HugeIcons.strokeRoundedHouse03,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          color: AppColors.gold,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildAnimatedField({required int index, required Widget child}) {
    // Calculate staggered animation delay
    final staggerDelay = Duration(milliseconds: 100 * index);

    return FutureBuilder(
      future: Future.delayed(staggerDelay, () => true),
      initialData: false,
      builder: (context, snapshot) {
        final shouldAnimate = snapshot.data as bool;

        return AnimatedOpacity(
          duration: _animationDuration,
          opacity: shouldAnimate ? 1.0 : 0.0,
          curve: Curves.easeOutQuad,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 400),
            offset: shouldAnimate ? Offset.zero : const Offset(0, 0.05),
            curve: Curves.easeOutCubic,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    int maxLength = 100,
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    final backgroundColor = Colors.grey[900];

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(_borderRadius),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: AppColors.gold,
            selectionColor: AppColors.gold.withOpacity(0.3),
            selectionHandleColor: AppColors.gold,
          ),
        ),
        child: TextField(
          controller: controller,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
          ),
          maxLength: maxLength,
          maxLines: maxLines,
          cursorColor: AppColors.gold,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.3),
              fontSize: 16,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0),
              child: Icon(
                icon,
                color: Colors.white.withOpacity(0.5),
                size: 20,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            counterStyle: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
            fillColor: Colors.transparent,
            filled: true,
            errorBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required List<String> items,
    required String? selectedValue,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(_borderRadius),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<String>(
            value: selectedValue,
            isExpanded: true,
            dropdownColor: Colors.grey[850],
            borderRadius: BorderRadius.circular(12),
            icon: Icon(
              Icons.arrow_drop_down,
              color: Colors.white.withOpacity(0.5),
            ),
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
            ),
            padding: EdgeInsets.zero,
            hint: _buildDropdownHint(icon),
            items: _buildDropdownItems(items, icon),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownHint(IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.5),
            size: 20,
          ),
          const SizedBox(width: 16),
          Text(
            'Select one',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.3),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildDropdownItems(
      List<String> items, IconData icon) {
    return items.map((String value) {
      return DropdownMenuItem<String>(
        value: value,
        child: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.white.withOpacity(0.5),
                size: 20,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildReadOnlyField({
    required String value,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.6),
        borderRadius: BorderRadius.circular(_borderRadius),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 16,
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Icon(
              icon,
              color: Colors.white.withOpacity(0.3),
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasChanges() {
    return _usernameController.text != widget.profile.username ||
        _selectedYear != widget.profile.year ||
        _selectedResidence != widget.profile.residence;
  }

  Future<void> _saveProfile() async {
    if (!_hasChanges()) return;

    setState(() {
      _isProcessing = true;
    });

    HapticFeedback.mediumImpact();

    try {
      final updatedProfile = widget.profile.copyWith(
        username: _usernameController.text,
        year: _selectedYear,
        residence: _selectedResidence,
        interests: widget.profile.interests,
        updatedAt: DateTime.now(),
      );

      // Simulate network delay for better UX feedback
      await Future.delayed(const Duration(milliseconds: 500));

      await widget.onProfileUpdated(updatedProfile);

      HapticFeedback.lightImpact();

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      HapticFeedback.vibrate();

      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String errorMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Error updating profile: $errorMessage',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

/// A reusable form field with title and child widget
class _FormField extends StatelessWidget {
  final String title;
  final Widget child;

  const _FormField({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            title,
            style: GoogleFonts.outfit(
              color: AppColors.gold,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        child,
      ],
    );
  }
}
