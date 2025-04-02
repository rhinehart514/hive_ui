import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/messaging/utils/messaging_initializer.dart';
import 'package:hive_ui/core/navigation/router_config.dart';
import 'package:hive_ui/theme/app_theme.dart';

class HiveApp extends ConsumerStatefulWidget {
  const HiveApp({super.key});

  @override
  ConsumerState<HiveApp> createState() => _HiveAppState();
}

class _HiveAppState extends ConsumerState<HiveApp> {
  @override
  void initState() {
    super.initState();
    
    // Defer setup to ensure everything is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupServices();
    });
  }
  
  Future<void> _setupServices() async {
    // Initialize messaging features
    await initializeFirebaseMessaging();
    // Initialize messaging services via provider
    ref.read(messagingInitializerProvider);
  }

  @override
  Widget build(BuildContext context) {
    // Setup notification navigation after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setupNotificationNavigation(appRouter, context);
    });
    
    return MaterialApp.router(
      title: 'HIVE',
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
} 