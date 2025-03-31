import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_theme.dart';
import 'package:hive_ui/utils/url_launcher_util.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  final List<String> _phrases = [
    'Campus',
    'Future',
    'Events',
    'Clubs',
    'People',
    'Spaces',
    'Parties',
    'App',
  ];
  int _currentPhraseIndex = 0;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Initialize the animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));

    // Start the animation cycle after a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startAnimation();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startAnimation() async {
    if (!mounted || _isAnimating) return;

    _isAnimating = true;

    while (mounted) {
      await _animationController.forward();
      await Future.delayed(const Duration(seconds: 2));
      await _animationController.reverse();

      if (!mounted) break;

      setState(() {
        _currentPhraseIndex = (_currentPhraseIndex + 1) % _phrases.length;
      });
    }

    _isAnimating = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Logo
              Image.asset(
                'assets/images/hivelogo.png',
                width: 100,
                height: 100,
              ),
              const SizedBox(height: AppTheme.spacing16),
              // HIVE text
              Text(
                'HIVE',
                style: AppTheme.displayLarge.copyWith(
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              // Finally, Your [Animated] text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Finally, Your ',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Text(
                        _phrases[_currentPhraseIndex],
                        key: ValueKey<String>(_phrases[_currentPhraseIndex]),
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    '.',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 2),
              // Get Started Button
              SizedBox(
                width: double.infinity,
                height: AppTheme.spacing56,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    context.push('/create-account');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Get Started',
                    style: AppTheme.labelLarge.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing24),
              // Terms and Privacy
              TextButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: AppColors.grey700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: Text(
                          'Terms of Service & Privacy Policy',
                          style: AppTheme.titleMedium.copyWith(
                            color: AppColors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'By using HIVE, you agree to our Terms of Service and Privacy Policy.',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppColors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'HIVE is a platform designed for university students to connect with campus organizations, events, and each other in a safe and respectful environment.',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppColors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'HIVE, while independently developed and not currently affiliated with the University at Buffalo, adheres to the UB Student Code of Conduct guidelines as a standard for our community.',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppColors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              InkWell(
                                onTap: () async {
                                  // Open external URL to UB Code of Conduct
                                  const url =
                                      'https://www.buffalo.edu/content/dam/www/studentlife/units/uls/student-conduct/UB%20Student%20Code%20of%20Conduct%202024-2025.pdf';
                                  await UrlLauncherUtil.openPdf(url);
                                },
                                child: Text(
                                  'Read UB Student Code of Conduct',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppColors.gold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Your privacy is important to us. We collect only necessary data to provide our services and do not share your personal information with third parties without your consent.',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppColors.white,
                                ),
                              ),
                              const SizedBox(height: 20),
                              InkWell(
                                onTap: () async {
                                  // Open external URL to HIVE website
                                  const url = 'https://thehiveuni.com';
                                  await UrlLauncherUtil.openWebPage(url);
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: AppColors.gold, width: 1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Visit thehiveuni.com for more information',
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: AppColors.gold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.black,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Close',
                              style: AppTheme.labelLarge.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.white,
                ),
                child: Text(
                  'Terms of Service and Privacy Policy',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppColors.white,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing24),
            ],
          ),
        ),
      ),
    );
  }
}
