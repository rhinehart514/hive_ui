// HIVE Button System Implementation & Testing
// Component Library Priority 1 - HiveButton System Development
// Part of the design system implementation phase

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ================================
// HIVE BUTTON SYSTEM - COMPONENT LIBRARY PRIORITY 1
// ================================

/// Primary Button Surface Exploration
/// Testing multiple surface treatments grounded in established design foundations
class HiveButtonVariants {
  
  // VARIATION 1: Gradient Surface with Micro-Grain
  static Widget buildGradientButton({
    required String text,
    required VoidCallback? onPressed,
    bool isPressed = false,
    bool isHovered = false,
    bool isDisabled = false,
  }) {
    return Container(
      height: 36, // Per component spec
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24), // Chip-sized per spec
        gradient: isDisabled 
          ? null
          : const LinearGradient(
              colors: [
                Color(0xFF1E1E1E),
                Color(0xFF2A2A2A),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
        color: isDisabled ? const Color(0xFF1E1E1E).withOpacity(0.5) : null,
        boxShadow: isPressed ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: isHovered ? 8 : 4,
            offset: Offset(0, isHovered ? 4 : 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(24),
          splashColor: const Color(0xFFFFD700).withOpacity(0.2),
          highlightColor: const Color(0xFFFFD700).withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDisabled 
                    ? Colors.white.withOpacity(0.5) 
                    : Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // VARIATION 2: Gold Primary with Glass Overlay
  static Widget buildGoldPrimaryButton({
    required String text,
    required VoidCallback? onPressed,
    bool isPressed = false,
    bool isHovered = false,
    bool isDisabled = false,
  }) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isDisabled 
          ? const Color(0xFFFFD700).withOpacity(0.5)
          : const Color(0xFFFFD700),
        boxShadow: isPressed ? [] : [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(isHovered ? 0.4 : 0.2),
            blurRadius: isHovered ? 12 : 6,
            offset: Offset(0, isHovered ? 3 : 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(24),
          splashColor: Colors.black.withOpacity(0.1),
          highlightColor: Colors.black.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDisabled 
                    ? const Color(0xFF0D0D0D).withOpacity(0.6) 
                    : const Color(0xFF0D0D0D),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // VARIATION 3: Glass Surface with Backdrop Blur
  static Widget buildGlassButton({
    required String text,
    required VoidCallback? onPressed,
    bool isPressed = false,
    bool isHovered = false,
    bool isDisabled = false,
  }) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isDisabled
          ? Colors.white.withOpacity(0.05)
          : Colors.white.withOpacity(isHovered ? 0.12 : 0.08),
        border: Border.all(
          color: isDisabled
            ? Colors.white.withOpacity(0.1)
            : Colors.white.withOpacity(isHovered ? 0.3 : 0.2),
          width: 1,
        ),
        boxShadow: isPressed ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: isHovered ? 8 : 4,
            offset: Offset(0, isHovered ? 2 : 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(24),
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.white.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDisabled 
                    ? Colors.white.withOpacity(0.4) 
                    : Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // VARIATION 4: Minimal Text Button with Gold Accent
  static Widget buildTextButton({
    required String text,
    required VoidCallback? onPressed,
    bool isPressed = false,
    bool isHovered = false,
    bool isDisabled = false,
  }) {
    return SizedBox(
      height: 36,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(18),
          splashColor: const Color(0xFFFFD700).withOpacity(0.15),
          highlightColor: const Color(0xFFFFD700).withOpacity(0.08),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDisabled 
                    ? Colors.white.withOpacity(0.4)
                    : isHovered
                      ? const Color(0xFFFFD700)
                      : Colors.white,
                  decoration: isHovered && !isDisabled 
                    ? TextDecoration.underline 
                    : null,
                  decorationColor: const Color(0xFFFFD700),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // VARIATION 5: Icon Button with Touch Target Optimization
  static Widget buildIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
    bool isPressed = false,
    bool isHovered = false,
    bool isDisabled = false,
    double size = 20,
  }) {
    return Container(
      width: 44, // Touch target optimization
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: isHovered && !isDisabled
          ? Colors.white.withOpacity(0.1)
          : Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(22),
          splashColor: const Color(0xFFFFD700).withOpacity(0.2),
          highlightColor: const Color(0xFFFFD700).withOpacity(0.1),
          child: Container(
            child: Center(
              child: Icon(
                icon,
                size: size,
                color: isDisabled 
                  ? Colors.white.withOpacity(0.4)
                  : isHovered
                    ? const Color(0xFFFFD700)
                    : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Focus Ring Strategy Testing
/// Testing different focus ring approaches for accessibility and effectiveness
class HiveFocusRings {
  
  // STRATEGY 1: Classic Gold Ring with Offset
  static Widget buildClassicFocusRing({
    required Widget child,
    required bool hasFocus,
    double ringWidth = 2.0,
    double ringOffset = 4.0,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28), // Button radius + offset
        border: hasFocus 
          ? Border.all(
              color: const Color(0xFFFFD700),
              width: ringWidth,
            )
          : null,
      ),
      margin: EdgeInsets.all(hasFocus ? ringOffset : 0),
      child: child,
    );
  }

  // STRATEGY 2: Glow Ring with Blur Effect
  static Widget buildGlowFocusRing({
    required Widget child,
    required bool hasFocus,
    double glowRadius = 8.0,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: hasFocus ? [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.6),
            blurRadius: glowRadius,
            spreadRadius: 2,
          ),
        ] : [],
      ),
      child: child,
    );
  }

  // STRATEGY 3: Inner Ring with Surface Highlight
  static Widget buildInnerFocusRing({
    required Widget child,
    required bool hasFocus,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: hasFocus 
          ? Border.all(
              color: const Color(0xFFFFD700),
              width: 2,
            )
          : null,
      ),
      child: child,
    );
  }
}

/// Press Animation Physics Comparison
/// Testing different animation approaches to compare feel and performance
class HivePressAnimations {
  
  // PHYSICS 1: Scale with Spring Bounce
  static Widget buildSpringPressAnimation({
    required Widget child,
    required bool isPressed,
  }) {
    return AnimatedScale(
      scale: isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.elasticOut,
      child: child,
    );
  }

  // PHYSICS 2: Scale with Ease Out (iOS-style)
  static Widget buildEaseOutPressAnimation({
    required Widget child,
    required bool isPressed,
  }) {
    return AnimatedScale(
      scale: isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: child,
    );
  }

  // PHYSICS 3: Transform with Depth Shift
  static Widget buildDepthPressAnimation({
    required Widget child,
    required bool isPressed,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      transform: Matrix4.identity()
        ..scale(isPressed ? 0.98 : 1.0)
        ..translate(0.0, isPressed ? 2.0 : 0.0, isPressed ? -2.0 : 0.0),
      child: child,
    );
  }

  // PHYSICS 4: Opacity + Scale Combination
  static Widget buildOpacityPressAnimation({
    required Widget child,
    required bool isPressed,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      transform: Matrix4.identity()..scale(isPressed ? 0.98 : 1.0),
      child: AnimatedOpacity(
        opacity: isPressed ? 0.8 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: child,
      ),
    );
  }
}

/// HiveButton Testing Page
/// Interactive testing environment for all button variations
class HiveButtonTestPage extends StatefulWidget {
  const HiveButtonTestPage({super.key});

  @override
  _HiveButtonTestPageState createState() => _HiveButtonTestPageState();
}

class _HiveButtonTestPageState extends State<HiveButtonTestPage> 
    with TickerProviderStateMixin {
  
  bool _isPressed1 = false;
  bool _isPressed2 = false;
  bool _isPressed3 = false;
  bool _isPressed4 = false;
  bool _hasFocus1 = false;
  bool _hasFocus2 = false;
  bool _hasFocus3 = false;
  bool _isAnimating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text(
          'HIVE Button System Testing',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF8CE563).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF8CE563).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✅ HiveButton System Implementation Started',
                    style: TextStyle(
                      color: Color(0xFF8CE563),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Component Library Priority 1 - Testing 5 button variations with 3 focus strategies and 4 animation approaches',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Button Variations Section
            _buildSectionTitle('Primary Button Surface Exploration'),
            _buildButtonVariations(),
            
            const SizedBox(height: 32),
            
            // Focus Ring Testing Section  
            _buildSectionTitle('Focus Ring Strategy Testing'),
            _buildFocusRingTesting(),
            
            const SizedBox(height: 32),
            
            // Press Animation Testing Section
            _buildSectionTitle('Press Animation Physics Comparison'),
            _buildPressAnimationTesting(),
            
            const SizedBox(height: 32),
            
            // Implementation Status
            _buildImplementationStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildButtonVariations() {
    return Column(
      children: [
        // Variation 1: Gradient Surface
        _buildButtonDemo(
          'Gradient Surface with Micro-Grain',
          HiveButtonVariants.buildGradientButton(
            text: 'Join Space',
            onPressed: () => _triggerHaptic(),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Variation 2: Gold Primary
        _buildButtonDemo(
          'Gold Primary with Glass Overlay',
          HiveButtonVariants.buildGoldPrimaryButton(
            text: 'Create Tool',
            onPressed: () => _triggerHaptic(),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Variation 3: Glass Surface
        _buildButtonDemo(
          'Glass Surface with Backdrop Blur',
          HiveButtonVariants.buildGlassButton(
            text: 'View Events',
            onPressed: () => _triggerHaptic(),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Variation 4: Text Button
        _buildButtonDemo(
          'Minimal Text Button with Gold Accent',
          HiveButtonVariants.buildTextButton(
            text: 'Learn More',
            onPressed: () => _triggerHaptic(),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Variation 5: Icon Button
        _buildButtonDemo(
          'Icon Button with Touch Target Optimization',
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              HiveButtonVariants.buildIconButton(
                icon: Icons.favorite,
                onPressed: () => _triggerHaptic(),
              ),
              HiveButtonVariants.buildIconButton(
                icon: Icons.share,
                onPressed: () => _triggerHaptic(),
              ),
              HiveButtonVariants.buildIconButton(
                icon: Icons.bookmark,
                onPressed: () => _triggerHaptic(),
              ),
              HiveButtonVariants.buildIconButton(
                icon: Icons.settings,
                onPressed: () => _triggerHaptic(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFocusRingTesting() {
    return Column(
      children: [
        // Strategy 1: Classic Ring
        _buildButtonDemo(
          'Classic Gold Ring with Offset',
          GestureDetector(
            onTap: () => setState(() => _hasFocus1 = !_hasFocus1),
            child: HiveFocusRings.buildClassicFocusRing(
              hasFocus: _hasFocus1,
              child: HiveButtonVariants.buildGradientButton(
                text: 'Tap to Toggle Focus',
                onPressed: () => _triggerHaptic(),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Strategy 2: Glow Ring
        _buildButtonDemo(
          'Glow Ring with Blur Effect',
          GestureDetector(
            onTap: () => setState(() => _hasFocus2 = !_hasFocus2),
            child: HiveFocusRings.buildGlowFocusRing(
              hasFocus: _hasFocus2,
              child: HiveButtonVariants.buildGlassButton(
                text: 'Tap to Toggle Focus',
                onPressed: () => _triggerHaptic(),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Strategy 3: Inner Ring
        _buildButtonDemo(
          'Inner Ring with Surface Highlight',
          GestureDetector(
            onTap: () => setState(() => _hasFocus3 = !_hasFocus3),
            child: HiveFocusRings.buildInnerFocusRing(
              hasFocus: _hasFocus3,
              child: HiveButtonVariants.buildGoldPrimaryButton(
                text: 'Tap to Toggle Focus',
                onPressed: () => _triggerHaptic(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPressAnimationTesting() {
    return Column(
      children: [
        // Physics 1: Spring Bounce
        _buildButtonDemo(
          'Scale with Spring Bounce',
          GestureDetector(
            onTapDown: (_) => setState(() => _isPressed1 = true),
            onTapUp: (_) => setState(() => _isPressed1 = false),
            onTapCancel: () => setState(() => _isPressed1 = false),
            child: HivePressAnimations.buildSpringPressAnimation(
              isPressed: _isPressed1,
              child: HiveButtonVariants.buildGradientButton(
                text: 'Hold to Test Spring',
                onPressed: () => _triggerHaptic(),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Physics 2: Ease Out
        _buildButtonDemo(
          'Scale with Ease Out (iOS-style)',
          GestureDetector(
            onTapDown: (_) => setState(() => _isPressed2 = true),
            onTapUp: (_) => setState(() => _isPressed2 = false),
            onTapCancel: () => setState(() => _isPressed2 = false),
            child: HivePressAnimations.buildEaseOutPressAnimation(
              isPressed: _isPressed2,
              child: HiveButtonVariants.buildGoldPrimaryButton(
                text: 'Hold to Test Ease',
                onPressed: () => _triggerHaptic(),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Physics 3: Depth Shift
        _buildButtonDemo(
          'Transform with Depth Shift',
          GestureDetector(
            onTapDown: (_) => setState(() => _isPressed3 = true),
            onTapUp: (_) => setState(() => _isPressed3 = false),
            onTapCancel: () => setState(() => _isPressed3 = false),
            child: HivePressAnimations.buildDepthPressAnimation(
              isPressed: _isPressed3,
              child: HiveButtonVariants.buildGlassButton(
                text: 'Hold to Test Depth',
                onPressed: () => _triggerHaptic(),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Physics 4: Opacity + Scale
        _buildButtonDemo(
          'Opacity + Scale Combination',
          GestureDetector(
            onTapDown: (_) => setState(() => _isPressed4 = true),
            onTapUp: (_) => setState(() => _isPressed4 = false),
            onTapCancel: () => setState(() => _isPressed4 = false),
            child: HivePressAnimations.buildOpacityPressAnimation(
              isPressed: _isPressed4,
              child: HiveButtonVariants.buildTextButton(
                text: 'Hold to Test Combo',
                onPressed: () => _triggerHaptic(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButtonDemo(String title, Widget button) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Center(child: button),
        ],
      ),
    );
  }

  Widget _buildImplementationStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF56CCF2).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF56CCF2).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎯 HiveButton System Progress',
            style: TextStyle(
              color: Color(0xFF56CCF2),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildProgressItem('Primary Button Surface Exploration', true),
          _buildProgressItem('Focus Ring Strategy Testing', true),
          _buildProgressItem('Secondary Button Glass Variations', false),
          _buildProgressItem('Text Button Hover Behavior Design', false),
          _buildProgressItem('Icon Button Touch Target Optimization', true),
          _buildProgressItem('Press Animation Physics Comparison', true),
          _buildProgressItem('Hover Effect Surface Treatment', false),
          _buildProgressItem('Disabled State Visual Language', false),
          _buildProgressItem('Loading State Transition Design', false),
          _buildProgressItem('Haptic Feedback Pattern Integration', false),
          const SizedBox(height: 12),
          const Text(
            'Status: 4/10 HiveButton system tasks completed. Testing multiple variations to determine optimal approaches for HIVE platform.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String task, bool completed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: completed ? const Color(0xFF8CE563) : Colors.white38,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              task,
              style: TextStyle(
                color: completed ? Colors.white : Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
    // Simulate button action feedback
    setState(() {
      _isAnimating = !_isAnimating;
    });
  }
} 