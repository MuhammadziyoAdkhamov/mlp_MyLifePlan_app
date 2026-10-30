import 'package:flutter/material.dart';

/// Resolution independent ribbon mark, shared by launch and account screens.
class MLPBrandMark extends StatelessWidget {
  const MLPBrandMark({super.key, this.size = 110});
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'MLP',
    image: true,
    child: RepaintBoundary(
      child: CustomPaint(size: Size(size, size), painter: const _RibbonMark()),
    ),
  );
}

class _RibbonMark extends CustomPainter {
  const _RibbonMark();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final segments = [
      (
        const Offset(13, 75),
        const Offset(32, 32),
        const Color(0xFF006AFF),
        const Color(0xFF28EDFF),
      ),
      (
        const Offset(32, 32),
        const Offset(51, 80),
        const Color(0xFF26DEFF),
        const Color(0xFF024BE2),
      ),
      (
        const Offset(51, 80),
        const Offset(72, 20),
        const Color(0xFF0454FF),
        const Color(0xFFB5F2FF),
      ),
      (
        const Offset(72, 20),
        const Offset(90, 80),
        const Color(0xFF91DEFF),
        const Color(0xFF7739F8),
      ),
    ];
    for (final (from, to, a, b) in segments) {
      final rect = Rect.fromPoints(from, to).inflate(1);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 17
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [a, b],
        ).createShader(rect);
      canvas.drawLine(
        from,
        to,
        Paint()
          ..color = b.withValues(alpha: .25)
          ..strokeWidth = 20
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
      canvas.drawLine(from, to, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RibbonMark oldDelegate) => false;
}
