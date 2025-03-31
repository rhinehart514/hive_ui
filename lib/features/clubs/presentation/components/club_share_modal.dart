import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/club.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_icons.dart';

/// Modal for sharing a club
class ClubShareModal extends StatelessWidget {
  final Club club;

  const ClubShareModal({
    super.key,
    required this.club,
  });

  @override
  Widget build(BuildContext context) {
    // Get screen size for proper sizing
    final size = MediaQuery.of(context).size;

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: 24 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(30),
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and icon
          Row(
            children: [
              const Icon(
                Icons.share,
                color: AppColors.gold,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Share Club',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Club info preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                // Club logo
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                    image: club.logoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(club.logoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: club.logoUrl == null
                      ? Center(
                          child: Text(
                            _getInitials(club.name),
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        club.name,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${club.memberCount} members · ${club.category}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Share options
          Text(
            'Share via',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.8),
            ),
          ),

          const SizedBox(height: 16),

          // Share option buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildShareOption(
                context,
                icon: AppIcons.message,
                label: 'Text',
                color: Colors.green,
                onTap: () => _shareViaText(context),
              ),
              _buildShareOption(
                context,
                icon: Icons.email_outlined,
                label: 'Email',
                color: Colors.red,
                onTap: () => _shareViaEmail(context),
              ),
              _buildShareOption(
                context,
                icon: Icons.copy,
                label: 'Copy Link',
                color: Colors.blue,
                onTap: () => _copyLink(context),
              ),
              _buildShareOption(
                context,
                icon: Icons.more_horiz,
                label: 'More',
                color: Colors.purple,
                onTap: () => _showMoreOptions(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Copy club code button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _copyClubCode(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.05),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.copy, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Copy Club Code',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  // Extract initials from club name
  String _getInitials(String name) {
    final words = name.split(' ');
    if (words.length > 1) {
      return words.take(2).map((word) => word.isNotEmpty ? word[0] : '').join();
    } else if (name.isNotEmpty) {
      return name.substring(0, 1);
    } else {
      return 'C';
    }
  }

  // Share methods
  void _shareViaText(BuildContext context) {
    final clubLink = 'https://hive.app/clubs/${club.id}';
    // TODO: Implement share via text
    Navigator.of(context).pop();
    _showShareSuccess(context, 'Opening messaging app...');
  }

  void _shareViaEmail(BuildContext context) {
    final clubLink = 'https://hive.app/clubs/${club.id}';
    // TODO: Implement share via email
    Navigator.of(context).pop();
    _showShareSuccess(context, 'Opening email app...');
  }

  void _copyLink(BuildContext context) {
    final clubLink = 'https://hive.app/clubs/${club.id}';
    Clipboard.setData(ClipboardData(text: clubLink));
    Navigator.of(context).pop();
    _showShareSuccess(context, 'Link copied to clipboard');
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: 24 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: AppColors.black,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(30),
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Share via',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Additional share options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAdditionalShareOption(
                  context,
                  icon: Icons.message,
                  label: 'WhatsApp',
                  color: Colors.green,
                  onTap: () => _shareViaWhatsApp(context),
                ),
                _buildAdditionalShareOption(
                  context,
                  icon: Icons.camera_alt_outlined,
                  label: 'Instagram',
                  color: Colors.pink,
                  onTap: () => _shareViaInstagram(context),
                ),
                _buildAdditionalShareOption(
                  context,
                  icon: Icons.alternate_email,
                  label: 'Twitter',
                  color: Colors.blue,
                  onTap: () => _shareViaTwitter(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalShareOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  void _shareViaWhatsApp(BuildContext context) {
    final clubLink = 'https://hive.app/clubs/${club.id}';
    Navigator.of(context).pop();
    Navigator.of(context).pop(); // Close both modals
    _showShareSuccess(context, 'Opening WhatsApp...');
    // Implement actual WhatsApp sharing here
  }

  void _shareViaInstagram(BuildContext context) {
    final clubLink = 'https://hive.app/clubs/${club.id}';
    Navigator.of(context).pop();
    Navigator.of(context).pop(); // Close both modals
    _showShareSuccess(context, 'Opening Instagram...');
    // Implement actual Instagram sharing here
  }

  void _shareViaTwitter(BuildContext context) {
    final clubLink = 'https://hive.app/clubs/${club.id}';
    Navigator.of(context).pop();
    Navigator.of(context).pop(); // Close both modals
    _showShareSuccess(context, 'Opening Twitter...');
    // Implement actual Twitter sharing here
  }

  void _copyClubCode(BuildContext context) {
    final clubCode = club.id.substring(0, 8).toUpperCase();
    Clipboard.setData(ClipboardData(text: clubCode));
    Navigator.of(context).pop();
    _showShareSuccess(context, 'Club code copied to clipboard');
  }

  void _showShareSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withOpacity(0.7),
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
