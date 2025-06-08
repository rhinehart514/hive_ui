import 'package:flutter/material.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A reusable loading view widget that displays a gold spinner with optional text
/// following HIVE design guidelines.
class LoadingView extends StatelessWidget {
  /// Optional message to display below the spinner
  final String? message;
  
  /// Whether to use a full-screen scaffold (true) or just the loading content (false)
  final bool fullScreen;
  
  /// Size of the loading spinner (default: 36.0)
  final double spinnerSize;
  
  /// Whether to add a subtle pulse animation to the spinner
  final bool animate;
  
  /// Creates a new [LoadingView] with optional parameters.
  const LoadingView({
    super.key,
    this.message,
    this.fullScreen = true,
    this.spinnerSize = 36.0,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final loadingContent = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Loading spinner with optional animation
        _buildSpinner().animate(
          autoPlay: animate,
          onPlay: (controller) => controller.repeat(),
        ).scaleXY(
          begin: 0.9,
          end: 1.1,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        ),
        
        // Optional message
        if (message != null) ...[
          const SizedBox(height: 20),
          Text(
            message!,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ).animate(autoPlay: animate).fadeIn(
            duration: const Duration(milliseconds: 400),
          ),
        ],
      ],
    );

    // Return either a full-screen scaffold or just the loading content
    return fullScreen
        ? Scaffold(
            backgroundColor: AppColors.dark,
            body: Center(child: loadingContent),
          )
        : Center(child: loadingContent);
  }

  /// Builds the spinner with HIVE styling
  Widget _buildSpinner() {
    return SizedBox(
      width: spinnerSize,
      height: spinnerSize,
      child: CircularProgressIndicator(
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
        backgroundColor: AppColors.black.withOpacity(0.2),
        strokeWidth: 3.0,
      ),
    );
  }
} 