import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:hive_ui/features/messaging/domain/entities/message.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

/// Service for handling media uploads and file operations for messaging
class MediaService {
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseStorage _storage;
  final Uuid _uuid;

  MediaService({
    required FirebaseStorage storage,
    required Uuid uuid,
  })  : _storage = storage,
        _uuid = uuid;

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } on PlatformException catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  // Take a photo with camera
  Future<File?> takePhoto() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } on PlatformException catch (e) {
      throw Exception('Failed to take photo: $e');
    }
  }

  // Pick video from gallery
  Future<File?> pickVideoFromGallery() async {
    try {
      final pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } on PlatformException catch (e) {
      throw Exception('Failed to pick video: $e');
    }
  }

  // Record video with camera
  Future<File?> recordVideo() async {
    try {
      final pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } on PlatformException catch (e) {
      throw Exception('Failed to record video: $e');
    }
  }

  // For now, we'll use a simpler version without FilePicker, which would need to be added to pubspec.yaml
  // Pick file from device storage
  Future<File?> pickFile() async {
    try {
      // Fall back to using image picker for files until FilePicker is added
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } on PlatformException catch (e) {
      throw Exception('Failed to pick file: $e');
    }
  }

  // Get message type based on file
  MessageType getMessageTypeFromFile(File file) {
    final extension = path.extension(file.path).toLowerCase();
    final mimeType = lookupMimeType(file.path);

    if (mimeType == null) {
      return MessageType.file;
    }

    if (mimeType.startsWith('image/')) {
      return MessageType.image;
    } else if (mimeType.startsWith('video/')) {
      return MessageType.video;
    } else if (mimeType.startsWith('audio/')) {
      return MessageType.audio;
    } else {
      return MessageType.file;
    }
  }

  // Get friendly file name for display
  String getDisplayNameForFile(File file) {
    final fileName = path.basename(file.path);

    // If the filename is too long, truncate it
    if (fileName.length > 25) {
      final extension = path.extension(fileName);
      final nameWithoutExtension = path.basenameWithoutExtension(fileName);
      return '${nameWithoutExtension.substring(0, 20)}...$extension';
    }

    return fileName;
  }

  // Get file size in readable format
  String getReadableFileSize(File file) {
    final bytes = file.lengthSync();
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];

    if (bytes == 0) return '0 B';

    final i = (math.log(bytes) / math.log(1024)).floor();
    return '${(bytes / math.pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  /// Upload a file to Firebase Storage
  /// Returns the download URL
  Future<String> uploadFile(File file, String userId) async {
    try {
      // Generate a unique filename
      final fileName = '${_uuid.v4()}${path.extension(file.path)}';

      // Create a reference to the file location in Firebase Storage
      final ref = _storage.ref().child('message_attachments/$userId/$fileName');

      // Start the upload
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: lookupMimeType(file.path),
          customMetadata: {
            'uploadedBy': userId,
            'timestamp': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        // This could be used to update a progress indicator in the UI
      });

      // Wait for upload to complete
      await uploadTask;

      // Get the download URL
      final downloadUrl = await ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Determine the attachment type based on the file extension
  String getAttachmentType(File file) {
    final extension = path.extension(file.path).toLowerCase();

    // Image types
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension)) {
      return 'image';
    }

    // Video types
    if (['.mp4', '.mov', '.avi', '.wmv', '.flv', '.webm'].contains(extension)) {
      return 'video';
    }

    // Audio types
    if (['.mp3', '.wav', '.ogg', '.m4a', '.aac'].contains(extension)) {
      return 'audio';
    }

    // Document types
    if (['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt']
        .contains(extension)) {
      return 'document';
    }

    // Default
    return 'file';
  }

  /// Delete a file from Firebase Storage
  Future<void> deleteFile(String fileUrl) async {
    try {
      // Get a reference to the file from the URL
      final ref = _storage.refFromURL(fileUrl);

      // Delete the file
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  /// Get the file size in a readable format
  String getFileSize(File file) {
    final bytes = file.lengthSync();

    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
