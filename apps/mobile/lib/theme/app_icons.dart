import 'package:flutter/material.dart';
import 'package:hive_ui/theme/huge_icons.dart';

/// A centralized class for all application icons
/// Combines Material icons with Hugeicons where appropriate
class AppIcons {
  // Navigation Icons
  static const IconData home = Icons.home_rounded;
  static const IconData back = Icons.arrow_back;
  static const IconData forward = Icons.arrow_forward;
  static const IconData up = Icons.arrow_upward;
  static const IconData down = Icons.arrow_downward;

  // Messaging Icons - Using Material icons for compatibility
  static const IconData message = HugeIcons.strokeRoundedMessageLock01;
  static const IconData messageSend = Icons.send;
  static const IconData messageThread = Icons.forum;
  static const IconData messageReply = Icons.reply;
  static const IconData messageSearch = Icons.search;
  static const IconData messageAdd = Icons.add_box;
  static const IconData messageAttachment = Icons.attachment;
  static const IconData messageFile = Icons.insert_drive_file;
  static const IconData messageVoice = Icons.mic;
  static const IconData messagePinned = Icons.push_pin;

  // Hugeicons constants - Updated to use IconData
  static const IconData hugeMessage = HugeIcons.strokeRoundedMessageLock01;
  static const IconData hugeMessageSearch = HugeIcons.search;
  static const IconData hugeSettings = HugeIcons.settings;
  static const IconData hugeUser = HugeIcons.user;

  // Action Icons
  static const IconData close = Icons.close;
  static const IconData plusCircle = Icons.add_circle;
  static const IconData camera = Icons.camera_alt;

  // Common UI Icons
  static const IconData settings = Icons.settings_outlined;
  static const IconData notification = Icons.notifications;
  static const IconData bookmark = Icons.bookmark_border;
  static const IconData save = Icons.save;
  static const IconData share = Icons.share;
  static const IconData edit = Icons.edit;
  static const IconData delete = Icons.delete;
  static const IconData more = Icons.more_horiz;
  static const IconData info = Icons.info;
  static const IconData warning = Icons.warning;
  static const IconData success = Icons.check_circle;
  static const IconData error = Icons.error;

  // Media Icons
  static const IconData image = Icons.image;
  static const IconData video = Icons.videocam;
  static const IconData audio = Icons.headphones;
  static const IconData document = Icons.description;

  // User Icons
  static const IconData user = Icons.person;
  static const IconData userGroup = Icons.group;
  static const IconData addUser = Icons.person_add;
  static const IconData removeUser = Icons.person_remove;

  // Call Icons
  static const IconData call = Icons.call;
  static const IconData videoCall = Icons.videocam;
  static const IconData callEnd = Icons.call_end;
  static const IconData callMute = Icons.mic_off;

  // Location Icons
  static const IconData location = Icons.location_on;
  static const IconData map = Icons.map;
  static const IconData navigation = Icons.navigation;

  // Misc Icons
  static const IconData calendar = Icons.calendar_today;
  static const IconData clock = Icons.access_time;
  static const IconData lock = Icons.lock;
  static const IconData unlock = Icons.lock_open;
  static const IconData star = Icons.star_border;
  static const IconData flag = Icons.flag;
  static const IconData link = Icons.link;
  static const IconData filter = Icons.filter_list;
  static const IconData sort = Icons.sort;
}
