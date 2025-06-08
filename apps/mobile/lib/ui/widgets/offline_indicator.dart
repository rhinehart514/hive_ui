import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/application/services/connectivity_monitor.dart'; // For ConnectionStatus enum
import 'package:hive_ui/presentation/providers/connectivity_provider.dart'; // The provider
import 'package:hive_ui/core/theme/app_colors.dart'; // Corrected import path
import 'package:flutter_animate/flutter_animate.dart'; // For animations

/// A widget that displays an unobtrusive banner when the device is offline
class OfflineIndicator extends ConsumerStatefulWidget {
  const OfflineIndicator({super.key});

  @override
  ConsumerState<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends ConsumerState<OfflineIndicator> with SingleTickerProviderStateMixin {
  // Previous connectivity status to detect changes
  ConnectionStatus? _previousStatus;
  // Animation controller for showing/hiding the indicator
  late AnimationController _animationController;
  // Controls if the indicator should be visible at all (even before animation)
  bool _shouldShow = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectionStatus = ref.watch(connectivityStatusProvider);

    // Use AsyncValue handling for the stream provider
    return connectionStatus.when(
      data: (status) {
        // Check for status changes to control animations
        if (_previousStatus != status) {
          _handleConnectivityChange(status);
          _previousStatus = status;
        }

        // Don't build anything if we shouldn't show the indicator
        if (!_shouldShow) {
          return const SizedBox.shrink();
        }

        // Animated container that slides in/out
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1), // Start fully below the screen
                  end: Offset.zero, // End at normal position
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: Curves.easeOutCubic,
                  reverseCurve: Curves.easeInCubic,
                )),
                child: FadeTransition(
                  opacity: _animationController,
                  child: child,
                ),
              ),
            );
          },
          child: _buildOfflineBanner(),
        );
      },
      error: (error, stackTrace) {
        // If we can't determine connectivity, assume online
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(), // Don't show anything while loading initial status
    );
  }

  void _handleConnectivityChange(ConnectionStatus status) {
    if (status == ConnectionStatus.offline) {
      // When going offline, immediately show the indicator and animate in
      setState(() {
        _shouldShow = true;
      });
      _animationController.forward();
    } else if (status == ConnectionStatus.online && _previousStatus == ConnectionStatus.offline) {
      // When going back online from offline, animate out then hide
      _animationController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _shouldShow = false;
          });
        }
      });
    }
  }

  Widget _buildOfflineBanner() {
    return Material(
      elevation: 8, // Add shadow
      color: AppColors.surfaceStart.withOpacity(0.95), // Use HIVE surfaceStart color with slight opacity
      child: SafeArea(
        top: false, // Only apply bottom safe area
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.signal_wifi_off_outlined,
                    color: AppColors.warning, // Use HIVE warning color
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'You are offline. Some features may be limited.',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () {
                      _animationController.reverse().then((_) {
                        if (mounted) {
                          setState(() {
                            _shouldShow = false;
                          });
                        }
                      });
                    },
                    tooltip: 'Dismiss',
                  ),
                ],
              ),
              
              // Alternative action suggestions
              Padding(
                padding: const EdgeInsets.only(left: 36.0, bottom: 8.0, top: 4.0),
                child: Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry connection'),
                      onPressed: () {
                        // This would trigger a manual connectivity check
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Checking connection...'))
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton.icon(
                      icon: const Icon(Icons.settings, size: 16),
                      label: const Text('Settings'),
                      onPressed: () {
                        // This would navigate to connection settings
                        // Navigator.of(context).pushNamed('/settings/connection');
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
} 