import 'dart:typed_data';

/// Represents the source of an image for the viewer
class ImageSource {
  final ImageSourceType type;
  final String? url;
  final Uint8List? bytes;
  final String? filename;
  final Map<String, String>? headers;

  const ImageSource._({
    required this.type,
    this.url,
    this.bytes,
    this.filename,
    this.headers,
  });

  /// Create image source from network URL
  ///
  /// [headers] can be used to add authentication tokens, e.g.:
  /// ```dart
  /// ImageSource.network(
  ///   'https://api.example.com/image.jpg',
  ///   headers: {'Authorization': 'Bearer $jwtToken'},
  /// )
  /// ```
  factory ImageSource.network(
      String url, {
        String? filename,
        Map<String, String>? headers,
      }) {
    return ImageSource._(
      type: ImageSourceType.network,
      url: url,
      filename: filename,
      headers: headers,
    );
  }

  /// Create image source from memory buffer
  factory ImageSource.memory(Uint8List bytes, {String? filename}) {
    return ImageSource._(
      type: ImageSourceType.memory,
      bytes: bytes,
      filename: filename,
    );
  }

  /// Get the filename for format detection
  String? get effectiveFilename => filename ?? _extractFilenameFromUrl();

  String? _extractFilenameFromUrl() {
    if (url == null) return null;
    try {
      final uri = Uri.parse(url!);
      final segments = uri.pathSegments;
      return segments.isNotEmpty ? segments.last : null;
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() {
    return 'ImageSource(type: $type, url: $url, filename: $filename, hasBytes: ${bytes != null})';
  }
}

enum ImageSourceType {
  network,
  memory,
}