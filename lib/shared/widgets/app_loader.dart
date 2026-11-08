import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppLoader extends StatefulWidget {
  const AppLoader({super.key});

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Semantics(
      label: 'Loading',
      child: CustomPaint(
        size: const Size.square(32),
        painter: _SegmentedLoaderPainter(color, _animation),
      ),
    );
  }
}

class _SegmentedLoaderPainter extends CustomPainter {
  _SegmentedLoaderPainter(this.color, Animation<double> animation)
    : animation = animation,
      super(repaint: animation);

  final Color color;
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final activeSegment = animation.value * 12;
    for (var index = 0; index < 12; index++) {
      final distance = (index - activeSegment + 12) % 12;
      final opacity = 0.2 + ((11 - distance) / 11) * 0.55;
      final paint = Paint()..color = color.withValues(alpha: opacity);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(index * math.pi / 6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-1.6, -14, 3.2, 8),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SegmentedLoaderPainter oldDelegate) =>
      color != oldDelegate.color || animation != oldDelegate.animation;
}
