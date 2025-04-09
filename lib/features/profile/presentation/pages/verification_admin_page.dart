import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/common/widgets/glassmorphic_container.dart';
import 'package:hive_ui/core/providers/role_checker_provider.dart';
import 'package:hive_ui/core/services/role_checker.dart';
import 'package:hive_ui/features/profile/domain/entities/verification_status.dart';
import 'package:hive_ui/features/profile/presentation/providers/verification_admin_provider.dart';
import 'package:hive_ui/features/profile/presentation/widgets/verification_badge.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_provider.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:intl/intl.dart';

/// Admin page for approving verification requests
class VerificationAdminPage extends ConsumerWidget {
  const VerificationAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if user is admin
    final isAdmin = ref.watch(hasRoleProvider(UserRole.admin));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Verification Management',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: isAdmin.when(
        data: (isAdmin) {
          if (!isAdmin) {
            return Center(
              child: Text(
                'You do not have permission to access this page',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            );
          }

          return _buildAdminPanel(context, ref);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Error: $error',
            style: GoogleFonts.poppins(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminPanel(BuildContext context, WidgetRef ref) {
    final pendingRequests = ref.watch(pendingVerificationRequestsProvider);

    return pendingRequests.when(
      data: (requests) {
        if (requests.isEmpty) {
          return Center(
            child: Text(
              'No pending verification requests',
              style: GoogleFonts.poppins(),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _buildRequestCard(context, ref, request);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          'Error loading requests: $error',
          style: GoogleFonts.poppins(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, WidgetRef ref, VerificationRequest request) {
    final spaceDetails = ref.watch(spaceProvider(request.spaceId));
    final isProcessing = ref.watch(processingRequestIdsProvider).contains(request.id);

    return GlassmorphicContainer(
      margin: const EdgeInsets.only(bottom: 16.0),
      borderRadius: 16,
      blur: 20,
      border: 2,
      linearGradient: AppColors.glassGradient,
      borderGradient: AppColors.glassGradient,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: request.userPhotoUrl != null
                      ? NetworkImage(request.userPhotoUrl!)
                      : null,
                  radius: 24,
                  child: request.userPhotoUrl == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.userName ?? 'Unknown User',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        request.userEmail ?? 'No email',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                VerificationBadge(
                  level: VerificationLevel.values[request.currentLevel],
                  size: 24,
                ),
                const Icon(Icons.arrow_forward, color: AppColors.gold),
                VerificationBadge(
                  level: VerificationLevel.values[request.requestedLevel],
                  size: 24,
                ),
              ],
            ),
            const Divider(height: 32, color: Colors.white24),
            spaceDetails.when(
              data: (space) => _buildSpaceInfo(space.name),
              loading: () => const Text('Loading space details...'),
              error: (_, __) => const Text('Failed to load space'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.work, size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  'Role: ${request.role}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            if (request.additionalInfo != null && request.additionalInfo!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Additional Information:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                request.additionalInfo!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Submitted: ${DateFormat.yMMMd().add_jm().format(request.createdAt)}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: isProcessing
                      ? null
                      : () => _showRejectDialog(context, ref, request),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: Text(
                    'Reject',
                    style: GoogleFonts.poppins(),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: isProcessing
                      ? null
                      : () => _confirmApprove(context, ref, request),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Approve',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpaceInfo(String spaceName) {
    return Row(
      children: [
        const Icon(Icons.groups, size: 16, color: Colors.white70),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Space: $spaceName',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _confirmApprove(BuildContext context, WidgetRef ref, VerificationRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Approve Request',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to approve this verification request? This will grant Verified+ status and make the user a leader of the selected space.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(verificationAdminProvider.notifier).approveRequest(request.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
            ),
            child: Text(
              'Approve',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref, VerificationRequest request) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reject Request',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please provide a reason for rejection:',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Reason for rejection',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason for rejection'),
                  ),
                );
                return;
              }
              Navigator.of(context).pop();
              ref.read(verificationAdminProvider.notifier).rejectRequest(
                    request.id,
                    reason,
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(
              'Reject',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }
} 