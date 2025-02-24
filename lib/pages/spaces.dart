import 'package:flutter/material.dart';

class SpacesPage extends StatelessWidget {
  const SpacesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Spaces',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontFamily: 'Outfit',
          ),
        ),
      ),
    );
  }
}
