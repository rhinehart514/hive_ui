import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/core/navigation/app_bar_builder.dart';
import 'package:hive_ui/core/widgets/hive_primary_button.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_layout.dart';
import 'package:hive_ui/utils/feedback_util.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Page that allows users to request verification or upgraded verification status
class VerificationRequestPage extends ConsumerStatefulWidget {
  const VerificationRequestPage({Key? key}) : super(key: key);

  @override
  ConsumerState<VerificationRequestPage> createState() => _VerificationRequestPageState();
}

class _VerificationRequestPageState extends ConsumerState<VerificationRequestPage> {
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _spaceIdController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // Whether the user is already verified (level 1) and requesting verified+ (level 2)
  bool _isRequestingUpgrade = false;
  
  @override
  void initState() {
    super.initState();
    
    // Check if user is already verified
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser.isVerified) {
        setState(() {
          _isRequestingUpgrade = true;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _reasonController.dispose();
    _spaceIdController.dispose();
    super.dispose();
  }
  
  void _submitVerificationRequest() async {
    // Clear previous errors
    setState(() {
      _errorMessage = null;
    });
    
    // Validate inputs
    if (_reasonController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please provide a reason for your verification request.';
      });
      FeedbackUtil.error();
      return;
    }
    
    // For verified+ requests, validate space ID if provided
    if (_isRequestingUpgrade && _spaceIdController.text.isNotEmpty) {
      // In a real implementation, we'd validate the space ID format here
      if (_spaceIdController.text.length < 3) {
        setState(() {
          _errorMessage = 'Please enter a valid space ID.';
        });
        FeedbackUtil.error();
        return;
      }
    }
    
    // Set loading state
    setState(() {
      _isLoading = true;
    });
    
    FeedbackUtil.buttonTap();
    
    try {
      // Call the appropriate Cloud Function
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        _isRequestingUpgrade ? 'requestVerifiedPlusClaim' : 'requestVerification'
      );
      
      final result = await callable.call({
        'reason': _reasonController.text,
        'spaceId': _isRequestingUpgrade ? _spaceIdController.text : null,
      });
      
      if (result.data['success'] == true) {
        if (mounted) {
          FeedbackUtil.showToast(
            context: context,
            message: result.data['message'] ?? 'Verification request submitted successfully.',
            isSuccess: true,
          );
          
          // Haptic feedback
          HapticFeedback.mediumImpact();
          
          // Allow user to see success message
          await Future.delayed(const Duration(milliseconds: 1500));
          
          if (mounted) {
            // Navigate back
            FeedbackUtil.navigate();
            context.pop();
          }
        }
      } else {
        throw Exception(result.data['message'] ?? 'Unknown error occurred.');
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Verification request error: ${e.message}');
      
      // Handle specific error codes
      String errorMsg = 'Failed to submit verification request.';
      
      if (e.code == 'already-exists') {
        errorMsg = 'You already have a pending verification request.';
      } else if (e.code == 'permission-denied') {
        errorMsg = 'You do not have permission to request this verification level.';
      } else if (e.code == 'invalid-argument') {
        errorMsg = 'Please provide all required information.';
      } else if (e.message != null) {
        errorMsg = e.message!;
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = errorMsg;
        });
        FeedbackUtil.error();
      }
    } catch (e) {
      debugPrint('Verification request error: $e');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An unexpected error occurred. Please try again later.';
        });
        FeedbackUtil.error();
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBarBuilder.buildStandardAppBar(
        context,
        title: _isRequestingUpgrade ? 'Request Verified+' : 'Request Verification',
        onBackPressed: () {
          FeedbackUtil.navigate();
          context.pop();
        },
        backgroundColor: AppColors.dark,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppLayout.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.dark2,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.gold,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _isRequestingUpgrade 
                        ? Icons.workspace_premium
                        : Icons.verified_user,
                    size: 40,
                    color: AppColors.gold,
                  ),
                ),
              ),
              const SizedBox(height: AppLayout.spacingLarge),
              
              // Title
              Text(
                _isRequestingUpgrade
                    ? 'Upgrade to Verified+'
                    : 'Become a Verified User',
                style: textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppLayout.spacingMedium),
              
              // Description
              Text(
                _isRequestingUpgrade
                    ? 'Verified+ users can create Spaces and participate in exclusive communities. This verification level is typically for leaders, organizers, and trusted community members.'
                    : 'Verified users have confirmed their .edu address and can participate in verified-only events and spaces. Verification helps build trust within the HIVE community.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppLayout.spacingXLarge),
              
              // Form fields
              if (_isRequestingUpgrade) ...[
                Text(
                  'Space ID (optional)',
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppLayout.spacingXSmall),
                TextFormField(
                  controller: _spaceIdController,
                  decoration: InputDecoration(
                    hintText: 'Enter Space ID if applicable',
                    hintStyle: const TextStyle(color: AppColors.textTertiary),
                    filled: true,
                    fillColor: AppColors.dark2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppLayout.radiusMedium),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppLayout.spacingMedium,
                      vertical: AppLayout.spacingMedium,
                    ),
                  ),
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppLayout.spacingSmall),
                Text(
                  'If you\'re requesting Verified+ status for a specific space, enter its ID.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: AppLayout.spacingLarge),
              ],
              
              Text(
                'Request Reason',
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppLayout.spacingXSmall),
              TextFormField(
                controller: _reasonController,
                maxLines: 5,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: _isRequestingUpgrade
                      ? 'Explain why you\'re requesting Verified+ status...'
                      : 'Explain why you\'re requesting verification...',
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  filled: true,
                  fillColor: AppColors.dark2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppLayout.radiusMedium),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(AppLayout.spacingMedium),
                ),
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppLayout.spacingLarge),
              
              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppLayout.spacingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppLayout.radiusMedium),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: AppLayout.spacingSmall),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppLayout.spacingLarge),
              ],
              
              // Submit button
              HivePrimaryButton(
                text: _isLoading 
                    ? 'Submitting...' 
                    : (_isRequestingUpgrade ? 'Request Verified+ Status' : 'Submit Verification Request'),
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _submitVerificationRequest,
              ),
              const SizedBox(height: AppLayout.spacingMedium),
              
              // Note about processing time
              Text(
                'Verification requests are typically processed within 1-3 business days.',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 