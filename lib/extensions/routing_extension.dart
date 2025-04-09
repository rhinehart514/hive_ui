import 'package:flutter/material.dart';

/// Extension methods for routing in the app
extension RoutingExtension on BuildContext {
  /// Push a new page onto the navigation stack
  Future<T?> pushPage<T>(Widget page) {
    return Navigator.of(this).push<T>(
      MaterialPageRoute(builder: (context) => page),
    );
  }
  
  /// Push a replacement page onto the navigation stack
  Future<T?> pushReplacementPage<T, TO>(Widget page) {
    return Navigator.of(this).pushReplacement<T, TO>(
      MaterialPageRoute(builder: (context) => page),
    );
  }
  
  /// Push a new page and remove all previous routes
  Future<T?> pushNewStack<T>(Widget page) {
    return Navigator.of(this).pushAndRemoveUntil<T>(
      MaterialPageRoute(builder: (context) => page),
      (route) => false,
    );
  }
  
  /// Push a new app page with custom transition
  Future<T?> pushAppPage<T>(Widget page, {String? stackName}) {
    return Navigator.of(this).push<T>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutQuart;
          
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        // Give the route a name for navigation stack identification
        settings: RouteSettings(name: stackName),
      ),
    );
  }
  
  /// Push a modal page that slides up from the bottom
  Future<T?> pushModal<T>(Widget page) {
    return Navigator.of(this).push<T>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.5),
      ),
    );
  }
} 