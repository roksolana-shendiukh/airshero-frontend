import 'package:flutter/material.dart';

class AnimatedFlightProgress extends StatefulWidget {
  final bool isSearching; 
  final VoidCallback? onComplete;

  const AnimatedFlightProgress({
    super.key,
    required this.isSearching,
    this.onComplete,
  });

  @override
  State<AnimatedFlightProgress> createState() => _AnimatedFlightProgressState();
}

class _AnimatedFlightProgressState extends State<AnimatedFlightProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(seconds: 8), 
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut, 
      ),
    );

    if (widget.isSearching) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedFlightProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isSearching && !oldWidget.isSearching) {
      _animation = Tween<double>(begin: 0.0, end: 0.95).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOut,
        ),
      );
      _controller.duration = const Duration(seconds: 8);
      _controller.forward(from: 0);
    } else if (!widget.isSearching && oldWidget.isSearching) {
      final currentProgress = _animation.value;
      
      _animation = Tween<double>(
        begin: currentProgress,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ));
      
      _controller.duration = const Duration(milliseconds: 300);
      _controller.forward(from: 0).then((_) {
        widget.onComplete?.call();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isSearching && _animation.value == 0) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, 60),
          painter: _FlightProgressPainter(
            progress: _animation.value,
            primaryColor: Theme.of(context).colorScheme.primary,
            surfaceColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
        );
      },
    );
  }
}

class _FlightProgressPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color surfaceColor;

  _FlightProgressPainter({
    required this.progress,
    required this.primaryColor,
    required this.surfaceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final double padding = 40;
    final double lineY = size.height / 2;
    final double lineStartX = padding;
    final double lineEndX = size.width - padding;
    final double lineLength = lineEndX - lineStartX;

    paint.color = surfaceColor;
    canvas.drawLine(
      Offset(lineStartX, lineY),
      Offset(lineEndX, lineY),
      paint,
    );

    if (progress > 0) {
      paint.color = primaryColor;
      final progressX = lineStartX + (lineLength * progress);
      canvas.drawLine(
        Offset(lineStartX, lineY),
        Offset(progressX, lineY),
        paint,
      );
    }

    _drawPoint(canvas, Offset(lineStartX, lineY), primaryColor, 6);
    _drawPoint(canvas, Offset(lineEndX, lineY), primaryColor, 6);

    if (progress > 0 && progress <= 1.0) {
      final planeX = lineStartX + (lineLength * progress);
      final planeY = lineY;
      _drawPlaneIcon(canvas, Offset(planeX, planeY), primaryColor);
    }
  }

  void _drawPoint(Canvas canvas, Offset center, Color color, double radius) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);

    final outlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, outlinePaint);
  }

  void _drawPlaneIcon(Canvas canvas, Offset position, Color color) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.flight.codePoint),
      style: TextStyle(
        fontSize: 24,
        fontFamily: Icons.flight.fontFamily,
        package: Icons.flight.fontPackage,
        color: color,
      ),
    );

    textPainter.layout();

    final offset = Offset(
      position.dx - textPainter.width / 2,
      position.dy - textPainter.height / 2,
    );

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(1.5708); 
    canvas.translate(-position.dx, -position.dy);

    final shadowTextPainter = TextPainter(textDirection: TextDirection.ltr);
    shadowTextPainter.text = TextSpan(
      text: String.fromCharCode(Icons.flight.codePoint),
      style: TextStyle(
        fontSize: 24,
        fontFamily: Icons.flight.fontFamily,
        package: Icons.flight.fontPackage,
        color: Colors.black.withValues(alpha: 0.2),
      ),
    );

    shadowTextPainter.layout();
    shadowTextPainter.paint(canvas, offset.translate(1, 1));
    textPainter.paint(canvas, offset);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_FlightProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}