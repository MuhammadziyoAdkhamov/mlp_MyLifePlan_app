import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class MiniLineChart extends StatelessWidget {
  const MiniLineChart({super.key, required this.values, this.height = 130});

  final List<double> values;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _MiniLinePainter(values: values),
      ),
    );
  }
}

class _MiniLinePainter extends CustomPainter {
  const _MiniLinePainter({required this.values});

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.borderSoft.withOpacity(0.55)
      ..strokeWidth = 1;

    for (var i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (values.isEmpty) return;
    final path = Path();
    final fillPath = Path();
    final step = values.length == 1 ? size.width : size.width / (values.length - 1);

    for (var i = 0; i < values.length; i++) {
      final x = i * step;
      final y = size.height - (values[i].clamp(0, 1) * size.height);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.primary.withOpacity(0.28), AppColors.primary.withOpacity(0.0)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(colors: [AppColors.primary, AppColors.cyan]).createShader(Offset.zero & size);
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = AppColors.cyan;
    for (var i = 0; i < values.length; i++) {
      final x = i * step;
      final y = size.height - (values[i].clamp(0, 1) * size.height);
      canvas.drawCircle(Offset(x, y), math.max(3, size.width * 0.008), dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniLinePainter oldDelegate) => oldDelegate.values != values;
}
