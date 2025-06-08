import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/providers/platform_providers.dart';
import 'package:hive_ui/core/ui/apple_ui_adapters.dart';

/// Example page demonstrating Apple platform-specific UI and features
class ApplePlatformExamplePage extends ConsumerWidget {
  const ApplePlatformExamplePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appleService = ref.watch(applePlatformServiceProvider);
    final isPlatformInitialized = ref.watch(platformInitializationProvider).maybeWhen(
      data: (_) => true,
      orElse: () => false,
    );
    
    // Get UI adapters for building platform-specific components
    final ui = appleService.ui;
    
    // Use platform-specific app bar
    final appBar = ui.getAppBar(
      context: context,
      title: 'Apple Platform Example',
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showAboutDialog(context, appleService),
        ),
      ],
    );
    
    return ui.getScaffold(
      context: context,
      appBar: appBar,
      body: !isPlatformInitialized
          ? const Center(child: CircularProgressIndicator(color: AppleUIAdapters.accentColor))
          : _buildContent(context, ref, appleService),
    );
  }
  
  Widget _buildContent(BuildContext context, WidgetRef ref, dynamic appleService) {
    final ui = appleService.ui;
    
    return SingleChildScrollView(
      physics: appleService.platform.getScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'HIVE on Apple Platforms',
              style: TextStyle(
                fontSize: 28.0,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24.0),
            
            // Platform information card
            ui.getCard(
              context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Platform Features',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  _buildFeatureItem(
                    'Native UI Components',
                    'Platform-specific navigation, buttons, and forms',
                  ),
                  const SizedBox(height: 12.0),
                  _buildFeatureItem(
                    'Sign in with Apple',
                    'Secure authentication with Apple ID',
                  ),
                  const SizedBox(height: 12.0),
                  _buildFeatureItem(
                    'Calendar Integration',
                    'Add events directly to Apple Calendar',
                  ),
                  const SizedBox(height: 12.0),
                  _buildFeatureItem(
                    'Native Sharing',
                    'Share content using native share sheet',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),
            
            // UI Components Examples
            const Text(
              'UI Components',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16.0),
            
            // Buttons
            ui.getCard(
              context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Buttons',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ui.getButton(
                        context: context,
                        text: 'Primary',
                        onPressed: () => _showButtonPressed(context, appleService, 'Primary'),
                      ),
                      ui.getButton(
                        context: context,
                        text: 'Secondary',
                        isPrimary: false,
                        onPressed: () => _showButtonPressed(context, appleService, 'Secondary'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Center(
                    child: ui.getButton(
                      context: context,
                      text: 'Destructive',
                      isDestructive: true,
                      onPressed: () => _showButtonPressed(context, appleService, 'Destructive'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            
            // Text Field
            ui.getCard(
              context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Text Field',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  ui.getTextField(
                    context: context,
                    placeholder: 'Enter your name',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            
            // Controls
            ui.getCard(
              context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Controls',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  _ControlsExample(appleService: appleService),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            
            // Platform Features
            ui.getCard(
              context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Platform Features',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ui.getButton(
                        context: context,
                        text: 'Sign In',
                        onPressed: () => _handleSignInWithApple(context, appleService),
                        icon: Icons.apple,
                      ),
                      ui.getButton(
                        context: context,
                        text: 'Share',
                        onPressed: () => _handleShare(context, appleService),
                        icon: Icons.share,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ui.getButton(
                        context: context,
                        text: 'Calendar',
                        onPressed: () => _addToCalendar(context, appleService),
                        icon: Icons.calendar_today,
                      ),
                      ui.getButton(
                        context: context,
                        text: 'App Store',
                        onPressed: () => _openAppStore(context, appleService),
                        icon: Icons.shop,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32.0),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureItem(String title, String description) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFFEEB700),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAboutDialog(BuildContext context, dynamic appleService) {
    appleService.showPlatformDialog(
      context: context, 
      title: 'About Apple Integration', 
      message: 'This screen demonstrates HIVE UI components and features specifically adapted for Apple platforms (iOS and macOS).',
      confirmText: 'Got it',
    );
  }
  
  void _showButtonPressed(BuildContext context, dynamic appleService, String buttonType) {
    appleService.showPlatformDialog(
      context: context, 
      title: 'Button Pressed', 
      message: 'You pressed the $buttonType button',
      confirmText: 'OK',
    );
  }
  
  void _handleSignInWithApple(BuildContext context, dynamic appleService) async {
    final result = await appleService.signInWithApple();
    
    if (result != null) {
      appleService.showPlatformDialog(
        context: context, 
        title: 'Sign In Successful', 
        message: 'Welcome ${result['name']['firstName'] ?? 'User'}!',
        confirmText: 'Continue',
      );
    } else {
      appleService.showPlatformDialog(
        context: context, 
        title: 'Sign In Cancelled', 
        message: 'Apple sign in was cancelled or failed',
        confirmText: 'OK',
      );
    }
  }
  
  void _handleShare(BuildContext context, dynamic appleService) {
    appleService.shareContent(
      context: context,
      text: 'Check out HIVE - the premium social platform for students!',
      subject: 'HIVE App Invitation',
    );
  }
  
  void _addToCalendar(BuildContext context, dynamic appleService) async {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    
    final success = await appleService.addToCalendar(
      title: 'HIVE Platform Launch',
      description: 'Join us for the official launch of the HIVE platform!',
      startDate: tomorrow,
      endDate: tomorrow.add(const Duration(hours: 2)),
      location: 'Student Union',
    );
    
    appleService.showPlatformDialog(
      context: context, 
      title: success ? 'Event Added' : 'Failed to Add Event', 
      message: success 
          ? 'Event has been added to your calendar'
          : 'There was an error adding the event to your calendar',
      confirmText: 'OK',
    );
  }
  
  void _openAppStore(BuildContext context, dynamic appleService) {
    appleService.openAppStore();
  }
}

/// Stateful widget for showing controls with state
class _ControlsExample extends StatefulWidget {
  final dynamic appleService;
  
  const _ControlsExample({
    Key? key,
    required this.appleService,
  }) : super(key: key);

  @override
  _ControlsExampleState createState() => _ControlsExampleState();
}

class _ControlsExampleState extends State<_ControlsExample> {
  double _sliderValue = 0.5;
  bool _switchValue = true;
  String _segmentValue = 'daily';
  
  @override
  Widget build(BuildContext context) {
    final ui = widget.appleService.ui;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Slider
        Row(
          children: [
            const SizedBox(width: 8),
            const Text('Volume:', style: TextStyle(color: Colors.white)),
            const SizedBox(width: 16),
            Expanded(
              child: ui.getSlider(
                context: context,
                value: _sliderValue,
                onChanged: (value) {
                  setState(() {
                    _sliderValue = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(_sliderValue * 100).toInt()}%',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
        ),
        const SizedBox(height: 16),
        
        // Switch
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Notifications:', style: TextStyle(color: Colors.white)),
            ui.getSwitch(
              context: context,
              value: _switchValue,
              onChanged: (value) {
                setState(() {
                  _switchValue = value;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Segmented Control
        const Text('View Mode:', style: TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        ui.getSegmentedControl<String>(
          context: context,
          children: {
            'daily': const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text('Daily'),
            ),
            'weekly': const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text('Weekly'),
            ),
            'monthly': const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text('Monthly'),
            ),
          },
          groupValue: _segmentValue,
          onValueChanged: (value) {
            if (value != null) {
              setState(() {
                _segmentValue = value;
              });
            }
          },
        ),
      ],
    );
  }
} 