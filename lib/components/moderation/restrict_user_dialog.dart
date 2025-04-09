import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/moderation/presentation/providers/moderation_providers.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';

/// Dialog to configure and apply user restrictions.
class RestrictUserDialog extends ConsumerStatefulWidget {
  final UserProfile targetUser;

  const RestrictUserDialog({Key? key, required this.targetUser}) : super(key: key);

  @override
  ConsumerState<RestrictUserDialog> createState() => _RestrictUserDialogState();
}

class _RestrictUserDialogState extends ConsumerState<RestrictUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  Duration? _selectedDuration;
  bool _isSubmitting = false;

  // Predefined restriction durations
  final Map<String, Duration?> _durations = {
    '1 Day': const Duration(days: 1),
    '1 Week': const Duration(days: 7),
    '1 Month': const Duration(days: 30),
    'Permanent': null,
  };

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitRestriction() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) {
      return;
    }
    setState(() => _isSubmitting = true);

    final moderatorId = ref.read(currentUserProvider).id; // Assuming current user ID is moderator
    final reason = _reasonController.text.trim();
    final endDate = _selectedDuration != null ? DateTime.now().add(_selectedDuration!) : null;

    try {
      await ref.read(moderationControllerProvider.notifier).restrictUser(
            userId: widget.targetUser.id,
            isRestricted: true,
            reason: reason,
            endDate: endDate,
            restrictedBy: moderatorId,
          );
      
      if (mounted) {
        Navigator.of(context).pop(true); // Indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.targetUser.displayName} has been restricted.'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to restrict user: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Restrict ${widget.targetUser.displayName}',
        style: GoogleFonts.inter(color: AppColors.white, fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select the duration and provide a reason for the restriction.',
                style: GoogleFonts.inter(color: AppColors.white.withOpacity(0.7)),
              ),
              const SizedBox(height: 20),
              // Duration Dropdown
              DropdownButtonFormField<Duration?>(
                value: _selectedDuration,
                onChanged: (value) => setState(() => _selectedDuration = value),
                decoration: InputDecoration(
                  labelText: 'Duration',
                  labelStyle: GoogleFonts.inter(color: AppColors.white.withOpacity(0.7)),
                  filled: true,
                  fillColor: AppColors.black.withOpacity(0.3),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
                dropdownColor: AppColors.cardBackground,
                style: GoogleFonts.inter(color: AppColors.white),
                items: _durations.entries.map((entry) {
                  return DropdownMenuItem<Duration?>(
                    value: entry.value,
                    child: Text(entry.key),
                  );
                }).toList(),
                validator: (value) {
                  // Allow null (Permanent) but ensure something is implicitly selected
                  // The initial value isn't null, so this mainly checks if it changed
                  // For simplicity, we don't enforce selection here, assuming default is okay
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Reason Text Field
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                maxLength: 200,
                style: GoogleFonts.inter(color: AppColors.white),
                decoration: InputDecoration(
                  labelText: 'Reason',
                  labelStyle: GoogleFonts.inter(color: AppColors.white.withOpacity(0.7)),
                  hintText: 'Explain why this user is being restricted...',
                  hintStyle: GoogleFonts.inter(color: AppColors.white.withOpacity(0.5)),
                  filled: true,
                  fillColor: AppColors.black.withOpacity(0.3),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  counterStyle: GoogleFonts.inter(color: AppColors.white.withOpacity(0.5)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a reason for the restriction.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.white.withOpacity(0.7))),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitRestriction,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: AppColors.error.withOpacity(0.5),
          ),
          child: _isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
              : Text('Restrict User', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
} 