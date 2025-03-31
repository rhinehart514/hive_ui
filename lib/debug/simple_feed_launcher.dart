import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:hive_ui/pages/main_feed.dart';
import 'package:hive_ui/services/service_initializer.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:hive_ui/theme/app_theme.dart';

/// A debug launcher that only shows the MainFeed
/// This can be used for debugging issues with the feed
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase (with error handling)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
    debugPrint('Continuing without Firebase');
  }

  // Initialize basic services
  try {
    await UserPreferencesService.initialize();
    await ServiceInitializer.initializeServices();
  } catch (e) {
    debugPrint('Error initializing services: $e');
    debugPrint('Continuing with degraded functionality');
  }

  // Run the app
  runApp(const ProviderScope(child: MainFeedApp()));
}

/// Simple app that only shows the MainFeed
class MainFeedApp extends StatelessWidget {
  const MainFeedApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return MaterialApp(
      title: 'HIVE Feed Debug',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const MainFeed(),
    );
  }
}
