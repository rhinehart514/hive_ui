import 'package:flutter/material.dart';
import 'package:hive_ui/services/club_service.dart';
import 'package:hive_ui/services/rss_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ui/models/club.dart';
import 'package:hive_ui/services/space_service.dart';
import 'package:hive_ui/services/space_event_service.dart';

/// Admin utility functions for data management
class AdminTools {
  /// Branch types for clubs in Firestore
  static const List<String> branchTypes = [
    'student_organizations',
    'university_departments',
    'fraternity_sorority_life',
    'campus_living',
  ];

  /// Takes clubs from local cache and syncs them to Firestore
  /// Returns true if sync was successful, false otherwise
  static Future<bool> syncClubsToFirestore() async {
    try {
      debugPrint('Starting club sync to Firestore...');

      // First ensure ClubService is initialized
      await ClubService.initialize();

      // Get all clubs from cache - this will load from SharedPreferences
      final clubs = await ClubService.loadClubs();
      debugPrint('Loaded ${clubs.length} clubs from cache');

      if (clubs.isEmpty) {
        debugPrint('No clubs found in cache to sync to Firestore');
        return false;
      }

      // Use the built-in sync method from ClubService
      final success = await ClubService.syncAllClubsToFirestore();

      if (success) {
        debugPrint('Successfully synced ${clubs.length} clubs to Firestore');

        // Update metadata about the sync
        final firestore = FirebaseFirestore.instance;
        await firestore.collection('metadata').doc('admin_actions').set({
          'last_club_sync': FieldValue.serverTimestamp(),
          'club_count': clubs.length,
        }, SetOptions(merge: true));
      } else {
        debugPrint('Failed to sync clubs to Firestore');
      }

      return success;
    } catch (e) {
      debugPrint('Error syncing clubs to Firestore: $e');
      return false;
    }
  }

  /// Takes clubs from Firestore and loads them into local cache
  /// Useful for refreshing local data without RSS feeds
  static Future<int> loadClubsFromFirestore() async {
    try {
      // Initialize ClubService if needed
      await ClubService.initialize();

      // Use the built-in loading method
      final clubs = await ClubService.loadClubsFromFirestore();
      debugPrint('Loaded ${clubs.length} clubs from Firestore to local cache');

      return clubs.length;
    } catch (e) {
      debugPrint('Error loading clubs from Firestore: $e');
      return 0;
    }
  }

  /// Generate clubs from existing events
  /// Useful when there are no clubs but events exist
  static Future<int> generateClubsFromExistingEvents() async {
    try {
      // Initialize services
      await ClubService.initialize();

      // Get events from RSS service's cache
      final events = await RssService.fetchEvents(forceRefresh: false);

      if (events.isEmpty) {
        debugPrint('No events found to generate clubs from');
        return 0;
      }

      // Generate clubs from events
      final clubs = await ClubService.generateClubsFromEvents(events);
      debugPrint(
          'Generated ${clubs.length} clubs from ${events.length} events');

      // Sync the generated clubs to Firestore
      await ClubService.syncAllClubsToFirestore();

      return clubs.length;
    } catch (e) {
      debugPrint('Error generating clubs from events: $e');
      return 0;
    }
  }

  /// Directly categorize clubs into branches for Firestore
  /// This is a simplified alternative to the automatic detection
  static Future<void> categorizeClubsInFirestore() async {
    try {
      debugPrint('Starting manual club categorization...');
      final firestore = FirebaseFirestore.instance;

      // Map to hold clubs for each branch
      final Map<String, List<Club>> branchMap = {
        'campus_living': [],
        'fraternity_sorority_life': [],
        'student_organizations': [],
        'university_departments': [],
      };

      // Load clubs from Firestore first
      await ClubService.initialize();
      final clubs = await ClubService.loadClubsFromFirestore();

      if (clubs.isEmpty) {
        debugPrint('No clubs found to categorize');
        return;
      }

      // Categorize each club based on its category and name
      for (final club in clubs) {
        final branch = _determineBranchFromRssCategory(club);
        branchMap[branch]!.add(club);
      }

      // Log the distribution
      debugPrint('Club categorization by branch:');
      branchMap.forEach((branch, clubList) {
        debugPrint('  $branch: ${clubList.length} clubs');
      });

      // Update each club in Firestore with its branch
      final batch = firestore.batch();
      int count = 0;

      for (final entry in branchMap.entries) {
        final branch = entry.key;
        final branchClubs = entry.value;

        for (final club in branchClubs) {
          // Update the club_index document
          final indexRef = firestore.collection('club_index').doc(club.id);
          batch.set(
              indexRef,
              {
                'branch': branch,
                'path': 'clubs/$branch/entities/${club.id}',
                'name': club.name,
                'updated_at': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true));

          // Update the club document itself
          final clubRef = firestore
              .collection('clubs')
              .doc(branch)
              .collection('entities')
              .doc(club.id);
          batch.set(
              clubRef,
              {
                'branch': branch,
                'updated_at': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true));

          count++;

          // Commit batch every 400 operations (Firestore limit is 500)
          if (count % 400 == 0) {
            await batch.commit();
            debugPrint('Committed batch of $count clubs');
          }
        }
      }

      // Commit any remaining operations
      if (count % 400 != 0) {
        await batch.commit();
      }

      debugPrint('Successfully categorized $count clubs into branches');

      // Update metadata
      await firestore.collection('metadata').doc('club_categorization').set({
        'last_update': FieldValue.serverTimestamp(),
        'club_count': count,
        'branch_counts': {
          'campus_living': branchMap['campus_living']!.length,
          'fraternity_sorority_life':
              branchMap['fraternity_sorority_life']!.length,
          'student_organizations': branchMap['student_organizations']!.length,
          'university_departments': branchMap['university_departments']!.length,
        }
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error during club categorization: $e');
    }
  }

  /// Determine which branch a club should belong to based on its RSS category and name
  static String _determineBranchFromRssCategory(Club club) {
    final name = club.name.toLowerCase();
    final category = club.category.toLowerCase();
    final description = club.description.toLowerCase();

    // First check if it's a university department
    if (_isUniversityDepartment(name, category, description)) {
      return 'university_departments';
    }

    // Next check if it's Greek life
    if (_isGreekLife(name, category, description)) {
      return 'fraternity_sorority_life';
    }

    // Next check if it's campus living
    if (_isCampusLiving(name, category, description)) {
      return 'campus_living';
    }

    // Default to student organizations
    return 'student_organizations';
  }

  /// Check if a club is a university department
  static bool _isUniversityDepartment(
      String name, String category, String description) {
    // List of department keywords
    final departmentKeywords = [
      'department of',
      'school of',
      'college of',
      'office of',
      'center for',
      'institute of',
      'division of',
      'program in',
    ];

    // Department-specific categories
    final departmentCategories = [
      'academic',
      'education',
      'research',
      'administration',
      'faculty',
    ];

    // Check name for department keywords
    for (final keyword in departmentKeywords) {
      if (name.contains(keyword)) {
        return true;
      }
    }

    // Check if it's a known UB department and has a department-like category
    return ((name.contains('ub') ||
            name.contains('buffalo') ||
            name.contains('university')) &&
        (departmentCategories.contains(category) ||
            name.contains('dept') ||
            name.contains('department')));
  }

  /// Check if a club is related to Greek life
  static bool _isGreekLife(String name, String category, String description) {
    // Greek life categories
    if (category == 'greek life' ||
        category == 'fraternity' ||
        category == 'sorority' ||
        category.contains('greek')) {
      return true;
    }

    // Check for Greek letters in name
    final greekLetters = [
      'alpha',
      'beta',
      'gamma',
      'delta',
      'epsilon',
      'zeta',
      'eta',
      'theta',
      'iota',
      'kappa',
      'lambda',
      'mu',
      'nu',
      'xi',
      'omicron',
      'pi',
      'rho',
      'sigma',
      'tau',
      'upsilon',
      'phi',
      'chi',
      'psi',
      'omega'
    ];

    // Check if the name contains Greek letters AND fraternity/sorority keywords
    final hasGreekLetters = greekLetters.any((letter) => name.contains(letter));
    final isFratSorority = name.contains('fraternity') ||
        name.contains('sorority') ||
        name.contains('frat') ||
        name.contains('greek') ||
        description.contains('fraternity') ||
        description.contains('sorority');

    return hasGreekLetters && isFratSorority;
  }

  /// Check if a club is related to campus living
  static bool _isCampusLiving(
      String name, String category, String description) {
    // Campus living categories
    if (category == 'residence life' ||
        category == 'housing' ||
        category == 'dormitory' ||
        category == 'campus living' ||
        category.contains('residence')) {
      return true;
    }

    // Campus living keywords
    final livingKeywords = [
      'residence hall',
      'dormitory',
      'dorm',
      'housing',
      'residential',
      'living community',
      'hall council',
      'res life',
    ];

    // Check for these keywords in name and description
    for (final keyword in livingKeywords) {
      if (name.contains(keyword) || description.contains(keyword)) {
        return true;
      }
    }

    // Specific residence hall names (can expand this list)
    final hallNames = [
      'greiner',
      'ellicott',
      'governors',
      'creekside',
      'flint',
      'red jacket',
      'richmond',
      'wilkeson',
      'spaulding',
    ];

    return hallNames.any((hall) => name.contains(hall));
  }

  /// Run a verification of event-space assignments
  Future<Map<String, dynamic>> verifyEventSpaceAssignments() async {
    debugPrint('Starting event-space assignment verification...');
    final results = await SpaceService.verifyEventSpaceAssignments();
    debugPrint('Verification complete.');
    return results;
  }

  /// Find and fix unassigned events
  Future<Map<String, dynamic>> fixUnassignedEvents() async {
    debugPrint('Starting event-space fix operation...');
    final results = await SpaceEventService.findAndFixUnassignedEvents();
    debugPrint('Fix operation complete.');
    return results;
  }

  /// Run a full event-space verification and fix operation
  Future<Map<String, dynamic>> verifyAndFixEventSpaceAssignments() async {
    debugPrint(
        'Starting comprehensive event-space verification and fix process...');

    // First verify to get the initial state
    debugPrint('\nPHASE 1: Initial verification');
    final verificationResults = await verifyEventSpaceAssignments();

    // Then fix any issues
    debugPrint('\nPHASE 2: Fixing unassigned events');
    final fixResults = await fixUnassignedEvents();

    // Finally verify again to get the final state
    debugPrint('\nPHASE 3: Final verification');
    final finalVerificationResults =
        await SpaceService.verifyEventSpaceAssignments();

    // Calculate improvement metrics with null safety
    final int initialUnassigned =
        verificationResults.containsKey('unassignedEvents') &&
                verificationResults['unassignedEvents'] != null
            ? (verificationResults['unassignedEvents'] as List).length
            : 0;
    final int finalUnassigned =
        finalVerificationResults.containsKey('unassignedEvents') &&
                finalVerificationResults['unassignedEvents'] != null
            ? (finalVerificationResults['unassignedEvents'] as List).length
            : 0;
    final int eventsFixed = initialUnassigned - finalUnassigned;
    final double percentImprovement =
        initialUnassigned > 0 ? (eventsFixed / initialUnassigned * 100) : 0.0;

    debugPrint('\n==== IMPROVEMENT SUMMARY ====');
    debugPrint('Events without spaces before: $initialUnassigned');
    debugPrint('Events without spaces after: $finalUnassigned');
    debugPrint('Events fixed: $eventsFixed');
    debugPrint('Improvement: ${percentImprovement.toStringAsFixed(1)}%');

    if (finalUnassigned > 0) {
      debugPrint(
          '\nThere are still $finalUnassigned events not assigned to spaces.');
      debugPrint('Most of these likely have missing organizer names.');

      final eventsWithMissingNames = finalVerificationResults
                  .containsKey('eventsWithMissingOrganizerName') &&
              finalVerificationResults['eventsWithMissingOrganizerName'] != null
          ? (finalVerificationResults['eventsWithMissingOrganizerName'] as List)
              .length
          : 0;
      debugPrint(
          'Events with missing organizer names: $eventsWithMissingNames');

      if (eventsWithMissingNames > 0) {
        debugPrint(
            'To fix these, add organizer names to the events and run this process again.');
      }
    } else {
      debugPrint('\nAll events are now assigned to spaces!');
    }

    return {
      'initialState': verificationResults,
      'fixResults': fixResults,
      'finalState': finalVerificationResults,
      'improvement': {
        'initialUnassigned': initialUnassigned,
        'finalUnassigned': finalUnassigned,
        'eventsFixed': eventsFixed,
        'percentImprovement': percentImprovement
      }
    };
  }
}
