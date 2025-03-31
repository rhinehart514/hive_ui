import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ui/features/auth/domain/entities/auth_user.dart';
import 'package:hive_ui/features/auth/domain/services/auth_analytics_service.dart';
import 'package:hive_ui/services/user_preferences_service.dart';

/// Represents the different steps in the onboarding process
enum OnboardingStep {
  /// Initial profile setup (name, bio, etc.)
  profileSetup,

  /// Selecting interests/categories
  interestSelection,

  /// Adding profile photo
  profilePhoto,

  /// Connecting with friends/clubs
  connections,

  /// Completed onboarding
  completed,
}

/// State class for the onboarding process
class OnboardingState {
  /// Current step in the onboarding process
  final OnboardingStep currentStep;

  /// Loading state for async operations
  final bool isLoading;

  /// Error message if any
  final String? errorMessage;

  /// User profile data collected during onboarding
  final Map<String, dynamic> profileData;

  /// Whether the onboarding is complete
  final bool isComplete;

  /// Timestamp when onboarding started
  final DateTime startTime;

  /// Timestamp of the last step change
  final DateTime lastStepTime;

  /// Creates an OnboardingState instance
  OnboardingState({
    this.currentStep = OnboardingStep.profileSetup,
    this.isLoading = false,
    this.errorMessage,
    Map<String, dynamic>? profileData,
    this.isComplete = false,
    DateTime? startTime,
    DateTime? lastStepTime,
  })  : profileData = profileData ?? {},
        startTime = startTime ?? DateTime.now(),
        lastStepTime = lastStepTime ?? DateTime.now();

  /// Creates a copy of this state with the given fields replaced with new values
  OnboardingState copyWith({
    OnboardingStep? currentStep,
    bool? isLoading,
    String? errorMessage,
    Map<String, dynamic>? profileData,
    bool? isComplete,
    DateTime? lastStepTime,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      profileData: profileData ?? Map.from(this.profileData),
      isComplete: isComplete ?? this.isComplete,
      startTime: startTime, // Start time never changes
      lastStepTime: lastStepTime ?? DateTime.now(),
    );
  }
}

/// Controller for managing the onboarding process
class OnboardingController extends StateNotifier<OnboardingState> {
  final FirebaseFirestore _firestore;
  final AuthUser _user;
  final AuthAnalyticsService _analyticsService;

  /// Creates an OnboardingController instance
  OnboardingController({
    required FirebaseFirestore firestore,
    required AuthUser user,
    required AuthAnalyticsService analyticsService,
  })  : _firestore = firestore,
        _user = user,
        _analyticsService = analyticsService,
        super(OnboardingState());

  /// Updates the profile data with new values
  void updateProfileData(Map<String, dynamic> data) {
    final updatedData = Map<String, dynamic>.from(state.profileData)
      ..addAll(data);
    state = state.copyWith(profileData: updatedData);
  }

  /// Moves to the next step in the onboarding process
  Future<void> nextStep() async {
    final currentStep = state.currentStep;
    final nextStep = _getNextStep(currentStep);

    // Calculate time spent on current step
    final timeSpent = DateTime.now().difference(state.lastStepTime).inSeconds;

    // Track step completion
    await _analyticsService.trackOnboardingStep(
      stepName: currentStep.toString().split('.').last,
      stepNumber: currentStep.index + 1,
      totalSteps:
          OnboardingStep.values.length - 1, // Subtract 'completed' state
      timeSpentSeconds: timeSpent,
    );

    // Update state
    state = state.copyWith(
      currentStep: nextStep,
      lastStepTime: DateTime.now(),
    );
  }

  /// Moves to the previous step in the onboarding process
  void previousStep() {
    final previousStep = _getPreviousStep(state.currentStep);
    state = state.copyWith(
      currentStep: previousStep,
      lastStepTime: DateTime.now(),
    );
  }

  /// Sets the current step in the onboarding process
  void setStep(OnboardingStep step) {
    state = state.copyWith(
      currentStep: step,
      lastStepTime: DateTime.now(),
    );
  }

  /// Saves the current onboarding progress to user preferences
  Future<void> saveProgress() async {
    try {
      final Map<String, dynamic> progressData = {
        'currentStep': state.currentStep.index,
        'profileData': state.profileData,
        'isComplete': state.isComplete,
        'startTime': state.startTime.millisecondsSinceEpoch,
        'lastStepTime': state.lastStepTime.millisecondsSinceEpoch,
      };

      await UserPreferencesService.setOnboardingData(progressData);
      debugPrint('Onboarding progress saved');
    } catch (e) {
      debugPrint('Error saving onboarding progress: $e');
    }
  }

  /// Saves the completed profile to Firestore
  Future<void> completeOnboarding() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Calculate total time spent in onboarding
      final totalTimeSeconds =
          DateTime.now().difference(state.startTime).inSeconds;

      // Add timestamp to profile data
      final profileData = Map<String, dynamic>.from(state.profileData)
        ..addAll({
          'onboardingCompletedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'onboardingTimeSeconds': totalTimeSeconds,
        });

      // Save to Firestore
      await _firestore.collection('users').doc(_user.id).set(
            profileData,
            SetOptions(merge: true),
          );

      // Track onboarding completion
      await _analyticsService.trackOnboardingCompleted(
        totalTimeSeconds: totalTimeSeconds,
        profileData: profileData,
      );

      // Update local state
      state = state.copyWith(
        isLoading: false,
        isComplete: true,
        currentStep: OnboardingStep.completed,
      );

      // Save completion status to preferences
      await UserPreferencesService.setOnboardingCompleted(true);

      debugPrint(
          'Onboarding completed successfully in $totalTimeSeconds seconds');
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to save profile: ${e.toString()}',
      );
    }
  }

  /// Loads saved onboarding progress from preferences
  Future<void> loadProgress() async {
    try {
      final progressData = await UserPreferencesService.getOnboardingData();

      if (progressData != null) {
        final stepIndex = progressData['currentStep'] as int;
        final profileData = progressData['profileData'] as Map<String, dynamic>;
        final isComplete = progressData['isComplete'] as bool;

        // Extract timestamps if available
        DateTime? startTime;
        DateTime? lastStepTime;

        if (progressData.containsKey('startTime')) {
          final startTimeMs = progressData['startTime'] as int;
          startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMs);
        }

        if (progressData.containsKey('lastStepTime')) {
          final lastStepTimeMs = progressData['lastStepTime'] as int;
          lastStepTime = DateTime.fromMillisecondsSinceEpoch(lastStepTimeMs);
        }

        state = OnboardingState(
          currentStep: OnboardingStep.values[stepIndex],
          profileData: profileData,
          isComplete: isComplete,
          startTime: startTime,
          lastStepTime: lastStepTime,
        );

        debugPrint('Loaded onboarding progress: ${state.currentStep}');
      }
    } catch (e) {
      debugPrint('Error loading onboarding progress: $e');
    }
  }

  /// Abandons the current onboarding process
  Future<void> abandonOnboarding() async {
    // Track abandonment
    await _analyticsService.trackOnboardingAbandoned(
      lastStep: state.currentStep.toString().split('.').last,
      lastStepNumber: state.currentStep.index + 1,
      totalSteps: OnboardingStep.values.length - 1,
      timeSpentSeconds: DateTime.now().difference(state.startTime).inSeconds,
    );

    // Clear progress
    await UserPreferencesService.clearOnboardingData();

    // Reset state
    state = OnboardingState();
  }

  /// Determines the next step based on the current step
  OnboardingStep _getNextStep(OnboardingStep currentStep) {
    switch (currentStep) {
      case OnboardingStep.profileSetup:
        return OnboardingStep.interestSelection;
      case OnboardingStep.interestSelection:
        return OnboardingStep.profilePhoto;
      case OnboardingStep.profilePhoto:
        return OnboardingStep.connections;
      case OnboardingStep.connections:
        return OnboardingStep.completed;
      case OnboardingStep.completed:
        return OnboardingStep.completed;
    }
  }

  /// Determines the previous step based on the current step
  OnboardingStep _getPreviousStep(OnboardingStep currentStep) {
    switch (currentStep) {
      case OnboardingStep.profileSetup:
        return OnboardingStep.profileSetup;
      case OnboardingStep.interestSelection:
        return OnboardingStep.profileSetup;
      case OnboardingStep.profilePhoto:
        return OnboardingStep.interestSelection;
      case OnboardingStep.connections:
        return OnboardingStep.profilePhoto;
      case OnboardingStep.completed:
        return OnboardingStep.connections;
    }
  }
}
