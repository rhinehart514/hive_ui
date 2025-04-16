import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/extensions/glassmorphism_extension.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/space_affiliation_button.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';

/// Extension on SpaceEntity to provide additional properties for affiliation states
extension SpaceEntityAffiliationExt on SpaceEntity {
  /// Whether the current user is a builder/admin for this space
  bool get isBuilder => admins.contains(FirebaseAuth.instance.currentUser?.uid ?? '');
  
  /// Whether the current user is a member of this space
  bool get isMember => isJoined;
  
  /// Whether the current user is watching this space (observing)
  bool get isWatching => customData['isWatching'] == true;
  
  /// Whether the current user has a pending request to join the space
  bool get hasPendingRequest => customData['hasPendingRequest'] == true;
  
  /// Avatar URL for the space
  String? get avatar => imageUrl;
}

/// Detailed space card showing more information about a space
/// Used in space details page and as an overlay in the constellation view
class SpaceDetailCard extends ConsumerStatefulWidget {
  /// Space entity to display
  final SpaceEntity space;
  
  /// Callback when affiliation changes
  final Function(SpaceAffiliationState) onAffiliationChange;
  
  /// Whether this is a modal overlay (changes styling)
  final bool isOverlay;
  
  /// Whether to show the full details
  final bool showFullDetails;
  
  /// Whether to show member counts and stats
  final bool showStats;
  
  /// Optional size constraint
  final SpaceDetailCardSize size;
  
  /// Optional callback when card is closed
  final VoidCallback? onClose;

  const SpaceDetailCard({
    Key? key,
    required this.space,
    required this.onAffiliationChange,
    this.isOverlay = true,
    this.showFullDetails = true,
    this.showStats = true,
    this.size = SpaceDetailCardSize.medium,
    this.onClose,
  }) : super(key: key);

  @override
  ConsumerState<SpaceDetailCard> createState() => _SpaceDetailCardState();
}

/// Size options for the detail card
enum SpaceDetailCardSize {
  /// Small compact card
  small,
  
  /// Medium-sized card with moderate detail
  medium,
  
  /// Large card with comprehensive details
  large
}

class _SpaceDetailCardState extends ConsumerState<SpaceDetailCard> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Set up animations
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    // Start the animation
    _animController.forward();
  }
  
  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // Format member count with proper suffixes (K, M)
  String _formatMemberCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }
  
  // Get friendly string for space type
  String _getSpaceTypeString(SpaceType type) {
    switch (type) {
      case SpaceType.studentOrg:
        return 'Student Organization';
      case SpaceType.universityOrg:
        return 'University Organization';
      case SpaceType.campusLiving:
        return 'Campus Living';
      case SpaceType.fraternityAndSorority:
        return 'Fraternity & Sorority';
      case SpaceType.hiveExclusive:
        return 'HIVE Exclusive';
      case SpaceType.organization:
        return 'Organization';
      case SpaceType.project:
        return 'Project';
      case SpaceType.event:
        return 'Event';
      case SpaceType.community:
        return 'Community';
      case SpaceType.other:
        return 'Community';
      default:
        return 'Community';
    }
  }
  
  // Get current affiliation state based on space status
  SpaceAffiliationState _getAffiliationState() {
    if (widget.space.isBuilder) {
      return SpaceAffiliationState.builder;
    } else if (widget.space.isMember) {
      return SpaceAffiliationState.member;
    } else if (widget.space.hasPendingRequest) {
      return SpaceAffiliationState.pending;
    } else if (widget.space.isWatching) {
      return SpaceAffiliationState.observing;
    } else {
      return SpaceAffiliationState.none;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the current affiliation state
    final affiliationState = _getAffiliationState();
    
    // Build the card with animations
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeInAnimation,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: _buildCard(affiliationState),
    );
  }
  
  Widget _buildCard(SpaceAffiliationState affiliationState) {
    // Calculate dimensions based on size
    double width;
    double height;
    
    switch (widget.size) {
      case SpaceDetailCardSize.small:
        width = 300.0;
        height = 240.0;
        break;
      case SpaceDetailCardSize.medium:
        width = 360.0;
        height = 340.0;
        break;
      case SpaceDetailCardSize.large:
        width = 420.0;
        height = 440.0;
        break;
    }
    
    // Build card with glassmorphism effect
    return Container(
      width: width,
      constraints: BoxConstraints(
        maxWidth: width,
        minHeight: height,
        maxHeight: widget.showFullDetails ? double.infinity : height,
      ),
      child: widget.isOverlay
          ? ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: _buildCardContent(affiliationState),
              ),
            )
          : _buildCardContent(affiliationState),
    );
  }
  
  Widget _buildCardContent(SpaceAffiliationState affiliationState) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: AppColors.glassGradient,
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: _buildInnerContent(affiliationState),
    );
  }
  
  Widget _buildInnerContent(SpaceAffiliationState affiliationState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header section
        _buildHeader(affiliationState),
        
        // Divider
        Divider(
          color: Colors.white.withOpacity(0.1),
          height: 1,
        ),
        
        // Main content
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description
              Text(
                widget.space.description,
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  height: 1.5,
                ),
                maxLines: widget.showFullDetails ? null : 3,
                overflow: widget.showFullDetails ? null : TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 16),
              
              // Stats section (conditional)
              if (widget.showStats) _buildStats(),
              
              // Space type and tags
              if (widget.space.tags.isNotEmpty || widget.space.spaceType != SpaceType.other)
                _buildTagsSection(),
              
              // Affiliation button
              const SizedBox(height: 16),
              SpaceAffiliationButton(
                state: affiliationState,
                onAffiliationChange: widget.onAffiliationChange,
                isPrivate: widget.space.isPrivate,
                usePrimaryStyle: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildHeader(SpaceAffiliationState affiliationState) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Space avatar or icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: widget.space.primaryColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: widget.space.avatar != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      widget.space.avatar!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          widget.space.icon,
                          color: Colors.white,
                          size: 28,
                        );
                      },
                    ),
                  )
                : Icon(
                    widget.space.icon,
                    color: Colors.white,
                    size: 28,
                  ),
          ),
          
          const SizedBox(width: 16),
          
          // Space name and basic info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.space.name,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 4),
                
                // Space type and member count
                Text(
                  '${_getSpaceTypeString(widget.space.spaceType)} · ${_formatMemberCount(widget.space.metrics.memberCount)} members',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // Affiliation status
                if (affiliationState != SpaceAffiliationState.none)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _buildAffiliationStatus(affiliationState),
                  ),
              ],
            ),
          ),
          
          // Close button if overlay
          if (widget.isOverlay && widget.onClose != null)
            IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.white60,
                size: 20,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                widget.onClose?.call();
              },
            ),
        ],
      ),
    );
  }
  
  Widget _buildAffiliationStatus(SpaceAffiliationState state) {
    Color bgColor;
    Color textColor;
    String text;
    IconData icon;
    
    switch (state) {
      case SpaceAffiliationState.builder:
        bgColor = AppColors.gold.withOpacity(0.2);
        textColor = AppColors.gold;
        text = 'Builder';
        icon = Icons.build;
        break;
      case SpaceAffiliationState.member:
        bgColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green[300]!;
        text = 'Member';
        icon = Icons.check_circle;
        break;
      case SpaceAffiliationState.pending:
        bgColor = Colors.orange.withOpacity(0.2);
        textColor = Colors.orange[300]!;
        text = 'Pending';
        icon = Icons.hourglass_empty;
        break;
      case SpaceAffiliationState.observing:
        bgColor = Colors.blue.withOpacity(0.2);
        textColor = Colors.blue[300]!;
        text = 'Watching';
        icon = Icons.visibility;
        break;
      default:
        return const SizedBox.shrink(); // No status for 'none'
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Stats grid
        Row(
          children: [
            _buildStatItem(
              'Members',
              _formatMemberCount(widget.space.metrics.memberCount),
              Icons.people,
            ),
            _buildStatItem(
              'Active',
              _formatMemberCount(widget.space.metrics.activeMembers),
              Icons.person,
            ),
            _buildStatItem(
              'Events',
              widget.space.metrics.weeklyEvents.toString(),
              Icons.event,
            ),
          ],
        ),
        
        const SizedBox(height: 16),
      ],
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Tags wrap
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Space type tag
            _buildTag(_getSpaceTypeString(widget.space.spaceType), 
                     widget.space.primaryColor.withOpacity(0.2)),
            
            // Other tags
            ...widget.space.tags.map((tag) => _buildTag(tag)),
          ],
        ),
        
        const SizedBox(height: 16),
      ],
    );
  }
  
  Widget _buildTag(String text, [Color? bgColor]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: Colors.white.withOpacity(0.9),
        ),
      ),
    );
  }
} 