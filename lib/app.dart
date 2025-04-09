import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/navigation/router_config.dart';
import 'package:hive_ui/theme/app_theme.dart';
import 'package:hive_ui/core/app_initializer.dart';
import 'package:hive_ui/core/widgets/offline_status_overlay.dart';

class HiveApp extends ConsumerWidget {
  const HiveApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize app services
    ref.watch(appInitializerProvider);
    
    // Get router config
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'HIVE',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Use dark theme by default
      routerConfig: router,
      builder: (context, child) {
        // Wrap the entire app with the offline status overlay
        return ConditionalOfflineStatusOverlay(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
} 