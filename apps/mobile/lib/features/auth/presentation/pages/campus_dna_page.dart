import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/core/providers/auth_provider.dart';
import 'package:hive_ui/features/auth/providers/onboarding_providers.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/services/analytics_service.dart';
import 'package:hive_ui/theme/app_layout.dart';
import 'package:hive_ui/theme/dark_surface.dart';
import 'package:hive_ui/utils/feedback_util.dart';
import 'package:flutter_animate/flutter_animate.dart';
// For firstWhereOrNull
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:hive_ui/core/navigation/routes.dart';

/// The Campus DNA page collects detailed profile information from the user.
///
/// This page collects Year, Major, Residence, and Interests.
/// It's shown when the user attempts to create content for the first time.
class CampusDnaPage extends ConsumerStatefulWidget {
  const CampusDnaPage({Key? key}) : super(key: key);

  @override
  ConsumerState<CampusDnaPage> createState() => _CampusDnaPageState();
}

class _CampusDnaPageState extends ConsumerState<CampusDnaPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Current step in the multi-step form
  int _currentStep = 0;
  final int _totalSteps = 5; // Updated to 5 to include Friday Night Vibe
  
  // Form values
  String? _selectedYear;
  String? _selectedMajor;
  String? _selectedResidence;
  final Set<String> _selectedInterests = {};
  final Set<String> _selectedVibes = {};
  String? _selectedFridayVibe;
  
  // Loading state
  bool _isSubmitting = false;
  String? _errorMessage;
  
  // Options for dropdowns
  final List<String> _yearOptions = ['Freshman', 'Sophomore', 'Junior', 'Senior', 'Graduate'];
  final List<String> _majorOptions = [
    'Computer Science', 
    'Engineering', 
    'Business', 
    'Arts', 
    'Sciences',
    'Humanities',
    'Social Sciences',
    'Medicine',
    'Law',
    'Undecided',
    'Other'
  ];
  final List<String> _residenceOptions = [
    'On-Campus Housing',
    'Off-Campus Apartment',
    'Greek Life Housing',
    'Commuter',
    'Other'
  ];
  
  // Sample interests - in a real app, these would be dynamically loaded
  final List<String> _interestOptions = [
    'Sports', 
    'Music', 
    'Art', 
    'Technology', 
    'Gaming',
    'Movies',
    'Books',
    'Fitness',
    'Food',
    'Travel',
    'Fashion',
    'Photography',
    'Dance',
    'Volunteering',
    'Politics'
  ];

  // Friday Night Vibes
  final List<String> _fridayVibeOptions = [
    'House Party',
    'Club Night',
    'Movie Marathon',
    'Game Night',
    'Study Session',
    'Dinner with Friends',
    'Concert or Show',
    'Sports Event',
    'Netflix and Chill',
    'Exploring the City'
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final onboardingState = ref.read(onboardingControllerProvider);
    
    // Pre-fill with existing data if available
    if (onboardingState.selectedYear != null) {
      _selectedYear = onboardingState.selectedYear;
    }
    
    if (onboardingState.selectedMajor != null) {
      _selectedMajor = onboardingState.selectedMajor;
    }
    
    if (onboardingState.selectedResidence != null) {
      _selectedResidence = onboardingState.selectedResidence;
    }
    
    if (onboardingState.selectedInterests.isNotEmpty) {
      _selectedInterests.addAll(onboardingState.selectedInterests);
    }

    // For Friday Night Vibe, we'll check a custom field in the future
    // This is a placeholder for now
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0: // Year selection
        return _selectedYear != null;
      case 1: // Major selection
        return _selectedMajor != null;
      case 2: // Residence selection
        return _selectedResidence != null;
      case 3: // Interests selection
        return _selectedInterests.isNotEmpty;
      case 4: // Friday Night Vibe
        return _selectedFridayVibe != null;
      default:
        return false;
    }
  }

  void _goToNextStep() {
    if (!_canProceedToNextStep()) return;
    
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      HapticFeedback.lightImpact();
    } else {
      _submitCampusDna();
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      HapticFeedback.lightImpact();
    }
  }

  void _toggleSelection(String item, Set<String> selectionSet) {
    FeedbackUtil.selection();
    setState(() {
      if (selectionSet.contains(item)) {
        selectionSet.remove(item);
      } else {
        selectionSet.add(item);
      }
    });
  }

  Future<void> _submitCampusDna() async {
    if (_selectedMajor == null || _selectedInterests.isEmpty || _selectedVibes.isEmpty) {
      FeedbackUtil.showToast(context: context, message: 'Please select at least one option for each category.', isError: true);
      FeedbackUtil.error();
      return;
    }

    setState(() => _isSubmitting = true);
    FeedbackUtil.success(); // Use success haptic for submission start

    try {
      final onboardingController = ref.read(onboardingControllerProvider.notifier);
      onboardingController.updateSelectedYear(_selectedYear!);
      onboardingController.updateSelectedMajor(_selectedMajor!);
      onboardingController.updateSelectedResidence(_selectedResidence!);
      onboardingController.updateSelectedInterests(_selectedInterests.toList());
      // onboardingController.updateSelectedVibes(_selectedVibes.toList()); // Add when state supports it

      final userId = ref.read(currentUserIdProvider);
      AnalyticsService.logEvent('campus_dna_completed', parameters: {
        'user_id': userId ?? 'unknown',
        'year': _selectedYear,
        'major': _selectedMajor,
        'residence': _selectedResidence,
        'interests_count': _selectedInterests.length,
        'vibes_count': _selectedVibes.length,
      });

      await Future.delayed(500.ms); // Simulate save
      if (mounted) {
        // Set onboarding completed flag (important!)
        await UserPreferencesService.setOnboardingCompleted(true); 
        // Navigate to home after completion
        context.go(AppRoutes.home);
      }

    } catch (e) {
      if (mounted) {
        FeedbackUtil.showToast(context: context, message: 'Failed to save DNA. Please try again.', isError: true);
        FeedbackUtil.error();
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return DarkSurface(
      surfaceType: SurfaceType.canvas,
      withGrainTexture: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent, elevation: 0,
          title: Text('Your Campus DNA', style: textTheme.titleMedium),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: AppLayout.pagePadding.copyWith(bottom: AppLayout.spacingXLarge * 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What makes you... You?',
                style: textTheme.headlineMedium?.copyWith(color: AppColors.textPrimary),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: AppLayout.spacingSmall),
              Text(
                'Select your major, interests, and social vibes.',
                style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
              
              const SizedBox(height: AppLayout.spacingXLarge),
              _buildSectionTitle('Major / Field of Study', textTheme),
              _buildMajorSelector(),
              
              const SizedBox(height: AppLayout.spacingLarge),
              _buildSectionTitle('Interests (Choose a few)', textTheme),
              _buildChipSelector(_interestOptions, _selectedInterests, AppColors.info.withOpacity(0.8)),
              
              const SizedBox(height: AppLayout.spacingLarge),
              _buildSectionTitle('Typical Friday Night Vibe?', textTheme),
              _buildChipSelector(_fridayVibeOptions, _selectedVibes, AppColors.success.withOpacity(0.8)),
              
              const SizedBox(height: AppLayout.spacingXLarge * 2),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _isSubmitting ? null : _submitCampusDna,
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.black,
          label: _isSubmitting
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.black, strokeWidth: 2.5))
              : Text('Save & Enter HIVE', style: textTheme.titleMedium?.copyWith(color: AppColors.black, fontWeight: FontWeight.bold)),
          icon: _isSubmitting ? null : const Icon(Icons.arrow_forward, color: AppColors.black),
        ).animate().slideY(begin: 1.2, delay: 500.ms, duration: 500.ms, curve: Curves.easeOut).fadeIn(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildSectionTitle(String title, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppLayout.spacingMedium),
      child: Text(title, style: textTheme.titleMedium?.copyWith(color: AppColors.textSecondary)),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildMajorSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedMajor,
      items: _majorOptions.map((major) => DropdownMenuItem(
        value: major,
        child: Text(major, style: const TextStyle(color: AppColors.textPrimary)),
      )).toList(),
      onChanged: (value) => setState(() => _selectedMajor = value),
      dropdownColor: AppColors.dark2, // Use dark surface for dropdown
      decoration: InputDecoration(
        hintText: 'Select your major',
        hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.7)),
        // Use theme defaults which are already customized
      ),
      style: const TextStyle(color: AppColors.textPrimary),
      iconEnabledColor: AppColors.textSecondary,
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }

  Widget _buildChipSelector(List<String> options, Set<String> selectedSet, Color selectedColor) {
    return Wrap(
      spacing: AppLayout.spacingSmall,
      runSpacing: AppLayout.spacingSmall,
      children: options.map((item) {
        final isSelected = selectedSet.contains(item);
        return InkWell(
          onTap: () => _toggleSelection(item, selectedSet),
          borderRadius: BorderRadius.circular(AppLayout.radiusFull),
          child: AnimatedContainer(
            duration: 200.ms,
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: AppLayout.spacingMedium, vertical: AppLayout.spacingSmall),
            decoration: BoxDecoration(
              color: isSelected ? selectedColor : AppColors.dark2,
              borderRadius: BorderRadius.circular(AppLayout.radiusFull),
              border: Border.all(
                color: isSelected ? selectedColor.withOpacity(0.5) : AppColors.dark3,
                width: 1.5,
              ),
              boxShadow: isSelected ? [
                BoxShadow(color: selectedColor.withOpacity(0.3), blurRadius: 8)
              ] : [],
            ),
            child: Text(
              item,
              style: TextStyle(
                color: isSelected ? AppColors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ).animate(target: isSelected ? 1 : 0)
           .scale(begin: const Offset(0.95, 0.95), duration: 200.ms, curve: Curves.elasticOut)
           .fadeIn(duration: 150.ms),
        );
      }).toList(),
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
  }
} 