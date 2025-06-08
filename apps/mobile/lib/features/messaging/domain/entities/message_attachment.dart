/// Represents an attachment in a message
class MessageAttachment {
  /// Unique identifier of the attachment
  final String id;
  
  /// URL of the attachment
  final String url;
  
  /// Type of the attachment (image, video, audio, file)
  final String type;
  
  /// Optional caption for the attachment
  final String? caption;
  
  /// File name for attachments of type 'file'
  final String? fileName;
  
  /// File size in bytes
  final int? size;
  
  /// MIME type of the file
  final String? mimeType;
  
  /// Width for image and video attachments
  final int? width;
  
  /// Height for image and video attachments
  final int? height;
  
  /// Duration in seconds for audio and video attachments
  final int? duration;
  
  /// Thumbnail URL for video attachments
  final String? thumbnailUrl;
  
  const MessageAttachment({
    required this.id,
    required this.url,
    required this.type,
    this.caption,
    this.fileName,
    this.size,
    this.mimeType,
    this.width,
    this.height,
    this.duration,
    this.thumbnailUrl,
  });
  
  /// Create from JSON data
  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      id: json['id'] as String,
      url: json['url'] as String,
      type: json['type'] as String,
      caption: json['caption'] as String?,
      fileName: json['fileName'] as String?,
      size: json['size'] as int?,
      mimeType: json['mimeType'] as String?,
      width: json['width'] as int?,
      height: json['height'] as int?,
      duration: json['duration'] as int?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'type': type,
      if (caption != null) 'caption': caption,
      if (fileName != null) 'fileName': fileName,
      if (size != null) 'size': size,
      if (mimeType != null) 'mimeType': mimeType,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (duration != null) 'duration': duration,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
    };
  }
  
  /// Create a copy of this attachment with modified properties
  MessageAttachment copyWith({
    String? id,
    String? url,
    String? type,
    String? caption,
    String? fileName,
    int? size,
    String? mimeType,
    int? width,
    int? height,
    int? duration,
    String? thumbnailUrl,
  }) {
    return MessageAttachment(
      id: id ?? this.id,
      url: url ?? this.url,
      type: type ?? this.type,
      caption: caption ?? this.caption,
      fileName: fileName ?? this.fileName,
      size: size ?? this.size,
      mimeType: mimeType ?? this.mimeType,
      width: width ?? this.width,
      height: height ?? this.height,
      duration: duration ?? this.duration,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }
} 
 
 