import 'package:flutter/material.dart';
import 'package:hive_ui/components/card_lifecycle.dart';
import 'package:hive_ui/components/card_lifecycle_wrapper.dart';
import 'package:hive_ui/components/hive_card.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A demo page showcasing the card lifecycle visualization
class CardLifecycleDemoPage extends StatefulWidget {
  /// Route name for navigation
  static const routeName = '/examples/card-lifecycle';
  
  /// Constructor
  const CardLifecycleDemoPage({Key? key}) : super(key: key);

  @override
  State<CardLifecycleDemoPage> createState() => _CardLifecycleDemoPageState();
}

class _CardLifecycleDemoPageState extends State<CardLifecycleDemoPage> {
  // Sample content creation dates
  final _now = DateTime.now();
  late final Map<CardLifecycleState, DateTime> _sampleDates;
  
  // Toggle for showing indicators
  bool _showIndicators = true;
  
  // Toggle for auto-aging
  bool _useAutoAging = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize sample dates for different states
    _sampleDates = {
      CardLifecycleState.fresh: _now.subtract(const Duration(hours: 2)),
      CardLifecycleState.aging: _now.subtract(const Duration(days: 2)),
      CardLifecycleState.old: _now.subtract(const Duration(days: 5)),
      CardLifecycleState.archived: _now.subtract(const Duration(days: 10)),
    };
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Card Lifecycle Visualization'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(
              _showIndicators ? Icons.visibility : Icons.visibility_off,
              color: AppColors.gold,
            ),
            onPressed: () {
              setState(() {
                _showIndicators = !_showIndicators;
              });
            },
            tooltip: 'Toggle state indicators',
          ),
          IconButton(
            icon: Icon(
              _useAutoAging ? Icons.access_time : Icons.access_time_outlined,
              color: AppColors.gold,
            ),
            onPressed: () {
              setState(() {
                _useAutoAging = !_useAutoAging;
              });
            },
            tooltip: 'Toggle auto aging',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SectionHeader('Card Lifecycle States'),
            
            // Display all lifecycle states
            ...CardLifecycleState.values.map(
              (state) => _buildStateExample(state),
            ),
            
            const SizedBox(height: 24),
            const _SectionHeader('Real-World Examples'),
            
            // Fresh content example - Shiny, full opacity
            _buildRealWorldExample(
              title: 'Just Posted',
              subtitle: 'New event coming up tomorrow',
              state: CardLifecycleState.fresh,
              date: _now.subtract(const Duration(hours: 1)),
            ),
            
            // Aging content example - Slight desaturation
            _buildRealWorldExample(
              title: 'Three Days Old',
              subtitle: 'Check out this interesting post',
              state: CardLifecycleState.aging,
              date: _now.subtract(const Duration(days: 3)),
            ),
            
            // Old content example - More desaturation, lower opacity
            _buildRealWorldExample(
              title: 'Last Week',
              subtitle: 'Content from a while back',
              state: CardLifecycleState.old,
              date: _now.subtract(const Duration(days: 6)),
            ),
            
            // Archived content example - Heavy desaturation, lowest opacity
            _buildRealWorldExample(
              title: 'Archived Content',
              subtitle: 'Historical content from the archives',
              state: CardLifecycleState.archived,
              date: _now.subtract(const Duration(days: 14)),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build an example card for a specific lifecycle state
  Widget _buildStateExample(CardLifecycleState state) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              state.displayName,
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          HiveCard(
            style: HiveCardStyle.standard,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Card in ${state.displayName} State',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.description,
                    style: const TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _useAutoAging
                        ? 'Created: ${_formatDate(_sampleDates[state]!)}'
                        : 'State: ${state.displayName}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ).withLifecycle(
            createdAt: _sampleDates[state]!,
            state: _useAutoAging ? CardLifecycleState.fresh : state,
            autoAge: _useAutoAging,
            showIndicator: _showIndicators,
          ),
        ],
      ),
    );
  }
  
  /// Build a real-world example card with the lifecycle visualization
  Widget _buildRealWorldExample({
    required String title,
    required String subtitle,
    required CardLifecycleState state,
    required DateTime date,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: HiveCard(
        style: HiveCardStyle.elevated,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card header
            Container(
              height: 120,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1A1A1A), // Dark gradient start
                    Color(0xFF2A2A2A), // Dark gradient end
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  _getIconForState(state),
                  size: 48,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
            
            // Card content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(date),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).withLifecycle(
        createdAt: date,
        state: _useAutoAging ? CardLifecycleState.fresh : state,
        autoAge: _useAutoAging,
        showIndicator: _showIndicators,
      ),
    );
  }
  
  /// Format a date as a relative string
  String _formatDate(DateTime date) {
    final difference = _now.difference(date);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${(difference.inDays / 30).floor()} months ago';
    }
  }
  
  /// Get an icon for a specific state
  IconData _getIconForState(CardLifecycleState state) {
    switch (state) {
      case CardLifecycleState.fresh:
        return Icons.new_releases;
      case CardLifecycleState.aging:
        return Icons.access_time;
      case CardLifecycleState.old:
        return Icons.history;
      case CardLifecycleState.archived:
        return Icons.archive;
    }
  }
}

/// A simple section header widget
class _SectionHeader extends StatelessWidget {
  final String title;
  
  const _SectionHeader(this.title);
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.gold,
        ),
      ),
    );
  }
} 