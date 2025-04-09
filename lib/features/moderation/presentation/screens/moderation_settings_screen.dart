import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/section_header.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/common/glass_container.dart';

class ModerationSettingsScreen extends ConsumerStatefulWidget {
  const ModerationSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ModerationSettingsScreen> createState() => _ModerationSettingsScreenState();
}

class _ModerationSettingsScreenState extends ConsumerState<ModerationSettingsScreen> {
  // Placeholder settings
  bool _enableAutoModeration = true;
  bool _notifyModerators = true;
  bool _archiveRemovedContent = true;
  double _spamThreshold = 0.7;
  double _toxicityThreshold = 0.8;
  int _requiredReportsForReview = 3;
  final List<String> _bannedWords = ['example', 'inappropriate', 'banned'];
  final TextEditingController _bannedWordController = TextEditingController();

  @override
  void dispose() {
    _bannedWordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moderation Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Auto-moderation section
            const SectionHeader(
              title: 'Automatic Moderation',
              subtitle: 'Configure how content is automatically moderated',
              icon: Icons.auto_fix_high,
            ),
            const SizedBox(height: 16),
            GlassContainer(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Enable Auto-Moderation', 
                        style: TextStyle(color: Colors.white)),
                      subtitle: const Text(
                        'Automatically detect and filter problematic content',
                        style: TextStyle(color: Colors.white70),
                      ),
                      value: _enableAutoModeration,
                      onChanged: (value) {
                        setState(() {
                          _enableAutoModeration = value;
                        });
                      },
                      activeColor: AppColors.gold,
                    ),
                    if (_enableAutoModeration) ...[
                      const Divider(height: 32, color: Colors.white24),
                      ListTile(
                        title: const Text('Spam Detection Threshold', 
                          style: TextStyle(color: Colors.white)),
                        subtitle: Text(
                          'Current: ${(_spamThreshold * 100).toInt()}%',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: SizedBox(
                          width: 180,
                          child: Slider(
                            value: _spamThreshold,
                            min: 0.5,
                            max: 0.95,
                            divisions: 9,
                            label: '${(_spamThreshold * 100).toInt()}%',
                            activeColor: AppColors.gold,
                            onChanged: (value) {
                              setState(() {
                                _spamThreshold = value;
                              });
                            },
                          ),
                        ),
                      ),
                      ListTile(
                        title: const Text('Toxicity Threshold', 
                          style: TextStyle(color: Colors.white)),
                        subtitle: Text(
                          'Current: ${(_toxicityThreshold * 100).toInt()}%',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: SizedBox(
                          width: 180,
                          child: Slider(
                            value: _toxicityThreshold,
                            min: 0.5,
                            max: 0.95,
                            divisions: 9,
                            label: '${(_toxicityThreshold * 100).toInt()}%',
                            activeColor: AppColors.gold,
                            onChanged: (value) {
                              setState(() {
                                _toxicityThreshold = value;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Word Filters
            const SectionHeader(
              title: 'Content Filters',
              subtitle: 'Configure banned words and phrases',
              icon: Icons.filter_list,
            ),
            const SizedBox(height: 16),
            GlassContainer(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _bannedWordController,
                            decoration: const InputDecoration(
                              hintText: 'Add a banned word or phrase',
                              hintStyle: TextStyle(color: Colors.white54),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, 
                                vertical: 12,
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: AppColors.gold),
                          onPressed: () {
                            final word = _bannedWordController.text.trim();
                            if (word.isNotEmpty && !_bannedWords.contains(word)) {
                              setState(() {
                                _bannedWords.add(word);
                                _bannedWordController.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Banned Words & Phrases:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _bannedWords.map((word) {
                        return Chip(
                          label: Text(word),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            setState(() {
                              _bannedWords.remove(word);
                            });
                          },
                          backgroundColor: Colors.red.withOpacity(0.2),
                          labelStyle: const TextStyle(color: Colors.white),
                          side: BorderSide(color: Colors.red.withOpacity(0.3)),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Workflow Settings
            const SectionHeader(
              title: 'Moderation Workflow',
              subtitle: 'Configure how reports are handled',
              icon: Icons.schema,
            ),
            const SizedBox(height: 16),
            GlassContainer(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text(
                        'Reports Required for Review',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Content will be flagged for review after $_requiredReportsForReview reports',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.white70),
                            onPressed: _requiredReportsForReview > 1 ? () {
                              setState(() {
                                _requiredReportsForReview--;
                              });
                            } : null,
                          ),
                          Text(
                            '$_requiredReportsForReview',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Colors.white70),
                            onPressed: _requiredReportsForReview < 10 ? () {
                              setState(() {
                                _requiredReportsForReview++;
                              });
                            } : null,
                          ),
                        ],
                      ),
                    ),
                    SwitchListTile(
                      title: const Text(
                        'Notify Moderators',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'Send notifications to moderators when content is reported',
                        style: TextStyle(color: Colors.white70),
                      ),
                      value: _notifyModerators,
                      onChanged: (value) {
                        setState(() {
                          _notifyModerators = value;
                        });
                      },
                      activeColor: AppColors.gold,
                    ),
                    SwitchListTile(
                      title: const Text(
                        'Archive Removed Content',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'Keep removed content in archive for review purposes',
                        style: TextStyle(color: Colors.white70),
                      ),
                      value: _archiveRemovedContent,
                      onChanged: (value) {
                        setState(() {
                          _archiveRemovedContent = value;
                        });
                      },
                      activeColor: AppColors.gold,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Save button
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Save Settings'),
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _saveSettings() {
    // In a real implementation, this would save the settings
    // using the ManageModerationSettingsUseCase
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
} 