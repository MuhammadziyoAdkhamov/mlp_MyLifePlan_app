import 'package:flutter/material.dart';

/// The scene stays still at rest. Only an active interaction drives a ticker.
class MLPAINebula extends StatefulWidget {
  const MLPAINebula({
    super.key,
    this.active = false,
    this.muted = false,
    this.height = 210,
  });

  final bool active, muted;
  final double height;

  @override
  State<MLPAINebula> createState() => _NebulaState();
}

class _NebulaState extends State<MLPAINebula>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1450),
  );

  void _sync() {
    final animate =
        widget.active &&
        !widget.muted &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (animate && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!animate) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant MLPAINebula oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ClipRect(
      child: SizedBox(
        width: double.infinity,
        height: widget.height,
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.white,
              Colors.white,
              Colors.transparent,
            ],
            stops: [0, .14, .85, 1],
          ).createShader(rect),
          child: AnimatedBuilder(
            animation: _pulse,
            child: const RepaintBoundary(
              child: CustomPaint(painter: _FriendlyOrbPainter()),
            ),
            builder: (_, child) => Opacity(
              opacity: widget.muted ? .5 : .9 + _pulse.value * .1,
              child: Transform.scale(
                scale: 1 + _pulse.value * .025,
                child: child,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _FriendlyOrbPainter extends CustomPainter {
  const _FriendlyOrbPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide * .34;
    final bounds = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r * 1.5,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x770073FF), Color(0x220064D9), Colors.transparent],
        ).createShader(Rect.fromCircle(center: c, radius: r * 1.5)),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = const Color(0xFF058DFF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 13),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const SweepGradient(
          colors: [
            Color(0xFFECFCFF),
            Color(0xFF00D5FF),
            Color(0xFF5F3BFF),
            Color(0xFFB159FF),
            Color(0xFF00D5FF),
            Color(0xFFECFCFF),
          ],
        ).createShader(bounds),
    );
    canvas.drawCircle(
      c,
      r - 4,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.4, -.5),
          colors: [Color(0xFF16499C), Color(0xFF071431), Color(0xFF030719)],
          stops: [0, .6, 1],
        ).createShader(bounds),
    );
    for (final x in [-.35, .35]) {
      final eye = Rect.fromCenter(
        center: c + Offset(r * x, -r * .06),
        width: r * .19,
        height: r * .28,
      );
      canvas.drawOval(
        eye.inflate(3),
        Paint()
          ..color = const Color(0xFF00BFFF)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawOval(
        eye,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFB3F7FF), Color(0xFF00B5FF), Color(0xFF097BFF)],
          ).createShader(eye),
      );
      canvas.drawCircle(
        eye.center + Offset(-r * .025, -r * .055),
        r * .03,
        Paint()..color = Colors.white,
      );
    }
    canvas.drawArc(
      Rect.fromCenter(
        center: c + Offset(0, r * .22),
        width: r * .32,
        height: r * .18,
      ),
      .15,
      2.84,
      false,
      Paint()
        ..color = const Color(0xFF0BCFFF)
        ..strokeWidth = r * .045
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_FriendlyOrbPainter oldDelegate) => false;
}
