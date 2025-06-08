import 'package:flutter/material.dart';
import 'typography_tokens.dart';

/// Test page to validate the HIVE 2025-ready typography system
/// This page displays all typography styles for testing and validation
class TypographyTestPage extends StatefulWidget {
  const TypographyTestPage({Key? key}) : super(key: key);

  @override
  State<TypographyTestPage> createState() => _TypographyTestPageState();
}

class _TypographyTestPageState extends State<TypographyTestPage>
    with TickerProviderStateMixin {
  bool _isSurging = false;
  late AnimationController _surgingController;

  @override
  void initState() {
    super.initState();
    _surgingController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    // Auto-toggle surging effect every 2 seconds for demo
    _startSurgingDemo();
  }

  void _startSurgingDemo() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isSurging = !_isSurging;
        });
        if (_isSurging) {
          _surgingController.forward();
        } else {
          _surgingController.reverse();
        }
        _startSurgingDemo();
      }
    });
  }

  @override
  void dispose() {
    _surgingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D), // HIVE background
      appBar: AppBar(
        title: Text(
          'HIVE Typography System',
          style: TypographyTokens.h2,
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Display Fonts (Inter Tight)', [
              _buildTypeSample('H1 Display', TypographyTokens.h1, 'Building the future of campus life'),
              _buildTypeSample('H2 Display', TypographyTokens.h2, 'Major section headers'),
              _buildTypeSample('H3 Display', TypographyTokens.h3, 'Subsection headers'),
            ]),
            
            const SizedBox(height: 32),
            
            _buildSection('Body Text (Inter)', [
              _buildTypeSample('Body Large', TypographyTokens.body, 
                'This is the primary body text used for comfortable reading. It includes proper tracking for dark mode readability.'),
              _buildTypeSample('Body Secondary', TypographyTokens.bodySecondary,
                'Secondary text for descriptions and metadata. Uses subtle color differentiation.'),
              _buildTypeSample('Caption', TypographyTokens.caption,
                'Small utility text, timestamps, and labels with enhanced tracking.'),
            ]),
            
            const SizedBox(height: 32),
            
            _buildSection('Interactive Elements', [
              _buildTypeSample('Button Primary', TypographyTokens.buttonPrimary, 'Join Space'),
              _buildTypeSample('Button Secondary', TypographyTokens.buttonSecondary, 'Learn More'),
              _buildTypeSample('Link', TypographyTokens.link, 'Interactive Link Text'),
              _buildTypeSample('Interactive Gold', 
                TypographyTokens.makeInteractive(TypographyTokens.body), 
                'This text uses the gold accent color'),
            ]),
            
            const SizedBox(height: 32),
            
            _buildSection('Code & Metrics (JetBrains Mono)', [
              _buildTypeSample('Mono Regular', TypographyTokens.mono, 'user.id: 12345'),
              _buildTypeSample('Mono Bold', TypographyTokens.monoBold, 'const API_KEY = "abc123"'),
              _buildCodeSample(),
            ]),
            
            const SizedBox(height: 32),
            
            _buildSection('Editorial Accent (Space Grotesk)', [
              _buildTypeSample('Ritual Countdown', TypographyTokens.ritualCountdown, '● LIVE NOW'),
              _buildTypeSample('Editorial Emphasis', TypographyTokens.editorialEmphasis, 'Featured Content'),
            ]),
            
            const SizedBox(height: 32),
            
            _buildSection('Animation Features', [
              _buildSurgingDemo(),
              _buildFontWeightDemo(),
            ]),
            
            const SizedBox(height: 32),
            
            _buildSection('Dark Mode Optimization', [
              _buildDarkModeDemo(),
            ]),
            
            const SizedBox(height: 32),
            
            _buildSection('State Variants', [
              _buildTypeSample('Success', TypographyTokens.makeSuccess(TypographyTokens.body), 'Success message'),
              _buildTypeSample('Error', TypographyTokens.makeError(TypographyTokens.body), 'Error message'),
              _buildTypeSample('Disabled', TypographyTokens.makeDisabled(TypographyTokens.body), 'Disabled text'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TypographyTokens.h3.copyWith(
                  color: const Color(0xFFFFD700), // Gold accent for section headers
                ),
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSample(String label, TextStyle style, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label (${style.fontSize?.toInt()}pt, ${_getFontWeightName(style.fontWeight)})',
            style: TypographyTokens.caption.copyWith(
              color: const Color(0xFF999999),
            ),
          ),
          const SizedBox(height: 4),
          Text(text, style: style),
        ],
      ),
    );
  }

  Widget _buildCodeSample() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'function createSpace(name: string) {',
            style: TypographyTokens.mono,
          ),
          Text(
            '  const id = generateId();',
            style: TypographyTokens.mono,
          ),
          Text(
            '  return { id, name, type: "Space" };',
            style: TypographyTokens.mono,
          ),
          Text(
            '}',
            style: TypographyTokens.mono,
          ),
        ],
      ),
    );
  }

  Widget _buildSurgingDemo() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Surging Animation (Auto-Demo)',
            style: TypographyTokens.caption.copyWith(
              color: const Color(0xFF999999),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 400),
            style: _isSurging 
              ? TypographyTokens.makeSurging(TypographyTokens.body)
              : TypographyTokens.body,
            child: const Text('This text surges between 400→600 weight'),
          ),
        ],
      ),
    );
  }

  Widget _buildFontWeightDemo() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Font Weight Animation',
            style: TypographyTokens.caption.copyWith(
              color: const Color(0xFF999999),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: _surgingController,
            builder: (context, child) {
              final fontWeight = FontWeightTween(
                begin: FontWeight.w400,
                end: FontWeight.w600,
              ).evaluate(_surgingController);
              
              return Text(
                'Smooth font weight transition',
                style: TypographyTokens.body.copyWith(fontWeight: fontWeight),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDarkModeDemo() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dark Mode Tuning (+2% tracking for OLED)',
            style: TypographyTokens.caption.copyWith(
              color: const Color(0xFF999999),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Standard', style: TypographyTokens.caption),
                    Text('Small text without tuning', style: TypographyTokens.caption),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tuned', style: TypographyTokens.caption),
                    Text(
                      'Small text with dark mode tuning',
                      style: TypographyTokens.applyDarkModetuning(TypographyTokens.caption),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getFontWeightName(FontWeight? weight) {
    switch (weight) {
      case FontWeight.w100: return 'Thin';
      case FontWeight.w200: return 'ExtraLight';
      case FontWeight.w300: return 'Light';
      case FontWeight.w400: return 'Regular';
      case FontWeight.w500: return 'Medium';
      case FontWeight.w600: return 'Semibold';
      case FontWeight.w700: return 'Bold';
      case FontWeight.w800: return 'ExtraBold';
      case FontWeight.w900: return 'Black';
      default: return 'Regular';
    }
  }
} 