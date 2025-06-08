import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/feed/domain/models/quote_item.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:uuid/uuid.dart';

/// State class for quote posts
class QuotePostState {
  /// List of quote posts
  final List<QuoteItem> quotes;
  
  /// Error message if any
  final String? errorMessage;
  
  /// Loading state
  final bool isLoading;
  
  /// Constructor
  const QuotePostState({
    this.quotes = const [],
    this.errorMessage,
    this.isLoading = false,
  });
  
  /// Create a copy with some fields replaced
  QuotePostState copyWith({
    List<QuoteItem>? quotes,
    String? errorMessage,
    bool? isLoading,
  }) {
    return QuotePostState(
      quotes: quotes ?? this.quotes,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// NotifierProvider for quote posts
class QuotePostNotifier extends StateNotifier<QuotePostState> {
  /// Constructor
  QuotePostNotifier() : super(const QuotePostState());
  
  /// Add a new quote post
  Future<void> addQuote({
    required Event event,
    required UserProfile author,
    required String content,
  }) async {
    try {
      state = state.copyWith(isLoading: true);
      
      // Create a new quote
      final quote = QuoteItem(
        id: const Uuid().v4(),
        event: event,
        author: author,
        content: content,
        createdAt: DateTime.now(),
      );
      
      // Add to the list
      final updatedQuotes = [...state.quotes, quote];
      
      // In a real app, this would save to a backend
      // For now, we'll just update the state
      
      // Update the state with the new quote
      state = state.copyWith(
        quotes: updatedQuotes,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create quote: $e',
      );
    }
  }
  
  /// Delete a quote post
  Future<void> deleteQuote(String quoteId) async {
    try {
      state = state.copyWith(isLoading: true);
      
      // Filter out the quote with the given ID
      final updatedQuotes = state.quotes.where((q) => q.id != quoteId).toList();
      
      // Update the state
      state = state.copyWith(
        quotes: updatedQuotes,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete quote: $e',
      );
    }
  }
  
  /// Get quotes for a specific event
  List<QuoteItem> getQuotesForEvent(String eventId) {
    return state.quotes.where((q) => q.event.id == eventId).toList();
  }
  
  /// Get quotes by a specific user
  List<QuoteItem> getQuotesByUser(String userId) {
    return state.quotes.where((q) => q.author.id == userId).toList();
  }
}

/// Provider for quote posts
final quotePostProvider = StateNotifierProvider<QuotePostNotifier, QuotePostState>((ref) {
  return QuotePostNotifier();
});

/// Provider to get all quotes
final allQuotesProvider = Provider<List<QuoteItem>>((ref) {
  return ref.watch(quotePostProvider).quotes;
});

/// Provider to get quotes for a specific event
final eventQuotesProvider = Provider.family<List<QuoteItem>, String>((ref, eventId) {
  return ref.watch(quotePostProvider.notifier).getQuotesForEvent(eventId);
});

/// Provider to get quotes by a specific user
final userQuotesProvider = Provider.family<List<QuoteItem>, String>((ref, userId) {
  return ref.watch(quotePostProvider.notifier).getQuotesByUser(userId);
}); 