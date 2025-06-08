import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/tutorial_providers.dart';
import '../../../../theme/app_colors.dart';

/// A widget that displays the current progress in the tutorial flow.
///
/// This widget shows dot indicators for each page of the tutorial,
/// with the current page highlighted.
class TutorialProgressIndicator extends ConsumerWidget {
  /// The total number of pages in the tutorial.
  final int totalPages;
  
  /// The page controller to monitor for page changes.
  final PageController pageController;

  /// Creates an instance of [TutorialProgressIndicator].
  const TutorialProgressIndicator({
    Key? key,
    required this.totalPages,
    required this.pageController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPage = ref.watch(tutorialCurrentPageProvider);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) => _buildDotIndicator(index, currentPage),
      ),
    );
  }

  Widget _buildDotIndicator(int index, int currentPage) {
    final bool isActive = index == currentPage;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: isActive ? 10 : 8,
      width: isActive ? 10 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.gold : AppColors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
} 