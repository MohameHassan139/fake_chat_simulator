import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/background_remover_helper.dart';

class BackgroundRemoverDialog extends StatefulWidget {
  final Uint8List originalBytes;

  const BackgroundRemoverDialog({
    super.key,
    required this.originalBytes,
  });

  @override
  State<BackgroundRemoverDialog> createState() => _BackgroundRemoverDialogState();
}

class _BackgroundRemoverDialogState extends State<BackgroundRemoverDialog> {
  late Color _targetColor;
  double _tolerance = 25.0;
  Uint8List? _processedBytes;
  bool _isProcessing = false;
  bool _useAuto = true;

  final List<Color> _presetColors = [
    Colors.white,
    Colors.black,
    const Color(0xFFF0F0F0),
    const Color(0xFF00FF00), // Green screen key
    const Color(0xFF0000FF), // Blue screen key
  ];

  @override
  void initState() {
    super.initState();
    _targetColor = BackgroundRemoverHelper.autoDetectCornerColor(widget.originalBytes);
    _processImage();
  }

  void _processImage() {
    setState(() => _isProcessing = true);
    Future.microtask(() {
      final processed = BackgroundRemoverHelper.removeBackground(
        inputBytes: widget.originalBytes,
        targetColor: _useAuto ? null : _targetColor,
        tolerance: _tolerance,
      );
      if (mounted) {
        setState(() {
          _processedBytes = processed;
          _isProcessing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<ThemeProvider>().isArabic;

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title Header
            Row(
              children: [
                const Icon(Icons.auto_fix_high_rounded, color: Color(0xFF25D366), size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isArabic ? 'إزالة خلفية الملصق' : 'Remove Sticker Background',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Live Preview Card with Checkerboard Background for Transparency
            Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Checkerboard background
                    CustomPaint(
                      painter: CheckerboardPainter(),
                      size: Size.infinite,
                    ),
                    if (_isProcessing)
                      const CircularProgressIndicator(color: Color(0xFF25D366))
                    else if (_processedBytes != null)
                      Image.memory(_processedBytes!, fit: BoxFit.contain)
                    else
                      Image.memory(widget.originalBytes, fit: BoxFit.contain),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Mode selector: Auto vs Manual Color
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Text(isArabic ? 'تلقائي (الزوايا)' : 'Auto Detect'),
                    selected: _useAuto,
                    selectedColor: const Color(0xFF25D366),
                    backgroundColor: Colors.white10,
                    labelStyle: TextStyle(
                      color: _useAuto ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _useAuto = true;
                        });
                        _processImage();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: Text(isArabic ? 'تحديد اللون' : 'Key Color'),
                    selected: !_useAuto,
                    selectedColor: const Color(0xFF25D366),
                    backgroundColor: Colors.white10,
                    labelStyle: TextStyle(
                      color: !_useAuto ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _useAuto = false;
                        });
                        _processImage();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Color Presets if Key Color selected
            if (!_useAuto) ...[
              Text(
                isArabic ? 'اختر لون الخلفية المراد إزالته:' : 'Select Background Color to Remove:',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _presetColors.map((color) {
                  final isSelected = _targetColor.value == color.value;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _targetColor = color;
                      });
                      _processImage();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? const Color(0xFF25D366) : Colors.white24,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Tolerance Slider
            Row(
              children: [
                Text(
                  isArabic ? 'دقة الإزالة:' : 'Sensitivity:',
                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                ),
                Expanded(
                  child: Slider(
                    value: _tolerance,
                    min: 5.0,
                    max: 80.0,
                    divisions: 75,
                    activeColor: const Color(0xFF25D366),
                    inactiveColor: Colors.white24,
                    label: '${_tolerance.toInt()}%',
                    onChanged: (val) {
                      setState(() {
                        _tolerance = val;
                      });
                    },
                    onChangeEnd: (val) {
                      _processImage();
                    },
                  ),
                ),
                Text(
                  '${_tolerance.toInt()}%',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Save Action Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: Text(
                isArabic ? 'استخدام كملصق شفاف' : 'Use as Transparent Sticker',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                if (_processedBytes != null) {
                  Navigator.pop(context, _processedBytes);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double checkSize = 12.0;
    final paint1 = Paint()..color = const Color(0xFF2B2B2B);
    final paint2 = Paint()..color = const Color(0xFF1F1F1F);

    for (double y = 0; y < size.height; y += checkSize) {
      for (double x = 0; x < size.width; x += checkSize) {
        final isEven = ((x / checkSize).floor() + (y / checkSize).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, checkSize, checkSize),
          isEven ? paint1 : paint2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
