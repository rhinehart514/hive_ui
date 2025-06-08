/// HIVE Card Usage Examples
/// 
/// Demonstrates the locked-in card variants based on design system validation

import 'package:flutter/material.dart';
import 'hive_card.dart';

class HiveCardExamples extends StatelessWidget {
  const HiveCardExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('HiveCard Examples'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LOCKED VARIANTS ✅',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Primary card - Sophisticated Depth
            HiveCard.sophisticatedDepth(
              onTap: () => _showDemo(context, 'Sophisticated Depth'),
              child: const HiveCardContent(
                title: 'Sophisticated Depth',
                subtitle: 'Primary card with deep shadows and premium feel',
                leading: Icon(Icons.star, color: Color(0xFFFFD700)),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Minimalist flat for pressed states
            HiveCard.minimalistFlat(
              onTap: () => _showDemo(context, 'Minimalist Flat'),
              child: const HiveCardContent(
                title: 'Minimalist Flat',
                subtitle: 'Clean flat surface for pressed/active states',
                leading: Icon(Icons.check_circle, color: Color(0xFF8CE563)),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Frosted glass treatment
            HiveCardWithBackdrop(
              onTap: () => _showDemo(context, 'Frosted Glass'),
              child: const HiveCardContent(
                title: 'Frosted Glass',
                subtitle: 'Premium glass effect with backdrop blur',
                leading: Icon(Icons.blur_on, color: Color(0xFF56CCF2)),
              ),
            ),
            
            const SizedBox(height: 32),
            
            const Text(
              'RESPONSIVE GRID',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Responsive grid example
            const Expanded(
              child: HiveCardGrid(
                cards: [
                  HiveCard.sophisticatedDepth(
                    child: HiveCardContent(
                      title: 'Event 1',
                      subtitle: 'Mobile: 1 col, Tablet: 3 cols, Desktop: 4 cols',
                    ),
                  ),
                  HiveCard.sophisticatedDepth(
                    child: HiveCardContent(
                      title: 'Event 2',
                      subtitle: 'Automatic responsive layout',
                    ),
                  ),
                  HiveCard.sophisticatedDepth(
                    child: HiveCardContent(
                      title: 'Event 3',
                      subtitle: 'Standard spacing hierarchy',
                    ),
                  ),
                  HiveCard.sophisticatedDepth(
                    child: HiveCardContent(
                      title: 'Event 4',
                      subtitle: '2% grain texture overlay',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDemo(BuildContext context, String cardType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$cardType card tapped'),
        backgroundColor: const Color(0xFF56CCF2),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

/// Quick helper for building card content with icons
class HiveEventCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final int attendees;
  final VoidCallback? onTap;

  const HiveEventCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.attendees,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return HiveCard.sophisticatedDepth(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HiveCardContent(
            title: title,
            subtitle: subtitle,
            trailing: Text(
              time,
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.people,
                color: Color(0xFF56CCF2),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '$attendees attending',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 