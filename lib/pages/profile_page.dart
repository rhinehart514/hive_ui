import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  bool _isFollowing = false;
  String _userName = 'Jacob Rhinehart';
  // Default selected badges
  final Map<String, String> _selectedBadges = {
    'Major': 'Computer Science',
    'Year': 'Junior',
    'Residence': 'Greiner',
  };

  final List<BadgeOption> _badgeOptions = [
    BadgeOption(
      name: 'Major',
      icon: 'assets/images/books.png',
      options: ['Computer Science', 'Engineering', 'Business', 'Arts', 'Entrepreneur'],
    ),
    BadgeOption(
      name: 'Year',
      icon: 'assets/images/year.png',
      options: ['Freshman', 'Sophomore', 'Junior', 'Senior', 'Graduate'],
    ),
    BadgeOption(
      name: 'Residence',
      icon: 'assets/images/whereyoulive.png',
      options: ['Greiner', 'Ellicott', 'Governors', 'South Lake', 'Off Campus'],
    ),
  ];

  void _handleBadgeTap(String badgeType) {
    final badge = _badgeOptions.firstWhere((b) => b.name == badgeType);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BadgeSelectionSheet(
        badgeOptions: [badge],
        initialStep: _badgeOptions.indexOf(badge),
        onComplete: (selectedValues) {
          setState(() {
            _selectedBadges[badgeType] = selectedValues.first;
          });
        },
      ),
    );
  }

  void _handleEditProfilePicture() {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Change Profile Picture tapped')),
    );
  }

  void _handleFollowButton() {
    HapticFeedback.lightImpact();
    setState(() {
      _isFollowing = !_isFollowing;
    });
  }

  void _handleEditProfile() {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit Profile tapped')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: CustomScrollView(
        slivers: [
          _buildProfileHeader(),
          SliverToBoxAdapter(child: _buildProfileContent()),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.black,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/hivelogo.png',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, AppColors.black.withOpacity(0.9)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _handleEditProfilePicture,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const CircleAvatar(
                          radius: 50,
                          backgroundImage: AssetImage('assets/images/profile_placeholder.png'),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.gold,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: AppColors.black,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  Text(
                    _userName,
                    style: AppTheme.displayLarge,
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  ElevatedButton(
                    onPressed: _handleEditProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      side: const BorderSide(color: AppColors.gold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    child: Text(
                      'Edit Profile',
                      style:
                          AppTheme.labelLarge.copyWith(color: AppColors.gold),
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

  Widget _buildProfileContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing24, vertical: AppTheme.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Badges', style: AppTheme.displayMedium),
          const SizedBox(height: AppTheme.spacing16),
          Wrap(
            spacing: AppTheme.spacing8,
            runSpacing: AppTheme.spacing8,
            children: _badgeOptions.map((badge) {
              final selectedValue = _selectedBadges[badge.name] ?? 'Select ${badge.name}';
              return GestureDetector(
                onTap: () => _handleBadgeTap(badge.name),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing12, vertical: AppTheme.spacing8),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusFull),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        badge.icon,
                        width: 16,
                        height: 16,
                        color: AppColors.textPrimary,
                      ),
                      const SizedBox(width: AppTheme.spacing8),
                      Text(selectedValue, style: AppTheme.labelMedium),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppTheme.spacing24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFollowButton(),
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share Profile tapped')),
                  );
                },
                icon: const Icon(
                  Icons.share_rounded,
                  color: AppColors.gold,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing32),
          Text('Recent Activity', style: AppTheme.displayMedium),
          const SizedBox(height: AppTheme.spacing16),
          _buildActivityList(),
        ],
      ),
    );
  }

  Widget _buildFollowButton() {
    return ElevatedButton(
      onPressed: _handleFollowButton,
      style: ElevatedButton.styleFrom(
        backgroundColor: _isFollowing ? AppColors.gold : AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
      child: Text(
        _isFollowing ? 'Following' : 'Follow',
        style: AppTheme.labelLarge.copyWith(
          color: _isFollowing ? AppColors.black : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildActivityList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacing16),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_rounded, color: AppColors.gold),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: Text('Activity item ${index + 1}',
                      style: AppTheme.bodyLarge),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class BadgeOption {
  final String name;
  final String icon;
  final List<String> options;
  String? selectedOption;

  BadgeOption({
    required this.name,
    required this.icon,
    required this.options,
  });
}

class BadgeSelectionSheet extends StatefulWidget {
  final List<BadgeOption> badgeOptions;
  final Function(List<String>) onComplete;
  final int initialStep;

  const BadgeSelectionSheet({
    Key? key,
    required this.badgeOptions,
    required this.onComplete,
    required this.initialStep,
  }) : super(key: key);

  @override
  State<BadgeSelectionSheet> createState() => _BadgeSelectionSheetState();
}

class _BadgeSelectionSheetState extends State<BadgeSelectionSheet> with TickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.5, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleOptionSelected(String option) {
    HapticFeedback.selectionClick();
    setState(() {
      widget.badgeOptions[_currentStep].selectedOption = option;
      if (_currentStep < widget.badgeOptions.length - 1) {
        _animationController.reverse().then((_) {
          setState(() {
            _currentStep++;
          });
          _animationController.forward();
        });
      } else {
        _animationController.reverse().then((_) {
          final selectedOptions = widget.badgeOptions
              .map((badge) => badge.selectedOption!)
              .toList();
          widget.onComplete(selectedOptions);
          Navigator.pop(context);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentBadge = widget.badgeOptions[_currentStep];
    final progress = (_currentStep + 1) / widget.badgeOptions.length;
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppTheme.spacing16),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(AppTheme.radiusXs),
            ),
          ),
          const SizedBox(height: AppTheme.spacing24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
            child: Stack(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 4,
                  width: MediaQuery.of(context).size.width * progress - 48,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing24),
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Text('Select your ${currentBadge.name}', style: AppTheme.displayMedium),
                  if (currentBadge.selectedOption != null) ...[
                    const SizedBox(height: AppTheme.spacing8),
                    Text('Selected: ${currentBadge.selectedOption}', style: AppTheme.bodyLarge.copyWith(color: AppColors.textSecondary)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing32),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
              itemCount: currentBadge.options.length,
              itemBuilder: (context, index) {
                final option = currentBadge.options[index];
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 100 + (index * 50)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
                    child: _buildOptionTile(option, currentBadge),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(String option, BadgeOption currentBadge) {
    final bool isSelected = currentBadge.selectedOption == option;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleOptionSelected(option),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing20,
            vertical: AppTheme.spacing16,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.cardBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: isSelected ? AppColors.gold : AppColors.cardBorder,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(AppTheme.spacing8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.cardBackground : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.gold : AppColors.cardBorder,
                    width: 1,
                  ),
                ),
                child: Image.asset(
                  currentBadge.icon,
                  width: 24,
                  height: 24,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: Text(
                  option,
                  style: AppTheme.labelLarge.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              AnimatedRotation(
                duration: const Duration(milliseconds: 200),
                turns: isSelected ? 0.25 : 0,
                child: Icon(
                  isSelected
                      ? Icons.check_rounded
                      : Icons.arrow_forward_ios_rounded,
                  color: AppColors.textPrimary,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 