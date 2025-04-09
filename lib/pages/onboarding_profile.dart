import 'package:flutter/material.dart'
    hide RefreshIndicator, RefreshIndicatorState;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_theme.dart';
import 'package:hive_ui/providers/profile_provider.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/services/club_service.dart';
// Add optimized club adapter
// Add service initializer
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
import 'package:hive_ui/models/club.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/widgets/search_select.dart';
import 'package:hive_ui/widgets/dropdown_select.dart';
import 'package:hive_ui/constants/interest_options.dart';
import 'package:hive_ui/constants/major_options.dart';
import 'package:hive_ui/constants/year_options.dart';
import 'package:hive_ui/constants/residence_options.dart';
import 'dart:math' show pi;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:hive_ui/core/navigation/app_bar_builder.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class OnboardingProfilePage extends ConsumerStatefulWidget {
  final bool skipToDefaults;
  
  const OnboardingProfilePage({
    super.key, 
    this.skipToDefaults = false,
  });

  @override
  ConsumerState<OnboardingProfilePage> createState() =>
      _OnboardingProfilePageState();
}

class _OnboardingProfilePageState extends ConsumerState<OnboardingProfilePage>
    with TickerProviderStateMixin {
  // Keep Firebase auth and firestore instances at class level
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers
  late final PageController
      _pageController; // Use late final so it can be initialized in initState
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _interestsScrollController = ScrollController();

  // Focus node for search
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;

  // Current page tracking
  int _currentPage = 0;
  bool _canGoBack = true;

  // Answers to sequential questions
  String? _selectedYear;
  String? _selectedMajor;
  String? _selectedResidence;
  AccountTier _selectedTier =
      AccountTier.verified; // Default to verified for UB students
  String? _selectedClub;
  String? _selectedClubRole;
  final List<String> _selectedInterests = [];

  // Filter states for search
  String _yearSearchQuery = '';
  String _fieldSearchQuery = '';
  String _residenceSearchQuery = '';
  String _clubSearchQuery = '';
  String _searchQuery = ''; // For interest search

  // Filtered lists based on search queries
  List<String> _filteredYears = [];
  List<String> _filteredFields = [];
  List<String> _filteredResidences = [];
  List<Club> _filteredClubs = [];
  List<Club> _clubs = [];
  bool _isLoadingClubs = false;

  // Which interest category is expanded
  String? _expandedCategory;
  String? _expandedInterest;
  AccountTier? _expandedTier;

  // Status flags
  bool _isCompletingOnboarding = false;
  final int _minInterests = 5; // Minimum required interests
  final int _maxInterests = 10; // Maximum allowed interests

  // Flat list of interests without categories or emojis
  final List<String> _interestOptions = InterestOptions.options;

  // For categorized interests view
  final Map<String, List<Map<String, dynamic>>> interestCategories = {};

  // Lists for dropdowns
  final List<String> _years = YearOptions.options;
  final List<String> _fields = MajorOptions.options;
  final List<String> _residences = ResidenceOptions.options;

  // Mock user email (can be updated)
  String _userEmail =
      ''; // Will be loaded from UserPreferencesService in initState

  // Method to update email for testing
  void _updateUserEmail(String email) async {
    // Store the email locally in state
    setState(() {
      _userEmail = email;
      // If changing to non-edu email and user has verified/verified+ selected, force to public
      if (!email.toLowerCase().endsWith('.edu') &&
          (_selectedTier == AccountTier.verified ||
              _selectedTier == AccountTier.verifiedPlus)) {
        _selectedTier = AccountTier.public;
      }
    });

    try {
      // Save to UserPreferencesService for persistence across sessions
      await UserPreferencesService.saveUserEmail(email);

      // Get the current Firebase user
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;
      final currentUser = auth.currentUser;

      if (currentUser != null) {
        // Update the email in Firebase Auth if user is signed in
        // Note: This will only update the email for verification purposes
        // It won't automatically update the user's primary sign-in email

        // Update the user's profile in Firestore
        await firestore.collection('users').doc(currentUser.uid).update({
          'educationalEmail': email,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('Updated user educational email in Firestore: $email');
      } else {
        // Store email locally only if user isn't authenticated yet
        debugPrint('User not signed in. Email saved locally only: $email');
      }
    } catch (e) {
      debugPrint('Error updating user email: $e');
      // Don't show error to user as this is handled silently in the background
    }
  }

  // Add this to the class variables section
  late final Map<String, AnimationController> _yearDescriptionControllers = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _expandedCategory =
        interestCategories.isNotEmpty ? interestCategories.keys.first : null;

    // Initialize animation controllers for year descriptions
    final List<Map<String, dynamic>> yearOptions = [
      {
        'year': 'Freshman',
        'description':
            'First year of college. Life is good, parties are better.',
      },
      {
        'year': 'Sophomore',
        'description': 'Still figuring it out, but with more confidence.',
      },
      {
        'year': 'Junior',
        'description': 'Internships, leadership roles, and the halfway mark.',
      },
      {
        'year': 'Senior',
        'description':
            'Job market about to cook us y\'all. AI gods, HAVE MERCY PLEASE!',
      },
      {
        'year': 'Masters',
        'description': 'I didn\'t forget you this time.',
      },
      {
        'year': 'PhD',
        'description':
            'Please sign up for HIVE team at the Hive website at thehiveuni.com.',
      },
      {
        'year': 'Non-Degree Seeking',
        'description': 'I wish I had a better description for you.',
      },
    ];

    // Create an animation controller for each year option
    for (final option in yearOptions) {
      final String year = option['year'] as String;
      _yearDescriptionControllers[year] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );
    }

    // Initialize variables from preferences
    _loadUserEmailFromPreferences();
    
    // Check if we should auto-skip with defaults
    if (widget.skipToDefaults) {
      // We'll schedule this to happen after the first frame renders
      // to ensure everything is properly initialized
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          debugPrint('Skipping to defaults as requested by route parameter');
          // This will be called after the first frame is rendered
          _autoSkipWithDefaults();
        }
      });
    }

    // Initialize filtered lists
    _filteredYears = List.from(_years);
    _filteredFields = List.from(_fields);
    _filteredResidences = List.from(_residences);
    _filteredClubs = [];

    // Fetch clubs if needed for Verified+ accounts
    _fetchClubs();

    // Listen for page changes to update UI
    _pageController.addListener(() {
      if (_pageController.hasClients) {
        setState(() {
          _currentPage = _pageController.page?.round() ?? 0;
          // Allow back navigation only if not on the first page
          _canGoBack = _currentPage > 0;
        });
      }
    });

    // Apply initial field filtering if a year is already selected
    if (_selectedYear != null) {
      _filterFields('');
    }

    // Verify auth state
    _verifyAuthState();
  }

  // Auto-skip helper method
  void _autoSkipWithDefaults() {
    // Set default values for all required fields
    setState(() {
      // Default year
      _selectedYear = _years.first;
      
      // Default major
      _selectedMajor = 'Computer Science';
      
      // Default residence
      _selectedResidence = _residences.first;
      
      // Default tier - use verified if they have a .edu email
      final userEmail = _firebaseAuth.currentUser?.email ?? '';
      _selectedTier = userEmail.toLowerCase().endsWith('.edu') 
          ? AccountTier.verified 
          : AccountTier.public;
      
      // Default interests
      _selectedInterests.clear();
      _selectedInterests.addAll([
        'Campus Events',
        'Student Life',
        'Networking',
        'Career Development',
        'Social Activities',
        'Technology'
      ]);
    });
    
    // Complete onboarding with defaults
    _completeOnboarding();
  }

  /// Complete onboarding with current values and navigate to home
  Future<void> _completeOnboarding() async {
    try {
      setState(() {
        _isCompletingOnboarding = true;
      });
      
      // Get current user ID
      final userId = _firebaseAuth.currentUser?.uid;
      if (userId == null) {
        debugPrint('Cannot complete onboarding: No user ID available');
        return;
      }
      
      // Create user profile data
      final profile = UserProfile(
        id: userId,
        username: '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        displayName: '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        year: _selectedYear ?? 'Freshman',
        major: _selectedMajor ?? 'Undecided',
        residence: _selectedResidence ?? 'Off Campus',
        eventCount: 0,
        spaceCount: 0,
        friendCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        accountTier: _selectedTier,
        interests: _selectedInterests,
      );
      
      // Save to Firestore
      await _firestore.collection('users').doc(userId).set(profile.toJson());
      
      // Save to local preferences 
      await UserPreferencesService.storeProfile(profile);
      
      // Mark onboarding as completed
      await UserPreferencesService.setOnboardingCompleted(true);
      
      if (mounted) {
        // Navigate to home
        context.go('/home');
      }
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
      // Show error if needed
    } finally {
      if (mounted) {
        setState(() {
          _isCompletingOnboarding = false;
        });
      }
    }
  }

  /// Load user email from preferences
  Future<void> _loadUserEmailFromPreferences() async {
    final email = UserPreferencesService.getUserEmail();
    if (email.isNotEmpty && mounted) {
      setState(() {
        _userEmail = email;
      });
    }
  }

  // Check if the user's email is verified in Firebase Auth
  Future<void> _checkEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        // Reload user to get latest verification status
        await user.reload();

        if (user.emailVerified) {
          // Email is verified, update tier
          if (_userEmail.toLowerCase().endsWith('.edu')) {
            setState(() {
              _selectedTier = AccountTier.verified;
            });
          }
        } else {
          // Not verified, prompt user to verify
          debugPrint('Educational email is not verified: ${user.email}');
        }
      }
    } catch (e) {
      debugPrint('Error checking email verification: $e');
    }
  }

  // Send verification email to user
  Future<void> _sendVerificationEmail() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.sendEmailVerification();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Verification email sent to ${user.email}',
                style: GoogleFonts.inter(
                  color: AppColors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error sending verification email: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error sending verification email: ${e.toString()}',
              style: GoogleFonts.inter(
                color: AppColors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Update the _verifyAuthState method to handle auth more robustly
  Future<void> _verifyAuthState() async {
    final currentUser = _firebaseAuth.currentUser;

    if (currentUser != null) {
      debugPrint('Firebase user available for onboarding: ${currentUser.uid}');

      // Store the user ID in preferences for persistence
      await UserPreferencesService.setUserId(currentUser.uid);

      // Make sure we have the email stored
      if (_userEmail.isEmpty && currentUser.email != null) {
        setState(() {
          _userEmail = currentUser.email!;
        });
        await UserPreferencesService.saveUserEmail(_userEmail);
      }
    } else {
      debugPrint('WARNING: No Firebase user found in onboarding');

      // If we're supposed to be logged in but no user is found, let's try to recover
      try {
        // First check if we can get a user from shared preferences
        final userId = await UserPreferencesService.getUserId();
        if (userId != null && userId.isNotEmpty) {
          debugPrint(
              'Found user ID in preferences: $userId. Using this for onboarding.');
        } else {
          // No user ID in preferences, this is a serious auth issue
          debugPrint(
              'No user ID found in preferences. Authentication state is invalid.');

          if (mounted) {
            // Show an error message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Authentication error. Please sign in again.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );

            // Navigate back to sign in using GoRouter
            if (context.mounted) {
              context.go('/sign-in');
              return;
            }
          }
        }
      } catch (e) {
        debugPrint('Error during auth state recovery: $e');

        // Navigate back to sign in on error
        if (mounted && context.mounted) {
          context.go('/sign-in');
          return;
        }
      }
    }
  }

  // Getter to flatten interests for easier access
  List<Map<String, dynamic>> get availableInterests {
    final List<Map<String, dynamic>> allInterests = [];
    for (final category in interestCategories.values) {
      allInterests.addAll(category);
    }
    return allInterests;
  }

  // Predefined club roles
  final List<String> clubRoles = [
    'President',
    'Vice President',
    'Treasurer',
    'Secretary',
    'Member (Non-officer)',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _interestsScrollController.dispose();
    // Dispose of search controller and focus node
    _searchController.dispose();
    _searchFocusNode.dispose();

    // Dispose all year description animation controllers
    for (final controller in _yearDescriptionControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<bool> _showExitConfirmationDialog() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.black,
        title: Text(
          'Exit Onboarding',
          style: AppTheme.displaySmall,
        ),
        content: Text(
          'Your progress will be lost. Are you sure you want to exit?',
          style: AppTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.error),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.black,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    return shouldExit ?? false;
  }

  // ignore: unused_element
  Future<void> _tryExitOnboarding() async {
    final shouldExit = await _showExitConfirmationDialog();
    if (shouldExit && mounted) {
      context.go('/');
    }
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        // Only add if we haven't reached the max
        if (_selectedInterests.length < _maxInterests) {
          _selectedInterests.add(interest);

          // Removed hidden interest reveal logic
        } else {
          // Show a custom dialog instead of a snackbar
          _showTooManyInterestsDialog();
        }
      }
    });
  }

  // Add this new method for the custom dialog
  void _showTooManyInterestsDialog() {
    // Add haptic feedback for emphasis
    HapticFeedback.heavyImpact();

    // Create an animation controller for custom shake effect
    final AnimationController controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Create a shake animation that oscillates
    final Animation<double> shakeAnimation = Tween<double>(
      begin: -0.05,
      end: 0.05,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.elasticIn,
    ));

    // Auto-reverse and repeat the animation
    controller.repeat(reverse: true);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.black,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppColors.gold.withOpacity(0.3), width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning icon with simple animation
                AnimatedBuilder(
                  animation: controller,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: shakeAnimation.value * pi / 10,
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.gold,
                        size: 48,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Hive logo
                Image.asset(
                  'assets/images/hivelogo.png',
                  width: 100,
                  height: 100,
                ),

                const SizedBox(height: 16),

                // Humorous message
                Text(
                  "Slow your roll sir/ma'am, how much money do you think that we have in storage??",
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 24),

                // Additional information about the limit
                Text(
                  "You can only select up to $_maxInterests interests.",
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 24),

                // OK button
                GestureDetector(
                  onTap: () {
                    // Dispose the controller when dialog is closed
                    controller.dispose();
                    Navigator.of(dialogContext).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 24),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppColors.gold),
                    ),
                    child: Text(
                      "I'll remove some",
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Update _completeOnboarding to handle auth issues properly
  Future<void> _completeOnboardingAndNavigate() async {
    if (_isCompletingOnboarding) return;

    setState(() {
      _isCompletingOnboarding = true;
    });

    try {
      // Get the current user
      final firebaseAuth = FirebaseAuth.instance;
      final currentUser = firebaseAuth.currentUser;

      if (currentUser == null) {
        setState(() {
          _isCompletingOnboarding = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No authenticated user found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Get the user's values from text controllers and selections
      final String firstName = _firstNameController.text.trim();
      final String lastName = _lastNameController.text.trim();
      final String userEmail = _userEmail.toLowerCase();
      
      debugPrint('Creating user profile for ${currentUser.email}');

      final String username = '${firstName.toLowerCase()}${lastName.toLowerCase()}';
      final bool hasBuffaloEmail = currentUser.email != null &&
          currentUser.email!.toLowerCase().endsWith('buffalo.edu');

      // Create the user profile structure for Firestore
      final Map<String, dynamic> profileData = {
        'id': currentUser.uid,
        'userId': currentUser.uid,
        'username': username, // Use the combined first and last name
        'displayName': '$firstName $lastName', // Also set displayName for compatibility
        'firstName': firstName,
        'lastName': lastName,
        'email': currentUser.email,
        'photoURL': currentUser.photoURL ?? '',
        'educationalEmail': userEmail,
        'eduEmailVerified': hasBuffaloEmail, // Auto-verify Buffalo emails
        'year': _selectedYear,
        'major': _selectedMajor, // Direct mapping to major field
        'residence': _selectedResidence,
        'interests': _selectedInterests, // Save as a list instead of a string
        'accountTier': _selectedTier.name,
        'onboardingCompleted': true,
        'eventCount': 0,
        'spaceCount': 0,
        'friendCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add club leadership info only if Verified+ and Buffalo email
      if (_selectedTier == AccountTier.verifiedPlus &&
          hasBuffaloEmail &&
          _selectedClub != null &&
          _selectedClubRole != null) {
        profileData['clubId'] = _selectedClub;
        profileData['clubRole'] = _selectedClubRole;
        profileData['isClubLeader'] = true;
      } else {
        // Ensure these fields are not set if user isn't a club leader
        profileData['isClubLeader'] = false;
      }

      // Update or create the user document in Firestore
      await _firestore.collection('users').doc(currentUser.uid).set(
            profileData,
            SetOptions(merge: true),
          );

      // Save the completion status to local preferences
      await UserPreferencesService.setOnboardingCompleted(true);

      // Save the user ID to preferences for persistence
      await UserPreferencesService.setUserId(currentUser.uid);

      // Create a UserProfile object from the profile data
      final userProfile = UserProfile.fromJson(profileData);
      
      // Cache the profile locally to ensure it's available immediately
      await UserPreferencesService.storeProfile(userProfile);
      
      // Call refreshProfile with a retry mechanism
      int retries = 0;
      bool refreshSuccess = false;
      while (!refreshSuccess && retries < 3) {
        try {
          if (ref.exists(profileProvider)) {
            debugPrint('Refreshing profile provider after onboarding completion (attempt ${retries + 1})');
            await ref.read(profileProvider.notifier).refreshProfile();
            refreshSuccess = true;
            debugPrint('Profile refresh successful');
          } else {
            debugPrint('Profile provider not available, skipping refresh');
            break;
          }
        } catch (e) {
          debugPrint('Error refreshing profile (attempt ${retries + 1}): $e');
          retries++;
          if (retries < 3) {
            await Future.delayed(Duration(milliseconds: 500 * retries));
          }
        }
      }

      if (mounted) {
        // Reset loading state
        setState(() {
          _isCompletingOnboarding = false;
        });

        // Provide haptic feedback before navigation
        HapticFeedback.mediumImpact();

        // Navigate to the home screen using GoRouter
        if (context.mounted) {
          // Use context.go with extra parameter to indicate coming from onboarding
          context.go('/home', extra: {'fromOnboarding': true});
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCompletingOnboarding = false;
        });

        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing onboarding: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Log the error
      debugPrint('Error completing onboarding: $e');
    }
  }

  Future<bool> _onWillPop() async {
    // If on the first page, show exit dialog
    if (_pageController.page == 0) {
      return await _showExitConfirmationDialog();
    } else {
      // Go to previous page
      _previousPage();
      return false;
    }
  }

  // ignore: unused_element
  void _filterClubs(String query) {
    setState(() {
      _clubSearchQuery = query;
      if (query.isEmpty) {
        _filteredClubs = _clubs;
      } else {
        // Use more sophisticated search algorithm
        final searchTerms = query
            .toLowerCase()
            .split(' ')
            .where((term) => term.isNotEmpty)
            .toList();

        _filteredClubs = _clubs.where((club) {
          // Calculate relevance score based on different match types
          int relevanceScore = 0;
          final clubName = club.name.toLowerCase();
          final clubDescription = club.description.toLowerCase();
          final clubTags = club.tags.join(' ').toLowerCase();

          // Check each search term
          for (final term in searchTerms) {
            // Exact club name match (highest relevance)
            if (clubName == term) {
              relevanceScore += 100;
              continue;
            }

            // Club name starts with term (high relevance)
            if (clubName.startsWith(term)) {
              relevanceScore += 50;
              continue;
            }

            // Club name contains the term (medium relevance)
            if (clubName.contains(term)) {
              relevanceScore += 25;
              continue;
            }

            // Description or tags contain the term (lower relevance)
            if (clubDescription.contains(term) || clubTags.contains(term)) {
              relevanceScore += 10;
              continue;
            }
          }

          // Return true if the club has any relevance
          return relevanceScore > 0;
        }).toList();

        // Sort by relevance score (simple implementation)
        _filteredClubs.sort((a, b) {
          // First sort by exact name match
          if (a.name.toLowerCase() == query.toLowerCase()) return -1;
          if (b.name.toLowerCase() == query.toLowerCase()) return 1;

          // Then sort by name contains
          final aContains = a.name.toLowerCase().contains(query.toLowerCase());
          final bContains = b.name.toLowerCase().contains(query.toLowerCase());
          if (aContains && !bContains) return -1;
          if (!aContains && bContains) return 1;

          // Finally sort alphabetically
          return a.name.compareTo(b.name);
        });
      }
    });
  }

  // ignore: unused_element
  void _filterYears(String query) {
    setState(() {
      _yearSearchQuery = query;
      if (query.isEmpty) {
        _filteredYears = List.from(_years);
      } else {
        _filteredYears = _years
            .where((year) => year.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // Get education level from selected year
  String _getEducationLevel(String? year) {
    if (year == null) return 'all';

    if (['Freshman', 'Sophomore', 'Junior', 'Senior'].contains(year)) {
      return 'undergraduate';
    } else if (year == 'Masters') {
      return 'masters';
    } else if (year == 'PhD') {
      return 'phd';
    } else if (year == 'Non-Degree Seeking') {
      return 'non-degree';
    } else {
      return 'all'; // For any other case
    }
  }

  // Filter fields based on search query and selected education level
  void _filterFields(String query) {
    setState(() {
      _fieldSearchQuery = query;

      // First filter: get fields based on education level
      List<String> levelFilteredFields = [];
      String educationLevel = _getEducationLevel(_selectedYear);

      if (educationLevel == 'all') {
        // Show all fields for students who don't fit a category
        levelFilteredFields = List.from(_fields);
      } else if (educationLevel == 'non-degree') {
        // Non-degree seeking students should pass this screen entirely
        // This page will be skipped, but we need this for safety
        levelFilteredFields = [];
      } else if (educationLevel == 'undergraduate') {
        // Strict filter for undergraduate programs - ONLY bachelor's degrees
        levelFilteredFields = _fields.where((field) {
          // Check for typical undergraduate degree indicators
          final lowerField = field.toLowerCase();

          // First check for positive matches (any of these indicate undergraduate)
          bool isUndergrad = field.endsWith(' BA') ||
              field.endsWith(' BS') ||
              field.endsWith(' BFA') ||
              field.endsWith(' BMus') ||
              field.endsWith(' B.A.') ||
              field.endsWith(' B.S.') ||
              field.endsWith(' B.F.A.') ||
              field.endsWith(' B.Mus.') ||
              lowerField.contains('bachelor') ||
              lowerField.contains('undergraduate');

          // Then exclude any fields that contain masters or doctoral indicators
          bool containsHigherDegree = lowerField.contains('master') ||
              lowerField.contains(' ma ') ||
              lowerField.contains(' m.a.') ||
              lowerField.contains(' ms ') ||
              lowerField.contains(' m.s.') ||
              lowerField.contains('mba') ||
              lowerField.contains('m.b.a.') ||
              lowerField.contains('mfa') ||
              lowerField.contains('m.f.a.') ||
              lowerField.contains('phd') ||
              lowerField.contains('ph.d.') ||
              lowerField.contains('doctor') ||
              lowerField.contains('doctoral');

          return isUndergrad && !containsHigherDegree;
        }).toList();
      } else if (educationLevel == 'masters') {
        // Strict filter for masters programs - ONLY master's degrees
        levelFilteredFields = _fields.where((field) {
          final lowerField = field.toLowerCase();

          // First check for positive matches (any of these indicate masters)
          bool isMasters = field.endsWith(' MA') ||
              field.endsWith(' MS') ||
              field.endsWith(' MBA') ||
              field.endsWith(' MFA') ||
              field.endsWith(' MPH') ||
              field.endsWith(' MM') ||
              field.endsWith(' MPS') ||
              field.endsWith(' MEd') ||
              field.endsWith(' MArch') ||
              field.endsWith(' ME') ||
              field.endsWith(' MUP') ||
              field.endsWith(' MSW') ||
              field.endsWith(' M.A.') ||
              field.endsWith(' M.S.') ||
              field.endsWith(' M.B.A.') ||
              field.endsWith(' M.F.A.') ||
              field.endsWith(' M.P.H.') ||
              field.endsWith(' M.M.') ||
              field.endsWith(' M.P.S.') ||
              field.endsWith(' M.Ed.') ||
              field.endsWith(' M.Arch.') ||
              field.endsWith(' M.E.') ||
              field.endsWith(' M.U.P.') ||
              field.endsWith(' M.S.W.') ||
              lowerField.contains('master') ||
              lowerField.contains('advanced certificate');

          // Then exclude any fields that contain bachelor's or doctoral indicators
          bool containsOtherDegree = lowerField.contains('bachelor') ||
              lowerField.contains('undergraduate') ||
              lowerField.contains(' bs ') ||
              lowerField.contains(' b.s.') ||
              lowerField.contains(' ba ') ||
              lowerField.contains(' b.a.') ||
              lowerField.contains('phd') ||
              lowerField.contains('ph.d.') ||
              lowerField.contains('doctor') ||
              lowerField.contains('doctoral');

          // Include professional doctorates typically categorized with Masters
          bool isProfessionalDoctorate = field.endsWith(' DNP') ||
              field.endsWith(' D.N.P.') ||
              field.endsWith(' LLM') ||
              field.endsWith(' L.L.M.');

          // Return true for masters programs that don't contain bachelor's or doctoral indicators
          // except for specifically included professional doctorates
          return (isMasters && !containsOtherDegree) || isProfessionalDoctorate;
        }).toList();
      } else if (educationLevel == 'phd') {
        // Strict filter for PhD and other doctoral programs - ONLY doctoral degrees
        levelFilteredFields = _fields.where((field) {
          final lowerField = field.toLowerCase();

          // Check for doctoral degrees
          bool isPhD = field.endsWith(' PhD') ||
              field.endsWith(' Ph.D.') ||
              field.endsWith(' EdD') ||
              field.endsWith(' Ed.D.') ||
              field.endsWith(' MD') ||
              field.endsWith(' M.D.') ||
              field.endsWith(' JD') ||
              field.endsWith(' J.D.') ||
              field.endsWith(' DDS') ||
              field.endsWith(' D.D.S.') ||
              field.endsWith(' DVM') ||
              field.endsWith(' D.V.M.') ||
              field.endsWith(' PharmD') ||
              field.endsWith(' Pharm.D.') ||
              lowerField.contains('doctor') ||
              lowerField.contains('doctoral');

          // Exclude other degree types
          bool containsOtherDegree = lowerField.contains('bachelor') ||
              lowerField.contains('undergraduate') ||
              (lowerField.contains('master') &&
                  !lowerField.contains('doctor')) ||
              (lowerField.contains(' bs ') && !lowerField.contains('phd')) ||
              (lowerField.contains(' ba ') && !lowerField.contains('phd')) ||
              (lowerField.contains(' ma ') && !lowerField.contains('phd')) ||
              (lowerField.contains(' ms ') && !lowerField.contains('phd'));

          return isPhD && !containsOtherDegree;
        }).toList();
      }

      // Sort the filtered fields alphabetically for easier scanning
      levelFilteredFields.sort();

      // Second filter: based on search query
      if (query.isEmpty) {
        _filteredFields = levelFilteredFields;
      } else {
        // Split the query into separate terms for more flexible searching
        final searchTerms = query
            .toLowerCase()
            .split(' ')
            .where((term) => term.isNotEmpty)
            .toList();

        _filteredFields = levelFilteredFields.where((field) {
          final lowerField = field.toLowerCase();

          // Check if field contains all search terms in any order
          return searchTerms.every((term) => lowerField.contains(term));
        }).toList();
      }
    });
  }

  // ignore: unused_element
  void _filterResidences(String query) {
    setState(() {
      _residenceSearchQuery = query;
      if (query.isEmpty) {
        _filteredResidences = List.from(_residences);
      } else {
        _filteredResidences = _residences
            .where((residence) =>
                residence.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // ignore: unused_element
  void _clearYearSelection() {
    setState(() {
      _selectedYear = null;
      _yearSearchQuery = '';
      _filteredYears = List.from(_years);
      // Refresh fields when year is cleared
      _fieldSearchQuery = '';
      _filteredFields = List.from(_fields);
    });
  }

  // ignore: unused_element
  void _clearFieldSelection() {
    setState(() {
      _selectedMajor = null;
      _fieldSearchQuery = '';
      // Apply education level filter
      _filterFields('');
    });
  }

  // ignore: unused_element
  void _clearResidenceSelection() {
    setState(() {
      _selectedResidence = null;
      _residenceSearchQuery = '';
      _filteredResidences = List.from(_residences);
    });
  }

  void _nextPage() {
    debugPrint('_nextPage called - navigating to next onboarding page');

    // Add stronger haptic feedback for better physical confirmation
    HapticFeedback.mediumImpact();

    // Special case for non-degree seeking students to skip field selection
    if (_pageController.page?.round() == 1 &&
        _selectedYear == 'Non-Degree Seeking') {
      debugPrint('Skipping field selection for Non-Degree Seeking student');
      // Skip the field of study page and go directly to residence
      _pageController.animateToPage(
        3, // Index of residence page
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
      return;
    }

    // Get current page and determine target page
    int currentPage = _pageController.page?.round() ?? 0;
    int targetPage = currentPage + 1;

    debugPrint('Navigating from page $currentPage to page $targetPage');

    // Normal page navigation
    _pageController.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  void _previousPage() {
    // Close any open dialogs or bottom sheets first
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    HapticFeedback.lightImpact();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentPage == 0) {
          final shouldExit = await _showExitConfirmationDialog();
          if (shouldExit) {
            // Properly abandon onboarding
            await _abandonOnboarding();
            return false; // Navigation is handled by _abandonOnboarding
          }
          return false;
        }
        // Allow the system back button to navigate to previous onboarding pages
        if (_currentPage > 0) {
          _pageController.previousPage(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.black,
        appBar: AppBarBuilder.buildOnboardingAppBar(
          context,
          showBackButton: _canGoBack,
          onBackPressed: _handleBackPress,
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildNamePage(),
            _buildYearPage(),
            _buildFieldPage(),
            _buildResidencePage(),
            _buildInterestsPage(),
            _buildAccountTierPage(),
          ],
        ),
      ),
    );
  }

  Widget _buildNamePage() {
    // Get the current page from the controller (this is the first page)
    final currentPage =
        _pageController.hasClients ? (_pageController.page ?? 0).round() : 0;
    const totalPages = 6;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          24, 32, 24, 24), // Reduced top padding from 64 to 32
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What\'s your name?',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Let\'s get to know you',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),

          // Use a constrained layout to prevent fields from growing too large
          // and to ensure consistent appearance across device sizes
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // First Name Field - with overflow protection
                TextField(
                  controller: _firstNameController,
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    labelStyle: GoogleFonts.inter(color: Colors.white70),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.gold),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  cursorColor: AppColors.gold,
                  textInputAction: TextInputAction.next,
                  maxLength: 30, // Prevent excessively long names
                  buildCounter: (context,
                      {required currentLength, required isFocused, maxLength}) {
                    return null; // Hide the counter
                  },
                ),
                const SizedBox(height: 16),

                // Last Name Field - with overflow protection
                TextField(
                  controller: _lastNameController,
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    labelStyle: GoogleFonts.inter(color: Colors.white70),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.gold),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  cursorColor: AppColors.gold,
                  textInputAction: TextInputAction.done,
                  maxLength: 30, // Prevent excessively long names
                  buildCounter: (context,
                      {required currentLength, required isFocused, maxLength}) {
                    return null; // Hide the counter
                  },
                  onSubmitted: (_) {
                    // Auto-advance when user hits done on keyboard
                    if (_isNameValid()) {
                      _nextPage();
                    }
                  },
                ),
              ],
            ),
          ),

          // Push content to bottom using an Expanded widget
          const Expanded(child: SizedBox()),

          // Progress indicator above the continue button
          _buildProgressIndicator(6, currentPage),
          const SizedBox(height: 16),
          _buildContinueButton(
            onPressed: _isNameValid() ? _nextPage : null,
          ),
          const SizedBox(
              height: 40), // Extra space for keyboard and bottom safe area
        ],
      ),
    );
  }

  Widget _buildYearPage() {
    // Get the current page from the controller
    final currentPage =
        _pageController.hasClients ? (_pageController.page ?? 0).round() : 0;

    final List<Map<String, dynamic>> yearOptions = [
      {
        'year': 'Freshman',
        'description':
            'First year of college. Life is good, parties are better.',
      },
      {
        'year': 'Sophomore',
        'description': 'Still figuring it out, but with more confidence.',
      },
      {
        'year': 'Junior',
        'description': 'Internships, leadership roles, and the halfway mark.',
      },
      {
        'year': 'Senior',
        'description':
            'Job market about to cook us y\'all. AI gods, HAVE MERCY PLEASE!',
      },
      {
        'year': 'Masters',
        'description': 'I didn\'t forget you this time.',
      },
      {
        'year': 'PhD',
        'description':
            'Please sign up for HIVE team at the Hive website at thehiveuni.com.',
      },
      {
        'year': 'Non-Degree Seeking',
        'description': 'I wish I had a better description for you.',
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          24, 32, 24, 24), // Reduced top padding from 64 to 32
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What year are you in?',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll connect you with events and groups relevant to your year.',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),

          // Direct selection of years with descriptions
          Expanded(
            child: ListView.builder(
              physics: const ClampingScrollPhysics(),
              itemCount: yearOptions.length,
              itemBuilder: (context, index) {
                final option = yearOptions[index];
                final String year = option['year'] as String;
                final bool isSelected = _selectedYear == year;

                // Control the animation based on selection state
                if (isSelected) {
                  _yearDescriptionControllers[year]?.forward();
                } else {
                  _yearDescriptionControllers[year]?.reverse();
                }

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedYear = year;

                      // Filter fields based on the selected year
                      _filterFields('');

                      // No auto-navigation - only use continue button
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.gold.withOpacity(0.1)
                          : const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.gold : Colors.white24,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            // Selection indicator
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? AppColors.gold
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.gold
                                      : Colors.white54,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Center(
                                      child: Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.black,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            // Year text
                            Expanded(
                              child: Text(
                                year,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.gold
                                      : Colors.white,
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Description text with proper transitions
                        ClipRect(
                          child: AnimatedBuilder(
                            animation: _yearDescriptionControllers[year] ??
                                AnimationController(
                                    vsync: this, duration: Duration.zero),
                            builder: (context, child) {
                              final Animation<double> sizeAnimation =
                                  _yearDescriptionControllers[year]?.drive(
                                          CurveTween(
                                              curve: Curves.easeInOut)) ??
                                      const AlwaysStoppedAnimation(0.0);

                              return SizeTransition(
                                sizeFactor: sizeAnimation,
                                axisAlignment: -1.0,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 40, top: 8, right: 8, bottom: 4),
                                  child: FadeTransition(
                                    opacity: sizeAnimation,
                                    child: Text(
                                      option['description'] ?? '',
                                      style: GoogleFonts.inter(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        height: 1.3,
                                      ),
                                      overflow: TextOverflow.visible,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Progress indicator above the continue button
          _buildProgressIndicator(6, currentPage),
          const SizedBox(height: 16),
          _buildContinueButton(
            onPressed: _selectedYear != null ? _nextPage : null,
          ),
        ],
      ),
    );
  }

  Widget _buildFieldPage() {
    // Get the current page from the controller
    final currentPage =
        _pageController.hasClients ? (_pageController.page ?? 0).round() : 0;
    const totalPages = 6;

    // Define the container background color once for consistency
    const containerBgColor = Color(0xFF1E1E1E);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          24, 32, 24, 24), // Reduced top padding from 64 to 32
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What are you studying?',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us suggest relevant events and groups.',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),

          // Search field for filtering
          Container(
            decoration: BoxDecoration(
              color: containerBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                fillColor: containerBgColor, // Match container background color
                filled: true, // Enable background fill
                border: InputBorder.none,
                hintText: 'Search fields...',
                hintStyle: TextStyle(color: Colors.white54),
                icon: Icon(Icons.search, color: Colors.white54),
                // Remove visible underline
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
              ),
              onChanged: _filterFields,
            ),
          ),
          const SizedBox(height: 16),

          // List of fields
          Expanded(
            child: ListView.builder(
              physics: const ClampingScrollPhysics(),
              itemCount: _filteredFields.length,
              itemBuilder: (context, index) {
                final field = _filteredFields[index];
                final bool isSelected = _selectedMajor == field;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedMajor = field;
                      _fieldSearchQuery = ''; // Clear search after selection
                      _filteredFields = []; // Clear filtered list
                      _searchFocusNode.unfocus(); // Dismiss keyboard
                    });
                    _nextPage();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.gold.withOpacity(0.1)
                          : const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.gold : Colors.white24,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Selection indicator
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppColors.gold
                                : Colors.transparent,
                            border: Border.all(
                              color:
                                  isSelected ? AppColors.gold : Colors.white54,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Center(
                                  child: Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.black,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        // Field name
                        Expanded(
                          child: Text(
                            field,
                            style: TextStyle(
                              color: isSelected ? AppColors.gold : Colors.white,
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Progress indicator and continue button
          _buildProgressIndicator(6, currentPage),
          const SizedBox(height: 16),
          _buildContinueButton(
            onPressed: _selectedMajor != null ? _nextPage : null,
          ),
        ],
      ),
    );
  }

  Widget _buildResidencePage() {
    // Get the current page from the controller
    final currentPage =
        _pageController.hasClients ? (_pageController.page ?? 0).round() : 0;
    const totalPages = 6;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          24, 32, 24, 24), // Reduced top padding from 64 to 32
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Where do you live?',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll connect you with events and groups relevant to your location.',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),

          // Direct selection of residences with descriptions
          Expanded(
            child: ListView.builder(
              physics: const ClampingScrollPhysics(),
              itemCount: _filteredResidences.length,
              itemBuilder: (context, index) {
                final residence = _filteredResidences[index];
                final bool isSelected = _selectedResidence == residence;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedResidence = residence;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.gold.withOpacity(0.1)
                          : const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.gold : Colors.white24,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Selection indicator
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppColors.gold
                                : Colors.transparent,
                            border: Border.all(
                              color:
                                  isSelected ? AppColors.gold : Colors.white54,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Center(
                                  child: Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.black,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        // Residence name
                        Expanded(
                          child: Text(
                            residence,
                            style: TextStyle(
                              color: isSelected ? AppColors.gold : Colors.white,
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Progress indicator above the continue button
          _buildProgressIndicator(6, currentPage),
          const SizedBox(height: 16),
          _buildContinueButton(
            onPressed: _selectedResidence != null ? _nextPage : null,
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsPage() {
    // Get the current page from the controller
    final currentPage =
        _pageController.hasClients ? (_pageController.page ?? 0).round() : 0;
    const totalPages = 6;

    // Sort interests alphabetically and create a filtered state
    final List<String> sortedInterests = [..._interestOptions]
      ..sort((a, b) => a.compareTo(b));

    final List<String> filteredInterests = _searchQuery.isEmpty
        ? sortedInterests
        : sortedInterests
            .where((interest) =>
                interest.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                _smartMatchInterest(interest, _searchQuery))
            .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24), // Reduced top padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Text(
            'What are you into?',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select 5-10 interests to personalize your experience.',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),

          // Subtle selection counter
          Row(
            children: [
              Text(
                '${_selectedInterests.length}/$_maxInterests',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: _selectedInterests.length / _minInterests > 1
                        ? 1
                        : _selectedInterests.length / _minInterests,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _selectedInterests.length >= _minInterests
                          ? AppColors.success
                          : Colors.white.withOpacity(0.5),
                    ),
                    minHeight: 3,
                  ),
                ),
              ),
              if (_selectedInterests.length < _minInterests) ...[
                const SizedBox(width: 8),
                Text(
                  'Select ${_minInterests - _selectedInterests.length} more',
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Interests grid in a scrollable container
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Made search less prevalent - smaller, more subtle search button that expands on tap
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      child: _searchQuery.isNotEmpty || _isSearchFocused
                          ? Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.1)),
                              ),
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                style: GoogleFonts.inter(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Search interests...',
                                  hintStyle:
                                      GoogleFonts.inter(color: Colors.white38),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  // Match container color
                                  fillColor: Colors.white.withOpacity(0.05),
                                  filled: true,
                                  prefixIcon: Icon(Icons.search,
                                      color: Colors.white.withOpacity(0.5),
                                      size: 20),
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 16),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(Icons.clear,
                                              color:
                                                  Colors.white.withOpacity(0.5),
                                              size: 18),
                                          onPressed: () {
                                            setState(() {
                                              _searchQuery = '';
                                              _searchController.clear();
                                            });
                                          },
                                        )
                                      : null,
                                ),
                                onChanged: (query) {
                                  setState(() {
                                    _searchQuery = query;
                                  });
                                },
                              ),
                            )
                          : GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isSearchFocused = true;
                                  Future.delayed(
                                      const Duration(milliseconds: 100), () {
                                    if (_searchFocusNode.canRequestFocus) {
                                      _searchFocusNode.requestFocus();
                                    }
                                  });
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.1)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.search,
                                        color: Colors.white.withOpacity(0.5),
                                        size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Search interests',
                                      style: GoogleFonts.inter(
                                        color: Colors.white38,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),

                  // Interest chips with fluid layout using Wrap instead of GridView
                  Expanded(
                    child: filteredInterests.isEmpty
                        ? Center(
                            child: Text(
                              'No matching interests found',
                              style: GoogleFonts.inter(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            child: Wrap(
                              spacing:
                                  6, // Reduced horizontal spacing between chips
                              runSpacing:
                                  8, // Reduced vertical spacing between lines
                              alignment: WrapAlignment
                                  .start, // Align items to start of each row
                              children: filteredInterests.map((interest) {
                                final isSelected =
                                    _selectedInterests.contains(interest);

                                // Enhanced animation chips with fluid sizing based on content
                                return GestureDetector(
                                  onTap: () {
                                    _toggleInterest(interest);

                                    // Add haptic feedback
                                    HapticFeedback.selectionClick();
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutCubic,
                                    // Make chips smaller to fit at least 3 across
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.gold.withOpacity(0.15)
                                          : Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.gold
                                            : Colors.white.withOpacity(0.2),
                                        width: isSelected ? 1.0 : 0.5,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: AppColors.gold
                                                    .withOpacity(0.15),
                                                blurRadius: 5,
                                                spreadRadius: 0,
                                                offset: const Offset(0, 2),
                                              )
                                            ]
                                          : null,
                                    ),
                                    // Smaller scale effect for selected items
                                    transform: isSelected
                                        ? (Matrix4.identity()..scale(1.05))
                                        : Matrix4.identity(),
                                    transformAlignment: Alignment.center,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          interest,
                                          style: GoogleFonts.inter(
                                            color: isSelected
                                                ? AppColors.gold
                                                : Colors.white,
                                            fontSize: 12, // Smaller text size
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        // Animated checkmark on the same line as text
                                        AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          width: isSelected ? 16 : 0,
                                          curve: Curves.easeInOut,
                                          child: AnimatedOpacity(
                                            opacity: isSelected ? 1.0 : 0.0,
                                            duration: const Duration(
                                                milliseconds: 200),
                                            child: const Padding(
                                              padding: EdgeInsets.only(
                                                  left: 4),
                                              child: Icon(
                                                Icons.check_circle,
                                                color: AppColors.gold,
                                                size: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Progress indicator above the continue button
          _buildProgressIndicator(6, currentPage),
          const SizedBox(height: 16),
          _buildContinueButton(
            onPressed:
                _selectedInterests.length >= _minInterests ? _nextPage : null,
          ),
          
          // Add skip option with defaults
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              _skipWithDefaultInterests();
              HapticFeedback.lightImpact();
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Skip with recommended interests',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24), // Extra space at bottom for mobile
        ],
      ),
    );
  }

  Widget _buildAccountTierPage() {
    // Get the current page from the controller
    final currentPage =
        _pageController.hasClients ? (_pageController.page ?? 0).round() : 0;
    const totalPages = 6;

    // Check user email domain for verified tier
    final userEmail = _firebaseAuth.currentUser?.email ?? '';
    final canSelectVerifiedTiers =
        userEmail.toLowerCase().endsWith('buffalo.edu') || kDebugMode;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24), // Reduced top padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose your account type',
            style: AppTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Select the account tier that best suits your needs',
            style: AppTheme.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          // Debug panel for testing - only visible in debug mode for developers
          // Never shown to actual users

          if (!canSelectVerifiedTiers)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Note: Verified tiers require a buffalo.edu email address',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          if (canSelectVerifiedTiers)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'You\'ve been automatically verified with your buffalo.edu email',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Account tier selection
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildTierCard(
                    title: 'Public',
                    description: 'Basic access for everyone',
                    benefits: [
                      'Browse public events',
                      'View club information',
                    ],
                    restrictions: [
                      'No RSVP access',
                      'Limited messaging',
                    ],
                    isSelected: _selectedTier == AccountTier.public,
                    isExpanded: _expandedTier == AccountTier.public,
                    tierIcon: Icons.public,
                    iconColor: Colors.grey,
                    onTap: () {
                      // Add a small delay before state changes to avoid rendering issues
                      Future.microtask(() {
                        if (mounted) {
                          setState(() {
                            // Toggle expansion first
                            if (_expandedTier == AccountTier.public) {
                              _selectedTier = AccountTier.public;
                              _expandedTier = null;
                              // Add haptic feedback when selected
                              HapticFeedback.mediumImpact();
                            } else {
                              _expandedTier = AccountTier.public;
                            }
                          });
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildTierCard(
                    title: 'Verified',
                    description: canSelectVerifiedTiers
                        ? 'You\'re already verified with your buffalo.edu email'
                        : 'For UB students with buffalo.edu email',
                    benefits: [
                      'Full RSVP access',
                      'Messaging with other verified users'
                    ],
                    isSelected: _selectedTier == AccountTier.verified,
                    isExpanded: _expandedTier == AccountTier.verified,
                    tierIcon: Icons.verified,
                    iconColor:
                        Colors.blue, // Always blue regardless of selection
                    onTap: () {
                      // Add a small delay before state changes to avoid rendering issues
                      Future.microtask(() {
                        // Only allow selection if user has buffalo.edu email
                        if (canSelectVerifiedTiers) {
                          if (mounted) {
                            setState(() {
                              // If already expanded, toggle selection instead of just collapsing
                              if (_expandedTier == AccountTier.verified) {
                                _selectedTier = AccountTier.verified;
                                _expandedTier = null;
                                // Add haptic feedback when selected
                                HapticFeedback.mediumImpact();
                              } else {
                                _expandedTier = AccountTier.verified;
                              }
                            });
                          }
                        } else {
                          // Show edu email input dialog
                          _showEduEmailInputDialog();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildTierCard(
                    title: 'Verified+',
                    description: 'For student leaders and club officers',
                    benefits: [
                      'Create and manage events',
                      'Promote your club',
                      'Analytics dashboard'
                    ],
                    isSelected: _selectedTier == AccountTier.verifiedPlus,
                    isExpanded: _expandedTier == AccountTier.verifiedPlus,
                    tierIcon: Icons.verified,
                    iconColor: AppColors.gold,
                    onTap: () {
                      // Only allow selection if user has buffalo.edu email
                      if (canSelectVerifiedTiers) {
                        // Use full screen for verified+ flow
                        _showFullScreenVerifiedPlusFlow();
                      } else {
                        // Show edu email input dialog
                        _showEduEmailInputDialog();
                      }
                    },
                  ),
                  // Add bottom padding to ensure content doesn't get cut off
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // Progress indicator above the continue button
          _buildProgressIndicator(6, currentPage),
          const SizedBox(height: 16),
          _buildContinueButton(
            onPressed: () {
              try {
                debugPrint(
                    'Continue button pressed for tier: ${_selectedTier.name}');
                // Get current email state
                final bool hasBuffaloEmail =
                    _userEmail.toLowerCase().endsWith('buffalo.edu');

                // Handle each tier explicitly
                switch (_selectedTier) {
                  case AccountTier.verifiedPlus:
                    if (hasBuffaloEmail) {
                      // Make sure club and role are selected (should be set from dialog)
                      if (_selectedClub != null && _selectedClubRole != null) {
                        // Complete onboarding directly - we've already collected club info
                        _completeOnboardingAndNavigate();
                      } else {
                        // Something went wrong, prompt user to select their club
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Please select your club and role first.'),
                            duration: Duration(seconds: 2),
                          ),
                        );

                        // Show the dialog again
                        _showClubLeaderVerificationDialog();
                      }
                    } else {
                      // Not a buffalo.edu email - enforce the rule
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Verified+ tier requires a buffalo.edu email address.'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                      setState(() {
                        _selectedTier = AccountTier.public;
                      });
                      // Show verification dialog
                      _showEduEmailInputDialog();
                    }
                    break;

                  case AccountTier.verified:
                    if (hasBuffaloEmail) {
                      // Complete onboarding directly
                      _completeOnboardingAndNavigate();
                    } else {
                      // Not a buffalo.edu email - enforce the rule
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Verified tier requires a buffalo.edu email address.'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                      setState(() {
                        _selectedTier = AccountTier.public;
                      });
                      // Show verification dialog
                      _showEduEmailInputDialog();
                    }
                    break;

                  case AccountTier.public:
                  default:
                    // Complete onboarding for public tier - fixed to ensure it always processes
                    debugPrint('Completing onboarding for public tier account');
                    _completeOnboardingAndNavigate();
                    break;
                }
              } catch (e) {
                // Log any errors
                debugPrint('Error in account tier selection: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('An error occurred. Please try again.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard({
    required String title,
    required String description,
    List<String>? benefits,
    List<String>? restrictions,
    required bool isSelected,
    required bool isExpanded,
    required IconData tierIcon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.gold.withOpacity(0.1)
            : const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.gold : Colors.white24,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icon and title
                Expanded(
                  child: Row(
                    children: [
                      // No container for any icons
                      Icon(
                        tierIcon,
                        color: title == 'Verified' ? Colors.blue : iconColor,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.inter(
                                color:
                                    isSelected ? AppColors.gold : Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Description with a height limit to prevent overflow
                            SizedBox(
                              height:
                                  36, // Fixed height to prevent layout shifts
                              child: Text(
                                description,
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Selection and expansion indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.gold : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppColors.gold : Colors.white24,
                      width: isSelected ? 0 : 1,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.black,
                        )
                      : null,
                ),
              ],
            ),
          ),

          // Expandable content
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: isExpanded ? (benefits?.length ?? 0) * 32.0 + 24 : 0,
            curve: Curves.easeInOut,
            child: AnimatedOpacity(
              opacity: isExpanded ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 8),
                    if (benefits != null && benefits.isNotEmpty)
                      ...benefits.map((benefit) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    benefit,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    if (restrictions != null && restrictions.isNotEmpty)
                      ...restrictions.map((restriction) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.cancel_outlined,
                                  color: Colors.red,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    restriction,
                                    style: GoogleFonts.inter(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClubDetailsPage() {
    // Get the current page from the controller
    final currentPage =
        _pageController.hasClients ? (_pageController.page ?? 0).round() : 0;
    const totalPages = 6;

    // If _clubs is null or empty, start loading them now
    if (_clubs.isEmpty && !_isLoadingClubs) {
      Future.microtask(() => _fetchClubs());
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Org details',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us about your leadership role',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),

          // Club search with SearchSelect
          _isLoadingClubs
              ? const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.gold),
                        strokeWidth: 2,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading clubs...',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                )
              : _clubs.isEmpty
                  ? Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.white70,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No clubs found',
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isLoadingClubs = true;
                              });
                              _fetchClubs();
                            },
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    )
                  : SearchSelect(
                      title: 'Club',
                      selectedValue: _selectedClub != null && _clubs.isNotEmpty
                          ? _clubs
                              .firstWhere(
                                (club) => club.id == _selectedClub,
                                orElse: () => _clubs.first,
                              )
                              .name
                          : null,
                      placeholder: 'Search for your club...',
                      options: _filteredClubs.map((club) => club.name).toList(),
                      onSearch: _filterClubs,
                      onSelect: (clubName) {
                        // Find the club safely
                        if (_filteredClubs.isNotEmpty) {
                          final selectedClub = _filteredClubs.firstWhere(
                            (club) => club.name == clubName,
                            orElse: () => _filteredClubs.first,
                          );
                          setState(() {
                            _selectedTier = AccountTier.verifiedPlus;
                            _selectedClub = selectedClub.id;
                            _selectedClubRole =
                                'President'; // Assume president for new clubs
                            _expandedTier = AccountTier.verifiedPlus;
                          });
                          HapticFeedback.selectionClick();
                        }
                      },
                      onClear: () {
                        setState(() {
                          _selectedClub = null;
                          _selectedClubRole = null;
                        });
                      },
                    ),

          const SizedBox(height: 24),

          // Role selection dropdown (only visible if club is selected)
          if (_selectedClub != null && !_isLoadingClubs) ...[
            Text(
              'Your role',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownSelect(
              title: 'Role',
              selectedValue: _selectedClubRole,
              placeholder: 'Select your role',
              options: clubRoles,
              onSelect: (value) {
                setState(() {
                  _selectedClubRole = value;
                });
              },
              onClear: () {
                setState(() {
                  _selectedClubRole = null;
                });
              },
            ),
          ],

          // Spacer to push information container to bottom when needed
          const Spacer(),

          // Information container
          if (_selectedClub != null && !_isLoadingClubs) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: const Color(0xFFFFD700).withOpacity(0.7),
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Your Verified+ account will require approval. We\'ll send you an email with next steps.',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Progress indicator above the continue button
          _buildProgressIndicator(6, currentPage),
          const SizedBox(height: 16),

          // Continue button with loading state
          _isCompletingOnboarding
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                    strokeWidth: 2,
                  ),
                )
              : _buildContinueButton(
                  onPressed: (_selectedClub != null &&
                          _selectedClubRole != null &&
                          !_isLoadingClubs)
                      ? _completeOnboardingAndNavigate
                      : null,
                ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Function(String) onSubmitted,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 16,
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.3),
          ),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Colors.white,
            width: 2,
          ),
        ),
        floatingLabelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.next,
      cursorColor: Colors.white,
    );
  }

  Widget _buildContinueButton({required VoidCallback? onPressed}) {
    // Ensure the button is more visible even when disabled
    final bool isEnabled = onPressed != null;

    // Use GestureDetector to improve tap detection on mobile
    return GestureDetector(
      onTap: isEnabled
          ? () {
              debugPrint('Continue button tapped manually via GestureDetector');
              onPressed();
                        }
          : null,
      child: Container(
        width: double.infinity,
        height: 56,
        margin: const EdgeInsets.only(
            bottom: 16), // Add bottom margin for better spacing on mobile
        // Make the touch target larger for better mobile tapping
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled
                ? () {
                    debugPrint('Continue button tapped via InkWell');
                    onPressed();
                                    }
                : null,
            borderRadius: BorderRadius.circular(30),
            splashColor: Colors.black.withOpacity(0.3),
            highlightColor: Colors.black.withOpacity(0.1),
            child: Ink(
              decoration: BoxDecoration(
                color: isEnabled ? Colors.white : Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Center(
                child: Text(
                  'Continue',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Fix the _getEmojiForInterest method
  // ignore: unused_element
  String _getEmojiForInterest(String interestName) {
    return '';
  }

  // Fetch clubs for Verified+ accounts with optimized space-based implementation
  Future<void> _fetchClubs() async {
    setState(() {
      _isLoadingClubs = true;
    });

    try {
      // Check if we already have clubs in the local state
      if (_clubs.isNotEmpty) {
        debugPrint('Using existing clubs in state, skipping Firestore query');
        setState(() {
          _isLoadingClubs = false;
        });
        return;
      }

      // Try to use ClubService first, which has caching built-in
      await ClubService.initialize();
      final cachedClubs = ClubService.getAllClubs();

      if (cachedClubs.isNotEmpty) {
        debugPrint('Using ${cachedClubs.length} clubs from ClubService cache');
        setState(() {
          _clubs = cachedClubs;
          _filteredClubs = cachedClubs;
          _isLoadingClubs = false;
        });
        return;
      }

      // If no cached clubs, query Firestore with strict limits
      final firestore = FirebaseFirestore.instance;

      debugPrint(
          'Fetching clubs using optimized collectionGroup query with limit');

      // Use a much smaller limit for onboarding - we just need a representative sample
      // This dramatically reduces read operations
      final snapshot = await firestore
          .collectionGroup('spaces')
          .orderBy('name')
          .limit(50) // Reduced from 500 to 50
          .get(const GetOptions(
              source: Source.serverAndCache)); // Allow cached data

      debugPrint(
          'Found ${snapshot.docs.length} clubs in collectionGroup "spaces"');

      // Process results
      final List<Club> allClubs = [];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          // Extract space type from the path for proper categorization
          final pathParts = doc.reference.path.split('/');
          final spaceType = pathParts.length > 2 ? pathParts[1] : 'general';

          final club = Club(
            id: doc.id,
            name: data['name'] ?? 'Unknown Club',
            description: data['description'] ?? '',
            category: data['category'] ?? spaceType,
            memberCount:
                data['memberCount'] ?? data['metrics']?['memberCount'] ?? 0,
            status: data['status'] ?? 'active',
            icon: Icons.group,
            createdAt:
                (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            updatedAt:
                (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            imageUrl: data['imageUrl'] ?? data['bannerUrl'],
            bannerUrl: data['bannerUrl'],
            tags: (data['tags'] as List<dynamic>?)
                    ?.map((tag) => tag.toString())
                    .toList() ??
                [],
          );

          allClubs.add(club);
        } catch (e) {
          debugPrint('Error parsing club document ${doc.id}: $e');
        }
      }

      // Sort clubs by name
      allClubs.sort((a, b) => a.name.compareTo(b.name));

      debugPrint('Total clubs found: ${allClubs.length}');

      // If no clubs found, add demo clubs
      if (allClubs.isEmpty) {
        debugPrint('No clubs found, adding demo clubs');
        allClubs.addAll(_getDemoClubs());
      }

      // Store clubs in ClubService for future use
      for (final club in allClubs) {
        // Use the correct method from ClubService
        ClubService.addClubToCache(club);
      }

      if (mounted) {
        setState(() {
          _clubs = allClubs;
          _filteredClubs = allClubs;
          _isLoadingClubs = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching clubs: $e');

      // Fallback to demo clubs if everything fails
      final demoClubs = _getDemoClubs();

      if (mounted) {
        setState(() {
          _clubs = demoClubs;
          _filteredClubs = demoClubs;
          _isLoadingClubs = false;
        });
      }
    }
  }

  // Helper method to create demo clubs as fallback
  List<Club> _getDemoClubs() {
    return [
      Club(
        id: 'club-cs',
        name: 'Computer Science Club',
        description:
            'A club for students interested in computer science and programming.',
        category: 'Academic',
        memberCount: 150,
        status: 'active',
        icon: Icons.computer,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Club(
        id: 'club-engineering',
        name: 'Engineering Society',
        description: 'For all engineering students to network and collaborate.',
        category: 'Academic',
        memberCount: 200,
        status: 'active',
        icon: Icons.build,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Club(
        id: 'club-business',
        name: 'Business Leadership Association',
        description:
            'Developing future business leaders through networking and skill building.',
        category: 'Professional',
        memberCount: 120,
        status: 'active',
        icon: Icons.business,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Club(
        id: 'club-arts',
        name: 'Art & Design Club',
        description:
            'A space for creative students to share their work and collaborate.',
        category: 'Arts',
        memberCount: 80,
        status: 'active',
        icon: Icons.palette,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Club(
        id: 'club-music',
        name: 'Music Society',
        description:
            'For students passionate about music performance and appreciation.',
        category: 'Arts',
        memberCount: 95,
        status: 'active',
        icon: Icons.music_note,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  Widget _buildProgressIndicator(int totalPages, int currentPage) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalPages, (index) {
          final isActive = index <= currentPage;
          final isCurrentPage = index == currentPage;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            width: isCurrentPage ? 24 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isActive ? const Color(0xFFFFD700) : Colors.white24,
            ),
          );
        }),
      ),
    );
  }

  // Fix the _getRelevantInterests method
  // ignore: unused_element
  List<String> _getRelevantInterests() {
    final List<String> relevant = [];

    if (_selectedMajor == null) return relevant;

    // Check for STEM-related fields
    if (_selectedMajor!.contains('Engineering') ||
        _selectedMajor!.contains('Computer') ||
        _selectedMajor!.contains('Science') ||
        _selectedMajor!.contains('Mathematics') ||
        _selectedMajor!.contains('Physics') ||
        _selectedMajor!.contains('Chemistry') ||
        _selectedMajor!.contains('Biology')) {
      relevant.addAll(
          ['Research', 'Hackathons', 'Tutoring', 'Academic Competitions']);
    }

    // Check for arts-related fields
    if (_selectedMajor!.contains('Art') ||
        _selectedMajor!.contains('Music') ||
        _selectedMajor!.contains('Theater') ||
        _selectedMajor!.contains('Design') ||
        _selectedMajor!.contains('Film') ||
        _selectedMajor!.contains('Dance') ||
        _selectedMajor!.contains('Creative')) {
      relevant.addAll([
        'Visual Arts',
        'Music',
        'Photography',
        'Theater',
        'Creative Writing',
        'Film'
      ]);
    }

    // Check for business-related fields
    if (_selectedMajor!.contains('Business') ||
        _selectedMajor!.contains('Management') ||
        _selectedMajor!.contains('Economics') ||
        _selectedMajor!.contains('Marketing') ||
        _selectedMajor!.contains('Finance')) {
      relevant.addAll([
        'Networking',
        'Entrepreneurship',
        'Leadership',
        'Career Development'
      ]);
    }

    // Check for healthcare-related fields
    if (_selectedMajor!.contains('Health') ||
        _selectedMajor!.contains('Nursing') ||
        _selectedMajor!.contains('Medicine') ||
        _selectedMajor!.contains('Pharmacy') ||
        _selectedMajor!.contains('Therapy')) {
      relevant.addAll(['Volunteering', 'Research', 'Fitness', 'Yoga']);
    }

    // Check for social science fields
    if (_selectedMajor!.contains('Psychology') ||
        _selectedMajor!.contains('Sociology') ||
        _selectedMajor!.contains('Anthropology') ||
        _selectedMajor!.contains('Political') ||
        _selectedMajor!.contains('History')) {
      relevant.addAll(['Volunteering', 'Discussion Groups', 'Book Clubs']);
    }

    return relevant;
  }

  // Enhanced smart match algorithm for better search results
  bool _smartMatchInterest(String interest, String query) {
    if (query.length < 2) return false;

    // Convert to lowercase for case-insensitive matching
    final interestLower = interest.toLowerCase();
    final queryLower = query.toLowerCase();

    // Direct contains check (already handled in the filtering function, but kept for clarity)
    if (interestLower.contains(queryLower)) {
      return true;
    }

    // Check for partial word matching with better flexibility
    final interestWords = interestLower.split(' ');
    final queryWords = queryLower.split(' ');

    for (final queryWord in queryWords) {
      // Skip very short query words
      if (queryWord.length < 2) continue;

      for (final interestWord in interestWords) {
        // Check for starts with
        if (interestWord.startsWith(queryWord)) {
          return true;
        }

        // Check for close matches (e.g., "prog" matches "programming")
        if (queryWord.length >= 3 &&
            interestWord.length > 4 &&
            interestWord.contains(queryWord)) {
          return true;
        }
      }
    }

    // Enhanced matching for related terms
    final Map<String, List<String>> relatedTerms = {
      'music': [
        'singing',
        'guitar',
        'piano',
        'drumming',
        'song',
        'instrument',
        'band',
        'concert',
        'perform'
      ],
      'sports': [
        'soccer',
        'basketball',
        'football',
        'tennis',
        'athletic',
        'team',
        'play',
        'competition'
      ],
      'tech': [
        'coding',
        'programming',
        'computer',
        'software',
        'technology',
        'app',
        'development',
        'engineering'
      ],
      'art': [
        'drawing',
        'painting',
        'creative',
        'design',
        'sketch',
        'craft',
        'artistic',
        'create',
        'sculpt'
      ],
      'fitness': [
        'gym',
        'workout',
        'exercise',
        'training',
        'running',
        'health',
        'strength',
        'cardio'
      ],
      'social': [
        'tiktok',
        'instagram',
        'snapchat',
        'twitter',
        'youtube',
        'media',
        'posting',
        'streaming',
        'online'
      ],
      'creative': [
        'writing',
        'sketching',
        'drawing',
        'painting',
        'crafting',
        'design',
        'pottery',
        'sculpting'
      ],
      'gaming': [
        'games',
        'play',
        'esports',
        'video games',
        'streaming',
        'twitch',
        'competitive'
      ],
      'relax': [
        'chill',
        'napping',
        'relaxing',
        'daydreaming',
        'meditation',
        'rest',
        'sleep',
        'calm'
      ],
      'academic': [
        'studying',
        'research',
        'learning',
        'education',
        'knowledge',
        'science',
        'reading'
      ],
    };

    // Check if interest contains any category
    for (final category in relatedTerms.keys) {
      // If the query contains this category
      if (queryLower.contains(category)) {
        // Check if interest contains any related term
        for (final relatedTerm in relatedTerms[category]!) {
          if (interestLower.contains(relatedTerm)) {
            return true;
          }
        }
      }

      // If interest is or contains the category
      if (interestLower == category || interestLower.contains(category)) {
        // Check if query contains any related term
        for (final relatedTerm in relatedTerms[category]!) {
          if (queryLower.contains(relatedTerm)) {
            return true;
          }
        }
      }

      // Check more specifically for related terms
      if (relatedTerms[category]!.contains(interestLower)) {
        if (queryLower.contains(category) ||
            relatedTerms[category]!.any((term) => queryLower.contains(term))) {
          return true;
        }
      }
    }

    // Special case for specific interests
    final Map<String, List<String>> specialInterests = {
      'tiktok': ['video', 'short form', 'social', 'dance', 'trend'],
      'youtube': ['video', 'streaming', 'content', 'creator', 'watch'],
      'napping': ['sleep', 'rest', 'relax', 'afternoon', 'tired'],
      'goose chasing': ['geese', 'campus', 'outdoor', 'ub', 'buffalo', 'birds'],
      'ublinkedhater': [
        'linkedin',
        'professional',
        'job',
        'career',
        'networking',
        'social'
      ],
      'streaming': [
        'watch',
        'content',
        'netflix',
        'youtube',
        'twitch',
        'online',
        'video'
      ],
      'cosplay': [
        'costume',
        'convention',
        'anime',
        'character',
        'dress up',
        'comic'
      ],
      'conventions': ['event', 'gathering', 'cosplay', 'comic', 'anime', 'fan'],
    };

    for (final interest in specialInterests.keys) {
      if (interestLower.contains(interest)) {
        for (final relatedTerm in specialInterests[interest]!) {
          if (queryLower.contains(relatedTerm)) {
            return true;
          }
        }
      }
    }

    return false;
  }

  // Add this method for educational email input dialog
  void _showEduEmailInputDialog() {
    // For users who already have a buffalo.edu email,
    // don't show the dialog and just update tier
    if (_userEmail.toLowerCase().endsWith('buffalo.edu')) {
      setState(() {
        // If they were trying to get verified+, set to verified+
        // Otherwise default to verified
        _selectedTier = _expandedTier == AccountTier.verifiedPlus
            ? AccountTier.verifiedPlus
            : AccountTier.verified;

        // Also update the expanded tier for UI
        _expandedTier = _selectedTier == AccountTier.verified
            ? AccountTier.verified
            : AccountTier.verifiedPlus;
      });
      return;
    }

    // Check if the user already has another type of .edu email
    if (_userEmail.toLowerCase().endsWith('.edu')) {
      // Check if it's verified
      final user = _firebaseAuth.currentUser;
      if (user != null && user.emailVerified) {
        // Already verified, just update the tier
        setState(() {
          _selectedTier = _expandedTier == AccountTier.verifiedPlus
              ? AccountTier.verifiedPlus
              : AccountTier.verified;

          _expandedTier = _selectedTier == AccountTier.verified
              ? AccountTier.verified
              : AccountTier.verifiedPlus;
        });
        return;
      } else {
        // Show verification needed dialog
        _showVerificationNeededDialog();
        return;
      }
    }

    // For non-edu emails, show the peeking card dialog for adding an edu email
    final TextEditingController eduEmailController = TextEditingController();
    bool isLoading = false;
    String? emailError;

    // Create bottom sheet controller for the peekable design
    final controller = DraggableScrollableController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          controller: controller,
          initialChildSize: 0.6, // Start with sheet peeking from bottom
          minChildSize: 0.4, // Minimum height when peeked
          maxChildSize: 0.85, // Maximum height when fully expanded
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setState) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.1), width: 0.5),
                  ),
                  child: Column(
                    children: [
                      // Drag handle for better UX
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Content area
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(24),
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.school,
                                  color: AppColors.gold,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Enter your Educational Email',
                                  style: AppTheme.displaySmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'For verified access, please provide a .edu email address. Buffalo.edu emails get immediate verification.',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextField(
                              controller: eduEmailController,
                              style: GoogleFonts.inter(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Educational Email',
                                labelStyle:
                                    GoogleFonts.inter(color: Colors.white70),
                                hintText: 'yourname@university.edu',
                                hintStyle:
                                    GoogleFonts.inter(color: Colors.white30),
                                prefixIcon: const Icon(Icons.email,
                                    color: Colors.white70),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.white30),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.gold),
                                ),
                                errorText: emailError,
                                filled: true,
                                fillColor: Colors.black45,
                              ),
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (value) {
                                // Validate email on each change
                                setState(() {
                                  if (!value.toLowerCase().endsWith('.edu')) {
                                    emailError = 'Must be a valid .edu email';
                                  } else {
                                    emailError = null;
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: isLoading ||
                                        (emailError != null &&
                                            eduEmailController.text.isNotEmpty)
                                    ? null
                                    : () async {
                                        final email =
                                            eduEmailController.text.trim();

                                        if (email.isEmpty) {
                                          setState(() {
                                            emailError =
                                                'Email cannot be empty';
                                          });
                                          return;
                                        }

                                        if (!email
                                            .toLowerCase()
                                            .endsWith('.edu')) {
                                          setState(() {
                                            emailError =
                                                'Must be a valid .edu email';
                                          });
                                          return;
                                        }

                                        // Show loading indicator
                                        setState(() {
                                          isLoading = true;
                                        });

                                        try {
                                          // Get Firebase instances
                                          final auth = FirebaseAuth.instance;
                                          final firestore =
                                              FirebaseFirestore.instance;
                                          final currentUser = auth.currentUser;

                                          if (currentUser != null) {
                                            // Update the user's educational email
                                            await firestore
                                                .collection('users')
                                                .doc(currentUser.uid)
                                                .update({
                                              'educationalEmail': email,
                                              'eduEmailVerified': email
                                                  .toLowerCase()
                                                  .endsWith('buffalo.edu'),
                                              'updatedAt':
                                                  FieldValue.serverTimestamp(),
                                            });

                                            // Send verification email for non-buffalo.edu emails
                                            if (!email
                                                .toLowerCase()
                                                .endsWith('buffalo.edu')) {
                                              try {
                                                // This would need to be implemented via Firebase Functions
                                                debugPrint(
                                                    'Would send verification email to: $email');

                                                // For non-Buffalo emails, we need verification
                                                await Future.delayed(
                                                    const Duration(seconds: 1));
                                              } catch (verificationError) {
                                                debugPrint(
                                                    'Error sending verification: $verificationError');
                                              }
                                            }
                                          }

                                          // Update email in parent widget
                                          if (context.mounted) {
                                            _updateUserEmail(email);

                                            // Check if user was trying to select verified+
                                            final targetTier = _expandedTier ==
                                                    AccountTier.verifiedPlus
                                                ? AccountTier.verifiedPlus
                                                : AccountTier.public;

                                            // Set the tier based on which they were attempting to access
                                            // Buffalo.edu emails get immediate access
                                            if (email
                                                .toLowerCase()
                                                .endsWith('buffalo.edu')) {
                                              this.setState(() {
                                                _selectedTier = targetTier;
                                                _expandedTier = targetTier;
                                              });

                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'Buffalo.edu email verified!'),
                                                  backgroundColor: Colors.green,
                                                  duration:
                                                      Duration(seconds: 3),
                                                ),
                                              );
                                            } else {
                                              // For other .edu emails, show verification needed
                                              this.setState(() {
                                                _selectedTier =
                                                    AccountTier.public;
                                                _expandedTier = null;
                                              });

                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      'Please verify $email to access higher tiers'),
                                                  backgroundColor:
                                                      AppColors.warning,
                                                  duration: const Duration(
                                                      seconds: 3),
                                                ),
                                              );
                                            }

                                            Navigator.pop(context);

                                            // For non-Buffalo emails, show the verification needed dialog
                                            if (!email
                                                .toLowerCase()
                                                .endsWith('buffalo.edu')) {
                                              Future.microtask(() {
                                                _showVerificationNeededDialog();
                                              });
                                            }
                                          }
                                        } catch (e) {
                                          // Handle errors
                                          debugPrint(
                                              'Error during email verification: $e');

                                          if (context.mounted) {
                                            setState(() {
                                              isLoading = false;
                                              emailError =
                                                  'Error verifying email. Please try again.';
                                            });
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.gold,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.black),
                                        ),
                                      )
                                    : const Text(
                                        'Verify Email',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        Navigator.pop(context);
                                        // Set tier to public when user cancels
                                        this.setState(() {
                                          _selectedTier = AccountTier.public;
                                          _expandedTier = null;
                                        });
                                      },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white24),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                child: Text(
                                  'Continue with Public Access',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Show dialog when verification is needed for an educational email
  void _showVerificationNeededDialog() {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.gold.withOpacity(0.5), width: 1),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.verified_outlined,
              color: AppColors.gold,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Verification Required',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your educational email needs to be verified before you can access the Verified tier.',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'We\'ve sent a verification email to ${user.email}. Please check your inbox and click the verification link.',
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Didn\'t receive the email?',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _selectedTier = AccountTier.public;
              });
            },
            child: Text(
              'Continue as Public',
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _sendVerificationEmail();
            },
            child: Text(
              'Resend Verification',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Club leader verification dialog
  void _showClubLeaderVerificationDialog() {
    HapticFeedback.mediumImpact();

    // Create bottom sheet controller for the peekable design
    final controller = DraggableScrollableController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          controller: controller,
          initialChildSize: 0.6, // Start with sheet peeking from bottom
          minChildSize: 0.4, // Minimum height when peeked
          maxChildSize: 0.85, // Maximum height when fully expanded
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(
                    color: Colors.white.withOpacity(0.1), width: 0.5),
              ),
              child: Column(
                children: [
                  // Drag handle for better UX
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Title section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.verified,
                                color: AppColors.gold,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Club Leader Verification',
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tell us about your leadership role in a campus organization',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: Colors.white10),

                  // Content section (scrollable)
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      children: [
                        // Club selection section
                        Text(
                          'Select your organization',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),

                        _isLoadingClubs
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24.0),
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.gold),
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Search field - made bigger for easier tapping on mobile
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    height:
                                        48, // Taller for better touch target
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.search,
                                          color: Colors.white.withOpacity(0.6),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextField(
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              hintText:
                                                  'Search for your organization...',
                                              hintStyle: GoogleFonts.inter(
                                                color: Colors.white
                                                    .withOpacity(0.4),
                                                fontSize: 14,
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14),
                                            ),
                                            onChanged: _filterClubs,
                                          ),
                                        ),
                                        if (_clubSearchQuery.isNotEmpty)
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _clubSearchQuery = '';
                                                _filteredClubs = _clubs;
                                              });
                                            },
                                            child: Icon(
                                              Icons.close,
                                              color:
                                                  Colors.white.withOpacity(0.6),
                                              size: 20,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  // Club selection list - limited height with internal scrolling
                                  _filteredClubs.isEmpty
                                      ? Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(24.0),
                                            child: Column(
                                              children: [
                                                Icon(
                                                  Icons.search_off,
                                                  color: Colors.white
                                                      .withOpacity(0.4),
                                                  size: 40,
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  'No organizations found',
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white
                                                        .withOpacity(0.7),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      : Container(
                                          constraints: const BoxConstraints(
                                              maxHeight: 200),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.02),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: Colors.white10),
                                          ),
                                          child: ListView.separated(
                                            shrinkWrap: true,
                                            physics:
                                                const ClampingScrollPhysics(),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8),
                                            itemCount: _filteredClubs.length,
                                            separatorBuilder:
                                                (context, index) => Divider(
                                              height: 1,
                                              color: Colors.white
                                                  .withOpacity(0.05),
                                              indent: 16,
                                              endIndent: 16,
                                            ),
                                            itemBuilder: (context, index) {
                                              final club =
                                                  _filteredClubs[index];
                                              final isSelected =
                                                  _selectedClub == club.id;
                                              return ListTile(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 4),
                                                leading: CircleAvatar(
                                                  backgroundColor: isSelected
                                                      ? AppColors.gold
                                                          .withOpacity(0.2)
                                                      : Colors.white
                                                          .withOpacity(0.1),
                                                  child: Icon(
                                                    club.icon,
                                                    color: isSelected
                                                        ? AppColors.gold
                                                        : Colors.white,
                                                    size: 20,
                                                  ),
                                                ),
                                                title: Text(
                                                  club.name,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w600
                                                        : FontWeight.w400,
                                                    color: isSelected
                                                        ? AppColors.gold
                                                        : Colors.white,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  club.category,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    color: Colors.white
                                                        .withOpacity(0.5),
                                                  ),
                                                ),
                                                trailing: isSelected
                                                    ? Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(4),
                                                        decoration:
                                                            const BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: AppColors.gold,
                                                        ),
                                                        child: const Icon(
                                                          Icons.check,
                                                          color: Colors.black,
                                                          size: 16,
                                                        ),
                                                      )
                                                    : null,
                                                onTap: () {
                                                  setState(() {
                                                    _selectedTier = AccountTier
                                                        .verifiedPlus;
                                                    _selectedClub = club.id;
                                                    _selectedClubRole =
                                                        'President'; // Assume president for new clubs
                                                    _expandedTier = AccountTier
                                                        .verifiedPlus;
                                                  });
                                                  Navigator.pop(context);
                                                  // After selecting a club, show the role selection dialog
                                                  _showRoleSelectionDialog();
                                                },
                                              );
                                            },
                                          ),
                                        ),

                                  const SizedBox(height: 24),

                                  Text(
                                    'Don\'t see your organization?',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Button to proceed with creating a new club
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                      // Show dialog to create new club here
                                      _showCreateClubDialog();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                        border:
                                            Border.all(color: Colors.white24),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.add_circle_outline,
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Request to add your organization',
                                              style: GoogleFonts.inter(
                                                color: Colors.white
                                                    .withOpacity(0.8),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            color:
                                                Colors.white.withOpacity(0.5),
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                        // Add extra bottom space for better scrolling experience
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),

                  // Bottom action buttons section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.black,
                      border: Border(
                        top: BorderSide(color: Colors.white.withOpacity(0.05)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              // Simply close this dialog without proceeding
                              Navigator.pop(context);
                              setState(() {
                                _selectedTier = AccountTier.verified;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: AppColors.gold,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Just Verified',
                                style: GoogleFonts.inter(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Role selection dialog
  void _showRoleSelectionDialog() {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          decoration: BoxDecoration(
            color: AppColors.black,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border:
                Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your role in the organization',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select your position in the organization',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 20),

              // Role selection
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: clubRoles.length,
                  itemBuilder: (context, index) {
                    final role = clubRoles[index];
                    final isSelected = _selectedClubRole == role;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 2),
                      title: Text(
                        role,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? AppColors.gold : Colors.white,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle,
                              color: AppColors.gold, size: 20)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedClubRole = role;
                        });
                        Navigator.pop(context);

                        // Complete the selection process
                        setState(() {
                          _selectedTier = AccountTier.verifiedPlus;
                        });
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Cancel button
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              // Safe area padding
              SizedBox(height: MediaQuery.of(context).viewPadding.bottom)
            ],
          ),
        );
      },
    );
  }

  // Dialog to request adding a new club
  void _showCreateClubDialog() {
    final TextEditingController clubNameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              color: AppColors.black,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              border:
                  Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request a new organization',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Provide details about your organization',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 24),

                // Club name field
                Text(
                  'Organization name',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: TextField(
                    controller: clubNameController,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter organization name',
                      hintStyle: GoogleFonts.inter(
                        color: Colors.white38,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Description field
                Text(
                  'Description',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: TextField(
                    controller: descriptionController,
                    style: GoogleFonts.inter(color: Colors.white),
                    maxLines: 3,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter a brief description',
                      hintStyle: GoogleFonts.inter(
                        color: Colors.white38,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Submit request logic would go here
                          final clubName = clubNameController.text.trim();
                          final description = descriptionController.text.trim();

                          if (clubName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Please enter an organization name')),
                            );
                            return;
                          }

                          // Close the dialog
                          Navigator.pop(context);

                          // Show confirmation and set state
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Request submitted for $clubName'),
                              backgroundColor: AppColors.success,
                            ),
                          );

                          // Create a temporary club
                          final newClubId = Club.createIdFromName(clubName);
                          final newClub = Club(
                            id: newClubId,
                            name: clubName,
                            description: description,
                            category: 'Other',
                            memberCount: 1,
                            status: 'pending',
                            icon: Icons.group,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          );

                          // Add to the list and select it
                          setState(() {
                            _clubs = [newClub, ..._clubs];
                            _filteredClubs = _clubs;
                            _selectedClub = newClubId;
                            _selectedClubRole =
                                'President'; // Assume president for new clubs
                            _selectedTier = AccountTier.verifiedPlus;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.gold,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Submit',
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Safe area padding
                SizedBox(height: MediaQuery.of(context).viewPadding.bottom)
              ],
            ),
          ),
        );
      },
    ).then((_) {
      // Dispose controllers when dialog is closed
      clubNameController.dispose();
      descriptionController.dispose();
    });
  }

  // Helper method to check if name fields are valid
  bool _isNameValid() {
    return _firstNameController.text.trim().isNotEmpty &&
        _lastNameController.text.trim().isNotEmpty;
  }

  // Handle back button press
  void _handleBackPress() {
    // Add haptic feedback
    HapticFeedback.lightImpact();

    // If we're on the first page, consider exiting the onboarding
    if (_currentPage == 0) {
      _showExitConfirmationDialog().then((shouldExit) {
        if (shouldExit && mounted) {
          // Sign out and return to landing page
          _abandonOnboarding();
        }
      });
    } else {
      // Otherwise, go to the previous page
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  // Properly handle abandoned onboarding by signing out and removing auth state
  Future<void> _abandonOnboarding() async {
    try {
      // Clear any saved partial profile data
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        // If there's a Firestore document already created, delete it
        try {
          await _firestore.collection('users').doc(user.uid).delete();
          debugPrint('Removed partial user profile from Firestore');
        } catch (e) {
          // Document might not exist yet, which is fine
          debugPrint('No Firestore profile to remove: $e');
        }

        // If there's a profile picture, consider deleting it from storage too
        // This would be something like:
        // final storageRef = FirebaseStorage.instance.ref().child('profile_pictures/${user.uid}');
        // await storageRef.delete().catchError((e) => debugPrint('No profile picture to remove: $e'));
      }

      // Use the auth controller from Riverpod to properly abandon onboarding
      final authController = ref.read(authControllerProvider.notifier);
      await authController.abandonOnboarding();

      // Update onboarding status in provider
      ref.read(onboardingInProgressProvider.notifier).state = false;

      if (mounted) {
        // Navigate back to landing page using GoRouter
        context.go('/');
      }
    } catch (e) {
      debugPrint('Error abandoning onboarding: $e');

      // Fallback to direct sign out if provider approach fails
      try {
        await _firebaseAuth.signOut();
        await UserPreferencesService.clearUserData();
      } catch (signOutError) {
        debugPrint('Even fallback sign out failed: $signOutError');
      }

      // Still try to navigate away even if there was an error
      if (mounted) {
        context.go('/');
      }
    }
  }

  // Full-screen approach for Verified+ flow
  Future<void> _showFullScreenVerifiedPlusFlow() async {
    HapticFeedback.mediumImpact();

    // For a full screen page that needs to return data, we can still use MaterialPageRoute
    // or Navigator.push since GoRouter's approach for returning data is more complex
    // This is an acceptable case for using Navigator directly
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _VerifiedPlusPage(
          clubs: _clubs,
          isLoading: _isLoadingClubs,
          selectedClub: _selectedClub,
          selectedClubRole: _selectedClubRole,
          onSelectClub: (clubId, role) {
            setState(() {
              _selectedTier = AccountTier.verifiedPlus;
              _selectedClub = clubId;
              _selectedClubRole = role;
              _expandedTier = AccountTier.verifiedPlus;
            });
          },
          onFetchClubs: () async {
            await _fetchClubs();
            return _clubs;
          },
        ),
      ),
    );

    // Force rebuild since we're back from the dialog
    if (mounted) {
      setState(() {
        // Refresh UI state
      });
    }
  }

  /// Skip interest selection and use default interests
  void _skipWithDefaultInterests() {
    // Set default interests based on the user's major
    setState(() {
      _selectedInterests.clear();
      
      // Add some default general interests that most students might like
      final defaultInterests = [
        'Campus Events',
        'Student Life',
        'Networking',
        'Career Development',
        'Social Activities',
      ];
      
      // Add major-specific interests if available
      if (_selectedMajor != null) {
        if (_selectedMajor!.contains('Computer') || _selectedMajor!.contains('Engineering')) {
          defaultInterests.addAll(['Technology', 'Programming', 'Innovation']);
        } else if (_selectedMajor!.contains('Business') || _selectedMajor!.contains('Economics')) {
          defaultInterests.addAll(['Entrepreneurship', 'Finance', 'Leadership']);
        } else if (_selectedMajor!.contains('Art') || _selectedMajor!.contains('Design')) {
          defaultInterests.addAll(['Creative Arts', 'Design', 'Visual Arts']);
        } else if (_selectedMajor!.contains('Science') || _selectedMajor!.contains('Biology')) {
          defaultInterests.addAll(['Research', 'Science', 'Healthcare']);
        }
      }
      
      // Filter to ensure all interests exist in the available options
      for (final interest in defaultInterests) {
        if (_interestOptions.contains(interest) && _selectedInterests.length < _maxInterests) {
          _selectedInterests.add(interest);
        }
      }
    });
    
    // Continue to next page
    _nextPage();
  }
}

// Full screen page for Verified+ selection
class _VerifiedPlusPage extends StatefulWidget {
  final List<Club> clubs;
  final bool isLoading;
  final String? selectedClub;
  final String? selectedClubRole;
  final Function(String clubId, String role) onSelectClub;
  final Future<List<Club>> Function() onFetchClubs;

  const _VerifiedPlusPage({
    Key? key,
    required this.clubs,
    required this.isLoading,
    this.selectedClub,
    this.selectedClubRole,
    required this.onSelectClub,
    required this.onFetchClubs,
  }) : super(key: key);

  @override
  State<_VerifiedPlusPage> createState() => _VerifiedPlusPageState();
}

class _VerifiedPlusPageState extends State<_VerifiedPlusPage> {
  List<Club> _clubs = [];
  List<Club> _filteredClubs = [];
  bool _isLoading = false;
  String? _selectedClub;
  String? _selectedRole;
  String _searchQuery = '';
  final List<String> clubRoles = [
    'President',
    'Vice President',
    'Treasurer',
    'Secretary',
    'Member (Non-officer)',
  ];

  @override
  void initState() {
    super.initState();
    _clubs = widget.clubs;
    _filteredClubs = widget.clubs;
    _isLoading = widget.isLoading;
    _selectedClub = widget.selectedClub;
    _selectedRole = widget.selectedClubRole;

    if (_clubs.isEmpty) {
      _loadClubs();
    }
  }

  Future<void> _loadClubs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final clubs = await widget.onFetchClubs();
      if (mounted) {
        setState(() {
          _clubs = clubs;
          _filteredClubs = clubs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading clubs: $e')),
        );
      }
    }
  }

  void _filterClubs(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredClubs = _clubs;
      } else {
        // Use more sophisticated search algorithm from the original implementation
        final searchTerms = query
            .toLowerCase()
            .split(' ')
            .where((term) => term.isNotEmpty)
            .toList();

        _filteredClubs = _clubs.where((club) {
          // Calculate relevance score based on different match types
          int relevanceScore = 0;
          final clubName = club.name.toLowerCase();
          final clubDescription = club.description.toLowerCase();
          final clubTags = club.tags.join(' ').toLowerCase();

          // Check each search term
          for (final term in searchTerms) {
            // Exact club name match (highest relevance)
            if (clubName == term) {
              relevanceScore += 100;
              continue;
            }

            // Club name starts with term (high relevance)
            if (clubName.startsWith(term)) {
              relevanceScore += 50;
              continue;
            }

            // Club name contains the term (medium relevance)
            if (clubName.contains(term)) {
              relevanceScore += 25;
              continue;
            }

            // Description or tags contain the term (lower relevance)
            if (clubDescription.contains(term) || clubTags.contains(term)) {
              relevanceScore += 10;
              continue;
            }
          }

          // Return true if the club has any relevance
          return relevanceScore > 0;
        }).toList();

        // Sort by relevance
        _filteredClubs.sort((a, b) {
          // First sort by exact name match
          if (a.name.toLowerCase() == query.toLowerCase()) return -1;
          if (b.name.toLowerCase() == query.toLowerCase()) return 1;

          // Then sort by name contains
          final aContains = a.name.toLowerCase().contains(query.toLowerCase());
          final bContains = b.name.toLowerCase().contains(query.toLowerCase());
          if (aContains && !bContains) return -1;
          if (!aContains && bContains) return 1;

          // Finally sort alphabetically
          return a.name.compareTo(b.name);
        });
      }
    });
  }

  void _setSelectedClub(String clubId) {
    setState(() {
      _selectedClub = clubId;
    });
  }

  void _completeSelection(BuildContext context) {
    if (_selectedClub != null) {
      // Always use 'Member' as the default role
      widget.onSelectClub(_selectedClub!, 'Member');
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an organization')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive adjustments
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        title: Row(
          children: [
            // Remove container around icon for VerifiedPlus
            const Icon(
              Icons.verified,
              color: AppColors.gold,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Verified+ Leadership',
                style: GoogleFonts.outfit(
                  fontSize: 18, // Slightly smaller for better fit on mobile
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
          iconSize: 24, // Good size for touch target
        ),
      ),
      body: SafeArea(
        // Add SafeArea to handle notches and system UI
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(
                'Select your organization and role to get verified as a club leader.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.gold),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search field - made bigger for easier tapping on mobile
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            height: 48, // Taller for better touch target
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  color: Colors.white.withOpacity(0.6),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Search any organization...',
                                      hintStyle: GoogleFonts.inter(
                                        color: Colors.white.withOpacity(0.4),
                                        fontSize: 15,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 14),
                                      // Remove all borders
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                                      // Match container color
                                      fillColor: Colors.white.withOpacity(0.05),
                                      filled: true,
                                    ),
                                    onChanged: _filterClubs,
                                  ),
                                ),
                                if (_searchQuery.isNotEmpty)
                                  IconButton(
                                    icon: Icon(
                                      Icons.close,
                                      color: Colors.white.withOpacity(0.6),
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _searchQuery = '';
                                        _filteredClubs = _clubs;
                                      });
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Club list
                          Expanded(
                            child: _filteredClubs.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search_off,
                                          color: Colors.white.withOpacity(0.4),
                                          size: 48,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No organizations found',
                                          style: GoogleFonts.inter(
                                            color: Colors.white70,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Try a different search term',
                                          style: GoogleFonts.inter(
                                            color: Colors.white38,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _filteredClubs.length,
                                    itemBuilder: (context, index) {
                                      final club = _filteredClubs[index];
                                      final isSelected =
                                          _selectedClub == club.id;

                                      return InkWell(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          _setSelectedClub(club.id);

                                          // Auto-set role to Member since we're not asking
                                          setState(() {
                                            _selectedRole = 'Member';
                                          });
                                        },
                                        child: Container(
                                          margin:
                                              const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.gold
                                                    .withOpacity(0.1)
                                                : Colors.white
                                                    .withOpacity(0.05),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColors.gold
                                                  : Colors.transparent,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                isSelected
                                                    ? Icons.check_circle
                                                    : Icons.circle_outlined,
                                                color: isSelected
                                                    ? AppColors.gold
                                                    : Colors.white54,
                                                size: 24,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      club.name,
                                                      style: GoogleFonts.inter(
                                                        color: isSelected
                                                            ? AppColors.gold
                                                            : Colors.white,
                                                        fontSize: 15,
                                                        fontWeight: isSelected
                                                            ? FontWeight.w600
                                                            : FontWeight.normal,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),

                          // Remove role selection dropdown and only show confirm button when a club is selected
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedClub != null && _selectedRole != null)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _completeSelection(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      'Confirm',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
