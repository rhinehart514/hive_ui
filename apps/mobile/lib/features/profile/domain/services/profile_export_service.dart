import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hive_ui/core/event_bus/app_event_bus.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:hive_ui/services/profile_sync_service_new.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Service for exporting and importing user profiles
class ProfileExportService {
  /// Default file name for exported profiles
  static const String defaultFileName = 'hive_profile.json';
  
  /// Firestore service for profile syncing
  final ProfileSyncService _profileSyncService;
  
  /// Event bus for broadcasting profile updates
  final AppEventBus _eventBus;

  /// Constructor for ProfileExportService
  ProfileExportService({
    ProfileSyncService? profileSyncService,
    AppEventBus? eventBus,
  }) : _profileSyncService = profileSyncService ?? ProfileSyncService(
          firestore: FirebaseFirestore.instance,
          storage: FirebaseStorage.instance,
        ),
        _eventBus = eventBus ?? AppEventBus();

  /// Export the user profile to a JSON file
  /// 
  /// Returns the path to the exported file
  Future<String> exportProfile(UserProfile profile) async {
    try {
      // Create a full export data structure with metadata
      final exportData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'profile': profile.toJson(),
      };
      
      // Convert to JSON string with pretty printing
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      
      // Get the application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$defaultFileName';
      
      // Write the JSON string to the file
      final file = File(filePath);
      await file.writeAsString(jsonString);
      
      debugPrint('ProfileExportService: Profile exported to: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('ProfileExportService: Error exporting profile: $e');
      throw Exception('Failed to export profile: $e');
    }
  }
  
  /// Share the profile export file
  Future<void> shareExportedProfile(String filePath) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'HIVE Profile Export',
        text: 'My HIVE Profile Data',
      );
    } catch (e) {
      debugPrint('ProfileExportService: Error sharing profile: $e');
      throw Exception('Failed to share profile: $e');
    }
  }
  
  /// Export and immediately share the profile
  Future<void> exportAndShareProfile(UserProfile profile) async {
    final filePath = await exportProfile(profile);
    await shareExportedProfile(filePath);
  }
  
  /// Import a profile from a JSON file
  /// 
  /// Returns the imported profile
  Future<UserProfile> importProfile(String filePath) async {
    try {
      // Read the file
      final file = File(filePath);
      final jsonString = await file.readAsString();
      
      // Parse the JSON
      final importData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Validate the import data format
      _validateImportData(importData);
      
      // Extract the profile data
      final profileData = importData['profile'] as Map<String, dynamic>;
      
      // Create a UserProfile object
      final importedProfile = UserProfile.fromJson(profileData);
      
      // Perform validation on the imported profile
      _validateImportedProfile(importedProfile);
      
      return importedProfile;
    } catch (e) {
      debugPrint('ProfileExportService: Error importing profile: $e');
      throw Exception('Failed to import profile: $e');
    }
  }
  
  /// Apply an imported profile to the current user
  /// 
  /// Returns true if successful
  Future<bool> applyImportedProfile(UserProfile importedProfile) async {
    try {
      // Get the current authenticated user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user to apply profile to');
      }
      
      // Preserve the current user's ID and authentication details
      final mergedProfile = importedProfile.copyWith(
        id: currentUser.uid,
        email: currentUser.email ?? importedProfile.email,
        updatedAt: DateTime.now(),
      );
      
      // Update the profile in Firebase and local storage
      final updateFields = mergedProfile.toJson();
      final success = await _profileSyncService.batchUpdateProfile(
        mergedProfile.id,
        updateFields,
      );
      
      if (success) {
        // Also update local storage
        await UserPreferencesService.storeProfile(mergedProfile);
        
        // Notify the app about the profile update
        _eventBus.emit(ProfileUpdatedEvent(
          userId: mergedProfile.id,
          updates: {'profile_imported': DateTime.now().toIso8601String()},
        ));
        
        debugPrint('ProfileExportService: Imported profile applied successfully');
      }
      
      return success;
    } catch (e) {
      debugPrint('ProfileExportService: Error applying imported profile: $e');
      throw Exception('Failed to apply imported profile: $e');
    }
  }
  
  /// Validate the import data format
  void _validateImportData(Map<String, dynamic> importData) {
    if (!importData.containsKey('version')) {
      throw Exception('Invalid import format: missing version information');
    }
    
    if (!importData.containsKey('profile')) {
      throw Exception('Invalid import format: missing profile data');
    }
    
    final profileData = importData['profile'];
    if (profileData is! Map<String, dynamic>) {
      throw Exception('Invalid import format: profile data is not a valid object');
    }
  }
  
  /// Validate the imported profile
  void _validateImportedProfile(UserProfile profile) {
    // Basic validation
    if (profile.username.isEmpty || profile.displayName.isEmpty) {
      throw Exception('Invalid profile: missing required fields');
    }
    
    // Validate that there's no malicious content
    // This is a simple check; you might want to add more sophisticated validation
    final suspiciousFields = [profile.bio, profile.username, profile.displayName];
    for (final field in suspiciousFields) {
      if (field != null && _containsSuspiciousContent(field)) {
        throw Exception('Invalid profile: contains potentially malicious content');
      }
    }
  }
  
  /// Check if a string contains potentially malicious content
  bool _containsSuspiciousContent(String content) {
    // Check for common script injection patterns
    final suspiciousPatterns = [
      '<script>', 
      'javascript:', 
      'onerror=', 
      'onclick=',
      'data:text/html',
    ];
    
    return suspiciousPatterns.any((pattern) => 
      content.toLowerCase().contains(pattern.toLowerCase()));
  }
} 