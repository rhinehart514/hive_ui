import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/widgets/profile/verification_dialog.dart';

/// A widget that handles feature restrictions based on verification status.
/// 
/// This component provides a user-friendly UI for features that require
/// specific verification levels, including explanations and upgrade prompts.
class RoleRestrictedFeature extends StatelessWidget {
  /// The user's current verification status
  final VerificationStatus currentStatus;
  
  /// The verification level required to access this feature
  final VerificationStatus requiredStatus;
  
  /// The feature name to display in explanations
  final String featureName;
  
  /// The feature description to help users understand what they're missing
  final String featureDescription;
  
  /// Icon to represent the feature
  final IconData featureIcon;
  
  /// Whether this restriction is being shown in a dialog context
  final bool isInDialog;
  
  /// Whether to automatically show verification dialog on tap
  final bool showVerificationOnTap;
  
  /// Optional callback when the user taps to verify
  final VoidCallback? onVerifyTapped;
  
  /// Constructor
  const RoleRestrictedFeature({
    Key? key,
    required this.currentStatus,
    required this.requiredStatus,
    required this.featureName,
    required this.featureDescription,
    required this.featureIcon,
    this.isInDialog = false,
    this.showVerificationOnTap = true,
    this.onVerifyTapped,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Feature header with icon and lock
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  featureIcon,
                  color: AppColors.gold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  featureName,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getVerificationText(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Feature description
          Text(
            featureDescription,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Verify button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _handleVerifyTap(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold.withOpacity(0.2),
                foregroundColor: AppColors.gold,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: AppColors.gold.withOpacity(0.5)),
                ),
              ),
              child: Text(
                _getButtonText(),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Get appropriate verification text based on required status
  String _getVerificationText() {
    switch (requiredStatus) {
      case VerificationStatus.verified:
        return 'Verification Required';
      case VerificationStatus.verifiedPlus:
        return 'Verified+ Required';
      default:
        return 'Restricted Feature';
    }
  }
  
  /// Get appropriate button text based on current and required status
  String _getButtonText() {
    // If already verified but need verified+
    if (currentStatus == VerificationStatus.verified && 
        requiredStatus == VerificationStatus.verifiedPlus) {
      return 'Upgrade to Verified+';
    }
    
    // If not verified at all
    if (currentStatus == VerificationStatus.none) {
      return 'Get Verified';
    }
    
    return 'View Verification Requirements';
  }
  
  /// Handle the verify button tap
  void _handleVerifyTap(BuildContext context) {
    HapticFeedback.mediumImpact();
    
    // Call the callback if provided
    if (onVerifyTapped != null) {
      onVerifyTapped!();
    }
    
    // Show verification dialog if enabled
    if (showVerificationOnTap) {
      // If in dialog context, close the current dialog first
      if (isInDialog) {
        Navigator.of(context).pop();
      }
      
      // Show the verification dialog
      showVerificationDialog(
        context,
        currentStatus: currentStatus,
      );
    }
  }
} 