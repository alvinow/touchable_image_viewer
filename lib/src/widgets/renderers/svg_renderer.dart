import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:typed_data';
import '../../models/image_source.dart';
import '../../models/viewer_config.dart';
import '../loading_widget.dart';
import '../error_widget.dart';

/// Renderer for SVG images
class SvgRenderer extends StatelessWidget {
  final ImageSource imageSource;
  final ViewerConfig config;
  final VoidCallback? onImageLoaded;
  final Function(Object error)? onError;
  final VoidCallback? onRetry;

  const SvgRenderer({
    Key? key,
    required this.imageSource,
    required this.config,
    this.onImageLoaded,
    this.onError,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageSource.type == ImageSourceType.network) {
      return _buildNetworkSvg();
    } else {
      return _buildMemorySvg();
    }
  }

  Widget _buildNetworkSvg() {
    return SvgPicture.network(
      imageSource.url!,
      headers: imageSource.headers,
      fit: BoxFit.contain,
      placeholderBuilder: (context) => LoadingWidget(
        type: config.loadingType,
        customWidget: config.customLoadingWidget,
      ),
    );
  }

  Widget _buildMemorySvg() {
    return SvgPicture.memory(
      imageSource.bytes!,
      fit: BoxFit.contain,
      placeholderBuilder: (context) => LoadingWidget(
        type: config.loadingType,
        customWidget: config.customLoadingWidget,
      ),
    );
  }
}