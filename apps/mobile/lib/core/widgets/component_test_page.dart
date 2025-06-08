import 'package:flutter/material.dart'; // Use standard Material
import 'package:flutter/services.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_neumorphic/flutter_neumorphic.dart' as neumorphic; // Removed import

import '../design/design_tokens.dart';
import '../design/typography_test_page.dart';
import 'materials/micro_grain_texture.dart'; 
import 'materials/gold_grain_overlay.dart'; 

// Interactive Button using standard Widgets (Reverted)
class InteractiveNeumorphicButton extends StatefulWidget {
  const InteractiveNeumorphicButton({super.key});

  @override
  State<InteractiveNeumorphicButton> createState() => _InteractiveNeumorphicButtonState();
}

class _InteractiveNeumorphicButtonState extends State<InteractiveNeumorphicButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens();
    // Using standard shadows again
    final shadows = _isPressed ? tokens.shadows.neumorphicEmbossed : tokens.shadows.neumorphicDarkElevated;
    final scale = _isPressed ? 0.97 : 1.0;

    final double horizontalPadding = tokens.spacing.space6;
    final double verticalPadding = tokens.spacing.spaceButtonVertical;
    const double buttonHeight = 52.0; // Adjusted height

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      child: AnimatedContainer(
        duration: tokens.animation.durationPress,
        curve: Curves.easeInOut,
        transform: Matrix4.identity()..scale(scale),
        transformAlignment: Alignment.center,
        padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding, 
            vertical: verticalPadding
        ),
        height: buttonHeight, 
        decoration: BoxDecoration(
          color: tokens.colors.bgButtonDark, 
          borderRadius: BorderRadius.circular(tokens.radius.radiusButton),
          boxShadow: shadows, // Apply dynamic shadows
        ),
        child: Center(
          child: Text(
            'Primary Action (Simulated)', // Updated text 
            style: TextStyle(
                fontFamily: tokens.typography.labelLg.fontFamily,
                color: tokens.colors.brandGold100,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
            ), 
          ),
        ),
      ),
    );
  }
}

// START: Resting Embossed Interactive Button
class RestingEmbossedInteractiveButton extends StatefulWidget {
  const RestingEmbossedInteractiveButton({super.key});

  @override
  State<RestingEmbossedInteractiveButton> createState() =>
      _RestingEmbossedInteractiveButtonState();
}

class _RestingEmbossedInteractiveButtonState
    extends State<RestingEmbossedInteractiveButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens();
    // Button is always embossed, press effect is primarily scale
    final shadows = tokens.shadows.neumorphicEmbossed;
    final scale = _isPressed ? 0.97 : 1.0;

    final double horizontalPadding = tokens.spacing.space6;
    final double verticalPadding = tokens.spacing.spaceButtonVertical;
    const double buttonHeight = 52.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      child: AnimatedContainer(
        duration: tokens.animation.durationPress, // Matches other button
        curve: Curves.easeInOut,
        transform: Matrix4.identity()..scale(scale),
        transformAlignment: Alignment.center,
        padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding, vertical: verticalPadding),
        height: buttonHeight,
        decoration: BoxDecoration(
          color: tokens.colors.bgButtonDark, // Consistent background
          borderRadius: BorderRadius.circular(tokens.radius.radiusButton),
          boxShadow: shadows, // Always embossed
        ),
        child: Center(
          child: Text(
            'Embossed Action',
            style: TextStyle(
              fontFamily: tokens.typography.labelLg.fontFamily,
              color: tokens.colors.brandGold100,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
// END: Resting Embossed Interactive Button

// START: Peaking Card Example Widget
/// A widget demonstrating a "Peaking Card" according to HIVE design principles.
class PeakingCardExample extends StatefulWidget {
  const PeakingCardExample({super.key});

  @override
  State<PeakingCardExample> createState() => _PeakingCardExampleState();
}

class _PeakingCardExampleState extends State<PeakingCardExample> {
  bool _isHovering = false;
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens();
    final scale = _isTapped ? 0.98 : (_isHovering ? 1.02 : 1.0);
    final elevation = _isHovering || _isTapped ? tokens.shadows.elevation3 : tokens.shadows.elevation2;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isTapped = true);
          HapticFeedback.lightImpact();
        },
        onTapUp: (_) => setState(() => _isTapped = false),
        onTapCancel: () => setState(() => _isTapped = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200), // Use a concrete duration
          curve: Curves.easeInOut,
          transform: Matrix4.identity()..scale(scale),
          transformAlignment: Alignment.center,
          width: 250, // Example width
          height: 150, // Example height
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(tokens.radius.radiusCard), // 20pt
            gradient: LinearGradient(
              colors: [
                tokens.colors.bg800, // Use existing token, assumed darker for start
                tokens.colors.bg700,   // Use existing token, assumed lighter for end
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: elevation,
            border: _isTapped || _isHovering
                ? Border.all(color: tokens.colors.brandGold100.withOpacity(0.3), width: 1.5)
                : Border.all(color: Colors.white.withOpacity(0.06), width: 1),
          ),
          child: Stack(
            children: [
              // Subtle inner glow for elevated look
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(tokens.radius.radiusCard),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.03), // rgba(255,255,255,0.03)
                        blurRadius: 8,
                        spreadRadius: 0, // Inner glow
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(tokens.spacing.space4), // 16pt padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Peaking Card Title',
                      style: tokens.typography.headlineSm.copyWith(color: tokens.colors.textPrimary),
                    ),
                    SizedBox(height: tokens.spacing.space2),
                    Builder(builder: (context) { // Using Builder to get a local context if needed, though not strictly necessary here
                      final TextStyle cardTextStyle = tokens.typography.bodyMd.copyWith(color: tokens.colors.textSecondary);
                      return Text(
                        'This card demonstrates HIVE\'s peaking card aesthetic with subtle interactions and gradient.',
                        style: cardTextStyle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      );
                    }),
                    const Spacer(),
                    if (_isHovering || _isTapped)
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Icon(
                          Icons.arrow_forward_ios,
                          color: tokens.colors.brandGold100,
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ),
              // Gold accent for focus/active state (simulated)
              if (_isTapped)
                Positioned(
                  top: tokens.spacing.space2,
                  right: tokens.spacing.space2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: tokens.colors.brandGold100,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
// END: Peaking Card Example Widget

/// A test page showcasing the HIVE Design Token system (New Specification)
class DesignTokensTestPage extends ConsumerWidget {
  const DesignTokensTestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = DesignTokens();

    // Removed NeumorphicTheme wrapper
    return Scaffold(
      backgroundColor: tokens.colors.bg900, // Reverted to standard background
      // Reverted to standard AppBar
      appBar: AppBar(
        title: Text('HIVE Design Tokens', style: tokens.typography.labelLg.copyWith(color: tokens.colors.textPrimary)),
        backgroundColor: tokens.colors.bg800,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(tokens.spacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSection(context, 'Colors', tokens,
              children: [
                _buildColorCard('BG 900 (Root)', tokens.colors.bg900, tokens: tokens),
                _buildColorCard('BG 800 (Primary Surface)', tokens.colors.bg800, tokens: tokens),
                _buildColorCard('BG 700 (Secondary Surface)', tokens.colors.bg700, tokens: tokens),
                _buildColorCard('Line 500 (Dividers/Strokes)', tokens.colors.line500, tokens: tokens),
                _buildColorCard('Text Primary', tokens.colors.textPrimary, tokens: tokens),
                _buildColorCard('Text Secondary', tokens.colors.textSecondary, tokens: tokens),
                _buildColorCard('Text On Accent (Gold)', tokens.colors.textOnAccent, tokens: tokens, showContrastWith: tokens.colors.brandGold100),
                _buildColorCard('Brand Gold 100', tokens.colors.brandGold100, tokens: tokens),
                _buildColorCard('Brand Gold 40 (Overlay)', tokens.colors.brandGold40, tokens: tokens, isOverlay: true),
                _buildColorCard('State Success', tokens.colors.stateSuccess, tokens: tokens),
                _buildColorCard('State Info', tokens.colors.stateInfo, tokens: tokens),
                _buildColorCard('State Error', tokens.colors.stateError, tokens: tokens),
                _buildColorCard('State Warning', tokens.colors.stateWarning, tokens: tokens),
              ]
            ),
            const SizedBox(height: 32),
            _buildSection(context, 'Typography', tokens,
              children: [
                Text('Headline Large', style: tokens.typography.headlineLg),
                Text('Headline Medium', style: tokens.typography.headlineMd),
                Text('Headline Small', style: tokens.typography.headlineSm),
                SizedBox(height: tokens.spacing.space2),
                Text('Body Large (Primary)', style: tokens.typography.bodyLg),
                Text('Body Medium (Secondary)', style: tokens.typography.bodyMd),
                Text('Body Small (Secondary)', style: tokens.typography.bodySm),
                SizedBox(height: tokens.spacing.space2),
                Text('Label Large (Button)', style: tokens.typography.labelLg),
                Text('Label Medium', style: tokens.typography.labelMd),
                Text('Label Small', style: tokens.typography.labelSm),
                SizedBox(height: tokens.spacing.space3),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const TypographyTestPage(),
                        ),
                      );
                    },
                    icon: Icon(Icons.font_download, color: tokens.colors.textOnAccent),
                    label: Text(
                      'View 2025 Typography System',
                      style: tokens.typography.labelMd.copyWith(color: tokens.colors.textOnAccent),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tokens.colors.brandGold100,
                      padding: EdgeInsets.symmetric(
                        horizontal: tokens.spacing.space4,
                        vertical: tokens.spacing.space2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(tokens.radius.radiusButton),
                      ),
                    ),
                  ),
                ),
              ]
            ),
            const SizedBox(height: 32),
            _buildSection(context, 'Spacing', tokens,
              children: [
                _buildSpacingExample('Space 1 (4pt)', tokens.spacing.space1, tokens),
                _buildSpacingExample('Space 2 (8pt)', tokens.spacing.space2, tokens),
                _buildSpacingExample('Space 3 (12pt)', tokens.spacing.space3, tokens),
                _buildSpacingExample('Space 4 (16pt)', tokens.spacing.space4, tokens),
                _buildSpacingExample('Space 6 (24pt)', tokens.spacing.space6, tokens),
                _buildSpacingExample('Space 8 (48pt)', tokens.spacing.space8, tokens),
              ]
            ),
            const SizedBox(height: 32),
            _buildSection(context, 'Radius', tokens,
              children: [
                _buildRadiusExample('Small (4pt)', tokens.radius.radiusSm, tokens),
                _buildRadiusExample('Medium (8pt)', tokens.radius.radiusMd, tokens),
                _buildRadiusExample('Large (16pt)', tokens.radius.radiusLg, tokens),
                _buildRadiusExample('Input (12pt)', tokens.radius.radiusInput, tokens),
                _buildRadiusExample('Card (20pt)', tokens.radius.radiusCard, tokens),
                _buildRadiusExample('Button/XL (24pt)', tokens.radius.radiusXl, tokens),
                _buildRadiusExample('Circular', tokens.radius.radiusCircular, tokens),
              ]
            ),
            const SizedBox(height: 32),
            _buildSection(context, 'Shadows', tokens,
              children: [
                _buildShadowExample('Elevation 1', tokens.shadows.elevation1, tokens),
                _buildShadowExample('Elevation 2', tokens.shadows.elevation2, tokens),
                _buildShadowExample('Elevation 3', tokens.shadows.elevation3, tokens),
                _buildShadowExample('Elevation 4', tokens.shadows.elevation4, tokens),
                SizedBox(height: tokens.spacing.space3),
                _buildShadowExample(
                  'Neumorphic Dark Elevated (Raised)',
                  tokens.shadows.neumorphicDarkElevated,
                  tokens,
                  containerColor: tokens.colors.bgButtonDark, 
                  width: 150, 
                  height: 60,
                  borderRadius: tokens.radius.radiusButton,
                ),
                SizedBox(height: tokens.spacing.space3),
                _buildShadowExample(
                  'Neumorphic Embossed (Simulated Inset)',
                  tokens.shadows.neumorphicEmbossed,
                  tokens,
                  containerColor: tokens.colors.bgButtonDark, 
                  width: 150,
                  height: 60,
                  borderRadius: tokens.radius.radiusButton,
                ),
              ]
            ),
            const SizedBox(height: 32),
            _buildSection(context, 'Opacity', tokens,
              children: [
                _buildOpacityExample('Low (8%)', tokens.opacity.low, tokens),
                _buildOpacityExample('Medium Low (12%)', tokens.opacity.mediumLow, tokens),
                _buildOpacityExample('Medium (50%)', tokens.opacity.medium, tokens),
                _buildOpacityExample('High (80%)', tokens.opacity.high, tokens),
                _buildOpacityExample('Brand Gold Overlay (40%)', tokens.opacity.brandGoldOverlay, tokens),
                _buildOpacityExample('Disabled Content (50% on line500)', tokens.opacity.disabledContent, tokens, baseColor: tokens.colors.line500),
              ]
            ),
            const SizedBox(height: 32),
             _buildSection(context, 'Textures & Materials', tokens,
              children: [
                _buildTextureExample('Micro Grain Texture (Default 3%)', tokens, tokens.colors.bg700),
                _buildTextureExample('Micro Grain Texture (10% Opacity)', tokens, tokens.colors.stateInfo, opacity: 0.10),
                SizedBox(height: tokens.spacing.space3),
                _buildTextureExample(
                  'Gold Grain Overlay (Canvas: bg900 + 3% Gold Grain)',
                  tokens,
                  tokens.colors.bg900,
                  isGoldOverlay: true,
                ),
              ]
            ),
            const SizedBox(height: 32),

            // START: New Section for Peaking Card
            _buildSection(context, 'Peaking Cards (Interactive)', tokens,
              children: [
                const Center(child: PeakingCardExample()),
                SizedBox(height: tokens.spacing.space2),
                Center(
                  child: Text(
                    'Hover and tap the card to see interactions.',
                    style: tokens.typography.bodySm.copyWith(color: tokens.colors.textSecondary),
                  ),
                ),
              ],
            ),
            // END: New Section for Peaking Card
            const SizedBox(height: 32),

            // Reverted Buttons Section
            _buildSection(context, 'Buttons', tokens,
              children: [
                const InteractiveNeumorphicButton(), 
                const SizedBox(height: 16),
                const RestingEmbossedInteractiveButton(), // Added new button
                const SizedBox(height: 24),

                // Static Neumorphic Examples (Using standard shadows)
                const Text("Static Neumorphic Button Examples (Simulated):"),
                const SizedBox(height: 12),
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: tokens.colors.bgButtonDark, 
                    borderRadius: BorderRadius.circular(tokens.radius.radiusButton),
                    boxShadow: tokens.shadows.neumorphicDarkElevated, 
                  ),
                  child: Center(
                    child: Text(
                      'Raised (Simulated)', // Text updated
                      style: tokens.typography.labelLg.copyWith(color: tokens.colors.brandGold100),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: tokens.colors.bgButtonDark, 
                    borderRadius: BorderRadius.circular(tokens.radius.radiusButton),
                    boxShadow: tokens.shadows.neumorphicEmbossed, 
                  ),
                  child: Center(
                    child: Text(
                      'Embossed (Simulated)',
                      style: tokens.typography.labelLg.copyWith(color: tokens.colors.brandGold100),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 4.0),
                  child: Text(
                    'Note: True inset shadows require a compatible package.',
                    style: tokens.typography.bodySm.copyWith(color: tokens.colors.textSecondary.withOpacity(0.7)),
                  ),
                ),
                const SizedBox(height: 24),

                // Standard Buttons remain for comparison
                const Text("Standard Themed Buttons (For Comparison):"),
                const SizedBox(height: 12),
                const ElevatedButton(onPressed: null, child: Text('Primary Disabled (Themed)')),
                const SizedBox(height: 16),
                OutlinedButton(onPressed: () {}, child: const Text('Secondary Outlined')),
                const SizedBox(height: 8),
                const OutlinedButton(onPressed: null, child: Text('Secondary Disabled')),
                const SizedBox(height: 16),
                TextButton(onPressed: () {}, child: const Text('Text Button (Themed Gold)')),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.colors.bg800,
                    foregroundColor: tokens.colors.textPrimary,
                    minimumSize: const Size(64, 36),
                    padding: EdgeInsets.symmetric(horizontal: tokens.spacing.space6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(tokens.radius.radiusXl), 
                    ),
                    textStyle: tokens.typography.labelLg,
                  ).copyWith(
                    overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
                      if (states.contains(MaterialState.pressed)) { return tokens.colors.textPrimary.withOpacity(0.08); }
                      if (states.contains(MaterialState.hovered)) { return tokens.colors.textPrimary.withOpacity(0.04); }
                      return null;
                    }),
                  ),
                  onPressed: () {},
                  child: const Text('Dark Filled Button (bg800)'),
                ),
                const SizedBox(height: 8),
                FilledButton(
                   style: FilledButton.styleFrom(
                    backgroundColor: tokens.colors.bg800,
                    foregroundColor: tokens.colors.textSecondary,
                    minimumSize: const Size(64, 36),
                    padding: EdgeInsets.symmetric(horizontal: tokens.spacing.space6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(tokens.radius.radiusXl), 
                    ),
                    textStyle: tokens.typography.labelLg,
                  ).copyWith(
                     backgroundColor: MaterialStateProperty.all(tokens.colors.line500),
                  ),
                  onPressed: null,
                  child: const Text('Dark Filled Disabled'),
                ),
              ]
            ),
          ],
        ),
      ),
    );
  }

  // Reverted helper methods: removed context parameter and NeumorphicTheme dependency
  Widget _buildSection(BuildContext context, String title, DesignTokens tokens, {required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: tokens.typography.headlineSm.copyWith(color: tokens.colors.textPrimary)), // Reverted text color
        SizedBox(height: tokens.spacing.space4),
        ...children,
      ],
    );
  }

  Widget _buildColorCard(String name, Color color, {DesignTokens? tokens, Color? showContrastWith, bool isOverlay = false}) {
    tokens ??= DesignTokens();
    final textColor = tokens.colors.textPrimary; // Reverted text color
    String hexValue = '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
    if (isOverlay) { hexValue += ' (${(color.opacity * 100).toInt()}%)'; }
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spacing.space1),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: isOverlay ? tokens.colors.bg700 : color,
              borderRadius: BorderRadius.circular(tokens.radius.radiusMd),
              border: Border.all(color: tokens.colors.line500, width: 1),
            ),
            foregroundDecoration: showContrastWith != null ? BoxDecoration(color: showContrastWith, borderRadius: BorderRadius.circular(tokens.radius.radiusMd), border: Border.all(color: tokens.colors.line500, width: 1)) : null,
            child: isOverlay ? Container(color: color) : (showContrastWith != null ? Center(child: Text('Aa', style: tokens.typography.labelLg.copyWith(color: color), textAlign: TextAlign.center)) : null),
          ),
          SizedBox(width: tokens.spacing.space4),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(name, style: tokens.typography.bodyLg.copyWith(color: textColor)), Text(hexValue, style: tokens.typography.bodySm.copyWith(color: tokens.colors.textSecondary)) ]),
        ],
      ),
    );
  }

  Widget _buildSpacingExample(String name, double size, DesignTokens tokens) {
    final textColor = tokens.colors.textPrimary; // Reverted text color
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spacing.space2),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(name, style: tokens.typography.bodyLg.copyWith(color: textColor)), SizedBox(height: tokens.spacing.space1), Row(children: [ Container(width: size, height: 48, color: tokens.colors.brandGold40), SizedBox(width: tokens.spacing.space4), Text('${size.toInt()} pt', style: tokens.typography.bodySm.copyWith(color: textColor)) ]) ]),
    );
  }

  Widget _buildRadiusExample(String name, double radius, DesignTokens tokens) {
    final textColor = tokens.colors.textPrimary; // Reverted text color
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spacing.space2),
      child: Row(children: [ Container(width: 48, height: 48, decoration: BoxDecoration(color: tokens.colors.brandGold40, borderRadius: BorderRadius.circular(radius), border: Border.all(color: tokens.colors.line500))), SizedBox(width: tokens.spacing.space4), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(name, style: tokens.typography.bodyLg.copyWith(color: textColor)), Text('${radius.toInt()} pt', style: tokens.typography.bodySm.copyWith(color: textColor)) ]) ]),
    );
  }

  Widget _buildShadowExample(String name, List<BoxShadow> boxShadow, DesignTokens tokens, {Color? containerColor, double width = 100, double height = 50, double? borderRadius}) {
     final textColor = tokens.colors.textPrimary; // Reverted text color
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: tokens.typography.bodyMd.copyWith(color: textColor)),
        SizedBox(height: tokens.spacing.space2),
        Container(width: width, height: height, decoration: BoxDecoration(color: containerColor ?? tokens.colors.bg700, borderRadius: BorderRadius.circular(borderRadius ?? tokens.radius.radiusMd), boxShadow: boxShadow)),
        SizedBox(height: tokens.spacing.space4),
      ],
    );
  }

  Widget _buildOpacityExample(String name, double opacityValue, DesignTokens tokens, {Color? baseColor}) {
    final textColor = tokens.colors.textPrimary; // Reverted text color
    baseColor ??= tokens.colors.brandGold100;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spacing.space2),
      child: Row(children: [ Container(width: 48, height: 48, decoration: BoxDecoration(color: baseColor.withOpacity(opacityValue), borderRadius: BorderRadius.circular(tokens.radius.radiusMd), border: Border.all(color: tokens.colors.line500)), child: Opacity(opacity: 0.1, child: Image.asset('assets/images/checkerboard.png', fit: BoxFit.cover))), SizedBox(width: tokens.spacing.space4), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(name, style: tokens.typography.bodyLg.copyWith(color: textColor)), Text('${(opacityValue * 100).toStringAsFixed(0)}%', style: tokens.typography.bodySm.copyWith(color: textColor)) ]) ]),
    );
  }

  Widget _buildTextureExample(String name, DesignTokens tokens, Color baseColor, {double? opacity, bool isGoldOverlay = false}) {
    final textColor = tokens.colors.textPrimary; // Reverted text color
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spacing.space2),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(name, style: tokens.typography.bodyLg.copyWith(color: textColor)), SizedBox(height: tokens.spacing.space2), isGoldOverlay ? GoldGrainOverlay(child: _buildBaseContainer(tokens, baseColor)) : MicroGrainTexture(opacity: opacity ?? -1, child: _buildBaseContainer(tokens, baseColor)) ]),
    );
  }

  Widget _buildBaseContainer(DesignTokens tokens, Color baseColor) {
    final textColor = tokens.colors.textPrimary; // Reverted text color
    return Container(width: double.infinity, height: 80, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(tokens.radius.radiusMd), border: Border.all(color: tokens.colors.line500)), alignment: Alignment.center, child: Text('Base Color', style: tokens.typography.labelMd.copyWith(color: textColor)));
  }
}