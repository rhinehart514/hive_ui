import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/components/navigation_bar.dart';
import 'package:hive_ui/core/navigation/transitions.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/huge_icons.dart';
import 'package:google_fonts/google_fonts.dart';

/// Provider to control the visibility of the navigation bar
final navigationBarVisibilityProvider = StateProvider<bool>((ref) => true);

/// Error boundary widget to catch rendering errors
class ErrorBoundaryWidget extends StatefulWidget {
  final Widget child;

  const ErrorBoundaryWidget({
    super.key,
    required this.child,
  });

  @override
  State<ErrorBoundaryWidget> createState() => _ErrorBoundaryWidgetState();
}

class _ErrorBoundaryWidgetState extends State<ErrorBoundaryWidget> {
  bool _hasError = false;
  FlutterErrorDetails? _errorDetails;

  @override
  void initState() {
    super.initState();
    FlutterError.onError = _handleFlutterError;
  }

  void _handleFlutterError(FlutterErrorDetails details) {
    // Only update state in the next frame to avoid setState during layout/paint
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorDetails = details;
        });
      }
    });

    // Also print to console
    FlutterError.presentError(details);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Material(
        color: Colors.black,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.gold),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The app encountered a rendering error. Try restarting the app.',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _errorDetails = null;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Try Again',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }

  @override
  void dispose() {
    FlutterError.onError = FlutterError.presentError;
    super.dispose();
  }
}

class Shell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const Shell({
    super.key,
    required this.navigationShell,
  });

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  // Track previous index for transition direction
  int _previousIndex = 0;
  
  // Store a reference to the ProviderContainer
  late ProviderContainer _container;
  
  @override
  void initState() {
    super.initState();
    // Create a standalone container to manage providers
    _container = ProviderContainer();
  }
  
  @override
  void dispose() {
    // Dispose of the container when the widget is disposed
    _container.dispose();
    super.dispose();
  }

  void _onTap(BuildContext context, int index) {
    // Apply haptic feedback
    NavigationTransitions.applyNavigationFeedback(
      type: NavigationFeedbackType.tabChange,
    );

    // Store previous index for transition
    setState(() {
      _previousIndex = widget.navigationShell.currentIndex;
    });

    // Navigate to the branch
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate bottom navigation bar height
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final navBarHeight =
        56.0 + bottomPadding; // Standard nav bar height + safe area

    // Get current index
    final currentIndex = widget.navigationShell.currentIndex;
    
    // Check if navigation bar should be visible
    final isNavBarVisible = _container.read(navigationBarVisibilityProvider);
    
    // Wrap the entire shell in an error boundary
    return UncontrolledProviderScope(
      container: _container,
      child: ErrorBoundaryWidget(
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Main content with smooth tab transition
              Positioned.fill(
                child: SafeArea(
                  bottom: false,
                  // Use a simpler approach to avoid animation issues
                  child: widget.navigationShell,
                ),
              ),

              // Bottom navigation bar
              if (isNavBarVisible)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    child: HiveNavigationBar(
                      selectedIndex: currentIndex,
                      onDestinationSelected: (index) => _onTap(context, index),
                      style: HiveNavigationBarStyle.glass,
                      selectedItemColor: AppColors.gold,
                      showLabels: true,
                      destinations: const [
                        HiveNavigationDestination(
                          icon: HugeIcons.home,
                          selectedIcon: HugeIcons.home,
                          label: 'Feed',
                        ),
                        HiveNavigationDestination(
                          icon: HugeIcons.constellation,
                          selectedIcon: HugeIcons.constellation,
                          label: 'Spaces',
                        ),
                        HiveNavigationDestination(
                          icon: HugeIcons.user,
                          selectedIcon: HugeIcons.user,
                          label: 'Profile',
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          extendBody: true, // Allow content to go under the nav bar
        ),
      ),
    );
  }
}
