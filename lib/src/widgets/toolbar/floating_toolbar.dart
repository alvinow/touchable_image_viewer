import 'package:flutter/material.dart';
import '../../models/enums.dart';
import '../../models/viewer_config.dart';
import 'background_picker.dart';

/// Floating toolbar with background and rotation controls
class FloatingToolbar extends StatelessWidget {
  final ViewerConfig config;
  final VoidCallback? onRotate;
  final Function(Color) onBackgroundColorChanged;
  final Function(BackgroundStyle) onBackgroundStyleChanged;
  final bool show3DControls;
  final Color currentBackgroundColor;
  final BackgroundStyle currentBackgroundStyle;

  const FloatingToolbar({
    Key? key,
    required this.config,
    this.onRotate,
    required this.onBackgroundColorChanged,
    required this.onBackgroundStyleChanged,
    this.show3DControls = false,
    required this.currentBackgroundColor,
    required this.currentBackgroundStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: _getBottom(),
      right: _getRight(),
      top: _getTop(),
      left: _getLeft(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Background color button
          if (config.showBackgroundButton)
            _ToolbarButton(
              icon: Icons.palette,
              tooltip: 'Background',
              onPressed: () => _showBackgroundPicker(context),
            ),

          if (config.showBackgroundButton && config.showRotateButton && !show3DControls)
            const SizedBox(height: 8),

          // Rotate button (only for 2D images)
          if (config.showRotateButton && !show3DControls && onRotate != null)
            _ToolbarButton(
              icon: Icons.rotate_90_degrees_ccw,
              tooltip: 'Rotate',
              onPressed: onRotate!,
            ),
        ],
      ),
    );
  }

  double? _getBottom() {
    switch (config.toolbarPosition) {
      case ToolbarPosition.bottomLeft:
      case ToolbarPosition.bottomRight:
        return 16.0;
      default:
        return null;
    }
  }

  double? _getRight() {
    switch (config.toolbarPosition) {
      case ToolbarPosition.topRight:
      case ToolbarPosition.bottomRight:
        return 16.0;
      default:
        return null;
    }
  }

  double? _getTop() {
    switch (config.toolbarPosition) {
      case ToolbarPosition.topLeft:
      case ToolbarPosition.topRight:
        return 16.0;
      default:
        return null;
    }
  }

  double? _getLeft() {
    switch (config.toolbarPosition) {
      case ToolbarPosition.topLeft:
      case ToolbarPosition.bottomLeft:
        return 16.0;
      default:
        return null;
    }
  }

  void _showBackgroundPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BackgroundPicker(
        currentColor: currentBackgroundColor,
        currentStyle: currentBackgroundStyle,
        checkerColor1: config.checkerColor1,
        checkerColor2: config.checkerColor2,
        onColorChanged: onBackgroundColorChanged,
        onStyleChanged: onBackgroundStyleChanged,
      ),
    );
  }
}

/// Individual toolbar button
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.7),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}