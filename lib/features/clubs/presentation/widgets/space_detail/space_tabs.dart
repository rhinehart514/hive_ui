import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A tabbed navigation widget for the space detail screen
class SpaceTabs extends StatelessWidget {
  final TabController tabController;
  final List<String> tabs;
  final List<Widget> tabViews;
  final Function(int)? onTabChanged;
  
  const SpaceTabs({
    Key? key,
    required this.tabController,
    required this.tabs,
    required this.tabViews,
    this.onTabChanged,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Bar
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            border: Border(
              bottom: BorderSide(
                color: AppColors.divider,
                width: 1,
              ),
            ),
          ),
          child: TabBar(
            controller: tabController,
            onTap: (index) {
              HapticFeedback.selectionClick();
              if (onTabChanged != null) {
                onTabChanged!(index);
              }
            },
            indicatorColor: AppColors.gold,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: AppColors.gold,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
            tabs: tabs.map((tab) => Tab(text: tab)).toList(),
          ),
        ),
        
        // Tab Views
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: tabViews,
          ),
        ),
      ],
    );
  }
} 