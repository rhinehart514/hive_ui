import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';

/// A card widget for displaying tutorial content.
///
/// This widget is used in the onboarding tutorial to display
/// information about different features of the app.
class TutorialCard extends StatelessWidget {
  /// The headline text for the card.
  final String headline;
  
  /// The body text for the card.
  final String body;
  
  /// The path to an optional image asset.
  final String? imagePath;
  
  /// The function to call when the next button is pressed.
  final VoidCallback onNext;
  
  /// Whether this is the last card in the tutorial.
  final bool isLastCard;
  
  /// The label for the action button.
  final String buttonLabel;

  /// Creates an instance of [TutorialCard].
  const TutorialCard({
    Key? key,
    required this.headline,
    required this.body,
    this.imagePath,
    required this.onNext,
    this.isLastCard = false,
    this.buttonLabel = 'Next',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing24,
        vertical: AppTheme.spacing8,
      ),
      decoration: BoxDecoration(
        color: AppColors.dark2,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Optional image
          if (imagePath != null) ...[
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacing16),
                child: Image.asset(
                  imagePath!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
          
          // Text content
          Expanded(
            flex: imagePath != null ? 2 : 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Headline
                Text(
                  headline,
                  style: AppTheme.displaySmall.copyWith(
                    color: AppColors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppTheme.spacing16),
                
                // Body
                Text(
                  body,
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Action button
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacing24),
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastCard ? AppColors.gold : AppColors.white,
                foregroundColor: AppColors.black,
                minimumSize: const Size(200, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                buttonLabel,
                style: AppTheme.labelLarge.copyWith(
                  color: AppColors.black,
                ),
              ),
            ),
          ),
          
          // Extra space for swipe affordance
          if (!isLastCard) ...[
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'Swipe left to continue',
              style: AppTheme.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
} 