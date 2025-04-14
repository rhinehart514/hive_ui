import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_theme.dart';
import 'package:hive_ui/models/user_profile.dart';

class AccountTierPage extends StatelessWidget {
  final AccountTier selectedTier;
  final List<AccountTier> availableTiers;
  final ValueChanged<AccountTier> onTierSelected;
  final Widget progressIndicator;
  final VoidCallback? onContinue;

  const AccountTierPage({
    Key? key,
    required this.selectedTier,
    required this.availableTiers,
    required this.onTierSelected,
    required this.progressIndicator,
    this.onContinue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose your account tier',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the tier that matches your status',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: availableTiers.map((tier) {
              final isSelected = tier == selectedTier;
              return GestureDetector(
                onTap: () => onTierSelected(tier),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.black,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected 
                        ? Colors.transparent 
                        : Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    tier.name,
                    style: GoogleFonts.inter(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const Expanded(child: SizedBox()),
          progressIndicator,
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: AppTheme.spacing56,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: Text(
                'Finish',
                style: AppTheme.labelLarge.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
} 