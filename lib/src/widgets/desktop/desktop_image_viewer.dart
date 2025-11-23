import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:math' as math;
import '../../models/image_source.dart';
import '../../models/viewer_config.dart';
import '../../models/enums.dart';
import '../../controllers/image_viewer_controller.dart';
import '../../painters/checkered_background_painter.dart';
import '../../utils/image_format_detector.dart';
import '../shared/renderers/raster_image_renderer.dart';
import '../shared/renderers/svg_renderer.dart';
import '../desktop/desktop_toolbar.dart';

/// Advanced Desktop/Web-optimized image viewer with pointer event handling
class DesktopImageViewer extends StatefulWidget {
  final ImageSource imageSource;
  final ViewerConfig config;

  final void Function(double scale)? onScaleChanged;
  final void Function()? onImageLoaded;
  final void Function(Object error)? onError;

  const DesktopImageViewer({
    Key? key,
    required this.imageSource,
    required this.config,
    this.onScaleChanged,
    this.onImageLoaded,
    this.onError,
  }) : super(key: key);

  @override
  State<DesktopImageViewer> createState() => _DesktopImageViewerState();
}

class _DesktopImageViewerState extends State<DesktopImageViewer>
    with TickerProviderStateMixin {
  late ImageViewerController _controller;
  late ImageFormat _imageFormat;

  BackgroundStyle _currentBackgroundStyle = BackgroundStyle.checkered;
  Color _currentBackgroundColor = Colors.white;

  // Advanced pointer tracking
  final Map<int, PointerEvent> _activePointers = {};
  PointerDeviceKind? _detectedDeviceKind;

  // Gesture state
  double _gestureStartScale = 1.0;
  double _currentScale = 1.0;
  Offset _gestureStartFocalPoint = Offset.zero;
  Offset _gestureStartTranslation = Offset.zero;
  Offset _previousFocalPoint = Offset.zero;

  // Zoom detection with velocity tracking
  double _previousScale = 1.0;
  double _scaleVelocity = 0.0;
  static const double _zoomVelocityThreshold = 0.005;

  // Pan state
  Offset _currentTranslation = Offset.zero;
  Offset _previousPointerDelta = Offset.zero;

  // Inertia with adaptive dampening
  Offset _velocity = Offset.zero;
  Offset _lastPanPosition = Offset.zero;
  DateTime _lastPanTime = DateTime.now();
  AnimationController? _momentumController;
  Animation<Offset>? _momentumAnimation;

  // Reset animation
  AnimationController? _resetController;
  Animation<Matrix4>? _resetAnimation;

  bool _isImageLoaded = false;

  @override
  void initState() {
    super.initState();
    _controller = ImageViewerController(
      vsync: this,
      minScale: widget.config.minScale,
      maxScale: widget.config.maxScale,
    );

    _currentBackgroundStyle = widget.config.backgroundStyle;
    _currentBackgroundColor = widget.config.backgroundColor ?? Colors.white;

    _imageFormat = ImageFormatDetector.detect(
      bytes: widget.imageSource.bytes,
      filename: widget.imageSource.effectiveFilename,
    );

    _momentumController = AnimationController(vsync: this);
    _resetController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _momentumController?.dispose();
    _resetController?.dispose();
    _controller.dispose();
    _activePointers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _controller.setSizes(
          containerSize: Size(constraints.maxWidth, constraints.maxHeight),
        );

        return Stack(
          children: [
            _buildBackground(),
            _buildAdvancedImageViewer(),
            if (widget.config.showToolbar)
              DesktopToolbar(
                config: widget.config,
                onRotate: widget.config.enableRotation && !_is3DFormat()
                    ? () => _controller.rotate90()
                    : null,
                onBackgroundColorChanged: _handleBackgroundColorChanged,
                onBackgroundStyleChanged: _handleBackgroundStyleChanged,
                show3DControls: _is3DFormat(),
                currentBackgroundColor: _currentBackgroundColor,
                currentBackgroundStyle: _currentBackgroundStyle,
              ),
          ],
        );
      },
    );
  }

  /// Advanced image viewer with pointer tracking and pan-zoom support
  Widget _buildAdvancedImageViewer() {
    return Listener(
      // Raw pointer event handling for max precision on web
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      onPointerSignal: _handlePointerSignal,
      // Pan-zoom support (Flutter 3.4+, trackpad gestures)
      onPointerPanZoomStart: widget.config.enableZoom
          ? _handlePanZoomStart
          : null,
      onPointerPanZoomUpdate: widget.config.enableZoom
          ? _handlePanZoomUpdate
          : null,
      onPointerPanZoomEnd: widget.config.enableZoom
          ? _handlePanZoomEnd
          : null,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onScaleStart: widget.config.enableZoom || widget.config.enablePan
            ? _handleScaleStart
            : null,
        onScaleUpdate: widget.config.enableZoom || widget.config.enablePan
            ? _handleScaleUpdate
            : null,
        onScaleEnd: widget.config.enableZoom || widget.config.enablePan
            ? _handleScaleEnd
            : null,
        onDoubleTapDown: widget.config.enableDoubleTap
            ? (details) => _handleDoubleTap(details.localPosition)
            : null,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _controller,
            _momentumController!,
            _resetController!,
          ]),
          builder: (context, child) {
            return Transform(
              transform: _controller.transformationController.value,
              alignment: Alignment.center,
              child: Transform.rotate(
                angle: _controller.rotationAngle * math.pi / 180,
                alignment: Alignment.center,
                child: _buildImageRenderer(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: RepaintBoundary(
        child: _buildBackgroundWidget(),
      ),
    );
  }

  Widget _buildBackgroundWidget() {
    switch (_currentBackgroundStyle) {
      case BackgroundStyle.checkered:
        return CustomPaint(
          painter: CheckeredBackgroundPainter(
            color1: widget.config.checkerColor1,
            color2: widget.config.checkerColor2,
            squareSize: widget.config.checkerSize,
          ),
        );
      case BackgroundStyle.solid:
        return Container(color: _currentBackgroundColor);
      case BackgroundStyle.custom:
        return Container(color: _currentBackgroundColor);
    }
  }

  Widget _buildImageRenderer() {
    if (ImageFormatDetector.isRasterImage(_imageFormat)) {
      return RasterImageRenderer(
        imageSource: widget.imageSource,
        config: widget.config,
        onImageLoaded: _handleImageLoaded,
        onError: _handleError,
        onRetry: _handleRetry,
      );
    } else if (_imageFormat == ImageFormat.svg) {
      return SvgRenderer(
        imageSource: widget.imageSource,
        config: widget.config,
        onImageLoaded: _handleImageLoaded,
        onError: _handleError,
        onRetry: _handleRetry,
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Format ${_imageFormat.name.toUpperCase()} renderer coming soon',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
  }

  // ============== POINTER EVENT HANDLING ==============

  void _handlePointerDown(PointerDownEvent event) {
    _activePointers[event.pointer] = event;
    _detectedDeviceKind = event.kind;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    _activePointers[event.pointer] = event;

    // Track raw pointer delta for velocity calculation
    _previousPointerDelta = event.localDelta;
    _lastPanTime = DateTime.now();
  }

  void _handlePointerUp(PointerUpEvent event) {
    _activePointers.remove(event.pointer);

    // Apply momentum if all pointers released and velocity is high
    if (_activePointers.isEmpty && _velocity.distance > 100) {
      _startMomentumAnimation();
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _activePointers.remove(event.pointer);
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent && widget.config.enableZoom) {
      _handleMouseWheel(event);
    }
  }

  // ============== PAN-ZOOM GESTURE SUPPORT (Trackpad) ==============

  void _handlePanZoomStart(PointerPanZoomStartEvent event) {
    _momentumController?.stop();
    _resetController?.stop();
    _detectedDeviceKind = PointerDeviceKind.trackpad;
    _gestureStartScale = _currentScale;
    _gestureStartTranslation = _currentTranslation;
  }

  void _handlePanZoomUpdate(PointerPanZoomUpdateEvent event) {
    setState(() {
      // Trackpad pan-zoom combines both operations
      final newScale = _controller.clampScale(
        _gestureStartScale * event.scale,
      );

      // Apply translation from pan
      final newTranslation = _gestureStartTranslation + event.pan;

      _currentScale = newScale;
      _currentTranslation = newTranslation;

      // Update transformation matrix
      final matrix = Matrix4.identity();
      matrix.translate(newTranslation.dx, newTranslation.dy);
      matrix.scale(newScale);
      _controller.transformationController.value = matrix;

      _controller.updateScale(_currentScale);
      widget.onScaleChanged?.call(_currentScale);
    });
  }

  void _handlePanZoomEnd(PointerPanZoomEndEvent event) {
    _animateResetToFit();
  }

  // ============== TRADITIONAL GESTURE HANDLING ==============

  void _handleScaleStart(ScaleStartDetails details) {
    _momentumController?.stop();
    _resetController?.stop();

    _gestureStartScale = _currentScale;
    _previousScale = 1.0;
    _scaleVelocity = 0.0;
    _gestureStartFocalPoint = details.focalPoint;
    _previousFocalPoint = details.focalPoint;

    _lastPanPosition = details.focalPoint;
    _lastPanTime = DateTime.now();
    _velocity = Offset.zero;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final now = DateTime.now();

    // Velocity-based zoom detection (instead of frame counting)
    _scaleVelocity = (details.scale - _previousScale).abs();
    final isZoomGesture = _scaleVelocity > _zoomVelocityThreshold;

    _previousScale = details.scale;

    setState(() {
      if (widget.config.enableZoom && isZoomGesture) {
        _handleZoomWithFocalPoint(details);
      } else if (widget.config.enablePan && !isZoomGesture) {
        _handlePanWithMomentum(details, now);
      }
    });

    _previousFocalPoint = details.focalPoint;
  }

  void _handleZoomWithFocalPoint(ScaleUpdateDetails details) {
    final newScale = _gestureStartScale * details.scale;
    final clampedScale = _controller.clampScale(newScale);
    final focalPoint = details.localFocalPoint;

    // Build matrix: zoom toward focal point with translation preservation
    final matrix = Matrix4.identity();
    matrix.translate(focalPoint.dx, focalPoint.dy);
    matrix.scale(clampedScale);
    matrix.translate(
      _currentTranslation.dx / clampedScale,
      _currentTranslation.dy / clampedScale,
    );
    matrix.translate(-focalPoint.dx, -focalPoint.dy);

    _currentScale = clampedScale;
    _controller.transformationController.value = matrix;
    _controller.updateScale(_currentScale);
    widget.onScaleChanged?.call(_currentScale);
  }

  void _handlePanWithMomentum(ScaleUpdateDetails details, DateTime now) {
    // Calculate velocity for momentum
    final timeDelta = now.difference(_lastPanTime).inMilliseconds;
    if (timeDelta > 0) {
      final delta = details.focalPoint - _lastPanPosition;
      _velocity = Offset(
        delta.dx / timeDelta * 1000,
        delta.dy / timeDelta * 1000,
      );
    }

    _lastPanPosition = details.focalPoint;
    _lastPanTime = now;

    final panDelta = details.focalPoint - _previousFocalPoint;
    _currentTranslation += panDelta;

    final matrix = Matrix4.identity();
    matrix.translate(_currentTranslation.dx, _currentTranslation.dy);
    matrix.scale(_currentScale);
    _controller.transformationController.value = matrix;
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    final velocityMagnitude = _velocity.distance;

    if (velocityMagnitude > 100 && !(_scaleVelocity > _zoomVelocityThreshold)) {
      _startMomentumAnimation();
    } else {
      _animateResetToFit();
    }
  }

  // ============== MOUSE WHEEL HANDLING ==============

  void _handleMouseWheel(PointerScrollEvent event) {
    final scrollDelta = event.scrollDelta.dy;
    final zoomMultiplier = scrollDelta > 0 ? 0.9 : 1.1;
    final newScale = _controller.clampScale(_currentScale * zoomMultiplier);

    setState(() {
      _currentScale = newScale;

      final focal = event.localPosition;
      final matrix = Matrix4.identity();
      matrix.translate(focal.dx, focal.dy);
      matrix.scale(_currentScale);
      matrix.translate(
        _currentTranslation.dx / _currentScale,
        _currentTranslation.dy / _currentScale,
      );
      matrix.translate(-focal.dx, -focal.dy);

      _controller.transformationController.value = matrix;
      _controller.updateScale(_currentScale);
      widget.onScaleChanged?.call(_currentScale);
    });
  }

  // ============== MOMENTUM & ANIMATIONS ==============

  void _startMomentumAnimation() {
    _momentumController!.reset();

    final duration = (100 + (_velocity.distance * 2).clamp(0.0, 400.0)).toInt();
    _momentumController!.duration = Duration(milliseconds: duration);

    final friction = _detectedDeviceKind == PointerDeviceKind.trackpad
        ? 0.92
        : 0.94;

    final startTranslation = _currentTranslation;
    final momentumDistance = _velocity * (duration / 1000) * 0.5;
    final endTranslation = startTranslation + momentumDistance;

    _momentumAnimation = Tween<Offset>(
      begin: startTranslation,
      end: endTranslation,
    ).animate(CurvedAnimation(
      parent: _momentumController!,
      curve: Curves.decelerate,
    ));

    _momentumController!.addListener(() {
      setState(() {
        _currentTranslation = _momentumAnimation!.value;

        final matrix = Matrix4.identity();
        matrix.translate(_currentTranslation.dx, _currentTranslation.dy);
        matrix.scale(_currentScale);
        _controller.transformationController.value = matrix;
      });
    });

    _momentumController!.forward().then((_) {
      _animateResetToFit();
    });
  }

  void _animateResetToFit() {
    _resetController!.reset();
    _resetController!.duration = const Duration(milliseconds: 400);

    final startMatrix = _controller.transformationController.value;
    final endMatrix = Matrix4.identity();

    _resetAnimation = Matrix4Tween(
      begin: startMatrix,
      end: endMatrix,
    ).animate(CurvedAnimation(
      parent: _resetController!,
      curve: Curves.easeInOut,
    ));

    _resetController!.addListener(() {
      setState(() {
        _controller.transformationController.value = _resetAnimation!.value;
        final scaleX = _resetAnimation!.value.getMaxScaleOnAxis();
        _currentScale = scaleX;
        _controller.updateScale(_currentScale);
        widget.onScaleChanged?.call(_currentScale);
      });
    });

    _resetController!.forward().then((_) {
      _currentScale = 1.0;
      _currentTranslation = Offset.zero;
      _controller.resetToFit();
    });
  }

  void _handleDoubleTap(Offset localPosition) {
    _controller.handleDoubleTap(
      localPosition,
      widget.config.doubleTapScale,
    );
  }

  void _handleImageLoaded() {
    setState(() {
      _isImageLoaded = true;
    });
    widget.onImageLoaded?.call();

    if (widget.config.autoFitOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.resetToFit();
      });
    }
  }

  void _handleError(Object error) {
    widget.onError?.call(error);
  }

  void _handleRetry() {
    setState(() {
      _isImageLoaded = false;
    });
  }

  void _handleBackgroundColorChanged(Color color) {
    setState(() {
      _currentBackgroundColor = color;
    });
  }

  void _handleBackgroundStyleChanged(BackgroundStyle style) {
    setState(() {
      _currentBackgroundStyle = style;
    });
  }

  bool _is3DFormat() {
    return ImageFormatDetector.is3DFormat(_imageFormat);
  }
}