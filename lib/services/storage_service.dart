import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload an image file to Firebase Storage
  /// Returns the download URL of the uploaded image
  Future<String> uploadImage({
    required File imageFile,
    required String folder,
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 85,
  }) async {
    try {
      // Compress and resize image
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) throw 'Could not decode image';

      // Resize image while maintaining aspect ratio
      final resized = img.copyResize(
        image,
        width: maxWidth,
        height: maxHeight,
        interpolation: img.Interpolation.linear,
      );

      // Encode as JPEG with quality setting
      final compressed = img.encodeJpg(resized, quality: quality);

      // Create unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = path.extension(imageFile.path).toLowerCase();
      final filename = 'image_$timestamp$ext';

      // Upload to Firebase Storage
      final ref = _storage.ref().child('$folder/$filename');

      // Create metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'originalFilename': path.basename(imageFile.path),
          'timestamp': timestamp.toString(),
          'width': resized.width.toString(),
          'height': resized.height.toString(),
        },
      );

      // Upload compressed image
      final uploadTask = await ref.putData(compressed, metadata);

      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }

  /// Delete an image from Firebase Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      if (!imageUrl.startsWith('https://firebasestorage.googleapis.com')) {
        throw 'Invalid Firebase Storage URL';
      }

      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting image: $e');
      rethrow;
    }
  }

  /// Get metadata for an image
  Future<Map<String, String>> getImageMetadata(String imageUrl) async {
    try {
      if (!imageUrl.startsWith('https://firebasestorage.googleapis.com')) {
        throw 'Invalid Firebase Storage URL';
      }

      final ref = _storage.refFromURL(imageUrl);
      final metadata = await ref.getMetadata();

      return metadata.customMetadata ?? {};
    } catch (e) {
      debugPrint('Error getting image metadata: $e');
      rethrow;
    }
  }
}
