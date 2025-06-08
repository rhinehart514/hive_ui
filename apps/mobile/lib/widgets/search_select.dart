import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchSelect extends StatefulWidget {
  final String title;
  final String? selectedValue;
  final String placeholder;
  final List<String> options;
  final Function(String)? onSearch;
  final Function(String) onSelect;
  final VoidCallback onClear;
  final bool showSearchInstructions;

  const SearchSelect({
    super.key,
    required this.title,
    this.selectedValue,
    required this.placeholder,
    required this.options,
    this.onSearch,
    required this.onSelect,
    required this.onClear,
    this.showSearchInstructions = true,
  });

  @override
  State<SearchSelect> createState() => _SearchSelectState();
}

class _SearchSelectState extends State<SearchSelect> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _showDropdown = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
      if (_isFocused) {
        _showDropdown = true;
        _showOverlay();
      } else {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (!_focusNode.hasFocus) {
            _hideOverlay();
          }
        });
      }
    });
  }

  void _showOverlay() {
    _hideOverlay(); // Ensure any existing overlay is removed first

    if (_overlayEntry != null) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        top: offset.dy + size.height + 5,
        left: offset.dx,
        child: Material(
          elevation: 4,
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: widget.options.isEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Text(
                      'No results found',
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: widget.options.length,
                    itemBuilder: (context, index) {
                      final option = widget.options[index];
                      return InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          widget.onSelect(option);
                          _searchController.clear();
                          _hideOverlay();
                          _focusNode.unfocus();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: index < widget.options.length - 1
                                ? const Border(
                                    bottom: BorderSide(color: Colors.white12))
                                : null,
                          ),
                          child: Text(
                            option,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _showDropdown = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _hideOverlay();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If an item is selected, show it with a clear button
    if (widget.selectedValue != null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.selectedValue!,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70, size: 20),
              onPressed: () {
                HapticFeedback.lightImpact();
                widget.onClear();
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    }

    // Otherwise show the search field with dropdown
    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              _focusNode.requestFocus();
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius:
                    BorderRadius.circular(28), // Pill shape for search
                border: Border.all(
                  color: _isFocused ? const Color(0xFFFFD700) : Colors.white24,
                  width: 1,
                ),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 0),
                        )
                      ]
                    : null,
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                ),
                onChanged: (value) {
                  if (widget.onSearch != null) {
                    widget.onSearch!(value);
                  }
                  if (!_showDropdown && value.isNotEmpty) {
                    setState(() {
                      _showDropdown = true;
                      _showOverlay();
                    });
                  }
                },
                onTap: () {
                  setState(() {
                    _showDropdown = true;
                    _showOverlay();
                  });
                },
                decoration: InputDecoration(
                  hintText: widget.placeholder,
                  hintStyle: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  suffixIcon: _isFocused
                      ? const Icon(Icons.keyboard_arrow_up,
                          color: Colors.white54)
                      : const Icon(Icons.keyboard_arrow_down,
                          color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
