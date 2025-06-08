import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_ui/features/onboarding/state/onboarding_providers.dart';
import 'package:hive_ui/features/onboarding/data/services/username_verification_service.dart';
import 'package:hive_ui/theme/app_colors.dart';
import '../widgets/onboarding_page_scaffold.dart';
import 'package:hive_ui/services/analytics_service.dart';
import 'package:hive_ui/utils/feedback_util.dart';

/// A page for selecting a unique username during onboarding.
///
/// This page allows the user to enter a desired username,
/// validates its format, and checks for uniqueness before proceeding.
class UsernamePage extends ConsumerStatefulWidget {
  /// Creates an instance of [UsernamePage].
  const UsernamePage({super.key});

  @override
  ConsumerState<UsernamePage> createState() => _UsernamePageState();
}

class _UsernamePageState extends ConsumerState<UsernamePage> with TickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final FocusNode _usernameFocus = FocusNode();
  late AnimationController _usernameShakeController;
  
  // Track if field has been interacted with for validation
  bool _usernameTouched = false;
  
  // Track availability check status
  bool _isCheckingAvailability = false;
  bool? _isUsernameAvailable;
  
  // Track debouncing for availability checks
  String _lastCheckedUsername = '';
  
  // Design constants
  static const shakeDuration = Duration(milliseconds: 400);
  static const double shakeHz = 5.0;
  static const double shakeAmount = 4.0;
  static const double spacingSemixlg = 16.0;
  static const double spacingSmall = 8.0;
  static const double spacingLarge = 32.0;
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0);

  @override
  void initState() {
    super.initState();
    _usernameFocus.addListener(_onUsernameFocusChange);
    
    // Initialize shake animation controller
    _usernameShakeController = AnimationController(vsync: this, duration: shakeDuration);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Log page view event
      AnalyticsService.logEvent('onboarding_username_page_viewed');
      
      final state = ref.read(onboardingStateNotifierProvider);
      if (state.username != null && state.username!.isNotEmpty) {
        _usernameController.text = state.username!;
        _usernameTouched = true;
        _checkUsernameAvailability(state.username!);
      }
      
      // Initial state update and validation check
      _updateStateAndValidate();
    });
  }
  
  @override
  void dispose() {
    _usernameFocus.removeListener(_onUsernameFocusChange);
    _usernameController.dispose();
    _usernameFocus.dispose();
    _usernameShakeController.dispose();
    super.dispose();
  }
  
  void _onUsernameFocusChange() {
    if (!_usernameFocus.hasFocus) {
      debugPrint('Username field lost focus');
      setState(() {
        _usernameTouched = true;
      });
      _updateStateAndValidate(triggerShake: true);
      
      // Check availability when focus is lost
      final username = _usernameController.text.trim();
      if (username.isNotEmpty) {
        _checkUsernameAvailability(username);
      }
    }
  }
  
  void _triggerErrorHaptic() {
    HapticFeedback.mediumImpact();
  }
  
  void _triggerMediumHaptic() {
    HapticFeedback.mediumImpact();
  }
  
  /// Validates username format and availability.
  String? _validateUsername({bool triggerShake = false}) {
    if (!_usernameTouched) return null;
    
    final value = _usernameController.text.trim();
    
    // Check format first
    final formatError = ref.read(usernameVerificationServiceProvider).validateUsernameFormat(value);
    if (formatError != null) {
      if (triggerShake) {
        _usernameShakeController.forward(from: 0.0);
        _triggerErrorHaptic();
      }
      return formatError;
    }
    
    // Availability check only happens when format is valid
    if (_isCheckingAvailability) {
      return 'Checking availability...';
    }
    
    if (_isUsernameAvailable == false) {
      if (triggerShake) {
        _usernameShakeController.forward(from: 0.0);
        _triggerErrorHaptic();
      }
      return 'This username is already taken';
    }
    
    return null;
  }
  
  /// Checks if the username is available.
  Future<void> _checkUsernameAvailability(String username) async {
    // Don't check empty usernames or usernames with format errors
    final formatError = ref.read(usernameVerificationServiceProvider).validateUsernameFormat(username);
    if (username.isEmpty || formatError != null) {
      setState(() {
        _isUsernameAvailable = null;
      });
      return;
    }
    
    // Don't recheck the same username
    if (_lastCheckedUsername == username) {
      return;
    }
    
    // Set checking status
    setState(() {
      _isCheckingAvailability = true;
      _isUsernameAvailable = null;
    });
    
    // Log check attempt
    AnalyticsService.logEvent('onboarding_username_check_attempt', parameters: {'username_length': username.length});
    
    try {
      _lastCheckedUsername = username;
      final isAvailable = await ref.read(usernameVerificationServiceProvider)
          .checkUsernameAvailability(username);
      
      // Update state if still mounted and username hasn't changed
      if (mounted && _usernameController.text.trim() == username) {
        setState(() {
          _isUsernameAvailable = isAvailable;
          _isCheckingAvailability = false;
        });
        
        // Log check result
        AnalyticsService.logEvent('onboarding_username_check_result', parameters: {'is_available': isAvailable});
        
        // If not available, show error animation
        if (!isAvailable) {
          _usernameShakeController.forward(from: 0.0);
          _triggerErrorHaptic();
        }
      }
    } catch (e) {
      // Handle error gracefully
      if (mounted) {
        // Log check error
        AnalyticsService.logEvent('onboarding_username_check_error', parameters: {'error': e.toString()});
        
        setState(() {
          _isCheckingAvailability = false;
          // Leave _isUsernameAvailable as null to indicate we don't know
        });
        // Show error message to user
        FeedbackUtil.showToast(
          context: context,
          message: 'Could not check username. Please try again later.',
          isError: true,
        );
      }
    }
  }
  
  void _updateStateAndValidate({bool triggerShake = false}) {
    final username = _usernameController.text.trim();
    
    // Update state if changed
    final currentState = ref.read(onboardingStateNotifierProvider);
    if (currentState.username != username) {
      ref.read(onboardingStateNotifierProvider.notifier).updateUsername(username);
    }
    
    // Re-validate after state update
    setState(() {
      _validateUsername(triggerShake: triggerShake && _usernameTouched);
    });
  }
  
  void _handleUsernameChanged(String value) {
    _updateStateAndValidate();
    
    // Schedule availability check with debounce
    if (value.trim().isNotEmpty) {
      final formatError = ref.read(usernameVerificationServiceProvider).validateUsernameFormat(value);
      if (formatError == null) {
        // Delay check to reduce API calls while typing
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _usernameController.text.trim() == value) {
            _checkUsernameAvailability(value);
          }
        });
      }
    }
  }
  
  void _handleUsernameSubmitted(String value) {
    debugPrint('Username submitted: "$value"');
    setState(() { _usernameTouched = true; });
    _updateStateAndValidate(triggerShake: true);
    
    // Check availability immediately on submission
    if (value.trim().isNotEmpty) {
      _checkUsernameAvailability(value);
    }
    
    // Attempt to navigate if the current page is valid
    // Availability check is async, so this may need to wait
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        final state = ref.read(onboardingStateNotifierProvider);
        final formatValid = ref.read(usernameVerificationServiceProvider).validateUsernameFormat(value) == null;
        
        if (formatValid && _isUsernameAvailable == true && state.isCurrentPageValid()) {
          // Log valid submission
          AnalyticsService.logEvent('onboarding_username_submitted_valid');
          _triggerMediumHaptic();
          ref.read(onboardingStateNotifierProvider.notifier).goToNextPage();
        } else {
          // Log invalid submission attempt
          AnalyticsService.logEvent('onboarding_username_submitted_invalid', parameters: {
            'format_valid': formatValid,
            'is_available': _isUsernameAvailable,
            'page_state_valid': state.isCurrentPageValid(),
            'error_reason': _validateUsername() ?? 'unknown',
          });
          setState(() {
            _validateUsername(triggerShake: true);
          });
        }
      }
    });
  }
  
  InputDecoration _usernameInputDecoration({
    required String labelText,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 17),
      floatingLabelStyle: const TextStyle(color: AppColors.gold, fontSize: 17),
      prefixText: '@',
      prefixStyle: const TextStyle(color: AppColors.gold, fontSize: 17, fontWeight: FontWeight.bold),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: AppColors.dark3, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: AppColors.gold, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: AppColors.error, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: AppColors.error, width: 2.0),
      ),
      errorText: errorText,
      errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
      suffixIcon: _getStatusIcon(),
      filled: true,
      fillColor: AppColors.dark2,
      contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
    );
  }
  
  Widget? _getStatusIcon() {
    if (_isCheckingAvailability) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          color: AppColors.gold,
          strokeWidth: 2.0,
        ),
      );
    } else if (_isUsernameAvailable == true) {
      return const Icon(Icons.check_circle, color: AppColors.success);
    } else if (_isUsernameAvailable == false) {
      return const Icon(Icons.cancel, color: AppColors.error);
    }
    return null;
  }
  
  @override
  Widget build(BuildContext context) {
    final isPageCurrentlyValid = ref.watch(isCurrentPageValidProvider);
    final usernameError = _usernameTouched ? _validateUsername() : null;
    
    return OnboardingPageScaffold(
      title: 'Choose Your Username',
      subtitle: 'This will be your unique identifier in HIVE. You can change it later, but choose wisely.',
      body: Padding(
        padding: pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: spacingLarge),
            // Username text field with shake animation
            Animate(
              effects: const [
                ShakeEffect(
                  hz: shakeHz,
                  curve: Curves.easeInOut,
                  duration: shakeDuration,
                  offset: Offset(shakeAmount, 0),
                )
              ],
              controller: _usernameShakeController,
              child: TextFormField(
                controller: _usernameController,
                focusNode: _usernameFocus,
                decoration: _usernameInputDecoration(
                  labelText: 'Username',
                  errorText: usernameError,
                ),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 17),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                onChanged: _handleUsernameChanged,
                onFieldSubmitted: _handleUsernameSubmitted,
              ),
            ),
            const SizedBox(height: spacingSmall),
            
            // Username guidelines
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Username requirements:',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• 3-20 characters',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  Text(
                    '• Letters, numbers, and underscores only',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  Text(
                    '• Must start with a letter',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 