import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:photo_view/photo_view.dart';
import 'package:hive_ui/features/messaging/domain/entities/message_attachment.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A screen for viewing attachments in fullscreen
class AttachmentViewerScreen extends StatefulWidget {
  final MessageAttachment attachment;
  final List<MessageAttachment>? allAttachments;

  const AttachmentViewerScreen({
    Key? key,
    required this.attachment,
    this.allAttachments,
  }) : super(key: key);

  @override
  _AttachmentViewerScreenState createState() => _AttachmentViewerScreenState();
}

class _AttachmentViewerScreenState extends State<AttachmentViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Enter fullscreen mode
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );
    
    if (widget.allAttachments != null) {
      _currentIndex = widget.allAttachments!.indexOf(widget.attachment);
      if (_currentIndex < 0) _currentIndex = 0;
      _pageController = PageController(initialPage: _currentIndex);
    } else {
      _currentIndex = 0;
      _pageController = PageController();
    }
    
    _initializeCurrentAttachment();
  }

  @override
  void dispose() {
    // Exit fullscreen mode
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
    
    _videoController?.dispose();
    _chewieController?.dispose();
    _pageController.dispose();
    super.dispose();
  }
  
  Future<void> _initializeCurrentAttachment() async {
    final attachment = _getCurrentAttachment();
    
    if (attachment.type == 'video') {
      _videoController?.dispose();
      _chewieController?.dispose();
      
      setState(() {
        _isLoading = true;
      });
      
      _videoController = VideoPlayerController.network(attachment.url);
      await _videoController!.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Error: $errorMessage',
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  MessageAttachment _getCurrentAttachment() {
    if (widget.allAttachments != null) {
      return widget.allAttachments![_currentIndex];
    }
    return widget.attachment;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_getCurrentAttachment().type == 'image')
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                // TODO: Implement download functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Download started')),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon')),
              );
            },
          ),
        ],
      ),
      body: widget.allAttachments != null && widget.allAttachments!.length > 1
          ? PageView.builder(
              controller: _pageController,
              itemCount: widget.allAttachments!.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
                _initializeCurrentAttachment();
              },
              itemBuilder: (context, index) {
                return _buildAttachmentView(widget.allAttachments![index]);
              },
            )
          : _buildAttachmentView(_getCurrentAttachment()),
      bottomNavigationBar: widget.allAttachments != null && widget.allAttachments!.length > 1
          ? Container(
              height: 60,
              color: Colors.black.withOpacity(0.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_currentIndex + 1} of ${widget.allAttachments!.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildAttachmentView(MessageAttachment attachment) {
    switch (attachment.type) {
      case 'image':
        return _buildImageView(attachment);
      case 'video':
        return _buildVideoView(attachment);
      case 'audio':
        return _buildAudioView(attachment);
      case 'file':
        return _buildFileView(attachment);
      default:
        return const Center(
          child: Text(
            'Unsupported attachment type',
            style: TextStyle(color: Colors.white),
          ),
        );
    }
  }

  Widget _buildImageView(MessageAttachment attachment) {
    return GestureDetector(
      onTap: () {
        // Toggle app bar visibility
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      child: PhotoView(
        imageProvider: CachedNetworkImageProvider(attachment.url),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        loadingBuilder: (context, event) => Center(
          child: CircularProgressIndicator(
            value: event == null
                ? 0
                : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
          ),
        ),
        errorBuilder: (context, obj, trace) => const Center(
          child: Icon(Icons.broken_image, color: Colors.white, size: 50),
        ),
      ),
    );
  }

  Widget _buildVideoView(MessageAttachment attachment) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
        ),
      );
    }
    
    if (_chewieController == null) {
      return const Center(
        child: Text(
          'Error loading video',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    
    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: Chewie(controller: _chewieController!),
      ),
    );
  }

  Widget _buildAudioView(MessageAttachment attachment) {
    // Simple audio player view
    return Center(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.audiotrack,
              color: AppColors.gold,
              size: 80,
            ),
            const SizedBox(height: 20),
            Text(
              attachment.fileName ?? 'Audio file',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            const Text(
              'Audio player coming soon',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileView(MessageAttachment attachment) {
    final fileName = attachment.fileName ?? attachment.url.split('/').last;
    
    return Center(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  fileName.split('.').last.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              fileName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (attachment.size != null) ...[
              const SizedBox(height: 10),
              Text(
                '${(attachment.size! / 1024).toStringAsFixed(2)} KB',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
            ],
            const SizedBox(height: 30),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                // TODO: Implement download functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Download started')),
                );
              },
              icon: const Icon(Icons.download),
              label: const Text('Download'),
            ),
          ],
        ),
      ),
    );
  }
} 