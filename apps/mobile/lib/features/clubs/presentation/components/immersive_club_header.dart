import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

// Models
import 'package:hive_ui/models/club.dart';
import 'package:hive_ui/models/space.dart';

// Theme and Styling
import 'package:hive_ui/theme/app_colors.dart';

class ImmersiveClubHeader extends StatefulWidget {
  final Club club;
  final Space? space;
  final double height;
  final double parallaxOffset;
  final Function? onTapFollowButton;
  final bool isFollowing;
  final bool isManager;

  const ImmersiveClubHeader({
    Key? key,
    required this.club,
    this.space,
    required this.height,
    this.parallaxOffset = 0.0,
    this.onTapFollowButton,
    this.isFollowing = false,
    this.isManager = false,
  }) : super(key: key);

  @override
  State<ImmersiveClubHeader> createState() => _ImmersiveClubHeaderState();
}

class _ImmersiveClubHeaderState extends State<ImmersiveClubHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Parallax background image or gradient
        _buildBackgroundLayer(),

        // Particle effect overlay
        _buildParticleEffectLayer(),

        // Bottom gradient overlay for text visibility
        _buildGradientOverlay(),

        // Text content
        _buildContentLayer(),
      ],
    );
  }

  Widget _buildBackgroundLayer() {
    // Calculate parallax effect
    final parallax = widget.parallaxOffset.clamp(0.0, 50.0);

    return Positioned.fill(
      child: widget.club.bannerUrl != null
          ? Transform.translate(
              offset: Offset(0, -parallax),
              child: ShaderMask(
                shaderCallback: (rect) {
                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.black.withOpacity(0.9),
                    ],
                  ).createShader(rect);
                },
                blendMode: BlendMode.srcATop,
                child: Image.network(
                  widget.club.bannerUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) => _buildGradientBackground(),
                ),
              ),
            )
          : _buildGradientBackground(),
    );
  }

  Widget _buildGradientBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blueGrey.shade900,
            Colors.black,
          ],
        ),
      ),
    );
  }

  Widget _buildParticleEffectLayer() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return CustomPaint(
            painter: ParticlePainter(
              color: AppColors.gold.withOpacity(0.3),
              particleCount: 20,
              animationValue: _animationController.value,
            ),
          );
        },
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: widget.height * 0.7,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.8),
              Colors.black,
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildContentLayer() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Club name with glow effect
            Text(
              widget.club.name,
              style: GoogleFonts.montserrat(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  BoxShadow(
                    color: AppColors.gold.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),

            // Tagline or description
            Text(
              widget.club.mission ?? widget.club.description.split('.').first,
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w300,
              ),
            ),

            const SizedBox(height: 12),

            // Status indicators
            Row(
              children: [
                // Trending indicator
                if (widget.club.followersCount > 50 ||
                    widget.club.memberCount > 100)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.gold.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.trending_up,
                          size: 14,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Trending',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.gold,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (widget.club.followersCount > 50 ||
                    widget.club.memberCount > 100)
                  const SizedBox(width: 8),

                // Member count
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.people_outline,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.club.memberCount} members',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for particle effects
class ParticlePainter extends CustomPainter {
  final Color color;
  final int particleCount;
  final double animationValue;

  ParticlePainter({
    required this.color,
    required this.particleCount,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill;

    for (int i = 0; i < particleCount; i++) {
      // Use deterministic "random" values based on index and animation
      final x = (((i * 7919) % 997) / 997) * size.width;
      final y = (((i * 6577) % 887) / 887) * size.height;

      // Vary size based on position and animation
      final particleSize = 2.0 + ((x / size.width) * 3);

      // Make particles pulse slightly with the animation
      final pulseSize = particleSize * (0.8 + (animationValue * 0.4));

      // Draw the particle
      canvas.drawCircle(
        Offset(x, y),
        pulseSize,
        paint,
      );

      // Some particles have connecting lines
      if (i > 0 && i % 3 == 0) {
        final prevX = (((i - 1) * 7919) % 997) / 997 * size.width;
        final prevY = (((i - 1) * 6577) % 887) / 887 * size.height;

        // Adjust line opacity based on distance
        final distance =
            sqrt(((x - prevX) * (x - prevX) + (y - prevY) * (y - prevY)));
        final maxDistance = size.width * 0.2;

        if (distance < maxDistance) {
          final lineOpacity = (1.0 - (distance / maxDistance)) * 0.3;
          final linePaint = Paint()
            ..color = color.withOpacity(lineOpacity)
            ..strokeWidth = 0.5;

          canvas.drawLine(
            Offset(x, y),
            Offset(prevX, prevY),
            linePaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
