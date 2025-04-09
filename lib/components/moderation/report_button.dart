import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ui/components/moderation/report_dialog.dart';
import 'package:hive_ui/features/moderation/domain/entities/content_report_entity.dart';

/// A reusable button component for reporting content
class ReportButton extends StatelessWidget {
  /// ID of the content to report
  final String contentId;
  
  /// Type of content being reported
  final ReportedContentType contentType;
  
  /// Preview text of the content being reported
  final String contentPreview;
  
  /// ID of the content owner
  final String? ownerId;
  
  /// Size of the button icon
  final double size;
  
  /// Color of the button icon
  final Color? color;
  
  /// Whether to show button text
  final bool showText;
  
  /// Button text to show if showText is true
  final String buttonText;

  /// Constructor
  const ReportButton({
    Key? key,
    required this.contentId,
    required this.contentType,
    required this.contentPreview,
    this.ownerId,
    this.size = 16,
    this.color,
    this.showText = false,
    this.buttonText = 'Report',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        showReportDialog(
          context,
          contentId: contentId,
          contentType: contentType,
          contentPreview: contentPreview,
          ownerId: ownerId,
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.flag_outlined,
              size: size,
              color: color ?? Colors.white54,
            ),
            if (showText) ...[
              const SizedBox(width: 4),
              Text(
                buttonText,
                style: TextStyle(
                  fontSize: size * 0.9,
                  color: color ?? Colors.white54,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 