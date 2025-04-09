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
  
  Widget _buildCardContent(
    SignalContent content, 
    _SignalCardStyle style,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: style.accentColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              content.title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: style.accentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Text(
            content.description,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.8),
              height: 1.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap to explore',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: style.secondaryColor.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
  
  _SignalCardStyle _getCardStyle(SignalType type) {
    switch (type) {
      case SignalType.lastNight:
        return _SignalCardStyle(
          accentColor: Colors.purple.shade300,
          secondaryColor: Colors.purple.shade200,
        );
      case SignalType.topEvent:
        return const _SignalCardStyle(
          accentColor: AppColors.yellow,
          secondaryColor: AppColors.yellow,
        );
      case SignalType.trySpace:
        return _SignalCardStyle(
          accentColor: Colors.blue.shade300,
          secondaryColor: Colors.blue.shade200,
        );
      case SignalType.hiveLab:
        return _SignalCardStyle(
          accentColor: Colors.green.shade300,
          secondaryColor: Colors.green.shade200,
        );
      case SignalType.underratedGem:
        return _SignalCardStyle(
          accentColor: Colors.amber.shade300,
          secondaryColor: Colors.amber.shade200,
        );
      case SignalType.universityNews:
        return _SignalCardStyle(
          accentColor: Colors.red.shade300,
          secondaryColor: Colors.red.shade200,
        );
      case SignalType.communityUpdate:
        return _SignalCardStyle(
          accentColor: Colors.teal.shade300,
          secondaryColor: Colors.teal.shade200,
        );
    }
  }
  
  IconData _getIconForType(SignalType type) {
    switch (type) {
      case SignalType.lastNight:
        return Icons.nightlife;
      case SignalType.topEvent:
        return Icons.event;
      case SignalType.trySpace:
        return Icons.group;
      case SignalType.hiveLab:
        return Icons.science;
      case SignalType.underratedGem:
        return Icons.star;
      case SignalType.universityNews:
        return Icons.campaign;
      case SignalType.communityUpdate:
        return Icons.emoji_events;
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
  final Color accentColor;
  final Color secondaryColor;
  
  const _SignalCardStyle({
    required this.accentColor,
    required this.secondaryColor,
  });
} 