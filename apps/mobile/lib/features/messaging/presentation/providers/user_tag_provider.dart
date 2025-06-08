import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Model for a user tag
class UserTag {
  /// User ID
  final String userId;
  
  /// Username for display
  final String username;
  
  /// User tag constructor
  UserTag({
    required this.userId,
    required this.username,
  });
  
  /// Create from JSON
  factory UserTag.fromJson(Map<String, dynamic> json) {
    return UserTag(
      userId: json['userId'] as String,
      username: json['username'] as String,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
    };
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserTag && other.userId == userId;
  }
  
  @override
  int get hashCode => userId.hashCode;
}

/// State for user tags
class UserTagsState {
  /// All selected user tags
  final List<UserTag> tags;
  
  /// Is loading
  final bool isLoading;
  
  /// Error message if any
  final String? error;
  
  /// Constructor
  UserTagsState({
    required this.tags,
    this.isLoading = false,
    this.error,
  });
  
  /// Initial empty state
  factory UserTagsState.initial() {
    return UserTagsState(tags: []);
  }
  
  /// Create copy with new values
  UserTagsState copyWith({
    List<UserTag>? tags,
    bool? isLoading,
    String? error,
  }) {
    return UserTagsState(
      tags: tags ?? this.tags,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing user tags
class UserTagsNotifier extends StateNotifier<UserTagsState> {
  final SharedPreferences _prefs;
  static const String _storageKey = 'user_tags';
  
  /// Constructor
  UserTagsNotifier(this._prefs) : super(UserTagsState.initial()) {
    // Load saved tags when initialized
    _loadTags();
  }
  
  /// Load tags from storage
  Future<void> _loadTags() async {
    try {
      state = state.copyWith(isLoading: true);
      
      final tagsJson = _prefs.getStringList(_storageKey);
      if (tagsJson == null) {
        state = state.copyWith(isLoading: false);
        return;
      }
      
      final List<UserTag> loadedTags = tagsJson
          .map((tagStr) => UserTag.fromJson(_decodeJson(tagStr)))
          .toList();
      
      state = state.copyWith(
        tags: loadedTags,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error loading tags: $e');
      state = state.copyWith(
        error: 'Failed to load tags',
        isLoading: false,
      );
    }
  }
  
  /// Save tags to storage
  Future<void> _saveTags() async {
    try {
      final tagsJson = state.tags
          .map((tag) => _encodeJson(tag.toJson()))
          .toList();
      
      await _prefs.setStringList(_storageKey, tagsJson);
    } catch (e) {
      debugPrint('Error saving tags: $e');
      state = state.copyWith(
        error: 'Failed to save tags',
      );
    }
  }
  
  /// Helper to encode JSON to string
  String _encodeJson(Map<String, dynamic> json) {
    return json.entries
        .map((e) => '${e.key}:${e.value}')
        .join(',');
  }
  
  /// Helper to decode JSON from string
  Map<String, dynamic> _decodeJson(String jsonStr) {
    final pairs = jsonStr.split(',');
    return Map.fromEntries(
      pairs.map((pair) {
        final parts = pair.split(':');
        return MapEntry(parts[0], parts[1]);
      }),
    );
  }
  
  /// Add a new tag - automatically saved
  Future<void> addTag(UserTag tag) async {
    // Check if tag already exists
    if (state.tags.any((t) => t.userId == tag.userId)) {
      return;
    }
    
    final updatedTags = [...state.tags, tag];
    state = state.copyWith(tags: updatedTags);
    
    // Auto-save
    await _saveTags();
  }
  
  /// Remove a tag by ID - automatically saved
  Future<void> removeTagById(String userId) async {
    final updatedTags = state.tags.where((tag) => tag.userId != userId).toList();
    state = state.copyWith(tags: updatedTags);
    
    // Auto-save
    await _saveTags();
  }
  
  /// Clear all tags - automatically saved
  Future<void> clearAllTags() async {
    state = state.copyWith(tags: []);
    
    // Auto-save
    await _saveTags();
  }
}

/// Provider for user tags
final userTagsProvider = StateNotifierProvider<UserTagsNotifier, UserTagsState>((ref) {
  final prefs = ref.watch(_sharedPreferencesProvider);
  return UserTagsNotifier(prefs);
});

/// Provider for shared preferences
final _sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize this provider in your main.dart');
});

/// Initialize shared preferences provider
Future<void> initializeUserTagProviders(ProviderContainer container) async {
  final prefs = await SharedPreferences.getInstance();
  container.updateOverrides([
    _sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
} 