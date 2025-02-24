import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/components/bottom_nav_bar.dart';

class Shell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const Shell({
    super.key,
    required this.navigationShell,
  });

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: navigationShell,
      bottomNavigationBar: BottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _onTap(context, index),
      ),
    );
  }
} 