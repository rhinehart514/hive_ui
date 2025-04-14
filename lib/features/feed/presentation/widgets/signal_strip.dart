import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/feed/domain/entities/signal_content.dart';
import 'package:hive_ui/features/feed/presentation/providers/signal_provider.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/main.dart' show firebaseVerificationProvider;

/// A horizontally-scrollable strip that appears at the top of the feed
/// Sets the tone, signals activity, and provides narrative framing
/// Follows brand aesthetic guidelines with glassmorphism effects
class SignalStrip extends ConsumerStatefulWidget {
  /// Custom height for the strip
  final double height;
  
  /// Custom padding for the strip
  final EdgeInsets padding;
  
  /// Callback when a card is tapped
  final Function(SignalContent content)? onCardTap;
  
  /// Maximum number of cards to display
  final int maxCards;
  
  /// Whether to show the header title text
  final bool showHeader;
  
  /// Optional filter for specific signal types
  final List<SignalType>? signalTypes;
  
  /// Whether to use glass effect
  final bool useGlassEffect;
  
  /// Custom opacity for glass effect
  final double glassOpacity;
  
  /// Optional pre-fetched signal content to display
  /// If provided, this will be used instead of fetching from the repository
  final List<SignalContent>? customSignalContent;

  /// Constructor
  const SignalStrip({
    super.key,
    this.height = 125.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0),
    this.onCardTap,
    this.maxCards = 5,
    this.showHeader = true,
    this.signalTypes,
    this.useGlassEffect = true,
    this.glassOpacity = 0.15,
    this.customSignalContent,
  });

  @override
  ConsumerState<SignalStrip> createState() => _SignalStripState();
}

class _SignalStripState extends ConsumerState<SignalStrip> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    
    // Start the animation after a short delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _animationController.forward();
      }
    });
    
    // Delay initialization to avoid Riverpod build-time errors
    Future.microtask(() => _ensureInitialized());
  }
  
  void _ensureInitialized() {
    // Check and ensure Firebase is initialized
    final firebaseVerifier = ref.read(firebaseVerificationProvider.future);
    firebaseVerifier.then((initialized) {
      if (!initialized) {
        debugPrint('Warning: Firebase not initialized in SignalStrip. Some features may not work.');
      }
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showHeader) _buildHeader(),
          SizedBox(
            height: widget.height,
            child: Padding(
              padding: widget.padding,
              child: _buildSignalContent(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.only(
        left: widget.padding.left, 
        right: widget.padding.right,
        bottom: 8,
      ),
      child: Row(
        children: [
          Text(
            'SIGNAL',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.white.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSignalContent() {
    // If custom signal content is provided, use it directly
    if (widget.customSignalContent != null) {
      final contentList = widget.customSignalContent!;
      
      if (contentList.isEmpty) {
        return _buildEmptyState();
      }
      
      // Mark the first item as viewed - AFTER the build is complete
      if (contentList.isNotEmpty) {
        // Use microtask to schedule after build completion
        Future.microtask(() {
          // Make sure the widget is still mounted
          if (mounted) {
            ref.read(signalStripProvider.notifier).logContentView(contentList[0].id);
          }
        });
      }
      
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: contentList.length,
        itemBuilder: (context, index) {
          final content = contentList[index];
          return _buildSignalCard(content);
        },
      );
    }
    
    // Otherwise, fetch from the repository using the provider
    final signalParams = SignalContentParams(
      maxItems: widget.maxCards,
      types: widget.signalTypes,
    );
    
    final signalContentAsync = ref.watch(signalContentProvider(signalParams));
    
    return signalContentAsync.when(
      data: (contentList) {
        if (contentList.isEmpty) {
          return _buildEmptyState();
        }
        
        // Mark the first item as viewed - AFTER the build is complete
        if (contentList.isNotEmpty) {
          // Use microtask to schedule after build completion
          Future.microtask(() {
            // Make sure the widget is still mounted
            if (mounted) {
              ref.read(signalStripProvider.notifier).logContentView(contentList[0].id);
            }
          });
        }
        
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: contentList.length,
          itemBuilder: (context, index) {
            final content = contentList[index];
            return _buildSignalCard(content);
          },
        );
      },
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(error),
    );
  }
  
  Widget _buildSignalCard(SignalContent content) {
    // Determine card style based on signal type
    final cardStyle = _getCardStyle(content.type);
    
    // Determine the icon based on the content type
    final icon = _getIconForType(content.type);
    
    return GestureDetector(
      onTap: () => _handleCardTap(content),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        child: widget.useGlassEffect
            ? _buildGlassCard(content, cardStyle, icon)
            : _buildStandardCard(content, cardStyle, icon),
      ),
    );
  }
  
  Widget _buildGlassCard(
    SignalContent content, 
    _SignalCardStyle style,
    IconData icon,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(widget.glassOpacity),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 0.5,
            ),
          ),
          child: _buildCardContent(content, style, icon),
        ),
      ),
    );
  }
  
  Widget _buildStandardCard(
    SignalContent content, 
    _SignalCardStyle style,
    IconData icon,
  ) {
    return Card(
      elevation: 0,
      color: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.white.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildCardContent(content, style, icon),
      ),
    );
  }
  
  /// Format a DateTime as a relative time string (e.g. "5m ago", "2h ago")
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      return '${(difference.inDays / 30).floor()}mo ago';
    }
  }
  
  Widget _buildCardContent(
    SignalContent content,
    _SignalCardStyle style,
    IconData icon,
  ) {
    // Get formatted time text
    final formattedTimeAgo = _getTimeAgo(content.createdAt);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with icon and time
        Row(
          children: [
            // Icon with background
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: style.iconBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: style.iconColor,
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Time ago text
            Expanded(
              child: Text(
                formattedTimeAgo,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: style.iconColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Title
        Text(
          content.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.3,
          ),
        ),
        
        const SizedBox(height: 4),
        
        // Description
        Expanded(
          child: Text(
            content.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.7),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
  
  IconData _getIconForType(SignalType type) {
    switch (type) {
      case SignalType.lastNight:
        return Icons.nightlife;
      case SignalType.topEvent:
        return Icons.event;
      case SignalType.trySpace:
        return Icons.people;
      case SignalType.hiveLab:
        return Icons.science;
      case SignalType.underratedGem:
        return Icons.diamond;
      case SignalType.universityNews:
        return Icons.school;
      case SignalType.communityUpdate:
        return Icons.campaign;
      case SignalType.timeMorning:
        return Icons.wb_sunny;
      case SignalType.timeAfternoon:
        return Icons.wb_twilight;
      case SignalType.timeEvening:
        return Icons.nightlight_round;
      case SignalType.spaceHeat:
        return Icons.local_fire_department;
      case SignalType.ritualLaunch:
        return Icons.rocket_launch;
      case SignalType.friendMotion:
        return Icons.directions_walk;
      default:
        return Icons.info;
    }
  }

  _SignalCardStyle _getCardStyle(SignalType type) {
    switch (type) {
      case SignalType.lastNight:
        return _SignalCardStyle(
          gradientColors: [
            const Color(0xFF2E0B33).withOpacity(0.7),
            const Color(0xFF1A062D).withOpacity(0.7),
          ],
          iconColor: Colors.purple,
          iconBackgroundColor: Colors.purple.withOpacity(0.25),
        );
      case SignalType.topEvent:
        return _SignalCardStyle(
          gradientColors: [
            const Color(0xFF33190B).withOpacity(0.7),
            const Color(0xFF1B0D04).withOpacity(0.7),
          ],
          iconColor: Colors.orange,
          iconBackgroundColor: Colors.orange.withOpacity(0.25),
        );
      case SignalType.trySpace:
        return _SignalCardStyle(
          gradientColors: [
            const Color(0xFF0B2E33).withOpacity(0.7),
            const Color(0xFF031F24).withOpacity(0.7),
          ],
          iconColor: Colors.teal,
          iconBackgroundColor: Colors.teal.withOpacity(0.25),
        );
      case SignalType.hiveLab:
        return _SignalCardStyle(
          gradientColors: [
            const Color(0xFF33310B).withOpacity(0.7),
            const Color(0xFF1F1D04).withOpacity(0.7),
          ],
          iconColor: AppColors.yellow,
          iconBackgroundColor: AppColors.yellow.withOpacity(0.25),
        );
      case SignalType.underratedGem:
        return _SignalCardStyle(
          gradientColors: [
            const Color(0xFF0B1933).withOpacity(0.7),
            const Color(0xFF030F24).withOpacity(0.7),
          ],
          iconColor: Colors.blue,
          iconBackgroundColor: Colors.blue.withOpacity(0.25),
        );
      case SignalType.universityNews:
        return _SignalCardStyle(
          gradientColors: [
            const Color(0xFF333333).withOpacity(0.7),
            const Color(0xFF1A1A1A).withOpacity(0.7),
          ],
          iconColor: AppColors.white,
          iconBackgroundColor: AppColors.white.withOpacity(0.25),
        );
      case SignalType.communityUpdate:
        return _SignalCardStyle(
          gradientColors: [
            const Color(0xFF152A18).withOpacity(0.7),
            const Color(0xFF0F1C11).withOpacity(0.7),
          ],
          iconColor: Colors.green,
          iconBackgroundColor: Colors.green.withOpacity(0.25),
        );
      case SignalType.timeMorning:
        return _SignalCardStyle(
          gradientColors: [
            const Color(0xFF3B2502).withOpacity(0.7),
            const Color(0xFF261701).withOpacity(0.7),
          ],
          iconColor: Colors.orange,
          iconBackgroundColor: Colors.orange.withOpacity(0.25),
        );
      case SignalType.timeAfternoon:
        return _SignalCardStyle(
          gradientColors: [
            const Color(0xFF33190B).withOpacity(0.7),
            const Color(0xFF1B0D04).withOpacity(0.7),
          ],
          iconColor: AppColors.gold,
          iconBackgroundColor: AppColors.gold.withOpacity(0.25),
        );
      case SignalType.timeEvening:
        return _SignalCardStyle(
          gradientColors: [
            const Color(0xFF0B0F33).withOpacity(0.7),
            const Color(0xFF060924).withOpacity(0.7),
          ],
          iconColor: Colors.indigo,
          iconBackgroundColor: Colors.indigo.withOpacity(0.25),
        );
      case SignalType.spaceHeat:
        return _SignalCardStyle(
          gradientColors: [
            const Color(0xFF330B0B).withOpacity(0.7),
            const Color(0xFF240606).withOpacity(0.7),
          ],
          iconColor: Colors.red,
          iconBackgroundColor: Colors.red.withOpacity(0.25),
        );
      case SignalType.ritualLaunch:
        return _SignalCardStyle(
          gradientColors: [
            const Color(0xFF2E0B33).withOpacity(0.7),
            const Color(0xFF1A062D).withOpacity(0.7),
          ],
          iconColor: Colors.purple,
          iconBackgroundColor: Colors.purple.withOpacity(0.25),
        );
      case SignalType.friendMotion:
        return _SignalCardStyle(
          gradientColors: [
            const Color(0xFF0B2933).withOpacity(0.7),
            const Color(0xFF061924).withOpacity(0.7),
          ],
          iconColor: Colors.cyan,
          iconBackgroundColor: Colors.cyan.withOpacity(0.25),
        );
      default:
        return _SignalCardStyle(
          gradientColors: [
            const Color(0xFF333333).withOpacity(0.7),
            const Color(0xFF1A1A1A).withOpacity(0.7),
          ],
          iconColor: AppColors.white,
          iconBackgroundColor: AppColors.white.withOpacity(0.25),
        );
    }
  }
  
  void _handleCardTap(SignalContent content) {
    // Provide haptic feedback
    HapticFeedback.selectionClick();
    
    // Log the tap
    ref.read(signalStripProvider.notifier).logContentTap(content.id);
    
    // Call the callback
    widget.onCardTap?.call(content);
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Opacity(
        opacity: 0.6,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              color: AppColors.white.withOpacity(0.7),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              'No signals right now',
              style: GoogleFonts.inter(
                color: AppColors.white.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.yellow),
        ),
      ),
    );
  }
  
  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade300,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              'Could not load signal content',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.white.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper class for styling signal cards
class _SignalCardStyle {
  final List<Color> gradientColors;
  final Color iconColor;
  final Color iconBackgroundColor;
  
  const _SignalCardStyle({
    required this.gradientColors,
    required this.iconColor,
    required this.iconBackgroundColor,
  });
} 