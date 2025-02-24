import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

// Model class for an event item from RSS feed
class EventItem {
  final String title;
  final String link;
  final String pubDate;
  final String description;

  EventItem({
    required this.title,
    required this.link,
    required this.pubDate,
    required this.description,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<List<EventItem>>? _futureEvents;

  @override
  void initState() {
    super.initState();
    _futureEvents = _fetchEvents();
  }

  Future<void> _refreshEvents() async {
    setState(() {
      _futureEvents = _fetchEvents();
    });
  }

  Future<List<EventItem>> _fetchEvents() async {
    const String rssUrl = 'https://buffalo.campuslabs.com/engage/events.rss';
    final response = await http.get(Uri.parse(rssUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to load RSS feed');
    }
    final document = xml.XmlDocument.parse(response.body);
    final items = document.findAllElements('item');
    return items.map((node) {
      final title = node.findElements('title').isNotEmpty ? node.findElements('title').first.text : 'No Title';
      final link = node.findElements('link').isNotEmpty ? node.findElements('link').first.text : '';
      final pubDate = node.findElements('pubDate').isNotEmpty ? node.findElements('pubDate').first.text : '';
      final description = node.findElements('description').isNotEmpty ? node.findElements('description').first.text : '';
      return EventItem(title: title, link: link, pubDate: pubDate, description: description);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: RefreshIndicator(
        onRefresh: _refreshEvents,
        child: CustomScrollView(
          slivers: [
            _buildHeader(),
            SliverToBoxAdapter(
              child: FutureBuilder<List<EventItem>>(
                future: _futureEvents,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppTheme.spacing24),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: AppTheme.bodyLarge));
                  }
                  final events = snapshot.data ?? [];
                  if (events.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(AppTheme.spacing24),
                      child: Center(
                        child: Text('No events available', style: AppTheme.bodyLarge.copyWith(color: AppColors.textTertiary)),
                      ),
                    );
                  }
                  return ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      return _buildEventCard(events[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.black,
      flexibleSpace: FlexibleSpaceBar(
        title: Text('Campus Events', style: AppTheme.displaySmall),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/hivelogo.png',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, AppColors.black.withOpacity(0.9)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(EventItem event) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24, vertical: AppTheme.spacing12),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tapped on event: ${event.title}')),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: AppTheme.displayMedium),
                const SizedBox(height: AppTheme.spacing8),
                Text(event.pubDate, style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: AppTheme.spacing12),
                Text(
                  event.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyLarge,
                ),
                const SizedBox(height: AppTheme.spacing12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Read More', style: AppTheme.labelMedium.copyWith(color: AppColors.gold)),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.gold),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 