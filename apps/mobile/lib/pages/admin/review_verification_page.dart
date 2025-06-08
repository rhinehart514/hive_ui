import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/widgets/hive_primary_button.dart';
import 'package:hive_ui/core/widgets/hive_secondary_button.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_layout.dart';
import 'package:hive_ui/theme/dark_surface.dart';
import 'package:hive_ui/utils/feedback_util.dart';
import 'package:flutter_animate/flutter_animate.dart';

// TODO: Replace with actual data model and provider
class VerificationRequest {
  final String id; 
  final String name;
  final String email;
  final String documentUrl; // URL to the verification document (e.g., image)
  final DateTime submittedAt;

  VerificationRequest({
    required this.id,
    required this.name,
    required this.email,
    required this.documentUrl,
    required this.submittedAt,
  });
}

// TODO: Replace with actual state management
final verificationListProvider = Provider<List<VerificationRequest>>((ref) {
  // Placeholder data
  return List.generate(5, (index) => VerificationRequest(
    id: 'req_$index',
    name: 'User Name $index',
    email: 'user$index@example.edu',
    documentUrl: 'https://via.placeholder.com/300x200.png?text=Verification+Doc+$index',
    submittedAt: DateTime.now().subtract(Duration(hours: index * 2)),
  ));
});

final adminActionStateProvider = StateProvider<Map<String, bool?>>((ref) => {}); // id -> true (approved), false (denied)

/// Admin screen for reviewing user verification requests.
class AdminReviewVerificationPage extends ConsumerWidget {
  const AdminReviewVerificationPage({super.key});

  Future<void> _handleAction(WidgetRef ref, String id, bool approve) async {
    FeedbackUtil.buttonTap();
    // Update local state for immediate feedback
    ref.read(adminActionStateProvider.notifier).update((state) => {...state, id: approve});
    
    // TODO: Call actual backend API to approve/deny verification
    await Future.delayed(500.ms); // Simulate API call
    
    print('Verification $id ${approve ? 'approved' : 'denied'}');
    // Remove from list or update status after backend confirms
    // For now, it just stays in its approved/denied state visually
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(verificationListProvider);
    final actionStates = ref.watch(adminActionStateProvider);
    final textTheme = Theme.of(context).textTheme;

    return DarkSurface(
      surfaceType: SurfaceType.canvas,
      withGrainTexture: false, // Cleaner admin look
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Review Verifications'),
          backgroundColor: AppColors.dark2, // Slightly different app bar
          elevation: 1,
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(AppLayout.spacingMedium),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final actionState = actionStates[request.id]; // null, true, or false
            bool isProcessing = actionState != null; // Already acted upon

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: AppLayout.spacingMedium),
              color: AppColors.dark2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppLayout.radiusMedium),
                side: const BorderSide(color: AppColors.dark3)
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppLayout.spacingSemixlg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(request.name, style: textTheme.titleMedium),
                        Text(
                          'Submitted: ${TimeAgo.format(request.submittedAt)}', 
                          style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    Text(request.email, style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: AppLayout.spacingMedium),
                    
                    // Document Preview (placeholder)
                    InkWell(
                      onTap: () { /* TODO: Show full document */ },
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: AppColors.dark3,
                          borderRadius: BorderRadius.circular(AppLayout.radiusSmall),
                          image: DecorationImage(
                            image: NetworkImage(request.documentUrl),
                            fit: BoxFit.cover,
                            // Add error builder for broken images
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.visibility, color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: AppLayout.spacingMedium),
                    
                    // Action Buttons with Animated State
                    AnimatedSwitcher(
                      duration: 300.ms,
                      transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                      child: isProcessing
                        ? _buildActionStateIndicator(actionState)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              HiveSecondaryButton(
                                text: 'Deny',
                                onPressed: () => _handleAction(ref, request.id, false),
                                // Custom styling for deny button maybe?
                              ),
                              const SizedBox(width: AppLayout.spacingSmall),
                              HivePrimaryButton(
                                text: 'Approve',
                                onPressed: () => _handleAction(ref, request.id, true),
                                style: HiveButtonStyle.success, // Use success style
                              ),
                            ],
                          ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: (index * 50).ms, duration: 300.ms);
          },
        ),
      ),
    );
  }

  Widget _buildActionStateIndicator(bool approved) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: approved ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppLayout.radiusSmall),
        border: Border.all(color: approved ? AppColors.success : AppColors.error),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(approved ? Icons.check_circle : Icons.cancel, color: approved ? AppColors.success : AppColors.error, size: 18),
          const SizedBox(width: AppLayout.spacingSmall),
          Text(
            approved ? 'Approved' : 'Denied',
            style: TextStyle(color: approved ? AppColors.success : AppColors.error, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// Helper for time ago formatting (replace with intl package or similar)
class TimeAgo {
  static String format(DateTime dt) {
    final duration = DateTime.now().difference(dt);
    if (duration.inMinutes < 1) return 'just now';
    if (duration.inHours < 1) return '${duration.inMinutes}m ago';
    if (duration.inDays < 1) return '${duration.inHours}h ago';
    return '${duration.inDays}d ago';
  }
} 