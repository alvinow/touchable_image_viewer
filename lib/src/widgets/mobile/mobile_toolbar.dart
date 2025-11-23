import 'package:flutter/material.dart';
import '../../models/enums.dart';
import '../../models/viewer_config.dart';
import '../toolbar/background_picker.dart';

/// Mobile-optimized toolbar with larger touch targets
class MobileToolbar extends StatelessWidget {
  final ViewerConfig config;
  final VoidCallback? onRotate;
  final Function(Color) onBackgroundColorChanged;
  final Function(BackgroundStyle) onBackgroundStyleChanged;
  final bool show3DControls;
  final Color currentBackgroundColor;
  final BackgroundStyle currentBackgroundStyle;

  const MobileToolbar({
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
      bottom: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Background color button
          if (config.showBackgroundButton)
            _MobileToolbarButton(
              icon: Icons.palette,
              tooltip: 'Background',
              onPressed: () => _showBackgroundPicker(context),
            ),

          if (config.showBackgroundButton && config.showRotateButton && !show3DControls)
            const SizedBox(height: 12),

          // Rotate button (only for 2D images)
          if (config.showRotateButton && !show3DControls && onRotate != null)
            _MobileToolbarButton(
              icon: Icons.rotate_90_degrees_ccw,
              tooltip: 'Rotate',
              onPressed: onRotate!,
            ),
        ],
      ),
    );
  }

  void _showBackgroundPicker(BuildContext context) {
    // Mobile: Use bottom sheet for better thumb reach
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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

/// Mobile toolbar button with larger touch target (56x56)
class _MobileToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _MobileToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.7),
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 56, // Larger for mobile touch
            height: 56,
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: Colors.white,
              size: 28, // Larger icon
            ),
          ),
        ),
      ),
    );
  }
}