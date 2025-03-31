import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/models/organization.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A widget to display an organization tile in a list or grid
/// Used to show organizations within spaces
class OrganizationTile extends StatelessWidget {
  final Organization organization;
  final bool isCompact;
  final VoidCallback? onTap;

  const OrganizationTile({
    Key? key,
    required this.organization,
    this.isCompact = false,
    this.onTap,
  }) : super(key: key);

  void _goToOrganizationProfile(BuildContext context) {
    context.pushNamed('organization_profile', extra: {'id': organization.id});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _goToOrganizationProfile(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.cardBorder,
            width: 1,
          ),
        ),
        child: isCompact ? _buildCompactTile(theme) : _buildFullTile(theme),
      ),
    );
  }

  Widget _buildCompactTile(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          _buildAvatar(size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNameRow(fontSize: 14),
                const SizedBox(height: 2),
                Text(
                  organization.category,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildEventCount(small: true),
        ],
      ),
    );
  }

  Widget _buildFullTile(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNameRow(fontSize: 16),
                    const SizedBox(height: 2),
                    Text(
                      organization.category,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              _buildEventCount(small: false),
            ],
          ),
          if (organization.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              organization.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 14,
              ),
            ),
          ],
          if (organization.mission != null &&
              organization.mission?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              "Mission: ${organization.mission}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNameRow({required double fontSize}) {
    return Row(
      children: [
        Flexible(
          child: Text(
            organization.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (organization.isVerified) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.verified,
            size: fontSize,
            color: Colors.blue,
          ),
        ],
        if (organization.isOfficial) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.workspace_premium,
            size: fontSize,
            color: AppColors.gold,
          ),
        ],
      ],
    );
  }

  Widget _buildAvatar({required double size}) {
    // If it's a university department, use the UB logo
    if (organization.isUniversityDepartment) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.asset(
          'assets/images/ublogo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackAvatar(size);
          },
        ),
      );
    }

    // For other organizations, use their logo if available
    final logoUrl = organization.logoUrl;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.network(
          logoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackAvatar(size);
          },
        ),
      );
    } else {
      return _buildFallbackAvatar(size);
    }
  }

  Widget _buildFallbackAvatar(double size) {
    // For university departments without the logo, use a different color scheme
    if (organization.isUniversityDepartment) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.gold.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.gold,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Icon(
            organization.displayIcon,
            color: AppColors.gold,
            size: size * 0.5,
          ),
        ),
      );
    }

    // Default fallback for other organizations
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors
            .primaries[organization.name.hashCode % Colors.primaries.length],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _getInitial(),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getInitial() {
    return organization.name.isNotEmpty
        ? organization.name[0].toUpperCase()
        : '#';
  }

  Widget _buildEventCount({required bool small}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.2),
        borderRadius: BorderRadius.circular(small ? 12 : 16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event,
            size: small ? 12 : 14,
            color: AppColors.gold,
          ),
          const SizedBox(width: 4),
          Text(
            organization.eventCount.toString(),
            style: TextStyle(
              color: AppColors.gold,
              fontSize: small ? 12 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
