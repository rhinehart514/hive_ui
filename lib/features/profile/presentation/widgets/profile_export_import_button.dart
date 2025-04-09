import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/common/widgets/glassmorphic_container.dart';
import 'package:hive_ui/features/profile/domain/providers/profile_export_provider.dart';
import 'package:hive_ui/features/profile/presentation/providers/profile_providers.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:file_picker/file_picker.dart';

/// Button for exporting and importing user profiles
class ProfileExportImportButton extends ConsumerWidget {
  const ProfileExportImportButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 70,
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      blur: 10,
      border: 1,
      linearGradient: AppColors.glassGradient,
      borderGradient: AppColors.glassGradient,
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile Data',
                style: GoogleFonts.poppins(
                  color: AppColors.gold,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Export or import your profile',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () => _showOptions(context, ref),
            icon: const Icon(Icons.import_export, color: AppColors.gold),
            tooltip: 'Export or import profile data',
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.grey800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Profile Data',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.download, color: AppColors.gold),
              title: Text('Export Profile', 
                style: GoogleFonts.poppins(color: Colors.white)),
              subtitle: Text('Save your profile data as a file',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
              onTap: () => _exportProfile(context, ref),
            ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.upload, color: AppColors.gold),
              title: Text('Import Profile', 
                style: GoogleFonts.poppins(color: Colors.white)),
              subtitle: Text('Load profile data from a file',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
              onTap: () => _importProfile(context, ref),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                'Note: Importing a profile will override your current profile information',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportProfile(BuildContext context, WidgetRef ref) async {
    // Close bottom sheet
    Navigator.pop(context);
    
    // Show loading dialog
    _showLoadingDialog(context, 'Preparing profile export...');
    
    try {
      final profileState = ref.read(profileProvider);
      final exportService = ref.read(profileExportServiceProvider);
      
      if (profileState.profile == null) {
        throw Exception('No profile loaded to export');
      }
      
      // Export the profile
      final filePath = await exportService.exportProfile(profileState.profile!);
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Show success dialog with share option
      _showSuccessDialog(context, filePath, ref);
    } catch (e) {
      // Close loading dialog if open
      if (context.mounted) {
        Navigator.pop(context);
      }
      
      // Show error message
      if (context.mounted) {
        _showErrorDialog(context, 'Failed to export profile: $e');
      }
    }
  }

  Future<void> _importProfile(BuildContext context, WidgetRef ref) async {
    // Close bottom sheet
    Navigator.pop(context);
    
    try {
      // Open file picker
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (result == null || result.files.isEmpty) {
        // User canceled the picker
        return;
      }
      
      final filePath = result.files.first.path;
      if (filePath == null) {
        throw Exception('Invalid file path');
      }
      
      // Show confirmation dialog
      if (context.mounted) {
        await _showImportConfirmationDialog(context, filePath, ref);
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'Failed to select file: $e');
      }
    }
  }

  Future<void> _showImportConfirmationDialog(
    BuildContext context, 
    String filePath, 
    WidgetRef ref
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.grey800,
          title: Text(
            'Import Profile',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'This will override your current profile information. Are you sure you want to continue?',
            style: GoogleFonts.poppins(
              color: Colors.white70,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Import',
                style: GoogleFonts.poppins(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _processImport(context, filePath, ref);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _processImport(
    BuildContext context, 
    String filePath, 
    WidgetRef ref
  ) async {
    // Show loading dialog
    _showLoadingDialog(context, 'Importing profile...');
    
    try {
      final exportService = ref.read(profileExportServiceProvider);
      
      // Import the profile
      final importedProfile = await exportService.importProfile(filePath);
      
      // Apply the imported profile
      final success = await exportService.applyImportedProfile(importedProfile);
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }
      
      if (success) {
        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile imported successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to apply imported profile');
      }
    } catch (e) {
      // Close loading dialog if open
      if (context.mounted) {
        Navigator.pop(context);
      }
      
      // Show error message
      if (context.mounted) {
        _showErrorDialog(context, 'Import failed: $e');
      }
    }
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.grey800,
        content: Row(
          children: [
            const CircularProgressIndicator(color: AppColors.gold),
            const SizedBox(width: 20),
            Flexible(
              child: Text(
                message,
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.grey800,
        title: Text(
          'Error',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(
            color: Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                color: AppColors.gold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String filePath, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.grey800,
        title: Text(
          'Export Completed',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your profile has been exported successfully.',
              style: GoogleFonts.poppins(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                filePath,
                style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(
                color: Colors.white70,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _shareExport(context, filePath, ref);
            },
            child: Text(
              'Share',
              style: GoogleFonts.poppins(
                color: AppColors.gold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareExport(BuildContext context, String filePath, WidgetRef ref) async {
    try {
      final exportService = ref.read(profileExportServiceProvider);
      await exportService.shareExportedProfile(filePath);
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'Failed to share export: $e');
      }
    }
  }
} 