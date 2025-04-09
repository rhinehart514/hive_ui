import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_ui/features/profile/presentation/providers/profile_providers.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// Enum to represent different roles for Verified+ status request
enum VerifiedPlusRole {
  /// Student organization leader
  orgLeader,
  
  /// Faculty member
  faculty,
  
  /// Department staff
  departmentStaff,
  
  /// Resident advisor
  residentAdvisor,
  
  /// Other campus leader
  otherLeader,
}

/// Page for submitting a request to upgrade to Verified+ status
class VerifiedPlusRequestPage extends ConsumerStatefulWidget {
  /// Constructor
  const VerifiedPlusRequestPage({Key? key}) : super(key: key);

  @override
  ConsumerState<VerifiedPlusRequestPage> createState() => _VerifiedPlusRequestPageState();
}

class _VerifiedPlusRequestPageState extends ConsumerState<VerifiedPlusRequestPage> {
  // Controllers
  final _justificationController = TextEditingController();
  final _roleController = TextEditingController();
  
  // Form state
  VerifiedPlusRole? _selectedRole;
  String? _documentPath;
  bool _isSubmitting = false;
  String? _errorMessage;
  
  // Form key for validation
  final _formKey = GlobalKey<FormState>();
  
  @override
  void dispose() {
    _justificationController.dispose();
    _roleController.dispose();
    super.dispose();
  }
  
  /// Get string representation of role enum for display
  String _getRoleName(VerifiedPlusRole role) {
    switch (role) {
      case VerifiedPlusRole.orgLeader:
        return 'Student Organization Leader';
      case VerifiedPlusRole.faculty:
        return 'Faculty Member';
      case VerifiedPlusRole.departmentStaff:
        return 'Department Staff';
      case VerifiedPlusRole.residentAdvisor:
        return 'Resident Advisor';
      case VerifiedPlusRole.otherLeader:
        return 'Other Campus Leader';
    }
  }
  
  /// Handler for role selection
  void _handleRoleSelected(VerifiedPlusRole role) {
    setState(() {
      _selectedRole = role;
      if (role == VerifiedPlusRole.otherLeader) {
        _roleController.clear();
      } else {
        _roleController.text = _getRoleName(role);
      }
    });
  }
  
  /// Handle document attachment
  Future<void> _attachDocument() async {
    try {
      final ImagePicker picker = ImagePicker();
      
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      
      if (pickedFile != null) {
        setState(() {
          _documentPath = pickedFile.path;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error attaching document: $e';
      });
    }
  }
  
  /// Submit the verification request
  Future<void> _submitRequest() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Check role selection
    if (_selectedRole == null) {
      setState(() {
        _errorMessage = 'Please select a role';
      });
      return;
    }
    
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    
    try {
      // In a real app, this would upload the document and send the request
      // For now, just simulate the API call with a delay
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;
      
      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.dark2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: AppColors.gold.withOpacity(0.3),
            ),
          ),
          title: Text(
            'Request Submitted',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.green,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your Verified+ request has been submitted for review. You will be notified when the review is complete.',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Return to previous screen
              },
              child: Text(
                'OK',
                style: GoogleFonts.outfit(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Error submitting request: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Get current user profile to check eligibility
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final currentUserAsyncValue = ref.watch(userProfileProvider(currentUserId ?? ''));
    
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Request Verified+',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: currentUserAsyncValue.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.gold,
          ),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Error loading profile: $err',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text(
                'User profile not found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          
          // Check if the user is eligible for Verified+ upgrade
          if (!user.isVerified || user.isVerifiedPlus) {
            return _buildIneligibleView(context, user);
          }
          
          // User is eligible, show request form
          return _buildRequestForm(context);
        },
      ),
    );
  }
  
  /// Build the request form for eligible users
  Widget _buildRequestForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.workspace_premium,
                    color: AppColors.gold,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Verified+ Status',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Text(
              'Apply for Verified+ Status',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Verified+ status provides enhanced privileges for campus leaders and organizational representatives.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            
            // Role selection
            Text(
              'Your Role',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            _buildRoleSelector(),
            const SizedBox(height: 16),
            
            // Other role field (shown only when "Other" is selected)
            if (_selectedRole == VerifiedPlusRole.otherLeader) ...[
              Text(
                'Specify Your Role',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _roleController,
                decoration: InputDecoration(
                  hintText: 'Enter your specific role',
                  hintStyle: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.5),
                  ),
                  fillColor: Colors.black.withOpacity(0.3),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.gold,
                    ),
                  ),
                ),
                style: GoogleFonts.inter(
                  color: Colors.white,
                ),
                validator: (value) {
                  if (_selectedRole == VerifiedPlusRole.otherLeader && 
                      (value == null || value.isEmpty)) {
                    return 'Please specify your role';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],
            
            // Justification field
            Text(
              'Justification',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _justificationController,
              decoration: InputDecoration(
                hintText: 'Explain why you qualify for Verified+ status',
                hintStyle: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.5),
                ),
                fillColor: Colors.black.withOpacity(0.3),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.gold,
                  ),
                ),
              ),
              style: GoogleFonts.inter(
                color: Colors.white,
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please provide justification';
                }
                if (value.length < 20) {
                  return 'Justification is too short';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Document upload
            Text(
              'Supporting Document (Optional)',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            _buildDocumentUploader(),
            const SizedBox(height: 32),
            
            // Error message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.inter(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: AppColors.gold.withOpacity(0.3),
                  disabledForegroundColor: Colors.black.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Submit Request',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Disclaimer
            Text(
              'Note: Verified+ requests are manually reviewed by administrators. The review process typically takes 1-3 business days.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withOpacity(0.5),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build the role selector widget
  Widget _buildRoleSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          _buildRoleOption(VerifiedPlusRole.orgLeader),
          _buildDivider(),
          _buildRoleOption(VerifiedPlusRole.faculty),
          _buildDivider(),
          _buildRoleOption(VerifiedPlusRole.departmentStaff),
          _buildDivider(),
          _buildRoleOption(VerifiedPlusRole.residentAdvisor),
          _buildDivider(),
          _buildRoleOption(VerifiedPlusRole.otherLeader),
        ],
      ),
    );
  }
  
  /// Build a divider for the role selector
  Widget _buildDivider() {
    return Container(
      width: double.infinity,
      height: 1,
      color: Colors.white.withOpacity(0.05),
    );
  }
  
  /// Build a role option item
  Widget _buildRoleOption(VerifiedPlusRole role) {
    final isSelected = _selectedRole == role;
    
    return InkWell(
      onTap: () => _handleRoleSelected(role),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.gold : Colors.white.withOpacity(0.7),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getRoleName(role),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build the document uploader widget
  Widget _buildDocumentUploader() {
    if (_documentPath != null) {
      // Show selected document
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.insert_drive_file,
              color: AppColors.gold,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Document Attached',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _documentPath!.split('/').last,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _documentPath = null;
                });
              },
            ),
          ],
        ),
      );
    }
    
    // Show upload button
    return InkWell(
      onTap: _attachDocument,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.file_upload_outlined,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to upload document',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'PDF, JPG, or PNG (max 5MB)',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build the view for ineligible users
  Widget _buildIneligibleView(BuildContext context, user) {
    // If already Verified+, show success message
    if (user.isVerifiedPlus) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified,
                  color: AppColors.gold,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              
              Text(
                'Already Verified+',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your account already has Verified+ status. You have access to all premium features.',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Return to Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold.withOpacity(0.2),
                  foregroundColor: AppColors.gold,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.gold.withOpacity(0.5)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // If not verified, show verification required message
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                color: Colors.red.shade300,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Verification Required',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'You need to verify your campus email before applying for Verified+ status.',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to verification page
                Navigator.of(context).pop();
                // In a real app, you would navigate to the email verification page
              },
              icon: const Icon(Icons.verified_user),
              label: const Text('Get Verified First'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.withOpacity(0.2),
                foregroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.blue.withOpacity(0.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 