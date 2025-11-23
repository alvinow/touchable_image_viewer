import 'package:flutter/material.dart';
import '../models/image_source.dart';
import '../models/viewer_config.dart';
import '../utils/platform_detector.dart';
import 'mobile/mobile_image_viewer.dart';
import 'desktop/desktop_image_viewer.dart';

/// Main touchable image viewer widget that routes to platform-specific implementations
///
/// Automatically detects if the device is mobile or desktop and renders
/// the appropriate optimized version:
/// - Mobile: Touch-optimized with larger buttons, bottom sheet dialogs
/// - Desktop: Mouse/touchpad optimized with compact UI, scroll wheel zoom
class TouchableImageViewer extends StatelessWidget {
  final ImageSource imageSource;
  final ViewerConfig config;

  // Callbacks
  final void Function(double scale)? onScaleChanged;
  final void Function()? onImageLoaded;
  final void Function(Object error)? onError;

  const TouchableImageViewer({
    Key? key,
    required this.imageSource,
    ViewerConfig? config,
    this.onScaleChanged,
    this.onImageLoaded,
    this.onError,
  })  : config = config ?? const ViewerConfig(),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    // Detect platform and route to appropriate implementation
    final isMobile = PlatformDetector.isMobile(
      context,
      breakpoint: config.mobileBreakpoint,
    );

    if (isMobile) {
      // Mobile-optimized implementation
      return MobileImageViewer(
        imageSource: imageSource,
        config: config,
        onScaleChanged: onScaleChanged,
        onImageLoaded: onImageLoaded,
        onError: onError,
      );
    } else {
      // Desktop-optimized implementation
      return DesktopImageViewer(
        imageSource: imageSource,
        config: config,
        onScaleChanged: onScaleChanged,
        onImageLoaded: onImageLoaded,
        onError: onError,
      );
    }
  }
}