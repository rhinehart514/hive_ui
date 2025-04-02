import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/messaging/application/providers/messaging_providers.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A search bar for searching messages in a chat
class MessageSearchBar extends ConsumerStatefulWidget {
  final String chatId;
  final VoidCallback onClose;
  final Function(String) onSearch;
  
  const MessageSearchBar({
    Key? key,
    required this.chatId,
    required this.onClose,
    required this.onSearch,
  }) : super(key: key);
  
  @override
  ConsumerState<MessageSearchBar> createState() => _MessageSearchBarState();
}

class _MessageSearchBarState extends ConsumerState<MessageSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;
  
  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _searchController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
  
  void _onSearchChanged() {
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    // Set searching state
    ref.read(isSearchingProvider.notifier).state = _searchController.text.isNotEmpty;
    
    // Debounce search
    if (_searchController.text.trim().length > 2) {
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        widget.onSearch(_searchController.text.trim());
      });
    }
  }
  
  void _clearSearch() {
    _searchController.clear();
    ref.read(isSearchingProvider.notifier).state = false;
    ref.read(chatSearchQueryProvider.notifier).state = '';
  }
  
  @override
  Widget build(BuildContext context) {
    final isSearching = ref.watch(isSearchingProvider);
    
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade800,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              // Clear search and close
              _clearSearch();
              widget.onClose();
            },
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search in conversation',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: _clearSearch,
                      )
                    : null,
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  widget.onSearch(value.trim());
                }
              },
            ),
          ),
          if (isSearching)
            Container(
              width: 56,
              height: 56,
              padding: const EdgeInsets.all(16),
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
              ),
            ),
        ],
      ),
    );
  }
}

/// A widget that shows search results
class MessageSearchResults extends ConsumerWidget {
  final String chatId;
  final String query;
  final VoidCallback onClose;
  final Function(String) onMessageSelected;
  
  const MessageSearchResults({
    Key? key,
    required this.chatId,
    required this.query,
    required this.onClose,
    required this.onMessageSelected,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResultsAsync = ref.watch(searchMessagesProvider((chatId: chatId, query: query)));
    
    return Container(
      color: Colors.grey.shade900,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade800,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Search results for "$query"',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          
          // Results list
          Expanded(
            child: searchResultsAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No results found for "$query"',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: messages.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    
                    return InkWell(
                      onTap: () => onMessageSelected(message.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sender
                            Text(
                              message.senderName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            
                            // Message content with highlighted query
                            _buildHighlightedText(message.content, query),
                            
                            // Time
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(message.timestamp),
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Text(
                  'Error: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Formats time for display
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays < 1) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[time.weekday - 1];
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
  
  // Highlights query text in message content
  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(
        text,
        style: const TextStyle(fontSize: 14),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
    
    final pattern = RegExp(RegExp.escape(query), caseSensitive: false);
    final matches = pattern.allMatches(text.toLowerCase());
    
    if (matches.isEmpty) {
      return Text(
        text,
        style: const TextStyle(fontSize: 14),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
    
    final spans = <TextSpan>[];
    int lastEnd = 0;
    
    for (final match in matches) {
      // Add text before match
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, match.start),
            style: const TextStyle(fontSize: 14),
          ),
        );
      }
      
      // Add highlighted match
      spans.add(
        TextSpan(
          text: text.substring(match.start, match.end),
          style: TextStyle(
            fontSize: 14,
            backgroundColor: AppColors.gold.withOpacity(0.3),
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      
      lastEnd = match.end;
    }
    
    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastEnd),
          style: const TextStyle(fontSize: 14),
        ),
      );
    }
    
    return RichText(
      text: TextSpan(children: spans),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
} 
 
 