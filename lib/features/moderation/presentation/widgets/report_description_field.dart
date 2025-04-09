import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

class ReportDescriptionField extends StatelessWidget {
  final String initialValue;
  final Function(String) onChanged;
  final int maxLength;
  final int minLength;

  const ReportDescriptionField({
    Key? key,
    required this.initialValue,
    required this.onChanged,
    this.maxLength = 500,
    this.minLength = 10,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Please provide details about why you are reporting this content',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: TextField(
            controller: TextEditingController(text: initialValue),
            onChanged: onChanged,
            maxLength: maxLength,
            maxLines: 5,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              counterStyle: const TextStyle(color: Colors.white70),
              hintText: 'Describe the issue...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              contentPadding: const EdgeInsets.all(16),
              border: InputBorder.none,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.gold,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        if (initialValue.isNotEmpty && initialValue.length < minLength)
          Text(
            'Please provide at least $minLength characters',
            style: TextStyle(
              fontSize: 12,
              color: Colors.redAccent.shade200,
            ),
          ),
      ],
    );
  }
} 