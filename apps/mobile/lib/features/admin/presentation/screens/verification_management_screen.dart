import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:hive_ui/core/theme/app_colors.dart';
import 'package:hive_ui/core/theme/app_typography.dart';
import 'package:hive_ui/widgets/hive_app_bar.dart';
import 'package:hive_ui/widgets/buttons/hive_primary_button.dart';
import 'package:hive_ui/widgets/buttons/hive_secondary_button.dart';
import 'package:hive_ui/utils/feedback_util.dart';
import 'package:hive_ui/core/haptics/haptic_feedback_manager.dart';
import 'package:hive_ui/features/admin/domain/entities/verification_request.dart';

// Define necessary providers if they don't exist elsewhere
final verificationAdminRepositoryProvider = Provider<VerificationAdminRepository>((ref) {
  // This should be a proper implementation in a real app
  throw UnimplementedError('This is a placeholder for demonstration');
});

final filteredVerificationRequestsProvider = Provider.family<List<VerificationRequest>, VerificationRequestStatus>((ref, status) {
  // This should be a proper implementation in a real app
  // Filtering should happen based on the status parameter
  return [];
});

// Define or mock necessary interfaces/classes for compilation
class VerificationAdminRepository {
  Future<void> approveRequest({required String requestId, required String adminId}) async {
    // Implementation details
  }
  
  Future<void> rejectRequest({required String requestId, required String adminId, required String reason}) async {
    // Implementation details
  }
  
  Future<void> flagForReview({required String requestId, required String adminId, required String notes}) async {
    // Implementation details
  }
}

class VerificationManagementScreen extends ConsumerStatefulWidget {
  const VerificationManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<VerificationManagementScreen> createState() => _VerificationManagementScreenState();
}

class _VerificationManagementScreenState extends ConsumerState<VerificationManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _rejectionReasonController = TextEditingController();
  final TextEditingController _flagNotesController = TextEditingController();
  VerificationRequestStatus _currentFilter = VerificationRequestStatus.pending;
  final _dateFormat = DateFormat('MM/dd/yyyy hh:mm a');
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _rejectionReasonController.dispose();
    _flagNotesController.dispose();
    super.dispose();
  }
  
  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      switch (_tabController.index) {
        case 0:
          setState(() {
            _currentFilter = VerificationRequestStatus.pending;
          });
          break;
        case 1:
          setState(() {
            _currentFilter = VerificationRequestStatus.approved;
          });
          break;
        case 2:
          setState(() {
            _currentFilter = VerificationRequestStatus.rejected;
          });
          break;
      }
    }
  }
  
  Future<void> _approveRequest(VerificationRequest request) async {
    try {
      // In a real implementation, we would get the admin ID from the current user
      const adminId = 'current-admin-id'; // Placeholder
      
      await ref.read(verificationAdminRepositoryProvider).approveRequest(
        requestId: request.id,
        adminId: adminId,
      );
      
      HapticFeedbackManager().mediumImpact();
      
      if (mounted) {
        FeedbackUtil.showToast(
          context: context,
          message: 'Request approved successfully',
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        FeedbackUtil.showToast(
          context: context,
          message: 'Failed to approve request: ${e.toString()}',
          isError: true,
        );
      }
    }
  }
  
  Future<void> _showRejectDialog(VerificationRequest request) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          title: Text(
            'Reject Verification Request',
            style: AppTypography.titleMedium,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please provide a reason for rejection:',
                style: AppTypography.bodyLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _rejectionReasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Rejection reason...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.accentGold),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _rejectionReasonController.clear();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                if (_rejectionReasonController.text.trim().isEmpty) {
                  FeedbackUtil.showToast(
                    context: context,
                    message: 'Rejection reason is required',
                    isError: true,
                  );
                  return;
                }
                
                Navigator.of(context).pop();
                _rejectRequest(
                  request, 
                  _rejectionReasonController.text.trim(),
                );
                _rejectionReasonController.clear();
              },
              child: const Text(
                'Reject',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _rejectRequest(VerificationRequest request, String reason) async {
    try {
      // In a real implementation, we would get the admin ID from the current user
      const adminId = 'current-admin-id'; // Placeholder
      
      await ref.read(verificationAdminRepositoryProvider).rejectRequest(
        requestId: request.id,
        adminId: adminId,
        reason: reason,
      );
      
      HapticFeedbackManager().mediumImpact();
      
      if (mounted) {
        FeedbackUtil.showToast(
          context: context,
          message: 'Request rejected',
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        FeedbackUtil.showToast(
          context: context,
          message: 'Failed to reject request: ${e.toString()}',
          isError: true,
        );
      }
    }
  }
  
  Future<void> _showFlagDialog(VerificationRequest request) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          title: Text(
            'Flag for Review',
            style: AppTypography.titleMedium,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please provide notes for why this request needs additional review:',
                style: AppTypography.bodyLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _flagNotesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Flag notes...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.accentGold),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _flagNotesController.clear();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                if (_flagNotesController.text.trim().isEmpty) {
                  FeedbackUtil.showToast(
                    context: context,
                    message: 'Flag notes are required',
                    isError: true,
                  );
                  return;
                }
                
                Navigator.of(context).pop();
                _flagForReview(
                  request, 
                  _flagNotesController.text.trim(),
                );
                _flagNotesController.clear();
              },
              child: const Text(
                'Flag',
                style: TextStyle(color: AppColors.warning),
              ),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _flagForReview(VerificationRequest request, String notes) async {
    try {
      // In a real implementation, we would get the admin ID from the current user
      const adminId = 'current-admin-id'; // Placeholder
      
      await ref.read(verificationAdminRepositoryProvider).flagForReview(
        requestId: request.id,
        adminId: adminId,
        notes: notes,
      );
      
      HapticFeedbackManager().mediumImpact();
      
      if (mounted) {
        FeedbackUtil.showToast(
          context: context,
          message: 'Request flagged for review',
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        FeedbackUtil.showToast(
          context: context,
          message: 'Failed to flag request: ${e.toString()}',
          isError: true,
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: const HiveAppBar(
        title: 'Verification Requests',
        centerTitle: true,
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Pending'),
              Tab(text: 'Approved'),
              Tab(text: 'Rejected'),
            ],
            indicatorColor: AppColors.accentGold,
            labelColor: AppColors.accentGold,
          ),
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final requests = ref.watch(filteredVerificationRequestsProvider(_currentFilter));
                
                if (requests.isEmpty) {
                  return Center(
                    child: Text(
                      _getEmptyStateMessage(_currentFilter),
                      style: AppTypography.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return _buildRequestCard(request);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  String _getEmptyStateMessage(VerificationRequestStatus status) {
    switch (status) {
      case VerificationRequestStatus.pending:
        return 'No pending verification requests';
      case VerificationRequestStatus.approved:
        return 'No approved verification requests';
      case VerificationRequestStatus.rejected:
        return 'No rejected verification requests';
    }
  }
  
  Widget _buildRequestCard(VerificationRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.surfaceCard.withOpacity(0.8),
                  child: Text(
                    request.userName.substring(0, 1).toUpperCase(),
                    style: AppTypography.titleMedium,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.userName,
                        style: AppTypography.titleMedium,
                      ),
                      Text(
                        request.userEmail,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(request.status),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Submitted: ${_dateFormat.format(request.createdAt)}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (request.justification.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Reason: ${request.justification}',
                style: AppTypography.bodyMedium,
              ),
            ],
            if (request.status == VerificationRequestStatus.pending) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  HiveSecondaryButton(
                    onPressed: () => _showFlagDialog(request),
                    text: 'Flag for Review',
                  ),
                  const SizedBox(width: 8),
                  HiveSecondaryButton(
                    onPressed: () => _showRejectDialog(request),
                    text: 'Reject',
                  ),
                  const SizedBox(width: 8),
                  HivePrimaryButton(
                    onPressed: () => _approveRequest(request),
                    text: 'Approve',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusBadge(VerificationRequestStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case VerificationRequestStatus.pending:
        color = AppColors.warning;
        text = 'Pending';
        break;
      case VerificationRequestStatus.approved:
        color = AppColors.success;
        text = 'Approved';
        break;
      case VerificationRequestStatus.rejected:
        color = AppColors.error;
        text = 'Rejected';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
} 