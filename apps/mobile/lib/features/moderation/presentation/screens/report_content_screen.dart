import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/content_report_entity.dart';
import '../controllers/report_controller.dart';
import '../widgets/report_reason_selector.dart';
import '../widgets/report_description_field.dart';
import '../widgets/report_evidence_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/glass_container.dart';
import '../widgets/section_header.dart';

class ReportContentScreen extends ConsumerStatefulWidget {
  final String contentId;
  final String contentType; // e.g., 'post', 'comment', 'space', 'event', 'profile'
  final String? ownerId;
  final String contentPreview; // Brief content summary to display

  const ReportContentScreen({
    Key? key,
    required this.contentId,
    required this.contentType,
    required this.contentPreview,
    this.ownerId,
  }) : super(key: key);

  @override
  ConsumerState<ReportContentScreen> createState() => _ReportContentScreenState();
}

class _ReportContentScreenState extends ConsumerState<ReportContentScreen> {
  ReportReason _selectedReason = ReportReason.inappropriateContent;
  String _description = '';
  final List<String> _evidenceLinks = [];
  bool _isSubmitting = false;

  void _submitReport() async {
    if (_description.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a description of the issue')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(reportControllerProvider.notifier).reportContent(
        contentId: widget.contentId,
        contentType: widget.contentType,
        reason: _selectedReason,
        description: _description,
        evidenceLinks: _evidenceLinks,
        reportedUserId: widget.ownerId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit report: ${e.toString()}')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Content'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassContainer(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Content Being Reported'),
                    const SizedBox(height: 8),
                    Text(
                      'Type: ${widget.contentType.toUpperCase()}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Preview: ${widget.contentPreview}',
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            const SectionHeader(title: 'Report Details'),
            const SizedBox(height: 16),
            
            ReportReasonSelector(
              selectedReason: _selectedReason,
              onReasonChanged: (reason) {
                setState(() {
                  _selectedReason = reason;
                });
              },
            ),
            
            const SizedBox(height: 24),
            
            ReportDescriptionField(
              initialValue: _description,
              onChanged: (value) {
                setState(() {
                  _description = value;
                });
              },
            ),
            
            const SizedBox(height: 24),
            
            ReportEvidenceField(
              evidenceLinks: _evidenceLinks,
              onEvidenceAdded: (link) {
                setState(() {
                  _evidenceLinks.add(link);
                });
              },
              onEvidenceRemoved: (index) {
                setState(() {
                  _evidenceLinks.removeAt(index);
                });
              },
            ),
            
            const SizedBox(height: 32),
            
            Center(
              child: PrimaryButton(
                onPressed: _isSubmitting ? null : _submitReport,
                text: _isSubmitting ? 'Submitting...' : 'Submit Report',
                isLoading: _isSubmitting,
                width: 200,
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
} 