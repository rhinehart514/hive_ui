import 'package:flutter/material.dart';
import 'dart:io';

/// HIVE File Upload - Smooth, Tech, Sleek File Handling
/// Drag and drop functionality with refined animations
class HiveFileUpload extends StatefulWidget {
  final String? label;
  final String? hint;
  final List<String>? allowedExtensions;
  final int? maxFiles;
  final int? maxSizeInMB;
  final ValueChanged<List<File>>? onFilesSelected;
  final bool allowMultiple;

  const HiveFileUpload({
    super.key,
    this.label,
    this.hint,
    this.allowedExtensions,
    this.maxFiles,
    this.maxSizeInMB,
    this.onFilesSelected,
    this.allowMultiple = true,
  });

  @override
  State<HiveFileUpload> createState() => _HiveFileUploadState();
}

class _HiveFileUploadState extends State<HiveFileUpload>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  
  bool _isDragOver = false;
  bool _isHovered = false;
  List<File> _selectedFiles = [];

  @override
  void initState() {
    super.initState();
    
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    ));

    _colorAnimation = ColorTween(
      begin: const Color(0xFF0F0F0F),
      end: const Color(0xFF1A1A1A),
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onDragEnter() {
    setState(() {
      _isDragOver = true;
    });
    _hoverController.forward();
    _pulseController.repeat();
  }

  void _onDragExit() {
    setState(() {
      _isDragOver = false;
    });
    _hoverController.reverse();
    _pulseController.stop();
    _pulseController.reset();
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    
    if (isHovered && !_isDragOver) {
      _hoverController.forward();
    } else if (!isHovered && !_isDragOver) {
      _hoverController.reverse();
    }
  }

  void _selectFiles() async {
    // Simulate file picker - in real implementation use file_picker package
    // For demo purposes, we'll just simulate adding files
    final newFiles = <File>[
      File('example_document.pdf'),
      File('image.jpg'),
    ];
    
    setState(() {
      if (widget.allowMultiple) {
        _selectedFiles.addAll(newFiles);
        if (widget.maxFiles != null && _selectedFiles.length > widget.maxFiles!) {
          _selectedFiles = _selectedFiles.take(widget.maxFiles!).toList();
        }
      } else {
        _selectedFiles = [newFiles.first];
      }
    });
    
    widget.onFilesSelected?.call(_selectedFiles);
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
    widget.onFilesSelected?.call(_selectedFiles);
  }

  String _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return '📄';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return '🖼️';
      case 'doc':
      case 'docx':
        return '📝';
      case 'xls':
      case 'xlsx':
        return '📊';
      default:
        return '📁';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
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
        
        // File Upload Zone
        AnimatedBuilder(
          animation: Listenable.merge([_hoverController, _pulseController]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: MouseRegion(
                onEnter: (_) => _onHover(true),
                onExit: (_) => _onHover(false),
                child: GestureDetector(
                  onTap: _selectFiles,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: _colorAnimation.value,
                      border: Border.all(
                        color: _isDragOver
                          ? const Color(0xFFFFD700)
                          : (_isHovered
                            ? const Color(0xFFFFD700).withOpacity(0.5)
                            : Colors.white.withOpacity(0.1)),
                        width: _isDragOver ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isDragOver
                            ? const Color(0xFFFFD700).withOpacity(0.2)
                            : Colors.black.withOpacity(0.4),
                          blurRadius: _isDragOver || _isHovered ? 12 : 4,
                          offset: Offset(0, _isDragOver || _isHovered ? 2 : 1),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Animated background pulse
                        if (_isDragOver)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: RadialGradient(
                                  center: Alignment.center,
                                  radius: 0.8,
                                  colors: [
                                    const Color(0xFFFFD700).withOpacity(
                                      0.1 * (1 - _pulseController.value),
                                    ),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        
                        // Content
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isDragOver
                                  ? Icons.file_download
                                  : Icons.cloud_upload_outlined,
                                size: 32,
                                color: _isDragOver
                                  ? const Color(0xFFFFD700)
                                  : (_isHovered
                                    ? const Color(0xFFFFD700).withOpacity(0.8)
                                    : Colors.white.withOpacity(0.6)),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isDragOver
                                  ? 'Drop files here'
                                  : (widget.hint ?? 'Drag & drop files or click to browse'),
                                style: TextStyle(
                                  color: _isDragOver
                                    ? const Color(0xFFFFD700)
                                    : Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (widget.allowedExtensions != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Supported: ${widget.allowedExtensions!.join(', ')}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
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
        
        // Selected Files List
        if (_selectedFiles.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF1A1A1A),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _selectedFiles.length,
              itemBuilder: (context, index) {
                final file = _selectedFiles[index];
                final fileName = file.path.split('/').last;
                
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: index < _selectedFiles.length - 1
                      ? const Border(
                          bottom: BorderSide(
                            color: Colors.white12,
                            width: 0.5,
                          ),
                        )
                      : null,
                  ),
                  child: Row(
                    children: [
                      Text(
                        _getFileIcon(fileName),
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fileName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _formatFileSize(1024 * 500), // Demo size
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeFile(index),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white54,
                          size: 18,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
} 