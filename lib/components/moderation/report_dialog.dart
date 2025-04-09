import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/moderation/domain/entities/content_report_entity.dart';
import 'package:hive_ui/features/moderation/presentation/controllers/report_controller.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Shows a dialog to report content
Future<bool?> showReportDialog(
  BuildContext context, {
  required String contentId,
  required ReportedContentType contentType,
  required String contentPreview,
  String? ownerId,
}) async {
  return showDialog<bool?>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 10,
                sigmaY: 10,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      'Report ${_getContentTypeName(contentType)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Dialog content
                    _ReportDialogContent(
                      contentId: contentId,
                      contentType: contentType,
                      contentPreview: contentPreview,
                      ownerId: ownerId,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

// Helper to get readable content type name
String _getContentTypeName(ReportedContentType type) {
  switch (type) {
    case ReportedContentType.event:
      return 'Event';
    case ReportedContentType.space:
      return 'Space';
    case ReportedContentType.profile:
      return 'Profile';
    case ReportedContentType.post:
      return 'Post';
    case ReportedContentType.comment:
      return 'Comment';
    case ReportedContentType.message:
      return 'Message';
  }
}

/// The content of the report dialog
class _ReportDialogContent extends ConsumerStatefulWidget {
  final String contentId;
  final ReportedContentType contentType;
  final String contentPreview;
  final String? ownerId;

  const _ReportDialogContent({
    required this.contentId,
    required this.contentType,
    required this.contentPreview,
    this.ownerId,
  });

  @override
  ConsumerState<_ReportDialogContent> createState() => _ReportDialogContentState();
}

class _ReportDialogContentState extends ConsumerState<_ReportDialogContent> {
  ReportReason _selectedReason = ReportReason.violatesGuidelines;
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  // Submit the report
  Future<void> _submitReport() async {
    if (_isSubmitting) return;

    // Set submitting state
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get the report controller
      final reportController = ref.read(reportControllerProvider.notifier);
      
      // Submit the report
      await reportController.reportContent(
        contentId: widget.contentId,
        contentType: widget.contentType.toString().split('.').last,
        reason: _selectedReason,
        description: _detailsController.text,
        reportedUserId: widget.ownerId,
      );
      
      if (mounted) {
        // Show success and close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your report. Our team will review it.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Content preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.white.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: Text(
              widget.contentPreview,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Reason selection
          const Text(
            'Reason for reporting:',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Dropdown for reason selection
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.white.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: DropdownButton<ReportReason>(
              value: _selectedReason,
              isExpanded: true,
              dropdownColor: AppColors.cardBackground,
              underline: const SizedBox(),
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 14,
              ),
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.white),
              onChanged: (ReportReason? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedReason = newValue;
                  });
                }
              },
              items: ReportReason.values.map<DropdownMenuItem<ReportReason>>((ReportReason reason) {
                return DropdownMenuItem<ReportReason>(
                  value: reason,
                  child: Text(_getReasonText(reason)),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Details field
          const Text(
            'Additional details:',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          TextField(
            controller: _detailsController,
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(
              hintText: 'Please provide any additional details that may help us understand the issue',
              hintStyle: TextStyle(
                color: AppColors.white.withOpacity(0.4),
                fontSize: 14,
              ),
              filled: true,
              fillColor: Colors.black.withOpacity(0.2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.white.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.white.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.white.withOpacity(0.3),
                  width: 1.0,
                ),
              ),
              counterStyle: TextStyle(
                color: AppColors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Cancel button
              TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.white.withOpacity(0.7),
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              
              // Submit button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: AppColors.gold.withOpacity(0.5),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : const Text('Submit'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Helper to get readable reason text
  String _getReasonText(ReportReason reason) {
    switch (reason) {
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.harassment:
        return 'Harassment or bullying';
      case ReportReason.hateSpeech:
        return 'Hate speech';
      case ReportReason.inappropriateContent:
        return 'Inappropriate content';
      case ReportReason.violatesGuidelines:
        return 'Violates community guidelines';
      case ReportReason.other:
        return 'Other';
    }
  }
} 