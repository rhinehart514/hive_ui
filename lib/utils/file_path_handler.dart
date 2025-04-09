import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

/// Utility class for handling file paths across platforms
class FilePathHandler {
  /// Convert a local file path to a proper URI string that works across platforms
  static String getProperPath(String filePath) {
    // Handle empty paths
    if (filePath.isEmpty) {
      return '';
    }
    
    // Handle file:// protocol properly
    if (filePath.startsWith('file://')) {
      try {
        // Remove the protocol to get a regular file path
        String rawPath = filePath.replaceFirst('file://', '');
        
        if (Platform.isWindows) {
          // For Windows paths:
          // 1. Remove leading slashes
          rawPath = rawPath.replaceFirst(RegExp(r'^/+'), '');
          
          // 2. Handle drive letter if present (e.g., C:)
          if (rawPath.contains(':')) {
            // Ensure drive letter is properly formatted
            final parts = rawPath.split(':');
            if (parts.length == 2) {
              rawPath = '${parts[0].toUpperCase()}:${parts[1]}';
            }
          }
          
          // 3. Convert forward slashes to backslashes for Windows
          rawPath = rawPath.replaceAll('/', '\\');
        } else {
          // For non-Windows platforms, just use the path as is
          rawPath = rawPath;
        }
            
        // Verify it's a valid file path
        if (rawPath.isEmpty) {
          debugPrint('Invalid file:// path: $filePath');
          return '';
        }
        
        // Return as regular file path to avoid URI parsing issues
        return rawPath;
      } catch (e) {
        debugPrint('Error handling file:// URI: $e');
        return '';
      }
    }
    
    if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
      try {
        final uri = Uri.parse(filePath);
        // Verify the URI has a host
        if (!uri.hasScheme || uri.host.isEmpty) {
          debugPrint('Invalid URI format: $filePath');
          return '';
        }
        return filePath;
      } catch (e) {
        debugPrint('Error parsing URI: $e');
        return '';
      }
    }

    try {
      if (Platform.isWindows) {
        // For Windows, handle the path while preserving drive letters
        String normalizedPath = path.normalize(filePath);
        
        // Convert all slashes to backslashes
        normalizedPath = normalizedPath.replaceAll('/', '\\');
        
        // Handle drive letter if present
        if (normalizedPath.contains(':')) {
          final parts = normalizedPath.split(':');
          if (parts.length == 2) {
            // Ensure drive letter is uppercase
            normalizedPath = '${parts[0].toUpperCase()}:${parts[1]}';
          }
        }
        
        return normalizedPath;
      } else if (Platform.isAndroid) {
        // For Android, handle content URIs and file paths
        if (filePath.startsWith('content://')) {
          return filePath;
        }
        // Normalize the path but preserve content URIs
        return path.normalize(filePath);
      } else if (Platform.isIOS) {
        // For iOS, normalize the path
        return path.normalize(filePath);
      } else {
        // For other platforms, normalize the path
        return path.normalize(filePath);
      }
    } catch (e) {
      debugPrint('Error handling file path: $e');
      return '';
    }
  }

  /// Check if a path is a valid file path or content URI
  static bool isValidFilePath(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return true;
    }

    try {
      if (Platform.isAndroid && path.startsWith('content://')) {
        // Content URIs are valid on Android
        return true;
      }

      // For regular file paths
      final file = File(path);
      return file.existsSync();
    } catch (e) {
      debugPrint('Error checking file path: $e');
      return false;
    }
  }

  /// Get a display-friendly file name from a path
  static String getFileName(String filePath) {
    try {
      if (Platform.isAndroid && filePath.startsWith('content://')) {
        // For content URIs, just return the last segment
        return filePath.split('/').last;
      }
      return path.basename(filePath);
    } catch (e) {
      debugPrint('Error getting file name: $e');
      return filePath;
    }
  }

  /// Check if the path is a content URI (Android)
  static bool isContentUri(String path) {
    return Platform.isAndroid && path.startsWith('content://');
  }

  /// Check if the path is a temporary file path
  static bool isTemporaryPath(String path) {
    try {
      final normalized = path.toLowerCase();
      return normalized.contains('/temp/') ||
          normalized.contains('/temporary/') ||
          normalized.contains('/cache/');
    } catch (e) {
      debugPrint('Error checking temporary path: $e');
      return false;
    }
  }
}
