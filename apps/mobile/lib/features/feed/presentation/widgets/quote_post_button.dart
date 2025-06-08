import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/feed/presentation/providers/quote_provider.dart';
import 'package:hive_ui/features/feed/presentation/widgets/quote_post_dialog.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A button for creating quote posts
class QuotePostButton extends ConsumerWidget {
  /// The event to quote
  final Event event;
  
  /// Size of the button
  final double size;
  
  /// Optional icon color
  final Color? iconColor;
  
  /// Optional button color
  final Color? buttonColor;
  
  /// Optional callback when the quote is posted
  final VoidCallback? onQuotePosted;

  /// Constructor
  const QuotePostButton({
    Key? key,
    required this.event,
    this.size = 40,
    this.iconColor,
    this.buttonColor,
    this.onQuotePosted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(size / 2),
        onTap: () => _handleTap(context, ref),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: buttonColor ?? Colors.transparent,
            border: Border.all(
              color: (iconColor ?? AppColors.gold).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.format_quote_rounded,
              color: iconColor ?? AppColors.gold,
              size: size * 0.5,
            ),
          ),
        ),
      ),
    );
  }
  
  /// Handle the button tap - show the quote dialog
  void _handleTap(BuildContext context, WidgetRef ref) {
    // Provide haptic feedback for button press
    HapticFeedback.mediumImpact();
    
    // Show the quote post dialog
    QuotePostDialog.show(
      context: context,
      event: event,
      onQuoteSubmit: (event, comment, userProfile) {
        _handleQuoteSubmit(ref, event, comment, userProfile);
      },
    );
  }
  
  /// Handle the quote submission
  void _handleQuoteSubmit(WidgetRef ref, Event event, String content, UserProfile author) {
    // Add the quote to the provider
    ref.read(quotePostProvider.notifier).addQuote(
      event: event,
      author: author,
      content: content,
    );
    
    // Call the callback if provided
    if (onQuotePosted != null) {
      onQuotePosted!();
    }
  }
} 