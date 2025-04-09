import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/content_report_entity.dart';
import '../../domain/entities/moderation_action_entity.dart';
import '../widgets/section_header.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/common/glass_container.dart';
import 'package:hive_ui/features/moderation/presentation/providers/moderation_providers.dart';

class ReportDetailsScreen extends ConsumerStatefulWidget {
  final ContentReportEntity report;

  const ReportDetailsScreen({
    Key? key,
    required this.report,
  }) : super(key: key);

  @override
  ConsumerState<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends ConsumerState<ReportDetailsScreen> {
  bool _isLoading = false;
  bool _showContentPreview = false;
  final TextEditingController _noteController = TextEditingController();
  ModerationActionType _selectedAction = ModerationActionType.markSafe;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report Status badge
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor(),
                    width: 1,
                  ),
                ),
                child: Text(
                  _getStatusLabel(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Report Info
            const SectionHeader(
              title: 'Report Information',
              icon: Icons.info_outline,
            ),
            const SizedBox(height: 16),
            GlassContainer(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow('Report ID', widget.report.id),
                    const Divider(height: 24, color: Colors.white24),
                    _buildInfoRow('Content Type', _getContentTypeLabel()),
                    const Divider(height: 24, color: Colors.white24),
                    _buildInfoRow('Reason', _getReasonLabel()),
                    const Divider(height: 24, color: Colors.white24),
                    _buildInfoRow('Created', _formatDateTime(widget.report.createdAt)),
                    const Divider(height: 24, color: Colors.white24),
                    _buildInfoRow('Updated', _formatDateTime(widget.report.updatedAt)),
                    if (widget.report.resolvedByUserId != null) ...[
                      const Divider(height: 24, color: Colors.white24),
                      _buildInfoRow('Resolved By', widget.report.resolvedByUserId!),
                    ],
                    if (widget.report.details != null && widget.report.details!.isNotEmpty) ...[
                      const Divider(height: 24, color: Colors.white24),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Reporter Description:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.report.details!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Content Preview
            const SectionHeader(
              title: 'Reported Content',
              icon: Icons.content_paste,
            ),
            const SizedBox(height: 16),
            GlassContainer(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_showContentPreview) ...[
                      // This would be replaced with actual content preview
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Content Preview',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'This is where the reported content would be displayed. In a real implementation, this would show the actual content that was reported.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton.icon(
                          icon: const Icon(Icons.visibility_off),
                          label: const Text('Hide Content'),
                          onPressed: () {
                            setState(() {
                              _showContentPreview = false;
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
                          ),
                        ),
                      ),
                    ] else ...[
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.visibility_off,
                              size: 48,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Content preview is hidden for safety',
                              style: TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              icon: const Icon(Icons.visibility),
                              label: const Text('Show Content'),
                              onPressed: () {
                                setState(() {
                                  _showContentPreview = true;
                                });
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Don't show moderation actions for already resolved reports
            if (!widget.report.isProcessed) ...[
              const SizedBox(height: 24),
              
              // Moderation Actions
              const SectionHeader(
                title: 'Moderation Actions',
                icon: Icons.gavel,
              ),
              const SizedBox(height: 16),
              GlassContainer(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Action:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Action selection radio buttons
                      _buildActionRadio(
                        ModerationActionType.markSafe, 
                        'Mark as Safe', 
                        'No action needed, content does not violate guidelines',
                        Icons.check_circle,
                        Colors.green,
                      ),
                      _buildActionRadio(
                        ModerationActionType.hideContent, 
                        'Hide Content', 
                        'Content is hidden but not removed',
                        Icons.visibility_off,
                        Colors.orange,
                      ),
                      _buildActionRadio(
                        ModerationActionType.removeContent, 
                        'Remove Content', 
                        'Content is removed for violating guidelines',
                        Icons.delete,
                        Colors.red,
                      ),
                      _buildActionRadio(
                        ModerationActionType.warnUser, 
                        'Warn User', 
                        'Send a warning message to the user',
                        Icons.warning,
                        Colors.amber,
                      ),
                      _buildActionRadio(
                        ModerationActionType.escalateToAdmin, 
                        'Escalate to Admin', 
                        'Send to admin for further review',
                        Icons.upgrade,
                        Colors.purple,
                      ),
                      
                      const SizedBox(height: 16),
                      const Text(
                        'Moderator Notes:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _noteController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Enter notes about this moderation action...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                          filled: true,
                          fillColor: Colors.black.withOpacity(0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.gold,
                              width: 1,
                            ),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Submit action button
                      Center(
                        child: ElevatedButton.icon(
                          icon: _isLoading 
                            ? Container(
                                width: 24,
                                height: 24,
                                padding: const EdgeInsets.all(2),
                                child: const CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Icon(Icons.send),
                          label: Text(_isLoading ? 'Submitting...' : 'Submit Action'),
                          onPressed: _isLoading ? null : _submitAction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionRadio(
    ModerationActionType action,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _selectedAction == action
            ? color.withOpacity(0.15)
            : Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _selectedAction == action
              ? color
              : Colors.white.withOpacity(0.1),
          width: _selectedAction == action ? 1 : 0.5,
        ),
      ),
      child: RadioListTile<ModerationActionType>(
        title: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: _selectedAction == action ? color : Colors.white,
                fontWeight: _selectedAction == action ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        value: action,
        groupValue: _selectedAction,
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedAction = value;
            });
          }
        },
        activeColor: color,
        dense: true,
      ),
    );
  }

  void _submitAction() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await ref.read(moderationControllerProvider.notifier).moderateContent(
        reportId: widget.report.id,
        actionType: _selectedAction,
        note: _noteController.text.trim(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Moderation action applied successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _getStatusColor() {
    switch (widget.report.status) {
      case ReportStatus.pending:
        return Colors.orangeAccent;
      case ReportStatus.underReview:
        return Colors.blueAccent;
      case ReportStatus.resolved:
        return Colors.greenAccent;
      case ReportStatus.dismissed:
        return Colors.grey;
    }
  }

  String _getStatusLabel() {
    switch (widget.report.status) {
      case ReportStatus.pending:
        return 'Pending';
      case ReportStatus.underReview:
        return 'Under Review';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.dismissed:
        return 'Dismissed';
    }
  }

  String _getContentTypeLabel() {
    switch (widget.report.contentType) {
      case ReportedContentType.post:
        return 'Post';
      case ReportedContentType.comment:
        return 'Comment';
      case ReportedContentType.message:
        return 'Message';
      case ReportedContentType.space:
        return 'Space';
      case ReportedContentType.event:
        return 'Event';
      case ReportedContentType.profile:
        return 'Profile';
    }
  }

  String _getReasonLabel() {
    switch (widget.report.reason) {
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.harassment:
        return 'Harassment';
      case ReportReason.hateSpeech:
        return 'Hate Speech';
      case ReportReason.inappropriateContent:
        return 'Inappropriate Content';
      case ReportReason.violatesGuidelines:
        return 'Violates Guidelines';
      case ReportReason.other:
        return 'Other';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
} 