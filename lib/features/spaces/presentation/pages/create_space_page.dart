import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/presentation/providers/create_space_provider.dart';
import 'package:hive_ui/features/spaces/presentation/providers/space_providers.dart';
import 'package:hive_ui/services/analytics_service.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/widgets/hive_app_bar.dart';
import 'package:hive_ui/providers/user_providers.dart';
import 'package:hive_ui/core/navigation/routes.dart';

class CreateSpacePage extends ConsumerStatefulWidget {
  const CreateSpacePage({super.key});

  @override
  ConsumerState<CreateSpacePage> createState() => _CreateSpacePageState();
}

class _CreateSpacePageState extends ConsumerState<CreateSpacePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Always set space type to hiveExclusive
  final SpaceType _spaceType = SpaceType.hiveExclusive;
  final bool _selectedPrivate = true; // This will be forced to true by business rules
  bool _showErrors = false;
  bool _isCreating = false;
  String? _nameErrorText;
  final List<String> _selectedInterests = [];

  // Map space types to icon code points
  final Map<SpaceType, int> _spaceTypeIcons = {
    SpaceType.studentOrg: Icons.group.codePoint,
    SpaceType.universityOrg: Icons.account_balance.codePoint,
    SpaceType.campusLiving: Icons.home.codePoint,
    SpaceType.fraternityAndSorority: Icons.diversity_3.codePoint,
    SpaceType.hiveExclusive: Icons.verified.codePoint,
    SpaceType.organization: Icons.business.codePoint,
    SpaceType.project: Icons.assignment.codePoint,
    SpaceType.event: Icons.event.codePoint,
    SpaceType.community: Icons.forum.codePoint,
    SpaceType.other: Icons.category.codePoint,
  };
  
  // Map space types to icon data for UI
  IconData _getIconForSpaceType(SpaceType type) {
    switch (type) {
      case SpaceType.studentOrg:
        return Icons.group;
      case SpaceType.universityOrg:
        return Icons.account_balance;
      case SpaceType.campusLiving:
        return Icons.home;
      case SpaceType.fraternityAndSorority:
        return Icons.diversity_3;
      case SpaceType.hiveExclusive:
        return Icons.verified;
      case SpaceType.organization:
        return Icons.business;
      case SpaceType.project:
        return Icons.assignment;
      case SpaceType.event:
        return Icons.event;
      case SpaceType.community:
        return Icons.forum;
      case SpaceType.other:
        return Icons.category;
    }
  }

  // Custom filter for interests to match requirements
  final List<String> _filteredInterestOptions = [
    'Academic',
    'Social',
    'Personal Growth',
    'Creative',
    'Artistic',
    'Gaming',
    'Fandoms',
    'Sports',
    'Fitness',
    'Service',
    'Leadership',
    'Lifestyle',
    'Innovation',
    'Tech',
    'Faith',
    'Philosophy',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }
  
  Future<void> _onNameChanged() async {
    // Don't check too frequently - only if name has at least 3 characters
    if (_nameController.text.length >= 3) {
      await ref.read(createSpaceProvider.notifier).checkSpaceNameAvailability(_nameController.text);
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Refresh all space-related providers to ensure the created space appears in lists
  void _refreshSpaceProviders() {
    // Use the provider references from space_providers.dart
    ref.refresh(spacesProvider);
    ref.refresh(userSpacesProvider);
    ref.refresh(hierarchicalSpacesProvider);
    ref.refresh(hiveExclusiveSpacesProvider);
    
    // Also refresh the user provider to ensure followedSpaces are up-to-date
    ref.read(userProvider.notifier).refreshUserData();
  }

  /// Attempts to create the space with the given data
  Future<void> _createSpace() async {
    // Validate form
    if (_formKey.currentState?.validate() != true || _selectedInterests.isEmpty) {
      if (mounted) {
        setState(() => _showErrors = true);
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isCreating = true;
      });
    }

    try {
      // First check if space name is available
      await ref.read(createSpaceProvider.notifier).checkSpaceNameAvailability(_nameController.text);

      // Check if we're still mounted after the async operation
      if (!mounted) return;

      if (ref.read(createSpaceProvider).isNameAvailable == false) {
        setState(() {
          _isCreating = false;
          _nameErrorText = 'This space name is already taken. Please try another one.';
        });
        return;
      }

      // Create the space
      await ref.read(createSpaceProvider.notifier).createSpace(
        name: _nameController.text,
        description: _descriptionController.text,
        spaceType: _spaceType,
        tags: _selectedInterests,
        iconCodePoint: _spaceTypeIcons[_spaceType] ?? Icons.group.codePoint,
        isHiveExclusive: true, // Set HIVE exclusive flag to true
      );

      // Check if we're still mounted after the async operation
      if (!mounted) return;

      // Check for errors
      final state = ref.read(createSpaceProvider);
      if (state.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create space: ${state.errorMessage}'),
            backgroundColor: Colors.red[700],
          ),
        );
        return;
      }

      // Get the created space to navigate to it
      final createdSpace = state.createdSpace;
      
      // Log success
      AnalyticsService.logEvent(
        'space_created',
        parameters: {
          'space_name': _nameController.text,
          'space_type': _spaceType.toString(),
          'is_private': true, // Always private per business rule
          'interests_count': _selectedInterests.length,
          'space_id': createdSpace?.id ?? '',
        },
      );

      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Space created successfully!'),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 2),
        ),
      );

      // If we have a created space, navigate to its details page
      if (createdSpace != null) {
        // Invalidate the relevant providers to refresh space lists
        _refreshSpaceProviders();
        
        // Wait a short time to show the snackbar before navigating
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          // Navigate to the space details page
          GoRouter.of(context).pushReplacement(AppRoutes.getSpaceDetailPath('hive_exclusive', createdSpace.id));
        });
      } else {
        // If no space was returned, just go back to spaces list
        GoRouter.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create space: ${e.toString()}'),
          backgroundColor: Colors.red[700],
        ),
      );
    } finally {
      // Reset state
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
      ref.read(createSpaceProvider.notifier).reset();
    }
  }

  Widget _buildInterestSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Interests',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select tags that best describe your space (at least 1)',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 16),
        if (_showErrors && _selectedInterests.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Please select at least one interest',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.red[300],
              ),
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 12,
          children: _filteredInterestOptions.map((interest) {
            final isSelected = _selectedInterests.contains(interest);
            return InkWell(
              onTap: () {
                if (!mounted) return;
                HapticFeedback.selectionClick();
                setState(() {
                  if (isSelected) {
                    _selectedInterests.remove(interest);
                  } else {
                    _selectedInterests.add(interest);
                  }
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.gold.withOpacity(0.2) : Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.gold : Colors.white24,
                    width: isSelected ? 1 : 0.5,
                  ),
                ),
                child: Text(
                  interest,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isSelected ? AppColors.gold : Colors.white,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Space Name
  Widget _buildSpaceNameField() {
    final createSpaceState = ref.watch(createSpaceProvider);
    final bool isCheckingName = createSpaceState.isCheckingName;
    final bool? isNameAvailable = createSpaceState.isNameAvailable;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _nameController,
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Space Name',
            labelStyle: GoogleFonts.inter(color: Colors.white70),
            hintText: 'Enter a name for your space',
            hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
            prefixIcon: Icon(
              Icons.group,
              color: AppColors.gold.withOpacity(0.7),
            ),
            suffixIcon: _nameController.text.length >= 3
                ? isCheckingName 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : isNameAvailable != null
                        ? Icon(
                            isNameAvailable ? Icons.check_circle : Icons.error,
                            color: isNameAvailable ? Colors.green : Colors.red[300],
                          )
                        : null
                : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isNameAvailable == false 
                    ? Colors.red[300]! 
                    : isNameAvailable == true
                        ? Colors.green
                        : Colors.white24,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isNameAvailable == false 
                    ? Colors.red[300]! 
                    : isNameAvailable == true
                        ? Colors.green
                        : AppColors.gold,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red[300]!),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red[300]!),
            ),
            errorStyle: GoogleFonts.inter(
              color: Colors.red[300],
              fontSize: 12,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a space name';
            }
            if (value.length < 3) {
              return 'Name must be at least 3 characters';
            }
            if (isNameAvailable == false) {
              return 'This name is already taken';
            }
            return null;
          },
          textInputAction: TextInputAction.next,
        ),
        if (isNameAvailable == false && _nameController.text.length >= 3)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Text(
              'This name is already taken. Please choose another.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.red[300],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createSpaceProvider);
    final nameAvailability = state.isNameAvailable;
    final isCheckingName = state.isCheckingName;
    final isNameChecked = nameAvailability != null;
    
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: HiveAppBar(
        title: 'Create Space',
        style: HiveAppBarStyle.standard,
        actions: [
          // Badge to show HIVE exclusive status
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.gold,
                width: 1,
              ),
            ),
            child: Text(
              'HIVE EXCLUSIVE',
              style: GoogleFonts.outfit(
                color: AppColors.gold,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.grey[900]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Introduction text
                Text(
                  'Create Your Own Space',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Fill in the details below to create a new space where people can connect and collaborate.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 32),

                // Space Name
                _buildSpaceNameField(),
                const SizedBox(height: 24),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  style: GoogleFonts.inter(color: Colors.white),
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: GoogleFonts.inter(color: Colors.white70),
                    hintText: 'What is this space about?',
                    hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(bottom: 64),
                      child: Icon(
                        Icons.description,
                        color: AppColors.gold.withOpacity(0.7),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.gold),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red[300]!),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red[300]!),
                    ),
                    errorStyle: GoogleFonts.inter(
                      color: Colors.red[300],
                      fontSize: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    if (value.length < 10) {
                      return 'Description must be at least 10 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // HIVE Exclusive Badge (replacing space type selection)
                _buildHiveExclusiveBadge(),

                // Privacy toggle - now shows info that space will be private
                const SizedBox(height: 24),
                Text(
                  'Privacy',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Spaces must be private until they reach 10 members',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.gold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.lock,
                            color: AppColors.gold,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Private Space',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: true, // Always true per business rule
                        onChanged: null, // Disabled
                        activeColor: AppColors.gold,
                        activeTrackColor: AppColors.gold.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),

                // Interest selector
                _buildInterestSelector(),

                // Create button
                const SizedBox(height: 40),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isCreating ? null : _createSpace,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 3,
                    ),
                    child: _isCreating
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_circle),
                              const SizedBox(width: 12),
                              Text(
                                'Create Space',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // New widget to display HIVE Exclusive badge instead of space type selection
  Widget _buildHiveExclusiveBadge() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        const SizedBox(height: 24),
        Text(
          'Space Type',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        
        // HIVE Exclusive badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gold),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.verified,
                color: AppColors.gold,
                size: 24,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HIVE Exclusive',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'All new spaces are HIVE exclusive',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
} 