import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/feed/domain/entities/signal_content.dart';
import 'package:hive_ui/features/feed/presentation/providers/feed_strip_provider.dart';
import 'package:hive_ui/features/feed/presentation/widgets/signal_strip.dart';

/// Enhanced Feed Strip component that appears at the top of the feed
/// Uses the specialized feed strip providers to display relevant cards
class FeedStrip extends ConsumerWidget {
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
  
  /// Whether to use glass effect
  final bool useGlassEffect;
  
  /// Custom opacity for glass effect
  final double glassOpacity;

  /// Constructor
  const FeedStrip({
    super.key,
    this.height = 125.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0),
    this.onCardTap,
    this.maxCards = 5,
    this.showHeader = true,
    this.useGlassEffect = true,
    this.glassOpacity = 0.15,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the combined feed strip cards provider
    final feedStripCardsAsync = ref.watch(feedStripCardsProvider);
    
    return feedStripCardsAsync.when(
      data: (feedStripCards) {
        // Get the combined cards, limited to maxCards
        final cards = feedStripCards.allCards.take(maxCards).toList();
        
        // Use the existing signal strip widget with our cards
        return _buildSignalStripWithCards(context, ref, cards);
      },
      loading: () => _buildLoadingStrip(),
      error: (error, stackTrace) => _buildErrorStrip(error),
    );
  }
  
  Widget _buildSignalStripWithCards(
    BuildContext context, 
    WidgetRef ref, 
    List<SignalContent> cards
  ) {
    // Use the pre-existing SignalStrip widget with our custom cards
    return SignalStrip(
      height: height,
      padding: padding,
      onCardTap: onCardTap,
      maxCards: maxCards,
      showHeader: showHeader,
      useGlassEffect: useGlassEffect,
      glassOpacity: glassOpacity,
      customSignalContent: cards,
    );
  }
  
  Widget _buildLoadingStrip() {
    return SignalStrip(
      height: height,
      padding: padding,
      maxCards: maxCards,
      showHeader: showHeader,
      useGlassEffect: useGlassEffect,
      glassOpacity: glassOpacity,
    );
  }
  
  Widget _buildErrorStrip(Object error) {
    // Return an empty strip on error (could be enhanced to show error state)
    return SignalStrip(
      height: height,
      padding: padding,
      maxCards: maxCards,
      showHeader: showHeader,
      useGlassEffect: useGlassEffect,
      glassOpacity: glassOpacity,
    );
  }
} 