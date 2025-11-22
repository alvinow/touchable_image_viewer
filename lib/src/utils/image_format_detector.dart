import 'dart:typed_data';
import '../models/enums.dart';

/// Detects image format from filename extension or byte signature
class ImageFormatDetector {
  /// Detect format from filename extension
  static ImageFormat detectFromFilename(String? filename) {
    if (filename == null || filename.isEmpty) {
      return ImageFormat.unknown;
    }

    final extension = filename.toLowerCase().split('.').last;

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return ImageFormat.jpg;
      case 'png':
        return ImageFormat.png;
      case 'webp':
        return ImageFormat.webp;
      case 'gif':
        return ImageFormat.gif;
      case 'svg':
        return ImageFormat.svg;
      case 'dxf':
        return ImageFormat.dxf;
      case 'stl':
        return ImageFormat.stl;
      default:
        return ImageFormat.unknown;
    }
  }

  /// Detect format from byte signature (magic numbers)
  static ImageFormat detectFromBytes(Uint8List bytes) {
    if (bytes.length < 4) return ImageFormat.unknown;

    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return ImageFormat.jpg;
    }

    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return ImageFormat.png;
    }

    // GIF: 47 49 46 38
    if (bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return ImageFormat.gif;
    }

    // WebP: 52 49 46 46 ... 57 45 42 50
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return ImageFormat.webp;
    }

    // SVG: starts with '<' or '<?' (XML)
    if (bytes[0] == 0x3C) {
      final text = String.fromCharCodes(bytes.take(100));
      if (text.contains('<svg') || text.contains('<?xml')) {
        return ImageFormat.svg;
      }
    }

    // STL ASCII: "solid "
    if (bytes.length >= 6) {
      final text = String.fromCharCodes(bytes.take(6));
      if (text.toLowerCase() == 'solid ') {
        return ImageFormat.stl;
      }
    }

    // STL Binary: header check (80 bytes header + triangle count)
    if (bytes.length > 84) {
      // Binary STL files typically don't start with "solid"
      // and have specific structure
      return ImageFormat.stl;
    }

    // DXF: starts with "0\r\nSECTION" or similar
    if (bytes.length >= 10) {
      final text = String.fromCharCodes(bytes.take(20));
      if (text.contains('SECTION') || text.contains('HEADER') || text.contains('ENTITIES')) {
        return ImageFormat.dxf;
      }
    }

    return ImageFormat.unknown;
  }

  /// Detect format with fallback (bytes first, then filename)
  static ImageFormat detect({Uint8List? bytes, String? filename}) {
    if (bytes != null && bytes.isNotEmpty) {
      final format = detectFromBytes(bytes);
      if (format != ImageFormat.unknown) {
        return format;
      }
    }

    return detectFromFilename(filename);
  }

  /// Check if format is a raster image
  static bool isRasterImage(ImageFormat format) {
    return format == ImageFormat.jpg ||
        format == ImageFormat.png ||
        format == ImageFormat.webp ||
        format == ImageFormat.gif;
  }

  /// Check if format is vector-based
  static bool isVectorImage(ImageFormat format) {
    return format == ImageFormat.svg || format == ImageFormat.dxf;
  }

  /// Check if format is 3D
  static bool is3DFormat(ImageFormat format) {
    return format == ImageFormat.stl;
  }
}