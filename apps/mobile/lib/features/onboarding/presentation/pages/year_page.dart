import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/onboarding/state/onboarding_providers.dart';
import 'package:hive_ui/constants/year_options.dart';
// import 'package:hive_ui/core/widgets/hive_selectable_card.dart'; // Assume or create
import 'package:hive_ui/theme/app_colors.dart';
// import 'package:hive_ui/theme/app_typography.dart'; // Use HIVE Typography
// import 'package:hive_ui/theme/app_layout.dart'; // Use HIVE Layout
// import 'package:hive_ui/core/haptics/haptic_feedback_manager.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:flutter_animate/flutter_animate.dart'; // Use animate extension
import '../widgets/onboarding_page_scaffold.dart'; // Common scaffold - NOW EXISTS

/// A page that allows users to select their academic year.
///
/// Presents a list of academic years using HIVE styled selectable cards.
class YearPage extends ConsumerStatefulWidget {
  /// Creates an instance of [YearPage].
  const YearPage({super.key});

  @override
  ConsumerState<YearPage> createState() => _YearPageState();
}

class _YearPageState extends ConsumerState<YearPage> {
  final List<String> _yearOptions = YearOptions.options;

  String? _selectedYear;

  // Define constants locally for now
  static const double spacingMedium = 12.0;
  static const double spacingSmall = 8.0;
  static const double spacingLarge = 32.0;
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(onboardingStateNotifierProvider);
      if (state.year != null && state.year!.isNotEmpty) {
        setState(() {
          _selectedYear = state.year;
        });
      }
    });
  }

  // Placeholder for Haptics
  void _triggerSelectionHaptic() {
    HapticFeedback.mediumImpact(); // Using standard Flutter haptics for now
    debugPrint("HapticFeedbackManager.selection() - Placeholder");
  }

  void _selectYear(String year) {
    final bool wasAlreadySelected = _selectedYear == year;

    setState(() {
      if (wasAlreadySelected) {
        _selectedYear = null;
      } else {
        _selectedYear = year;
      }
    });

    if (!wasAlreadySelected) {
      ref.read(onboardingStateNotifierProvider.notifier).updateYear(year);
      _triggerSelectionHaptic();
    } else {
      // Clear the year if deselected
      ref.read(onboardingStateNotifierProvider.notifier).updateYear('');
    }
  }

  Widget _buildHiveSelectableCard({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    // Simulating HiveSelectableCard with a styled Card
    return Card(
      elevation: isSelected ? 4 : 2,
      color: isSelected ? AppColors.gold.withOpacity(0.15) : AppColors.dark2, // Match brand_aesthetic card surface
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0), // HIVE standard radius
        side: BorderSide(
          color: isSelected ? AppColors.gold : AppColors.dark3, // Gold border when selected
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0), // Standard padding
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                text,
                style: TextStyle( // Placeholder style
                  fontSize: 17, // SF Pro Text Regular 17pt
                  fontWeight: FontWeight.w500,
                  color: isSelected ? AppColors.gold : AppColors.textPrimary,
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
    // Using Theme.of(context).textTheme for placeholders
    final textTheme = Theme.of(context).textTheme;
    final titleStyle = textTheme.headlineMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600); // SF Pro Display Medium 28pt
    final subtitleStyle = textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary); // SF Pro Text Regular 17pt

    // Use the common scaffold
    return OnboardingPageScaffold(
      title: 'What year are you in?',
      subtitle: 'Select your current academic year.',
      body: ListView.separated(
        padding: EdgeInsets.zero, // Padding handled by scaffold
        itemCount: _yearOptions.length,
        separatorBuilder: (context, index) => const SizedBox(height: spacingMedium),
        itemBuilder: (context, index) {
          final year = _yearOptions[index];
          final isSelected = year == _selectedYear;

          return _buildHiveSelectableCard(
            text: year,
            isSelected: isSelected,
            onTap: () => _selectYear(year),
          )
          .animate()
          .fadeIn(delay: (100 * index).ms, duration: 300.ms)
          .slideY(begin: 0.2, end: 0, duration: 300.ms, curve: Curves.easeOut);
        },
      ),
    );
  }
} 