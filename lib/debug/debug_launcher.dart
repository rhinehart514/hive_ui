import 'package:flutter/material.dart';
import 'debug_menu.dart';

/// A debug launcher widget that can be placed in your app to quickly access the debug menu.
/// This should only be included in development builds, not production.
class DebugLauncher extends StatelessWidget {
  /// The child widget that will display normally
  final Widget child;
  
  /// Whether to show the debug launcher
  final bool visible;

  /// Constructor
  const DebugLauncher({
    Key? key,
    required this.child,
    this.visible = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!visible) return child;
    
    return Stack(
      children: [
        // Main app content
        child,
        
        // Debug launcher button
        Positioned(
          right: 16,
          bottom: 100, // Position above the bottom nav bar
          child: _buildLauncherButton(context),
        ),
      ],
    );
  }
  
  Widget _buildLauncherButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDebugMenu(context),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.yellow.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            "D",
            style: TextStyle(
              color: Colors.yellow,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
  
  void _openDebugMenu(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DebugMenu()),
    );
  }
} 