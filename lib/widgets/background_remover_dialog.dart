import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/background_remover_helper.dart';

enum RemovalMode {
  aiAuto,
  smartFloodFill,
  colorKey,
}

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
  RemovalMode _mode = RemovalMode.aiAuto;
  late Color _targetColor;
  double _tolerance = 28.0;
  Uint8List? _processedBytes;
  bool _isProcessing = false;
  String? _statusMessage;

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

  Future<void> _processImage() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = null;
    });

    if (_mode == RemovalMode.aiAuto) {
      final aiResult = await BackgroundRemoverHelper.removeBackgroundAI(widget.originalBytes);
      if (mounted) {
        if (aiResult != null) {
          setState(() {
            _processedBytes = aiResult;
            _isProcessing = false;
          });
        } else {
          // Fallback to Smart Flood Fill if AI mode fails or is unsupported on platform
          final fallbackResult = BackgroundRemoverHelper.removeBackgroundSmartFloodFill(
            inputBytes: widget.originalBytes,
            tolerance: _tolerance,
          );
          setState(() {
            _mode = RemovalMode.smartFloodFill;
            _processedBytes = fallbackResult;
            _isProcessing = false;
            _statusMessage = 'AI model unavailable, switched to Smart Flood-Fill';
          });
        }
      }
      return;
    }

    // Run non-AI modes asynchronously using microtask
    Future.microtask(() {
      Uint8List processed;
      if (_mode == RemovalMode.smartFloodFill) {
        processed = BackgroundRemoverHelper.removeBackgroundSmartFloodFill(
          inputBytes: widget.originalBytes,
          tolerance: _tolerance,
        );
      } else {
        processed = BackgroundRemoverHelper.removeBackgroundGlobalColor(
          inputBytes: widget.originalBytes,
          targetColor: _targetColor,
          tolerance: _tolerance,
        );
      }

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 700),
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
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: subTextColor),
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
                  border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
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
                      Container(
                        color: Colors.black45,
                        child: const Center(
                          child: CircularProgressIndicator(color: Color(0xFF25D366)),
                        ),
                      )
                    else if (_processedBytes != null)
                      Image.memory(
                        _processedBytes!,
                        fit: BoxFit.contain,
                      )
                    else
                      Image.memory(widget.originalBytes, fit: BoxFit.contain),
                  ],
                ),
              ),
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _statusMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.amberAccent : Colors.deepOrange, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),

            // Mode Selector: AI Auto vs Smart Flood-Fill vs Key Color
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    avatar: Icon(Icons.psychology_rounded, size: 18, color: _mode == RemovalMode.aiAuto ? Colors.black : textColor),
                    label: Text(isArabic ? 'ذكاء اصطناعي (تلقائي)' : 'AI Auto'),
                    selected: _mode == RemovalMode.aiAuto,
                    selectedColor: const Color(0xFF25D366),
                    backgroundColor: isDark ? Colors.white10 : const Color(0xFFEEEEEE),
                    labelStyle: TextStyle(
                      color: _mode == RemovalMode.aiAuto ? Colors.black : textColor,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() => _mode = RemovalMode.aiAuto);
                        _processImage();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    avatar: Icon(Icons.border_outer_rounded, size: 18, color: _mode == RemovalMode.smartFloodFill ? Colors.black : textColor),
                    label: Text(isArabic ? 'إزالة حدود (ذكي)' : 'Smart Flood-Fill'),
                    selected: _mode == RemovalMode.smartFloodFill,
                    selectedColor: const Color(0xFF25D366),
                    backgroundColor: isDark ? Colors.white10 : const Color(0xFFEEEEEE),
                    labelStyle: TextStyle(
                      color: _mode == RemovalMode.smartFloodFill ? Colors.black : textColor,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() => _mode = RemovalMode.smartFloodFill);
                        _processImage();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    avatar: Icon(Icons.color_lens_rounded, size: 18, color: _mode == RemovalMode.colorKey ? Colors.black : textColor),
                    label: Text(isArabic ? 'تحديد اللون' : 'Color Key'),
                    selected: _mode == RemovalMode.colorKey,
                    selectedColor: const Color(0xFF25D366),
                    backgroundColor: isDark ? Colors.white10 : const Color(0xFFEEEEEE),
                    labelStyle: TextStyle(
                      color: _mode == RemovalMode.colorKey ? Colors.black : textColor,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() => _mode = RemovalMode.colorKey);
                        _processImage();
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Color Presets if Key Color selected
            if (_mode == RemovalMode.colorKey) ...[
              Text(
                isArabic ? 'اختر لون الخلفية المراد إزالته:' : 'Select Background Color to Remove:',
                style: TextStyle(color: subTextColor, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _presetColors.map((color) {
                  final isSelected = _targetColor == color;
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
                          color: isSelected ? const Color(0xFF25D366) : (isDark ? Colors.white24 : Colors.black26),
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Tolerance Slider (for non-AI modes)
            if (_mode != RemovalMode.aiAuto)
              Row(
                children: [
                  Text(
                    isArabic ? 'دقة الإزالة:' : 'Sensitivity:',
                    style: TextStyle(color: textColor, fontSize: 13.5),
                  ),
                  Expanded(
                    child: Slider(
                      value: _tolerance,
                      min: 5.0,
                      max: 80.0,
                      divisions: 75,
                      activeColor: const Color(0xFF25D366),
                      inactiveColor: isDark ? Colors.white24 : Colors.black12,
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
                    style: TextStyle(color: subTextColor, fontSize: 12),
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
