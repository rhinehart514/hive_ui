import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/utils/feedback_util.dart';
import 'package:hive_ui/widgets/buttons/hive_primary_button.dart';

/// Admin page for approving verification requests
class VerificationAdminPage extends ConsumerStatefulWidget {
  const VerificationAdminPage({Key? key}) : super(key: key);

  @override
  ConsumerState<VerificationAdminPage> createState() => _VerificationAdminPageState();
}

class _VerificationAdminPageState extends ConsumerState<VerificationAdminPage> {
  bool _isLoading = true;
  List<VerificationRequest> _requests = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchVerificationRequests();
  }

  Future<void> _fetchVerificationRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Simulated data for now - would connect to Firestore in real implementation
      await Future.delayed(const Duration(seconds: 1));
      
      final dummyRequests = [
        VerificationRequest(
          id: '1',
          userId: 'user1',
          name: 'John Smith',
          email: 'jsmith@university.edu',
          role: 'Professor',
          department: 'Computer Science',
          reason: 'I am a professor teaching CS 101 and want to create a space for my class.',
          submittedAt: DateTime.now().subtract(const Duration(days: 2)),
          status: VerificationStatus.pending,
        ),
        VerificationRequest(
          id: '2',
          userId: 'user2',
          name: 'Emma Johnson',
          email: 'ejohnson@university.edu',
          role: 'Student Government',
          department: 'Student Affairs',
          reason: 'I am the president of the student government and need to create official announcements.',
          submittedAt: DateTime.now().subtract(const Duration(hours: 5)),
          status: VerificationStatus.pending,
        ),
      ];
      
      setState(() {
        _requests = dummyRequests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load verification requests: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateRequestStatus(String requestId, VerificationStatus newStatus) async {
    FeedbackUtil.buttonTap();
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Simulated API call - would call Firebase Function in real implementation
      await Future.delayed(const Duration(milliseconds: 800));
      
      setState(() {
        _requests = _requests.map((request) {
          if (request.id == requestId) {
            return request.copyWith(status: newStatus);
          }
          return request;
        }).toList();
        
        _isLoading = false;
      });
      
      FeedbackUtil.success();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == VerificationStatus.approved
                ? 'User has been verified'
                : 'Request has been rejected',
          ),
          backgroundColor: newStatus == VerificationStatus.approved
              ? AppColors.success
              : AppColors.error,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update status: ${e.toString()}';
        _isLoading = false;
      });
      
      FeedbackUtil.error();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        title: const Text('Verification Requests'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchVerificationRequests,
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            HivePrimaryButton(
              text: 'Retry',
              onPressed: _fetchVerificationRequests,
            ),
          ],
        ),
      );
    }

    if (_requests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.gold, size: 48),
            SizedBox(height: 16),
            Text(
              'No pending verification requests',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _requests.length,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      itemBuilder: (context, index) {
        final request = _requests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildRequestCard(VerificationRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.dark2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: request.status == VerificationStatus.pending
              ? AppColors.inputBorder
              : request.status == VerificationStatus.approved
                  ? AppColors.success
                  : AppColors.error,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(request.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              request.email,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              '${request.role} - ${request.department}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const Divider(color: AppColors.inputBorder, height: 24),
            const Text(
              'Reason for verification:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              request.reason,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              'Submitted ${_formatDateTime(request.submittedAt)}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            if (request.status == VerificationStatus.pending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateRequestStatus(
                        request.id,
                        VerificationStatus.rejected,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateRequestStatus(
                        request.id,
                        VerificationStatus.approved,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(VerificationStatus status) {
    Color chipColor;
    String label;
    
    switch (status) {
      case VerificationStatus.pending:
        chipColor = AppColors.gold;
        label = 'Pending';
        break;
      case VerificationStatus.approved:
        chipColor = AppColors.success;
        label = 'Approved';
        break;
      case VerificationStatus.rejected:
        chipColor = AppColors.error;
        label = 'Rejected';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chipColor),
      ),
      child: Text(
        label,
        style: TextStyle(color: chipColor, fontSize: 12),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'just now';
    }
  }
}

/// Status of a verification request
enum VerificationStatus {
  pending,
  approved,
  rejected,
}

/// Model representing a verification request
class VerificationRequest {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String role;
  final String department;
  final String reason;
  final DateTime submittedAt;
  final VerificationStatus status;

  VerificationRequest({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.reason,
    required this.submittedAt,
    required this.status,
  });

  /// Creates a copy of the verification request with updated fields
  VerificationRequest copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? role,
    String? department,
    String? reason,
    DateTime? submittedAt,
    VerificationStatus? status,
  }) {
    return VerificationRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      reason: reason ?? this.reason,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
    );
  }
} 