import 'package:flutter/services.dart';

/// Utility class for providing haptic feedback in messaging interactions
class HapticFeedbackUtils {
  /// Trigger a light impact feedback for common interactions
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }
  
  /// Trigger a medium impact feedback for more significant actions
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }
  
  /// Trigger a heavy impact feedback for important actions
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }
  
  /// Trigger a vibration feedback
  static void vibrate() {
    HapticFeedback.vibrate();
  }
  
  /// Feedback for sending a message
  static void messageSent() {
    lightImpact();
  }
  
  /// Feedback for receiving a new message
  static void messageReceived() {
    mediumImpact();
  }
  
  /// Feedback for long-pressing a message (opening context menu)
  static void messageLongPress() {
    HapticFeedback.heavyImpact();
  }
  
  /// Feedback for starting to record audio
  static void recordStart() {
    HapticFeedback.heavyImpact();
  }
  
  /// Feedback for stopping recording audio
  static void recordStop() {
    HapticFeedback.mediumImpact();
  }
  
  /// Feedback for selecting a reaction
  static void selectReaction() {
    HapticFeedback.lightImpact();
  }
  
  /// Feedback for tapping on an attachment
  static void tapAttachment() {
    HapticFeedback.selectionClick();
  }
  
  /// Feedback for error
  static void error() {
    HapticFeedback.vibrate();
  }
} 
 
 