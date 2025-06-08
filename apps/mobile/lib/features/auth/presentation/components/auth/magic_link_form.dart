import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/features/auth/presentation/components/auth/email_domain_validator.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_layout.dart';

/// Form for sending magic links for passwordless authentication
class MagicLinkForm extends ConsumerStatefulWidget {
  /// Callback for when the magic link has been sent
  final Function(bool success, String message) onMagicLinkSent;
  
  /// Initial email value (optional)
  final String? initialEmail;
  
  /// Whether to only allow .edu domains
  final bool eduOnly;

  const MagicLinkForm({
    Key? key,
    required this.onMagicLinkSent,
    this.initialEmail,
    this.eduOnly = true,
  }) : super(key: key);

  @override
  ConsumerState<MagicLinkForm> createState() => _MagicLinkFormState();
}

class _MagicLinkFormState extends ConsumerState<MagicLinkForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isEduEmail = false;
  
  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
      _checkEmailDomain(_emailController.text);
    }
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
  
  void _checkEmailDomain(String email) {
    if (email.isEmpty) return;
    
    setState(() {
      _isEduEmail = EmailDomainValidator.isEduEmail(email);
    });
  }
  
  Future<void> _sendMagicLink() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    final email = _emailController.text.trim();
    
    try {
      final result = await ref.read(authRepositoryProvider).sendSignInLinkToEmail(email);
      
      if (result) {
        if (mounted) {
          widget.onMagicLinkSent(true, 'Magic link sent to $email');
          context.go('/magic-link-sent');
        }
      } else {
        if (mounted) {
          widget.onMagicLinkSent(false, 'Failed to send magic link. Please try again.');
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        widget.onMagicLinkSent(false, 'Error: ${e.toString()}');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Email Authentication',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppLayout.spacingSmall),
          
          Text(
            widget.eduOnly 
                ? 'Enter your .edu email to receive a magic sign-in link'
                : 'Enter your email to receive a magic sign-in link',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppLayout.spacingMedium),
          
          // Email field with edu domain validation
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: widget.eduOnly ? 'your.name@university.edu' : 'your.email@example.com',
              prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
              suffixIcon: _isEduEmail && widget.eduOnly
                  ? const Icon(Icons.school, color: AppColors.success)
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppLayout.radiusSmall),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppLayout.radiusSmall),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppLayout.radiusSmall),
                borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppLayout.radiusSmall),
                borderSide: const BorderSide(color: AppColors.error),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppLayout.spacingMedium,
                vertical: AppLayout.spacingMedium,
              ),
            ),
            style: const TextStyle(color: AppColors.textPrimary),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            onChanged: _checkEmailDomain,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              
              if (widget.eduOnly && !EmailDomainValidator.isEduEmail(value)) {
                return 'Please use your .edu school email';
              }
              
              return null;
            },
          ),
          const SizedBox(height: AppLayout.spacingLarge),
          
          // Send button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendMagicLink,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
                disabledBackgroundColor: AppColors.gold.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppLayout.radiusMedium),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : const Text(
                      'Send Magic Link',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
} 