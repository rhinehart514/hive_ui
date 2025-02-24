import 'package:flutter/material.dart';

class MessagingPage extends StatelessWidget {
  const MessagingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            color: Colors.white,
            onPressed: () {
              // TODO: Handle new message
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Messages',
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
