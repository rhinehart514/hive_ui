import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/constants/interest_options.dart';

/// A component for selecting interests from a list
class InterestSelector extends ConsumerStatefulWidget {
  /// The list of selected interests
  final List<String> selectedInterests;

  /// The list of all available interests
  final List<String> interestOptions;

  /// The minimum number of required interests
  final int minInterests;

  /// The maximum number of allowed interests
  final int maxInterests;

  /// Callback when interests are updated
  final Function(List<String>) onInterestsUpdated;

  /// Creates an InterestSelector
  const InterestSelector({
    super.key,
    required this.selectedInterests,
    this.interestOptions = const [], // Make optional
    required this.minInterests,
    required this.maxInterests,
    required this.onInterestsUpdated,
  });

  @override
  ConsumerState<InterestSelector> createState() => _InterestSelectorState();
}

class _InterestSelectorState extends ConsumerState<InterestSelector> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _interestsScrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  String _searchQuery = '';
  bool _isSearchFocused = false;
  List<String> _filteredInterests = [];
  List<String> _availableInterests = [];

  @override
  void initState() {
    super.initState();
    // Use the provided interests or fall back to shared InterestOptions
    _availableInterests = widget.interestOptions.isNotEmpty
        ? widget.interestOptions
        : InterestOptions.options;

    _filteredInterests = _availableInterests;
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _interestsScrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filteredInterests = _availableInterests
          .where((interest) => interest.toLowerCase().contains(_searchQuery))
          .toList();
    });
  }

  void _onSearchFocusChanged() {
    setState(() {
      _isSearchFocused = _searchFocusNode.hasFocus;
    });
  }

  void _toggleInterest(String interest) {
    if (widget.selectedInterests.contains(interest)) {
      // Remove interest
      final updated =
          widget.selectedInterests.where((i) => i != interest).toList();
      widget.onInterestsUpdated(updated);
    } else if (widget.selectedInterests.length < widget.maxInterests) {
      // Add interest if under max limit
      widget.onInterestsUpdated([...widget.selectedInterests, interest]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select ${widget.minInterests}-${widget.maxInterests} interests',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            Text(
              '${widget.selectedInterests.length}/${widget.maxInterests}',
              style: TextStyle(
                color: widget.selectedInterests.length < widget.minInterests
                    ? Colors.redAccent
                    : Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Search bar
        TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search interests...',
            hintStyle: const TextStyle(color: Colors.white54),
            prefixIcon: const Icon(Icons.search, color: Colors.white54),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white54),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 16),

        // Selected interests chips
        if (widget.selectedInterests.isNotEmpty) ...[
          const Text(
            'Selected Interests',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.selectedInterests.map((interest) {
              return Chip(
                label: Text(interest),
                backgroundColor: AppColors.gold.withOpacity(0.2),
                side: const BorderSide(color: AppColors.gold),
                labelStyle: const TextStyle(color: Colors.white),
                deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white),
                onDeleted: () => _toggleInterest(interest),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Available interests
        Text(
          _searchQuery.isEmpty ? 'Popular Interests' : 'Search Results',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Interest options
        SizedBox(
          height: 200,
          child: SingleChildScrollView(
            controller: _interestsScrollController,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _filteredInterests.map((interest) {
                final isSelected = widget.selectedInterests.contains(interest);
                return ActionChip(
                  label: Text(interest),
                  backgroundColor: isSelected
                      ? AppColors.gold.withOpacity(0.2)
                      : Colors.white.withOpacity(0.1),
                  side: BorderSide(
                    color: isSelected ? AppColors.gold : Colors.transparent,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.gold : Colors.white,
                  ),
                  onPressed: () => _toggleInterest(interest),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
