import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/organization.dart';
import '../providers/organization_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Widget for displaying organization details in a card format
class _OrganizationCard extends StatelessWidget {
  final Organization organization;

  const _OrganizationCard({
    Key? key,
    required this.organization,
  }) : super(key: key);

  void _goToOrganizationProfile(BuildContext context) {
    context.pushNamed('organization_profile', extra: {'id': organization.id});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _goToOrganizationProfile(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Organization icon
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: organization.avatarColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      organization.icon,
                      color: organization.avatarColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Organization info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          organization.name,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          organization.category,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Official badge
                  if (organization.isOfficiallyVerified)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.gold.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'Official',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Divider
            Container(
              height: 1,
              color: Colors.white.withOpacity(0.05),
            ),

            // Details section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(
                    organization.shortDescription,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),

                  // Stats row
                  Row(
                    children: [
                      _buildStat(organization.eventCount.toString(), 'Events'),
                      const SizedBox(width: 16),
                      _buildStat(
                          organization.memberCount.toString(), 'Members'),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.white38,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Row(
      children: [
        Icon(
          label == 'Events' ? Icons.event : Icons.people,
          size: 16,
          color: Colors.white38,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }
}

class OrganizationsPage extends ConsumerStatefulWidget {
  const OrganizationsPage({super.key});

  @override
  ConsumerState<OrganizationsPage> createState() => _OrganizationsPageState();
}

class _OrganizationsPageState extends ConsumerState<OrganizationsPage> {
  final String _sortOption = 'Name'; // Default sort option
  final List<String> _sortOptions = ['Name', 'Events', 'Recently Active'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(organizationsProvider);
      _checkForRefresh();
    });
  }

  Future<void> _checkForRefresh() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        final currentOrganizations =
            await ref.read(organizationsProvider.future);
        if (currentOrganizations.isEmpty && mounted) {
          ref.read(refreshOrganizationsProvider.notifier).state = true;
        }
      }
    } catch (e) {
      debugPrint('Background refresh check error: $e');
    }
  }

  List<Organization> _getSortedOrganizations(List<Organization> organizations) {
    switch (_sortOption) {
      case 'Events':
        return List.from(organizations)
          ..sort((a, b) => b.eventCount.compareTo(a.eventCount));
      case 'Recently Active':
        return List.from(organizations)
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case 'Name':
      default:
        return List.from(organizations)
          ..sort((a, b) => a.name.compareTo(b.name));
    }
  }

  Future<void> _performThoroughRefresh() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing all organizations data...'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      ref.read(refreshOrganizationsProvider.notifier).state = true;
      ref.invalidate(organizationsProvider);
      ref.invalidate(orgCategoriesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Organizations data refreshed successfully!'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing data: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Error during thorough refresh: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the current selected category
    final selectedCategory = ref.watch(selectedOrgCategoryProvider);

    // Watch the organizations data based on selected category
    final organizationsAsync = ref.watch(selectedCategory == null
        ? organizationsProvider
        : organizationsByCategoryProvider(selectedCategory));

    // Watch the categories list
    final categoriesAsync = ref.watch(orgCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        title: Text(
          'Organizations',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Sort button
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white),
            tooltip: 'Sort organizations',
            onSelected: (String value) {
              ref.read(selectedOrgCategoryProvider.notifier).state = null;
            },
            itemBuilder: (BuildContext context) {
              return _sortOptions.map((String option) {
                return PopupMenuItem<String>(
                  value: option,
                  child: Row(
                    children: [
                      Icon(
                        _sortOption == option
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: _sortOption == option ? AppColors.gold : null,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(option),
                    ],
                  ),
                );
              }).toList();
            },
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _performThoroughRefresh,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Text(
                  'All Organizations',
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Show current sort option
                Row(
                  children: [
                    Text(
                      'Sorted by: ',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _sortOption,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Category filters
          categoriesAsync.when(
            data: (categories) {
              if (categories.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      'Categories',
                      style: AppTheme.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 60,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: ChoiceChip(
                            label: const Text('All'),
                            selected: selectedCategory == null,
                            onSelected: (selected) {
                              if (selected) {
                                ref
                                    .read(selectedOrgCategoryProvider.notifier)
                                    .state = null;
                              }
                            },
                            backgroundColor: Colors.grey[800],
                            selectedColor: AppColors.gold.withOpacity(0.3),
                            labelStyle: TextStyle(
                              color: selectedCategory == null
                                  ? AppColors.gold
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        ...categories.map((category) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(category),
                              selected: selectedCategory == category,
                              onSelected: (selected) {
                                if (selected) {
                                  ref
                                      .read(
                                          selectedOrgCategoryProvider.notifier)
                                      .state = category;
                                } else {
                                  ref
                                      .read(
                                          selectedOrgCategoryProvider.notifier)
                                      .state = null;
                                }
                              },
                              backgroundColor: Colors.grey[800],
                              selectedColor: AppColors.gold.withOpacity(0.3),
                              labelStyle: TextStyle(
                                color: selectedCategory == category
                                    ? AppColors.gold
                                    : AppColors.textPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox(height: 60),
            error: (_, __) => const SizedBox(height: 60),
          ),

          // Organization list
          Expanded(
            child: organizationsAsync.when(
              data: (organizations) {
                if (organizations.isEmpty) {
                  return _buildEmpty(selectedCategory != null);
                }
                // Apply sorting before displaying
                return _buildOrganizationsList(
                    _getSortedOrganizations(organizations));
              },
              loading: () => _buildLoading(),
              error: (error, stackTrace) {
                debugPrint('Error loading organizations: $error\n$stackTrace');
                return _buildError();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading organizations...',
            style: AppTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isFiltered) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltered ? Icons.filter_list : Icons.business_outlined,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No Organizations Found',
            style: AppTheme.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              isFiltered
                  ? 'No organizations match the selected filter.'
                  : 'Check back later or refresh to see organizations from RSS feeds.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _performThoroughRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: AppTheme.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'There was an error loading the organizations.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _performThoroughRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizationsList(List<Organization> organizations) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: organizations.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final organization = organizations[index];
        return _OrganizationCard(
          organization: organization,
        );
      },
    );
  }
}
