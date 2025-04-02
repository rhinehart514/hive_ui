import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

/// A shimmer loading placeholder for event cards
/// Follows HIVE's brand aesthetic with subtle animations
class ShimmerEventCard extends StatefulWidget {
  const ShimmerEventCard({Key? key}) : super(key: key);

  @override
  State<ShimmerEventCard> createState() => _ShimmerEventCardState();
}

class _ShimmerEventCardState extends State<ShimmerEventCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.cardBorder,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: LinearGradient(
                    begin: Alignment(_shimmerAnimation.value - 1, 0),
                    end: Alignment(_shimmerAnimation.value, 0),
                    colors: [
                      AppColors.cardBackground,
                      AppColors.cardBackground.withOpacity(0.5),
                      AppColors.cardBackground,
                    ],
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title placeholder
                    Container(
                      width: double.infinity,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          begin: Alignment(_shimmerAnimation.value - 1, 0),
                          end: Alignment(_shimmerAnimation.value, 0),
                          colors: [
                            AppColors.cardBackground,
                            AppColors.cardBackground.withOpacity(0.5),
                            AppColors.cardBackground,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Description placeholder
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          begin: Alignment(_shimmerAnimation.value - 1, 0),
                          end: Alignment(_shimmerAnimation.value, 0),
                          colors: [
                            AppColors.cardBackground,
                            AppColors.cardBackground.withOpacity(0.5),
                            AppColors.cardBackground,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.6,
                      height: 16,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          begin: Alignment(_shimmerAnimation.value - 1, 0),
                          end: Alignment(_shimmerAnimation.value, 0),
                          colors: [
                            AppColors.cardBackground,
                            AppColors.cardBackground.withOpacity(0.5),
                            AppColors.cardBackground,
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Action buttons placeholder
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 32,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment(_shimmerAnimation.value - 1, 0),
                              end: Alignment(_shimmerAnimation.value, 0),
                              colors: [
                                AppColors.cardBackground,
                                AppColors.cardBackground.withOpacity(0.5),
                                AppColors.cardBackground,
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment(_shimmerAnimation.value - 1, 0),
                              end: Alignment(_shimmerAnimation.value, 0),
                              colors: [
                                AppColors.cardBackground,
                                AppColors.cardBackground.withOpacity(0.5),
                                AppColors.cardBackground,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 