import 'package:flutter/material.dart';
import 'package:hive_ui/theme/app_colors.dart' as app_colors;

@immutable
class Club {
  final String id;
  final String name;
  final String description;
  final String category;
  final int memberCount;
  final String status; // active, inactive, pending, verified
  final IconData icon;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? logoUrl;
  final String? bannerUrl;
  final String? website;
  final String? email;
  final String? location;
  final List<String> categories;
  final List<String> tags;
  final int eventCount;

  /// Determines if this is an official registered club or automatically generated
  final bool isOfficial;

  // New fields for HIVE
  final String? mission;
  final String? vision;
  final int? foundedYear;
  final List<String> socialLinks;
  final Map<String, String> leaders; // role -> name
  final int followersCount;
  final List<String> upcomingEventIds;
  final List<String> pastEventIds;
  final Map<String, dynamic> metrics; // Engagement metrics
  final String? customBrandColor;
  final bool isUniversityDepartment;
  final bool isVerifiedPlus; // Premium tier
  final List<String> affiliatedClubs;
  final String? parentOrganization;
  final List<String> subOrganizations;
  final Map<String, String> contactInfo; // type -> value
  final List<String> meetingTimes; // Regular meeting schedule
  final String? roomNumber;
  final String? buildingCode;
  final List<String> requirements; // Membership requirements
  final Map<String, String> resources; // Resource name -> URL
  final List<String> achievements;
  final Map<String, int> engagementStats; // Various engagement statistics

  const Club({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.memberCount,
    required this.status,
    required this.icon,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.logoUrl,
    this.bannerUrl,
    this.website,
    this.email,
    this.location,
    this.categories = const [],
    this.tags = const [],
    this.eventCount = 0,
    this.isOfficial = false,
    this.mission,
    this.vision,
    this.foundedYear,
    this.socialLinks = const [],
    this.leaders = const {},
    this.followersCount = 0,
    this.upcomingEventIds = const [],
    this.pastEventIds = const [],
    this.metrics = const {},
    this.customBrandColor,
    this.isUniversityDepartment = false,
    this.isVerifiedPlus = false,
    this.affiliatedClubs = const [],
    this.parentOrganization,
    this.subOrganizations = const [],
    this.contactInfo = const {},
    this.meetingTimes = const [],
    this.roomNumber,
    this.buildingCode,
    this.requirements = const [],
    this.resources = const {},
    this.achievements = const [],
    this.engagementStats = const {},
  });

  /// Create a Club from a JSON map
  factory Club.fromJson(Map<String, dynamic> json) {
    // Parse icon which could be either a string name or integer code
    IconData parseIcon(dynamic iconValue) {
      if (iconValue is int) {
        // Use predefined icons based on the code point instead of creating new IconData
        switch (iconValue) {
          case 0xe318:
            return Icons.group;
          case 0xe1a5:
            return Icons.business;
          case 0xe639:
            return Icons.sports;
          case 0xe430:
            return Icons.music_note;
          case 0xe40a:
            return Icons.palette;
          case 0xe465:
            return Icons.science;
          case 0xe0c9:
            return Icons.computer;
          default:
            return Icons.group;
        }
      } else if (iconValue is String) {
        return _getIconFromString(iconValue);
      }
      // Default icon if the value is invalid
      return Icons.group;
    }

    return Club(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      memberCount: _parseIntField(json['memberCount']),
      status: json['status'] as String,
      icon: parseIcon(json['icon']),
      imageUrl: json['imageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      logoUrl: json['logoUrl'] as String?,
      bannerUrl: json['bannerUrl'] as String?,
      website: json['website'] as String?,
      email: json['email'] as String?,
      location: json['location'] as String?,
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
      eventCount: _parseIntField(json['eventCount']),
      isOfficial: json['isOfficial'] as bool? ?? false,
      mission: json['mission'] as String?,
      vision: json['vision'] as String?,
      foundedYear:
          json['foundedYear'] is int ? json['foundedYear'] as int? : null,
      socialLinks: (json['socialLinks'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      leaders: (json['leaders'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as String),
          ) ??
          {},
      followersCount: _parseIntField(json['followersCount']),
      upcomingEventIds: (json['upcomingEventIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      pastEventIds: (json['pastEventIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      metrics: json['metrics'] as Map<String, dynamic>? ?? {},
      customBrandColor: json['customBrandColor'] as String?,
      isUniversityDepartment: json['isUniversityDepartment'] as bool? ?? false,
      isVerifiedPlus: json['isVerifiedPlus'] as bool? ?? false,
      affiliatedClubs: (json['affiliatedClubs'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      parentOrganization: json['parentOrganization'] as String?,
      subOrganizations: (json['subOrganizations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      contactInfo: (json['contactInfo'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as String),
          ) ??
          {},
      meetingTimes: (json['meetingTimes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      roomNumber: json['roomNumber'] as String?,
      buildingCode: json['buildingCode'] as String?,
      requirements: (json['requirements'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      resources: (json['resources'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as String),
          ) ??
          {},
      achievements: (json['achievements'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      engagementStats: _parseEngagementStats(json['engagementStats']),
    );
  }

  // Helper method to parse integer fields that might be strings
  static int _parseIntField(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  // Helper method to parse engagement stats that might have string values for integers
  static Map<String, int> _parseEngagementStats(dynamic stats) {
    if (stats == null) return {};
    if (stats is! Map<String, dynamic>) return {};

    return stats.map((key, value) {
      if (value is int) return MapEntry(key, value);
      if (value is String) {
        final parsedValue = int.tryParse(value);
        return MapEntry(key, parsedValue ?? 0);
      }
      return MapEntry(key, 0);
    });
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'memberCount': memberCount,
      'status': status,
      'icon': _getStringFromIcon(icon),
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'logoUrl': logoUrl,
      'bannerUrl': bannerUrl,
      'website': website,
      'email': email,
      'location': location,
      'categories': categories,
      'tags': tags,
      'eventCount': eventCount,
      'isOfficial': isOfficial,
      'mission': mission,
      'vision': vision,
      'foundedYear': foundedYear,
      'socialLinks': socialLinks,
      'leaders': leaders,
      'followersCount': followersCount,
      'upcomingEventIds': upcomingEventIds,
      'pastEventIds': pastEventIds,
      'metrics': metrics,
      'customBrandColor': customBrandColor,
      'isUniversityDepartment': isUniversityDepartment,
      'isVerifiedPlus': isVerifiedPlus,
      'affiliatedClubs': affiliatedClubs,
      'parentOrganization': parentOrganization,
      'subOrganizations': subOrganizations,
      'contactInfo': contactInfo,
      'meetingTimes': meetingTimes,
      'roomNumber': roomNumber,
      'buildingCode': buildingCode,
      'requirements': requirements,
      'resources': resources,
      'achievements': achievements,
      'engagementStats': engagementStats,
    };
  }

  static IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'computer':
        return Icons.computer;
      case 'business':
        return Icons.business;
      case 'sports':
        return Icons.sports;
      case 'music':
        return Icons.music_note;
      case 'art':
        return Icons.palette;
      case 'science':
        return Icons.science;
      default:
        return Icons.group;
    }
  }

  static String _getStringFromIcon(IconData icon) {
    if (icon == Icons.computer) return 'computer';
    if (icon == Icons.business) return 'business';
    if (icon == Icons.sports) return 'sports';
    if (icon == Icons.music_note) return 'music';
    if (icon == Icons.palette) return 'art';
    if (icon == Icons.science) return 'science';
    return 'group';
  }

  String get subtitle => '$memberCount members • $category';

  Club copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    int? memberCount,
    String? status,
    IconData? icon,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? logoUrl,
    String? bannerUrl,
    String? website,
    String? email,
    String? location,
    List<String>? categories,
    List<String>? tags,
    int? eventCount,
    bool? isOfficial,
    String? mission,
    String? vision,
    int? foundedYear,
    List<String>? socialLinks,
    Map<String, String>? leaders,
    int? followersCount,
    List<String>? upcomingEventIds,
    List<String>? pastEventIds,
    Map<String, dynamic>? metrics,
    String? customBrandColor,
    bool? isUniversityDepartment,
    bool? isVerifiedPlus,
    List<String>? affiliatedClubs,
    String? parentOrganization,
    List<String>? subOrganizations,
    Map<String, String>? contactInfo,
    List<String>? meetingTimes,
    String? roomNumber,
    String? buildingCode,
    List<String>? requirements,
    Map<String, String>? resources,
    List<String>? achievements,
    Map<String, int>? engagementStats,
  }) {
    return Club(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      memberCount: memberCount ?? this.memberCount,
      status: status ?? this.status,
      icon: icon ?? this.icon,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      logoUrl: logoUrl ?? this.logoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      website: website ?? this.website,
      email: email ?? this.email,
      location: location ?? this.location,
      categories: categories ?? this.categories,
      tags: tags ?? this.tags,
      eventCount: eventCount ?? this.eventCount,
      isOfficial: isOfficial ?? this.isOfficial,
      mission: mission ?? this.mission,
      vision: vision ?? this.vision,
      foundedYear: foundedYear ?? this.foundedYear,
      socialLinks: socialLinks ?? this.socialLinks,
      leaders: leaders ?? this.leaders,
      followersCount: followersCount ?? this.followersCount,
      upcomingEventIds: upcomingEventIds ?? this.upcomingEventIds,
      pastEventIds: pastEventIds ?? this.pastEventIds,
      metrics: metrics ?? this.metrics,
      customBrandColor: customBrandColor ?? this.customBrandColor,
      isUniversityDepartment:
          isUniversityDepartment ?? this.isUniversityDepartment,
      isVerifiedPlus: isVerifiedPlus ?? this.isVerifiedPlus,
      affiliatedClubs: affiliatedClubs ?? this.affiliatedClubs,
      parentOrganization: parentOrganization ?? this.parentOrganization,
      subOrganizations: subOrganizations ?? this.subOrganizations,
      contactInfo: contactInfo ?? this.contactInfo,
      meetingTimes: meetingTimes ?? this.meetingTimes,
      roomNumber: roomNumber ?? this.roomNumber,
      buildingCode: buildingCode ?? this.buildingCode,
      requirements: requirements ?? this.requirements,
      resources: resources ?? this.resources,
      achievements: achievements ?? this.achievements,
      engagementStats: engagementStats ?? this.engagementStats,
    );
  }

  /// Create a unique ID from an organization name
  static String createIdFromName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }

  /// Convert a Space document from Firestore to a Club
  factory Club.fromSpace(Map<String, dynamic> spaceData) {
    // Parse icon which could be either a string name or integer code
    IconData parseIcon(dynamic iconValue) {
      if (iconValue is int) {
        // Use predefined icons based on the code point instead of creating new IconData
        switch (iconValue) {
          case 0xe318:
            return Icons.group;
          case 0xe1a5:
            return Icons.business;
          case 0xe639:
            return Icons.sports;
          case 0xe430:
            return Icons.music_note;
          case 0xe40a:
            return Icons.palette;
          case 0xe465:
            return Icons.science;
          case 0xe0c9:
            return Icons.computer;
          default:
            return Icons.group;
        }
      } else if (iconValue is String) {
        return _getIconFromString(iconValue);
      }
      // Default icon if the value is invalid
      return Icons.group;
    }

    // Extract tags from the space data
    List<String> extractTags(Map<String, dynamic> data) {
      if (data.containsKey('tags') && data['tags'] is List) {
        return (data['tags'] as List).map((tag) => tag.toString()).toList();
      }
      return [];
    }

    // Extract metrics or create empty one
    Map<String, dynamic> extractMetrics(Map<String, dynamic> data) {
      if (data.containsKey('metrics') && data['metrics'] is Map) {
        return data['metrics'] as Map<String, dynamic>;
      }
      return {};
    }

    // Get member count from metrics if available
    int getMemberCount(Map<String, dynamic> data) {
      if (data.containsKey('metrics') &&
          data['metrics'] is Map &&
          data['metrics'].containsKey('memberCount')) {
        var count = data['metrics']['memberCount'];
        if (count is int) return count;
        if (count is String) return int.tryParse(count) ?? 0;
      }
      return 0;
    }

    // Parse dates safely
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();

      if (dateValue is String) {
        return DateTime.tryParse(dateValue) ?? DateTime.now();
      } else if (dateValue is Map && dateValue.containsKey('seconds')) {
        // Handle Firestore Timestamp
        return DateTime.fromMillisecondsSinceEpoch(
            (dateValue['seconds'] as int) * 1000);
      }

      return DateTime.now();
    }

    return Club(
      id: spaceData['id'] as String? ?? 'unknown',
      name: spaceData['name'] as String? ?? 'Unknown Space',
      description: spaceData['description'] as String? ?? '',
      category:
          spaceData.containsKey('spaceType') && spaceData['spaceType'] != null
              ? spaceData['spaceType'].toString()
              : (extractTags(spaceData).isNotEmpty
                  ? extractTags(spaceData).first
                  : 'General'),
      memberCount: getMemberCount(spaceData),
      status: spaceData['isPrivate'] == true ? 'private' : 'active',
      icon: parseIcon(spaceData['icon']),
      imageUrl: spaceData['imageUrl'] as String?,
      createdAt: parseDate(spaceData['createdAt']),
      updatedAt: parseDate(spaceData['updatedAt']),
      logoUrl: spaceData['logoUrl'] as String?,
      bannerUrl: spaceData['bannerUrl'] as String?,
      website: spaceData['website'] as String?,
      email: spaceData['email'] as String?,
      location: spaceData['location'] as String?,
      categories: extractTags(spaceData),
      tags: extractTags(spaceData),
      eventCount: spaceData['eventCount'] as int? ?? 0,
      isOfficial: spaceData['isOfficial'] as bool? ?? false,
      mission: spaceData['mission'] as String?,
      vision: spaceData['vision'] as String?,
      socialLinks: spaceData.containsKey('socialLinks') &&
              spaceData['socialLinks'] is List
          ? (spaceData['socialLinks'] as List)
              .map((link) => link.toString())
              .toList()
          : [],
      metrics: extractMetrics(spaceData),
      isVerifiedPlus: spaceData['isVerifiedPlus'] as bool? ?? false,
    );
  }

  /// Get the first letter of the club name for avatar display
  String get initial => name.isNotEmpty ? name[0].toUpperCase() : 'C';

  /// Get a truncated description suitable for display in cards
  String get shortDescription {
    if (description.length <= 80) return description;
    return '${description.substring(0, 77)}...';
  }

  /// Check if this club is verified (official and with a buffalo.edu email)
  bool get isVerified {
    return isOfficial && (email?.endsWith('buffalo.edu') ?? false);
  }

  /// Check if this club is featured (has multiple events or is verified)
  bool get isFeatured {
    return eventCount > 1 || isVerified || isVerifiedPlus;
  }

  /// Get formatted member count (e.g., "1.2K members" instead of "1200 members")
  String get formattedMemberCount {
    if (memberCount < 1000) {
      return '$memberCount members';
    } else if (memberCount < 10000) {
      final double k = memberCount / 1000;
      return '${k.toStringAsFixed(1)}K members';
    } else {
      final int k = (memberCount / 1000).round();
      return '${k}K members';
    }
  }

  /// Get all tags including both categories and tags
  List<String> get allTags {
    final Set<String> allTags = {...categories, ...tags};
    if (isOfficial) allTags.add('Official');
    if (isVerified) allTags.add('Verified');
    if (isVerifiedPlus) allTags.add('Verified+');
    if (isUniversityDepartment) allTags.add('UB Department');
    return allTags.toList();
  }

  /// Get an appropriate avatar color based on the club name
  Color get avatarColor {
    if (isUniversityDepartment) return Colors.white;
    if (customBrandColor != null) return brandColor;

    // Generate a deterministic color based on the name
    final int hashCode = name.hashCode;
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.amber,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.orange,
      Colors.cyan,
    ];

    return colors[hashCode.abs() % colors.length];
  }

  /// Get the club's brand color or default
  Color get brandColor {
    if (customBrandColor != null) {
      try {
        return Color(
            int.parse(customBrandColor!.replaceAll('#', ''), radix: 16));
      } catch (_) {}
    }
    return app_colors.AppColors.gold;
  }

  /// Get the appropriate icon for display
  IconData get displayIcon {
    if (isUniversityDepartment) return Icons.school;
    if (icon != Icons.group) return icon;

    // Choose icon based on category
    switch (category.toLowerCase()) {
      case 'academic':
        return Icons.school;
      case 'sports':
        return Icons.sports;
      case 'arts':
        return Icons.palette;
      case 'technology':
        return Icons.computer;
      case 'social':
        return Icons.people;
      case 'service':
        return Icons.volunteer_activism;
      case 'professional':
        return Icons.business;
      default:
        return Icons.group;
    }
  }

  /// Get the verification level description
  String get verificationLevel {
    if (isVerifiedPlus) return 'Verified+';
    if (isVerified) return 'Verified';
    if (isOfficial) return 'Official';
    return 'Community';
  }

  /// Get the organization type description
  String get organizationType {
    if (isUniversityDepartment) return 'University Department';
    if (isVerifiedPlus) return 'Premium Organization';
    if (isVerified) return 'Verified Organization';
    if (isOfficial) return 'Registered Organization';
    return 'Community Organization';
  }

  /// Check if the club has complete profile information
  bool get hasCompleteProfile {
    return description.length > 100 &&
        email != null &&
        location != null &&
        categories.isNotEmpty &&
        (mission != null || vision != null);
  }

  /// Get engagement level based on metrics
  String get engagementLevel {
    final score = (engagementStats['events_hosted'] ?? 0) * 2 +
        (engagementStats['total_attendees'] ?? 0) +
        (engagementStats['active_members'] ?? 0) * 3 +
        followersCount;

    if (score > 1000) return 'Very High';
    if (score > 500) return 'High';
    if (score > 100) return 'Moderate';
    if (score > 0) return 'Low';
    return 'New';
  }

  /// Get the next meeting time if available
  String? get nextMeetingTime {
    if (meetingTimes.isEmpty) return null;
    // TODO: Implement logic to find next meeting time based on schedule
    return meetingTimes.first;
  }

  /// Get the full location string including room if available
  String get fullLocation {
    final List<String> parts = [];
    if (location != null) parts.add(location!);
    if (buildingCode != null) parts.add(buildingCode!);
    if (roomNumber != null) parts.add('Room $roomNumber');
    return parts.join(', ');
  }

  /// Check if the club is currently active
  bool get isActive {
    return status == 'active' &&
        DateTime.now().difference(updatedAt).inDays < 90;
  }

  /// Convert Club to a format compatible with Space
  Map<String, dynamic> toSpace() {
    // Create metrics data
    final metricsData = <String, dynamic>{
      'spaceId': id,
      'memberCount': memberCount,
      'activeMembers': engagementStats['active_members'] ?? 0,
      'weeklyEvents': metrics['weeklyEvents'] ?? 0,
      'monthlyEngagements': metrics['monthlyEngagements'] ?? 0,
      'lastActivity': updatedAt.toIso8601String(),
      'hasNewContent': metrics['hasNewContent'] ?? false,
      'isTrending': metrics['isTrending'] ?? false,
      'engagementScore': metrics['engagementScore'] ?? 0.0,
    };

    // Determine appropriate spaceType from category
    String spaceType = 'other';
    final lowerCategory = category.toLowerCase();

    if (lowerCategory.contains('fraternity') ||
        lowerCategory.contains('sorority')) {
      spaceType = 'fraternityAndSorority';
    } else if (lowerCategory.contains('student') &&
        lowerCategory.contains('org')) {
      spaceType = 'studentOrg';
    } else if (lowerCategory.contains('university') ||
        lowerCategory.contains('department')) {
      spaceType = 'universityOrg';
    } else if (lowerCategory.contains('campus') &&
        lowerCategory.contains('living')) {
      spaceType = 'campusLiving';
    }

    // Convert to Space-compatible format
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon.codePoint,
      'imageUrl': imageUrl,
      'bannerUrl': bannerUrl,
      'metrics': metricsData,
      'tags': [...categories, ...tags],
      'customData': {
        'website': website,
        'email': email,
        'location': location,
        'mission': mission,
        'vision': vision,
        'foundedYear': foundedYear,
        'socialLinks': socialLinks,
        'isOfficial': isOfficial,
        'isVerifiedPlus': isVerifiedPlus,
      },
      'isJoined':
          false, // Default value, to be updated by client code if needed
      'isPrivate': status == 'private',
      'moderators': leaders.values.toList(),
      'admins': [],
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'spaceType': spaceType,
      'eventIds': [...upcomingEventIds, ...pastEventIds],
    };
  }
}
