import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/club.dart';
import 'package:go_router/go_router.dart';

/// Club header component that displays the banner image with a parallax effect
class ClubHeader extends StatelessWidget {
  final Club club;
  final double scrollOffset;
  final double bannerHeight;

  const ClubHeader({
    super.key,
    required this.club,
    this.scrollOffset = 0,
    this.bannerHeight = 250,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Banner image with parallax effect
        _buildBannerImage(context),

        // Gradient overlay for better readability
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
                stops: const [0.6, 1.0],
              ),
            ),
          ),
        ),

        // Club logo
        Positioned(
          left: 20,
          bottom: 20,
          child: _buildClubLogo(),
        ),

        // Back button
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          child: _buildBackButton(context),
        ),

        // Member count
        Positioned(
          bottom: 16,
          right: 16,
          child: _buildMemberCount(),
        ),
      ],
    );
  }

  Widget _buildBannerImage(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Calculate the parallax effect based on scroll offset
    final parallaxOffset = scrollOffset * 0.5;

    return SizedBox(
      height: bannerHeight,
      width: screenWidth,
      child: club.bannerUrl != null
          ? ShaderMask(
              shaderCallback: (rect) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Colors.transparent],
                  stops: [0.8, 1.0],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: Transform.translate(
                offset: Offset(0, parallaxOffset),
                child: Image.network(
                  club.bannerUrl!,
                  fit: BoxFit.cover,
                  height: bannerHeight + 50, // Add extra height for parallax
                  width: screenWidth,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholderBanner();
                  },
                ),
              ),
            )
          : _buildPlaceholderBanner(),
    );
  }

  Widget _buildPlaceholderBanner() {
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 48,
              color: Colors.white.withOpacity(0.6),
            ),
            const SizedBox(height: 8),
            Text(
              club.name,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClubLogo() {
    const logoSize = 80.0;

    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: club.logoUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(logoSize / 2),
              child: Image.network(
                club.logoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildLogoFallback();
                },
              ),
            )
          : _buildLogoFallback(),
    );
  }

  Widget _buildLogoFallback() {
    return CircleAvatar(
      radius: 40,
      backgroundColor: _getColorFromClubName(club.name),
      child: Text(
        _getInitials(club.name),
        style: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  // Extract initials from club name
  String _getInitials(String name) {
    final words = name.split(' ');
    if (words.length > 1) {
      return words.take(2).map((word) => word.isNotEmpty ? word[0] : '').join();
    } else if (name.isNotEmpty) {
      return name.substring(0, 1);
    } else {
      return 'C';
    }
  }

  // Generate a consistent color based on club name
  Color _getColorFromClubName(String name) {
    if (name.isEmpty) return Colors.blueGrey;

    final colorValue =
        name.codeUnits.fold<int>(0, (int result, int unit) => result + unit);

    final colors = [
      Colors.blue.shade800,
      Colors.purple.shade800,
      Colors.red.shade800,
      Colors.green.shade800,
      Colors.orange.shade800,
      Colors.teal.shade800,
      Colors.indigo.shade800,
      Colors.pink.shade800,
    ];

    return colors[colorValue % colors.length];
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.pop();
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.arrow_back,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildMemberCount() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.people,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '${club.memberCount} members',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
