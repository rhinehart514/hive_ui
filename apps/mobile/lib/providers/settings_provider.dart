import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/// Keys for storing settings in SharedPreferences
class SettingsKeys {
  static const String profilePrivacy = 'profile_privacy';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String pushNotifications = 'push_notifications';
  static const String emailNotifications = 'email_notifications';
  static const String theme = 'theme';
  static const String fontScale = 'font_scale';
  static const String dataSaver = 'data_saver';
  static const String analyticsEnabled = 'analytics_enabled';
  static const String faceIdEnabled = 'face_id_enabled';
}

/// Enum for theme settings
enum AppTheme {
  system,
  dark,
  light,
}

/// Settings state class
class SettingsState {
  final bool profilePrivate;
  final bool notificationsEnabled;
  final bool pushNotificationsEnabled;
  final bool emailNotificationsEnabled;
  final AppTheme theme;
  final double fontScale;
  final bool dataSaverEnabled;
  final bool analyticsEnabled;
  final bool faceIdEnabled;

  const SettingsState({
    this.profilePrivate = false,
    this.notificationsEnabled = true,
    this.pushNotificationsEnabled = true,
    this.emailNotificationsEnabled = true,
    this.theme = AppTheme.system,
    this.fontScale = 1.0,
    this.dataSaverEnabled = false,
    this.analyticsEnabled = true,
    this.faceIdEnabled = false,
  });

  SettingsState copyWith({
    bool? profilePrivate,
    bool? notificationsEnabled,
    bool? pushNotificationsEnabled,
    bool? emailNotificationsEnabled,
    AppTheme? theme,
    double? fontScale,
    bool? dataSaverEnabled,
    bool? analyticsEnabled,
    bool? faceIdEnabled,
  }) {
    return SettingsState(
      profilePrivate: profilePrivate ?? this.profilePrivate,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      emailNotificationsEnabled:
          emailNotificationsEnabled ?? this.emailNotificationsEnabled,
      theme: theme ?? this.theme,
      fontScale: fontScale ?? this.fontScale,
      dataSaverEnabled: dataSaverEnabled ?? this.dataSaverEnabled,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      faceIdEnabled: faceIdEnabled ?? this.faceIdEnabled,
    );
  }
}

/// Settings notifier to manage the settings state
class SettingsNotifier extends StateNotifier<SettingsState> {
  final SharedPreferences _prefs;
  bool _isInitialized = false;

  SettingsNotifier(this._prefs) : super(const SettingsState()) {
    _loadSettings();
  }

  /// Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      debugPrint('📋 Loading settings from SharedPreferences...');

      final profilePrivate =
          _prefs.getBool(SettingsKeys.profilePrivacy) ?? false;
      final notificationsEnabled =
          _prefs.getBool(SettingsKeys.notificationsEnabled) ?? true;
      final pushNotifications =
          _prefs.getBool(SettingsKeys.pushNotifications) ?? true;
      final emailNotifications =
          _prefs.getBool(SettingsKeys.emailNotifications) ?? true;
      final themeString = _prefs.getString(SettingsKeys.theme) ?? 'system';
      final fontScale = _prefs.getDouble(SettingsKeys.fontScale) ?? 1.0;
      final dataSaver = _prefs.getBool(SettingsKeys.dataSaver) ?? false;
      final analyticsEnabled =
          _prefs.getBool(SettingsKeys.analyticsEnabled) ?? true;
      final faceIdEnabled = _prefs.getBool(SettingsKeys.faceIdEnabled) ?? false;

      state = state.copyWith(
        profilePrivate: profilePrivate,
        notificationsEnabled: notificationsEnabled,
        pushNotificationsEnabled: pushNotifications,
        emailNotificationsEnabled: emailNotifications,
        theme: AppTheme.values.firstWhere(
          (t) => t.toString() == 'AppTheme.$themeString',
          orElse: () => AppTheme.system,
        ),
        fontScale: fontScale,
        dataSaverEnabled: dataSaver,
        analyticsEnabled: analyticsEnabled,
        faceIdEnabled: faceIdEnabled,
      );

      debugPrint('✅ Settings loaded successfully: '
          'theme=$themeString, '
          'fontScale=$fontScale, '
          'notifications=$notificationsEnabled, '
          'profilePrivate=$profilePrivate, '
          'pushNotifications=$pushNotifications, '
          'emailNotifications=$emailNotifications, '
          'dataSaver=$dataSaver, '
          'analytics=$analyticsEnabled, '
          'faceId=$faceIdEnabled');
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading settings from SharedPreferences: $e');
      debugPrint('Stack trace: $stackTrace');

      // Despite the error, use defaults to avoid app breaking
      state = const SettingsState(
        profilePrivate: false,
        notificationsEnabled: true,
        pushNotificationsEnabled: true,
        emailNotificationsEnabled: true,
        theme: AppTheme.system,
        fontScale: 1.0,
        dataSaverEnabled: false,
        analyticsEnabled: true,
        faceIdEnabled: false,
      );
    }
  }

  /// Toggle profile privacy
  Future<void> toggleProfilePrivacy() async {
    final newValue = !state.profilePrivate;
    await _prefs.setBool(SettingsKeys.profilePrivacy, newValue);
    state = state.copyWith(profilePrivate: newValue);
    debugPrint('🔒 Profile privacy set to: $newValue');
  }

  /// Toggle notifications
  Future<void> toggleNotifications() async {
    final newValue = !state.notificationsEnabled;
    await _prefs.setBool(SettingsKeys.notificationsEnabled, newValue);
    state = state.copyWith(notificationsEnabled: newValue);
    debugPrint('🔔 Notifications set to: $newValue');
  }

  /// Toggle push notifications
  Future<void> togglePushNotifications() async {
    final newValue = !state.pushNotificationsEnabled;
    await _prefs.setBool(SettingsKeys.pushNotifications, newValue);
    state = state.copyWith(pushNotificationsEnabled: newValue);
    debugPrint('📱 Push notifications set to: $newValue');
  }

  /// Toggle email notifications
  Future<void> toggleEmailNotifications() async {
    final newValue = !state.emailNotificationsEnabled;
    await _prefs.setBool(SettingsKeys.emailNotifications, newValue);
    state = state.copyWith(emailNotificationsEnabled: newValue);
    debugPrint('📧 Email notifications set to: $newValue');
  }

  /// Set theme
  Future<void> setTheme(AppTheme theme) async {
    await _prefs.setString(
        SettingsKeys.theme, theme.toString().split('.').last);
    state = state.copyWith(theme: theme);
    debugPrint('🎨 Theme set to: ${theme.toString().split('.').last}');
  }

  /// Set font scale
  Future<void> setFontScale(double scale) async {
    await _prefs.setDouble(SettingsKeys.fontScale, scale);
    state = state.copyWith(fontScale: scale);
    debugPrint('🔤 Font scale set to: $scale');
  }

  /// Toggle data saver
  Future<void> toggleDataSaver() async {
    final newValue = !state.dataSaverEnabled;
    await _prefs.setBool(SettingsKeys.dataSaver, newValue);
    state = state.copyWith(dataSaverEnabled: newValue);
    debugPrint('💾 Data saver set to: $newValue');
  }

  /// Toggle analytics
  Future<void> toggleAnalytics() async {
    final newValue = !state.analyticsEnabled;
    await _prefs.setBool(SettingsKeys.analyticsEnabled, newValue);
    state = state.copyWith(analyticsEnabled: newValue);
    debugPrint('📊 Analytics set to: $newValue');
  }

  /// Toggle Face ID / Touch ID
  Future<void> toggleFaceId() async {
    final newValue = !state.faceIdEnabled;
    await _prefs.setBool(SettingsKeys.faceIdEnabled, newValue);
    state = state.copyWith(faceIdEnabled: newValue);
    debugPrint('👤 Face ID set to: $newValue');
  }

  /// Initialize the provider
  @override
  Future<void> build() async {
    try {
      debugPrint('🔄 Initializing settings provider...');
      await _loadSettings();

      // Set initialization flag
      _isInitialized = true;
      debugPrint('✅ Settings provider successfully initialized');
    } catch (e, stackTrace) {
      debugPrint('❌ Error initializing SettingsProvider: $e');
      debugPrint('Stack trace: $stackTrace');

      // Set default state on error
      state = const SettingsState(
        profilePrivate: false,
        notificationsEnabled: true,
        pushNotificationsEnabled: true,
        emailNotificationsEnabled: true,
        theme: AppTheme.system,
        fontScale: 1.0,
        dataSaverEnabled: false,
        analyticsEnabled: true,
        faceIdEnabled: false,
      );

      rethrow;
    }
  }

  /// Sync settings to SharedPreferences
  Future<void> _syncSettings() async {
    try {
      debugPrint('💾 Syncing settings to SharedPreferences...');

      // Profile privacy
      await _prefs.setBool(SettingsKeys.profilePrivacy, state.profilePrivate);

      // Notifications
      await _prefs.setBool(
          SettingsKeys.notificationsEnabled, state.notificationsEnabled);
      await _prefs.setBool(
          SettingsKeys.pushNotifications, state.pushNotificationsEnabled);
      await _prefs.setBool(
          SettingsKeys.emailNotifications, state.emailNotificationsEnabled);

      // Theme
      await _prefs.setString(SettingsKeys.theme, state.theme.name);

      // Appearance
      await _prefs.setDouble(SettingsKeys.fontScale, state.fontScale);

      // Performance
      await _prefs.setBool(SettingsKeys.dataSaver, state.dataSaverEnabled);

      // Privacy
      await _prefs.setBool(
          SettingsKeys.analyticsEnabled, state.analyticsEnabled);
      await _prefs.setBool(SettingsKeys.faceIdEnabled, state.faceIdEnabled);

      debugPrint('✅ Settings synced successfully to SharedPreferences');
    } catch (e, stackTrace) {
      debugPrint('❌ Error syncing settings to SharedPreferences: $e');
      debugPrint('Stack trace: $stackTrace');

      // Rethrow to let calling code handle specific errors
      rethrow;
    }
  }
}

/// Provider for settings state
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final sharedPrefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(sharedPrefs);
});

/// Provider for shared preferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('You must override this provider before using it');
});

/// Initialize shared preferences provider
Future<Override> initializeSettingsProvider() async {
  final prefs = await SharedPreferences.getInstance();
  return sharedPreferencesProvider.overrideWithValue(prefs);
}
