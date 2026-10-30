import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Static reference artwork; no timers, image downloads or per-frame blur.
class MLPFocusDialPainter extends CustomPainter {
  const MLPFocusDialPainter(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 12;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = const Color(0xFF26375D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final inner = r - 24;
    canvas.drawCircle(
      c,
      inner,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF102348), Color(0xFF040D21), Color(0xFF10122D)],
        ).createShader(rect),
    );
    canvas.drawCircle(
      c,
      inner,
      Paint()
        ..color = const Color(0xFF899EFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final sweep = 2 * math.pi * progress.clamp(0, 1);
    final shader = const SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
      colors: [
        Color(0xFF23EAFF),
        Color(0xFF3B8DFF),
        Color(0xFF9056FF),
        Color(0xFFE2BFFF),
      ],
      transform: GradientRotation(-math.pi / 2),
    ).createShader(rect);
    if (sweep > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..shader = shader
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawArc(
        rect,
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..shader = shader
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(MLPFocusDialPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
