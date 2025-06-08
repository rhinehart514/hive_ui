import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A widget that displays a user's bio with expandable functionality for longer text
class ProfileBioSection extends StatefulWidget {
  /// The user's bio text
  final String? bio;
  
  /// Whether this is the current user's profile
  final bool isCurrentUser;
  
  /// Callback when edit bio is tapped
  final VoidCallback? onEditBio;
  
  /// Maximum number of lines to show when collapsed
  final int collapsedLines;

  const ProfileBioSection({
    super.key,
    this.bio,
    required this.isCurrentUser,
    this.onEditBio,
    this.collapsedLines = 3,
  });

  @override
  State<ProfileBioSection> createState() => _ProfileBioSectionState();
}

class _ProfileBioSectionState extends State<ProfileBioSection> {
  bool _isExpanded = false;
  late TextPainter _textPainter;
  bool _needsExpansion = false;

  @override
  void initState() {
    super.initState();
    _calculateTextHeight();
  }

  @override
  void didUpdateWidget(ProfileBioSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bio != widget.bio) {
      _calculateTextHeight();
    }
  }

  void _calculateTextHeight() {
    if (widget.bio == null || widget.bio!.isEmpty) {
      _needsExpansion = false;
      return;
    }

    final textStyle = GoogleFonts.inter(
      fontSize: 15,
      height: 1.4,
      color: Colors.white.withOpacity(0.9),
    );

    _textPainter = TextPainter(
      text: TextSpan(text: widget.bio, style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: widget.collapsedLines,
    );

    // Need to set a width constraint before calculating if text is overflowing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final width = MediaQuery.of(context).size.width - 32; // Account for padding
      _textPainter.layout(maxWidth: width);
      
      // Check if text would overflow when constrained to collapsed lines
      final didExceedMaxLines = _textPainter.didExceedMaxLines;
      
      if (didExceedMaxLines != _needsExpansion) {
        setState(() {
          _needsExpansion = didExceedMaxLines;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasValidBio = widget.bio != null && widget.bio!.isNotEmpty;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bio header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Semantics(
                header: true,
                label: 'Bio section',
                child: Text(
                  'Bio',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (widget.isCurrentUser)
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (widget.onEditBio != null) {
                        widget.onEditBio!();
                      }
                    },
                    child: Semantics(
                      button: true,
                      label: 'Edit bio',
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            Icon(
                              hasValidBio ? Icons.edit : Icons.add,
                              color: AppColors.gold,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              hasValidBio ? 'Edit' : 'Add',
                              style: GoogleFonts.inter(
                                color: AppColors.gold,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Show bio text or placeholder
          if (!hasValidBio)
            _buildEmptyBioState()
          else
            GestureDetector(
              onTap: _needsExpansion 
                ? () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                    HapticFeedback.lightImpact();
                  }
                : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.bio!,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      height: 1.4,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    maxLines: _isExpanded ? null : widget.collapsedLines,
                    overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  ),
                  if (_needsExpansion)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _isExpanded ? 'Show less' : 'Read more',
                        style: GoogleFonts.inter(
                          color: AppColors.gold,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyBioState() {
    if (!widget.isCurrentUser) {
      return Text(
        'No bio available',
        style: GoogleFonts.inter(
          fontSize: 15,
          fontStyle: FontStyle.italic,
          color: Colors.white.withOpacity(0.5),
        ),
      );
    }
    
    return InkWell(
      onTap: widget.onEditBio,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold.withOpacity(0.3)),
          color: AppColors.gold.withOpacity(0.05),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.edit_note,
                color: AppColors.gold.withOpacity(0.7),
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                'Add a bio to tell others about yourself',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.gold.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
