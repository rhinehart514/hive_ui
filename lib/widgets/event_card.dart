import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/event.dart';
import '../models/repost_content_type.dart';
import 'package:url_launcher/url_launcher.dart';

class EventCard extends StatefulWidget {
  final Event event;
  final VoidCallback? onTap;
  final bool isCompact;
  final bool isRepost;
  final String? reposterName;
  final String? quoteText;
  final RepostContentType repostType;
  final Function(Event, String?, RepostContentType)? onRepost;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.isCompact = false,
    this.isRepost = false,
    this.reposterName,
    this.quoteText,
    this.repostType = RepostContentType.standard,
    this.onRepost,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> with SingleTickerProviderStateMixin {
  // Animation controller for repost interactions
  late AnimationController _animationController;
  
  // Animations for repost effects
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _opacityAnimation;
  
  // Track if animation has played
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    
    // Set up animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        reverseCurve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );
    
    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
        reverseCurve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
      ),
    );
    
    // Play animation if this is a repost
    if (widget.isRepost && !_hasAnimated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _playRepostAnimation();
      });
    }
  }
  
  @override
  void didUpdateWidget(EventCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If this became a repost, play animation
    if (widget.isRepost && !oldWidget.isRepost && !_hasAnimated) {
      _playRepostAnimation();
    }
  }
  
  void _playRepostAnimation() {
    _animationController.forward().then((_) {
      _animationController.reverse();
      setState(() {
        _hasAnimated = true;
      });
    });
    
    // Add haptic feedback
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _launchEventUrl() async {
    try {
      final url = widget.event.link;
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching event URL: $e');
    }
  }
  
  // Handle the repost action
  void _handleRepost() {
    if (widget.onRepost != null) {
      // Trigger haptic feedback
      HapticFeedback.mediumImpact();
      
      // Show repost options (bottom sheet would be implemented elsewhere)
      // For now, just call with standard repost type
      widget.onRepost!(widget.event, null, RepostContentType.standard);
      
      // Play the animation
      _playRepostAnimation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotateAnimation.value,
            child: child,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: widget.isRepost 
                ? const Color(0xFFFFD700).withOpacity(0.3) // Gold border for reposts
                : Colors.white.withOpacity(0.1),
            width: widget.isRepost ? 1.5 : 1,
          ),
        ),
        color: const Color(0xFF1E1E1E),
        elevation: 4,
        child: Column(
          children: [
            // Repost header if this is a repost
            if (widget.isRepost && widget.reposterName != null)
              Container(
                padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.repeat_rounded,
                      size: 14,
                      color: const Color(0xFFFFD700).withOpacity(0.8),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${widget.reposterName} reposted",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              
            // Quote text if this is a quote repost
            if (widget.isRepost && 
                widget.repostType == RepostContentType.quote && 
                widget.quoteText != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8, left: 16, right: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  widget.quoteText!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              
            // Main event card content
            InkWell(
              onTap: widget.onTap ?? _launchEventUrl,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildCategoryIndicator(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.event.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Outfit',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (!widget.isCompact) ...[
                      const SizedBox(height: 12),
                      Text(
                        widget.event.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          fontFamily: 'Inter',
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.event.formattedTimeRange,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.event.location,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                              fontFamily: 'Inter',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (!widget.isCompact) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.white.withOpacity(0.1),
                                child: Text(
                                  widget.event.organizerName[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.event.organizerName,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                          // Only show status for non-repost cards
                          if (!widget.isRepost)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: widget.event.status == 'confirmed'
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.event.status.toUpperCase(),
                                style: TextStyle(
                                  color: widget.event.status == 'confirmed'
                                      ? Colors.green
                                      : Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          // Show repost button for reposted items
                          if (widget.isRepost)
                            GestureDetector(
                              onTap: _handleRepost,
                              child: AnimatedBuilder(
                                animation: _opacityAnimation,
                                builder: (context, child) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Color.lerp(
                                        const Color(0xFFFFD700).withOpacity(0.1),
                                        const Color(0xFFFFD700).withOpacity(0.3),
                                        _animationController.value,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.repeat_rounded,
                                          size: 14,
                                          color: Color(0xFFFFD700),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          "REPOST",
                                          style: TextStyle(
                                            color: Color(0xFFFFD700),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _getCategoryColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        widget.event.category.toUpperCase(),
        style: TextStyle(
          color: _getCategoryColor(),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  Color _getCategoryColor() {
    switch (widget.event.category.toLowerCase()) {
      case 'academic':
        return Colors.blue;
      case 'social':
        return Colors.purple;
      case 'sports':
        return Colors.orange;
      case 'cultural':
        return Colors.pink;
      case 'career':
        return Colors.green;
      default:
        return const Color(0xFFFFD700); // Gold color for other categories
    }
  }
}
