import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/core/navigation/routes.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// HIVE Landing Page - "Campus, now playable."
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  
  // Feature flags
  static const String targetCampus = "University at Buffalo";
  static const bool showVBetaBadge = true;
  static const bool showV1Countdown = true;
  static const String v1DateUTC = "2025-08-20T00:00:00Z";

  // Animation controllers
  late AnimationController _hexController;
  late AnimationController _badgeController;
  late AnimationController _rotatorController;
  late AnimationController _navbarController;
  
  // Animations
  late Animation<double> _hexAnimation;
  late Animation<Offset> _badgeSlideAnimation;
  late Animation<double> _badgeOpacityAnimation;
  late Animation<double> _navbarOpacityAnimation;
  late Animation<Offset> _navbarSlideAnimation;
  
  // Controllers
  final ScrollController _scrollController = ScrollController();
  
  // State
  bool _showNavbar = false;
  bool _showStickyFooter = false;
  double _mouseX = 0.0;
  double _mouseY = 0.0;
  int _currentRotatorIndex = 0;
  String _countdownText = "";
  Timer? _rotatorTimer;
  Timer? _countdownTimer;
  bool _showScrollHint = true;

  // Rotator words
  final List<String> _rotatorWords = [
    'schedule',
    'dorm',
    'club',
    'voice',
    'campus'
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupScrollListener();
    _startAnimationSequence();
    _startRotatorTimer();
    _startCountdownTimer();
  }

  void _initializeAnimations() {
    _hexController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );

    _badgeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _rotatorController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _navbarController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Hex animation: 0→1.12→0.92→1.0
    _hexAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.12)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.12, end: 0.92)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.92, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
    ]).animate(_hexController);

    _badgeSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _badgeController,
      curve: Curves.easeOut,
    ));

    _badgeOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_badgeController);

    _navbarOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_navbarController);

    _navbarSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _navbarController,
      curve: Curves.easeOut,
    ));
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final offset = _scrollController.offset;
      final screenHeight = MediaQuery.of(context).size.height;
      
      final showNavbar = offset > 24 || offset > screenHeight * 0.7;
      if (showNavbar != _showNavbar) {
        setState(() => _showNavbar = showNavbar);
        if (showNavbar) {
          _navbarController.forward();
        } else {
          _navbarController.reverse();
        }
      }

      final showFooter = offset > screenHeight;
      if (showFooter != _showStickyFooter) {
        setState(() => _showStickyFooter = showFooter);
      }

      if (offset > 12 && _showScrollHint) {
        setState(() => _showScrollHint = false);
      } else if (offset <= 12 && !_showScrollHint) {
        setState(() => _showScrollHint = true);
      }
    });
  }

  void _startAnimationSequence() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _hexController.forward().then((_) {
        HapticFeedback.lightImpact();
        Future.delayed(const Duration(milliseconds: 100), () {
          HapticFeedback.lightImpact();
          Future.delayed(const Duration(milliseconds: 100), () {
            HapticFeedback.mediumImpact();
          });
        });
      });
    });

    if (showVBetaBadge) {
      Future.delayed(const Duration(milliseconds: 750), () {
        _badgeController.forward();
      });
    }
  }

  void _startRotatorTimer() {
    _rotatorTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _rotatorController.forward().then((_) {
          setState(() {
            _currentRotatorIndex = (_currentRotatorIndex + 1) % _rotatorWords.length;
          });
          _rotatorController.reverse();
        });
      }
    });
  }

  void _startCountdownTimer() {
    if (!showV1Countdown) return;
    
    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    final v1Date = DateTime.parse(v1DateUTC);
    final now = DateTime.now().toUtc();
    final difference = v1Date.difference(now);

    if (difference.isNegative) {
      setState(() => _countdownText = "LIVE NOW");
    } else {
      final days = difference.inDays;
      final hours = difference.inHours % 24;
      final minutes = difference.inMinutes % 60;
      setState(() => _countdownText = "${days}d ${hours}h ${minutes}m");
    }
  }

  void _handleMouseMove(PointerEvent details) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;
    final parallaxStrength = isMobile ? 0.04 : 0.05;
    
    setState(() {
      _mouseX = (details.position.dx / size.width - 0.5) * 2 * parallaxStrength;
      _mouseY = (details.position.dy / size.height - 0.5) * 2 * parallaxStrength;
    });
  }

  void _handleSignUp() {
    HapticFeedback.mediumImpact();
    debugPrint('🔘 Sign up with .edu pressed');
    debugPrint('🔘 Navigating to: ${AppRoutes.register}');
    context.go(AppRoutes.register);
  }

  void _handleLogin() {
    HapticFeedback.lightImpact();
    debugPrint('🔘 Log in pressed');
    debugPrint('🔘 Navigating to: ${AppRoutes.signIn}');
    context.go(AppRoutes.signIn);
  }

  @override
  void dispose() {
    _hexController.dispose();
    _badgeController.dispose();
    _rotatorController.dispose();
    _navbarController.dispose();
    _scrollController.dispose();
    _rotatorTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0C0E),
      body: MouseRegion(
        onHover: _handleMouseMove,
        child: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeroSection(isMobile, screenSize),
                ),
                SliverToBoxAdapter(
                  child: _buildVideoSection(),
                ),
                SliverToBoxAdapter(
                  child: _buildTriptychSection(),
                ),
                SliverToBoxAdapter(
                  child: _buildSocialProofStrip(),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
            _buildAnimatedHexGlyph(),
            if (_showNavbar) _buildNavbar(isMobile),
            if (_showStickyFooter) _buildStickyFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedHexGlyph() {
    return AnimatedBuilder(
      animation: _hexAnimation,
      builder: (context, child) {
        final scale = _hexAnimation.value;
        final isCompleted = _hexController.isCompleted;
        final screenSize = MediaQuery.of(context).size;
        
        return AnimatedPositioned(
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
          top: isCompleted ? 20 : screenSize.height / 2 - 32,
          left: isCompleted ? 20 : screenSize.width / 2 - 32,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 650),
            curve: Curves.elasticOut,
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, glowValue, child) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.gold,
                        AppColors.gold.withOpacity(0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withOpacity(0.6 * glowValue),
                        blurRadius: 24 * glowValue,
                        spreadRadius: 4 * glowValue,
                      ),
                      BoxShadow(
                        color: AppColors.gold.withOpacity(0.3),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Image.asset(
                          'assets/images/hivelogo.png',
                          width: 64,
                          height: 64,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.hexagon,
                              color: Color(0xFF0B0C0E),
                              size: 32,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHeroSection(bool isMobile, Size screenSize) {
    return Container(
      height: screenSize.height,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showVBetaBadge) _buildVBetaBadge(),
          if (showVBetaBadge) const SizedBox(height: 16),
          Transform.translate(
            offset: Offset(
              _mouseX * screenSize.width * (isMobile ? 0.04 : 0.05),
              _mouseY * screenSize.height * (isMobile ? 0.04 : 0.05),
            ),
            child: Text(
              'Campus, now playable.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w900,
                fontSize: isMobile ? 36 : 48,
                color: Colors.white,
                height: 1.1,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildRotatorLine(),
          const SizedBox(height: 16),
          if (targetCampus.isNotEmpty) _buildCampusSubline(),
          const SizedBox(height: 48),
          _buildCTAs(isMobile),
          const SizedBox(height: 80),
          if (_showScrollHint) _buildScrollHint(),
        ],
      ),
    );
  }

  Widget _buildVBetaBadge() {
    return AnimatedBuilder(
      animation: _badgeController,
      builder: (context, child) {
        return SlideTransition(
          position: _badgeSlideAnimation,
          child: FadeTransition(
            opacity: _badgeOpacityAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.gold.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Text(
                'vBETA · LIVE NOW',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRotatorLine() {
    return AnimatedBuilder(
      animation: _rotatorController,
      builder: (context, child) {
        return SizedBox(
          height: 24,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (Widget child, Animation<double> animation) {
              final slideAnimation = Tween<Offset>(
                begin: const Offset(0, 0.5),
                end: Offset.zero,
              ).animate(animation);
              
              return SlideTransition(
                position: slideAnimation,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: Text(
              'Finally, your ${_rotatorWords[_currentRotatorIndex]}.',
              key: ValueKey(_currentRotatorIndex),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withOpacity(0.8),
                height: 1.4,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCampusSubline() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Text(
        'Built for $targetCampus. Track pop-up concerts, dorm rivalries, and more.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          color: Colors.white.withOpacity(0.6),
          height: 1.5,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }

  Widget _buildCTAs(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: _buildPrimaryCTA(),
          ),
          const SizedBox(height: 16),
          _buildSecondaryCTA(),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPrimaryCTA(),
          const SizedBox(width: 16),
          _buildSecondaryCTA(),
        ],
      );
    }
  }

  Widget _buildPrimaryCTA() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      curve: Curves.elasticOut,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  AppColors.gold,
                  AppColors.gold.withOpacity(0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.5 * value),
                  blurRadius: 16 * value,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.3 * value),
                  blurRadius: 32 * value,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _handleSignUp();
                },
                borderRadius: BorderRadius.circular(24),
                splashColor: Colors.white.withOpacity(0.2),
                highlightColor: Colors.white.withOpacity(0.1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, textValue, child) {
                        return Transform.translate(
                          offset: Offset(0, 10 * (1 - textValue)),
                          child: AnimatedOpacity(
                            opacity: textValue,
                            duration: const Duration(milliseconds: 600),
                            child: Text(
                              'Sign up with .edu',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0B0C0E),
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecondaryCTA() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1400),
      curve: Curves.elasticOut,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.3 * value),
                width: 1.5,
              ),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.08 * value),
                  Colors.white.withOpacity(0.03 * value),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _handleLogin();
                  },
                  borderRadius: BorderRadius.circular(24),
                  splashColor: Colors.white.withOpacity(0.1),
                  highlightColor: Colors.white.withOpacity(0.05),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOut,
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, textValue, child) {
                          return Transform.translate(
                            offset: Offset(0, 10 * (1 - textValue)),
                            child: AnimatedOpacity(
                              opacity: textValue,
                              duration: const Duration(milliseconds: 800),
                              child: Text(
                                'Log in ▼',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.95),
                                  letterSpacing: 0.3,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScrollHint() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 2000),
      tween: Tween(begin: 0.3, end: 1.0),
      builder: (context, opacity, child) {
        return AnimatedOpacity(
          opacity: opacity,
          duration: const Duration(milliseconds: 1000),
              child: Column(
            children: [
              Text(
                'Scroll to explore',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 8),
              Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white.withOpacity(0.5),
                size: 24,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoSection() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Container(
          width: double.infinity,
          height: 400,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.black.withOpacity(0.4),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    color: AppColors.gold.withOpacity(0.8),
                    size: 80,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '12s Noir Campus Montage',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Premium visuals with gold accents only',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.gold.withOpacity(0.3),
                      width: 1,
                    ),
                ),
                child: const Text(
                    'Fallback JPG for data-saver',
                    style: TextStyle(
                    color: AppColors.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTriptychSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          Text(
            'Three Pillars',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          _buildTriptychItem('Feed', 'Real-time campus pulse', Icons.dynamic_feed),
          const SizedBox(height: 32),
          _buildTriptychItem('Spaces', 'Your clubs, dorms, classes', Icons.groups),
          const SizedBox(height: 32),
          _buildTriptychItem('Rituals', 'Build tools together', Icons.build_circle),
        ],
      ),
    );
  }

  Widget _buildTriptychItem(String title, String description, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    AppColors.gold.withOpacity(0.15),
                    AppColors.gold.withOpacity(0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border.all(
                  color: AppColors.gold.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: 48,
                color: AppColors.gold,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                ),
              ),
            ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialProofStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Container(
            width: math.min(960, MediaQuery.of(context).size.width - 48),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.3),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Text(
                  'Trusted by 17 campus builders',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.gold.withOpacity(0.3),
                              AppColors.gold.withOpacity(0.1),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          border: Border.all(
                            color: AppColors.gold.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: AppColors.gold,
                          size: 24,
                        ),
                      );
                    },
                  ),
                ),
              ],
                      ),
                    ),
                  ],
      ),
    );
  }

    Widget _buildNavbar(bool isMobile) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _navbarController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -68 * (1 - _navbarOpacityAnimation.value)),
            child: AnimatedOpacity(
              opacity: _navbarOpacityAnimation.value,
              duration: const Duration(milliseconds: 300),
              curve: Curves.fastOutSlowIn,
              child: Container(
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0C0E).withOpacity(0.95),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.elasticOut,
                          tween: Tween(begin: 0.8, end: 1.0),
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.gold.withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.hexagon,
                                  color: Color(0xFF0B0C0E),
                                  size: 20,
                                ),
                              ),
                            );
                          },
                        ),
                        const Spacer(),
                        if (!isMobile) ...[
                          _buildNavLink('Tour'),
                          const SizedBox(width: 32),
                          _buildNavLink('Builders'),
                          const SizedBox(width: 32),
                          _buildNavLink('Partner'),
                        ] else
                          IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white),
                            onPressed: () {},
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavLink(String text) {
    return TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(
        foregroundColor: Colors.white.withOpacity(0.8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
                  child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildStickyFooter() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 600),
        curve: Curves.fastOutSlowIn,
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 64 * (1 - value)),
            child: AnimatedOpacity(
              opacity: value,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0C0E).withOpacity(0.98),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.gold.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOut,
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, textValue, child) {
                              return Transform.translate(
                                offset: Offset(-20 * (1 - textValue), 0),
                                child: AnimatedOpacity(
                                  opacity: textValue,
                                  duration: const Duration(milliseconds: 600),
                                  child: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: 0.3,
                                      ),
                                      children: [
                                        const TextSpan(text: 'Launching at '),
                                        const TextSpan(
                                          text: targetCampus,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        if (showV1Countdown) ...[
                                          const TextSpan(text: ' · v1 in '),
                                          TextSpan(
                                            text: _countdownText,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.gold,
                                              shadows: [
                                                Shadow(
                                                  color: AppColors.gold.withOpacity(0.3),
                                                  blurRadius: 8,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                      ),
                    ),
                  ),
                              );
                            },
                          ),
                        ),
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.elasticOut,
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, buttonValue, child) {
                            return Transform.scale(
                              scale: 0.8 + (0.2 * buttonValue),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: AppColors.gold.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: IconButton(
                                  onPressed: _handleSignUp,
                                  icon: const Icon(
                                    Icons.arrow_forward,
                                    color: AppColors.gold,
                                    size: 20,
                                  ),
                                ),
                        ),
                      );
                    },
                      ),
                      ],
                    ),
                  ),
            ),
          ),
        ),
          );
        },
      ),
    );
  }
} 