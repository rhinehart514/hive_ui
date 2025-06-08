import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/club_providers.dart';
import '../providers/event_providers.dart';
import '../models/club.dart';
import '../models/event.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildResultItem(dynamic item) {
    if (item is Club) {
      return ListTile(
        leading: const Icon(Icons.group, color: Color(0xFFEEBA2A)),
        title: Text(
          item.name,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          'Club',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        onTap: () {
          // Navigate to club details
        },
      );
    } else if (item is Event) {
      return ListTile(
        leading: const Icon(Icons.event, color: Color(0xFFEEBA2A)),
        title: Text(
          item.title,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          'Event',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        onTap: () {
          // Navigate to event details
        },
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSearchResults(List<Club> clubs, List<Event> events) {
    final results = [...clubs, ...events];
    if (results.isEmpty && _searchQuery.isNotEmpty) {
      return const Center(
        child: Text(
          'No results found',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) => _buildResultItem(results[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Search',
          style: TextStyle(
            color: Color(0xFFEEBA2A),
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search events and clubs...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  final clubsAsync =
                      ref.watch(searchClubsProvider(_searchQuery));
                  final eventsAsync =
                      ref.watch(searchEventsProvider(_searchQuery));

                  return clubsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFFEEBA2A)),
                      ),
                    ),
                    error: (error, stack) => Center(
                      child: Text(
                        'Error: $error',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    data: (clubs) => eventsAsync.when(
                      loading: () => _buildSearchResults(clubs, []),
                      error: (error, stack) => _buildSearchResults(clubs, []),
                      data: (events) => _buildSearchResults(clubs, events),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
