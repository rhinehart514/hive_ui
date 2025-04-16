import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_repository_provider.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A widget for managing the lifecycle state of a space
class SpaceLifecycleManagement extends ConsumerStatefulWidget {
  /// The space entity to manage
  final SpaceEntity space;
  
  /// Whether the current user can modify the space
  final bool canModify;
  
  /// Callback when lifecycle state is changed
  final Function(SpaceLifecycleState)? onLifecycleChanged;
  
  /// Constructor
  const SpaceLifecycleManagement({
    Key? key,
    required this.space,
    this.canModify = false,
    this.onLifecycleChanged,
  }) : super(key: key);
  
  @override
  ConsumerState<SpaceLifecycleManagement> createState() => _SpaceLifecycleManagementState();
}

class _SpaceLifecycleManagementState extends ConsumerState<SpaceLifecycleManagement> {
  bool _isExpanded = false;
  bool _isLoading = false;
  SpaceLifecycleState? _selectedState;
  
  @override
  void initState() {
    super.initState();
    _selectedState = widget.space.lifecycleState;
  }
  
  @override
  void didUpdateWidget(SpaceLifecycleManagement oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.space.lifecycleState != widget.space.lifecycleState) {
      setState(() {
        _selectedState = widget.space.lifecycleState;
      });
    }
  }
  
  /// Get color for lifecycle state
  Color _getStateColor(SpaceLifecycleState state) {
    switch (state) {
      case SpaceLifecycleState.created:
        return Colors.blue;
      case SpaceLifecycleState.active:
        return Colors.green;
      case SpaceLifecycleState.dormant:
        return Colors.amber;
      case SpaceLifecycleState.archived:
        return Colors.grey;
    }
  }
  
  /// Get icon for lifecycle state
  IconData _getStateIcon(SpaceLifecycleState state) {
    switch (state) {
      case SpaceLifecycleState.created:
        return Icons.new_releases_outlined;
      case SpaceLifecycleState.active:
        return Icons.check_circle_outline;
      case SpaceLifecycleState.dormant:
        return Icons.access_time;
      case SpaceLifecycleState.archived:
        return Icons.archive_outlined;
    }
  }
  
  /// Get description for lifecycle state
  String _getStateDescription(SpaceLifecycleState state) {
    switch (state) {
      case SpaceLifecycleState.created:
        return 'The space has been created but has little or no activity yet. It will appear in "New Spaces" for discovery.';
      case SpaceLifecycleState.active:
        return 'The space has regular activity and engagement. It will appear in feeds and search results.';
      case SpaceLifecycleState.dormant:
        return 'The space has been inactive for over 30 days. It will appear less frequently in feeds and search results.';
      case SpaceLifecycleState.archived:
        return 'The space has been archived and is no longer active. Content is preserved but no new content can be added.';
    }
  }
  
  /// Get transition limitations
  String? _getTransitionLimitation(SpaceLifecycleState? from, SpaceLifecycleState to) {
    if (from == null) return null;
    
    // Can't move from archived to dormant
    if (from == SpaceLifecycleState.archived && to == SpaceLifecycleState.dormant) {
      return 'Archived spaces should be reactivated directly to active state.';
    }
    
    // Can't move from active to created
    if (from == SpaceLifecycleState.active && to == SpaceLifecycleState.created) {
      return 'Active spaces cannot be moved back to created state.';
    }
    
    // Can't move from dormant to created
    if (from == SpaceLifecycleState.dormant && to == SpaceLifecycleState.created) {
      return 'Dormant spaces cannot be moved back to created state.';
    }
    
    return null;
  }
  
  /// Check if a state transition is allowed
  bool _isTransitionAllowed(SpaceLifecycleState from, SpaceLifecycleState to) {
    if (from == to) return false;
    
    switch (from) {
      case SpaceLifecycleState.created:
        // Created can transition to any state
        return true;
      case SpaceLifecycleState.active:
        // Active can transition to dormant or archived, but not back to created
        return to != SpaceLifecycleState.created;
      case SpaceLifecycleState.dormant:
        // Dormant can transition to active or archived, but not back to created
        return to != SpaceLifecycleState.created;
      case SpaceLifecycleState.archived:
        // Archived can transition to active only
        return to == SpaceLifecycleState.active;
    }
  }
  
  Future<void> _updateLifecycleState() async {
    if (_selectedState == null || 
        _selectedState == widget.space.lifecycleState || 
        !widget.canModify ||
        _isLoading) {
      return;
    }
    
    final limitation = _getTransitionLimitation(widget.space.lifecycleState, _selectedState!);
    if (limitation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(limitation),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Reset selection
      setState(() {
        _selectedState = widget.space.lifecycleState;
      });
      return;
    }
    
    final confirmed = await _confirmStateChange();
    if (!confirmed) {
      // User cancelled, reset selection
      setState(() {
        _selectedState = widget.space.lifecycleState;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final repository = ref.read(spaceRepositoryProvider);
      final currentUser = ref.read(currentUserProvider);
      
      // Update the lifecycle state
      await repository.updateLifecycleState(
        widget.space.id,
        _selectedState!,
        lastActivityAt: _selectedState == SpaceLifecycleState.active 
            ? DateTime.now() 
            : widget.space.lastActivityAt,
      );
      
      // Record the action in custom data
      final newCustomData = Map<String, dynamic>.from(widget.space.customData);
      final List<Map<String, dynamic>> stateHistory = 
          (newCustomData['lifecycleStateHistory'] as List<dynamic>? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
      
      stateHistory.add({
        'from': widget.space.lifecycleState.name,
        'to': _selectedState!.name,
        'by': currentUser.id,
        'byName': currentUser.displayName,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      newCustomData['lifecycleStateHistory'] = stateHistory;
      
      // Update space with new custom data
      final updatedSpace = widget.space.copyWith(
        customData: newCustomData,
        lifecycleState: _selectedState,
      );
      
      await repository.updateSpace(updatedSpace);
      
      if (widget.onLifecycleChanged != null) {
        widget.onLifecycleChanged!(_selectedState!);
      }
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Space state updated to ${_selectedState!.name}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating space state: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
        
        // Reset selection
        setState(() {
          _selectedState = widget.space.lifecycleState;
        });
      }
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isExpanded = false;
      });
    }
  }
  
  Future<bool> _confirmStateChange() async {
    if (_selectedState == null) return false;
    
    final color = _getStateColor(_selectedState!);
    
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.dark2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          title: Row(
            children: [
              Icon(
                _getStateIcon(_selectedState!),
                color: color,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Change Space State?',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Change space state from ${widget.space.lifecycleState.name} to ${_selectedState!.name}?',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _getStateDescription(_selectedState!),
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              if (_selectedState == SpaceLifecycleState.archived) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Archiving is a significant action. Members will still be able to view content but no new content can be created.',
                          style: GoogleFonts.inter(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Change State',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }
  
  @override
  Widget build(BuildContext context) {
    final currentState = widget.space.lifecycleState;
    final color = _getStateColor(currentState);
    
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _getStateIcon(currentState),
                    color: color,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Space State: ',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            Text(
                              widget.space.lifecycleStateDescription,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                        if (widget.space.lastActivityAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Last activity: ${_formatLastActivity(widget.space.lastActivityAt!)}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded content
          if (_isExpanded) ...[
            Divider(
              color: Colors.white.withOpacity(0.1),
              height: 1,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStateDescription(currentState),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Space metrics relevant to lifecycle
                  _buildSpaceMetrics(),
                  
                  if (widget.canModify) ...[
                    const SizedBox(height: 16),
                    Divider(
                      color: Colors.white.withOpacity(0.1),
                      height: 1,
                    ),
                    const SizedBox(height: 16),
                    
                    // State transition controls
                    Text(
                      'Change Space State',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // State options
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: SpaceLifecycleState.values.map((state) {
                        final isSelected = _selectedState == state;
                        final isCurrentState = currentState == state;
                        final isDisabled = isCurrentState || 
                            !_isTransitionAllowed(currentState, state);
                        
                        return _buildStateOption(
                          state,
                          isSelected: isSelected,
                          isCurrentState: isCurrentState,
                          isDisabled: isDisabled,
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _selectedState != currentState
                                  ? _updateLifecycleState
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gold,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Update State',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildSpaceMetrics() {
    final activityIndicator = _getActivityIndicator();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Members',
                  widget.space.metrics.memberCount.toString(),
                  Icons.people_outline,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Events',
                  widget.space.eventIds.length.toString(),
                  Icons.event_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Activity',
                  activityIndicator.label,
                  activityIndicator.icon,
                  color: activityIndicator.color,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Age',
                  _getSpaceAge(),
                  Icons.calendar_month_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetricItem(String label, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color ?? Colors.white.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color ?? Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStateOption(
    SpaceLifecycleState state, {
    bool isSelected = false,
    bool isCurrentState = false,
    bool isDisabled = false,
  }) {
    final color = _getStateColor(state);
    
    return InkWell(
      onTap: isDisabled
          ? null
          : () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedState = state;
              });
            },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.2)
              : Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color
                : Colors.white.withOpacity(0.1),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getStateIcon(state),
              size: 16,
              color: isDisabled
                  ? Colors.white.withOpacity(0.3)
                  : color,
            ),
            const SizedBox(width: 8),
            Text(
              state.name,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isDisabled
                    ? Colors.white.withOpacity(0.3)
                    : isSelected
                        ? color
                        : Colors.white.withOpacity(0.8),
              ),
            ),
            if (isCurrentState) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Current',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  String _formatLastActivity(DateTime lastActivity) {
    final now = DateTime.now();
    final difference = now.difference(lastActivity);
    
    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
  
  String _getSpaceAge() {
    final now = DateTime.now();
    final difference = now.difference(widget.space.createdAt);
    
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'}';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'}';
    } else {
      return 'New';
    }
  }
  
  ({String label, IconData icon, Color color}) _getActivityIndicator() {
    if (widget.space.lastActivityAt == null) {
      return (
        label: 'No data',
        icon: Icons.help_outline,
        color: Colors.grey,
      );
    }
    
    final now = DateTime.now();
    final difference = now.difference(widget.space.lastActivityAt!);
    
    if (difference.inDays < 7) {
      return (
        label: 'Very Active',
        icon: Icons.trending_up,
        color: Colors.green,
      );
    } else if (difference.inDays < 14) {
      return (
        label: 'Active',
        icon: Icons.check_circle_outline,
        color: Colors.lightGreen,
      );
    } else if (difference.inDays < 30) {
      return (
        label: 'Slowing',
        icon: Icons.trending_down,
        color: Colors.amber,
      );
    } else if (difference.inDays < 90) {
      return (
        label: 'Inactive',
        icon: Icons.access_time,
        color: Colors.orange,
      );
    } else {
      return (
        label: 'Dormant',
        icon: Icons.do_not_disturb_on_outlined,
        color: Colors.red,
      );
    }
  }
} 