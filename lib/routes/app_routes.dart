import 'package:flutter/material.dart';
import '../components/event_card/event_card_example.dart';

/// Application routes definitions 
class AppRoutes {
  /// Event card example page route
  static const String eventCardExample = '/event-card-example';

  /// Route generator for the app
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case eventCardExample:
        return MaterialPageRoute(builder: (_) => const EventCardExamplePage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
} 