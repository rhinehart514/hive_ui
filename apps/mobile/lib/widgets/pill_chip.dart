import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

enum PillChipVariant {
  selected,
  unselected,
  selectable,
}

class PillChip extends StatelessWidget {
  final String text;
  final String? emoji;
  final bool isSelected;
  final VoidCallback onTap;
  final PillChipVariant variant;
  final bool showRemoveIcon;

  const PillChip({
    super.key,
    required this.text,
    this.emoji,
    required this.isSelected,
    required this.onTap,
    this.variant = PillChipVariant.selectable,
    this.showRemoveIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(28), // Pill shape
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD700) : Colors.white24,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(
                emoji!,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showRemoveIcon && isSelected) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.close,
                color: Colors.white70,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (variant) {
      case PillChipVariant.selected:
        return const Color(0xFF2A2A2A);
      case PillChipVariant.unselected:
        return Colors.transparent;
      case PillChipVariant.selectable:
        return isSelected ? const Color(0xFF2A2A2A) : Colors.transparent;
    }
  }
}
