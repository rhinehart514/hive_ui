import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:async';
import 'package:hive_ui/theme/app_colors.dart';

/// A sophisticated predictive search input component that expands with backdrop blur
/// and provides type-ahead powered by recent campus terms from Feed and Space titles
/// 
/// HIVE Principle Compliance:
/// - Campus-first minimalism: Translucent backdrop for real content
/// - Living momentum: Weight-pulse animation creates peripheral energy
/// - Honey-drop restraint: Gold only for "take action now" (selection)
/// - Builder-first modularity: Fully customizable via props and tokens
class PredictiveSearchInput extends StatefulWidget {
  /// Callback when a search result is selected
  final Function(String)? onResultSelected;
  
  /// Callback when search text changes
  final Function(String)? onSearchChanged;
  
  /// List of campus terms to search through (from Feed and Space titles)
  final List<String> campusTerms;
  
  /// Placeholder text for the input
  final String hintText;
  
  /// Whether the search is currently active/expanded
  final bool isInitiallyExpanded;

  const PredictiveSearchInput({
    super.key,
    this.onResultSelected,
    this.onSearchChanged,
    this.campusTerms = const [],
    this.hintText = 'Search campus terms...',
    this.isInitiallyExpanded = false,
  });

  @override
  State<PredictiveSearchInput> createState() => _PredictiveSearchInputState();
}

class _PredictiveSearchInputState extends State<PredictiveSearchInput>
    with TickerProviderStateMixin {
  
  late AnimationController _expansionController;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late Animation<double> _expandAnimation;
  late Animation<double> _blurAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;
  
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  bool _isExpanded = false;
  bool _isHovering = false;
  List<String> _filteredResults = [];
  int _selectedIndex = -1;
  String _searchText = '';
  Timer? _shimmerTimer;
  
  // HIVE Design Tokens (Builder-first modularity)
  static const Color _pulseBlue = Color(0xFF56CCF2); // Info blue for hover states
  static const Color _neutralBorder = Colors.white;
  static const double _borderRadius = 12.0;
  static const double _inputHeight = 56.0;
  static const double _spacing = 16.0;
  
  // Sample campus terms (in real app, this would come from Feed and Space data)
  late List<String> _defaultCampusTerms;

  @override
  void initState() {
    super.initState();
    
    // Initialize default campus terms if none provided
    _defaultCampusTerms = widget.campusTerms.isNotEmpty 
        ? widget.campusTerms
        : [
            'Computer Science Club',
            'Entrepreneurship Space',
            'Campus Hackathon 2024',
            'Study Group - Algorithms',
            'Basketball Intramurals',
            'AI Research Lab',
            'Startup Pitch Night',
            'Career Fair Fall 2024',
            'Greek Life Mixer',
            'Engineering Society',
            'Pre-Med Study Hall',
            'Music Production Workshop',
            'Photography Club',
            'Debate Team Tryouts',
            'Sustainability Initiative',
            'Campus Food Drive',
            'Tech Talk Series',
            'Finance Club Meeting',
            'Gaming Tournament',
            'Art Exhibition Opening'
          ];
    
    // Initialize animations (Living momentum)
    _expansionController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _expandAnimation = CurvedAnimation(
      parent: _expansionController,
      curve: Curves.easeOutCubic,
    );
    
    _blurAnimation = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(_expandAnimation);
    
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Set initial state
    _isExpanded = widget.isInitiallyExpanded;
    if (_isExpanded) {
      _expansionController.value = 1.0;
    }
    
    // Listen to text changes
    _textController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
    
    // Start living momentum effects
    _startShimmerTimer();
    _startPulseAnimation();
  }

  @override
  void dispose() {
    _expansionController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    _textController.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _textController.dispose();
    _focusNode.dispose();
    _shimmerTimer?.cancel();
    super.dispose();
  }

  void _startShimmerTimer() {
    _shimmerTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && _isExpanded && _filteredResults.isNotEmpty) {
        _shimmerController.forward().then((_) {
          if (mounted) {
            _shimmerController.reset();
          }
        });
      }
    });
  }
  
  void _startPulseAnimation() {
    _pulseController.repeat(reverse: true);
  }

  void _onTextChanged() {
    final text = _textController.text;
    setState(() {
      _searchText = text;
      _selectedIndex = -1;
    });
    
    // Predictive filtering - feels alive on first 3 keystrokes
    _updateFilteredResults(text);
    
    // Notify parent
    if (widget.onSearchChanged != null) {
      widget.onSearchChanged!(text);
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && !_isExpanded) {
      _expand();
    }
  }

  void _updateFilteredResults(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredResults = [];
      });
      return;
    }
    
    // Smart filtering with predictive feel
    final filtered = _defaultCampusTerms.where((term) {
      final queryLower = query.toLowerCase();
      final termLower = term.toLowerCase();
      
      // Prioritize starts with matches for first 3 keystrokes
      if (query.length <= 3) {
        return termLower.startsWith(queryLower);
      }
      
      // Then expand to contains matches
      return termLower.contains(queryLower);
    }).take(8).toList(); // Limit to 8 results
    
    setState(() {
      _filteredResults = filtered;
    });
  }

  void _expand() {
    if (_isExpanded) return;
    
    setState(() {
      _isExpanded = true;
    });
    
    _expansionController.forward();
    _focusNode.requestFocus();
    
    // Haptic feedback
    HapticFeedback.lightImpact();
  }

  void _collapse() {
    if (!_isExpanded) return;
    
    setState(() {
      _isExpanded = false;
      _filteredResults = [];
    });
    
    _expansionController.reverse();
    _focusNode.unfocus();
    
    // Haptic feedback
    HapticFeedback.selectionClick();
  }

  void _selectResult(String result) {
    _textController.text = result;
    _collapse();
    
    if (widget.onResultSelected != null) {
      widget.onResultSelected!(result);
    }
    
    // Haptic feedback - celebrate the win
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchInput(),
        if (_isExpanded && _filteredResults.isNotEmpty)
          _buildResultsList(),
      ],
    );
  }

  Widget _buildSearchInput() {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        return MouseRegion(
          onEnter: (_) => setState(() => _isHovering = true),
          onExit: (_) => setState(() => _isHovering = false),
          child: GestureDetector(
            onTap: _expand,
            child: Container(
              width: double.infinity,
              height: _inputHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_borderRadius),
                // Campus-first minimalism: Translucent backdrop
                color: Colors.white.withOpacity(0.06),
                border: Border.all(
                  // Honey-drop restraint: Use pulse-blue for hover, neutral for normal
                  color: _isExpanded 
                      ? _pulseBlue.withOpacity(0.8)
                      : _neutralBorder.withOpacity(_isHovering ? 0.15 : 0.1),
                  width: _isExpanded ? 1.5 : 1.0,
                ),
                // Subtle glow when expanded (pulse-blue, not gold)
                boxShadow: _isExpanded ? [
                  BoxShadow(
                    color: _pulseBlue.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ] : [],
              ),
              child: Stack(
                children: [
                  // Backdrop blur effect when expanded
                  if (_isExpanded)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(_borderRadius),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: _blurAnimation.value,
                            sigmaY: _blurAnimation.value,
                          ),
                          child: Container(
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                  
                  // Input field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _spacing),
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        suffixIcon: _isExpanded ? IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: _collapse,
                        ) : AnimatedBuilder(
                          animation: _pulseAnimation,
                          child: const Icon(
                            Icons.search,
                            color: _pulseBlue,
                            size: 20,
                          ),
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: child,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultsList() {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_borderRadius),
            color: const Color(0xFF1E1E1E),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
            // Elevation e2 as specified
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_borderRadius),
            child: Column(
              children: [
                // Living momentum: Real-time shimmer indicator
                SizedBox(
                  height: 2,
                  child: AnimatedBuilder(
                    animation: _shimmerAnimation,
                    builder: (context, child) {
                      return Stack(
                        children: [
                          Container(
                            color: Colors.white.withOpacity(0.05),
                          ),
                          Positioned(
                            left: _shimmerAnimation.value * MediaQuery.of(context).size.width,
                            child: Container(
                              width: 60,
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    _pulseBlue.withOpacity(0.6),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                
                // Results list
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredResults.length,
                  itemBuilder: (context, index) {
                    final result = _filteredResults[index];
                    final isSelected = index == _selectedIndex;
                    
                    return _buildResultItem(result, isSelected, index);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultItem(String result, bool isSelected, int index) {
    return MouseRegion(
      onEnter: (_) => setState(() => _selectedIndex = index),
      child: GestureDetector(
        onTap: () => _selectResult(result),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: _spacing, vertical: 12),
          decoration: BoxDecoration(
            // Honey-drop restraint: Gold ONLY for "take action now" (selected state)
            color: isSelected 
                ? AppColors.gold.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search,
                size: 16,
                // Honey-drop restraint: Gold only when ready to take action
                color: isSelected 
                    ? AppColors.gold 
                    : _pulseBlue.withOpacity(0.8),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result,
                  style: TextStyle(
                    color: isSelected 
                        ? Colors.white 
                        : Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  // Honey-drop restraint: Gold for "take action now"
                  color: AppColors.gold.withOpacity(0.8),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 