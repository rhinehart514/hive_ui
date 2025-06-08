import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/profile/data/repositories/trail_repository.dart';
import 'package:hive_ui/features/profile/domain/models/trail_entry.dart';

/// Provider for streaming the current user's trail
final currentUserTrailProvider = StreamProvider<List<TrailEntry>>((ref) {
  final repository = ref.watch(trailRepositoryProvider);
  return repository.getCurrentUserTrail();
});

/// Provider for streaming a specific user's trail
final userTrailProvider = StreamProvider.family<List<TrailEntry>, String>((ref, userId) {
  final repository = ref.watch(trailRepositoryProvider);
  return repository.getUserTrail(userId);
});

/// Provider for grouping trail entries by date
final groupedTrailEntriesProvider = Provider.family<Map<String, List<TrailEntry>>, List<TrailEntry>>(
  (ref, entries) {
    final groupedEntries = <String, List<TrailEntry>>{};
    
    for (final entry in entries) {
      final date = _formatDateKey(entry.timestamp);
      if (!groupedEntries.containsKey(date)) {
        groupedEntries[date] = [];
      }
      groupedEntries[date]!.add(entry);
    }
    
    return groupedEntries;
  },
);

/// Provider for grouping the current user's trail entries by date
final currentUserGroupedTrailProvider = Provider<Map<String, List<TrailEntry>>>((ref) {
  final trailAsync = ref.watch(currentUserTrailProvider);
  return trailAsync.when(
    data: (entries) => ref.watch(groupedTrailEntriesProvider(entries)),
    loading: () => {},
    error: (_, __) => {},
  );
});

/// Format a date into a standardized string key for grouping
String _formatDateKey(DateTime date) {
  // Today
  final now = DateTime.now();
  if (date.year == now.year && date.month == now.month && date.day == now.day) {
    return 'Today';
  }
  
  // Yesterday
  final yesterday = now.subtract(const Duration(days: 1));
  if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
    return 'Yesterday';
  }
  
  // This week (within 7 days)
  final weekAgo = now.subtract(const Duration(days: 7));
  if (date.isAfter(weekAgo)) {
    return 'This Week';
  }
  
  // This month
  if (date.year == now.year && date.month == now.month) {
    return 'This Month';
  }
  
  // Last month
  final lastMonth = DateTime(now.year, now.month - 1);
  if (date.year == lastMonth.year && date.month == lastMonth.month) {
    return 'Last Month';
  }
  
  // This year
  if (date.year == now.year) {
    return 'This Year';
  }
  
  // Earlier (beyond this year)
  return 'Earlier';
} 