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

/// Desktop-optimized image viewer with mouse and touchpad support
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

  double _baseScale = 1.0;
  double _currentScale = 1.0;
  Offset _previousFocalPoint = Offset.zero;

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
  }

  @override
  void dispose() {
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
          animation: _controller,
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
    _baseScale = _currentScale;
    _previousFocalPoint = details.focalPoint;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      if (widget.config.enableZoom && details.scale != 1.0) {
        // Touchscreen pinch or trackpad gesture
        final newScale = _baseScale * details.scale;
        _currentScale = _controller.clampScale(newScale);

        final matrix = Matrix4.identity();
        final focal = details.localFocalPoint;
        matrix.translate(focal.dx, focal.dy);
        matrix.scale(_currentScale);
        matrix.translate(-focal.dx, -focal.dy);

        _controller.transformationController.value = matrix;
        _controller.updateScale(_currentScale);

        widget.onScaleChanged?.call(_currentScale);
      } else if (widget.config.enablePan && _currentScale > 1.0) {
        // Click and drag to pan
        final delta = details.focalPoint - _previousFocalPoint;
        final currentMatrix = _controller.transformationController.value;

        final newMatrix = Matrix4.copy(currentMatrix)
          ..translate(delta.dx, delta.dy);

        _controller.transformationController.value = newMatrix;
        _previousFocalPoint = details.focalPoint;
      }
    });
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    // Could add momentum animation
  }

  void _handleDoubleTap(Offset localPosition) {
    _controller.handleDoubleTap(
      localPosition,
      widget.config.doubleTapScale,
    );
  }

  void _handleMouseScroll(PointerScrollEvent event) {
    // Mouse wheel zoom
    final delta = event.scrollDelta.dy;
    final zoomChange = delta > 0 ? 0.9 : 1.1;

    final newScale = _controller.clampScale(_currentScale * zoomChange);

    setState(() {
      _currentScale = newScale;

      final matrix = Matrix4.identity();
      final focal = event.localPosition;
      matrix.translate(focal.dx, focal.dy);
      matrix.scale(_currentScale);
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