import 'package:flutter/material.dart';
import 'club.dart';

@immutable
class Organization {
  final String id;
  final String name;
  final String description;
  final String category;
  final int memberCount;
  final String status; // active, inactive
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
  final bool isVerified;
  final bool isOfficial;
  final String? foundedYear;
  final String? mission;
  final List<String> leaders;
  final String? contactPhone;
  final String? socialMedia;
  final String? affiliatedWith;
  final int followersCount;

  const Organization({
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
    this.isVerified = false,
    this.isOfficial = false,
    this.foundedYear,
    this.mission,
    this.leaders = const [],
    this.contactPhone,
    this.socialMedia,
    this.affiliatedWith,
    this.followersCount = 0,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      memberCount: json['memberCount'] as int,
      status: json['status'] as String,
      icon: _getIconFromString(json['icon'] as String),
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
          const [],
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      eventCount: json['eventCount'] as int? ?? 0,
      isVerified: json['isVerified'] as bool? ?? false,
      isOfficial: json['isOfficial'] as bool? ?? false,
      foundedYear: json['foundedYear'] as String?,
      mission: json['mission'] as String?,
      leaders: (json['leaders'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      contactPhone: json['contactPhone'] as String?,
      socialMedia: json['socialMedia'] as String?,
      affiliatedWith: json['affiliatedWith'] as String?,
      followersCount: json['followersCount'] as int? ?? 0,
    );
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
      'isVerified': isVerified,
      'isOfficial': isOfficial,
      'foundedYear': foundedYear,
      'mission': mission,
      'leaders': leaders,
      'contactPhone': contactPhone,
      'socialMedia': socialMedia,
      'affiliatedWith': affiliatedWith,
      'followersCount': followersCount,
    };
  }

  static IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'business':
        return Icons.business;
      case 'school':
        return Icons.school;
      case 'sports':
        return Icons.sports;
      case 'music':
        return Icons.music_note;
      case 'art':
        return Icons.palette;
      case 'science':
        return Icons.science;
      case 'volunteer':
        return Icons.volunteer_activism;
      case 'government':
        return Icons.account_balance;
      case 'medical':
        return Icons.local_hospital;
      case 'technology':
        return Icons.computer;
      default:
        return Icons.groups;
    }
  }

  static String _getStringFromIcon(IconData icon) {
    if (icon == Icons.business) return 'business';
    if (icon == Icons.school) return 'school';
    if (icon == Icons.sports) return 'sports';
    if (icon == Icons.music_note) return 'music';
    if (icon == Icons.palette) return 'art';
    if (icon == Icons.science) return 'science';
    if (icon == Icons.volunteer_activism) return 'volunteer';
    if (icon == Icons.account_balance) return 'government';
    if (icon == Icons.local_hospital) return 'medical';
    if (icon == Icons.computer) return 'technology';
    return 'groups';
  }

  String get subtitle => '$memberCount members • $category';

  Organization copyWith({
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
    bool? isVerified,
    bool? isOfficial,
    String? foundedYear,
    String? mission,
    List<String>? leaders,
    String? contactPhone,
    String? socialMedia,
    String? affiliatedWith,
    int? followersCount,
  }) {
    return Organization(
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
      isVerified: isVerified ?? this.isVerified,
      isOfficial: isOfficial ?? this.isOfficial,
      foundedYear: foundedYear ?? this.foundedYear,
      mission: mission ?? this.mission,
      leaders: leaders ?? this.leaders,
      contactPhone: contactPhone ?? this.contactPhone,
      socialMedia: socialMedia ?? this.socialMedia,
      affiliatedWith: affiliatedWith ?? this.affiliatedWith,
      followersCount: followersCount ?? this.followersCount,
    );
  }

  /// Create a unique ID from an organization name
  static String createIdFromName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }

  /// Get the first letter of the organization name for avatar display
  String get initial => name.isNotEmpty ? name[0].toUpperCase() : 'O';

  /// Get a truncated description suitable for display in cards
  String get shortDescription {
    if (description.length <= 80) return description;
    return '${description.substring(0, 77)}...';
  }

  /// Get the avatar color based on the organization category
  Color get avatarColor {
    switch (category.toLowerCase()) {
      case 'academic':
      case 'education':
        return Colors.blue.shade700;
      case 'business':
      case 'professional':
        return Colors.purple.shade700;
      case 'government':
      case 'political':
        return Colors.red.shade700;
      case 'nonprofit':
      case 'charitable':
        return Colors.teal.shade700;
      case 'technology':
        return Colors.cyan.shade700;
      case 'arts':
      case 'culture':
        return Colors.pink.shade700;
      case 'sports':
      case 'recreation':
        return Colors.green.shade700;
      case 'medical':
      case 'health':
        return Colors.orange.shade700;
      default:
        return Colors.indigo.shade700;
    }
  }

  /// Get formatted member count (e.g., "1.2K members" instead of "1200 members")
  String get formattedMemberCount {
    if (memberCount < 1000) return '$memberCount members';
    if (memberCount < 10000) {
      return '${(memberCount / 1000).toStringAsFixed(1)}K members';
    }
    return '${(memberCount / 1000).toStringAsFixed(0)}K members';
  }

  /// Check if the organization is verified based on its email and official status
  bool get isOfficiallyVerified {
    return isOfficial && isVerified && (email?.contains('.edu') ?? false);
  }

  /// Check if the organization is a university department
  bool get isUniversityDepartment {
    final lowerName = name.toLowerCase();
    final departmentKeywords = [
      'department of',
      'school of',
      'college of',
      'office of',
      'center for',
      'institute of',
      'division of',
      'program in',
    ];

    return departmentKeywords.any((keyword) => lowerName.contains(keyword)) &&
        (lowerName.contains('ub') ||
            lowerName.contains('buffalo') ||
            email?.endsWith('buffalo.edu') == true);
  }

  /// Get the appropriate icon for the organization
  IconData get displayIcon {
    if (isUniversityDepartment) {
      return Icons
          .account_balance; // Temporary icon while image asset is used in UI
    }
    return icon;
  }

  /// Convert this Organization to a Club
  Club toClub() {
    return Club(
      id: id,
      name: name,
      description: description,
      category: category,
      memberCount: memberCount,
      status: status,
      icon: icon,
      imageUrl: imageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
      logoUrl: logoUrl,
      bannerUrl: bannerUrl,
      website: website,
      email: email,
      location: location,
      categories: categories,
      tags: tags,
      eventCount: eventCount,
      isOfficial: isOfficial,
      mission: mission,
      vision: null,
      foundedYear: foundedYear != null ? int.tryParse(foundedYear!) : null,
      socialLinks: [if (socialMedia != null) socialMedia!],
      leaders:
          leaders.asMap().map((key, value) => MapEntry(key.toString(), value)),
      followersCount: followersCount,
      upcomingEventIds: const [],
      pastEventIds: const [],
      metrics: const {},
      customBrandColor: null,
      isUniversityDepartment: false,
      isVerifiedPlus: false,
      affiliatedClubs: const [],
      parentOrganization: affiliatedWith,
      subOrganizations: const [],
      contactInfo: {
        if (contactPhone != null) 'phone': contactPhone!,
      },
      meetingTimes: const [],
      roomNumber: null,
      buildingCode: null,
      requirements: const [],
      resources: const {},
      achievements: const [],
      engagementStats: const {},
    );
  }
}
