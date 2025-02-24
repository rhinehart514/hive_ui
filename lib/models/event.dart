import 'package:flutter/material.dart';

@immutable
class Event {
  final String title;
  final String description;
  final String location;
  final DateTime startTime;
  final DateTime endTime;
  final String organizerEmail;
  final String organizerName;
  final String category;
  final String status; // confirmed, cancelled
  final String link;

  const Event({
    required this.title,
    required this.description,
    required this.location,
    required this.startTime,
    required this.endTime,
    required this.organizerEmail,
    required this.organizerName,
    required this.category,
    required this.status,
    required this.link,
  });

  // This will be used when we receive data from the backend
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      title: json['title'] as String,
      description: json['description'] as String,
      location: json['location'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      organizerEmail: json['organizerEmail'] as String,
      organizerName: json['organizerName'] as String,
      category: json['category'] as String,
      status: json['status'] as String,
      link: json['link'] as String,
    );
  }

  // Helper method to format the event time range
  String get formattedTimeRange {
    final startFormat = '${_formatTime(startTime)} ${_formatDate(startTime)}';
    final endFormat = '${_formatTime(endTime)} ${_formatDate(endTime)}';
    return '$startFormat - $endFormat';
  }

  // Helper method to format time
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  // Helper method to format date
  String _formatDate(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dateTime.month - 1]} ${dateTime.day}';
  }
} 