import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/leadership_claim_form.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A dialog for handling space leadership claims
class LeadershipClaimDialog extends StatelessWidget {
  /// The ID of the space to claim leadership of
  final String spaceId;
  
  /// Callback triggered when a claim is submitted
  final VoidCallback onClaim;

  /// Constructor
  const LeadershipClaimDialog({
    Key? key,
    required this.spaceId,
    required this.onClaim,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.gold.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Claim Leadership',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'To claim leadership of this space, please provide your credentials and reason for claiming. Your request will be reviewed by our team.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            LeadershipClaimForm(
              spaceId: spaceId,
              onSubmitComplete: () {
                Navigator.of(context).pop();
                onClaim();
              },
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withOpacity(0.7),
                ),
                child: Text('Cancel', style: GoogleFonts.inter()),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 