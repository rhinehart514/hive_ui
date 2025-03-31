import 'package:flutter/material.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

/// A bottom sheet dialog for RSVPing to events with optional comments
class RsvpDialog extends StatefulWidget {
  /// The event being RSVPed to
  final Event event;

  /// Callback when RSVP is submitted
  final Function(String?) onRsvp;

  const RsvpDialog({
    super.key,
    required this.event,
    required this.onRsvp,
  });

  @override
  State<RsvpDialog> createState() => _RsvpDialogState();

  /// Helper to show the dialog as a modal bottom sheet
  static Future<String?> show(
    BuildContext context,
    Event event,
  ) {
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: RsvpDialog(
          event: event,
          onRsvp: (comment) {
            Navigator.pop(context, comment);
          },
        ),
      ),
    );
  }
}

class _RsvpDialogState extends State<RsvpDialog> {
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleRsvp() async {
    setState(() {
      _isLoading = true;
    });

    // Get the comment text
    final comment =
        _commentController.text.isNotEmpty ? _commentController.text : null;

    // Wait a moment to show loading indicator
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      // Call the callback with the comment
      widget.onRsvp(comment);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RSVP to Event',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.event.title,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'by ${widget.event.organizerName}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),

          // Event details summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.gold,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatEventDate(widget.event),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          // Comment field
          TextField(
            controller: _commentController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Add a comment (optional)',
              hintStyle: TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Color(0xFF2A2A2A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.all(16),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleRsvp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.grey,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'RSVP',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Format event date for display
  String _formatEventDate(Event event) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final eventDate = DateTime(
        event.startDate.year, event.startDate.month, event.startDate.day);

    // Format time
    final hour = event.startDate.hour > 12
        ? event.startDate.hour - 12
        : (event.startDate.hour == 0 ? 12 : event.startDate.hour);
    final minute = event.startDate.minute.toString().padLeft(2, '0');
    final period = event.startDate.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour:$minute $period';

    if (eventDate.isAtSameMomentAs(today)) {
      return 'Today at $timeStr';
    } else if (eventDate.isAtSameMomentAs(tomorrow)) {
      return 'Tomorrow at $timeStr';
    } else {
      // Format date
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      final month = months[event.startDate.month - 1];
      final day = event.startDate.day;

      return '$month $day at $timeStr';
    }
  }
}
