import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_ui/core/services/event_state_manager.dart';

/// A widget that allows administrators or event owners to manage
/// the lifecycle state of an event
class EventLifecycleManager extends ConsumerStatefulWidget {
  /// The event to manage
  final Event event;
  
  /// Callback when the state is changed
  final Function(EventLifecycleState)? onStateChanged;
  
  /// Creates an event lifecycle manager
  const EventLifecycleManager({
    Key? key,
    required this.event,
    this.onStateChanged,
  }) : super(key: key);

  @override
  ConsumerState<EventLifecycleManager> createState() => _EventLifecycleManagerState();
}

class _EventLifecycleManagerState extends ConsumerState<EventLifecycleManager> {
  final EventStateManager _stateManager = EventStateManager();
  bool _isUpdating = false;
  bool _canEdit = false;
  
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }
  
  @override
  void didUpdateWidget(EventLifecycleManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.event.id != widget.event.id) {
      _checkPermissions();
    }
  }
  
  Future<void> _checkPermissions() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      // Check if user is admin or event owner
      final canEdit = await _stateManager.canEditEvent(widget.event.id);
      
      if (mounted) {
        setState(() {
          _canEdit = canEdit;
        });
      }
    }
  }
  
  Future<void> _updateState(EventLifecycleState newState) async {
    if (_isUpdating) return;
    
    setState(() {
      _isUpdating = true;
    });
    
    try {
      HapticFeedback.mediumImpact();
      
      final success = await _stateManager.transitionEventState(
        widget.event.id, 
        newState,
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event updated to ${_getStateLabel(newState)}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
        
        widget.onStateChanged?.call(newState);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update event state'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }
  
  String _getStateLabel(EventLifecycleState state) {
    switch (state) {
      case EventLifecycleState.draft:
        return 'Draft';
      case EventLifecycleState.published:
        return 'Published';
      case EventLifecycleState.live:
        return 'Live';
      case EventLifecycleState.completed:
        return 'Completed';
      case EventLifecycleState.archived:
        return 'Archived';
    }
  }
  
  void _showStateSelector() {
    final currentState = widget.event.currentState;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.dark2,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Update Event Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const Divider(color: Colors.white10),
            ...EventLifecycleState.values.map((state) {
              final isCurrentState = state == currentState;
              
              return ListTile(
                title: Text(
                  _getStateLabel(state),
                  style: TextStyle(
                    color: isCurrentState ? AppColors.gold : AppColors.textDark,
                    fontWeight: isCurrentState ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                leading: Icon(
                  _getStateIcon(state),
                  color: isCurrentState ? AppColors.gold : AppColors.grey,
                ),
                trailing: isCurrentState 
                  ? const Icon(Icons.check_circle, color: AppColors.gold) 
                  : null,
                onTap: isCurrentState 
                  ? () => Navigator.pop(context) 
                  : () {
                      Navigator.pop(context);
                      _updateState(state);
                    },
              );
            }).toList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  IconData _getStateIcon(EventLifecycleState state) {
    switch (state) {
      case EventLifecycleState.draft:
        return Icons.edit_outlined;
      case EventLifecycleState.published:
        return Icons.event_available_outlined;
      case EventLifecycleState.live:
        return Icons.live_tv_outlined;
      case EventLifecycleState.completed:
        return Icons.check_circle_outline;
      case EventLifecycleState.archived:
        return Icons.archive_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_canEdit) {
      return const SizedBox.shrink(); // Don't show if user can't edit
    }
    
    return ElevatedButton.icon(
      onPressed: _isUpdating ? null : _showStateSelector,
      icon: _isUpdating 
        ? const SizedBox(
            width: 16, 
            height: 16, 
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(_getStateIcon(widget.event.currentState)),
      label: Text(_isUpdating 
        ? 'Updating...' 
        : 'Update Status: ${_getStateLabel(widget.event.currentState)}'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.dark3,
        foregroundColor: AppColors.textDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
      ),
    );
  }
} 