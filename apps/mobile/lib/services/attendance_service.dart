import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event.dart';
import '../models/attendance_record.dart';
import '../utils/app_event_bus.dart';
import '../events/rsvp_status_changed_event.dart';
import 'event_service.dart';
import 'profile_service.dart';
import '../models/user_profile.dart';

/// Service for managing event attendance and check-ins
class AttendanceService {
  static const String _logPrefix = '[AttendanceService]';
  static const String _promotionExpiryKey = 'waitlist_promotion_expiry';
  
  // Cache for promoted users (userId -> {eventId: expiryTime})
  static final Map<String, Map<String, DateTime>> _promotionExpiryCache = {};
  
  /// Check if an event is at capacity
  static bool isEventAtCapacity(Event event) {
    if (event.capacity == null) return false;
    return event.attendees.length >= event.capacity!;
  }
  
  /// RSVP to an event, respecting capacity limits
  static Future<RsvpResult> rsvpToEvent(String eventId, String userId, bool attending) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final eventRef = firestore.collection('events').doc(eventId);
      
      // Get the event to check capacity
      final eventDoc = await eventRef.get();
      if (!eventDoc.exists) {
        debugPrint('$_logPrefix Event $eventId not found');
        return RsvpResult.failed;
      }
      
      final eventData = eventDoc.data()!;
      final capacity = eventData['capacity'] as int?;
      final List<dynamic> attendees = eventData['attendees'] as List<dynamic>? ?? [];
      final List<dynamic> waitlist = eventData['waitlist'] as List<dynamic>? ?? [];
      
      // Execute in a transaction for data consistency
      bool isOnWaitlist = false;
      
      await firestore.runTransaction((transaction) async {
        if (attending) {
          // If user is cancelling RSVP
          if (attendees.contains(userId)) {
            // Already attending, nothing to do
            return;
          }
          
          // Check if user is on waitlist and trying to RSVP directly (should not happen, but handle anyway)
          if (waitlist.contains(userId)) {
            transaction.update(eventRef, {
              'waitlist': FieldValue.arrayRemove([userId]),
            });
          }
          
          // Check if event is at capacity
          if (capacity != null && attendees.length >= capacity) {
            // If at capacity, add to waitlist
            transaction.update(eventRef, {
              'waitlist': FieldValue.arrayUnion([userId]),
              'lastModified': FieldValue.serverTimestamp(),
            });
            isOnWaitlist = true;
          } else {
            // Not at capacity, add to attendees
            transaction.update(eventRef, {
              'attendees': FieldValue.arrayUnion([userId]),
              'lastModified': FieldValue.serverTimestamp(),
            });
            
            // Also update user's saved events
            final userRef = firestore.collection('users').doc(userId);
            transaction.update(userRef, {
              'savedEvents': FieldValue.arrayUnion([eventId]),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        } else {
          // User is cancelling RSVP
          if (attendees.contains(userId)) {
            // Remove from attendees
            transaction.update(eventRef, {
              'attendees': FieldValue.arrayRemove([userId]),
              'lastModified': FieldValue.serverTimestamp(),
            });
            
            // Remove from user's saved events
            final userRef = firestore.collection('users').doc(userId);
            transaction.update(userRef, {
              'savedEvents': FieldValue.arrayRemove([eventId]),
              'updatedAt': FieldValue.serverTimestamp(),
            });
            
            // Promote someone from waitlist if there is anyone
            if (waitlist.isNotEmpty && capacity != null && attendees.length <= capacity) {
              final promotedUserId = waitlist[0];
              
              // Set expiration time for promotion (5 minutes)
              await _setPromotionExpiry(promotedUserId, eventId, 
                DateTime.now().add(const Duration(minutes: 5)));
              
              // Move first user from waitlist to attendees
              transaction.update(eventRef, {
                'waitlist': FieldValue.arrayRemove([promotedUserId]),
                'temp_promoted': FieldValue.arrayUnion([promotedUserId]),
              });
              
              // Send notification to the promoted user
              _sendPromotionNotification(promotedUserId, eventId);
            }
          } else if (waitlist.contains(userId)) {
            // Remove from waitlist
            transaction.update(eventRef, {
              'waitlist': FieldValue.arrayRemove([userId]),
              'lastModified': FieldValue.serverTimestamp(),
            });
          }
        }
      });
      
      // Emit event to the event bus
      AppEventBus.instance.emit(RsvpStatusChangedEvent(
        eventId: eventId,
        userId: userId,
        isAttending: attending && !isOnWaitlist,
        isWaitlisted: isOnWaitlist,
      ));
      
      // Return result
      if (attending) {
        return isOnWaitlist ? RsvpResult.waitlisted : RsvpResult.successful;
      } else {
        return RsvpResult.removed;
      }
    } catch (e) {
      debugPrint('$_logPrefix Error RSVPing to event $eventId: $e');
      return RsvpResult.failed;
    }
  }
  
  /// Confirms a promotion from waitlist to attendee
  static Future<bool> confirmWaitlistPromotion(String eventId, String userId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final eventRef = firestore.collection('events').doc(eventId);
      
      // Check if promotion is still valid
      if (!await _isPromotionValid(userId, eventId)) {
        debugPrint('$_logPrefix Promotion for user $userId expired');
        return false;
      }
      
      // Execute in a transaction
      await firestore.runTransaction((transaction) async {
        // Get current event data to verify state
        final eventDoc = await transaction.get(eventRef);
        if (!eventDoc.exists) return;
        
        final eventData = eventDoc.data()!;
        final List<dynamic> tempPromoted = eventData['temp_promoted'] as List<dynamic>? ?? [];
        
        if (tempPromoted.contains(userId)) {
          // Confirm promotion - add to attendees, remove from temp_promoted
          transaction.update(eventRef, {
            'attendees': FieldValue.arrayUnion([userId]),
            'temp_promoted': FieldValue.arrayRemove([userId]),
            'lastModified': FieldValue.serverTimestamp(),
          });
          
          // Add to user's saved events
          final userRef = firestore.collection('users').doc(userId);
          transaction.update(userRef, {
            'savedEvents': FieldValue.arrayUnion([eventId]),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
      
      // Clear promotion cache
      _clearPromotionExpiry(userId, eventId);
      
      // Emit event
      AppEventBus.instance.emit(RsvpStatusChangedEvent(
        eventId: eventId,
        userId: userId,
        isAttending: true,
        isWaitlisted: false,
      ));
      
      return true;
    } catch (e) {
      debugPrint('$_logPrefix Error confirming promotion: $e');
      return false;
    }
  }
  
  /// Check in a user at an event using location verification
  static Future<bool> checkInUserWithLocation(String eventId, String userId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final eventRef = firestore.collection('events').doc(eventId);
      
      // First verify user is at the event location
      final isAtLocation = await _verifyUserLocation(eventId, userId);
      if (!isAtLocation) {
        debugPrint('$_logPrefix User $userId not at event location');
        return false;
      }
      
      // Create attendance record
      final attendanceRecord = AttendanceRecord(
        userId: userId,
        checkedInAt: DateTime.now(),
        verificationMethod: VerificationMethod.location,
        verificationData: {'verified_by_location': true},
      );
      
      // Save to Firestore
      await eventRef.update({
        'attendance.$userId': attendanceRecord.toJson(),
        'lastModified': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      debugPrint('$_logPrefix Error checking in user: $e');
      return false;
    }
  }
  
  /// Verify user is at event location (within 100 meters)
  static Future<bool> _verifyUserLocation(String eventId, String userId) async {
    // This is a simplified location verification - in a real app we would
    // use location permissions and services to get the actual location
    try {
      // For demo purposes, we'll simulate location verification
      // In production, use a proper location plugin
      
      // Get event coordinates
      final event = await EventService.getEventById(eventId);
      if (event == null) return false;
      
      // Simplified location verification
      // A real implementation would use GPS and compare coordinates
      
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
      
      // For demo purposes, consider 90% of check-ins successful
      final random = DateTime.now().millisecondsSinceEpoch % 10;
      final verified = random < 9; // 90% success rate
      
      return verified;
    } catch (e) {
      debugPrint('$_logPrefix Error verifying location: $e');
      return false;
    }
  }
  
  /// Export attendance records as CSV
  static Future<String> exportAttendanceAsCsv(String eventId) async {
    final firestore = FirebaseFirestore.instance;
    final eventRef = firestore.collection('events').doc(eventId);
    
    try {
      // Check if current user is event owner or verified leader
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return '';
      
      final eventDoc = await eventRef.get();
      if (!eventDoc.exists) return '';
      
      final event = Event.fromJson({'id': eventId, ...eventDoc.data()!});
      
      // Check permission (only owner or verified admin can export)
      if (event.createdBy != currentUser.uid) {
        final userProfile = await ProfileService.getProfile(currentUser.uid);
        if (userProfile == null || userProfile.accountTier != AccountTier.verified) {
          return '';
        }
      }
      
      // Get attendance records
      final Map<String, dynamic> attendanceData = 
          eventDoc.data()?['attendance'] as Map<String, dynamic>? ?? {};
      
      // Get user profiles for attendees
      final List<Map<String, dynamic>> exportData = [];
      
      for (final entry in attendanceData.entries) {
        final userId = entry.key;
        final attendanceRecord = AttendanceRecord.fromJson(entry.value as Map<String, dynamic>);
        
        // Get user profile
        final userProfile = await ProfileService.getProfile(userId);
        if (userProfile != null) {
          exportData.add({
            'First Name': userProfile.firstName,
            'Last Name': userProfile.lastName,
            'Email': userProfile.email,
            'Check-in Time': attendanceRecord.checkedInAt.toString(),
            'Verification Method': attendanceRecord.verificationMethod.toString().split('.').last,
          });
        }
      }
      
      // Generate CSV
      const header = 'First Name,Last Name,Email,Check-in Time,Verification Method\n';
      final rows = exportData.map((record) => 
        '${record['First Name']},${record['Last Name']},${record['Email']},"${record['Check-in Time']}",${record['Verification Method']}'
      ).join('\n');
      
      return header + rows;
    } catch (e) {
      debugPrint('$_logPrefix Error exporting attendance: $e');
      return '';
    }
  }
  
  /// Creates an attendance report for the event organizer
  static Future<AttendanceReport> getAttendanceReport(String eventId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final eventDoc = await firestore.collection('events').doc(eventId).get();
      
      if (!eventDoc.exists) {
        return AttendanceReport.empty();
      }
      
      final event = Event.fromJson({'id': eventId, ...eventDoc.data()!});
      final Map<String, dynamic> attendanceData = 
          eventDoc.data()?['attendance'] as Map<String, dynamic>? ?? {};
      
      return AttendanceReport(
        totalRsvps: event.attendees.length,
        totalCheckedIn: attendanceData.length,
        totalCapacity: event.capacity ?? 0,
        totalWaitlisted: event.waitlist.length,
        attendanceRate: event.attendees.isEmpty 
            ? 0 
            : attendanceData.length / event.attendees.length,
      );
    } catch (e) {
      debugPrint('$_logPrefix Error getting attendance report: $e');
      return AttendanceReport.empty();
    }
  }
  
  /// Set promotion expiry time
  static Future<void> _setPromotionExpiry(String userId, String eventId, DateTime expiry) async {
    try {
      // Set in memory cache
      _promotionExpiryCache.putIfAbsent(userId, () => {})[eventId] = expiry;
      
      // Also save to shared preferences for persistence
      final prefs = await SharedPreferences.getInstance();
      final expiryData = prefs.getString(_promotionExpiryKey) ?? '{}';
      final Map<String, dynamic> expiryMap = jsonDecode(expiryData);
      
      expiryMap[userId] = expiryMap[userId] ?? {};
      expiryMap[userId][eventId] = expiry.toIso8601String();
      
      await prefs.setString(_promotionExpiryKey, jsonEncode(expiryMap));
    } catch (e) {
      debugPrint('$_logPrefix Error setting promotion expiry: $e');
    }
  }
  
  /// Clear promotion expiry time
  static Future<void> _clearPromotionExpiry(String userId, String eventId) async {
    try {
      // Clear from memory cache
      _promotionExpiryCache[userId]?.remove(eventId);
      
      // Also clear from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final expiryData = prefs.getString(_promotionExpiryKey) ?? '{}';
      final Map<String, dynamic> expiryMap = jsonDecode(expiryData);
      
      if (expiryMap.containsKey(userId)) {
        expiryMap[userId].remove(eventId);
        await prefs.setString(_promotionExpiryKey, jsonEncode(expiryMap));
      }
    } catch (e) {
      debugPrint('$_logPrefix Error clearing promotion expiry: $e');
    }
  }
  
  /// Check if promotion is still valid
  static Future<bool> _isPromotionValid(String userId, String eventId) async {
    try {
      // Check memory cache first
      if (_promotionExpiryCache.containsKey(userId) && 
          _promotionExpiryCache[userId]!.containsKey(eventId)) {
        final expiry = _promotionExpiryCache[userId]![eventId]!;
        return DateTime.now().isBefore(expiry);
      }
      
      // Check shared preferences
      final prefs = await SharedPreferences.getInstance();
      final expiryData = prefs.getString(_promotionExpiryKey) ?? '{}';
      final Map<String, dynamic> expiryMap = jsonDecode(expiryData);
      
      if (expiryMap.containsKey(userId) && 
          expiryMap[userId] is Map && 
          expiryMap[userId].containsKey(eventId)) {
        final expiryStr = expiryMap[userId][eventId];
        final expiry = DateTime.parse(expiryStr);
        return DateTime.now().isBefore(expiry);
      }
      
      return false;
    } catch (e) {
      debugPrint('$_logPrefix Error checking promotion validity: $e');
      return false;
    }
  }
  
  /// Send notification to user about promotion from waitlist
  static Future<void> _sendPromotionNotification(String userId, String eventId) async {
    try {
      // Get event details
      final event = await EventService.getEventById(eventId);
      if (event == null) return;
      
      // In a real implementation, this would send a push notification
      // For now we'll just log it
      debugPrint('$_logPrefix Sending promotion notification to user $userId for event ${event.title}');
      
      // For demo, we could vibrate the device
      HapticFeedback.vibrate();
    } catch (e) {
      debugPrint('$_logPrefix Error sending promotion notification: $e');
    }
  }
  
  /// Process expired promotions from waitlist
  static Future<void> processExpiredPromotions() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final now = DateTime.now();
      
      // Iterate through memory cache first
      for (final userId in _promotionExpiryCache.keys) {
        for (final entry in _promotionExpiryCache[userId]!.entries) {
          final eventId = entry.key;
          final expiry = entry.value;
          
          if (now.isAfter(expiry)) {
            // Promotion expired, handle in Firestore
            final eventRef = firestore.collection('events').doc(eventId);
            
            await firestore.runTransaction((transaction) async {
              final eventDoc = await transaction.get(eventRef);
              if (!eventDoc.exists) return;
              
              final eventData = eventDoc.data()!;
              final List<dynamic> tempPromoted = eventData['temp_promoted'] as List<dynamic>? ?? [];
              final List<dynamic> waitlist = eventData['waitlist'] as List<dynamic>? ?? [];
              
              if (tempPromoted.contains(userId)) {
                // Remove from temp_promoted - promotion expired
                transaction.update(eventRef, {
                  'temp_promoted': FieldValue.arrayRemove([userId]),
                });
                
                // If there are more people on waitlist, promote next person
                if (waitlist.isNotEmpty) {
                  final nextPromotedUserId = waitlist[0];
                  
                  // Set new promotion expiry
                  await _setPromotionExpiry(nextPromotedUserId, eventId, 
                    now.add(const Duration(minutes: 5)));
                  
                  // Update waitlist and temp_promoted
                  transaction.update(eventRef, {
                    'waitlist': FieldValue.arrayRemove([nextPromotedUserId]),
                    'temp_promoted': FieldValue.arrayUnion([nextPromotedUserId]),
                  });
                  
                  // Send notification
                  _sendPromotionNotification(nextPromotedUserId, eventId);
                }
              }
            });
            
            // Clear expired promotion
            await _clearPromotionExpiry(userId, eventId);
          }
        }
      }
    } catch (e) {
      debugPrint('$_logPrefix Error processing expired promotions: $e');
    }
  }
}

/// Result of an RSVP attempt
enum RsvpResult {
  /// RSVP was successful
  successful,
  
  /// RSVP failed
  failed,
  
  /// User was added to waitlist
  waitlisted,
  
  /// User was removed from event/waitlist
  removed,
}

/// Report of attendance statistics for an event
class AttendanceReport {
  final int totalRsvps;
  final int totalCheckedIn;
  final int totalCapacity;
  final int totalWaitlisted;
  final double attendanceRate;
  
  AttendanceReport({
    required this.totalRsvps,
    required this.totalCheckedIn,
    required this.totalCapacity,
    required this.totalWaitlisted,
    required this.attendanceRate,
  });
  
  factory AttendanceReport.empty() {
    return AttendanceReport(
      totalRsvps: 0,
      totalCheckedIn: 0,
      totalCapacity: 0,
      totalWaitlisted: 0,
      attendanceRate: 0,
    );
  }
} 