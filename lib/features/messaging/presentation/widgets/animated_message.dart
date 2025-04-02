import 'package:flutter/material.dart';

/// Widget to animate messages when they appear
class AnimatedMessage extends StatefulWidget {
  /// The child widget to animate
  final Widget child;
  
  /// Whether the message is from the current user (sent) or another user (received)
  final bool isFromCurrentUser;
  
  /// Custom animation duration, defaults to 300ms
  final Duration duration;
  
  /// Optional delay before starting the animation
  final Duration? delay;
  
  const AnimatedMessage({
    Key? key,
    required this.child,
    required this.isFromCurrentUser,
    this.duration = const Duration(milliseconds: 300),
    this.delay,
  }) : super(key: key);

  @override
  _AnimatedMessageState createState() => _AnimatedMessageState();
}

class _AnimatedMessageState extends State<AnimatedMessage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    // Create slide animation based on message direction
    final beginOffset = widget.isFromCurrentUser ? const Offset(0.3, 0) : const Offset(-0.3, 0);
    _slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    // Create fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    // Start animation after delay if specified
    if (widget.delay != null) {
      Future.delayed(widget.delay!, () {
        if (mounted) {
          _controller.forward();
        }
      });
    } else {
      _controller.forward();
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Widget that animates message status changes
class AnimatedMessageStatus extends StatefulWidget {
  /// The child widget containing the status indicator
  final Widget child;
  
  /// Duration of the animation
  final Duration duration;
  
  const AnimatedMessageStatus({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
  }) : super(key: key);

  @override
  _AnimatedMessageStatusState createState() => _AnimatedMessageStatusState();
}

class _AnimatedMessageStatusState extends State<AnimatedMessageStatus> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
    
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
} 
 
 