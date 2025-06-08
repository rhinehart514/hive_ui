import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_text_styles.dart';
import 'package:hive_ui/providers/friend_providers.dart';
import 'package:hive_ui/widgets/friends/friend_request_card.dart';
import 'package:hive_ui/widgets/common/glass_container.dart';

/// A page that displays all pending friend requests
class FriendRequestsPage extends ConsumerStatefulWidget {
  const FriendRequestsPage({super.key});

  @override
  ConsumerState<FriendRequestsPage> createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends ConsumerState<FriendRequestsPage> {
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  
  @override
  void initState() {
    super.initState();
    // Initial data load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }
  
  Future<void> _refresh() async {
    // Force refresh the pending requests
    ref.invalidate(pendingFriendRequestsProvider);
  }
  
  @override
  Widget build(BuildContext context) {
    final pendingRequestsAsync = ref.watch(pendingFriendRequestsProvider);
    
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Friend Requests', style: AppTextStyles.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: RefreshIndicator(
        key: _refreshKey,
        onRefresh: _refresh,
        color: AppColors.yellow,
        backgroundColor: Colors.grey[900],
        child: pendingRequestsAsync.when(
          data: (requests) {
            if (requests.isEmpty) {
              return _buildEmptyState();
            }
            
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final request = requests[index];
                return FriendRequestCard(
                  requestId: request['requestId'],
                  senderId: request['senderId'],
                  senderName: request['senderName'],
                  senderImageUrl: request['senderImage'],
                  senderMajor: request['senderMajor'],
                  senderYear: request['senderYear'],
                  createdAt: request['createdAt'],
                  onRequestHandled: _refresh,
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: AppColors.yellow,
            ),
          ),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load friend requests',
                    style: AppTextStyles.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _refresh();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.yellow,
                      foregroundColor: AppColors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassContainer(
              blur: 5,
              opacity: 0.1,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Pending Requests',
                      style: AppTextStyles.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You don\'t have any friend requests at the moment. When someone sends you a request, it will appear here.',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: () {
                        // Navigate to invite friends or search people page here
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.yellow,
                        side: const BorderSide(
                          color: AppColors.yellow,
                          width: 1.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Find People'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 