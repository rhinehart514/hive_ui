import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/profile/domain/entities/verification_status.dart';
import 'package:hive_ui/features/profile/presentation/providers/verification_provider.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/utils/feedback_util.dart';

/// A button to open the verification page
class VerificationButton extends ConsumerWidget {
  final Color? buttonColor;
  final bool showIcon;
  
  const VerificationButton({
    super.key,
    this.buttonColor,
    this.showIcon = true,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verificationAsync = ref.watch(userVerificationProvider);
    
    return verificationAsync.when(
      data: (verification) {
        // Don't show the button for fully verified users
        if (verification.level == VerificationLevel.verifiedPlus && 
            verification.status == VerificationStatus.verified) {
          return const SizedBox.shrink();
        }
        
        String buttonText;
        IconData? buttonIcon;
        Color buttonColor = this.buttonColor ?? AppColors.gold;
        
        if (verification.status == VerificationStatus.pending) {
          buttonText = 'Verification Pending';
          buttonIcon = Icons.hourglass_empty;
          buttonColor = Colors.orange;
        } else if (verification.level == VerificationLevel.public) {
          buttonText = 'Verify Account';
          buttonIcon = Icons.verified_user_outlined;
        } else if (verification.level == VerificationLevel.verified &&
                  verification.status == VerificationStatus.verified) {
          buttonText = 'Request Student Leader Status';
          buttonIcon = Icons.school_outlined;
        } else if (verification.status == VerificationStatus.rejected) {
          buttonText = 'Verification Rejected';
          buttonIcon = Icons.error_outline;
          buttonColor = Colors.red;
        } else {
          buttonText = 'Verify Account';
          buttonIcon = Icons.verified_user_outlined;
        }
        
        return ElevatedButton(
          onPressed: () {
            FeedbackUtil.buttonTap();
            context.push('/verification/admin');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcon) ...[
                Icon(buttonIcon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                buttonText,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
      error: (_, __) => ElevatedButton(
        onPressed: () {
          FeedbackUtil.buttonTap();
          context.push('/verification/admin');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor ?? AppColors.gold,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              const Icon(Icons.verified_user_outlined, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              'Verify Account',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 