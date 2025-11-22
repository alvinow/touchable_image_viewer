import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Controller for managing image viewer state and transformations
class ImageViewerController extends ChangeNotifier {
  final TransformationController _transformationController;
  final AnimationController _animationController;

  double _currentScale = 1.0;
  double _rotationAngle = 0.0; // in degrees
  Offset _position = Offset.zero;

  Size? _imageSize;
  Size? _containerSize;

  final double minScale;
  final double maxScale;

  bool _isAnimating = false;

  ImageViewerController({
    required TickerProvider vsync,
    this.minScale = 0.5,
    this.maxScale = 10.0,
  })  : _transformationController = TransformationController(),
        _animationController = AnimationController(
          vsync: vsync,
          duration: const Duration(milliseconds: 300),
        );

  TransformationController get transformationController => _transformationController;
  AnimationController get animationController => _animationController;

  double get currentScale => _currentScale;
  double get rotationAngle => _rotationAngle;
  Offset get position => _position;
  Size? get imageSize => _imageSize;
  bool get isAnimating => _isAnimating;

  /// Calculate the scale needed to fit image in container
  double calculateFitScale() {
    if (_imageSize == null || _containerSize == null) return 1.0;

    final scaleX = _containerSize!.width / _imageSize!.width;
    final scaleY = _containerSize!.height / _imageSize!.height;

    return math.min(scaleX, scaleY);
  }

  /// Set image and container sizes
  void setSizes({Size? imageSize, Size? containerSize}) {
    if (imageSize != null) _imageSize = imageSize;
    if (containerSize != null) _containerSize = containerSize;
    notifyListeners();
  }

  /// Update scale (called during gestures)
  void updateScale(double scale) {
    _currentScale = scale.clamp(minScale, maxScale);
    notifyListeners();
  }

  /// Update position (called during pan)
  void updatePosition(Offset position) {
    _position = position;
    notifyListeners();
  }

  /// Animate zoom to specific scale
  Future<void> animateZoomTo(double targetScale, {Offset? focalPoint}) async {
    if (_isAnimating) return;

    _isAnimating = true;
    targetScale = targetScale.clamp(minScale, maxScale);

    final Matrix4 begin = _transformationController.value;
    final Matrix4 end = Matrix4.identity();

    // Calculate focal point (default to center)
    final focal = focalPoint ?? Offset(
      (_containerSize?.width ?? 0) / 2,
      (_containerSize?.height ?? 0) / 2,
    );

    // Apply transformation with focal point
    end.translate(focal.dx, focal.dy);
    end.scale(targetScale);
    end.translate(-focal.dx, -focal.dy);

    final Animation<Matrix4> animation = Matrix4Tween(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    void listener() {
      _transformationController.value = animation.value;
      _currentScale = targetScale;
    }

    animation.addListener(listener);

    await _animationController.forward(from: 0.0);

    animation.removeListener(listener);
    _isAnimating = false;
    notifyListeners();
  }

  /// Reset to fit view
  Future<void> resetToFit() async {
    final fitScale = calculateFitScale();
    await animateZoomTo(fitScale);
  }

  /// Rotate image by 90 degrees
  Future<void> rotate90() async {
    _rotationAngle = (_rotationAngle + 90) % 360;
    notifyListeners();
  }

  /// Set rotation angle
  void setRotation(double angle) {
    _rotationAngle = angle % 360;
    notifyListeners();
  }

  /// Handle double tap - toggle between fit and 2x zoom
  Future<void> handleDoubleTap(Offset localPosition, double doubleTapScale) async {
    if (_isAnimating) return;

    final isZoomedIn = _currentScale > calculateFitScale() * 1.1;

    if (isZoomedIn) {
      // Reset to fit
      await resetToFit();
    } else {
      // Zoom to double tap scale at tap position
      await animateZoomTo(doubleTapScale, focalPoint: localPosition);
    }
  }

  /// Clamp scale within bounds
  double clampScale(double scale) {
    final fitScale = calculateFitScale();
    final effectiveMinScale = math.max(minScale, fitScale * 0.8);
    return scale.clamp(effectiveMinScale, maxScale);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}