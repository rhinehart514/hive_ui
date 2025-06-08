import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/onboarding/state/onboarding_providers.dart';
import 'package:hive_ui/constants/major_options.dart';
// Commenting out missing HIVE imports
// import 'package:hive_ui/core/widgets/hive_text_field.dart'; 
// import 'package:hive_ui/core/widgets/hive_primary_button.dart'; 
// import 'package:hive_ui/core/widgets/hive_secondary_button.dart'; 
// import 'package:hive_ui/core/widgets/hive_selectable_list_item.dart'; 
import 'package:hive_ui/theme/app_colors.dart';
// import 'package:hive_ui/theme/app_typography.dart';
// import 'package:hive_ui/theme/app_layout.dart';
// import 'package:hive_ui/core/haptics/haptic_feedback_manager.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/onboarding_page_scaffold.dart'; // Common scaffold - NOW EXISTS
// import '../widgets/hive_alert_dialog.dart'; // Placeholder - Keep commented until created

/// A page that allows users to select their academic major or field of study.
///
/// This is the third page in the onboarding flow and presents a searchable
/// list of majors/fields for the user to choose from.
class MajorPage extends ConsumerStatefulWidget {
  /// Creates an instance of [MajorPage].
  const MajorPage({super.key});

  @override
  ConsumerState<MajorPage> createState() => _MajorPageState();
}

class _MajorPageState extends ConsumerState<MajorPage> {
  final List<String> _majorOptions = MajorOptions.options;
  String? _selectedMajor;
  String _searchQuery = '';
  late List<String> _filteredOptions;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  // Define constants locally for now
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 12.0;
  static const double spacingLarge = 24.0; // Adjusted from 32 for tighter feel
  static const double spacingXLarge = 32.0;
  static const double radiusFull = 999.0;
  static const double radiusDefault = 20.0;
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0);
  static const EdgeInsets contentPadding = EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0);

  @override
  void initState() {
    super.initState();
    _filteredOptions = List.from(_majorOptions);
    _searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(onboardingStateNotifierProvider);
      if (state.major != null && state.major!.isNotEmpty) {
        setState(() {
          _selectedMajor = state.major;
          // If initialized with a custom major, reflect it
          if (_selectedMajor!.startsWith('[CUSTOM]') && !_majorOptions.contains(_selectedMajor)) {
             // Optionally handle display of custom major better
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterOptions(_searchController.text);
  }

  void _filterOptions(String query) {
    setState(() {
      _searchQuery = query.trim().toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredOptions = List.from(_majorOptions);
      } else {
        _filteredOptions = _majorOptions
            .where((option) => option.toLowerCase().contains(_searchQuery))
            .toList();
      }
    });
  }

  // Placeholder for Haptics
  void _triggerSelectionHaptic() {
    HapticFeedback.mediumImpact(); 
    debugPrint("HapticFeedbackManager.selection() - Placeholder");
  }
  void _triggerLightImpactHaptic() {
    HapticFeedback.lightImpact();
    debugPrint("HapticFeedbackManager.lightImpact() - Placeholder");
  }

  void _selectMajor(String major, {bool isCustom = false}) {
    final majorToStore = isCustom ? '[CUSTOM] $major' : major;
    setState(() {
      _selectedMajor = majorToStore;
      _searchController.clear(); // Clear search on selection
      FocusScope.of(context).unfocus(); // Dismiss keyboard
    });

    ref.read(onboardingStateNotifierProvider.notifier).updateMajor(majorToStore);
    _triggerSelectionHaptic();
  }

  void _clearSelection() {
     setState(() {
       _selectedMajor = null;
     });
     ref.read(onboardingStateNotifierProvider.notifier).updateMajor('');
     _triggerLightImpactHaptic();
  }

  InputDecoration _hiveInputDecoration({
    required String hintText,
    IconData? prefixIcon,
  }) {
    // Using placeholder styling from NamePage
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 17),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.textSecondary, size: 20) : null,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: AppColors.dark3, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: AppColors.gold, width: 2.0),
      ),
      filled: true,
      fillColor: AppColors.dark2,
      contentPadding: contentPadding,
    );
  }

  Future<void> _showManualEntryDialog() async {
    final customMajor = await showDialog<String>(
      context: context,
      builder: (context) {
        String inputText = '';
        final TextEditingController dialogController = TextEditingController();
        final textTheme = Theme.of(context).textTheme;
        // Placeholder for HiveAlertDialog
        return AlertDialog(
          backgroundColor: AppColors.dark2, // Use dark2 instead of dark1
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusDefault)),
          title: Text('Enter Your Major', style: textTheme.headlineSmall?.copyWith(color: AppColors.textPrimary)),
          content: TextField(
            controller: dialogController,
            autofocus: true,
            style: textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
            decoration: _hiveInputDecoration(hintText: 'Type your major here...'),
            textCapitalization: TextCapitalization.words,
            onChanged: (value) => inputText = value,
          ),
          actionsPadding: const EdgeInsets.all(spacingMedium),
          actions: [
            // Placeholder for HiveSecondaryButton
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: textTheme.labelLarge?.copyWith(color: AppColors.textSecondary)),
            ),
            // Placeholder for HivePrimaryButton
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusFull)),
                  padding: const EdgeInsets.symmetric(horizontal: spacingLarge, vertical: spacingMedium),
              ),
              onPressed: () {
                Navigator.of(context).pop(inputText.trim());
              },
              child: Text('Submit', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (customMajor != null && customMajor.isNotEmpty) {
      _selectMajor(customMajor, isCustom: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showSearchResults = _searchQuery.isNotEmpty;
    final bool hasSelection = _selectedMajor != null;
    final textTheme = Theme.of(context).textTheme; // For placeholders
    final titleStyle = textTheme.headlineMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600);
    final subtitleStyle = textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary);
    final bodyStyle = textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary);
    final bodyBoldStyle = bodyStyle?.copyWith(fontWeight: FontWeight.bold);
    final buttonTextStyle = textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold);

    // Use the common scaffold
    return OnboardingPageScaffold(
      title: 'What are you studying?',
      subtitle: 'Select your major or field of study.',
      body: Column(
        children: [
          // Search Field
          TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            style: bodyStyle,
            decoration: _hiveInputDecoration(
              hintText: 'Search majors...',
              prefixIcon: Icons.search_rounded,
            ),
            // onChanged handled by listener
          ).animate().fadeIn(duration: 300.ms),

          SizedBox(height: hasSelection || showSearchResults ? spacingMedium : spacingLarge),

          // Display Selected Major (if any)
          if (hasSelection)
            _buildSelectedMajorChip(bodyBoldStyle).animate().fadeIn(duration: 200.ms).scaleXY(begin: 0.95, end: 1.0, duration: 200.ms),

          // Results/List Area
          Expanded(
            child: AnimatedSwitcher(
              duration: 200.ms,
              child: _filteredOptions.isEmpty && _searchQuery.isNotEmpty
                  ? _buildNotFoundState(textTheme, buttonTextStyle)
                  : _buildMajorList(bodyStyle, bodyBoldStyle),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedMajorChip(TextStyle? chipTextStyle) {
    final displayName = _selectedMajor!.startsWith('[CUSTOM]')
        ? _selectedMajor!.substring(9)
        : _selectedMajor!;

    return Container(
      key: const ValueKey('selected_major_chip'),
      margin: const EdgeInsets.only(bottom: spacingMedium), // Add margin below chip
      padding: const EdgeInsets.symmetric(horizontal: spacingMedium, vertical: spacingSmall),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.15),
        borderRadius: BorderRadius.circular(radiusFull),
        border: Border.all(color: AppColors.gold, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.school_rounded, color: AppColors.gold, size: 20),
          const SizedBox(width: spacingSmall),
          Flexible(
            child: Text(
              displayName,
              style: chipTextStyle?.copyWith(color: AppColors.gold) ?? const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: spacingSmall),
          InkWell(
            onTap: _clearSelection,
            radius: 15, // Make tap target larger
            child: const Icon(Icons.close_rounded, color: AppColors.gold, size: 20),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.1, end: 0).fadeIn();
  }

  Widget _buildMajorList(TextStyle? itemStyle, TextStyle? selectedItemStyle) {
    // Placeholder for HiveSelectableListItem
    return ListView.builder(
       key: const ValueKey('major_list'),
       padding: EdgeInsets.zero, // No top padding needed here
       itemCount: _filteredOptions.length,
       itemBuilder: (context, index) {
         final major = _filteredOptions[index];
         final isSelected = major == _selectedMajor;

         return ListTile(
           contentPadding: const EdgeInsets.symmetric(horizontal: spacingSmall, vertical: 0), // Tighter padding
           title: Text(
             major,
             style: isSelected 
                 ? selectedItemStyle?.copyWith(color: AppColors.gold) ?? const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold) 
                 : itemStyle,
           ),
           trailing: isSelected
               ? const Icon(Icons.check_circle_rounded, color: AppColors.gold, size: 20)
               : null,
           onTap: () => _selectMajor(major),
         );
       },
     );
  }

  Widget _buildNotFoundState(TextTheme textTheme, TextStyle? buttonTextStyle) {
    // Placeholder for Buttons
    return Container(
      key: const ValueKey('not_found_state'),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(spacingLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, color: AppColors.textSecondary, size: 48),
          const SizedBox(height: spacingMedium),
          Text(
            'No majors found for "$_searchQuery"',
            style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: spacingXLarge),
          Text(
            'Can\'t find your major?',
            style: textTheme.titleMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: spacingMedium),
          // Placeholder Primary Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.black,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusFull)),
            ),
            onPressed: _showManualEntryDialog,
            child: Text('Enter it manually', style: buttonTextStyle),
          ),
          const SizedBox(height: spacingSmall),
          // Placeholder Secondary Button
          OutlinedButton(
             style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary, // White text
              side: const BorderSide(color: AppColors.dark3, width: 1.5),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusFull)),
            ),
            onPressed: () => _selectMajor('Other/Undeclared'),
            child: Text('Select Other / Undeclared', style: buttonTextStyle),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// Assumptions:
// - HiveTextField, HivePrimaryButton, HiveSecondaryButton, HiveSelectableListItem, HiveAlertDialog exist and follow HIVE styles.
// - AppTypography, AppLayout, HapticFeedbackManager provide necessary styles/constants/functions.
// - OnboardingPageScaffold handles overall layout.
// - Removed alphabetical grouping for simplicity. 