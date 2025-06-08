import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/onboarding/state/onboarding_providers.dart';
import 'package:hive_ui/constants/residence_options.dart';
// import 'package:hive_ui/core/widgets/hive_selectable_card.dart'; // Placeholder
import 'package:hive_ui/theme/app_colors.dart';
// import 'package:hive_ui/theme/app_typography.dart';
// import 'package:hive_ui/theme/app_layout.dart';
// import 'package:hive_ui/core/haptics/haptic_feedback_manager.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/onboarding_page_scaffold.dart'; // Common scaffold - NOW EXISTS

/// A page that allows users to select their residence type.
///
/// This is the fourth page in the onboarding flow and collects information
/// about where the user lives.
class ResidencePage extends ConsumerStatefulWidget {
  /// Creates an instance of [ResidencePage].
  const ResidencePage({super.key});

  @override
  ConsumerState<ResidencePage> createState() => _ResidencePageState();
}

class _ResidencePageState extends ConsumerState<ResidencePage> {
  final List<String> _residenceOptions = ResidenceOptions.options;
  String? _selectedResidence;
  String _searchQuery = '';
  late List<String> _filteredOptions;
  final TextEditingController _searchController = TextEditingController();

  // Define constants locally for now
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 12.0;
  static const double spacingLarge = 24.0;
  static const double radiusDefault = 20.0;
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0);
  static const EdgeInsets contentPadding = EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0);

  @override
  void initState() {
    super.initState();
    _filteredOptions = List.from(_residenceOptions);
    _searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(onboardingStateNotifierProvider);
      if (state.residenceType != null && state.residenceType!.isNotEmpty) {
        setState(() {
          _selectedResidence = state.residenceType;
        });
      }
    });
  }

   @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterOptions(_searchController.text);
  }

  void _filterOptions(String query) {
    setState(() {
      _searchQuery = query.trim().toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredOptions = List.from(_residenceOptions);
      } else {
        _filteredOptions = _residenceOptions
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

  void _selectResidence(String residence) {
    final wasAlreadySelected = _selectedResidence == residence;
    setState(() {
      _selectedResidence = residence;
      _searchController.clear();
      FocusScope.of(context).unfocus();
    });

    if (!wasAlreadySelected) { // Only update and navigate if it wasn't already selected
      ref.read(onboardingStateNotifierProvider.notifier).updateResidence(residence);
      _triggerSelectionHaptic();
    }
  }
  
  InputDecoration _hiveInputDecoration({
    required String hintText,
    IconData? prefixIcon,
  }) {
    // Using placeholder styling from NamePage/MajorPage
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

  // Placeholder for HiveSelectableCard
  Widget _buildHiveSelectableCard({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: isSelected ? 4 : 2,
      color: isSelected ? AppColors.gold.withOpacity(0.15) : AppColors.dark2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusDefault),
        side: BorderSide(
          color: isSelected ? AppColors.gold : AppColors.dark3,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radiusDefault),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded( // Allow text to wrap
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? AppColors.gold : AppColors.textPrimary,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.gold,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme; // For placeholders
    final titleStyle = textTheme.headlineMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600);
    final subtitleStyle = textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary);
    final bodyStyle = textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary);

    // Use the common scaffold
    return OnboardingPageScaffold(
      title: 'Where do you live?',
      subtitle: 'Select your residence type.',
      body: Column(
        children: [
          // Optional Search Field (Can be removed if not needed for residences)
          TextField(
            controller: _searchController,
            style: bodyStyle,
            decoration: _hiveInputDecoration(
              hintText: 'Search residence types...',
              prefixIcon: Icons.search_rounded,
            ),
            // onChanged handled by listener
          ),
          const SizedBox(height: spacingLarge),

          // Residence options list
          Expanded(
            child: AnimatedSwitcher(
              duration: 200.ms,
              child: _filteredOptions.isEmpty && _searchQuery.isNotEmpty
                ? Center(
                    key: const ValueKey('residence_not_found'),
                    child: Text(
                      'No residence types found for "$_searchQuery"',
                      style: subtitleStyle,
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(),
                  )
                : ListView.separated(
                    key: const ValueKey('residence_list'),
                    padding: EdgeInsets.zero,
                    itemCount: _filteredOptions.length,
                    separatorBuilder: (context, index) => const SizedBox(height: spacingMedium),
                    itemBuilder: (context, index) {
                      final residence = _filteredOptions[index];
                      final isSelected = residence == _selectedResidence;

                      return _buildHiveSelectableCard(
                        text: residence,
                        isSelected: isSelected,
                        onTap: () => _selectResidence(residence),
                      )
                      .animate()
                      .fadeIn(delay: (80 * index).ms, duration: 300.ms)
                      .slideY(begin: 0.1, end: 0, duration: 300.ms, curve: Curves.easeOut);
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }
} 