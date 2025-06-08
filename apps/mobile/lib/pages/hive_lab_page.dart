import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:auto_route/auto_route.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_theme.dart';
import 'package:hive_ui/components/buttons.dart';
import 'package:hive_ui/extensions/glassmorphism_extension.dart';
import 'package:hive_ui/theme/glassmorphism_guide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@RoutePage()
class HiveLabPage extends ConsumerStatefulWidget {
  const HiveLabPage({super.key});

  @override
  ConsumerState<HiveLabPage> createState() => _HiveLabPageState();
}

class _HiveLabPageState extends ConsumerState<HiveLabPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _ideaController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int? _selectedPollOption;
  bool _hasSubmittedIdea = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    // Start the entrance animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _ideaController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _submitIdea() {
    if (_ideaController.text.trim().isEmpty) return;

    // Provide haptic feedback
    HapticFeedback.mediumImpact();

    // In a real app, this would send the idea to a backend
    // For MVP, just show success toast and clear input
    setState(() {
      _hasSubmittedIdea = true;
    });

    // Clear the text field
    _ideaController.clear();

    // Hide success message after a delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _hasSubmittedIdea = false;
        });
      }
    });
  }

  void _votePoll(int option) {
    // Provide haptic feedback
    HapticFeedback.selectionClick();

    // Update selected option
    setState(() {
      _selectedPollOption = option;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            color: AppColors.gold,
            backgroundColor: AppColors.black.withOpacity(0.8),
            onRefresh: () async {
              // Simulate refresh
              HapticFeedback.mediumImpact();
              await Future.delayed(const Duration(seconds: 1));
              // In a real app, this would refresh the data
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // App Bar
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  expandedHeight: 180,
                  pinned: true,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white),
                    onPressed: () => context.router.pop(),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background with gradient
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.black,
                                AppColors.black.withOpacity(0.8),
                                AppColors.gold.withOpacity(0.1),
                              ],
                            ),
                          ),
                        ),

                        // Semi-transparent beaker image (right side)
                        Positioned(
                          right: -20,
                          bottom: 0,
                          child: Opacity(
                            opacity: 0.2,
                            child: Image.asset(
                              'assets/images/hivebeaker.png',
                              height: 140,
                            ),
                          ),
                        ),

                        // Title and subtitle
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.rocket_launch,
                                    color: AppColors.gold,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Welcome to HiveLab',
                                    style: AppTheme.displaySmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Help Shape HIVE!',
                                style: AppTheme.displaySmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Submit ideas, vote on features, and see what\'s coming next.',
                                style: AppTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),

                        // Gradient overlay at the bottom for smooth transition
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 40,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.transparent,
                                  AppColors.black,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Content sections
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section 1: What's Coming (Roadmap Preview)
                        _buildSectionHeader(
                          icon: Icons.timeline,
                          title: "What's Coming",
                        ),
                        const SizedBox(height: 16),
                        _buildRoadmapCards(),

                        const SizedBox(height: 32),

                        // Section 2: Submit an Idea
                        _buildSectionHeader(
                          icon: Icons.lightbulb_outline,
                          title: "Submit an Idea",
                        ),
                        const SizedBox(height: 16),
                        _buildIdeaSubmission(),

                        const SizedBox(height: 32),

                        // Section 3: Community Feedback & Polls
                        _buildSectionHeader(
                          icon: Icons.poll_outlined,
                          title: "Community Feedback",
                        ),
                        const SizedBox(height: 16),
                        _buildCurrentPoll(),

                        // Bottom spacing
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.gold, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTheme.displaySmall,
        ),
      ],
    );
  }

  Widget _buildRoadmapCards() {
    // Sample roadmap items - in a real app, these would come from a provider
    final roadmapItems = [
      {
        'title': 'Spaces 2.0 – Custom Student Groups',
        'status': 'Planned',
        'statusColor': AppColors.gold.withOpacity(0.7),
        'description':
            'Create your own custom space types with granular permissions.',
      },
      {
        'title': 'Event RSVP Boosting',
        'status': 'In Progress',
        'statusColor': AppColors.gold,
        'description':
            'Increase event visibility and attendance with smart RSVP features.',
      },
      {
        'title': 'Dark Mode Enhancements',
        'status': 'Released',
        'statusColor': AppColors.gold.withOpacity(0.5),
        'description': 'Improved contrast and new theme customization options.',
      },
    ];

    return Column(
      children: roadmapItems
          .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildRoadmapCard(
                  title: item['title'] as String,
                  status: item['status'] as String,
                  statusColor: item['statusColor'] as Color,
                  description: item['description'] as String,
                ),
              ))
          .toList(),
    );
  }

  Widget _buildRoadmapCard({
    required String title,
    required String status,
    required Color statusColor,
    required String description,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusMd),
        border: Border.all(
          color: AppColors.cardBorder,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusMd),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status badge and title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status pill
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      status,
                      style: AppTheme.bodyMedium.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title
                  Expanded(
                    child: Text(
                      title,
                      style: AppTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Description
              Text(
                description,
                style: AppTheme.bodyMedium,
              ),
            ],
          ),
        ).addGlassmorphism(
          blur: GlassmorphismGuide.kCardBlur,
          opacity: GlassmorphismGuide.kCardGlassOpacity / 1.5,
          borderRadius: GlassmorphismGuide.kRadiusMd,
        ),
      ),
    );
  }

  Widget _buildIdeaSubmission() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusMd),
        border: Border.all(
          color: AppColors.cardBorder,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusMd),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text field for idea submission
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground.withOpacity(0.3),
                  borderRadius:
                      BorderRadius.circular(GlassmorphismGuide.kRadiusSm),
                  border: Border.all(
                    color: AppColors.cardBorder,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _ideaController,
                  maxLines: 5,
                  maxLength: 200,
                  style: AppTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Share your ideas for improving HIVE...',
                    hintStyle: AppTheme.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                    border: InputBorder.none,
                    counterStyle: AppTheme.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Success message or submit button
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _hasSubmittedIdea
                    ? Container(
                        key: const ValueKey('success'),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.success.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Thank you for your suggestion! Our team will review it.',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Row(
                        key: const ValueKey('submit'),
                        children: [
                          Expanded(
                            child: Text(
                              'Your feedback directly influences our roadmap and development priorities.',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          HiveButton(
                            text: 'Submit',
                            onPressed: _submitIdea,
                            variant: HiveButtonVariant.primary,
                            size: HiveButtonSize.medium,
                            icon: Icons.send,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ).addGlassmorphism(
          blur: GlassmorphismGuide.kCardBlur,
          opacity: GlassmorphismGuide.kCardGlassOpacity / 1.5,
          borderRadius: GlassmorphismGuide.kRadiusMd,
        ),
      ),
    );
  }

  Widget _buildCurrentPoll() {
    // Sample poll question - in a real app, this would come from a provider
    const pollQuestion = "Should we add Space Categories?";
    final pollOptions = [
      {"emoji": "👍", "text": "Yes", "votes": 75},
      {"emoji": "🤷", "text": "Maybe", "votes": 15},
      {"emoji": "👎", "text": "No", "votes": 10},
    ];

    // Calculate total votes for percentages
    final totalVotes =
        pollOptions.fold(0, (sum, option) => sum + (option["votes"] as int)) +
            (_selectedPollOption != null ? 1 : 0);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusMd),
        border: Border.all(
          color: AppColors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusMd),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poll question
              Text(
                pollQuestion,
                style: AppTheme.displaySmall,
              ),
              const SizedBox(height: 16),

              // Poll options
              for (int i = 0; i < pollOptions.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildPollOption(
                    emoji: pollOptions[i]["emoji"] as String,
                    text: pollOptions[i]["text"] as String,
                    votes: pollOptions[i]["votes"] as int,
                    isSelected: _selectedPollOption == i,
                    showResults: _selectedPollOption != null,
                    percentage: totalVotes > 0
                        ? (pollOptions[i]["votes"] as int) / totalVotes * 100
                        : 0,
                    onTap: () => _votePoll(i),
                  ),
                ),

              // Poll status info
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _selectedPollOption != null
                      ? '$totalVotes total votes'
                      : 'Vote to see results',
                  style: AppTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ).addGlassmorphism(
          blur: GlassmorphismGuide.kCardBlur,
          opacity: GlassmorphismGuide.kCardGlassOpacity / 1.5,
          borderRadius: GlassmorphismGuide.kRadiusMd,
        ),
      ),
    );
  }

  Widget _buildPollOption({
    required String emoji,
    required String text,
    required int votes,
    required bool isSelected,
    required bool showResults,
    required double percentage,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _selectedPollOption == null ? onTap : null,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusSm),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Progress bar background
            if (showResults)
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: percentage),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutQuart,
                  builder: (context, value, child) {
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: value / 100,
                      child: Container(
                        color: isSelected
                            ? AppColors.gold.withOpacity(0.2)
                            : AppColors.cardBackground.withOpacity(0.3),
                      ),
                    );
                  },
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Emoji indicator
                  Text(
                    emoji,
                    style: AppTheme.bodyLarge,
                  ),
                  const SizedBox(width: 8),
                  // Option text
                  Expanded(
                    child: Text(
                      text,
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Vote count
                  if (showResults)
                    Text(
                      '${percentage.round()}%',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected ? AppColors.gold : AppColors.textPrimary,
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

  Widget _buildFeatureCard({
    required String title,
    required String description,
    required IconData icon,
    required String status,
    required VoidCallback onTap,
  }) {
    final statusColors = {
      'Live': AppColors.success,
      'Coming Soon': AppColors.gold,
      'In Development': AppColors.warning,
      'Under Review': AppColors.textTertiary,
    };

    final statusColor = statusColors[status] ?? AppColors.textTertiary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Feature icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.gold,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Title and description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: AppTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Status bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    status,
                    style: AppTheme.bodySmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward,
                    color: statusColor,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
