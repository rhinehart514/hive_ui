import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/feed/domain/entities/signal_content.dart';
import 'package:hive_ui/features/feed/presentation/widgets/signal_strip.dart' as widgets;

/// Signal Strip component that appears at the top of the feed
/// This is a forwarding component that uses the implementation in the widgets directory
class SignalStrip extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    return widgets.SignalStrip(
      height: height,
      padding: padding,
      onCardTap: onCardTap,
      maxCards: maxCards,
      showHeader: showHeader,
      signalTypes: signalTypes,
      useGlassEffect: useGlassEffect,
      glassOpacity: glassOpacity,
      customSignalContent: customSignalContent,
    );
  }
} 