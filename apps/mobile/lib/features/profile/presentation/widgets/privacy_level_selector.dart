import 'package:flutter/material.dart';
import 'package:hive_ui/features/profile/domain/entities/profile_visibility_settings.dart';

/// Widget for selecting a privacy level
class PrivacyLevelSelector extends StatelessWidget {
  /// Current selected privacy level
  final PrivacyLevel value;
  
  /// Callback when the privacy level changes
  final Function(PrivacyLevel) onChanged;

  /// Constructor
  const PrivacyLevelSelector({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildPrivacyOption(
          context,
          PrivacyLevel.everyone,
          'Everyone',
          'Anyone can view',
          Icons.public,
        ),
        const SizedBox(height: 8),
        _buildPrivacyOption(
          context,
          PrivacyLevel.friends,
          'Friends Only',
          'Only people you are connected with',
          Icons.group,
        ),
        const SizedBox(height: 8),
        _buildPrivacyOption(
          context,
          PrivacyLevel.private,
          'Private',
          'Only you can view',
          Icons.lock,
        ),
      ],
    );
  }

  Widget _buildPrivacyOption(
    BuildContext context,
    PrivacyLevel level,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = value == level;
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: () => onChanged(level),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primary.withOpacity(0.1)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected 
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
} 