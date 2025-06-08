import 'package:flutter/material.dart';

/// HIVE Instant Dropdown Search - Clear, Immediate Suggestions
/// Your preferred search behavior with smooth, tech, sleek aesthetic
class HiveInstantDropdownSearch extends StatefulWidget {
  final String? label;
  final String? hint;
  final List<String> suggestions;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSelected;
  final TextEditingController? controller;

  const HiveInstantDropdownSearch({
    super.key,
    this.label,
    this.hint,
    required this.suggestions,
    this.onChanged,
    this.onSelected,
    this.controller,
  });

  @override
  State<HiveInstantDropdownSearch> createState() => _HiveInstantDropdownSearchState();
}

class _HiveInstantDropdownSearchState extends State<HiveInstantDropdownSearch>
    with TickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _dropdownController;
  late Animation<double> _dropdownAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isOpen = false;
  List<String> _filteredSuggestions = [];

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode();
    _filteredSuggestions = widget.suggestions;
    
    _dropdownController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _dropdownAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _dropdownController,
        curve: const Cubic(0.25, 0.46, 0.45, 0.94),
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _dropdownController,
        curve: const Cubic(0.16, 1, 0.3, 1),
      ),
    );

    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onTextChanged() {
    final query = _controller.text.toLowerCase();
    setState(() {
      _filteredSuggestions = widget.suggestions
          .where((suggestion) => 
              suggestion.toLowerCase().contains(query))
          .toList();
      _isOpen = _filteredSuggestions.isNotEmpty && _focusNode.hasFocus;
    });
    
    if (_isOpen) {
      _dropdownController.forward();
    } else {
      _dropdownController.reverse();
    }
    
    widget.onChanged?.call(_controller.text);
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      setState(() {
        _isOpen = false;
      });
      _dropdownController.reverse();
    } else if (_filteredSuggestions.isNotEmpty) {
      setState(() {
        _isOpen = true;
      });
      _dropdownController.forward();
    }
  }

  void _selectSuggestion(String suggestion) {
    _controller.text = suggestion;
    setState(() {
      _isOpen = false;
    });
    _dropdownController.reverse();
    widget.onSelected?.call(suggestion);
    _focusNode.unfocus();
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    _dropdownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              color: Color(0xFFCCCCCC),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        // Search Input Field
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF0F0F0F),
            border: Border.all(
              color: _focusNode.hasFocus 
                ? const Color(0xFFFFD700)
                : Colors.white.withOpacity(0.1),
              width: _focusNode.hasFocus ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: _focusNode.hasFocus ? 12 : 4,
                offset: Offset(0, _focusNode.hasFocus ? 2 : 1),
              ),
            ],
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              suffixIcon: Icon(
                Icons.search,
                color: _focusNode.hasFocus 
                  ? const Color(0xFFFFD700)
                  : Colors.white.withOpacity(0.4),
              ),
            ),
          ),
        ),
        
        // Instant Dropdown Suggestions
        if (_isOpen)
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _dropdownAnimation,
              child: Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _filteredSuggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _filteredSuggestions[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _selectSuggestion(suggestion),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                size: 16,
                                color: Colors.white.withOpacity(0.6),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  suggestion,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
} 