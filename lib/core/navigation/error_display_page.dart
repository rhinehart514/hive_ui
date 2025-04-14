import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A generic error display page for navigation errors
class ErrorDisplayPage extends StatelessWidget {
  /// The error message to display
  final String message;
  
  /// Whether to show a back button
  final bool showBackButton;
  
  /// Whether to show a home button
  final bool showHomeButton;
  
  /// Create an error display page
  const ErrorDisplayPage({
    Key? key,
    required this.message,
    this.showBackButton = true,
    this.showHomeButton = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
        backgroundColor: Colors.red.shade800,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 24),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showBackButton)
                    ElevatedButton.icon(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        }
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Go Back'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade800,
                      ),
                    ),
                  if (showBackButton && showHomeButton)
                    const SizedBox(width: 16),
                  if (showHomeButton)
                    ElevatedButton.icon(
                      onPressed: () {
                        context.go('/');
                      },
                      icon: const Icon(Icons.home),
                      label: const Text('Go Home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade800,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 