import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
import 'package:hive_ui/services/user_preferences_service.dart';

/// Splash/auth gate page that routes based on auth and onboarding state
class SplashGatePage extends ConsumerStatefulWidget {
  const SplashGatePage({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashGatePage> createState() => _SplashGatePageState();
}

class _SplashGatePageState extends ConsumerState<SplashGatePage> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // Add a safety timeout to prevent getting stuck on splash
    _setupNavigationTimeout();
  }

  void _setupNavigationTimeout() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!_navigated && mounted) {
        debugPrint('🚨 SplashGate: Navigation timeout reached, forcing navigation to /landing');
        setState(() {
          _navigated = true;
        });
        context.go('/landing');
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    if (_navigated) {
      debugPrint('✋ SplashGate: Already navigated, skipping navigation check');
      return;
    }
    
    debugPrint('🧭 SplashGate: Checking navigation state...');
    
    final authState = ref.read(authStateProvider);
    // Ensure preferences are initialized before checking onboarding
    await UserPreferencesService.initialize();
    final onboardingComplete = UserPreferencesService.hasCompletedOnboarding();
    final mounted = this.mounted;
    
    debugPrint('📊 SplashGate: AuthState: ${authState}, onboardingComplete: ${onboardingComplete}');

    authState.when(
      data: (user) async {
        if (!mounted || _navigated) return;
        if (user.isNotEmpty) {
          if (onboardingComplete) {
            debugPrint('🏠 SplashGate: User authenticated and onboarding complete, navigating to /home');
            _navigated = true;
            context.go('/home');
          } else {
            debugPrint('🔄 SplashGate: User authenticated but onboarding incomplete, navigating to /onboarding');
            _navigated = true;
            context.go('/onboarding');
          }
        } else {
          debugPrint('🎬 SplashGate: No user, navigating to /landing');
          _navigated = true;
          context.go('/landing');
        }
      },
      loading: () {
        debugPrint('⏳ SplashGate: Auth state is still loading');
      },
      error: (error, stack) {
        debugPrint('❌ SplashGate: Auth error: $error, navigating to /landing');
        if (!mounted || _navigated) return;
        _navigated = true;
        context.go('/landing');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
} 