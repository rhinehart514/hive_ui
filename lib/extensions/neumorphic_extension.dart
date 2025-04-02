// ignore_for_file: dead_code

import 'package:flutter/material.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Extension on [Widget] to add standardized neumorphic effects
extension NeumorphicExtension on Widget {
  /// Creates a standardized neumorphic effect container around the child widget
  ///
  /// Parameters:
  /// - [borderRadius]: The border radius of the container (default: 24)
  /// - [padding]: Padding inside the container (default: null)
  /// - [margin]: Margin around the container (default: null)
  /// - [backgroundColor]: Background color of the container (default: AppColors.cardBackground)
  /// - [lightSource]: The source of light for shadow direction (default: top left)
  /// - [depth]: The depth of the neumorphic effect (default: 5)
  /// - [intensity]: The intensity of the shadows (default: 0.15)
  /// - [isPressed]: Whether the widget is in pressed state (default: false)
  /// - [hasBorder]: Whether to add a subtle border (default: true)
  /// - [elevation]: Additional elevation factor to make the component pop more (default: 1.0)
  /// - [accentGlow]: Whether to add a gold accent glow (default: false)
  Widget addNeumorphism({
    double borderRadius = 24.0,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color backgroundColor = AppColors.cardBackground,
    Alignment lightSource = Alignment.topLeft,
    double depth = 5.0,
    double intensity = 0.15,
    bool isPressed = false,
    bool hasBorder = true,
    double elevation = 1.0,
    bool accentGlow = false,
  }) {
    // Determine shadow offsets based on light source
    final xOffset = lightSource.x * depth * elevation;
    final yOffset = lightSource.y * depth * elevation;
    
    // Pure black background requires a slightly visible surface
    const adjustedBackgroundColor = Color(0xFF0A0A0A);
    
    // Create lighter and darker colors for the shadow effect (more dramatic contrast)
    final lighterColor = Color.lerp(
      Colors.white, 
      Colors.white, 
      isPressed ? 0.25 : 0.3 * elevation
    )!.withOpacity(isPressed ? intensity * 0.2 : intensity * 0.7 * elevation);
    
    final darkerColor = Color.lerp(
      Colors.black, 
      Colors.black, 
      isPressed ? 0.95 : 0.7
    )!.withOpacity(isPressed ? 0.5 : 0.8);
    
    // Adjust depth for pressed state
    final pressedDepth = isPressed ? depth * 0.2 : depth * elevation;

    // Create shadows for neumorphic effect
    final List<BoxShadow> neumorphicShadows = [
      // Light shadow (more intense for better pop against black)
      BoxShadow(
        color: lighterColor,
        offset: Offset(-xOffset * 0.7, -yOffset * 0.7),
        blurRadius: pressedDepth * 3.0,
        spreadRadius: -1 + (elevation - 1) * 0.6,
      ),
      // Dark shadow (stronger for more contrast with the black background)
      BoxShadow(
        color: darkerColor,
        offset: Offset(xOffset, yOffset),
        blurRadius: pressedDepth * 2.5,
        spreadRadius: 1.8 * elevation,
      ),
    ];

    // Create a gold accent glow if enabled
    if (accentGlow && !isPressed) {
      neumorphicShadows.add(
        BoxShadow(
          color: AppColors.gold.withOpacity(0.09 * elevation),
          offset: const Offset(0, 0),
          blurRadius: 18 * elevation,
          spreadRadius: 1.5 * elevation,
        ),
      );
    } else if (!isPressed) {
      // Add subtle gold accent for standard elements
      neumorphicShadows.add(
        BoxShadow(
          color: AppColors.gold.withOpacity(0.035),
          offset: const Offset(0, 0),
          blurRadius: 12,
          spreadRadius: 0,
        ),
      );
    }

    // Create the wrapped widget with appropriate padding
    Widget wrappedWidget = this;
    if (padding != null) {
      wrappedWidget = Padding(
        padding: padding,
        child: wrappedWidget,
      );
    }

    // Create outer container with black edges
    Widget result = Container(
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(borderRadius + 2),
      ),
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: adjustedBackgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: neumorphicShadows,
          border: hasBorder
              ? Border.all(
                  color: isPressed
                      ? Colors.black.withOpacity(0.35)
                      : Colors.white.withOpacity(0.05 * elevation),
                  width: 0.5,
                )
              : null,
        ),
        child: wrappedWidget,
      ),
    );

    // Apply margin if provided
    if (margin != null) {
      result = Padding(
        padding: margin,
        child: result,
      );
    }

    return result;
  }

  /// Creates a highly elevated neumorphic effect that pops dramatically from the background
  ///
  /// Parameters:
  /// - [borderRadius]: The border radius of the container (default: 24)
  /// - [padding]: Padding inside the container (default: null)
  /// - [margin]: Margin around the container (default: null)
  /// - [lightSource]: The source of light for shadow direction (default: top left)
  /// - [accentGlow]: Whether to add a gold accent glow (default: true)
  Widget addElevatedNeumorphism({
    double borderRadius = 24.0,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Alignment lightSource = Alignment.topLeft,
    bool accentGlow = true,
  }) {
    return addNeumorphism(
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      lightSource: lightSource,
      depth: 8.0,
      intensity: 0.2,
      elevation: 2.5,
      accentGlow: accentGlow,
    );
  }

  /// Creates a neumorphic button effect that responds to press interactions
  ///
  /// Parameters:
  /// - [borderRadius]: The border radius of the container (default: 16)
  /// - [backgroundColor]: Background color of the container (default: AppColors.cardBackground)
  /// - [padding]: Padding inside the container (default: null)
  /// - [margin]: Margin around the container (default: null)
  /// - [depth]: The depth of the neumorphic effect (default: 4)
  /// - [intensity]: The intensity of the shadows (default: 0.2)
  /// - [elevation]: How much the button pops from the background (default: 1.2)
  Widget addNeumorphicButton({
    double borderRadius = 16.0,
    Color backgroundColor = AppColors.cardBackground,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double depth = 4.0,
    double intensity = 0.2,
    double elevation = 1.2,
  }) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        bool isPressed = false;

        return GestureDetector(
          onTapDown: (_) => setState(() => isPressed = true),
          onTapUp: (_) => setState(() => isPressed = false),
          onTapCancel: () => setState(() => isPressed = false),
          child: addNeumorphism(
            borderRadius: borderRadius,
            backgroundColor: backgroundColor,
            padding: padding,
            margin: margin,
            depth: depth,
            intensity: intensity,
            isPressed: isPressed,
            elevation: elevation,
          ),
        );
      },
    );
  }
  
  /// Creates a neumorphic primary button with gold accents
  ///
  /// Parameters:
  /// - [onPressed]: Callback when button is pressed
  /// - [borderRadius]: The border radius of the button (default: 8)
  /// - [padding]: Padding inside the button (default: standard button padding)
  /// - [margin]: Margin around the button (default: null)
  /// - [elevation]: How much the button pops from the background (default: 1.5)
  Widget addNeumorphicPrimaryButton({
    required VoidCallback onPressed,
    double borderRadius = 8.0,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    EdgeInsetsGeometry? margin,
    double elevation = 1.5,
  }) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        bool isPressed = false;
        
        return GestureDetector(
          onTapDown: (_) => setState(() => isPressed = true),
          onTapUp: (_) {
            setState(() => isPressed = false);
            onPressed();
          },
          onTapCancel: () => setState(() => isPressed = false),
          child: Container(
            padding: const EdgeInsets.all(0),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(borderRadius + 2),
              boxShadow: isPressed ? [] : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10 * elevation,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  if (!isPressed) BoxShadow(
                    color: AppColors.gold.withOpacity(0.45 * elevation),
                    blurRadius: 10 * elevation,
                    spreadRadius: -1,
                    offset: const Offset(0, 0),
                  ),
                ],
                border: Border.all(
                  color: isPressed 
                    ? AppColors.gold.withOpacity(0.35) 
                    : AppColors.gold.withOpacity(0.8),
                  width: 0.7,
                ),
              ),
              child: Padding(
                padding: padding,
                child: this,
              ),
            ),
          ),
        );
      },
    );
  }
  
  /// Creates a neumorphic secondary button (outline style)
  ///
  /// Parameters:
  /// - [onPressed]: Callback when button is pressed
  /// - [borderRadius]: The border radius of the button (default: 8)
  /// - [outlineColor]: Color of the button outline (default: Colors.white.withOpacity(0.3))
  /// - [padding]: Padding inside the button (default: standard button padding)
  /// - [margin]: Margin around the button (default: null)
  /// - [elevation]: How much the button pops from the background (default: 1.2)
  Widget addNeumorphicSecondaryButton({
    required VoidCallback onPressed,
    double borderRadius = 8.0,
    Color outlineColor = AppColors.textSecondary,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    EdgeInsetsGeometry? margin,
    double elevation = 1.2,
  }) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        bool isPressed = false;
        
        return GestureDetector(
          onTapDown: (_) => setState(() => isPressed = true),
          onTapUp: (_) {
            setState(() => isPressed = false);
            onPressed();
          },
          onTapCancel: () => setState(() => isPressed = false),
          child: Container(
            padding: const EdgeInsets.all(0),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(borderRadius + 2),
              boxShadow: isPressed ? [] : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 8 * elevation,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  if (!isPressed) BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 2,
                    spreadRadius: 0,
                    offset: const Offset(0, 1),
                  ),
                ],
                border: Border.all(
                  color: isPressed 
                    ? outlineColor.withOpacity(0.3) 
                    : outlineColor.withOpacity(0.6),
                  width: 0.7,
                ),
              ),
              child: Padding(
                padding: padding,
                child: this,
              ),
            ),
          ),
        );
      },
    );
  }
  
  /// Creates a neumorphic icon button
  ///
  /// Parameters:
  /// - [onPressed]: Callback when button is pressed
  /// - [borderRadius]: The border radius of the button (default: 12)
  /// - [backgroundColor]: Background color of the button (default: transparent)
  /// - [padding]: Padding inside the button (default: standard icon padding)
  /// - [margin]: Margin around the button (default: null)
  /// - [elevation]: How much the button pops from the background (default: 1.3)
  /// - [accentGlow]: Whether to add a subtle gold glow (default: false)
  Widget addNeumorphicIconButton({
    required VoidCallback onPressed,
    double borderRadius = 12.0,
    Color backgroundColor = Colors.transparent,
    EdgeInsetsGeometry padding = const EdgeInsets.all(12),
    EdgeInsetsGeometry? margin,
    double elevation = 1.3,
    bool accentGlow = false,
  }) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        bool isPressed = false;
        
        return GestureDetector(
          onTapDown: (_) => setState(() => isPressed = true),
          onTapUp: (_) {
            setState(() => isPressed = false);
            onPressed();
          },
          onTapCancel: () => setState(() => isPressed = false),
          child: Container(
            padding: const EdgeInsets.all(0),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(borderRadius + 2),
              boxShadow: isPressed ? [] : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 5 * elevation,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  if (!isPressed) BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 3 * elevation,
                    spreadRadius: 0,
                    offset: const Offset(1, 1),
                  ),
                  if (accentGlow && !isPressed) BoxShadow(
                    color: AppColors.gold.withOpacity(0.06 * elevation),
                    blurRadius: 7 * elevation,
                    spreadRadius: 0,
                    offset: const Offset(0, 0),
                  ),
                ],
                border: Border.all(
                  color: isPressed
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.14 * elevation),
                  width: 0.5,
                ),
              ),
              child: Padding(
                padding: padding,
                child: this,
              ),
            ),
          ),
        );
      },
    );
  }
  
  /// Creates a neumorphic QR code container with 3D pop-out effect
  ///
  /// Parameters:
  /// - [qrData]: The data to be encoded in the QR code
  /// - [size]: Size of the QR code container (default: 180)
  /// - [elevation]: How much the QR code pops from the background (default: 2.0)
  /// - [embeddedImage]: Optional image to embed in the center of the QR code
  /// - [embeddedImageSize]: Size of the embedded image (default: Size(40, 40))
  /// - [padding]: Padding inside the QR code container (default: 12)
  /// - [borderRadius]: Border radius of the container (default: 20)
  Widget addNeumorphicQrCode({
    required String qrData,
    double size = 180.0,
    double elevation = 2.0,
    ImageProvider? embeddedImage,
    Size embeddedImageSize = const Size(40, 40),
    double padding = 12.0,
    double borderRadius = 20.0,
  }) {
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // Add perspective
        ..translate(0.0, -8.0 * elevation, 0.0), // Floating effect proportional to elevation
      alignment: Alignment.center,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            // Outer shadow for depth
            BoxShadow(
              color: Colors.black.withOpacity(0.4 * elevation),
              blurRadius: 16.0 * elevation,
              spreadRadius: 1.0 * elevation,
              offset: Offset(0, 10.0 * elevation),
            ),
            // Gold inner glow
            BoxShadow(
              color: AppColors.gold.withOpacity(0.12 * elevation),
              blurRadius: 12.0 * elevation,
              spreadRadius: -1.0,
              offset: const Offset(0, 0),
            ),
          ],
          border: Border.all(
            color: AppColors.gold.withOpacity(0.5),
            width: 1.2,
          ),
        ),
        padding: EdgeInsets.all(padding),
        child: SizedBox(
          width: size - (padding * 2),
          height: size - (padding * 2),
          child: QrImageView(
            data: qrData,
            version: QrVersions.auto,
            errorCorrectionLevel: QrErrorCorrectLevel.H, // Higher error correction
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            size: size - (padding * 2),
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Colors.black,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Colors.black,
            ),
            padding: const EdgeInsets.all(0),
            embeddedImage: embeddedImage,
            embeddedImageStyle: QrEmbeddedImageStyle(
              size: embeddedImageSize,
            ),
          ),
        ),
      ),
    );
  }
} 