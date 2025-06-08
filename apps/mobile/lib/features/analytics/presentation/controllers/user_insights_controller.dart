import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/analytics/domain/usecases/get_user_insights_usecase.dart';
import 'package:hive_ui/features/analytics/domain/usecases/track_user_activity_usecase.dart';
import 'package:hive_ui/features/analytics/domain/providers/analytics_providers.dart' as providers;

/// State for the user insights controller
class UserInsightsState {
  final AsyncValue<UserInsights> insights;
  final String? error;

  const UserInsightsState({
    this.insights = const AsyncValue.loading(),
    this.error,
  });

  /// Create a copy with updated values
  UserInsightsState copyWith({
    AsyncValue<UserInsights>? insights,
    String? error,
  }) {
    return UserInsightsState(
      insights: insights ?? this.insights,
      error: error ?? this.error,
    );
  }
}

/// Controller for managing user insights
class UserInsightsController extends StateNotifier<UserInsightsState> {
  final String userId;
  final GetUserInsightsUseCase _getUserInsightsUseCase;
  final TrackUserActivityUseCase _trackActivityUseCase;
  final Ref _ref;
  
  UserInsightsController({
    required this.userId,
    required GetUserInsightsUseCase getUserInsightsUseCase,
    required TrackUserActivityUseCase trackActivityUseCase,
    required Ref ref,
  })  : _getUserInsightsUseCase = getUserInsightsUseCase,
        _trackActivityUseCase = trackActivityUseCase,
        _ref = ref,
        super(const UserInsightsState()) {
    // Load insights when controller is created
    loadInsights();
  }
  
  /// Track that a user viewed analytics
  Future<void> trackAnalyticsView() async {
    await _trackActivityUseCase.trackProfileView(userId);
  }
  
  /// Load user insights
  Future<void> loadInsights() async {
    state = state.copyWith(insights: const AsyncValue.loading());

    try {
      final result = await _getUserInsightsUseCase.call(userId);
      
      result.fold(
        (failure) => state = state.copyWith(
          insights: AsyncValue.error(failure, StackTrace.current),
          error: failure.message,
        ),
        (insights) => state = state.copyWith(
          insights: AsyncValue.data(insights),
          error: null,
        ),
      );
    } catch (e, stack) {
      state = state.copyWith(
        insights: AsyncValue.error(e, stack),
        error: 'Failed to load insights',
      );
    }
  }
  
  /// Refresh insights data
  Future<void> refresh() => loadInsights();
  
  /// Export analytics for a user
  Future<Map<String, dynamic>> exportAnalytics() async {
    final result = await _getUserInsightsUseCase.call(userId);
    
    return result.fold(
      (failure) => throw failure,
      (insights) => {
        'engagementScore': insights.engagementScore,
        'peakActivityHour': insights.peakActivityHour,
        'mostActiveDay': insights.mostActiveDay,
        'isActiveUser': insights.isActive,
        'metrics': {
          'profileViews': insights.metrics.profileViews,
          'contentCreated': insights.metrics.contentCreated,
          'contentEngagement': insights.metrics.contentEngagement,
          'spacesJoined': insights.metrics.spacesJoined,
          'eventsAttended': insights.metrics.eventsAttended,
        },
        'categoryBreakdown': insights.categoryBreakdown,
        'recentEvents': insights.recentEvents.map((e) => e.getEventDescription()).toList(),
      },
    );
  }
}

/// Provider for the user insights controller
final userInsightsControllerProvider = StateNotifierProvider.family<UserInsightsController, UserInsightsState, String>(
  (ref, userId) => UserInsightsController(
    userId: userId,
    getUserInsightsUseCase: ref.watch(providers.getUserInsightsUseCaseProvider),
    trackActivityUseCase: ref.watch(providers.trackUserActivityUseCaseProvider),
    ref: ref,
  ),
); 