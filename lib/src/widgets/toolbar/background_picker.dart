import 'package:flutter/material.dart';
import '../../models/enums.dart';

/// Dialog for picking background color/style
class BackgroundPicker extends StatefulWidget {
  final Color currentColor;
  final BackgroundStyle currentStyle;
  final Color checkerColor1;
  final Color checkerColor2;
  final Function(Color) onColorChanged;
  final Function(BackgroundStyle) onStyleChanged;

  const BackgroundPicker({
    Key? key,
    required this.currentColor,
    required this.currentStyle,
    required this.checkerColor1,
    required this.checkerColor2,
    required this.onColorChanged,
    required this.onStyleChanged,
  }) : super(key: key);

  @override
  State<BackgroundPicker> createState() => _BackgroundPickerState();
}

class _BackgroundPickerState extends State<BackgroundPicker> {
  late BackgroundStyle _selectedStyle;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedStyle = widget.currentStyle;
    _selectedColor = widget.currentColor;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 300),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Background',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Checkered option
            _BackgroundOption(
              title: 'Checkered',
              subtitle: 'Transparent pattern',
              isSelected: _selectedStyle == BackgroundStyle.checkered,
              previewWidget: _CheckeredPreview(
                color1: widget.checkerColor1,
                color2: widget.checkerColor2,
              ),
              onTap: () {
                setState(() => _selectedStyle = BackgroundStyle.checkered);
                widget.onStyleChanged(BackgroundStyle.checkered);
              },
            ),

            const SizedBox(height: 12),

            // Black option
            _BackgroundOption(
              title: 'Black',
              subtitle: 'Solid black',
              isSelected: _selectedStyle == BackgroundStyle.solid &&
                  _selectedColor == Colors.black,
              previewWidget: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
              onTap: () {
                setState(() {
                  _selectedStyle = BackgroundStyle.solid;
                  _selectedColor = Colors.black;
                });
                widget.onStyleChanged(BackgroundStyle.solid);
                widget.onColorChanged(Colors.black);
              },
            ),

            const SizedBox(height: 12),

            // White option
            _BackgroundOption(
              title: 'White',
              subtitle: 'Solid white',
              isSelected: _selectedStyle == BackgroundStyle.solid &&
                  _selectedColor == Colors.white,
              previewWidget: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
              onTap: () {
                setState(() {
                  _selectedStyle = BackgroundStyle.solid;
                  _selectedColor = Colors.white;
                });
                widget.onStyleChanged(BackgroundStyle.solid);
                widget.onColorChanged(Colors.white);
              },
            ),

            const SizedBox(height: 12),

            // Custom color option
            _BackgroundOption(
              title: 'Custom',
              subtitle: 'Choose color',
              isSelected: _selectedStyle == BackgroundStyle.solid &&
                  _selectedColor != Colors.black &&
                  _selectedColor != Colors.white,
              previewWidget: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _selectedColor != Colors.black &&
                      _selectedColor != Colors.white
                      ? _selectedColor
                      : Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
              onTap: () => _showColorPicker(),
            ),

            const SizedBox(height: 20),

            // Close button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => _SimpleColorPicker(
        currentColor: _selectedColor,
        onColorSelected: (color) {
          setState(() {
            _selectedStyle = BackgroundStyle.solid;
            _selectedColor = color;
          });
          widget.onStyleChanged(BackgroundStyle.solid);
          widget.onColorChanged(color);
        },
      ),
    );
  }
}

/// Background option tile
class _BackgroundOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final Widget previewWidget;
  final VoidCallback onTap;

  const _BackgroundOption({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.previewWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            previewWidget,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
              ),
          ],
        ),
      ),
    );
  }
}

/// Checkered pattern preview
class _CheckeredPreview extends StatelessWidget {
  final Color color1;
  final Color color2;

  const _CheckeredPreview({
    required this.color1,
    required this.color2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: CustomPaint(
        painter: _MiniCheckeredPainter(color1: color1, color2: color2),
      ),
    );
  }
}

class _MiniCheckeredPainter extends CustomPainter {
  final Color color1;
  final Color color2;

  _MiniCheckeredPainter({required this.color1, required this.color2});

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = color1;
    final paint2 = Paint()..color = color2;
    final squareSize = size.width / 4;

    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 4; col++) {
        final paint = ((row + col) % 2 == 0) ? paint1 : paint2;
        canvas.drawRect(
          Rect.fromLTWH(col * squareSize, row * squareSize, squareSize, squareSize),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_MiniCheckeredPainter oldDelegate) =>
      color1 != oldDelegate.color1 || color2 != oldDelegate.color2;
}

/// Simple color picker with preset colors
class _SimpleColorPicker extends StatelessWidget {
  final Color currentColor;
  final Function(Color) onColorSelected;

  const _SimpleColorPicker({
    required this.currentColor,
    required this.onColorSelected,
  });

  static final List<Color> _colors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
    Colors.white,
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 300),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Color',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colors.map((color) {
                return GestureDetector(
                  onTap: () {
                    onColorSelected(color);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color == currentColor
                            ? Colors.blue
                            : Colors.grey.shade300,
                        width: color == currentColor ? 3 : 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}