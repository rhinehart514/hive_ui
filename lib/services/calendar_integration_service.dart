import 'package:add_2_calendar/add_2_calendar.dart' as calendar;
import 'package:flutter/material.dart';
import '../models/event.dart';

/// Service for handling calendar integration operations
class CalendarIntegrationService {
  /// Add an event to the device calendar
  static Future<bool> addEventToCalendar(Event event) async {
    try {
      final calendarEvent = calendar.Event(
        title: event.title,
        description: event.description,
        location: event.location,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      // The add_2_calendar plugin handles the platform-specific calendar operations
      calendar.Add2Calendar.addEvent2Cal(calendarEvent);

      // Note: The package doesn't provide a way to know if the event was actually added
      // since it just launches the calendar app and the user might cancel
      // So we return true if we successfully launched the calendar app
      return true;
    } catch (e) {
      debugPrint('Error adding event to calendar: $e');
      return false;
    }
  }

  /// Create a calendar event object from a HIVE event
  static calendar.Event createCalendarEvent(Event event) {
    return calendar.Event(
      title: event.title,
      description: _formatEventDescription(event),
      location: event.location,
      startDate: event.startDate,
      endDate: event.endDate,
      // Set recurrence rule if the event is recurring (not implemented yet)
      // recurrence: calendar.Recurrence(
      //   frequency: calendar.Frequency.weekly,
      //   endDate: event.endDate.add(const Duration(days: 365)),
      // ),
    );
  }

  /// Format event description with additional event details
  static String _formatEventDescription(Event event) {
    final buffer = StringBuffer();

    // Add main description
    buffer.writeln(event.description);
    buffer.writeln();

    // Add organizer info
    if (event.organizerName.isNotEmpty) {
      buffer.writeln('Organized by: ${event.organizerName}');
    }

    if (event.organizerEmail.isNotEmpty) {
      buffer.writeln('Contact: ${event.organizerEmail}');
    }

    // Add category
    if (event.category.isNotEmpty) {
      buffer.writeln('Category: ${event.category}');
    }

    // Add link to original event
    if (event.link.isNotEmpty) {
      buffer.writeln('\nEvent link: ${event.link}');
    }

    // Add HIVE app signature
    buffer.writeln('\nAdded from HIVE app');

    return buffer.toString();
  }

  /// Check if calendar functionality is available on this device
  static Future<bool> isCalendarAvailable() async {
    // The add_2_calendar package doesn't offer a direct way to check
    // We could potentially try to add a test event and catch exceptions
    // For now, assume it's available on all platforms supported by the package
    return true;
  }
}
