import 'dart:math' as math;
import 'package:flutter/material.dart';

Future<String?> showPlanningTimePicker({
  required BuildContext context,
  required String initialTime,
}) async {
  return showDialog<String>(
    context: context,
    builder: (context) => Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: _PlanningTimePicker(initialTime: initialTime),
    ),
  );
}

enum _ClockMode { hours, minutes }

class _PlanningTimePicker extends StatefulWidget {
  final String initialTime;
  const _PlanningTimePicker({required this.initialTime});

  @override
  State<_PlanningTimePicker> createState() => _PlanningTimePickerState();
}

class _PlanningTimePickerState extends State<_PlanningTimePicker> {
  late int _hour;
  late int _minute;
  _ClockMode _mode = _ClockMode.hours;

  @override
  void initState() {
    super.initState();
    final parts = widget.initialTime.split(':');
    _hour = parts.length == 2 ? int.tryParse(parts[0]) ?? 0 : 0;
    _minute = parts.length == 2 ? int.tryParse(parts[1]) ?? 0 : 0;
  }

  String get _formatted =>
      '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'Select time',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildTimeDisplay(colors),
            const SizedBox(height: 16),

            _ClockFace(
              mode: _mode,
              hour: _hour,
              minute: _minute,
              onHourChanged: (h) {
                setState(() {
                  _hour = h;
                  _mode = _ClockMode.minutes;
                });
              },
              onMinuteChanged: (m) {
                setState(() => _minute = m);
              },
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(context).pop(_formatted),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDisplay(ColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _TimeSegment(
          value: _hour.toString().padLeft(2, '0'),
          label: 'HH',
          isActive: _mode == _ClockMode.hours,
          onTap: () => setState(() => _mode = _ClockMode.hours),
          colors: colors,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            ':',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w300,
              color: colors.onSurface,
            ),
          ),
        ),
        _TimeSegment(
          value: _minute.toString().padLeft(2, '0'),
          label: 'MM',
          isActive: _mode == _ClockMode.minutes,
          onTap: () => setState(() => _mode = _ClockMode.minutes),
          colors: colors,
        ),
      ],
    );
  }
}

class _TimeSegment extends StatelessWidget {
  final String value;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final ColorScheme colors;

  const _TimeSegment({
    required this.value,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? colors.primaryContainer
              : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          value,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w500,
            color: isActive ? colors.onPrimaryContainer : colors.onSurface,
          ),
        ),
      ),
    );
  }
}

class _ClockFace extends StatefulWidget {
  final _ClockMode mode;
  final int hour;
  final int minute;
  final ValueChanged<int> onHourChanged;
  final ValueChanged<int> onMinuteChanged;

  const _ClockFace({
    required this.mode,
    required this.hour,
    required this.minute,
    required this.onHourChanged,
    required this.onMinuteChanged,
  });

  @override
  State<_ClockFace> createState() => _ClockFaceState();
}

class _ClockFaceState extends State<_ClockFace> {
  static const _size = 220.0;
  static const _radius = 90.0;
  static const _innerRadius = 60.0;

  int? _dragging;

  void _handleTapOrDrag(Offset local) {
    final center = const Offset(_size / 2, _size / 2);
    final delta = local - center;
    final angle = math.atan2(delta.dx, -delta.dy);
    final normalized = (angle + 2 * math.pi) % (2 * math.pi);

    if (widget.mode == _ClockMode.hours) {
      final dist = delta.distance;
      final isInner = dist < (_radius + _innerRadius) / 2;
      final rawHour =
          (normalized / (2 * math.pi) * 12).round() % 12;
      final hour = isInner ? rawHour + 12 : rawHour;
      widget.onHourChanged(hour);
    } else {
      final rawMin =
          (normalized / (2 * math.pi) * 60).round() % 60;
      widget.onMinuteChanged(rawMin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (d) => _handleTapOrDrag(d.localPosition),
      onPanUpdate: (d) => _handleTapOrDrag(d.localPosition),
      child: CustomPaint(
        size: const Size(_size, _size),
        painter: _ClockPainter(
          mode: widget.mode,
          hour: widget.hour,
          minute: widget.minute,
          primaryColor: colors.primary,
          onPrimaryColor: colors.onPrimary,
          surfaceColor:
              colors.surfaceContainerHighest.withValues(alpha: 0.6),
          onSurfaceColor: colors.onSurface,
          onSurfaceVariantColor: colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  final _ClockMode mode;
  final int hour;
  final int minute;
  final Color primaryColor;
  final Color onPrimaryColor;
  final Color surfaceColor;
  final Color onSurfaceColor;
  final Color onSurfaceVariantColor;

  static const _size = 220.0;
  static const _center = Offset(_size / 2, _size / 2);
  static const _outerR = 90.0;
  static const _innerR = 60.0;
  static const _dotR = 18.0;

  _ClockPainter({
    required this.mode,
    required this.hour,
    required this.minute,
    required this.primaryColor,
    required this.onPrimaryColor,
    required this.surfaceColor,
    required this.onSurfaceColor,
    required this.onSurfaceVariantColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = surfaceColor;
    canvas.drawCircle(_center, _outerR + 20, bgPaint);

    if (mode == _ClockMode.hours) {
      _drawHours(canvas);
    } else {
      _drawMinutes(canvas);
    }
  }

  void _drawHours(Canvas canvas) {
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi - math.pi / 2;
      final outerPos = Offset(
        _center.dx + _outerR * math.cos(angle),
        _center.dy + _outerR * math.sin(angle),
      );
      final innerPos = Offset(
        _center.dx + _innerR * math.cos(angle),
        _center.dy + _innerR * math.sin(angle),
      );

      final outerHour = i == 0 ? 12 : i;
      final innerHour = i == 0 ? 0 : i + 12;

      final isOuterSelected = hour == outerHour ||
          (outerHour == 12 && hour == 12);
      final isInnerSelected = hour == innerHour;

      _drawDot(canvas, outerPos, isOuterSelected);
      _drawLabel(canvas, outerPos, '$outerHour', isOuterSelected);

      _drawDot(canvas, innerPos, isInnerSelected);
      _drawLabel(canvas, innerPos, innerHour.toString().padLeft(2, '0'),
          isInnerSelected, small: true);
    }

    _drawHand(canvas, hour);
  }

  void _drawMinutes(Canvas canvas) {
    for (int i = 0; i < 60; i += 5) {
      final angle = (i / 60) * 2 * math.pi - math.pi / 2;
      final pos = Offset(
        _center.dx + _outerR * math.cos(angle),
        _center.dy + _outerR * math.sin(angle),
      );
      final isSelected = minute == i;
      _drawDot(canvas, pos, isSelected);
      _drawLabel(canvas, pos, i.toString().padLeft(2, '0'), isSelected);
    }

    final minAngle = (minute / 60) * 2 * math.pi - math.pi / 2;
    final minPos = Offset(
      _center.dx + _outerR * math.cos(minAngle),
      _center.dy + _outerR * math.sin(minAngle),
    );

    final handPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(_center, minPos, handPaint);

    final centerDot = Paint()..color = primaryColor;
    canvas.drawCircle(_center, 4, centerDot);

    if (minute % 5 != 0) {
      _drawDot(canvas, minPos, true);
    }
  }

  void _drawHand(Canvas canvas, int h) {
    final displayH = h % 12;
    final angle = (displayH / 12) * 2 * math.pi - math.pi / 2;
    final r = h >= 12 && h != 0 ? _innerR : _outerR;
    final pos = Offset(
      _center.dx + r * math.cos(angle),
      _center.dy + r * math.sin(angle),
    );

    final handPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(_center, pos, handPaint);

    final centerDot = Paint()..color = primaryColor;
    canvas.drawCircle(_center, 4, centerDot);
  }

  void _drawDot(Canvas canvas, Offset pos, bool selected) {
    final paint = Paint()
      ..color = selected ? primaryColor : Colors.transparent;
    canvas.drawCircle(pos, _dotR, paint);
  }

  void _drawLabel(Canvas canvas, Offset pos, String text, bool selected,
      {bool small = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: selected ? onPrimaryColor : onSurfaceColor,
          fontSize: small ? 11 : 13,
          fontWeight:
              selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
        canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_ClockPainter old) =>
      old.mode != mode ||
      old.hour != hour ||
      old.minute != minute ||
      old.primaryColor != primaryColor;
}