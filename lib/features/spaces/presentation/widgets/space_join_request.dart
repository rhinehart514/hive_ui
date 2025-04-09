import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/presentation/providers/join_request_provider.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_repository_provider.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Widget to handle the join request flow for private spaces
class SpaceJoinRequest extends ConsumerStatefulWidget {
  /// The space entity to request to join
  final SpaceEntity space;
  
  /// Callback when join status is changed
  final VoidCallback? onJoinStatusChanged;

  /// Constructor
  const SpaceJoinRequest({
    Key? key,
    required this.space,
    this.onJoinStatusChanged,
  }) : super(key: key);

  @override
  ConsumerState<SpaceJoinRequest> createState() => _SpaceJoinRequestState();
}

enum JoinRequestStatus {
  notRequested,
  pending,
  approved,
  rejected,
}

class _SpaceJoinRequestState extends ConsumerState<SpaceJoinRequest> {
  bool _isLoading = false;
  JoinRequestStatus _status = JoinRequestStatus.notRequested;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkJoinRequestStatus();
    });
  }
  
  Future<void> _checkJoinRequestStatus() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser.isEmpty) return;
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Get join request status for this user and space
      final joinRequestAsyncValue = await ref.read(joinRequestProvider((
        spaceId: widget.space.id, 
        userId: currentUser.id,
      )).future);
      
      if (mounted) {
        // Example structure for join request:
        // { status: 'pending', createdAt: timestamp }
        final status = joinRequestAsyncValue['status'] as String? ?? 'none';
        
        setState(() {
          switch (status) {
            case 'pending':
              _status = JoinRequestStatus.pending;
              break;
            case 'approved':
              _status = JoinRequestStatus.approved;
              break;
            case 'rejected':
              _status = JoinRequestStatus.rejected;
              break;
            default:
              _status = JoinRequestStatus.notRequested;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _sendJoinRequest() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser.isEmpty) return;
    
    // Apply haptic feedback
    HapticFeedback.mediumImpact();
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Create the join request
      final repository = ref.read(spaceRepositoryProvider);
      await repository.requestToJoinSpace(widget.space.id, currentUser.id);
      
      if (mounted) {
        setState(() {
          _status = JoinRequestStatus.pending;
          _isLoading = false;
        });
        
        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Join request sent. Space admins will review your request.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        if (widget.onJoinStatusChanged != null) {
          widget.onJoinStatusChanged!();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending join request: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  
  Widget _buildActionButton() {
    // If the user is already a member, show nothing
    if (widget.space.isJoined) {
      return const SizedBox.shrink();
    }
    
    if (_isLoading) {
      return const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
        ),
      );
    }
    
    // If not a private space, don't show request button
    if (!widget.space.isPrivate) {
      return ElevatedButton(
        onPressed: _sendJoinRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Join Space',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      );
    }
    
    switch (_status) {
      case JoinRequestStatus.notRequested:
        return ElevatedButton(
          onPressed: _sendJoinRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Request to Join',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        );
      case JoinRequestStatus.pending:
        return OutlinedButton.icon(
          onPressed: null, // Disabled button
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.orange,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            side: const BorderSide(color: Colors.orange),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.hourglass_empty, size: 16),
          label: Text(
            'Request Pending',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        );
      case JoinRequestStatus.approved:
        return const SizedBox.shrink(); // Should be handled by isJoined
      case JoinRequestStatus.rejected:
        return TextButton.icon(
          onPressed: _sendJoinRequest, // Allow retry
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          icon: const Icon(Icons.refresh, size: 16),
          label: Text(
            'Request Again',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show for spaces the user already joined
    if (widget.space.isJoined) {
      return const SizedBox.shrink();
    }
    
    // For public spaces, just show join button
    if (!widget.space.isPrivate) {
      return _buildActionButton();
    }
    
    // For private spaces with different request states
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lock,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This is a private space',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You need to request permission from admins to join and see content.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: _buildActionButton(),
          ),
          if (_status == JoinRequestStatus.pending)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Your request is being reviewed by space admins.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.orange,
                ),
              ),
            ),
          if (_status == JoinRequestStatus.rejected)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Your previous request was not approved.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.red,
                ),
              ),
            ),
        ],
      ),
    );
  }
} 