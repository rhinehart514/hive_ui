import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/profile/domain/entities/profile_visibility_settings.dart';
import 'package:hive_ui/features/profile/presentation/providers/profile_visibility_providers.dart';
import 'package:hive_ui/features/profile/presentation/widgets/privacy_level_selector.dart';

/// Page for managing profile privacy and visibility settings
class ProfileVisibilitySettingsPage extends ConsumerStatefulWidget {
  /// The user ID whose settings are being edited
  final String userId;

  /// Constructor
  const ProfileVisibilitySettingsPage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState<ProfileVisibilitySettingsPage> createState() => _ProfileVisibilitySettingsPageState();
}

class _ProfileVisibilitySettingsPageState extends ConsumerState<ProfileVisibilitySettingsPage> {
  @override
  void initState() {
    super.initState();
    // Load settings on initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileVisibilityControllerProvider).loadSettings(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(profileVisibilityControllerProvider);
    final settings = controller.settings;
    final isLoading = controller.isLoading;
    final error = controller.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Visibility'),
        backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        centerTitle: true,
        elevation: 0,
      ),
      body: _buildBody(context, settings, isLoading, error),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ProfileVisibilitySettings? settings,
    bool isLoading,
    String? error,
  ) {
    if (isLoading && settings == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null && settings == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error loading settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(profileVisibilityControllerProvider).loadSettings(widget.userId);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (settings == null) {
      return const Center(
        child: Text('No settings found'),
      );
    }

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildDiscoverabilitySection(context, settings),
            const Divider(height: 32),
            _buildContentVisibilitySection(context, settings),
            const Divider(height: 32),
            _buildPrivacyLevelsSection(context, settings),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Last updated: ${_formatDate(settings.updatedAt)}',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDiscoverabilitySection(
    BuildContext context,
    ProfileVisibilitySettings settings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Discoverability',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        _buildSwitchTile(
          title: 'Profile Visibility',
          subtitle: 'Allow others to discover your profile',
          value: settings.isDiscoverable,
          onChanged: (value) => _updateSetting('isDiscoverable', value),
        ),
      ],
    );
  }

  Widget _buildContentVisibilitySection(
    BuildContext context,
    ProfileVisibilitySettings settings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Content Visibility',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        _buildSwitchTile(
          title: 'Events',
          subtitle: 'Show your events to non-connections',
          value: settings.showEventsToPublic,
          onChanged: (value) => _updateSetting('showEventsToPublic', value),
        ),
        _buildSwitchTile(
          title: 'Spaces',
          subtitle: 'Show your spaces to non-connections',
          value: settings.showSpacesToPublic,
          onChanged: (value) => _updateSetting('showSpacesToPublic', value),
        ),
        _buildSwitchTile(
          title: 'Friends',
          subtitle: 'Show your friends list to non-connections',
          value: settings.showFriendsToPublic,
          onChanged: (value) => _updateSetting('showFriendsToPublic', value),
        ),
      ],
    );
  }

  Widget _buildPrivacyLevelsSection(
    BuildContext context,
    ProfileVisibilitySettings settings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacy Controls',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        _buildPrivacyLevelTile(
          title: 'Friend Requests',
          subtitle: 'Who can send you friend requests',
          value: settings.friendRequestsPrivacy,
          onChanged: (value) => _updateSetting('friendRequestsPrivacy', value),
        ),
        const SizedBox(height: 8),
        _buildPrivacyLevelTile(
          title: 'Activity Feed',
          subtitle: 'Who can see your activity feed',
          value: settings.activityFeedPrivacy,
          onChanged: (value) => _updateSetting('activityFeedPrivacy', value),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        dense: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildPrivacyLevelTile({
    required String title,
    required String subtitle,
    required PrivacyLevel value,
    required Function(PrivacyLevel) onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            PrivacyLevelSelector(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  void _updateSetting(String field, dynamic value) {
    ref.read(profileVisibilityControllerProvider).updateSetting(
      field: field,
      value: value,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} at ${_formatTime(date)}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
} 