import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/core/services/role_checker.dart';
import 'package:hive_ui/features/auth/presentation/widgets/role_badge.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A bottom sheet for initiating and guiding users through the role upgrade process.
/// Includes multi-step flow for upgrading from Public to Verified or Verified to Verified+.
class RoleUpgraderSheet extends ConsumerStatefulWidget {
  /// The current role of the user
  final UserRole currentRole;
  
  /// The target role for upgrade
  final UserRole targetRole;
  
  /// Callback when the upgrade process is completed
  final Function(bool success)? onComplete;
  
  /// Creates a role upgrader sheet
  const RoleUpgraderSheet({
    super.key,
    required this.currentRole,
    required this.targetRole,
    this.onComplete,
  });
  
  /// Show the role upgrader as a modal bottom sheet
  static Future<void> show({
    required BuildContext context,
    required UserRole currentRole,
    required UserRole targetRole,
    Function(bool success)? onComplete,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RoleUpgraderSheet(
        currentRole: currentRole,
        targetRole: targetRole,
        onComplete: onComplete,
      ),
    );
  }
  
  @override
  ConsumerState<RoleUpgraderSheet> createState() => _RoleUpgraderSheetState();
}

class _RoleUpgraderSheetState extends ConsumerState<RoleUpgraderSheet> {
  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Form data
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _organizationController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  String? _selectedOrganizationType;
  
  final List<String> _organizationTypes = [
    'Student Club',
    'Department',
    'Greek Life',
    'Sports Team',
    'Administrative',
    'Other',
  ];
  
  @override
  void dispose() {
    _emailController.dispose();
    _organizationController.dispose();
    _roleController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar at top
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTitle(),
                  style: GoogleFonts.outfit(
                    color: AppColors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getDescription(),
                  style: GoogleFonts.inter(
                    color: AppColors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                
                // Role badges
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RoleBadge(role: widget.currentRole, size: RoleBadgeSize.large),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Icon(
                        Icons.arrow_forward,
                        color: AppColors.white.withOpacity(0.7),
                        size: 20,
                      ),
                    ),
                    RoleBadge(role: widget.targetRole, size: RoleBadgeSize.large),
                  ],
                ),
              ],
            ),
          ),
          
          // Progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(
                _getTotalSteps(),
                (index) => Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: index <= _currentStep
                          ? AppColors.gold
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Step title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _getStepTitle(),
              style: GoogleFonts.outfit(
                color: AppColors.gold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Error message
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade300,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.inter(
                        color: Colors.red.shade300,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Step content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildStepContent(),
            ),
          ),
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Back button
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _handleBack,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Back',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                if (_currentStep > 0)
                  const SizedBox(width: 16),
                
                // Continue/Submit button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor: AppColors.gold.withOpacity(0.3),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isLastStep() ? 'Submit' : 'Continue',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Build step content based on current step
  Widget _buildStepContent() {
    if (widget.targetRole == UserRole.verified) {
      // Public to Verified flow
      switch (_currentStep) {
        case 0:
          return _buildWelcomeStep();
        case 1:
          return _buildEmailVerificationStep();
        case 2:
          return _buildSubmitStep();
        default:
          return const SizedBox.shrink();
      }
    } else {
      // Verified to Verified+ flow
      switch (_currentStep) {
        case 0:
          return _buildWelcomeStep();
        case 1:
          return _buildOrganizationDetailsStep();
        case 2:
          return _buildVerifyRoleStep();
        case 3:
          return _buildSubmitStep();
        default:
          return const SizedBox.shrink();
      }
    }
  }
  
  // Step 0: Welcome and introduction
  Widget _buildWelcomeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Benefits:',
          style: GoogleFonts.outfit(
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._getBenefits().map((benefit) => _buildBenefitItem(benefit)),
        const SizedBox(height: 24),
        Text(
          'Requirements:',
          style: GoogleFonts.outfit(
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._getRequirements().map((req) => _buildRequirementItem(req)),
      ],
    );
  }
  
  // Step 1: Email verification (for Public to Verified)
  Widget _buildEmailVerificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Please enter your university email address to verify your student status.',
          style: GoogleFonts.inter(
            color: AppColors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'University Email',
          style: GoogleFonts.inter(
            color: AppColors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          style: GoogleFonts.inter(
            color: AppColors.white,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: 'your.name@university.edu',
            hintStyle: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.3),
              fontSize: 16,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.gold.withOpacity(0.5),
              ),
            ),
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 24),
        Text(
          'Note: A verification email will be sent to this address. You must have access to this email to complete verification.',
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
  
  // Step 1: Organization details (for Verified to Verified+)
  Widget _buildOrganizationDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Please provide details about the organization you represent.',
          style: GoogleFonts.inter(
            color: AppColors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        
        // Organization type dropdown
        Text(
          'Organization Type',
          style: GoogleFonts.inter(
            color: AppColors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedOrganizationType,
              hint: Text(
                'Select organization type',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 16,
                ),
              ),
              isExpanded: true,
              dropdownColor: AppColors.black,
              icon: Icon(
                Icons.arrow_drop_down,
                color: Colors.white.withOpacity(0.5),
              ),
              style: GoogleFonts.inter(
                color: AppColors.white,
                fontSize: 16,
              ),
              onChanged: (value) {
                setState(() {
                  _selectedOrganizationType = value;
                });
              },
              items: _organizationTypes.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Organization name
        Text(
          'Organization Name',
          style: GoogleFonts.inter(
            color: AppColors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _organizationController,
          style: GoogleFonts.inter(
            color: AppColors.white,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: 'Enter organization name',
            hintStyle: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.3),
              fontSize: 16,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.gold.withOpacity(0.5),
              ),
            ),
          ),
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }
  
  // Step 2: Verify role (for Verified to Verified+)
  Widget _buildVerifyRoleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Please provide your position in the organization.',
          style: GoogleFonts.inter(
            color: AppColors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        
        // Role position
        Text(
          'Your Position/Role',
          style: GoogleFonts.inter(
            color: AppColors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _roleController,
          style: GoogleFonts.inter(
            color: AppColors.white,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: 'e.g. President, Treasurer, etc.',
            hintStyle: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.3),
              fontSize: 16,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.gold.withOpacity(0.5),
              ),
            ),
          ),
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 24),
        Text(
          'Note: We may contact you for additional verification. Leadership positions typically require approval from your organization or department.',
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
  
  // Final step: Submit
  Widget _buildSubmitStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Please review your information before submitting:',
          style: GoogleFonts.inter(
            color: AppColors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        
        // Review information
        if (widget.targetRole == UserRole.verified)
          _buildReviewItem('University Email', _emailController.text)
        else ...[
          _buildReviewItem('Organization Type', _selectedOrganizationType ?? 'Not specified'),
          _buildReviewItem('Organization Name', _organizationController.text),
          _buildReviewItem('Your Position', _roleController.text),
        ],
        
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.gold.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.gold,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'What happens next?',
                    style: GoogleFonts.outfit(
                      color: AppColors.gold,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _getNextStepsText(),
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Helper for review items
  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? 'Not provided' : value,
            style: GoogleFonts.inter(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper for benefit items
  Widget _buildBenefitItem(String benefit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.gold,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              benefit,
              style: GoogleFonts.inter(
                color: AppColors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper for requirement items
  Widget _buildRequirementItem(String requirement) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.arrow_right,
            color: Colors.white.withOpacity(0.7),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              requirement,
              style: GoogleFonts.inter(
                color: AppColors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Get the sheet title
  String _getTitle() {
    if (widget.targetRole == UserRole.verified) {
      return 'Verify Your Account';
    } else if (widget.targetRole == UserRole.verifiedPlus) {
      return 'Upgrade to Verified+';
    }
    return 'Account Upgrade';
  }
  
  // Get the sheet description
  String _getDescription() {
    if (widget.targetRole == UserRole.verified) {
      return 'Complete the steps below to verify your student status and unlock additional features.';
    } else if (widget.targetRole == UserRole.verifiedPlus) {
      return 'Leaders and officers can access enhanced features by upgrading to Verified+.';
    }
    return 'Upgrade your account to access more features.';
  }
  
  // Get step title based on current step
  String _getStepTitle() {
    if (widget.targetRole == UserRole.verified) {
      switch (_currentStep) {
        case 0:
          return 'About Verification';
        case 1:
          return 'Email Verification';
        case 2:
          return 'Submit Request';
        default:
          return 'Verification';
      }
    } else {
      switch (_currentStep) {
        case 0:
          return 'About Verified+';
        case 1:
          return 'Organization Details';
        case 2:
          return 'Your Position';
        case 3:
          return 'Submit Request';
        default:
          return 'Upgrade';
      }
    }
  }
  
  // Get total steps for the flow
  int _getTotalSteps() {
    return widget.targetRole == UserRole.verified ? 3 : 4;
  }
  
  // Check if current step is the last step
  bool _isLastStep() {
    return _currentStep == _getTotalSteps() - 1;
  }
  
  // Get role-specific benefits
  List<String> _getBenefits() {
    if (widget.targetRole == UserRole.verified) {
      return [
        'RSVP to campus events',
        'Join exclusive spaces',
        'Engage with the campus community',
        'Personalized event recommendations',
      ];
    } else {
      return [
        'Create and manage spaces',
        'Create and host events',
        'Access to visibility tools (Boost, Honey Mode)',
        'Analytics for your spaces and events',
        'Priority support',
      ];
    }
  }
  
  // Get role-specific requirements
  List<String> _getRequirements() {
    if (widget.targetRole == UserRole.verified) {
      return [
        'Must have an active university email address',
        'Must be a current student',
        'Verification typically takes 1-2 business days',
      ];
    } else {
      return [
        'Must be a verified student',
        'Must hold a leadership position in a recognized organization',
        'Position must be verified with the organization',
        'Verification typically takes 2-3 business days',
      ];
    }
  }
  
  // Get next steps text for final step
  String _getNextStepsText() {
    if (widget.targetRole == UserRole.verified) {
      return 'After submitting, you will receive a verification email. Once you confirm your email, our team will review your request and update your account status, typically within 1-2 business days.';
    } else {
      return 'After submitting, our team will review your role in the organization. This may involve contacting your organization or department for confirmation. Verified+ status is typically granted within 2-3 business days if your leadership position is confirmed.';
    }
  }
  
  // Handle continue button
  void _handleContinue() async {
    // Clear any previous error
    setState(() {
      _errorMessage = null;
    });
    
    // Validate current step
    bool isValid = await _validateCurrentStep();
    if (!isValid) {
      return;
    }
    
    // If this is the last step, submit the request
    if (_isLastStep()) {
      _submitRequest();
    } else {
      // Otherwise, move to next step
      setState(() {
        _currentStep++;
      });
    }
  }
  
  // Handle back button
  void _handleBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _errorMessage = null;
      });
    }
  }
  
  // Validate the current step
  Future<bool> _validateCurrentStep() async {
    if (widget.targetRole == UserRole.verified) {
      switch (_currentStep) {
        case 0:
          return true;
        case 1:
          if (_emailController.text.isEmpty) {
            setState(() {
              _errorMessage = 'Please enter your university email address';
            });
            return false;
          }
          if (!_emailController.text.contains('@') || !_emailController.text.contains('.edu')) {
            setState(() {
              _errorMessage = 'Please enter a valid .edu email address';
            });
            return false;
          }
          return true;
        case 2:
          return true;
      }
    } else {
      switch (_currentStep) {
        case 0:
          return true;
        case 1:
          if (_selectedOrganizationType == null) {
            setState(() {
              _errorMessage = 'Please select an organization type';
            });
            return false;
          }
          if (_organizationController.text.isEmpty) {
            setState(() {
              _errorMessage = 'Please enter your organization name';
            });
            return false;
          }
          return true;
        case 2:
          if (_roleController.text.isEmpty) {
            setState(() {
              _errorMessage = 'Please enter your position in the organization';
            });
            return false;
          }
          return true;
        case 3:
          return true;
      }
    }
    return true;
  }
  
  // Submit the verification request
  Future<void> _submitRequest() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Simulate API call with a delay
      await Future.delayed(const Duration(seconds: 2));
      
      // In a real implementation, this would interact with the backend
      // For now, we'll simulate success and call the onComplete callback
      
      if (widget.onComplete != null) {
        widget.onComplete!(true);
      }
      
      // Show success and close the sheet
      if (mounted) {
        // Provide haptic feedback
        HapticFeedback.mediumImpact();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Your ${widget.targetRole == UserRole.verified ? 'verification' : 'upgrade'} request has been submitted!',
              style: GoogleFonts.inter(
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        // Close the sheet
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to submit request: ${e.toString()}';
      });
    }
  }
} 