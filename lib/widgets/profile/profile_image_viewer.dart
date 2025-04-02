import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/components/optimized_image.dart';
import 'dart:io';

/// Shows a full-screen dialog to view a profile image
void showProfileImageViewer(BuildContext context, String? imageUrl) {
  // Check for null or empty image URL
  if (imageUrl == null || imageUrl.isEmpty) {
    debugPrint('Null or empty image URL provided to showProfileImageViewer');
    return;
  }

  // Handle network images vs local files differently
  if (imageUrl.startsWith('http')) {
    try {
      final uri = Uri.parse(imageUrl);
      if (!uri.hasScheme || !uri.hasAuthority) {
        debugPrint('Invalid image URL format in showProfileImageViewer: $imageUrl');
        return;
      }
    } catch (e) {
      debugPrint('Error parsing image URL in showProfileImageViewer: $e');
      return;
    }
  } else {
    // For local files, check if the file exists
    try {
      final file = File(imageUrl);
      if (!file.existsSync()) {
        debugPrint('Local image file does not exist: $imageUrl');
        return;
      }
    } catch (e) {
      debugPrint('Error checking local file: $e');
      return;
    }
  }

  // Use a unique, non-null Hero tag
  final heroTag = 'profile-image-${DateTime.now().millisecondsSinceEpoch}';

  // Enter immersive mode that hides navigation and status bars
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black.withOpacity(0.85),
      pageBuilder: (BuildContext context, _, __) {
        return ProfileImageViewer(
          imageUrl: imageUrl,
          heroTag: heroTag,
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    ),
  ).then((_) {
    // Restore system UI when viewer is closed
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  });
}

/// A widget that displays an expanded profile image with zoom functionality
class ProfileImageViewer extends StatefulWidget {
  /// The URL of the image to display
  final String imageUrl;

  /// Hero tag for transition animation
  final String heroTag;

  const ProfileImageViewer({
    super.key,
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  State<ProfileImageViewer> createState() => _ProfileImageViewerState();
}

class _ProfileImageViewerState extends State<ProfileImageViewer> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  double _dragOffset = 0.0;
  bool _isDragging = false;
  double _scale = 1.0;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  // Handle vertical drag which will be used for pull-up effect
  void _handleDragUpdate(DragUpdateDetails details) {
    if (_scale > 1.0) return; // Don't allow drag when zoomed in
    
    setState(() {
      _isDragging = true;
      _dragOffset += details.delta.dy;
      // Limit the drag offset to reasonable values
      _dragOffset = _dragOffset.clamp(-200.0, 200.0);
    });
  }
  
  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dy;
    
    setState(() {
      _isDragging = false;
    });
    
    // Close if dragged down with significant velocity or distance
    if (_dragOffset > 100 || velocity > 700) {
      _animateToClose();
    } else {
      // Reset position
      setState(() {
        _dragOffset = 0.0;
      });
    }
  }
  
  // Animate closure with a fade-out effect
  void _animateToClose() {
    _animationController.duration = const Duration(milliseconds: 200);
    _animationController.addListener(() {
      setState(() {
        // Animate the drag offset for a smoother closing effect
        _dragOffset = 200.0 * _animationController.value;
      });
    });
    
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.pop(context);
      }
    });
    
    _animationController.forward(from: 0.0);
  }
  
  // Update scale when zoom changes
  void _handleScaleUpdate(double newScale) {
    setState(() {
      _scale = newScale;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    // Calculate opacity based on drag (fade out when dragging down)
    final opacity = 1.0 - (_dragOffset.abs() / 300).clamp(0.0, 1.0);
    
    // Scale and translation for the drag effect
    final scale = _isDragging 
        ? 1.0 - (_dragOffset.abs() / 1000) 
        : 1.0;
        
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: opacity,
        child: GestureDetector(
          onVerticalDragUpdate: _handleDragUpdate,
          onVerticalDragEnd: _handleDragEnd,
          onTap: () => Navigator.pop(context),
          child: Container(
            width: screenSize.width,
            height: screenSize.height,
            color: Colors.transparent,
            child: Stack(
              children: [
                // Fullscreen image with transformation
                Transform(
                  transform: Matrix4.identity()
                    ..translate(0.0, _dragOffset)
                    ..scale(scale),
                  child: Center(
                    child: Hero(
                      tag: widget.heroTag,
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        onInteractionUpdate: (details) {
                          _handleScaleUpdate(details.scale);
                        },
                        child: _buildImage(context, isSmallScreen),
                      ),
                    ),
                  ),
                ),
                
                // Pull-up indicator at the bottom
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _scale <= 1.0 ? 0.8 : 0.0,
                    child: const Center(
                      child: Icon(
                        Icons.keyboard_arrow_up,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                
                // Pull-down indicator at the top
                Positioned(
                  top: 30,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _scale <= 1.0 ? 0.8 : 0.0,
                    child: const Center(
                      child: Text(
                        'Pull down to close',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),

                // Close button with solid background
                Positioned(
                  top: isSmallScreen ? 40 : 60,
                  right: isSmallScreen ? 16 : 40,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      customBorder: const CircleBorder(),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the image widget based on the URL type
  Widget _buildImage(BuildContext context, bool isSmallScreen) {
    // Additional check for empty URL (this should never happen due to validation in showProfileImageViewer)
    if (widget.imageUrl.isEmpty) {
      return _buildErrorWidget(isSmallScreen, 'No image provided');
    }

    // Handle local files
    if (!widget.imageUrl.startsWith('http')) {
      try {
        // For local files, use Image.file not Image.asset
        return Image.file(
          File(widget.imageUrl),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error loading local image in viewer: $error');
            return _buildErrorWidget(isSmallScreen);
          },
        );
      } catch (e) {
        debugPrint('Exception loading local image in viewer: $e');
        return _buildErrorWidget(isSmallScreen);
      }
    }

    // Network image
    return OptimizedImage(
      imageUrl: widget.imageUrl,
      fit: BoxFit.contain,
      errorWidget: (context, url, error) {
        debugPrint('Error loading network image in viewer: $error');
        return _buildErrorWidget(isSmallScreen);
      },
      loadingWidget: const Center(
        child: CircularProgressIndicator(
          color: AppColors.gold,
        ),
      ),
    );
  }

  /// Builds an error widget when image loading fails
  Widget _buildErrorWidget(bool isSmallScreen, [String message = 'Unable to load image']) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
