import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Detects the platform and device type for optimal UI rendering
class PlatformDetector {
  /// Check if running on mobile device
  ///
  /// Uses screen width and user agent to determine if device is mobile
  static bool isMobile(BuildContext context, {double breakpoint = 768}) {
    if (!kIsWeb) return false; // Only relevant for web

    final width = MediaQuery.of(context).size.width;

    // Mobile if width is less than breakpoint
    return width < breakpoint;
  }

  /// Check if running on tablet device
  static bool isTablet(BuildContext context, {
    double mobileBreakpoint = 768,
    double desktopBreakpoint = 1024,
  }) {
    if (!kIsWeb) return false;

    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  /// Check if running on desktop device
  static bool isDesktop(BuildContext context, {double breakpoint = 768}) {
    if (!kIsWeb) return false;

    return !isMobile(context, breakpoint: breakpoint);
  }

  /// Get device type enum
  static DeviceType getDeviceType(BuildContext context, {
    double mobileBreakpoint = 768,
    double desktopBreakpoint = 1024,
  }) {
    final width = MediaQuery.of(context).size.width;

    if (width < mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (width < desktopBreakpoint) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Check if device has touch capability
  /// Note: Some devices have both touch and mouse (e.g., Windows touchscreen laptops)
  static bool hasTouchscreen() {
    if (!kIsWeb) return false;

    // Check via JavaScript interop if available
    // For now, return true on mobile, false on desktop
    return true; // Can be enhanced with JS interop
  }
}

/// Device type enumeration
enum DeviceType {
  mobile,
  tablet,
  desktop,
}