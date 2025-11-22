/// Image format types supported by the viewer
enum ImageFormat {
  jpg,
  png,
  webp,
  gif,
  svg,
  dxf,
  stl,
  unknown,
}

/// Loading indicator types
enum LoadingType {
  /// Default circular spinner
  spinner,

  /// Shimmer loading effect
  shimmer,

  /// Custom widget provided by user
  custom,
}

/// Error handling types
enum ErrorHandlingType {
  /// Show error icon with retry button
  iconWithRetry,

  /// Show custom error widget
  customWidget,

  /// Only trigger callback, no UI
  callbackOnly,
}

/// Toolbar position on screen
enum ToolbarPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

/// Background style for transparent images
enum BackgroundStyle {
  /// Checkered pattern (Photoshop-style)
  checkered,

  /// Solid color
  solid,

  /// Custom widget
  custom,
}