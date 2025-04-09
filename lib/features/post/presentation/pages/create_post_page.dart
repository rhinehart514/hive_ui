import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_theme.dart';
import 'package:hive_ui/widgets/hive_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/providers/profile_provider.dart';
import '../../domain/models/hivelab_post.dart';
import '../../domain/providers/hivelab_post_providers.dart';

/// A page for creating new HIVELab posts (similar to X/Twitter)
class CreatePostPage extends ConsumerStatefulWidget {
  const CreatePostPage({Key? key}) : super(key: key);

  @override
  ConsumerState<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends ConsumerState<CreatePostPage> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  bool _isLoading = false;
  HiveLabPostCategory _selectedCategory = HiveLabPostCategory.featureRequest; // Default category
  
  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _createPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('You must be logged in to create a post');
      }
      
      // Get user profile
      final userProfile = ref.read(profileProvider).profile;
      if (userProfile == null) {
        throw Exception('Profile not found');
      }
      
      // Create post using the provider
      final success = await ref.read(hiveLabPostsProvider.notifier).createPost(
        content: _contentController.text,
        category: _selectedCategory,
        userId: user.uid,
        userName: userProfile.displayName,
        userImage: userProfile.profileImageUrl,
      );
      
      if (!success) {
        throw Exception('Failed to create post');
      }
      
      HapticFeedback.mediumImpact();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Your ${_selectedCategory.displayName.toLowerCase()} has been posted to HIVELab!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(); // Return to feed after successful post creation
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: HiveAppBar(
        title: 'Create HIVE Post',
        centerTitle: true,
        useGlassmorphism: true,
        showBackButton: true,
        showBottomBorder: true,
        titleStyle: AppTheme.displaySmall.copyWith(
          color: AppColors.white,
        ),
        backgroundColor: AppColors.black.withOpacity(0.2),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: TextButton(
                onPressed: _createPost,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.gold,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Post'),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // HIVELab intro section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gold.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.black,
                      border: Border.all(
                        color: AppColors.gold,
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.science_outlined,
                      color: AppColors.gold,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HIVE LAB',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Share your ideas, report bugs, or suggest features for HIVE',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Post content text field
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    AppColors.gold.withOpacity(0.3),
                    AppColors.gold.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextFormField(
                  controller: _contentController,
                  style: const TextStyle(color: AppColors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'What\'s on your mind? Share your thoughts, ideas, or bug reports...',
                    hintStyle: TextStyle(color: AppColors.white.withOpacity(0.5), fontSize: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                  maxLines: 8,
                  minLines: 5,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter some content';
                    }
                    if (value.length < 10) {
                      return 'Post must be at least 10 characters';
                    }
                    return null;
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Category selection
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CATEGORY',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white.withOpacity(0.7),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Category chips
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: HiveLabPostCategory.values.map((category) {
                    final isSelected = _selectedCategory == category;
                    
                    // Different colors for different categories
                    Color chipColor;
                    IconData chipIcon;
                    
                    switch (category) {
                      case HiveLabPostCategory.bug:
                        chipColor = Colors.redAccent;
                        chipIcon = Icons.bug_report;
                        break;
                      case HiveLabPostCategory.featureRequest:
                        chipColor = Colors.greenAccent;
                        chipIcon = Icons.lightbulb;
                        break;
                      case HiveLabPostCategory.chaos:
                        chipColor = Colors.purpleAccent;
                        chipIcon = Icons.auto_awesome;
                        break;
                    }
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                        HapticFeedback.lightImpact();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? chipColor.withOpacity(0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? chipColor : AppColors.white.withOpacity(0.3),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              chipIcon,
                              size: 18,
                              color: isSelected ? chipColor : AppColors.white.withOpacity(0.7),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              category.displayName,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: isSelected ? chipColor : AppColors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
} 