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

/// Desktop-optimized image viewer with improved multi-touch support
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

  // Gesture state
  double _gestureStartScale = 1.0;
  double _currentScale = 1.0;
  Offset _gestureStartFocalPoint = Offset.zero;
  Offset _previousFocalPoint = Offset.zero;

  // Zoom detection
  double _previousScale = 1.0;
  bool _isZooming = false;
  int _zoomStableFrames = 0;
  static const int _zoomStableThreshold = 3; // Frames before considering zoom stopped

  // Pan state
  Offset _currentTranslation = Offset.zero;

  // Momentum/Inertia
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

    // Initialize momentum controller
    _momentumController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Initialize reset controller
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _momentumController?.dispose();
    _resetController?.dispose();
    _controller.dispose();
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
            _buildImageViewer(),
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

  Widget _buildImageViewer() {
    return GestureDetector(
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
      child: Listener(
        onPointerSignal: (event) {
          if (event is PointerScrollEvent && widget.config.enableZoom) {
            _handleMouseScroll(event);
          }
        },
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

  void _handleScaleStart(ScaleStartDetails details) {
    // Cancel any ongoing animations
    _momentumController?.stop();
    _resetController?.stop();

    _gestureStartScale = _currentScale;
    _previousScale = 1.0;
    _gestureStartFocalPoint = details.focalPoint;
    _previousFocalPoint = details.focalPoint;
    _isZooming = false;
    _zoomStableFrames = 0;

    // Initialize pan tracking
    _lastPanPosition = details.focalPoint;
    _lastPanTime = DateTime.now();
    _velocity = Offset.zero;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final now = DateTime.now();

    // Detect if zooming is happening
    final scaleChanged = (details.scale - _previousScale).abs() > 0.001;

    if (scaleChanged) {
      _isZooming = true;
      _zoomStableFrames = 0;
    } else {
      _zoomStableFrames++;
      if (_zoomStableFrames >= _zoomStableThreshold) {
        _isZooming = false;
      }
    }

    _previousScale = details.scale;

    setState(() {
      // PHASE 1: Handle Zoom (priority)
      if (widget.config.enableZoom && _isZooming) {
        _handleZoom(details);
      }
      // PHASE 2: Handle Pan (only when zoom is stable)
      else if (widget.config.enablePan && !_isZooming) {
        _handlePan(details, now);
      }
    });

    _previousFocalPoint = details.focalPoint;
  }

  void _handleZoom(ScaleUpdateDetails details) {
    // Calculate new scale
    final newScale = _gestureStartScale * details.scale;
    final clampedScale = _controller.clampScale(newScale);

    // Get the focal point in local coordinates
    final focalPoint = details.localFocalPoint;

    // Build transformation matrix that zooms toward focal point
    final matrix = Matrix4.identity();

    // 1. Translate so focal point is at origin
    matrix.translate(focalPoint.dx, focalPoint.dy);

    // 2. Apply scale
    matrix.scale(clampedScale);

    // 3. Apply current translation (preserve pan)
    matrix.translate(_currentTranslation.dx / clampedScale,
        _currentTranslation.dy / clampedScale);

    // 4. Translate back
    matrix.translate(-focalPoint.dx, -focalPoint.dy);

    _currentScale = clampedScale;
    _controller.transformationController.value = matrix;
    _controller.updateScale(_currentScale);

    widget.onScaleChanged?.call(_currentScale);
  }

  void _handlePan(ScaleUpdateDetails details, DateTime now) {
    // Calculate velocity for momentum
    final timeDelta = now.difference(_lastPanTime).inMilliseconds;
    if (timeDelta > 0) {
      final delta = details.focalPoint - _lastPanPosition;
      _velocity = Offset(
        delta.dx / timeDelta * 1000, // pixels per second
        delta.dy / timeDelta * 1000,
      );
    }

    _lastPanPosition = details.focalPoint;
    _lastPanTime = now;

    // Calculate pan delta
    final delta = details.focalPoint - _previousFocalPoint;
    _currentTranslation += delta;

    // Apply transformation with current scale and translation
    final matrix = Matrix4.identity();
    matrix.translate(_currentTranslation.dx, _currentTranslation.dy);
    matrix.scale(_currentScale);

    _controller.transformationController.value = matrix;
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    // Start momentum animation if velocity is significant
    final velocityMagnitude = _velocity.distance;

    if (velocityMagnitude > 50 && !_isZooming) {
      _startMomentumAnimation();
    } else {
      // No significant momentum, just reset
      _animateResetToFit();
    }
  }

  void _startMomentumAnimation() {
    _momentumController!.reset();

    // Calculate deceleration (friction)
    final friction = 0.95; // Decay factor per frame at 60fps
    final duration = 500; // milliseconds

    final startTranslation = _currentTranslation;
    final velocityDecay = math.pow(friction, duration / 16.67); // ~60fps

    // Calculate end position based on velocity with decay
    final momentumDistance = Offset(
      _velocity.dx * duration / 1000 * (1 - velocityDecay) / (1 - friction),
      _velocity.dy * duration / 1000 * (1 - velocityDecay) / (1 - friction),
    );

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
      // After momentum, reset to fit
      _animateResetToFit();
    });
  }

  void _animateResetToFit() {
    _resetController!.reset();

    final startMatrix = _controller.transformationController.value;
    final endMatrix = Matrix4.identity(); // Reset to fit

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

        // Extract scale from matrix for callbacks
        final matrix = _resetAnimation!.value;
        final scaleX = matrix.getMaxScaleOnAxis();
        _currentScale = scaleX;
        _controller.updateScale(_currentScale);

        widget.onScaleChanged?.call(_currentScale);
      });
    });

    _resetController!.forward().then((_) {
      // Reset state
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

  void _handleMouseScroll(PointerScrollEvent event) {
    // Mouse wheel zoom - zoom toward cursor
    final delta = event.scrollDelta.dy;
    final zoomChange = delta > 0 ? 0.9 : 1.1;

    final newScale = _controller.clampScale(_currentScale * zoomChange);
    final focal = event.localPosition;

    setState(() {
      _currentScale = newScale;

      final matrix = Matrix4.identity();
      matrix.translate(focal.dx, focal.dy);
      matrix.scale(_currentScale);
      matrix.translate(_currentTranslation.dx / _currentScale,
          _currentTranslation.dy / _currentScale);
      matrix.translate(-focal.dx, -focal.dy);

      _controller.transformationController.value = matrix;
      _controller.updateScale(_currentScale);

      widget.onScaleChanged?.call(_currentScale);
    });
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