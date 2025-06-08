import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/core/theme/app_typography.dart';
import 'package:hive_ui/widgets/hive_app_bar.dart';
import 'package:hive_ui/widgets/buttons/hive_primary_button.dart';
import 'package:hive_ui/widgets/buttons/hive_secondary_button.dart';
import 'package:hive_ui/widgets/form_fields/hive_text_form_field.dart';
import 'package:hive_ui/core/haptics/haptic_feedback_manager.dart';
import 'package:hive_ui/utils/feedback_util.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';

class PasskeyRegisterScreen extends ConsumerStatefulWidget {
  const PasskeyRegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PasskeyRegisterScreen> createState() => _PasskeyRegisterScreenState();
}

class _PasskeyRegisterScreenState extends ConsumerState<PasskeyRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSupported = false;
  
  @override
  void initState() {
    super.initState();
    _checkPasskeySupport();
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
  
  Future<void> _checkPasskeySupport() async {
    try {
      final isSupported = await ref.read(authRepositoryProvider).isPasskeySupported();
      
      if (mounted) {
        setState(() {
          _isSupported = isSupported;
        });
        
        if (!isSupported) {
          FeedbackUtil.showToast(
            context: context,
            message: 'Your device does not support passkeys. Try another sign-in method.',
            isError: true,
          );
        }
      }
    } catch (e) {
      // Handle errors checking passkey support
      if (mounted) {
        setState(() {
          _isSupported = false;
        });
      }
    }
  }
  
  Future<void> _registerWithPasskey() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (!_isSupported) {
      FeedbackUtil.showToast(
        context: context,
        message: 'Your device does not support passkeys. Try another sign-in method.',
        isError: true,
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final email = _emailController.text.trim();
      await ref.read(authRepositoryProvider).registerWithPasskey(email);
      
      HapticFeedbackManager().mediumImpact();
      
      // Navigate to onboarding or home screen after successful registration
      if (mounted) {
        FeedbackUtil.showToast(
          context: context,
          message: 'Registration successful! Welcome to HIVE.',
          isError: false,
        );
        
        // In a complete implementation, we would navigate to the next screen
        // This is a placeholder - in a real app we would use a proper route
        context.go('/onboarding');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        FeedbackUtil.showToast(
          context: context,
          message: 'Registration failed: ${e.toString()}',
          isError: true,
        );
      }
    }
  }
  
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    final eduRegExp = RegExp(r'\.edu$');
    if (!eduRegExp.hasMatch(value)) {
      return 'Please use your .edu email address';
    }
    
    return null;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: const HiveAppBar(
        title: 'Register with Passkey',
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create your account',
                style: AppTypography.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Enter your university .edu email to register with passkey authentication - a more secure way to sign in without passwords.',
                style: AppTypography.bodyLarge,
              ),
              const SizedBox(height: 32),
              HiveTextFormField(
                controller: _emailController,
                labelText: 'University Email',
                hintText: 'you@university.edu',
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              const SizedBox(height: 24),
              HivePrimaryButton(
                onPressed: _isLoading ? null : _registerWithPasskey,
                text: 'Create Account with Passkey',
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),
              Center(
                child: HiveSecondaryButton(
                  onPressed: _isLoading 
                    ? null 
                    : () => context.go('/register'),
                  text: 'Use Password Instead',
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.security,
                          color: AppColors.accent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'About Passkeys',
                          style: AppTypography.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• More secure than passwords',
                      style: AppTypography.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Uses your device\'s biometrics (Face ID, fingerprint, etc.)',
                      style: AppTypography.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Cannot be phished or stolen',
                      style: AppTypography.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Works across your devices',
                      style: AppTypography.bodyLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 