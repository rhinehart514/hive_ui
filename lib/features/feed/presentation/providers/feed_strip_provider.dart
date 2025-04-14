import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/feed/domain/entities/signal_content.dart';
import 'package:hive_ui/features/feed/presentation/providers/signal_provider.dart';

/// Provider to specifically get Space Heat cards for the Feed Strip
final spaceHeatCardsProvider = FutureProvider<List<SignalContent>>((ref) async {
  // Create params to only fetch space heat cards
  final params = SignalContentParams(
    maxItems: 3,
    types: [SignalType.spaceHeat],
  );
  
  // Use the existing signalContentProvider to get the cards
  return ref.watch(signalContentProvider(params).future);
});

/// Provider to specifically get Ritual Launch cards for the Feed Strip
final ritualLaunchCardsProvider = FutureProvider<List<SignalContent>>((ref) async {
  // Create params to only fetch ritual launch cards
  final params = SignalContentParams(
    maxItems: 2,
    types: [SignalType.ritualLaunch],
  );
  
  // Use the existing signalContentProvider to get the cards
  return ref.watch(signalContentProvider(params).future);
});

/// Provider to specifically get Friend Motion cards for the Feed Strip
final friendMotionCardsProvider = FutureProvider<List<SignalContent>>((ref) async {
  // Create params to only fetch friend motion cards
  final params = SignalContentParams(
    maxItems: 2,
    types: [SignalType.friendMotion],
  );
  
  // Use the existing signalContentProvider to get the cards
  return ref.watch(signalContentProvider(params).future);
});

/// Provider to get Time Marker cards for the Feed Strip
final timeMarkerCardsProvider = FutureProvider<List<SignalContent>>((ref) async {
  // Determine the appropriate time marker type based on current time
  final currentHour = DateTime.now().hour;
  SignalType timeMarkerType;
  
  if (currentHour >= 5 && currentHour < 12) {
    timeMarkerType = SignalType.timeMorning;
  } else if (currentHour >= 12 && currentHour < 18) {
    timeMarkerType = SignalType.timeAfternoon;
  } else {
    timeMarkerType = SignalType.timeEvening;
  }
  
  // Create params to fetch the appropriate time marker
  final params = SignalContentParams(
    maxItems: 1,
    types: [timeMarkerType],
  );
  
  // Use the existing signalContentProvider to get the cards
  return ref.watch(signalContentProvider(params).future);
});

/// Class that combines various feed strip card types into a single collection
class FeedStripCards {
  final List<SignalContent> spaceHeatCards;
  final List<SignalContent> ritualLaunchCards;
  final List<SignalContent> friendMotionCards;
  final List<SignalContent> timeMarkerCards;
  
  const FeedStripCards({
    required this.spaceHeatCards,
    required this.ritualLaunchCards,
    required this.friendMotionCards,
    required this.timeMarkerCards,
  });
  
  /// Get all cards combined and sorted by priority
  List<SignalContent> get allCards {
    final combined = [
      ...spaceHeatCards,
      ...ritualLaunchCards,
      ...friendMotionCards,
      ...timeMarkerCards,
    ];
    
    // Sort by priority (highest first)
    combined.sort((a, b) => b.priority.compareTo(a.priority));
    return combined;
  }
}

/// Provider that combines all feed strip card types
final feedStripCardsProvider = FutureProvider<FeedStripCards>((ref) async {
  // Get all card types in parallel
  final spaceHeatCardsFuture = ref.watch(spaceHeatCardsProvider.future);
  final ritualLaunchCardsFuture = ref.watch(ritualLaunchCardsProvider.future);
  final friendMotionCardsFuture = ref.watch(friendMotionCardsProvider.future);
  final timeMarkerCardsFuture = ref.watch(timeMarkerCardsProvider.future);
  
  // Wait for all to complete
  final spaceHeatCards = await spaceHeatCardsFuture;
  final ritualLaunchCards = await ritualLaunchCardsFuture;
  final friendMotionCards = await friendMotionCardsFuture;
  final timeMarkerCards = await timeMarkerCardsFuture;
  
  // Return the combined result
  return FeedStripCards(
    spaceHeatCards: spaceHeatCards,
    ritualLaunchCards: ritualLaunchCards,
    friendMotionCards: friendMotionCards,
    timeMarkerCards: timeMarkerCards,
  );
}); 