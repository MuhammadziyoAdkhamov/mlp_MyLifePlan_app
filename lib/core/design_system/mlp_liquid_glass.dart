import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../app/theme/mlp_design_system.dart';
import 'mlp_appearance.dart';
import 'mlp_haptics.dart';

/// Clipping bounds the blur cost. Grouped siblings share one backdrop capture.
class MLPLiquidSurface extends StatelessWidget {
  const MLPLiquidSurface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 20,
    this.tint,
    this.grouped = true,
    this.blur = true,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? tint;
  final bool grouped, blur;
  @override
  Widget build(BuildContext context) {
    final contrast = MediaQuery.highContrastOf(context);
    final color = tint ?? MLPColors.elevated;
    final panel = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: contrast ? .98 : .68),
            MLPColors.secondary.withValues(alpha: contrast ? .98 : .62),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: contrast ? .5 : .28),
          width: .7,
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
    final sigma = blur && !contrast ? 10.0 : 0.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .2),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: sigma == 0
            ? panel
            : grouped
            ? BackdropFilter.grouped(
                filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                child: panel,
              )
            : BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                child: panel,
              ),
      ),
    );
  }
}

class MLPLiquidBackground extends StatelessWidget {
  const MLPLiquidBackground({super.key});
  @override
  Widget build(BuildContext context) {
    final bytes = MLPAppearanceScope.maybeOf(context)?.backgroundBytes;
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(
            painter: _AmbientPainter(),
            child: SizedBox.expand(),
          ),
          if (bytes != null) ...[
            Image.memory(
              bytes,
              fit: BoxFit.cover,
              cacheWidth: 1080,
              gaplessPlayback: true,
              excludeFromSemantics: true,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            ColoredBox(
              color: MLPColors.background.withValues(
                alpha: MediaQuery.highContrastOf(context) ? .92 : .72,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  const _AmbientPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = MLPColors.background);
    // Soft, open ribbons keep the content legible without solid angular shapes.
    for (var i = 0; i < 3; i++) {
      final ribbon = Path()
        ..moveTo(-size.width * .25, size.height * (.13 + i * .20))
        ..cubicTo(
          size.width * .9,
          size.height * (.02 + i * .16),
          size.width * -.15,
          size.height * (.57 + i * .12),
          size.width * 1.2,
          size.height * (.38 + i * .2),
        );
      final shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0x003856EA),
          Color(i == 1 ? 0x885C2DD2 : 0x774664F4),
          const Color(0x660296D9),
          const Color(0x003856EA),
        ],
      ).createShader(Offset.zero & size);
      canvas.drawPath(
        ribbon,
        Paint()
          ..shader = shader
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * .13
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
      );
      canvas.drawPath(
        ribbon,
        Paint()
          ..shader = shader
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    for (final glow in [
      (
        Offset(size.width * .95, size.height * .04),
        MLPColors.turquoise.withValues(alpha: .09),
        size.width * .85,
      ),
      (
        Offset(0, size.height * .65),
        MLPColors.primary.withValues(alpha: .08),
        size.width * .85,
      ),
    ]) {
      canvas.drawCircle(
        glow.$1,
        glow.$3,
        Paint()
          ..shader = RadialGradient(
            colors: [glow.$2, glow.$2.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: glow.$1, radius: glow.$3)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter oldDelegate) => false;
}

class MLPPressResponse extends StatefulWidget {
  const MLPPressResponse({super.key, required this.child});
  final Widget child;
  @override
  State<MLPPressResponse> createState() => _PressResponseState();
}

class _PressResponseState extends State<MLPPressResponse> {
  bool pressed = false;
  void update(bool value) {
    if (pressed != value && mounted) setState(() => pressed = value);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) {
      MLPHaptics.selection();
      update(true);
    },
    onPointerUp: (_) => update(false),
    onPointerCancel: (_) => update(false),
    child: AnimatedScale(
      scale: pressed ? .975 : 1,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 100),
      curve: Curves.easeOutCubic,
      child: widget.child,
    ),
  );
}

class MLPCircleAction extends StatelessWidget {
  const MLPCircleAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color = MLPColors.turquoise,
    this.size = 52,
    this.filled = true,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final double size;
  final bool filled;
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: label,
    button: true,
    enabled: onPressed != null,
    onTap: onPressed,
    excludeSemantics: true,
    child: MLPPressResponse(
      child: SizedBox(
        width: size < 48 ? 48 : size,
        height: size < 48 ? 48 : size,
        child: Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: filled
                    ? [Color.lerp(color, Colors.white, .13)!, color]
                    : [const Color(0xFF172437), const Color(0xFF080F1C)],
              ),
              border: Border.all(
                color: filled
                    ? color.withValues(alpha: .7)
                    : Colors.white.withValues(alpha: .14),
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: filled ? .2 : .04),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: IconButton(
              tooltip: label,
              padding: EdgeInsets.zero,
              onPressed: onPressed,
              icon: Icon(
                icon,
                color: filled ? MLPColors.background : MLPColors.text,
                size: size * .42,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class MLPSegmented extends StatelessWidget {
  const MLPSegmented({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
        MediaQuery.sizeOf(context).width < 340) {
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: List.generate(
          labels.length,
          (i) => ChoiceChip(
            label: Text(labels[i]),
            selected: selected == i,
            onSelected: (_) => onChanged(i),
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<int>(
        groupValue: selected >= 0 && selected < labels.length ? selected : null,
        backgroundColor: Colors.white.withValues(alpha: .045),
        thumbColor: const Color(0xFF6256EA),
        padding: const EdgeInsets.all(4),
        children: {
          for (var i = 0; i < labels.length; i++)
            i: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text(
                labels[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: i == selected ? Colors.white : MLPColors.secondaryText,
                ),
              ),
            ),
        },
        onValueChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

Future<T?> mlpShowDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useSafeArea = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Color? barrierColor,
}) => showDialog<T>(
  context: context,
  barrierDismissible: barrierDismissible,
  useSafeArea: useSafeArea,
  useRootNavigator: useRootNavigator,
  routeSettings: routeSettings,
  animationStyle: MediaQuery.disableAnimationsOf(context)
      ? AnimationStyle.noAnimation
      : null,
  barrierColor: barrierColor ?? Colors.black.withValues(alpha: .4),
  builder: (dialog) => BackdropFilter(
    filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
    child: builder(dialog),
  ),
);

Future<T?> mlpShowSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useSafeArea = false,
  bool isDismissible = true,
  bool enableDrag = true,
  Color? backgroundColor,
  ShapeBorder? shape,
  Clip? clipBehavior,
  RouteSettings? routeSettings,
}) {
  final noMotion = MediaQuery.of(context).disableAnimations;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    sheetAnimationStyle: noMotion ? AnimationStyle.noAnimation : null,
    backgroundColor: Colors.transparent,
    routeSettings: routeSettings,
    shape: shape,
    clipBehavior: clipBehavior,
    builder: (sheet) =>
        MLPLiquidSurface(grouped: false, radius: 28, child: builder(sheet)),
  );
}

/// A mutually exclusive choice with the same glass treatment as form fields.
class MLPSelectionTile extends StatelessWidget {
  const MLPSelectionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Semantics(
      container: true,
      checked: selected,
      inMutuallyExclusiveGroup: true,
      child: MLPLiquidSurface(
        blur: false,
        radius: 14,
        tint: selected ? const Color(0xFF174A86) : null,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onSelected,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? CupertinoIcons.checkmark_circle_fill
                        : CupertinoIcons.circle,
                    size: 22,
                    color: selected
                        ? MLPColors.turquoise
                        : MLPColors.secondaryText,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 15, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
