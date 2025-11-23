import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:typed_data';
import '../../../models/image_source.dart';
import '../../../models/viewer_config.dart';
import '../../loading_widget.dart';
import '../../error_widget.dart';

/// Renderer for raster images (JPG, PNG, WebP, GIF)
class RasterImageRenderer extends StatelessWidget {
  final ImageSource imageSource;
  final ViewerConfig config;
  final VoidCallback? onImageLoaded;
  final Function(Object error)? onError;
  final VoidCallback? onRetry;

  const RasterImageRenderer({
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
      return _buildNetworkImage();
    } else {
      return _buildMemoryImage();
    }
  }

  Widget _buildNetworkImage() {
    if (config.enableCaching) {
      return CachedNetworkImage(
        imageUrl: imageSource.url!,
        httpHeaders: imageSource.headers,
        fit: BoxFit.contain,
        filterQuality: config.filterQuality,
        placeholder: (context, url) => LoadingWidget(
          type: config.loadingType,
          customWidget: config.customLoadingWidget,
        ),
        errorWidget: (context, url, error) {
          onError?.call(error);
          return ErrorDisplayWidget(
            type: config.errorHandlingType,
            customWidget: config.customErrorWidget,
            onRetry: onRetry,
            errorMessage: 'Failed to load image from network',
          );
        },
        imageBuilder: (context, imageProvider) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onImageLoaded?.call();
          });

          return Image(
            image: imageProvider,
            fit: BoxFit.contain,
            filterQuality: config.filterQuality,
            isAntiAlias: config.enableAntiAlias,
          );
        },
      );
    } else {
      return Image.network(
        imageSource.url!,
        headers: imageSource.headers,
        fit: BoxFit.contain,
        filterQuality: config.filterQuality,
        isAntiAlias: config.enableAntiAlias,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onImageLoaded?.call();
            });
            return child;
          }

          return LoadingWidget(
            type: config.loadingType,
            customWidget: config.customLoadingWidget,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          onError?.call(error);
          return ErrorDisplayWidget(
            type: config.errorHandlingType,
            customWidget: config.customErrorWidget,
            onRetry: onRetry,
            errorMessage: 'Failed to load image from network',
          );
        },
      );
    }
  }

  Widget _buildMemoryImage() {
    return Image.memory(
      imageSource.bytes!,
      fit: BoxFit.contain,
      filterQuality: config.filterQuality,
      isAntiAlias: config.enableAntiAlias,
      errorBuilder: (context, error, stackTrace) {
        onError?.call(error);
        return ErrorDisplayWidget(
          type: config.errorHandlingType,
          customWidget: config.customErrorWidget,
          onRetry: onRetry,
          errorMessage: 'Failed to load image from memory',
        );
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (frame != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onImageLoaded?.call();
          });
        }
        return child;
      },
    );
  }
}