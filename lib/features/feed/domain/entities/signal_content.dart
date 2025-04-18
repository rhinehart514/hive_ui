import 'package:equatable/equatable.dart';

/// Domain entity for the content displayed in the Signal Strip
class SignalContent extends Equatable {
  /// Unique identifier for the signal content
  final String id;
  
  /// Title of the signal content
  final String title;
  
  /// Description or body of the signal content
  final String description;
  
  /// Type of signal content
  final SignalType type;
  
  /// Associated data for the signal content (e.g. event ID, space ID)
  final Map<String, dynamic>? data;
  
  /// Priority level (higher means more important)
  final int priority;
  
  /// Time when the signal content was created
  final DateTime createdAt;
  
  /// Time when the signal content expires
  final DateTime? expiresAt;
  
  /// URL for associated image, if any
  final String? imageUrl;
  
  /// Action text for the content (e.g., "joined a space")
  final String? action;
  
  /// Member count for spaces and clubs
  final int? memberCount;
  
  /// Timestamp for when the content was generated
  DateTime get timestamp => createdAt;
  
  /// Whether the content is marked as hot
  final bool isHot;
  
  /// Whether the content is marked as trending
  final bool isTrending;
  
  /// Constructor
  SignalContent({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.data,
    this.priority = 0,
    DateTime? createdAt,
    this.expiresAt,
    this.imageUrl,
    this.action,
    this.memberCount,
    this.isHot = false,
    this.isTrending = false,
  }) : createdAt = createdAt ?? DateTime.now();
  
  /// Check if the signal content is expired
  bool isExpired() {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
  
  @override
  List<Object?> get props => [
    id,
    title,
    description,
    type,
    priority,
    createdAt,
    expiresAt,
    isHot,
    isTrending,
    action,
    memberCount,
  ];
}

/// Types of signal content
enum SignalType {
  /// Events from the previous night on campus
  lastNight,
  
  /// Top event happening today
  topEvent,
  
  /// Recommended space to try
  trySpace,
  
  /// HiveLab activity teaser
  hiveLab,
  
  /// Surprising events that gained unexpected popularity
  underratedGem,
  
  /// Official university news
  universityNews,
  
  /// Community update
  communityUpdate,
  
  /// Time marker for morning
  timeMorning,
  
  /// Time marker for afternoon
  timeAfternoon,
  
  /// Time marker for evening
  timeEvening,
  
  /// Space with high activity (heat)
  spaceHeat,
  
  /// Ritual Launch notification
  ritualLaunch,
  
  /// Friend motion notification
  friendMotion,
  
  /// Club related content
  club,
  
  /// Time marker content
  timeMarker,
  
  /// Photo content
  photo,
  
  /// Space related content
  space,
} 