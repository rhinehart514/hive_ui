import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart' as hugeicons_pkg;

/// A constant class for Hugeicons identifiers
/// This class serves as a centralized place for all Hugeicons
class HugeIcons {
  HugeIcons._();

  // Basic UI
  static const IconData home = hugeicons_pkg.HugeIcons.strokeRoundedHome01;
  static const IconData message =
      hugeicons_pkg.HugeIcons.strokeRoundedMessageLock01;
  static const IconData settings =
      hugeicons_pkg.HugeIcons.strokeRoundedSettings01;
  static const IconData profile = hugeicons_pkg.HugeIcons.strokeRoundedProfile;
  static const IconData chat =
      hugeicons_pkg.HugeIcons.strokeRoundedMessageLock01;
  static const IconData search = hugeicons_pkg.HugeIcons.strokeRoundedSearch01;
  static const IconData rocket = hugeicons_pkg.HugeIcons.strokeRoundedRocket;
  static const IconData user = hugeicons_pkg.HugeIcons.strokeRoundedUser;
  static const IconData constellation =
      hugeicons_pkg.HugeIcons.strokeRoundedConstellation;
  static const IconData party =
      hugeicons_pkg.HugeIcons.strokeRoundedConstellation;
  static const IconData add = hugeicons_pkg.HugeIcons.strokeRoundedAdd01;
  static const IconData calendar =
      hugeicons_pkg.HugeIcons.strokeRoundedCalendar01;
  static const IconData repost = Icons.repeat_rounded;

  // New icons added - profile and settings
  static const IconData pencilEdit =
      hugeicons_pkg.HugeIcons.strokeRoundedPencilEdit01;
  static const IconData share = hugeicons_pkg.HugeIcons.strokeRoundedShare05;
  static const IconData settingsAdvanced =
      hugeicons_pkg.HugeIcons.strokeRoundedSetting07;
  static const IconData tag = hugeicons_pkg.HugeIcons.strokeRoundedTag01;

  // Messaging icons
  static const IconData strokeRoundedMessageLock01 =
      hugeicons_pkg.HugeIcons.strokeRoundedMessageLock01;

  // Education and profile icons
  static const IconData strokeRoundedMortarboard02 =
      hugeicons_pkg.HugeIcons.strokeRoundedMortarboard02;
  static const IconData strokeRoundedBook02 =
      hugeicons_pkg.HugeIcons.strokeRoundedBook02;
  static const IconData strokeRoundedHouse03 =
      hugeicons_pkg.HugeIcons.strokeRoundedHouse03;

  // Greek life and user group icons
  static const IconData strokeRoundedAlphabetGreek =
      hugeicons_pkg.HugeIcons.strokeRoundedAlphabetGreek;
  static const IconData strokeRoundedUserGroup03 =
      hugeicons_pkg.HugeIcons.strokeRoundedUserGroup03;

  // Custom names (using known valid icons to avoid linter errors)
  static const IconData spaces = hugeicons_pkg.HugeIcons.strokeRoundedHome01;
  static const IconData groups = hugeicons_pkg.HugeIcons.strokeRoundedProfile;
  static const IconData business = hugeicons_pkg.HugeIcons.strokeRoundedHome01;
  static const IconData academic =
      hugeicons_pkg.HugeIcons.strokeRoundedCalendar01;
  static const IconData clock = hugeicons_pkg.HugeIcons.strokeRoundedCalendar01;
  static const IconData lock = hugeicons_pkg.HugeIcons.strokeRoundedProfile;
  static const IconData government =
      hugeicons_pkg.HugeIcons.strokeRoundedHome01;
  static const IconData people = hugeicons_pkg.HugeIcons.strokeRoundedProfile;
  static const IconData image = hugeicons_pkg.HugeIcons.strokeRoundedSearch01;
  static const IconData check = hugeicons_pkg.HugeIcons.strokeRoundedSearch01;
  static const IconData strokeRoundedTick01 = hugeicons_pkg.HugeIcons.strokeRoundedTick01;
  static const IconData strokeRoundedHexagon01 = hugeicons_pkg.HugeIcons.strokeRoundedHexagon01;

  // Achievement and rewards
  static const IconData crown =
      Icons.military_tech; // Using Material Icon as fallback

  static const IconData strokeRoundedPlusSignCircle =
      hugeicons_pkg.HugeIcons.strokeRoundedPlusSignCircle;
}

/// A widget to display Hugeicons with customizable properties
class HugeIcon extends StatelessWidget {
  final IconData icon; // Using IconData for type safety
  final double size;
  final Color? color;

  const HugeIcon({
    super.key,
    required this.icon,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: color,
    );
  }
}
