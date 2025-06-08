import 'package:flutter/material.dart';
import 'package:hive_ui/extensions/glassmorphism_extension.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// This file demonstrates how to use the glassmorphism extensions in the HIVE UI
class GlassmorphismDemo extends StatelessWidget {
  const GlassmorphismDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Glassmorphism Examples',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Standard Card Example
              _buildSectionTitle('Standard Card'),
              const SizedBox(height: 8),
              _buildStandardCard(),
              const SizedBox(height: 24),

              // Modal Example
              _buildSectionTitle('Modal Style'),
              const SizedBox(height: 8),
              _buildModalCard(),
              const SizedBox(height: 24),

              // Header Example
              _buildSectionTitle('Header Style'),
              const SizedBox(height: 8),
              _buildHeaderExample(),
              const SizedBox(height: 24),

              // Gold Accent Example
              _buildSectionTitle('Gold Accent'),
              const SizedBox(height: 8),
              _buildGoldAccentCard(),
              const SizedBox(height: 24),

              // Usage Notes
              _buildSectionTitle('Usage Notes'),
              const SizedBox(height: 8),
              _buildUsageNotes(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildStandardCard() {
    return SizedBox(
      height: 150,
      child: const Card(
        elevation: 0,
        color: Colors.transparent,
        child: Center(
          child: Text(
            'Standard Card with Glassmorphism',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
            ),
          ),
        ),
      ).addGlassmorphism(),
    );
  }

  Widget _buildModalCard() {
    return SizedBox(
      height: 150,
      child: const Card(
        elevation: 0,
        color: Colors.transparent,
        child: Center(
          child: Text(
            'Modal Style Glassmorphism',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
            ),
          ),
        ),
      ).addModalGlassmorphism(),
    );
  }

  Widget _buildHeaderExample() {
    return SizedBox(
      height: 80,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Icon(Icons.menu, color: AppColors.textPrimary),
            SizedBox(width: 16),
            Text(
              'Header Example',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Spacer(),
            Icon(Icons.search, color: AppColors.textPrimary),
            SizedBox(width: 16),
            Icon(Icons.more_vert, color: AppColors.textPrimary),
          ],
        ),
      ).addHeaderGlassmorphism(),
    );
  }

  Widget _buildGoldAccentCard() {
    return SizedBox(
      height: 150,
      child: const Card(
        elevation: 0,
        color: Colors.transparent,
        child: Center(
          child: Text(
            'Gold Accent Glassmorphism',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
            ),
          ),
        ),
      ).addGlassmorphism(addGoldAccent: true),
    );
  }

  Widget _buildUsageNotes() {
    return const Text(
      '''
How to use the glassmorphism extensions:

1. Import the extension:
   import 'package:hive_ui/extensions/glassmorphism_extension.dart';

2. Add to any widget using:
   - .addGlassmorphism() - For standard cards and containers
   - .addModalGlassmorphism() - For modals, bottom sheets, and dialogs
   - .addHeaderGlassmorphism() - For app bars and headers

3. Customize options like blur, opacity, and border radius as needed

4. All extensions use the standardized values from GlassmorphismGuide class
''',
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
      ),
    ).addGlassmorphism(
      blur: 1.5,
      opacity: 0.3,
      padding: const EdgeInsets.all(16),
    );
  }
}
