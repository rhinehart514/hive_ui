import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User preferences state
class UserPreferencesState {
  /// Whether the user has accepted the terms
  final bool hasAcceptedTerms;
  
  /// When the user accepted the terms
  final DateTime? termsAcceptedAt;
  
  /// Whether the user has accepted the privacy policy
  final bool hasAcceptedPrivacyPolicy;
  
  /// When the user accepted the privacy policy
  final DateTime? privacyPolicyAcceptedAt;
  
  /// User preferred theme (light/dark/system)
  final String theme;
  
  /// User notification preferences enabled/disabled
  final bool notificationsEnabled;
  
  /// Constructor
  const UserPreferencesState({
    this.hasAcceptedTerms = false,
    this.termsAcceptedAt,
    this.hasAcceptedPrivacyPolicy = false,
    this.privacyPolicyAcceptedAt,
    this.theme = 'dark',
    this.notificationsEnabled = true,
  });
  
  /// Create a copy with modified fields
  UserPreferencesState copyWith({
    bool? hasAcceptedTerms,
    DateTime? termsAcceptedAt,
    bool? hasAcceptedPrivacyPolicy,
    DateTime? privacyPolicyAcceptedAt,
    String? theme,
    bool? notificationsEnabled,
  }) {
    return UserPreferencesState(
      hasAcceptedTerms: hasAcceptedTerms ?? this.hasAcceptedTerms,
      termsAcceptedAt: termsAcceptedAt ?? this.termsAcceptedAt,
      hasAcceptedPrivacyPolicy: hasAcceptedPrivacyPolicy ?? this.hasAcceptedPrivacyPolicy,
      privacyPolicyAcceptedAt: privacyPolicyAcceptedAt ?? this.privacyPolicyAcceptedAt,
      theme: theme ?? this.theme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

/// User preferences controller to manage user preferences
class UserPreferencesNotifier extends StateNotifier<UserPreferencesState> {
  /// Shared preferences instance for persisting data
  final SharedPreferences _preferences;
  
  /// Preference keys
  static const String _kHasAcceptedTerms = 'has_accepted_terms';
  static const String _kTermsAcceptedAt = 'terms_accepted_at';
  static const String _kHasAcceptedPrivacyPolicy = 'has_accepted_privacy_policy';
  static const String _kPrivacyPolicyAcceptedAt = 'privacy_policy_accepted_at';
  static const String _kTheme = 'theme';
  static const String _kNotificationsEnabled = 'notifications_enabled';
  
  /// Constructor
  UserPreferencesNotifier(this._preferences)
      : super(UserPreferencesState(
          hasAcceptedTerms: _preferences.getBool(_kHasAcceptedTerms) ?? false,
          termsAcceptedAt: _getDateTimeFromPrefs(_preferences, _kTermsAcceptedAt),
          hasAcceptedPrivacyPolicy: _preferences.getBool(_kHasAcceptedPrivacyPolicy) ?? false,
          privacyPolicyAcceptedAt: _getDateTimeFromPrefs(_preferences, _kPrivacyPolicyAcceptedAt),
          theme: _preferences.getString(_kTheme) ?? 'dark',
          notificationsEnabled: _preferences.getBool(_kNotificationsEnabled) ?? true,
        ));
  
  /// Get a DateTime from preferences
  static DateTime? _getDateTimeFromPrefs(SharedPreferences prefs, String key) {
    final timestamp = prefs.getInt(key);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }
  
  /// Check if the user has accepted the terms
  Future<bool> hasAcceptedTerms() async {
    return state.hasAcceptedTerms;
  }
  
  /// Set the terms accepted status
  Future<void> setTermsAccepted(DateTime acceptedAt) async {
    await _preferences.setBool(_kHasAcceptedTerms, true);
    await _preferences.setInt(
      _kTermsAcceptedAt,
      acceptedAt.millisecondsSinceEpoch,
    );
    
    state = state.copyWith(
      hasAcceptedTerms: true,
      termsAcceptedAt: acceptedAt,
    );
  }
  
  /// Check if the user has accepted the privacy policy
  Future<bool> hasAcceptedPrivacyPolicy() async {
    return state.hasAcceptedPrivacyPolicy;
  }
  
  /// Set the privacy policy accepted status
  Future<void> setPrivacyPolicyAccepted(DateTime acceptedAt) async {
    await _preferences.setBool(_kHasAcceptedPrivacyPolicy, true);
    await _preferences.setInt(
      _kPrivacyPolicyAcceptedAt,
      acceptedAt.millisecondsSinceEpoch,
    );
    
    state = state.copyWith(
      hasAcceptedPrivacyPolicy: true,
      privacyPolicyAcceptedAt: acceptedAt,
    );
  }
  
  /// Set the theme preference
  Future<void> setTheme(String theme) async {
    await _preferences.setString(_kTheme, theme);
    state = state.copyWith(theme: theme);
  }
  
  /// Toggle notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _preferences.setBool(_kNotificationsEnabled, enabled);
    state = state.copyWith(notificationsEnabled: enabled);
  }
  
  /// Reset all preferences to default
  Future<void> reset() async {
    await _preferences.clear();
    state = const UserPreferencesState();
  }
}

/// Shared preferences provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'SharedPreferences must be initialized before accessing this provider',
  );
});

/// User preferences provider
final userPreferencesProvider = StateNotifierProvider<UserPreferencesNotifier, UserPreferencesState>((ref) {
  final preferences = ref.watch(sharedPreferencesProvider);
  return UserPreferencesNotifier(preferences);
}); 