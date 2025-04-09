import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

class ReportEvidenceField extends StatefulWidget {
  final List<String> evidenceLinks;
  final Function(String) onEvidenceAdded;
  final Function(int) onEvidenceRemoved;

  const ReportEvidenceField({
    Key? key,
    required this.evidenceLinks,
    required this.onEvidenceAdded,
    required this.onEvidenceRemoved,
  }) : super(key: key);

  @override
  State<ReportEvidenceField> createState() => _ReportEvidenceFieldState();
}

class _ReportEvidenceFieldState extends State<ReportEvidenceField> {
  final TextEditingController _linkController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isAddingLink = false;
  String? _linkError;

  @override
  void dispose() {
    _linkController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _validateAndAddLink() {
    final link = _linkController.text.trim();
    
    if (link.isEmpty) {
      setState(() {
        _linkError = null;
      });
      return;
    }
    
    // Simple URL validation
    bool isValidUrl = Uri.tryParse(link)?.hasAbsolutePath ?? false;
    if (!isValidUrl && !link.startsWith('http')) {
      setState(() {
        _linkError = 'Please enter a valid URL';
      });
      return;
    }
    
    widget.onEvidenceAdded(link);
    _linkController.clear();
    setState(() {
      _linkError = null;
      _isAddingLink = false;
    });
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Supporting Evidence (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Add links to screenshots or other evidence',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 12),
        
        // List of existing evidence links
        if (widget.evidenceLinks.isNotEmpty) ...[
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.evidenceLinks.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.link,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.evidenceLinks[index],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white70,
                        size: 16,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => widget.onEvidenceRemoved(index),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
        
        // Button to add new evidence
        if (_isAddingLink)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _linkError != null
                        ? Colors.redAccent
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: TextField(
                  controller: _linkController,
                  focusNode: _focusNode,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter URL (e.g. https://example.com)',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    contentPadding: const EdgeInsets.all(12),
                    border: InputBorder.none,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.gold,
                        width: 2,
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _validateAndAddLink(),
                ),
              ),
              if (_linkError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 12),
                  child: Text(
                    _linkError!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isAddingLink = false;
                        _linkError = null;
                      });
                      _linkController.clear();
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _validateAndAddLink,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Add Link'),
                  ),
                ],
              ),
            ],
          )
        else
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isAddingLink = true;
              });
              // Wait for the next frame to focus the field
              Future.delayed(const Duration(milliseconds: 50), () {
                _focusNode.requestFocus();
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Evidence Link'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: AppColors.gold,
              side: const BorderSide(color: AppColors.gold),
            ),
          ),
      ],
    );
  }
} 