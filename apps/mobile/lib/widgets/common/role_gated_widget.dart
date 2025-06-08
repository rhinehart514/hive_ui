import 'package:flutter/material.dart';
import 'package:hive_ui/models/user_profile.dart';

/// A widget that conditionally renders its children based on the user's verification status.
/// 
/// This is used to implement role-based UI adaptation - showing or hiding UI elements
/// based on the user's verification level.
class RoleGatedWidget extends StatelessWidget {
  /// The current user's verification status
  final VerificationStatus currentStatus;
  
  /// The minimum verification status required to view this content
  final VerificationStatus requiredStatus;
  
  /// The child widget to display if the user meets the verification status
  final Widget child;
  
  /// Optional widget to display if the user doesn't meet the verification status
  /// If not provided, nothing will be displayed for unauthorized users
  final Widget? unauthorizedWidget;
  
  /// Optional callback for when an unauthorized user attempts to interact
  final VoidCallback? onUnauthorizedTap;
  
  /// Whether to show a placeholder when unauthorized (vs just hiding completely)
  final bool showPlaceholder;
  
  /// Constructor
  const RoleGatedWidget({
    super.key,
    required this.currentStatus,
    required this.requiredStatus,
    required this.child,
    this.unauthorizedWidget,
    this.onUnauthorizedTap,
    this.showPlaceholder = true,
  });
  
  @override
  Widget build(BuildContext context) {
    // Check if the user has the required verification status
    final bool isAuthorized = _isAuthorized();
    
    // If authorized, show the child
    if (isAuthorized) {
      return child;
    }
    
    // If unauthorized and a custom unauthorized widget is provided, show it
    if (unauthorizedWidget != null) {
      return unauthorizedWidget!;
    }
    
    // If unauthorized and we should show a placeholder, create one
    if (showPlaceholder) {
      return _buildPlaceholder(context);
    }
    
    // Otherwise, render nothing
    return const SizedBox.shrink();
  }
  
  /// Check if the user is authorized based on their verification status
  bool _isAuthorized() {
    // Special case: if no verification is required, always allow
    if (requiredStatus == VerificationStatus.none) {
      return true;
    }
    
    // For verified requirement, user must be verified or verified+
    if (requiredStatus == VerificationStatus.verified) {
      return currentStatus == VerificationStatus.verified || 
             currentStatus == VerificationStatus.verifiedPlus;
    }
    
    // For verified+ requirement, user must be verified+
    if (requiredStatus == VerificationStatus.verifiedPlus) {
      return currentStatus == VerificationStatus.verifiedPlus;
    }
    
    // Default fallback
    return false;
  }
  
  /// Build a placeholder widget that indicates content is locked behind verification
  Widget _buildPlaceholder(BuildContext context) {
    // If there's an onUnauthorizedTap handler, make the placeholder tappable
    final Widget placeholder = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline,
            size: 16,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Text(
            _getLockMessage(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
    
    // Wrap in GestureDetector if there's an onUnauthorizedTap handler
    if (onUnauthorizedTap != null) {
      return GestureDetector(
        onTap: onUnauthorizedTap,
        child: placeholder,
      );
    }
    
    return placeholder;
  }
  
  /// Get the appropriate lock message based on the required verification status
  String _getLockMessage() {
    switch (requiredStatus) {
      case VerificationStatus.verified:
        return 'Verification required';
      case VerificationStatus.verifiedPlus:
        return 'Verified+ status required';
      default:
        return 'Locked content';
    }
  }
} 