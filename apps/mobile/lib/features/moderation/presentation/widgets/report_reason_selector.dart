import 'package:flutter/material.dart';
import '../../domain/entities/content_report_entity.dart';
import '../../../../theme/app_colors.dart';

class ReportReasonSelector extends StatelessWidget {
  final ReportReason selectedReason;
  final Function(ReportReason) onReasonChanged;

  const ReportReasonSelector({
    Key? key,
    required this.selectedReason,
    required this.onReasonChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reason for Report',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        _buildReasonCard(
          context,
          ReportReason.spam,
          'Spam',
          'Content is unwanted repetitive, or commercial in nature',
          Icons.mark_email_unread_outlined,
        ),
        _buildReasonCard(
          context,
          ReportReason.harassment,
          'Harassment',
          'Content targets or bullies an individual or group',
          Icons.sentiment_very_dissatisfied_outlined,
        ),
        _buildReasonCard(
          context,
          ReportReason.hateSpeech,
          'Hate Speech',
          'Content promotes hatred or violence against protected groups',
          Icons.voice_over_off_outlined,
        ),
        _buildReasonCard(
          context,
          ReportReason.inappropriateContent,
          'Inappropriate Content',
          'Content includes explicit, harmful, or sensitive material',
          Icons.warning_amber_outlined,
        ),
        _buildReasonCard(
          context,
          ReportReason.violatesGuidelines,
          'Violates Guidelines',
          'Content breaks community guidelines or rules',
          Icons.gavel_outlined,
        ),
        _buildReasonCard(
          context,
          ReportReason.other,
          'Other',
          'Other reasons not listed above',
          Icons.more_horiz_outlined,
        ),
      ],
    );
  }

  Widget _buildReasonCard(
    BuildContext context,
    ReportReason reason,
    String title,
    String description,
    IconData icon,
  ) {
    final bool isSelected = selectedReason == reason;
    
    return GestureDetector(
      onTap: () => onReasonChanged(reason),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
            ? AppColors.gold.withOpacity(0.15) 
            : Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
              ? AppColors.gold 
              : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.gold : Colors.white.withOpacity(0.7),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.gold : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.gold,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
} 