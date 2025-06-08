import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

/// Data class for about section items
class AboutItem {
  final String title;
  final IconData icon;
  final String content;
  final String? secondaryInfo;
  final bool isLink;
  final String? linkUrl;
  final bool isEditable;

  const AboutItem({
    required this.title,
    required this.icon,
    required this.content,
    this.secondaryInfo,
    this.isLink = false,
    this.linkUrl,
    this.isEditable = false,
  });
}

/// A tab to display information about a space
class SpaceAboutTab extends StatelessWidget {
  final String description;
  final List<AboutItem> aboutItems;
  final VoidCallback? onEditDescription;
  
  const SpaceAboutTab({
    Key? key,
    required this.description,
    required this.aboutItems,
    this.onEditDescription,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'About',
                    style: GoogleFonts.inter(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.25,
                    ),
                  ),
                  if (onEditDescription != null)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.white, size: 20),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        onEditDescription!();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.1,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        
        // Connect section
        if (aboutItems.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Connect With Us',
              style: GoogleFonts.inter(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.25,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // About items
          ...aboutItems.map((item) => _buildAboutItem(context, item)),
        ],
      ],
    );
  }
  
  Widget _buildAboutItem(BuildContext context, AboutItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      child: InkWell(
        onTap: item.isLink && item.linkUrl != null ? () => _launchUrl(item.linkUrl!) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.cardBorder,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item.icon,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.content,
                      style: GoogleFonts.inter(
                        color: item.isLink ? AppColors.gold : AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item.secondaryInfo != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.secondaryInfo!,
                        style: GoogleFonts.inter(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Action icon for links
              if (item.isLink)
                const Icon(
                  Icons.open_in_new,
                  color: AppColors.gold,
                  size: 16,
                ),
              
              // Edit icon for editable items
              if (item.isEditable)
                const Icon(
                  Icons.edit_outlined,
                  color: AppColors.white,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Launch URL helper
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }
} 