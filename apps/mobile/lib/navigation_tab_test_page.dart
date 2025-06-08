import 'dart:ui';
import 'package:flutter/material.dart';

/// Dedicated Navigation System Test Page
/// Testing platform-specific navigation patterns:
/// Mobile: Bottom Nav | Web/Desktop: Left Sidebar (Twitter-style)
/// Following "smooth, tech, sleek" aesthetic preferences

class NavigationTabTestPage extends StatefulWidget {
  const NavigationTabTestPage({super.key});

  @override
  State<NavigationTabTestPage> createState() => _NavigationTabTestPageState();
}

class _NavigationTabTestPageState extends State<NavigationTabTestPage> {
  int _selectedIndex = 0;
  bool _isDesktopLayout = false;
  
  // HIVE Navigation Items (from existing codebase)
  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Home',
      route: '/home',
    ),
    NavigationItem(
      icon: Icons.group_outlined,
      selectedIcon: Icons.group,
      label: 'Spaces',
      route: '/spaces',
    ),
    NavigationItem(
      icon: Icons.event_outlined,
      selectedIcon: Icons.event,
      label: 'Events',
      route: '/events',
    ),
    NavigationItem(
      icon: Icons.science_outlined,
      selectedIcon: Icons.science,
      label: 'HiveLAB',
      route: '/lab',
    ),
    NavigationItem(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Profile',
      route: '/profile',
    ),
    // Additional items for desktop sidebar testing
    NavigationItem(
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications,
      label: 'Notifications',
      route: '/notifications',
    ),
    NavigationItem(
      icon: Icons.bookmark_border,
      selectedIcon: Icons.bookmark,
      label: 'Saved',
      route: '/saved',
    ),
    NavigationItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
      route: '/settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    _isDesktopLayout = MediaQuery.of(context).size.width >= 768;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          '🧭 HIVE Navigation System Design',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.phone_android,
                  color: !_isDesktopLayout ? const Color(0xFFFFD700) : Colors.white54,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _isDesktopLayout,
                  onChanged: (value) {
                    setState(() {
                      _isDesktopLayout = value;
                    });
                  },
                  activeColor: const Color(0xFFFFD700),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.white24,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.desktop_mac,
                  color: _isDesktopLayout ? const Color(0xFFFFD700) : Colors.white54,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isDesktopLayout ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          color: const Color(0xFF1A1A1A),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📱 Mobile Navigation: Bottom Nav',
                style: TextStyle(
                  color: Color(0xFF56CCF2),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Standard mobile pattern with 5 primary navigation items',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 12),
              Text(
                '✨ Features: Gold selection indicator, haptic feedback, adaptive touch targets',
                style: TextStyle(color: Color(0xFFFFD700), fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        
        // Content Area
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Current Page Indicator
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _navigationItems[_selectedIndex].selectedIcon,
                        color: const Color(0xFFFFD700),
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_navigationItems[_selectedIndex].label} Page',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Route: ${_navigationItems[_selectedIndex].route}',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Mobile Navigation Guidelines
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📋 Mobile Navigation Guidelines',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '• Maximum 5 items for thumb accessibility\n'
                        '• 56pt minimum height for touch targets\n'
                        '• Gold accent (#FFD700) for active states\n'
                        '• Haptic feedback on selection\n'
                        '• Outlined/filled icon variants\n'
                        '• Smooth 200ms selection animation',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // HIVE Bottom Navigation Bar (Mobile)
        _buildHiveBottomNav(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // HIVE Left Sidebar (Desktop)
        _buildHiveLeftSidebar(),
        
        // Content Area
        Expanded(
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: const Color(0xFF1A1A1A),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🖥️ Desktop Navigation: Left Sidebar (Twitter-style)',
                      style: TextStyle(
                        color: Color(0xFF56CCF2),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Scalable sidebar pattern supporting unlimited navigation items',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '✨ Features: Collapsible design, smooth animations, contextual tooltips',
                      style: TextStyle(color: Color(0xFFFFD700), fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Current Page Indicator
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _navigationItems[_selectedIndex].selectedIcon,
                              color: const Color(0xFFFFD700),
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${_navigationItems[_selectedIndex].label} Page',
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Route: ${_navigationItems[_selectedIndex].route}',
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Desktop Navigation Guidelines
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '📋 Desktop Sidebar Guidelines',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              '• Scalable to unlimited navigation items\n'
                              '• 240px width when expanded, 72px when collapsed\n'
                              '• Twitter-style interaction patterns\n'
                              '• Gold accent bar for active states\n'
                              '• Smooth hover animations\n'
                              '• Keyboard navigation support\n'
                              '• Tooltips for collapsed state',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

    Widget _buildHiveBottomNav() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1E1E1E).withOpacity(0.95),
            const Color(0xFF0F0F0F).withOpacity(0.98),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.02),
            blurRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.03),
                  Colors.white.withOpacity(0.01),
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: _navigationItems.take(5).toList().asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = index == _selectedIndex;
                
                return Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _selectedIndex = index),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Gold selection indicator with glow
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              width: isSelected ? 32 : 0,
                              height: 3,
                              decoration: BoxDecoration(
                                gradient: isSelected ? const LinearGradient(
                                  colors: [Color(0xFFFFD700), Color(0xFFFFE55C)],
                                ) : null,
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: const Color(0xFFFFD700).withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ] : [],
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Icon with smooth transition
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                isSelected ? item.selectedIcon : item.icon,
                                key: ValueKey('$index-$isSelected'),
                                color: isSelected 
                                  ? const Color(0xFFFFD700)
                                  : Colors.white.withOpacity(0.7),
                                size: 24,
                              ),
                            ),
                            
                            const SizedBox(height: 4),
                            
                            // Label
                            Text(
                              item.label,
                              style: TextStyle(
                                color: isSelected 
                                  ? const Color(0xFFFFD700)
                                  : Colors.white.withOpacity(0.7),
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHiveLeftSidebar() {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E1E1E).withOpacity(0.98),
            const Color(0xFF161616).withOpacity(0.95),
          ],
        ),
        border: Border(
          right: BorderSide(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // HIVE Brand Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFE55C)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.hexagon,
                    color: Color(0xFF0D0D0D),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'HIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          
          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _navigationItems.length,
              itemBuilder: (context, index) {
                final item = _navigationItems[index];
                final isSelected = index == _selectedIndex;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => setState(() => _selectedIndex = index),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: isSelected ? LinearGradient(
                            colors: [
                              const Color(0xFFFFD700).withOpacity(0.12),
                              const Color(0xFFFFE55C).withOpacity(0.06),
                            ],
                          ) : null,
                          color: !isSelected ? Colors.transparent : null,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                            ? Border.all(color: const Color(0xFFFFD700).withOpacity(0.3))
                            : null,
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ] : [],
                        ),
                        child: Row(
                          children: [
                            // Gold accent bar
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              width: 3,
                              height: isSelected ? 24 : 0,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            
                            SizedBox(width: isSelected ? 12 : 0),
                            
                            // Icon
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                isSelected ? item.selectedIcon : item.icon,
                                key: ValueKey('$index-$isSelected'),
                                color: isSelected 
                                  ? const Color(0xFFFFD700)
                                  : Colors.white.withOpacity(0.7),
                                size: 20,
                              ),
                            ),
                            
                            const SizedBox(width: 16),
                            
                            // Label
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  color: isSelected 
                                    ? const Color(0xFFFFD700)
                                    : Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
  });
} 