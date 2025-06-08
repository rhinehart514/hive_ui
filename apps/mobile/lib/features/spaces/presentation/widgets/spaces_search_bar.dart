import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A search bar widget for spaces
class SpacesSearchBar extends StatefulWidget {
  /// Callback when the search query changes
  final Function(String) onSearch;
  
  /// Callback when the search is cleared
  final VoidCallback onClear;

  /// Constructor
  const SpacesSearchBar({
    Key? key,
    required this.onSearch,
    required this.onClear,
  }) : super(key: key);

  @override
  State<SpacesSearchBar> createState() => _SpacesSearchBarState();
}

class _SpacesSearchBarState extends State<SpacesSearchBar> {
  final TextEditingController _controller = TextEditingController();
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _controller.clear();
    widget.onClear();
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onSearch,
        style: GoogleFonts.inter(
          color: Colors.white,
        ),
        decoration: InputDecoration(
          hintText: 'Search spaces...',
          hintStyle: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.5),
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Colors.white,
          ),
          suffixIcon: IconButton(
            icon: const Icon(
              Icons.clear,
              color: Colors.white,
            ),
            onPressed: _clearSearch,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        cursorColor: AppColors.gold,
        textInputAction: TextInputAction.search,
        onSubmitted: widget.onSearch,
      ),
    );
  }
}
