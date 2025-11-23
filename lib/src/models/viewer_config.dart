import 'package:flutter/material.dart';
import 'enums.dart';

/// Configuration for the TouchableImageViewer widget
class ViewerConfig {
  // Zoom configuration
  final double minScale;
  final double maxScale;
  final bool autoFitOnLoad;

  // Gesture configuration
  final bool enableDoubleTap;
  final double doubleTapScale;
  final bool enableRotation;
  final bool enablePan;
  final bool enableZoom;

  // Background configuration
  final BackgroundStyle backgroundStyle;
  final Color? backgroundColor;
  final Color checkerColor1;
  final Color checkerColor2;
  final double checkerSize;

  // Toolbar configuration
  final bool showToolbar;
  final ToolbarPosition toolbarPosition;
  final bool showBackgroundButton;
  final bool showRotateButton;

  // Loading configuration
  final LoadingType loadingType;
  final Widget? customLoadingWidget;

  // Error handling configuration
  final ErrorHandlingType errorHandlingType;
  final Widget? customErrorWidget;

  // Performance
  final FilterQuality filterQuality;
  final bool enableAntiAlias;
  final bool enableCaching;

  // Platform detection
  final double mobileBreakpoint;
  final double desktopBreakpoint;

  const ViewerConfig({
    this.mobileBreakpoint=768,
    this.desktopBreakpoint=1024,

    // Zoom
    this.minScale = 0.5,
    this.maxScale = 10.0,
    this.autoFitOnLoad = true,

    // Gestures
    this.enableDoubleTap = true,
    this.doubleTapScale = 2.0,
    this.enableRotation = true,
    this.enablePan = true,
    this.enableZoom = true,

    // Background
    this.backgroundStyle = BackgroundStyle.checkered,
    this.backgroundColor,
    this.checkerColor1 = const Color(0xFFCCCCCC),
    this.checkerColor2 = const Color(0xFFFFFFFF),
    this.checkerSize = 10.0,

    // Toolbar
    this.showToolbar = true,
    this.toolbarPosition = ToolbarPosition.bottomRight,
    this.showBackgroundButton = true,
    this.showRotateButton = true,

    // Loading
    this.loadingType = LoadingType.spinner,
    this.customLoadingWidget,

    // Error
    this.errorHandlingType = ErrorHandlingType.iconWithRetry,
    this.customErrorWidget,

    // Performance
    this.filterQuality = FilterQuality.high,
    this.enableAntiAlias = true,
    this.enableCaching = true,
  });

  ViewerConfig copyWith({
    double? minScale,
    double? maxScale,
    bool? autoFitOnLoad,
    bool? enableDoubleTap,
    double? doubleTapScale,
    bool? enableRotation,
    bool? enablePan,
    bool? enableZoom,
    BackgroundStyle? backgroundStyle,
    Color? backgroundColor,
    Color? checkerColor1,
    Color? checkerColor2,
    double? checkerSize,
    bool? showToolbar,
    ToolbarPosition? toolbarPosition,
    bool? showBackgroundButton,
    bool? showRotateButton,
    LoadingType? loadingType,
    Widget? customLoadingWidget,
    ErrorHandlingType? errorHandlingType,
    Widget? customErrorWidget,
    FilterQuality? filterQuality,
    bool? enableAntiAlias,
    bool? enableCaching,
  }) {
    return ViewerConfig(
      minScale: minScale ?? this.minScale,
      maxScale: maxScale ?? this.maxScale,
      autoFitOnLoad: autoFitOnLoad ?? this.autoFitOnLoad,
      enableDoubleTap: enableDoubleTap ?? this.enableDoubleTap,
      doubleTapScale: doubleTapScale ?? this.doubleTapScale,
      enableRotation: enableRotation ?? this.enableRotation,
      enablePan: enablePan ?? this.enablePan,
      enableZoom: enableZoom ?? this.enableZoom,
      backgroundStyle: backgroundStyle ?? this.backgroundStyle,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      checkerColor1: checkerColor1 ?? this.checkerColor1,
      checkerColor2: checkerColor2 ?? this.checkerColor2,
      checkerSize: checkerSize ?? this.checkerSize,
      showToolbar: showToolbar ?? this.showToolbar,
      toolbarPosition: toolbarPosition ?? this.toolbarPosition,
      showBackgroundButton: showBackgroundButton ?? this.showBackgroundButton,
      showRotateButton: showRotateButton ?? this.showRotateButton,
      loadingType: loadingType ?? this.loadingType,
      customLoadingWidget: customLoadingWidget ?? this.customLoadingWidget,
      errorHandlingType: errorHandlingType ?? this.errorHandlingType,
      customErrorWidget: customErrorWidget ?? this.customErrorWidget,
      filterQuality: filterQuality ?? this.filterQuality,
      enableAntiAlias: enableAntiAlias ?? this.enableAntiAlias,
      enableCaching: enableCaching ?? this.enableCaching,
    );
  }
}