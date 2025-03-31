import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/messaging/injection.dart' as injection;
import 'package:hive_ui/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_ui/theme/app_icons.dart';
import 'package:hive_ui/widgets/hive_app_bar.dart';

class GroupMembersScreen extends ConsumerStatefulWidget {
  final String chatId;

  const GroupMembersScreen({
    Key? key,
    required this.chatId,
  }) : super(key: key);

  @override
  ConsumerState<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends ConsumerState<GroupMembersScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: HiveAppBar(
        title: 'Group Members',
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.person_add,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              // TODO: Implement add member functionality
              // context.pushNamed('add_members', extra: {'chatId': widget.chatId});
            },
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final chatAsync =
              ref.watch(injection.chatDetailsProvider(widget.chatId));

          return chatAsync.when(
            data: (chat) {
              if (chat.participantIds.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.group_off,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No members found',
                        style: GoogleFonts.outfit(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add members to this group',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: chat.participantIds.length,
                itemBuilder: (context, index) {
                  final participantId = chat.participantIds[index];

                  return Card(
                    color: AppColors.cardBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(
                        color: AppColors.cardBorder,
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.cardBackground,
                          border: Border.all(
                            color: AppColors.cardBorder,
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: AppColors.gold,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        participantId, // TODO: Get actual user name
                        style: GoogleFonts.outfit(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          color: AppColors.textPrimary,
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'message',
                            child: Row(
                              children: [
                                const Icon(
                                  AppIcons.message,
                                  color: AppColors.gold,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Message',
                                  style: GoogleFonts.outfit(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (participantId !=
                              FirebaseAuth.instance.currentUser?.uid)
                            PopupMenuItem(
                              value: 'remove',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Remove',
                                    style: GoogleFonts.outfit(
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        onSelected: (value) {
                          if (value == 'message') {
                            // TODO: Navigate to direct message with this user
                          } else if (value == 'remove') {
                            // Show confirmation dialog
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: AppColors.cardBackground,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(
                                    color: AppColors.cardBorder,
                                    width: 1,
                                  ),
                                ),
                                title: Text(
                                  'Remove Member',
                                  style: GoogleFonts.outfit(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                content: Text(
                                  'Are you sure you want to remove this member from the group?',
                                  style: GoogleFonts.inter(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      'Cancel',
                                      style: GoogleFonts.outfit(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      // TODO: Implement remove member functionality
                                    },
                                    child: Text(
                                      'Remove',
                                      style: GoogleFonts.outfit(
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: AppColors.gold,
              ),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading members',
                    style: GoogleFonts.outfit(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
