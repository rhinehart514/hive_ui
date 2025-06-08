import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A consistent scaffold for authentication and onboarding screens.
///
/// Provides standardized layout, including app bar, padding, and loading state.
class AuthScreenScaffold extends StatelessWidget {
  /// The title displayed in the app bar.
  final String title;

  /// The main content of the screen.
  final Widget body;

  /// Whether the screen is in a loading state.
  final bool isLoading;

  /// Indicates if the back button should be shown in the app bar.
  final bool showBackButton;

  /// Callback when the back button is pressed.
  final VoidCallback? onBackPressed;

  /// Footer content to display at the bottom of the screen.
  final Widget? footer;

  /// Creates an instance of [AuthScreenScaffold].
  const AuthScreenScaffold({
    Key? key,
    required this.title,
    required this.body,
    this.isLoading = false,
    this.showBackButton = false,
    this.onBackPressed,
    this.footer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  if (onBackPressed != null) {
                    onBackPressed!();
                  } else {
                    Navigator.of(context).maybePop();
                  }
                },
              )
            : null,
        centerTitle: false,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    body,
                    if (footer != null) ...[
                      const SizedBox(height: 24),
                      footer!,
                    ],
                    // Add extra bottom padding for scrolling
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 