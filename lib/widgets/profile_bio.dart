import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ui/theme.dart';
import 'hive_card.dart';

class ProfileBio extends StatefulWidget {
  final String? bio;
  final Function(String) onBioUpdated;

  const ProfileBio({
    super.key,
    this.bio,
    required this.onBioUpdated,
  });

  @override
  State<ProfileBio> createState() => _ProfileBioState();
}

class _ProfileBioState extends State<ProfileBio> {
  bool _isEditing = false;
  late TextEditingController _bioController;
  final FocusNode _bioFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.bio);
  }

  @override
  void dispose() {
    _bioController.dispose();
    _bioFocus.dispose();
    super.dispose();
  }

  void _saveBio() {
    if (_bioController.text != widget.bio) {
      widget.onBioUpdated(_bioController.text);
      HapticFeedback.mediumImpact();
    }
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return HiveCard(
        isHighlighted: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'About Me',
                  style: AppTextStyle.headlineLarge.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.white.withOpacity(0.7),
                    size: 20,
                  ),
                  onPressed: () {
                    _bioController.text = widget.bio ?? '';
                    setState(() => _isEditing = false);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              focusNode: _bioFocus,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.5,
              ),
              maxLines: 4,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Tell others about yourself...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 16,
                  height: 1.5,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.gold.withOpacity(0.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
                counterStyle: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: _saveBio,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold.withOpacity(0.2),
                    foregroundColor: AppColors.gold,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return HiveCard(
      isInteractive: true,
      onTap: () => setState(() => _isEditing = true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'About Me',
                style: AppTextStyle.headlineLarge.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.edit_outlined,
                color: Colors.white.withOpacity(0.5),
                size: 16,
              ),
            ],
          ),
          if (widget.bio != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.bio!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Add a bio to tell others about yourself...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
} 