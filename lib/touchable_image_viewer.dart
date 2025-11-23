/// A powerful Flutter web image viewer widget with Instagram-like gestures
///
/// This package provides a high-performance image viewer supporting multiple
/// formats (JPG, PNG, WebP, GIF, SVG) with touch gestures, zoom, pan, rotation,
/// and customizable UI.
///
/// ## Features
/// - Multi-format support: JPG, PNG, WebP, GIF, SVG (DXF & STL coming in Phase 2)
/// - Instagram-like gestures: pinch-to-zoom, double-tap, pan
/// - Desktop support: mouse wheel zoom, click-drag
/// - Image rotation (90° increments)
/// - Customizable backgrounds (checkered pattern for transparency)
/// - JWT/Bearer token authentication support
/// - Loading states (spinner, shimmer, custom)
/// - Error handling (retry, custom widget, callback)
/// - High performance with caching
///
/// ## Quick Start
///
/// ```dart
/// import 'package:touchable_image_viewer/touchable_image_viewer.dart';
///
/// TouchableImageViewer(
///   imageSource: ImageSource.network('https://example.com/image.jpg'),
/// )
/// ```
///
/// ## With Authentication
///
/// ```dart
/// TouchableImageViewer(
///   imageSource: ImageSource.network(
///     'https://api.example.com/image.jpg',
///     headers: {'Authorization': 'Bearer $token'},
///   ),
/// )
/// ```
///
/// ## With Full Configuration
///
/// ```dart
/// TouchableImageViewer(
///   imageSource: ImageSource.network('https://example.com/photo.png'),
///   config: ViewerConfig(
///     minScale: 0.5,
///     maxScale: 10.0,
///     autoFitOnLoad: true,
///     enableDoubleTap: true,
///     backgroundStyle: BackgroundStyle.checkered,
///     showToolbar: true,
///   ),
///   onScaleChanged: (scale) => print('Zoom: ${scale}x'),
///   onImageLoaded: () => print('Loaded!'),
///   onError: (error) => print('Error: $error'),
/// )
/// ```
library touchable_image_viewer;

// Main widget
export 'src/widgets/touchable_image_viewer_widget.dart';

// Controllers
export 'src/controllers/image_viewer_controller.dart';

// Models
export 'src/models/image_source.dart';
export 'src/models/viewer_config.dart';
export 'src/models/enums.dart';

// Utilities (exposed for advanced usage)
export 'src/utils/image_format_detector.dart';
export 'src/utils/platform_detector.dart';