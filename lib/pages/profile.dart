import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isFollowing = false;
  bool _hasSelectedBadges = false;
  final List<String> _selectedBadges = [];
  final Map<String, String> _selectedBadgeValues = {};
  late AnimationController _profileAnimationController;
  late Animation<double> _profileFadeAnimation;
  late Animation<Offset> _profileSlideAnimation;
  late AnimationController _badgeAnimationController;
  late Animation<double> _badgeScaleAnimation;

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _profileAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _badgeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _badgeScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _badgeAnimationController, curve: Curves.easeOutBack),
    );
    _profileFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _profileAnimationController, curve: Curves.easeOut),
    );
    _profileSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _profileAnimationController, curve: Curves.easeOutCubic));
    _checkBadgeSelection();
  }

  void _checkBadgeSelection() {
    // TODO: Replace with actual storage check
    setState(() {
      _hasSelectedBadges = _selectedBadges.length == 3;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _profileAnimationController.dispose();
    _badgeAnimationController.dispose();
    super.dispose();
  }

  void _handleSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Settings functionality coming soon!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleBadgeSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BadgeSelectionSheet(
        badgeOptions: _badgeOptions,
        initialStep: 0,
        onComplete: (selectedBadges) {
          setState(() {
            _selectedBadges.clear();
            _selectedBadges.addAll(selectedBadges);
            // Store the selected values
            for (int i = 0; i < _badgeOptions.length; i++) {
              _selectedBadgeValues[_badgeOptions[i].name] = selectedBadges[i];
            }
            _hasSelectedBadges = true;
          });
          _badgeAnimationController.forward().then((_) {
            _badgeAnimationController.reverse();
          });
          _profileAnimationController.forward();
        },
        onOptionSelected: (badgeName, option) {
          setState(() {
            _selectedBadgeValues[badgeName] = option;
          });
          _badgeAnimationController.forward().then((_) {
            _badgeAnimationController.reverse();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _handleSettings,
          ),
        ],
      ),
      body: _hasSelectedBadges ? _buildAnimatedMainContent() : _buildBadgeSelection(),
    );
  }

  Widget _buildAnimatedMainContent() {
    return SlideTransition(
      position: _profileSlideAnimation,
      child: FadeTransition(
        opacity: _profileFadeAnimation,
        child: _buildMainContent(),
      ),
    );
  }

  Widget _buildBadgeSelection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white24,
                width: 2,
              ),
              image: const DecorationImage(
                image: AssetImage('assets/images/hivelogo.png'),
                fit: BoxFit.contain,
                alignment: Alignment.center,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Welcome to HIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Let\'s personalize your profile',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _handleBadgeSelection,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(
                  color: Color(0xFFFFD700),
                  width: 1,
                ),
              ),
            ),
            child: const Text(
              'Select Your Badges',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CustomProfileImage(
                    imagePath: 'assets/images/hivelogo.png',
                    onTap: () {
                      // TODO: Implement profile image update
                      HapticFeedback.lightImpact();
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Jacob Rhinehart',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            _buildIconButton(
                              icon: Icons.share_outlined,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                // TODO: Implement share
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 32,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _buildBadge(
                                icon: 'assets/images/books.png',
                                label: _selectedBadgeValues['Major'] ?? 'Add Major',
                                isSet: _selectedBadgeValues.containsKey('Major'),
                                onTap: () => _handleBadgeTap('Major'),
                              ),
                              const SizedBox(width: 8),
                              _buildBadge(
                                icon: 'assets/images/year.png',
                                label: _selectedBadgeValues['Year'] ?? 'Add Year',
                                isSet: _selectedBadgeValues.containsKey('Year'),
                                onTap: () => _handleBadgeTap('Year'),
                              ),
                              const SizedBox(width: 8),
                              _buildBadge(
                                icon: 'assets/images/whereyoulive.png',
                                label: _selectedBadgeValues['Residence'] ?? 'Add Residence',
                                isSet: _selectedBadgeValues.containsKey('Residence'),
                                onTap: () => _handleBadgeTap('Residence'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildActionButton(
                          label: _isFollowing ? 'Following' : 'Follow',
                          icon: _isFollowing ? Icons.check : Icons.add,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() => _isFollowing = !_isFollowing);
                          },
                          isActive: _isFollowing,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white12,
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              indicatorColor: Colors.white,
              indicatorWeight: 1,
              tabs: const [
                Tab(text: 'Events'),
                Tab(text: 'Clubs'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEmptyEvents(),
                _buildEmptyClubs(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required String icon,
    required String label,
    required bool isSet,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSet ? Colors.white10 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSet ? Colors.white24 : Colors.white12,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              icon,
              width: 16,
              height: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(isSet ? 1 : 0.7),
                fontSize: 13,
                fontWeight: isSet ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white10 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Colors.white24 : Colors.white12,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white12,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }

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
            _selectedBadgeValues[badgeType] = selectedValues.first;
            _hasSelectedBadges = _selectedBadgeValues.length == _badgeOptions.length;
          });
          _badgeAnimationController.forward().then((_) {
            _badgeAnimationController.reverse();
          });
        },
      ),
    );
  }

  Widget _buildEmptyEvents() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_outlined,
            size: 48,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Events Yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Events you\'re interested in will appear here',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          _buildEmptyStateButton(
            label: 'Browse Events',
            icon: Icons.search,
            onTap: () {
              // TODO: Navigate to events browse
              HapticFeedback.lightImpact();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyClubs() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.groups_outlined,
            size: 48,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Clubs Yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Join clubs to connect with like-minded people',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          _buildEmptyStateButton(
            label: 'Discover Clubs',
            icon: Icons.explore_outlined,
            onTap: () {
              // TODO: Navigate to clubs discovery
              HapticFeedback.lightImpact();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white24,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomProfileImage extends StatelessWidget {
  final String imagePath;
  final VoidCallback onTap;

  const _CustomProfileImage({
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: 240,
        child: Stack(
          children: [
            ClipPath(
              clipper: _ProfileImageClipper(),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  image: DecorationImage(
                    image: AssetImage(imagePath),
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),
            ),
            ClipPath(
              clipper: _ProfileImageClipper(),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0),
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileImageClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    
    path.moveTo(0, 0);
    path.lineTo(w, 0);
    path.lineTo(w, h * 0.85);
    
    // Create a smooth curve for the bottom
    path.quadraticBezierTo(
      w * 0.8, h,  // control point
      w * 0.6, h,   // end point
    );
    path.quadraticBezierTo(
      w * 0.4, h,   // control point
      w * 0.2, h * 0.9, // end point
    );
    path.quadraticBezierTo(
      0, h * 0.8,   // control point
      0, h * 0.7,   // end point
    );
    
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
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
  final Function(String, String)? onOptionSelected;
  final int initialStep;

  const BadgeSelectionSheet({
    super.key,
    required this.badgeOptions,
    required this.onComplete,
    this.onOptionSelected,
    required this.initialStep,
  });

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
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();
    _currentStep = widget.initialStep;
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
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Stack(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  height: 4,
                  width: MediaQuery.of(context).size.width * progress - 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Text(
                    'Select your ${currentBadge.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (currentBadge.selectedOption != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Selected: ${currentBadge.selectedOption}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildOptionTile(option, currentBadge),
                      ),
                    );
                  },
                ),
              ),
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
        onTap: () {
          HapticFeedback.selectionClick();
          _handleOptionSelected(option);
          widget.onOptionSelected?.call(currentBadge.name, option);
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white10 : Colors.black,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFFFFD700) : Colors.white24,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white10 : Colors.black,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? const Color(0xFFFFD700) : Colors.white24,
                    width: 1,
                  ),
                ),
                child: Image.asset(
                  currentBadge.icon,
                  width: 24,
                  height: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  option,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              AnimatedRotation(
                duration: const Duration(milliseconds: 200),
                turns: isSelected ? 0.25 : 0,
                child: Icon(
                  isSelected ? Icons.check : Icons.arrow_forward_ios,
                  color: Colors.white,
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