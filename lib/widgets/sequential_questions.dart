import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/components/buttons.dart';

class SequentialQuestion extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final bool isAnswered;
  final bool isLast;
  final VoidCallback? onContinue;
  final Widget? continueButton;

  const SequentialQuestion({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    required this.isAnswered,
    this.isLast = false,
    this.onContinue,
    this.continueButton,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question title
          Text(
            title,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Subtitle if provided
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Main content (search, options, etc.)
          child,

          // Continue button that shows only when answered
          if (isAnswered) ...[
            const SizedBox(height: 24),
            continueButton ??
                HiveButton(
                  text: isLast ? 'Finish' : 'Continue',
                  variant: HiveButtonVariant.primary,
                  size: HiveButtonSize.medium,
                  fullWidth: true,
                  onPressed: onContinue,
                ),
          ],
        ],
      ),
    );
  }
}

class SequentialQuestionsContainer extends StatelessWidget {
  final List<SequentialQuestion> questions;
  final int currentQuestionIndex;

  const SequentialQuestionsContainer({
    super.key,
    required this.questions,
    required this.currentQuestionIndex,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (currentQuestionIndex + 1) / questions.length,
              backgroundColor: Colors.white10,
              color: const Color(0xFFFFD700),
              minHeight: 4,
            ),
            const SizedBox(height: 32),

            // Displayed questions
            for (int i = 0; i <= currentQuestionIndex; i++)
              Padding(
                padding:
                    EdgeInsets.only(bottom: i < currentQuestionIndex ? 40 : 0),
                child: questions[i],
              ),
          ],
        ),
      ),
    );
  }
}
