import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_repository_provider.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Widget to initiate and visualize the space archiving process
class SpaceArchiveControl extends ConsumerStatefulWidget {
  /// The space entity to control archiving for
  final SpaceEntity space;
  
  /// Whether the current user has permission to initiate archiving
  final bool canArchive;
  
  /// Callback when archive status is changed
  final Function(SpaceLifecycleState newState)? onLifecycleChanged;

  /// Constructor
  const SpaceArchiveControl({
    Key? key,
    required this.space,
    this.canArchive = false,
    this.onLifecycleChanged,
  }) : super(key: key);

  @override
  ConsumerState<SpaceArchiveControl> createState() => _SpaceArchiveControlState();
}

class _SpaceArchiveControlState extends ConsumerState<SpaceArchiveControl> {
  bool _isLoading = false;
  int _archiveVotes = 0;
  int _requiredVotes = 3; // Default threshold, can be dynamic
  
  @override
  void initState() {
    super.initState();
    _loadArchiveStatus();
  }
  
  Future<void> _loadArchiveStatus() async {
    final space = widget.space;
    
    // Get archive votes from custom data (this would be properly structured in a real implementation)
    if (space.customData.containsKey('archiveVotes')) {
      setState(() {
        _archiveVotes = space.customData['archiveVotes'] as int;
      });
    }
    
    // Determine required votes (could be based on member count)
    if (space.customData.containsKey('requiredArchiveVotes')) {
      setState(() {
        _requiredVotes = space.customData['requiredArchiveVotes'] as int;
      });
    } else {
      // Default logic - larger spaces require more votes
      final memberCount = widget.space.metrics.memberCount;
      setState(() {
        _requiredVotes = memberCount > 100 ? 5 : (memberCount > 20 ? 3 : 2);
      });
    }
  }

  Future<void> _handleArchiveVote() async {
    if (!widget.canArchive || widget.space.lifecycleState == SpaceLifecycleState.archived) {
      return;
    }

    // Apply haptic feedback
    HapticFeedback.mediumImpact();
    
    // Check if current user already voted
    final currentUser = ref.read(currentUserProvider);
    final List<String> voters = (widget.space.customData['archiveVoters'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
        
    if (voters.contains(currentUser.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already voted to archive this space'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Update space with new vote
      final repository = ref.read(spaceRepositoryProvider);
      final newVotes = _archiveVotes + 1;
      voters.add(currentUser.id);
      
      // Create updated custom data
      final newCustomData = Map<String, dynamic>.from(widget.space.customData);
      newCustomData['archiveVotes'] = newVotes;
      newCustomData['archiveVoters'] = voters;
      
      // Determine if threshold is reached
      SpaceLifecycleState newState = widget.space.lifecycleState;
      if (newVotes >= _requiredVotes) {
        newState = SpaceLifecycleState.archived;
      }
      
      // Update the space entity
      final updatedSpace = widget.space.copyWith(
        customData: newCustomData,
        lifecycleState: newState,
      );
      
      await repository.updateSpace(updatedSpace);
      
      // Call the callback if provided
      if (widget.onLifecycleChanged != null && newState != widget.space.lifecycleState) {
        widget.onLifecycleChanged!(newState);
      }
      
      if (mounted) {
        setState(() {
          _archiveVotes = newVotes;
          _isLoading = false;
        });
        
        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newState == SpaceLifecycleState.archived
                  ? 'Space has been archived'
                  : 'Vote recorded. ${_requiredVotes - newVotes} more votes needed to archive',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error recording vote: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmArchive() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.dark2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 0.5,
          ),
        ),
        title: Text(
          'Archive Space?',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Archived spaces cannot be recovered and will no longer appear in search results or feeds. Members can still view archived content but no new content can be added.',
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.8),
          ),
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
              backgroundColor: Colors.red.withOpacity(0.8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Archive',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    
    if (result == true) {
      _handleArchiveVote();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show anything for normal active spaces
    if (widget.space.lifecycleState == SpaceLifecycleState.active && 
        _archiveVotes == 0 && 
        !widget.canArchive) {
      return const SizedBox.shrink();
    }
    
    // Show archived state
    if (widget.space.lifecycleState == SpaceLifecycleState.archived) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.red.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.archive,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'This Space is Archived',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'This space is no longer active. Content is preserved for reference but no new content can be added.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }
    
    // Show archive in progress
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Space Archiving',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_archiveVotes > 0) ...[
            Text(
              'This space has $_archiveVotes/${_requiredVotes} votes to archive.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _archiveVotes / _requiredVotes,
                backgroundColor: Colors.orange.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                minHeight: 8,
              ),
            ),
          ] else ...[
            Text(
              'This space can be archived if it is no longer active.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (widget.canArchive && widget.space.lifecycleState != SpaceLifecycleState.archived)
            Align(
              alignment: Alignment.centerRight,
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    )
                  : TextButton.icon(
                      onPressed: _confirmArchive,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      icon: const Icon(Icons.archive, size: 16),
                      label: Text(
                        _archiveVotes > 0 ? 'Vote to Archive' : 'Initiate Archive',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }
} 