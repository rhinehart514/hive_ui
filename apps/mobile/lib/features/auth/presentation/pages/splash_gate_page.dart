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
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Add a safety timeout to prevent getting stuck on splash
    _setupNavigationTimeout();
    _verifyPreferencesInitialization();
  }
  
  /// Verify that preferences are initialized
  Future<void> _verifyPreferencesInitialization() async {
    try {
      // Initialize if not already initialized
      await UserPreferencesService.initialize();
      setState(() {
        _isInitialized = true;
      });
      debugPrint('✅ SplashGate: UserPreferencesService initialized successfully');
      
      // Immediately check navigation after we know preferences are ready
      if (mounted) {
        _checkAndNavigate();
      }
    } catch (e) {
      debugPrint('❌ SplashGate: Error initializing preferences: $e');
      // If we can't initialize preferences, we'll have to navigate based on auth state only
      _isInitialized = false;
    }
  }

  void _setupNavigationTimeout() {
    // Set up a primary timeout for normal navigation
    Future.delayed(const Duration(seconds: 5), () {
      if (!_navigated && mounted) {
        debugPrint('⚠️ SplashGate: Navigation timeout reached, forcing navigation check');
        _checkAndNavigate(isTimeout: true);
      }
    });
    
    // Set up a hard timeout as a last resort
    Future.delayed(const Duration(seconds: 10), () {
      if (!_navigated && mounted) {
        debugPrint('🚨 SplashGate: Hard navigation timeout reached, forcing navigation to /landing');
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
    // Only check navigation if we haven't already navigated
    if (!_navigated && _isInitialized) {
      _checkAndNavigate();
    }
  }
  
  /// Listen for auth state changes
  @override
  void didUpdateWidget(SplashGatePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // React to auth state changes by rechecking navigation
    if (!_navigated && _isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndNavigate();
      });
    }
  }

  Future<void> _checkAndNavigate({bool isTimeout = false}) async {
    if (_navigated) {
      debugPrint('✋ SplashGate: Already navigated, skipping navigation check');
      return;
    }
    
    debugPrint('🧭 SplashGate: Checking navigation state${isTimeout ? " (timeout triggered)" : ""}...');
    
    try {
      // Force a re-read of preferences if this is a timeout call
      if (isTimeout) {
        try {
          await UserPreferencesService.initialize();
          debugPrint('🔄 SplashGate: Re-initialized preferences during timeout check');
        } catch (e) {
          debugPrint('⚠️ SplashGate: Error re-initializing preferences: $e');
        }
      }
      
      final authState = ref.read(authStateProvider);
      final onboardingComplete = UserPreferencesService.hasCompletedOnboarding();
      final hasAcceptedTerms = ref.read(userPreferencesProvider).hasAcceptedTerms;
      
      debugPrint('📊 SplashGate: AuthState: $authState, onboardingComplete: $onboardingComplete, hasAcceptedTerms: $hasAcceptedTerms');

      if (!mounted) return;

      authState.when(
        data: (user) async {
          if (!mounted || _navigated) return;
          
          if (user.isNotEmpty) {
            if (onboardingComplete) {
              if (hasAcceptedTerms) {
                debugPrint('🏠 SplashGate: User authenticated, onboarding complete, and terms accepted, navigating to /home');
                _setNavigated('/home');
              } else {
                debugPrint('📜 SplashGate: User authenticated and onboarding complete, but terms not accepted, navigating to /terms');
                _setNavigated('/terms');
              }
            } else {
              debugPrint('🔄 SplashGate: User authenticated but onboarding incomplete, navigating to /onboarding');
              _setNavigated('/onboarding');
            }
          } else {
            debugPrint('🎬 SplashGate: No user, navigating to /landing');
            _setNavigated('/landing');
          }
        },
        loading: () {
          debugPrint('⏳ SplashGate: Auth state is still loading');
          
          // If this is a timeout call, we need to make a decision even without auth data
          if (isTimeout) {
            debugPrint('⏱️ SplashGate: Auth still loading during timeout, forcing navigation to /landing');
            _setNavigated('/landing');
          }
        },
        error: (error, stack) {
          debugPrint('❌ SplashGate: Auth error: $error, navigating to /landing');
          if (!mounted || _navigated) return;
          _setNavigated('/landing');
        },
      );
    } catch (e) {
      debugPrint('❌ SplashGate: Unexpected error during navigation check: $e');
      if (!mounted || _navigated) return;
      
      // Fall back to landing page on any error
      _setNavigated('/landing');
    }
  }
  
  /// Helper to set navigated flag and perform navigation
  void _setNavigated(String route) {
    setState(() {
      _navigated = true;
    });
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    // React to auth state changes in the build method
    ref.listen(authStateProvider, (previous, next) {
      if (!_navigated && _isInitialized && next != previous) {
        debugPrint('👂 SplashGate: Auth state changed, rechecking navigation');
        _checkAndNavigate();
      }
    });
    
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
} 