import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../theme/app_colors.dart';

/// A component that displays the event description
class EventDescriptionSection extends StatefulWidget {
  /// The event to display the description for
  final Event event;

  /// Animation controller for entrance animation
  final AnimationController animationController;

  /// Constructor
  const EventDescriptionSection({
    Key? key,
    required this.event,
    required this.animationController,
  }) : super(key: key);

  @override
  State<EventDescriptionSection> createState() =>
      _EventDescriptionSectionState();
}

class _EventDescriptionSectionState extends State<EventDescriptionSection> {
  late String _description;

  @override
  void initState() {
    super.initState();
    _description = widget.event.description;

    // Clean up description for better display
    if (_description.isEmpty) {
      _description = 'No description available for this event.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: widget.animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: widget.animationController,
          curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
        )),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description title
              const Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    color: AppColors.white,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Description',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Description text - always show full text
              Text(
                _description,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
