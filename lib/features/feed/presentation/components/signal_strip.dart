import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Signal content for the signal strip
class SignalContent {
  /// Unique identifier
  final String id;
  
  /// Primary title text
  final String title;
  
  /// Description or content text
  final String? description;
  
  /// Category or tag for the signal
  final String? category;
  
  /// Icon to display (optional)
  final IconData? icon;
  
  /// Background color override (optional)
  final Color? backgroundColor;
  
  /// Whether this represents a live/active content
  final bool isLive;
  
  /// Time relative description (e.g., "1h ago")
  final String? timeAgo;
  
  /// Optional data for handling when tapped
  final Map<String, dynamic>? data;
  
  SignalContent({
    required this.id,
    required this.title,
    this.description,
    this.category,
    this.icon,
    this.backgroundColor,
    this.isLive = false,
    this.timeAgo,
    this.data,
  });
}

/// A premium signal strip component
/// Displays important signals and content highlights in a horizontally scrolling strip
class SignalStrip extends StatelessWidget {
  /// Overall height of the strip
  final double height;
  
  /// Padding around the strip
  final EdgeInsets padding;
  
  /// Whether to show the header
  final bool showHeader;
  
  /// Header title (defaults to "SIGNAL")
  final String headerTitle;
  
  /// Header description (optional)
  final String? headerDescription;
  
  /// Signal content to display
  final List<SignalContent>? signalContent;
  
  /// Callback when a signal card is tapped
  final Function(SignalContent)? onCardTap;
  
  /// Maximum number of cards to display
  final int maxCards;
  
  /// Card width
  final double cardWidth;
  
  /// Card height (defaults to 80% of overall height)
  final double? cardHeight;
  
  /// Space between cards
  final double cardSpacing;
  
  const SignalStrip({
    Key? key,
    this.height = 150.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0),
    this.showHeader = true,
    this.headerTitle = "SIGNAL",
    this.headerDescription,
    this.signalContent,
    this.onCardTap,
    this.maxCards = 10,
    this.cardWidth = 180.0,
    this.cardHeight,
    this.cardSpacing = 12.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          if (showHeader) _buildHeader(),
          
          // Card list
          Expanded(
            child: _buildSignalCards(),
          ),
        ],
      ),
    );
  }
  
  /// Builds the header section with title and optional description
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Text(
            headerTitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.gold,
              letterSpacing: 0.8,
            ),
          ),
          if (headerDescription != null) ...[
            const SizedBox(width: 8),
            Text(
              headerDescription!,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFFB0B0B0), // Text Secondary color
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  /// Builds the horizontally scrolling signal cards
  Widget _buildSignalCards() {
    // If no content provided, show placeholders
    final content = signalContent ?? _generatePlaceholderContent();
    final limitedContent = content.take(maxCards).toList();
    
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: limitedContent.length,
      itemBuilder: (context, index) {
        return _buildSignalCard(context, limitedContent[index], index);
      },
    );
  }
  
  /// Builds an individual signal card
  Widget _buildSignalCard(BuildContext context, SignalContent content, int index) {
    // Calculate dimensions
    final cardH = cardHeight ?? (height * 0.8);
    
    return GestureDetector(
      onTap: () {
        // Provide haptic feedback
        HapticFeedback.selectionClick();
        
        // Call the callback if provided
        if (onCardTap != null) {
          onCardTap!(content);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300), // standard duration token
        curve: Curves.easeOutQuint,
        width: cardWidth,
        height: cardH,
        margin: EdgeInsets.only(right: cardSpacing, bottom: 4),
        decoration: BoxDecoration(
          color: content.backgroundColor ?? const Color(0xFF1E1E1E), // Secondary Surface color
          borderRadius: BorderRadius.circular(8.0), // radius-md token
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Stack(
            children: [
              // Content area
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(12.0), // spacing-sm token
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row with time and icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Time ago indicator with optional live marker
                          if (content.timeAgo != null || content.isLive)
                            _buildTimeIndicator(content),
                            
                          // Category icon if available
                          if (content.icon != null)
                            Icon(
                              content.icon,
                              color: AppColors.gold,
                              size: 18,
                            ),
                        ],
                      ),
                      
                      // Spacer
                      const Spacer(),
                      
                      // Title and description at the bottom
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            content.title,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (content.description != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              content.description!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFFB0B0B0), // Text Secondary color
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Bottom gradient overlay for better text visibility
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 60,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Builds the time indicator with optional live badge
  Widget _buildTimeIndicator(SignalContent content) {
    if (content.isLive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.8),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'LIVE NOW',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );
    } else if (content.timeAgo != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          content.timeAgo!,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: const Color(0xFFB0B0B0), // Text Secondary color
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }
  
  /// Generates placeholder content when none is provided
  List<SignalContent> _generatePlaceholderContent() {
    final icons = [Icons.local_fire_department, Icons.photo_camera, Icons.event, Icons.group];
    final titles = ['CS Club is on fire 🔥', 'Weekly Photo Challenge', 'Campus DJ Night', 'Design Meetup'];
    final descriptions = [
      '14 new members in the past hour',
      'Post your best campus shot',
      'Tonight at the Student Center',
      '8 new postings this week'
    ];
    final categories = ['Club', 'Contest', 'Event', 'Group'];
    final times = ['1h ago', '1h ago', '3h ago', '5h ago'];
    final backgrounds = [
      const Color(0xFF2D1A13), // deep red-brown
      const Color(0xFF1A1D2C), // deep blue-purple
      const Color(0xFF1A2E29), // deep teal
      const Color(0xFF2C1827), // deep purple
    ];
    
    return List.generate(
      4,
      (index) => SignalContent(
        id: 'placeholder-$index',
        title: titles[index % titles.length],
        description: descriptions[index % descriptions.length],
        category: categories[index % categories.length],
        icon: icons[index % icons.length],
        backgroundColor: backgrounds[index % backgrounds.length],
        isLive: index == 0 || index == 2,
        timeAgo: times[index % times.length],
      ),
    );
  }
} 