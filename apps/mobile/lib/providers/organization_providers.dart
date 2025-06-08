import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

import '../models/organization.dart';
import '../models/event.dart';
import '../providers/event_providers.dart'; // Added import for eventsProvider

// Provider for the currently selected organization category
final selectedOrgCategoryProvider = StateProvider<String?>((ref) => null);

// Provider for all available organization categories
final orgCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final organizations = await ref.watch(organizationsProvider.future);

  // Extract unique categories and sort them
  final categories = organizations.map((org) => org.category).toSet().toList();

  categories.sort();
  return categories;
});

// Provider for all organizations
final organizationsProvider = FutureProvider<List<Organization>>((ref) async {
  try {
    // First check if we need to refresh data from RSS feed
    final shouldRefresh = ref.watch(refreshOrganizationsProvider);

    // Use a mix of pre-built organizations and RSS feed data
    final List<Organization> organizations = await _getOrganizations();

    return organizations;
  } catch (e) {
    debugPrint('Error loading organizations: $e');
    return [];
  }
});

// Provider for organizations filtered by category
final organizationsByCategoryProvider =
    FutureProvider.family<List<Organization>, String>((ref, category) async {
  final organizations = await ref.watch(organizationsProvider.future);

  return organizations
      .where((org) => org.category.toLowerCase() == category.toLowerCase())
      .toList();
});

// Provider to force refresh of organization data
final refreshOrganizationsProvider = StateProvider<bool>((ref) => false);

// Helper to get organizations from both pre-built data and RSS feeds
Future<List<Organization>> _getOrganizations() async {
  // Start with pre-built organizations
  final List<Organization> organizations = _getPreBuiltOrganizations();

  try {
    // Try to fetch from RSS feeds
    final rssOrganizations = await _fetchOrganizationsFromRss();
    organizations.addAll(rssOrganizations);
  } catch (e) {
    debugPrint('Error fetching organizations from RSS: $e');
    // Continue with pre-built orgs if RSS fetch fails
  }

  return organizations;
}

// Pre-built organizations for initial data
List<Organization> _getPreBuiltOrganizations() {
  return [
    Organization(
      id: 'university_alumni_association',
      name: 'University Alumni Association',
      description:
          'Official alumni network connecting graduates with resources, events, and networking opportunities. Supporting career advancement and continued involvement with university initiatives.',
      category: 'Education',
      memberCount: 5800,
      status: 'active',
      icon: Icons.school,
      createdAt: DateTime.now().subtract(const Duration(days: 365 * 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      logoUrl: 'https://example.com/logo.png',
      bannerUrl: 'https://example.com/banner.jpg',
      website: 'https://alumni.university.edu',
      email: 'alumni@university.edu',
      location: 'University Campus, Building 5',
      isVerified: true,
      isOfficial: true,
      foundedYear: '1950',
      mission:
          'Connecting alumni across generations to strengthen the university community',
      leaders: const ['Dr. Jane Smith', 'Prof. Robert Johnson'],
      eventCount: 12,
      followersCount: 4200,
    ),
    Organization(
      id: 'tech_innovators_hub',
      name: 'Tech Innovators Hub',
      description:
          'Community of technology enthusiasts and professionals collaborating on cutting-edge projects. Regular workshops, hackathons, and networking events for tech-minded individuals.',
      category: 'Technology',
      memberCount: 3200,
      status: 'active',
      icon: Icons.computer,
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      website: 'https://techhub.org',
      email: 'info@techhub.org',
      location: 'Innovation District, Downtown',
      isVerified: true,
      isOfficial: false,
      foundedYear: '2018',
      mission:
          'Fostering tech innovation through collaboration and knowledge sharing',
      leaders: const ['Alex Chen', 'Maya Thompson'],
      eventCount: 8,
      followersCount: 2800,
    ),
    Organization(
      id: 'sustainability_action_network',
      name: 'Sustainability Action Network',
      description:
          'Environmental advocacy group focused on campus sustainability initiatives and community-wide ecological awareness. Coordinating recycling programs, clean energy campaigns, and educational events.',
      category: 'Nonprofit',
      memberCount: 1500,
      status: 'active',
      icon: Icons.volunteer_activism,
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      website: 'https://sustainabilitynetwork.org',
      email: 'action@sustainnet.org',
      location: 'Science Center, Room 302',
      isVerified: false,
      isOfficial: false,
      foundedYear: '2020',
      mission:
          'Creating a more sustainable future through local action and education',
      leaders: const ['Jordan Rivera', 'Sam Lee'],
      eventCount: 5,
      followersCount: 1200,
    ),
    Organization(
      id: 'community_health_alliance',
      name: 'Community Health Alliance',
      description:
          'Coalition of healthcare professionals, students, and community members promoting public health initiatives. Organizing health fairs, screenings, education campaigns, and volunteer opportunities.',
      category: 'Medical',
      memberCount: 2100,
      status: 'active',
      icon: Icons.local_hospital,
      createdAt: DateTime.now().subtract(const Duration(days: 240)),
      updatedAt: DateTime.now().subtract(const Duration(days: 7)),
      website: 'https://communityhealthalliance.org',
      email: 'contact@healthalliance.org',
      location: 'Medical Campus, Building H',
      isVerified: true,
      isOfficial: true,
      foundedYear: '2016',
      mission:
          'Improving health outcomes through community engagement and education',
      leaders: const ['Dr. Michael Johnson', 'Nurse Sophia Garcia'],
      eventCount: 9,
      followersCount: 1850,
    ),
    Organization(
      id: 'student_government_association',
      name: 'Student Government Association',
      description:
          'Elected student body representing undergraduate interests to university administration. Advocating for student rights, allocating activity funds, and organizing campus-wide events.',
      category: 'Government',
      memberCount: 75,
      status: 'active',
      icon: Icons.account_balance,
      createdAt: DateTime.now().subtract(const Duration(days: 365 * 5)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      website: 'https://sga.university.edu',
      email: 'sga@university.edu',
      location: 'Student Union, Suite 200',
      isVerified: true,
      isOfficial: true,
      foundedYear: '1892',
      mission: 'Representing student interests and enhancing campus life',
      leaders: const ['Taylor Adams (President)', 'Jamie Wilson (Vice President)'],
      eventCount: 15,
      followersCount: 3500,
    ),
    // Add more UB-specific organizations
    Organization(
      id: 'engineering_student_society',
      name: 'Engineering Student Society',
      description:
          'Professional organization for engineering students focused on career development, networking, and technical projects. Hosting industry talks, workshops, and design competitions.',
      category: 'Academic',
      memberCount: 450,
      status: 'active',
      icon: Icons.engineering,
      createdAt: DateTime.now().subtract(const Duration(days: 365 * 3)),
      updatedAt: DateTime.now(),
      website: 'https://ubess.org',
      email: 'ess@buffalo.edu',
      location: 'Davis Hall',
      isVerified: true,
      isOfficial: true,
      foundedYear: '1985',
      mission: 'Bridging engineering education with professional practice',
      leaders: const ['Emily Zhang (President)', 'Marcus Rodriguez (VP)'],
      eventCount: 20,
      followersCount: 800,
    ),
    Organization(
      id: 'computer_science_club',
      name: 'Computer Science Club',
      description:
          'Student organization dedicated to exploring computer science beyond the classroom. Regular coding workshops, hackathons, and tech talks from industry professionals.',
      category: 'Technology',
      memberCount: 320,
      status: 'active',
      icon: Icons.computer,
      createdAt: DateTime.now().subtract(const Duration(days: 365 * 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
      website: 'https://ubcsc.org',
      email: 'csc@buffalo.edu',
      location: 'Davis Hall, Room 338',
      isVerified: true,
      isOfficial: true,
      foundedYear: '1990',
      mission: 'Fostering innovation and collaboration in computer science',
      leaders: const ['David Kim', 'Sarah Johnson'],
      eventCount: 25,
      followersCount: 600,
    ),
    Organization(
      id: 'international_student_association',
      name: 'International Student Association',
      description:
          'Cultural organization promoting diversity and global understanding. Organizing cultural festivals, language exchange programs, and international student support services.',
      category: 'Cultural',
      memberCount: 890,
      status: 'active',
      icon: Icons.public,
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      website: 'https://ubisa.org',
      email: 'isa@buffalo.edu',
      location: 'Student Union',
      isVerified: true,
      isOfficial: true,
      foundedYear: '1975',
      mission:
          'Building bridges across cultures and supporting international students',
      leaders: const ['Mei Chen', 'Abdul Rahman'],
      eventCount: 30,
      followersCount: 1200,
    ),
  ];
}

// Fetches organizations from RSS feeds
Future<List<Organization>> _fetchOrganizationsFromRss() async {
  final List<Organization> organizations = [];

  // List of RSS feed URLs to fetch from
  final List<String> rssFeedUrls = [
    'https://calendar.buffalo.edu/organizations.rss',
    'https://buffalo.campuslabs.com/engage/organizations.rss',
  ];

  // Skip if no feeds are configured
  if (rssFeedUrls.isEmpty) {
    return organizations;
  }

  for (final url in rssFeedUrls) {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        // Parse the XML RSS feed
        final items = document.findAllElements('item');

        for (final item in items) {
          try {
            // Extract organization data from RSS item
            final title =
                _getXmlElementText(item, 'title') ?? 'Unnamed Organization';
            final description = _getXmlElementText(item, 'description');
            final link = _getXmlElementText(item, 'link') ?? '';
            final pubDate = _getXmlElementText(item, 'pubDate');

            // Extract additional fields if they exist in your RSS feed
            final category =
                _getXmlElementText(item, 'category') ?? 'Uncategorized';
            final imageUrl = _getXmlElementText(item, 'image') ??
                _extractImageFromContent(description);

            // Create a unique ID from the title
            final id = Organization.createIdFromName(title);

            // Create an organization from RSS data
            final organization = Organization(
              id: id,
              name: title,
              description: _cleanDescription(description),
              category: category,
              memberCount: 0, // Default since RSS might not provide this
              status: 'active',
              icon: _getIconFromCategory(category),
              createdAt: _parseDate(pubDate),
              updatedAt: _parseDate(pubDate),
              website: link,
              imageUrl: imageUrl,
              eventCount: 0, // Default since RSS might not provide this
            );

            organizations.add(organization);
          } catch (e) {
            debugPrint('Error parsing organization from RSS item: $e');
            // Skip this item and continue with the next
            continue;
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching from RSS feed $url: $e');
      // Continue with the next URL
      continue;
    }
  }

  return organizations;
}

// Helper functions for RSS data parsing

String? _getXmlElementText(xml.XmlElement element, String name) {
  final childElements = element.findElements(name);
  if (childElements.isNotEmpty) {
    return childElements.first.innerText;
  }
  return null;
}

String _cleanDescription(String? description) {
  if (description == null) return 'No description available';

  // Remove HTML tags
  final withoutHtml = description.replaceAll(RegExp(r'<[^>]*>'), '');

  // Decode HTML entities
  final decoded = _decodeHtmlEntities(withoutHtml);

  // Trim and limit length
  return decoded.trim().length > 300
      ? '${decoded.trim().substring(0, 297)}...'
      : decoded.trim();
}

String _decodeHtmlEntities(String input) {
  return input
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'");
}

String? _extractImageFromContent(String? content) {
  if (content == null) return null;

  // Try to extract image URL from HTML img tag
  final imgRegex = RegExp(r'<img[^>]+src="([^">]+)"');
  final match = imgRegex.firstMatch(content);

  if (match != null && match.groupCount >= 1) {
    return match.group(1);
  }

  return null;
}

DateTime _parseDate(String? dateStr) {
  if (dateStr == null) return DateTime.now();

  try {
    return DateTime.parse(dateStr);
  } catch (e) {
    return DateTime.now();
  }
}

IconData _getIconFromCategory(String category) {
  final lowerCategory = category.toLowerCase();

  if (lowerCategory.contains('edu') || lowerCategory.contains('academic')) {
    return Icons.school;
  } else if (lowerCategory.contains('tech') ||
      lowerCategory.contains('computer')) {
    return Icons.computer;
  } else if (lowerCategory.contains('health') ||
      lowerCategory.contains('medic')) {
    return Icons.local_hospital;
  } else if (lowerCategory.contains('gov') || lowerCategory.contains('polit')) {
    return Icons.account_balance;
  } else if (lowerCategory.contains('art') ||
      lowerCategory.contains('cultur')) {
    return Icons.palette;
  } else if (lowerCategory.contains('sport') ||
      lowerCategory.contains('athlet')) {
    return Icons.sports;
  } else if (lowerCategory.contains('music')) {
    return Icons.music_note;
  } else if (lowerCategory.contains('science')) {
    return Icons.science;
  } else if (lowerCategory.contains('volunteer') ||
      lowerCategory.contains('nonprofit')) {
    return Icons.volunteer_activism;
  } else {
    return Icons.groups;
  }
}

// Provider for events organized by a specific organization
final organizationEventsProvider = FutureProvider.family
    .autoDispose<List<Event>, String>((ref, orgName) async {
  // Get all events
  final events = await ref.watch(eventsProvider.future);

  // Filter events by organizer name
  return events.where((event) => event.organizerName == orgName).toList();
});
