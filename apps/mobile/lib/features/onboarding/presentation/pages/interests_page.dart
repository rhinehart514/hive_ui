import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/onboarding/state/onboarding_providers.dart';
import 'package:hive_ui/constants/interest_options.dart';
import 'package:flutter/services.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/onboarding_page_scaffold.dart'; // Common scaffold - NOW EXISTS

/// A page that allows users to select their interests.
///
/// This is the fifth page in the onboarding flow and requires users to
/// select at least 5 interests, with a maximum of 10 allowed.
class InterestsPage extends ConsumerStatefulWidget {
  /// Creates an instance of [InterestsPage].
  const InterestsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<InterestsPage> createState() => _InterestsPageState();
}

class _InterestsPageState extends ConsumerState<InterestsPage> {
  final List<String> _allInterests = InterestOptions.options.map((i) => i.contains(':') ? i.split(':')[1].trim() : i).toSet().toList()..sort(); // Get unique, sorted interests
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredInterests = [];
  final FocusNode _searchFocus = FocusNode();
  
  // Categories and their associated interests
  final Map<String, List<String>> _interestCategories = {};
  
  // Which category is expanded in the UI
  String? _expandedCategory;
  
  // Define constants locally
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 12.0;
  static const double spacingLarge = 24.0;
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0);
  static const EdgeInsets contentPadding = EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0);
  static const int minInterests = 5;
  static const int maxInterests = 10;
  
  @override
  void initState() {
    super.initState();
    
    // Group interests by category
    for (var interest in _allInterests) {
      final parts = interest.split(':');
      if (parts.length == 2) {
        final category = parts[0].trim();
        final interestName = parts[1].trim();
        
        if (!_interestCategories.containsKey(category)) {
          _interestCategories[category] = [];
        }
        
        _interestCategories[category]!.add(interestName);
      } else {
        // Handle interests without category
        if (!_interestCategories.containsKey('Other')) {
          _interestCategories['Other'] = [];
        }
        _interestCategories['Other']!.add(interest);
      }
    }
    
    // Set default expanded category
    if (_interestCategories.isNotEmpty) {
      _expandedCategory = _interestCategories.keys.first;
    }
    
    // Initialize filtered interests
    _filteredInterests = List.from(_allInterests);
    _searchController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }
  
  void _onSearchChanged() {
    _filterInterests(_searchController.text);
  }
  
  void _filterInterests(String query) {
    setState(() {
      final searchTerm = query.trim().toLowerCase();
      if (searchTerm.isEmpty) {
        _filteredInterests = List.from(_allInterests);
      } else {
        _filteredInterests = _allInterests
            .where((interest) => interest.toLowerCase().contains(searchTerm))
            .toList();
      }
    });
  }
  
  void _toggleInterest(String interest) {
    final notifier = ref.read(onboardingStateNotifierProvider.notifier);
    final selectedInterests = ref.read(onboardingStateNotifierProvider).interests;
    
    if (selectedInterests.contains(interest)) {
      notifier.removeInterest(interest);
      _triggerLightImpactHaptic();
    } else {
      if (selectedInterests.length < maxInterests) {
        notifier.addInterest(interest);
        _triggerLightImpactHaptic();
      } else {
        _triggerErrorHaptic();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Maximum $maxInterests interests allowed', style: TextStyle(color: AppColors.textPrimary)),
            backgroundColor: AppColors.error.withOpacity(0.8),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
  
  void _toggleCategory(String category) {
    setState(() {
      _expandedCategory = _expandedCategory == category ? null : category;
    });
    HapticFeedback.selectionClick();
  }

  // Placeholder for Haptics
  void _triggerLightImpactHaptic() {
    HapticFeedback.lightImpact();
    debugPrint("HapticFeedbackManager.lightImpact() - Placeholder");
  }
  void _triggerErrorHaptic() {
    HapticFeedback.mediumImpact(); 
    debugPrint("HapticFeedbackManager.error() - Placeholder");
  }

  @override
  Widget build(BuildContext context) {
    final selectedInterests = ref.watch(onboardingStateNotifierProvider.select((s) => s.interests));
    final bool isPageValid = ref.watch(isCurrentPageValidProvider);
    final remainingSelections = minInterests - selectedInterests.length;
    final textTheme = Theme.of(context).textTheme;
    final chipTheme = Theme.of(context).chipTheme;
    final titleStyle = textTheme.headlineMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600);
    final subtitleStyle = textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary);
    final validationStyle = textTheme.bodyLarge?.copyWith(
      color: remainingSelections > 0 ? AppColors.textSecondary : AppColors.gold,
      fontWeight: remainingSelections > 0 ? FontWeight.normal : FontWeight.w600,
    );

    // Use the common scaffold
    return OnboardingPageScaffold(
      title: 'What are you interested in?',
      // Use the dynamically generated validation text as the subtitle
      subtitle: remainingSelections > 0
                ? 'Select at least $remainingSelections more interests'
                : (selectedInterests.length == maxInterests 
                    ? 'Maximum interests selected' 
                    : 'Select up to ${maxInterests - selectedInterests.length} more interests'),
      body: Column(
        // Removed crossAxisAlignment
        children: [
          // Search Field
          TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            style: textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
            decoration: _hiveInputDecoration(
              hintText: 'Search interests...',
              prefixIcon: Icons.search_rounded,
            ),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: spacingLarge),
          
          // Selected interests chips
          if (selectedInterests.isNotEmpty) ...[
            Wrap(
              spacing: AppTheme.spacing8,
              runSpacing: AppTheme.spacing8,
              children: selectedInterests.map((interest) {
                return InputChip(
                  label: Text(interest),
                  backgroundColor: AppColors.gold.withOpacity(0.2),
                  labelStyle: chipTheme.labelStyle?.copyWith(color: AppColors.gold),
                  deleteIconColor: AppColors.gold,
                  onDeleted: () => _toggleInterest(interest),
                  side: chipTheme.side ?? const BorderSide(color: AppColors.gold),
                  shape: chipTheme.shape,
                  padding: chipTheme.padding,
                );
              }).toList(),
            ),
            const SizedBox(height: AppTheme.spacing16),
          ],
          
          // Interest categories and options
          Expanded(
            child: _filteredInterests.isEmpty && _searchController.text.isNotEmpty
                ? Center(
                    child: Text(
                      'No interests found for "${_searchController.text}"',
                      style: subtitleStyle,
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(),
                  )
                : SingleChildScrollView( // Use SingleChildScrollView for the Wrap
                    child: Wrap(
                      spacing: spacingSmall,
                      runSpacing: spacingSmall,
                      children: _filteredInterests.map((interest) {
                        final isSelected = selectedInterests.contains(interest);
                        return _buildHiveToggleChip(
                          label: interest,
                          isSelected: isSelected,
                          onSelected: (_) => _toggleInterest(interest),
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
  
  InputDecoration _hiveInputDecoration({
    required String hintText,
    IconData? prefixIcon,
  }) {
    // Using placeholder styling
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

  // Placeholder for HiveToggleChip
  Widget _buildHiveToggleChip({required String label, required bool isSelected, required Function(bool) onSelected}) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.black : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 14, // SF Pro Text Regular 14pt
      ),
      selectedColor: AppColors.gold,
      backgroundColor: AppColors.dark2,
      shape: StadiumBorder(side: BorderSide(color: isSelected ? AppColors.gold : AppColors.dark3, width: 1.0)),
      padding: const EdgeInsets.symmetric(horizontal: spacingMedium, vertical: spacingSmall),
      showCheckmark: false,
    );
  }
} 