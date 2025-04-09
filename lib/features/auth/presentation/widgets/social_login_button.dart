import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/core/navigation/deep_link_service.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A reusable social login button that redirects to the login page
/// with a return path specified
class SocialLoginButton extends StatelessWidget {
  /// The text to display on the button
  final String text;
  
  /// The icon to display on the button
  final IconData icon;
  
  /// The path to return to after successful authentication
  final String returnToPath;
  
  /// Optional callback to run before navigation
  final VoidCallback? onBeforeNavigate;
  
  /// Creates a social login button
  const SocialLoginButton({
    Key? key,
    required this.text,
    required this.icon,
    required this.returnToPath,
    this.onBeforeNavigate,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          // Run the callback if provided
          onBeforeNavigate?.call();
          
          // Navigate to login with return path
          DeepLinkService.navigateToSocialAuth(context, returnToPath);
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.gold),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppColors.black,
        ),
        icon: Icon(
          icon,
          color: AppColors.gold,
          size: 24,
        ),
        label: Text(
          text,
          style: GoogleFonts.inter(
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
} 