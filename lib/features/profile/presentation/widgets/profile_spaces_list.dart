import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/providers/space_providers.dart';
import 'package:hive_ui/providers/user_providers.dart';
import 'package:hive_ui/services/analytics_service.dart';
import 'package:hive_ui/services/space_service.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A widget that displays a list of spaces for a user profile
class ProfileSpacesList extends ConsumerWidget {
  /// The user profile
  final UserProfile profile;
  
  /// Whether this is the current user's profile
  final bool isCurrentUser;
  
  /// Callback when the action button is pressed
  final VoidCallback? onActionPressed;

  const ProfileSpacesList({
    super.key,
    required this.profile,
    required this.isCurrentUser,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if this is the current user to use the right provider
    if (isCurrentUser) {
      // For current user, use the userSpacesProvider for "MY spaces"
      return _CurrentUserSpacesList(
        onActionPressed: onActionPressed,
      );
    } else {
      // For other users, use the profile followedSpaces list
    final List<String> followedSpaces = profile.followedSpaces;
    
    // Show empty state if no followed spaces
    if (followedSpaces.isEmpty) {
      return _buildProfileEmptyState(context);
    }
    
    return _SpacesList(
      followedSpaceIds: followedSpaces,
      isCurrentUser: isCurrentUser,
      onActionPressed: onActionPressed,
    );
    }
  }

  /// Builds the empty state when no spaces are followed
  Widget _buildProfileEmptyState(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.4,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.grey[850]!.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.group,
                  color: Colors.white.withOpacity(0.7),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Spaces Yet',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                isCurrentUser
                    ? 'Follow spaces to see them here'
                    : '${profile.username} hasn\'t followed any spaces yet',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              if (isCurrentUser && onActionPressed != null) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onActionPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Explore Spaces',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A widget that displays the current user's joined spaces
class _CurrentUserSpacesList extends StatefulWidget {
  /// Callback when the action button is pressed
  final VoidCallback? onActionPressed;

  const _CurrentUserSpacesList({
    this.onActionPressed,
  });

  @override
  State<_CurrentUserSpacesList> createState() => _CurrentUserSpacesListState();
}

class _CurrentUserSpacesListState extends State<_CurrentUserSpacesList> {
  bool _isRefreshing = false;
  
  @override
  void initState() {
    super.initState();
    // Debug user clubs on initialization after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _debugUserClubs();
      // Force refresh on initial load to ensure we have the latest data
      _refreshSpaces(showSnackbar: false);
    });
  }
  
  Future<void> _debugUserClubs() async {
    // Get current user data
    try {
      final userData = ProviderScope.containerOf(context).read(userProvider);
      debugPrint('🔍 DEBUG ProfileSpacesList - Current user data: ${userData?.id}');
      
      if (userData != null) {
        debugPrint('🔍 DEBUG ProfileSpacesList - User has ${userData.joinedClubs.length} joined clubs: ${userData.joinedClubs}');
        
        // Check for duplicates
        final uniqueJoinedClubs = userData.joinedClubs.toSet().toList();
        if (uniqueJoinedClubs.length < userData.joinedClubs.length) {
          debugPrint('⚠️ DEBUG ProfileSpacesList - Found ${userData.joinedClubs.length - uniqueJoinedClubs.length} duplicate IDs in joinedClubs');
        }
        
        // Check Firestore directly
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          try {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
            
            if (userDoc.exists && userDoc.data() != null) {
              final data = userDoc.data()!;
              
              if (data['followedSpaces'] != null && data['followedSpaces'] is List) {
                final followedSpaces = List<String>.from(data['followedSpaces']);
                debugPrint('🔍 DEBUG ProfileSpacesList - Firestore followedSpaces: $followedSpaces');
                
                // Check for duplicates in followedSpaces
                final uniqueFollowedSpaces = followedSpaces.toSet().toList();
                if (uniqueFollowedSpaces.length < followedSpaces.length) {
                  debugPrint('⚠️ DEBUG ProfileSpacesList - Found ${followedSpaces.length - uniqueFollowedSpaces.length} duplicate IDs in followedSpaces');
                }
                
                // Check if any of the joinedClubs are missing from followedSpaces
                final missingSpaces = userData.joinedClubs
                    .where((clubId) => !followedSpaces.contains(clubId))
                    .toList();
                
                if (missingSpaces.isNotEmpty) {
                  debugPrint('⚠️ DEBUG ProfileSpacesList - Found ${missingSpaces.length} clubs missing from followedSpaces: $missingSpaces');
                  
                  // Show a snackbar with a fix button
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${missingSpaces.length} spaces need to be synchronized'),
                        duration: const Duration(seconds: 15),
                        action: SnackBarAction(
                          label: 'Fix Now',
                          onPressed: () => _syncSpaceFields(),
                        ),
                      ),
                    );
                  }
                }
                
                // Check if followedSpaces has entries not in joinedClubs
                final extraSpaces = followedSpaces
                    .where((spaceId) => !userData.joinedClubs.contains(spaceId))
                    .toList();
                    
                if (extraSpaces.isNotEmpty) {
                  debugPrint('⚠️ DEBUG ProfileSpacesList - Found ${extraSpaces.length} extra spaces in followedSpaces but not in joinedClubs: $extraSpaces');
                }
              } else {
                debugPrint('⚠️ DEBUG ProfileSpacesList - Firestore followedSpaces is null or not a list');
                // Offer to create the field
                if (userData.joinedClubs.isNotEmpty && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('followedSpaces field is missing in Firestore'),
                      duration: const Duration(seconds: 15),
                      action: SnackBarAction(
                        label: 'Fix Now',
                        onPressed: () => _syncSpaceFields(),
                      ),
                    ),
                  );
                }
              }
              
              if (data['joinedClubs'] != null && data['joinedClubs'] is List) {
                final joinedClubs = List<String>.from(data['joinedClubs']);
                debugPrint('🔍 DEBUG ProfileSpacesList - Firestore joinedClubs: $joinedClubs');
                
                // Check for duplicates in joinedClubs in Firestore
                final uniqueJoinedClubsFirestore = joinedClubs.toSet().toList();
                if (uniqueJoinedClubsFirestore.length < joinedClubs.length) {
                  debugPrint('⚠️ DEBUG ProfileSpacesList - Found ${joinedClubs.length - uniqueJoinedClubsFirestore.length} duplicate IDs in Firestore joinedClubs');
                }
              }
            } else {
              debugPrint('⚠️ DEBUG ProfileSpacesList - User document not found or empty');
            }
          } catch (e) {
            debugPrint('❌ DEBUG ProfileSpacesList - Error checking Firestore: $e');
          }
        }
      } else {
        debugPrint('⚠️ DEBUG ProfileSpacesList - No user data available');
      }
    } catch (e) {
      debugPrint('❌ DEBUG ProfileSpacesList - Error in debugging clubs: $e');
    }
  }
  
  /// Synchronize joinedClubs and followedSpaces fields in the user document
  Future<void> _syncSpaceFields() async {
    try {
      setState(() {
        _isRefreshing = true;
      });
      
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You need to be signed in to sync spaces'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Get user data from both sources
      final userData = ProviderScope.containerOf(context).read(userProvider);
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (!userDoc.exists || userDoc.data() == null || userData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User data not available'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      final data = userDoc.data()!;
      
      // Get all space IDs from both fields
      List<String> followedSpaces = [];
      if (data['followedSpaces'] != null && data['followedSpaces'] is List) {
        followedSpaces = List<String>.from(data['followedSpaces']);
      }
      
      List<String> joinedClubsFirestore = [];
      if (data['joinedClubs'] != null && data['joinedClubs'] is List) {
        joinedClubsFirestore = List<String>.from(data['joinedClubs']);
      }
      
      // Merge and deduplicate
      final allSpaceIds = {...followedSpaces, ...joinedClubsFirestore, ...userData.joinedClubs}.toList();
      
      // Update both fields with the merged, deduplicated list
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'joinedClubs': allSpaceIds,
        'followedSpaces': allSpaceIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Show success message
      int fixedSpaces = (followedSpaces.toSet().difference(allSpaceIds.toSet())).length + 
                         (joinedClubsFirestore.toSet().difference(allSpaceIds.toSet())).length +
                         (userData.joinedClubs.toSet().difference(allSpaceIds.toSet())).length;
                         
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Synchronized ${allSpaceIds.length} spaces across all fields! Fixed $fixedSpaces inconsistencies.'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // Refresh providers
      ProviderScope.containerOf(context).refresh(userProvider);
      ProviderScope.containerOf(context).refresh(userSpacesProvider);
      
      // Wait for the refresh
      await Future.delayed(const Duration(seconds: 1));
      
      // Update UI
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error synchronizing space fields: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error syncing spaces: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }
  
  Future<void> _refreshSpaces({bool showSnackbar = true}) async {
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      // Get the current container for the context
      final container = ProviderScope.containerOf(context);
      
      // Force invalidate all providers that could affect spaces
      container.refresh(userProvider);
      container.refresh(userSpacesProvider);
      
      if (showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Refreshing your spaces...'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      
      // Wait for the refresh
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      debugPrint('Error refreshing spaces: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer to access the providers
    return Consumer(
      builder: (context, ref, child) {
        // Get user data to debug joined clubs
        final userData = ref.watch(userProvider);
        final joinedClubs = userData?.joinedClubs ?? [];
        
        // Check for duplicate space IDs
        final uniqueClubIds = joinedClubs.toSet().toList();
        final hasDuplicates = uniqueClubIds.length < joinedClubs.length;
        final duplicateCount = hasDuplicates ? joinedClubs.length - uniqueClubIds.length : 0;
        
        // Use the userSpacesProvider from providers/space_providers.dart
        final userSpacesAsync = ref.watch(userSpacesProvider);
        
        return Column(
          children: [
            // Add data status indicator
            if (joinedClubs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasDuplicates)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.withOpacity(0.3))
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Found $duplicateCount duplicate space IDs in your profile',
                                  style: GoogleFonts.inter(
                                    color: Colors.orange,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: Center(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isRefreshing ? null : () => _refreshSpaces(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gold,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              icon: _isRefreshing 
                                ? const SizedBox(
                                    width: 16, 
                                    height: 16, 
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.refresh, size: 16),
                              label: Text(_isRefreshing ? 'Refreshing...' : 'Refresh'),
                            ),
                            if (hasDuplicates)
                              ElevatedButton.icon(
                                onPressed: _isRefreshing ? null : () => _syncSpaceFields(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                icon: const Icon(Icons.healing, size: 16),
                                label: const Text('Fix Issues'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            userSpacesAsync.when(
              data: (spaces) {
                debugPrint('🔍 DEBUG ProfileSpacesList - userSpacesProvider returned ${spaces.length} spaces');
                
                if (spaces.isEmpty) {
                  // If we have joined clubs but no spaces, this is a data issue
                  if (joinedClubs.isNotEmpty) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red[300], size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Data Mismatch Detected',
                                      style: GoogleFonts.outfit(
                                        color: Colors.red[300],
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'You have ${joinedClubs.length} spaces in your profile but none could be loaded. This indicates a synchronization issue.',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: Center(
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: _isRefreshing ? null : () => _syncSpaceFields(),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red[300],
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                        ),
                                        icon: const Icon(Icons.sync_problem, size: 18),
                                        label: const Text('Sync Data'),
                                      ),
                                      ElevatedButton(
                                        onPressed: _isRefreshing ? null : () => _refreshSpaces(),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.gold,
                                          foregroundColor: Colors.black,
                                        ),
                                        child: _isRefreshing 
                                          ? const SizedBox(
                                              width: 20, 
                                              height: 20, 
                                              child: CircularProgressIndicator(
                                                color: Colors.black,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text('Refresh'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildEmptyState(context),
                      ],
                    );
                  }
                  
                  return _buildEmptyState(context);
                }
                
                // Use ListView.builder with no shrinkWrap for better performance when we have spaces
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: spaces.length,
                  itemBuilder: (context, index) {
                    final space = spaces[index];
                    return _buildSpaceListItem(context, space);
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(
                    color: AppColors.gold,
                  ),
                ),
              ),
              error: (error, stack) {
                debugPrint('❌ DEBUG ProfileSpacesList - Error loading user spaces: $error\n$stack');
                
                // If we have joined clubs but got an error, show recovery UI
                if (joinedClubs.isNotEmpty) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Error loading your ${joinedClubs.length} spaces',
                          style: GoogleFonts.inter(
                            color: Colors.red[300],
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          error.toString(),
                          style: GoogleFonts.inter(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isRefreshing ? null : () => _refreshSpaces(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: Colors.black,
                        ),
                        child: _isRefreshing 
                          ? const SizedBox(
                              width: 20, 
                              height: 20, 
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Try Again'),
                      ),
                    ],
                  );
                }
                
                return _buildEmptyState(context);
              },
            ),
          ],
        );
      },
    );
  }

  /// Builds the empty state when no spaces are joined
  Widget _buildEmptyState(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.4,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.grey[850]!.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.group,
                  color: Colors.white.withOpacity(0.7),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Spaces Yet',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Join spaces to see them here',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              if (widget.onActionPressed != null) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: widget.onActionPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Explore Spaces',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a space list item
  Widget _buildSpaceListItem(BuildContext context, Space space) {
    // Create a custom space card that matches the screenshot design
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Add haptic feedback
            HapticFeedback.selectionClick();
            
            try {
              // Navigate to space detail
              final clubId = Uri.encodeComponent(space.id);
              final spaceType = space.spaceType.toString().split('.').last;
              
              // Log analytics
              AnalyticsService.logEvent(
                'view_space',
                parameters: {
                  'space_id': space.id,
                  'space_name': space.name,
                  'space_type': space.spaceType.toString(),
                  'source': 'profile_spaces_list',
                },
              );
              
              // Safe navigation - check if context is still mounted
              if (!context.mounted) return;
              
              // Use a safer navigation method
              try {
                // Try to navigate using standard Navigator first
                Navigator.of(context).pushNamed(
                  '/spaces/club',
                  arguments: {'id': clubId, 'type': spaceType},
                );
              } catch (navError) {
                debugPrint('Primary navigation failed, trying fallback: $navError');
                
                // Fallback to go_router if available
                if (context.mounted) {
                  context.go('/spaces/club/$clubId');
                }
              }
            } catch (e) {
              debugPrint('Error navigating to space: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Error opening space'),
                    backgroundColor: Colors.red[700],
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Space name and icon
                Row(
                  children: [
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.group,
                          color: Colors.green,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        space.name,
                        style: GoogleFonts.inter(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.25,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Space description
                Text(
                  space.description,
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 16),

                // Space metrics
                Row(
                  children: [
                    // Members count
                    Icon(
                      Icons.people_outline,
                      size: 16,
                      color: Colors.white.withOpacity(0.4),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${space.metrics.memberCount}',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Members',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Weekly events count
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: Colors.white.withOpacity(0.4),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${space.metrics.weeklyEvents}',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Weekly Events',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),

                // Join button if not joined
                if (!space.isJoined)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: TextButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        // Use the SpaceService to join space
                        SpaceService.joinSpace(space.id).then((_) {
                          // Refresh spaces list after joining
                          _refreshSpaces(showSnackbar: false);
                          
                          // Show feedback to user
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Joined ${space.name}'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        }).catchError((e) {
                          // Handle error
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error joining space: $e'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.gold,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ).copyWith(
                        overlayColor: MaterialStateProperty.resolveWith<Color?>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.pressed)) {
                              return AppColors.gold.withOpacity(0.15);
                            }
                            return null;
                          },
                        ),
                      ),
                      child: Text(
                        'Join Space',
                        style: GoogleFonts.inter(
                          color: AppColors.gold,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A widget that displays spaces for other users
class _SpacesList extends ConsumerStatefulWidget {
  /// The IDs of spaces that the user follows
  final List<String> followedSpaceIds;
  
  /// Whether this is the current user's profile
  final bool isCurrentUser;
  
  /// Callback when the action button is pressed
  final VoidCallback? onActionPressed;

  const _SpacesList({
    required this.followedSpaceIds,
    required this.isCurrentUser,
    this.onActionPressed,
  });

  @override
  ConsumerState<_SpacesList> createState() => _SpacesListState();
}

class _SpacesListState extends ConsumerState<_SpacesList> {
  /// Spaces data
  List<Space>? _spaces;
  
  /// Loading state
  bool _isLoading = true;
  
  /// Error message
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSpaces();
  }
  
  @override
  void didUpdateWidget(_SpacesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.followedSpaceIds != widget.followedSpaceIds) {
      _loadSpaces();
    }
  }
  
  /// Load spaces data
  Future<void> _loadSpaces() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final spaces = await SpaceService.getUserSpaces(widget.followedSpaceIds);
      if (mounted) {
        setState(() {
          _spaces = spaces;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading spaces: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load spaces';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(
            color: AppColors.gold,
          ),
        ),
      );
    }
    
    // Show error message
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: GoogleFonts.inter(
                  color: Colors.red[300],
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadSpaces,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                ),
                child: Text(
                  'Try Again',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Show spaces list
    if (_spaces == null || _spaces!.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _spaces!.length,
      itemBuilder: (context, index) {
        final space = _spaces![index];
        return _buildSpaceListItem(context, space);
      },
    );
  }
  
  /// Builds the empty state when no spaces are followed
  Widget _buildEmptyState() {
    return SizedBox(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.4,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.grey[850]!.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.group,
                  color: Colors.white.withOpacity(0.7),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Spaces Yet',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Join spaces to see them here',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              if (widget.onActionPressed != null) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: widget.onActionPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Explore Spaces',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  /// Builds a space list item
  Widget _buildSpaceListItem(BuildContext context, Space space) {
    // Create a custom space card that matches the screenshot design
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Add haptic feedback
            HapticFeedback.selectionClick();
            
            try {
              // Navigate to space detail
              final clubId = Uri.encodeComponent(space.id);
              final spaceType = space.spaceType.toString().split('.').last;
              
              // Log analytics
              AnalyticsService.logEvent(
                'view_space',
                parameters: {
                  'space_id': space.id,
                  'space_name': space.name,
                  'space_type': space.spaceType.toString(),
                  'source': 'profile_spaces_list',
                },
              );
              
              // Safe navigation - check if context is still mounted
              if (!context.mounted) return;
              
              // Use a safer navigation method
              try {
                // Try to navigate using standard Navigator first
                Navigator.of(context).pushNamed(
                  '/spaces/club',
                  arguments: {'id': clubId, 'type': spaceType},
                );
              } catch (navError) {
                debugPrint('Primary navigation failed, trying fallback: $navError');
                
                // Fallback to go_router if available
                if (context.mounted) {
                  context.go('/spaces/club/$clubId');
                }
              }
            } catch (e) {
              debugPrint('Error navigating to space: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Error opening space'),
                    backgroundColor: Colors.red[700],
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Space name and icon
                Row(
                  children: [
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.group,
                          color: Colors.green,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        space.name,
                        style: GoogleFonts.inter(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.25,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Space description
                Text(
                  space.description,
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 16),

                // Space metrics
                Row(
                  children: [
                    // Members count
                    Icon(
                      Icons.people_outline,
                      size: 16,
                      color: Colors.white.withOpacity(0.4),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${space.metrics.memberCount}',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Members',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Weekly events count
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: Colors.white.withOpacity(0.4),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${space.metrics.weeklyEvents}',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Weekly Events',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),

                // Join button if not joined
                if (!space.isJoined)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: TextButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        // Use the SpaceService to join space
                        SpaceService.joinSpace(space.id).then((_) {
                          // Refresh spaces list after joining
                          _loadSpaces();
                          
                          // Show feedback to user
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Joined ${space.name}'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        }).catchError((e) {
                          // Handle error
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error joining space: $e'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.gold,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ).copyWith(
                        overlayColor: MaterialStateProperty.resolveWith<Color?>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.pressed)) {
                              return AppColors.gold.withOpacity(0.15);
                            }
                            return null;
                          },
                        ),
                      ),
                      child: Text(
                        'Join Space',
                        style: GoogleFonts.inter(
                          color: AppColors.gold,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 