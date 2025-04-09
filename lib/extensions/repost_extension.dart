import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/repost_content_type.dart';
import '../theme/app_colors.dart';

/// Extension on BuildContext for displaying repost options
extension RepostExtension on BuildContext {
  /// Shows repost options for an event
  void showRepostOptions({
    required Event event,
    required Function(Event, String?, RepostContentType) onRepostSelected,
    bool followsClub = false,
    int todayBoosts = 0,
  }) {
    showModalBottomSheet(
      context: this,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _SimpleRepostOptions(
          event: event,
          onRepostSelected: onRepostSelected,
          followsClub: followsClub,
          todayBoosts: todayBoosts,
        );
      },
    );
  }
}

/// A simplified version of the repost options
class _SimpleRepostOptions extends StatefulWidget {
  final Event event;
  final Function(Event, String?, RepostContentType) onRepostSelected;
  final bool followsClub;
  final int todayBoosts;

  const _SimpleRepostOptions({
    Key? key,
    required this.event,
    required this.onRepostSelected,
    this.followsClub = false,
    this.todayBoosts = 0,
  }) : super(key: key);

  @override
  State<_SimpleRepostOptions> createState() => _SimpleRepostOptionsState();
}

class _SimpleRepostOptionsState extends State<_SimpleRepostOptions> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share Event',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Repost options
            _buildRepostOption(
              icon: Icons.repeat,
              title: 'Repost',
              description: 'Share this event with your followers',
              type: RepostContentType.standard,
            ),
            
            _buildRepostOption(
              icon: Icons.format_quote,
              title: 'Quote',
              description: 'Add your thoughts when sharing',
              type: RepostContentType.quote,
            ),
            
            _buildRepostOption(
              icon: Icons.star_rate,
              title: 'Highlight',
              description: 'Highlight and feature this event',
              type: RepostContentType.highlight,
            ),
            
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRepostOption({
    required IconData icon,
    required String title,
    required String description,
    required RepostContentType type,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : () => _handleSelectRepost(type),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: type.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  color: type.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _handleSelectRepost(RepostContentType type) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // For quote type, we'd typically navigate to another page for input
      // For this simple implementation, we'll just handle the basic types
      if (type == RepostContentType.quote) {
        // We could navigate to a page for quote input
        Navigator.of(context).pop(); // Just close for now
        return;
      }
      
      // Call the callback with no comment text for basic types
      await widget.onRepostSelected(widget.event, null, type);
      
      // Close the bottom sheet
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error reposting: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to repost: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 