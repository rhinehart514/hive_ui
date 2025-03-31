import 'package:flutter/material.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A SliverPersistentHeaderDelegate implementation for the profile page tab bar.
/// This creates a sticky header effect for the tabs.
class ProfileAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  ProfileAppBarDelegate(this.tabBar);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.black,
        border: Border(
          bottom: BorderSide(
            color: Colors.white10,
            width: 0.5,
          ),
        ),
      ),
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(ProfileAppBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
