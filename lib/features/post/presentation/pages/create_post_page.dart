import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_theme.dart';
import 'package:hive_ui/widgets/hive_app_bar.dart';

/// A page for creating new posts using HiveLab
class CreatePostPage extends ConsumerStatefulWidget {
  const CreatePostPage({Key? key}) : super(key: key);

  @override
  ConsumerState<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends ConsumerState<CreatePostPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _createPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Implement HiveLab integration for post creation
      // This will be implemented once HiveLab is ready

      HapticFeedback.mediumImpact();
      if (mounted) {
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
        title: 'Create Post',
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
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: AppColors.white),
              decoration: const InputDecoration(
                hintText: 'Title',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.gold),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.gold, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentController,
              style: const TextStyle(color: AppColors.white),
              decoration: const InputDecoration(
                hintText: 'What\'s on your mind?',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.gold),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.gold),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.gold, width: 2),
                ),
              ),
              maxLines: 10,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter some content';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // TODO: Add HiveLab integration components here
            // This section will be implemented once HiveLab is ready
          ],
        ),
      ),
    );
  }
} 