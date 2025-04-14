import 'package:flutter/material.dart'
    hide RefreshIndicator, RefreshIndicatorState;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_theme.dart';
import 'package:hive_ui/providers/profile_provider.dart';
import 'package:hive_ui/models/user_profile.dart';
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
import 'package:hive_ui/features/auth/presentation/components/onboarding/name_page.dart';
import 'package:hive_ui/features/auth/presentation/components/onboarding/year_page.dart';
import 'package:hive_ui/features/auth/presentation/components/onboarding/field_page.dart';
import 'package:hive_ui/features/auth/presentation/components/onboarding/residence_page.dart';
import 'package:hive_ui/features/auth/presentation/components/onboarding/interests_page.dart';
import 'package:hive_ui/features/auth/presentation/components/onboarding/account_tier_page.dart';

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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No authenticated user found'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isCompletingOnboarding = false;
        });
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
      try {
      await _firestore.collection('users').doc(userId).set(profile.toJson());
      } catch (e) {
        debugPrint('Error saving profile to Firestore: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving profile to server: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isCompletingOnboarding = false;
        });
        return;
      }
      // Save to local preferences 
      await UserPreferencesService.storeProfile(profile);
      // Mark onboarding as completed
      await UserPreferencesService.setOnboardingCompleted(true);
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing onboarding: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic, // iOS-style deceleration curve
      );
      return;
    }

    // Get current page and determine target page
    int currentPage = _pageController.page?.round() ?? 0;
    int targetPage = currentPage + 1;

    debugPrint('Navigating from page $currentPage to page $targetPage');

    // Normal page navigation with improved iOS-style animation
    _pageController.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic, // iOS-style deceleration curve
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
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic, // iOS-style deceleration curve
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
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic, // iOS-style deceleration curve
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
          // Add a page transition effect similar to iOS
          pageSnapping: true,
          clipBehavior: Clip.none,
          children: [
            NamePage(
              firstNameController: _firstNameController,
              lastNameController: _lastNameController,
              onContinue: () {
                // Only proceed if names are valid
                    if (_isNameValid()) {
                      _nextPage();
                } else {
                  // Provide feedback that fields need to be filled
                  HapticFeedback.mediumImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter both first and last name'),
                      backgroundColor: Colors.redAccent,
                      duration: Duration(seconds: 2),
      ),
    );
  }
              },
              isNameValid: _isNameValid(),
              progressIndicator: _buildProgressIndicator(6, 0),
            ),
            YearPage(
              selectedYear: _selectedYear,
              years: _years,
              onYearSelected: (year) {
                setState(() => _selectedYear = year);
              },
              progressIndicator: _buildProgressIndicator(6, 1),
              onContinue: () {
                if (_selectedYear != null) {
                    _nextPage();
                } else {
                  HapticFeedback.mediumImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select your current year'),
                      backgroundColor: Colors.redAccent,
                      duration: Duration(seconds: 2),
      ),
    );
  }
              },
            ),
            FieldPage(
              selectedMajor: _selectedMajor,
              filteredFields: _filteredFields,
              onMajorSelected: (major) {
                setState(() => _selectedMajor = major);
              },
              progressIndicator: _buildProgressIndicator(6, 2),
              onContinue: () {
                if (_selectedMajor != null) {
                  _nextPage();
                            } else {
                                HapticFeedback.mediumImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                      content: Text('Please select your major/field'),
                      backgroundColor: Colors.redAccent,
                            duration: Duration(seconds: 2),
                          ),
                        );
                }
              },
            ),
            ResidencePage(
              selectedResidence: _selectedResidence,
              filteredResidences: _filteredResidences,
              onResidenceSelected: (res) {
                setState(() => _selectedResidence = res);
              },
              progressIndicator: _buildProgressIndicator(6, 3),
              onContinue: () {
                if (_selectedResidence != null) {
                  _nextPage();
                    } else {
                  HapticFeedback.mediumImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                      content: Text('Please select your residence'),
                      backgroundColor: Colors.redAccent,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
            InterestsPage(
              selectedInterests: _selectedInterests,
              interestOptions: _interestOptions,
              onInterestToggle: _toggleInterest,
              progressIndicator: _buildProgressIndicator(6, 4),
              onContinue: () {
                if (_selectedInterests.length >= _minInterests) {
                  _nextPage();
                } else {
                  HapticFeedback.mediumImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please select at least $_minInterests interests'),
                      backgroundColor: Colors.redAccent,
                      duration: const Duration(seconds: 2),
      ),
    );
  }
              },
              minInterests: _minInterests,
              maxInterests: _maxInterests,
            ),
            AccountTierPage(
              selectedTier: _selectedTier,
              availableTiers: AccountTier.values,
              onTierSelected: (tier) {
                setState(() => _selectedTier = tier);
              },
              progressIndicator: _buildProgressIndicator(6, 5),
              onContinue: _completeOnboarding,
            ),
          ],
        ),
      ),
    );
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
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            width: isCurrentPage ? 24 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isActive ? Colors.white : Colors.white24,
              boxShadow: isActive ? [
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ] : null,
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

  // Check if the name fields are valid
  bool _isNameValid() {
    // Simple validation: Both fields need to have content
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    
    // Debug output to help diagnose the issue
    debugPrint('Name validation check: First name: "$firstName", Last name: "$lastName"');
    debugPrint('Is name valid? ${firstName.isNotEmpty && lastName.isNotEmpty}');
    
    return firstName.isNotEmpty && lastName.isNotEmpty;
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

  // Add the missing _fetchClubs method
  Future<void> _fetchClubs() async {
    setState(() {
      _isLoadingClubs = true;
    });
    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collectionGroup('spaces')
          .orderBy('name')
          .limit(50)
          .get(const GetOptions(source: Source.serverAndCache));
      final List<Club> allClubs = [];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final pathParts = doc.reference.path.split('/');
          final spaceType = pathParts.length > 2 ? pathParts[1] : 'general';
          final club = Club(
            id: doc.id,
            name: data['name'] ?? 'Unknown Club',
            description: data['description'] ?? '',
            category: data['category'] ?? spaceType,
            memberCount: data['memberCount'] ?? data['metrics']?['memberCount'] ?? 0,
            status: data['status'] ?? 'active',
            icon: Icons.group,
            createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            imageUrl: data['imageUrl'] ?? data['bannerUrl'],
            bannerUrl: data['bannerUrl'],
            tags: (data['tags'] as List<dynamic>?)?.map((tag) => tag.toString()).toList() ?? [],
          );
          allClubs.add(club);
        } catch (e) {
          debugPrint('Error parsing club document \\${doc.id}: \\$e');
        }
      }
      allClubs.sort((a, b) => a.name.compareTo(b.name));
      setState(() {
        _clubs = allClubs;
        _filteredClubs = allClubs;
        _isLoadingClubs = false;
      });
    } catch (e) {
      debugPrint('Error fetching clubs: \\$e');
      setState(() {
        _isLoadingClubs = false;
      });
    }
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
