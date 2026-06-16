import 'package:flutter/material.dart';

class FakeStatusBar extends StatelessWidget {
  final String time;
  final int battery;
  final bool hasWifi;
  final Color backgroundColor;
  final bool isLight;

  const FakeStatusBar({
    super.key,
    required this.time,
    required this.battery,
    required this.hasWifi,
    required this.backgroundColor,
    this.isLight = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isLight ? Colors.white : Colors.black;

    return Container(
      height: 44,
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Time
          Text(
            time,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          // Status icons
          Row(
            children: [
              // Signal bars
              _SignalBars(color: textColor),
              const SizedBox(width: 6),
              // WiFi
              if (hasWifi)
                Icon(Icons.wifi_rounded, color: textColor, size: 16),
              if (!hasWifi)
                Icon(Icons.wifi_off_rounded,
                    color: textColor.withValues(alpha: 0.5), size: 16),
              const SizedBox(width: 6),
              // Battery
              _BatteryIcon(level: battery, color: textColor),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignalBars extends StatelessWidget {
  final Color color;
  const _SignalBars({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        return Container(
          width: 3,
          height: 4.0 + (i * 2.5),
          margin: const EdgeInsets.only(right: 1.5),
          decoration: BoxDecoration(
            color: i < 3 ? color : color.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}

class _BatteryIcon extends StatelessWidget {
  final int level;
  final Color color;

  const _BatteryIcon({required this.level, required this.color});

  @override
  Widget build(BuildContext context) {
    final fillColor = level > 20 ? color : Colors.red;

    return Row(
      children: [
        Text(
          '$level%',
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 3),
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Outer battery body
            Container(
              width: 24,
              height: 12,
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 1.5),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // Battery tip
            Positioned(
              right: -3.5,
              child: Container(
                width: 2,
                height: 5,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(1)),
                ),
              ),
            ),
            // Fill level
            Positioned(
              left: 2,
              child: Container(
                width: ((level / 100) * 18).clamp(0, 18),
                height: 7,
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
