import 'package:flutter/material.dart';
import 'package:hive_ui/features/content_seeding/data/models/seed_content_model.dart';
import 'package:hive_ui/features/content_seeding/domain/entities/seed_content_entity.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A card widget to display seed content information
class SeedContentCard extends StatelessWidget {
  /// The seed content entity to display
  final SeedContentEntity seedContent;
  
  /// Callback for when the card is tapped
  final VoidCallback? onTap;
  
  /// Constructor
  const SeedContentCard({
    Key? key,
    required this.seedContent,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Extract data from seed content
    final title = seedContent.data['title'] as String? ?? 'Untitled';
    final description = seedContent.data['description'] as String? ?? 'No description';
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildTypeIndicator(theme),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              _buildStatusIndicator(theme),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Build a widget to display the type of seed content
  Widget _buildTypeIndicator(ThemeData theme) {
    final typeString = seedContent.type.toString().split('.').last.toUpperCase();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        typeString,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  /// Build a widget to display the status of the seed content
  Widget _buildStatusIndicator(ThemeData theme) {
    final statusString = seedContent.status.toString().split('.').last.toUpperCase();
    final statusColor = _getStatusColor(seedContent.status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        statusString,
        style: theme.textTheme.bodySmall?.copyWith(
          color: _getTextColorForStatus(seedContent.status),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  /// Get the background color for a status indicator
  Color _getStatusColor(SeedingStatus status) {
    switch (status) {
      case SeedingStatus.pending:
        return const Color(0xFFE6E6E6); // Light gray
      case SeedingStatus.inProgress:
        return const Color(0xFF2196F3); // Blue
      case SeedingStatus.completed:
        return const Color(0xFF4CAF50); // Green
      case SeedingStatus.failed:
        return const Color(0xFFF44336); // Red
      case SeedingStatus.skipped:
        return const Color(0xFFFF9800); // Orange
    }
  }
  
  /// Get the text color for a status indicator
  Color _getTextColorForStatus(SeedingStatus status) {
    switch (status) {
      case SeedingStatus.pending:
        return Colors.black87;
      case SeedingStatus.completed:
      case SeedingStatus.inProgress:
      case SeedingStatus.failed:
      case SeedingStatus.skipped:
        return Colors.white;
    }
  }
} 