import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_text_styles.dart';
import 'package:hive_ui/providers/friend_providers.dart';

/// Friend connection states
enum FriendConnectionState {
  /// Not connected and no pending requests
  notFriends,
  
  /// Request sent by the current user
  requestSent,
  
  /// Request received from the other user
  requestReceived,
  
  /// Users are friends
  friends,
  
  /// Initial loading state
  loading,
  
  /// Error state
  error,
}

/// A button that handles different friend connection states
class FriendRequestButton extends ConsumerStatefulWidget {
  /// The user ID to connect with
  final String userId;
  
  /// Optional initial state - will be determined automatically if not provided
  final FriendConnectionState? initialState;
  
  /// Optional callback when the connection state changes
  final Function(FriendConnectionState)? onConnectionStateChanged;
  
  /// Constructor
  const FriendRequestButton({
    super.key,
    required this.userId,
    this.initialState,
    this.onConnectionStateChanged,
  });

  @override
  ConsumerState<FriendRequestButton> createState() => _FriendRequestButtonState();
}

class _FriendRequestButtonState extends ConsumerState<FriendRequestButton> {
  late FriendConnectionState _connectionState;
  bool _isProcessing = false;
  String? _currentUserId;
  
  @override
  void initState() {
    super.initState();
    _connectionState = widget.initialState ?? FriendConnectionState.loading;
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    if (widget.initialState == null) {
      _determineConnectionState();
    }
  }
  
  Future<void> _determineConnectionState() async {
    if (_currentUserId == null) {
      setState(() {
        _connectionState = FriendConnectionState.error;
      });
      return;
    }
    
    // Don't allow sending friend requests to yourself
    if (_currentUserId == widget.userId) {
      setState(() {
        _connectionState = FriendConnectionState.error;
      });
      return;
    }
    
    try {
      setState(() {
        _connectionState = FriendConnectionState.loading;
      });
      
      // Check if already friends
      final areFriends = await ref.read(
        checkFriendshipProvider(widget.userId).future,
      );
      
      if (areFriends) {
        setState(() {
          _connectionState = FriendConnectionState.friends;
        });
        return;
      }
      
      // Check if there's a pending request from the other user
      final hasPendingRequest = await ref.read(
        hasPendingRequestFromProvider(widget.userId).future,
      );
      
      if (hasPendingRequest) {
        setState(() {
          _connectionState = FriendConnectionState.requestReceived;
        });
        return;
      }
      
      // Check if current user sent a request already
      final hasOutgoingRequest = await ref.read(
        hasOutgoingRequestProvider(widget.userId).future,
      );
      
      if (hasOutgoingRequest) {
        setState(() {
          _connectionState = FriendConnectionState.requestSent;
        });
        return;
      }
      
      // No connection exists
      setState(() {
        _connectionState = FriendConnectionState.notFriends;
      });
    } catch (e) {
      setState(() {
        _connectionState = FriendConnectionState.error;
      });
    }
  }
  
  Future<void> _sendFriendRequest() async {
    if (_isProcessing) return;
    
    HapticFeedback.mediumImpact();
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      final success = await ref.read(
        sendFriendRequestProvider(widget.userId).future,
      );
      
      if (success) {
        setState(() {
          _connectionState = FriendConnectionState.requestSent;
          _isProcessing = false;
        });
        
        if (widget.onConnectionStateChanged != null) {
          widget.onConnectionStateChanged!(FriendConnectionState.requestSent);
        }
        
        if (mounted) {
          _showSuccessMessage('Friend request sent');
        }
      } else {
        setState(() {
          _isProcessing = false;
        });
        
        if (mounted) {
          _showErrorMessage('Failed to send friend request');
        }
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      
      if (mounted) {
        _showErrorMessage('Error: ${e.toString()}');
      }
    }
  }
  
  Future<void> _cancelFriendRequest() async {
    // Not implemented yet in the friend service
    _showErrorMessage('Canceling requests is not available yet');
  }
  
  Future<void> _removeFriend() async {
    if (_isProcessing) return;
    
    HapticFeedback.mediumImpact();
    
    // Show confirmation dialog
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Remove Friend',
          style: AppTextStyles.titleLarge,
        ),
        content: Text(
          'Are you sure you want to remove this friend?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelMedium.copyWith(
                color: Colors.white,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red[400],
            ),
            child: Text(
              'Remove',
              style: AppTextStyles.labelMedium.copyWith(
                color: Colors.red[400],
              ),
            ),
          ),
        ],
      ),
    ) ?? false;
    
    if (!shouldRemove || !mounted) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      final success = await ref.read(
        removeFriendProvider(widget.userId).future,
      );
      
      if (success) {
        setState(() {
          _connectionState = FriendConnectionState.notFriends;
          _isProcessing = false;
        });
        
        if (widget.onConnectionStateChanged != null) {
          widget.onConnectionStateChanged!(FriendConnectionState.notFriends);
        }
        
        if (mounted) {
          _showSuccessMessage('Friend removed');
        }
      } else {
        setState(() {
          _isProcessing = false;
        });
        
        if (mounted) {
          _showErrorMessage('Failed to remove friend');
        }
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      
      if (mounted) {
        _showErrorMessage('Error: ${e.toString()}');
      }
    }
  }
  
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
  
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    switch (_connectionState) {
      case FriendConnectionState.notFriends:
        return _buildAddFriendButton();
      case FriendConnectionState.requestSent:
        return _buildRequestSentButton();
      case FriendConnectionState.requestReceived:
        return _buildRequestReceivedButton();
      case FriendConnectionState.friends:
        return _buildFriendsButton();
      case FriendConnectionState.loading:
        return _buildLoadingButton();
      case FriendConnectionState.error:
        return _buildErrorButton();
    }
  }
  
  Widget _buildAddFriendButton() {
    return OutlinedButton.icon(
      onPressed: _isProcessing ? null : _sendFriendRequest,
      icon: _isProcessing 
          ? const SizedBox(
              width: 16, 
              height: 16, 
              child: CircularProgressIndicator(
                color: AppColors.yellow,
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.person_add_alt),
      label: const Text('Add Friend'),
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
          horizontal: 16,
          vertical: 10,
        ),
      ).copyWith(
        overlayColor: MaterialStateProperty.resolveWith<Color?>(
          (states) {
            if (states.contains(MaterialState.pressed)) {
              return AppColors.yellow.withOpacity(0.15);
            }
            return null;
          },
        ),
      ),
    );
  }
  
  Widget _buildRequestSentButton() {
    return OutlinedButton.icon(
      onPressed: _isProcessing ? null : _cancelFriendRequest,
      icon: const Icon(Icons.hourglass_top),
      label: const Text('Request Sent'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(
          color: Colors.white.withOpacity(0.3),
          width: 1.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
      ),
    );
  }
  
  Widget _buildRequestReceivedButton() {
    return OutlinedButton.icon(
      onPressed: () {
        // Navigate to friend requests page
        HapticFeedback.lightImpact();
        Navigator.of(context).pushNamed('/friend-requests');
      },
      icon: const Icon(Icons.notifications_active),
      label: const Text('Respond to Request'),
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
          horizontal: 16,
          vertical: 10,
        ),
      ),
    );
  }
  
  Widget _buildFriendsButton() {
    return OutlinedButton.icon(
      onPressed: _isProcessing ? null : _removeFriend,
      icon: _isProcessing 
          ? const SizedBox(
              width: 16, 
              height: 16, 
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.people),
      label: const Text('Friends'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(
          color: Colors.white.withOpacity(0.3),
          width: 1.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
      ),
    );
  }
  
  Widget _buildLoadingButton() {
    return OutlinedButton(
      onPressed: null,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(
          color: Colors.white.withOpacity(0.3),
          width: 1.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
      ),
      child: const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      ),
    );
  }
  
  Widget _buildErrorButton() {
    return OutlinedButton.icon(
      onPressed: _determineConnectionState,
      icon: const Icon(Icons.refresh),
      label: const Text('Retry'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red[400],
        side: BorderSide(
          color: Colors.red[400]!,
          width: 1.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
      ),
    );
  }
} 