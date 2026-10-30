import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui' as ui;
import '../../app/theme/mlp_design_system.dart';
import 'mlp_liquid_glass.dart';

class MLPScaffold extends StatelessWidget {
  const MLPScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.leading,
    this.background,
  });
  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar, floatingActionButton;
  final Widget? leading;
  final Widget? background;
  @override
  Widget build(BuildContext context) => BackdropGroup(
    child: Scaffold(
      backgroundColor: MLPColors.background,
      extendBody: bottomNavigationBar != null,
      appBar: title == null
          ? null
          : MLPAppBar(title: title!, actions: actions, leading: leading),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: background ?? const MLPLiquidBackground()),
          SafeArea(bottom: bottomNavigationBar == null, child: body),
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      resizeToAvoidBottomInset: true,
    ),
  );
}

class MLPAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MLPAppBar({super.key, required this.title, this.actions, this.leading});
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  @override
  Size get preferredSize => const Size.fromHeight(56);
  @override
  Widget build(BuildContext context) => ClipRect(
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: AppBar(
        leading: leading,
        centerTitle: true,
        toolbarHeight: 56,
        flexibleSpace: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                MLPColors.secondary.withValues(alpha: .7),
                MLPColors.background.withValues(alpha: .45),
              ],
            ),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: .045)),
            ),
          ),
        ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: actions,
      ),
    ),
  );
}

class MLPFloatingTabBar extends StatelessWidget {
  const MLPFloatingTabBar({
    super.key,
    required this.index,
    required this.onChanged,
    this.onAdd,
  });
  final int index;
  final ValueChanged<int> onChanged;
  final VoidCallback? onAdd;
  // Public route indices remain compatible with existing feature callbacks.
  static const entries = [
    (0, 'Bugun', CupertinoIcons.house_fill),
    (1, 'Maqsadlar', CupertinoIcons.list_bullet),
    (2, 'Fokus', CupertinoIcons.timer),
    (6, 'Ustoz', CupertinoIcons.chat_bubble_2),
    (5, 'Profil', CupertinoIcons.person),
  ];
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
          child: MLPLiquidSurface(
            grouped: false,
            radius: 36,
            child: Row(
              children: [
                for (final item in entries)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected:
                          index == item.$1 || (index == 3 && item.$1 == 1),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => onChanged(item.$1),
                          child: AnimatedContainer(
                            duration: MLPDimensions.motion(context),
                            constraints: const BoxConstraints(minHeight: 64),
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 2,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: item.$1 == 2
                                  ? (index == 2
                                      ? const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFF00E5FF),
                                            Color(0xFF2979FF),
                                          ],
                                        )
                                      : const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0x3300E5FF),
                                            Color(0x332979FF),
                                          ],
                                        ))
                                  : (index == item.$1 ||
                                          (index == 3 && item.$1 == 1)
                                      ? const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0x994758FF),
                                            Color(0x6600D1FF),
                                          ],
                                        )
                                      : null),
                              border: Border.all(
                                color: item.$1 == 2
                                    ? (index == 2
                                        ? const Color(0xFF00F0FF)
                                        : const Color(0x6600E5FF))
                                    : (index == item.$1 ||
                                            (index == 3 && item.$1 == 1)
                                        ? const Color(0x886CBFFF)
                                        : Colors.transparent),
                                width: item.$1 == 2 ? 1.5 : 1.0,
                              ),
                              boxShadow: item.$1 == 2
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF00E5FF)
                                            .withValues(alpha: index == 2 ? 0.45 : 0.2),
                                        blurRadius: index == 2 ? 16 : 8,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item.$1 == 2
                                      ? CupertinoIcons.stopwatch_fill
                                      : item.$3,
                                  size: item.$1 == 2 ? 26 : 24,
                                  color: item.$1 == 2
                                      ? (index == 2
                                          ? Colors.white
                                          : const Color(0xFF00E5FF))
                                      : (index == item.$1 ||
                                              (index == 3 && item.$1 == 1)
                                          ? MLPColors.turquoise
                                          : MLPColors.secondaryText),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.$2,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: item.$1 == 2 || index == item.$1
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: item.$1 == 2 && index == 2
                                        ? Colors.white
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class MLPPrimaryButton extends StatelessWidget {
  const MLPPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  @override
  Widget build(BuildContext context) => MLPPressResponse(
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: onPressed == null || busy
            ? null
            : const LinearGradient(
                colors: [
                  Color(0xFF00D9F5),
                  Color(0xFF3C49FF),
                  Color(0xFFBA6AFF),
                ],
                stops: [0, .55, 1],
              ),
        border: Border.all(
          color: Colors.white.withValues(alpha: onPressed == null ? .1 : .45),
        ),
        boxShadow: onPressed == null
            ? []
            : [
                BoxShadow(
                  color: MLPColors.primary.withValues(alpha: .15),
                  blurRadius: 18,
                ),
              ],
      ),
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: MLPColors.elevated,
          minimumSize: const Size(48, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        onPressed: busy ? null : onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (busy) ...[
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
            ] else if (icon != null) ...[
              Icon(icon, size: 22),
              const SizedBox(width: 8),
            ],
            Flexible(child: Text(label, textAlign: TextAlign.center)),
          ],
        ),
      ),
    ),
  );
}

class MLPSecondaryButton extends StatelessWidget {
  const MLPSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => MLPPressResponse(
    child: OutlinedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ],
      ),
    ),
  );
}

class MLPIconButton extends StatelessWidget {
  const MLPIconButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) =>
      IconButton(tooltip: label, onPressed: onPressed, icon: Icon(icon));
}

class MLPGlassCard extends StatelessWidget {
  const MLPGlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = 20,
    this.accent = false,
  });
  final Widget child;
  final VoidCallback? onTap;
  final double padding;
  final bool accent;
  @override
  Widget build(BuildContext context) => MLPLiquidSurface(
    radius: MLPDimensions.cardRadius,
    tint: accent ? MLPColors.elevated : null,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: EdgeInsets.all(padding), child: child),
      ),
    ),
  );
}

class MLPSectionHeader extends StatelessWidget {
  const MLPSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) {
    final heading = Text(title, style: Theme.of(context).textTheme.titleLarge);
    final actionButton = action == null
        ? null
        : TextButton(onPressed: onAction, child: Text(action!));
    if (MediaQuery.textScalerOf(context).scale(1) > 1.3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading,
          if (actionButton != null)
            Align(alignment: Alignment.centerRight, child: actionButton),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: heading),
        if (actionButton != null) Flexible(child: actionButton),
      ],
    );
  }
}

class MLPTextField extends StatelessWidget {
  const MLPTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.autofocus = false,
    this.enabled = true,
    this.onChanged,
  });
  final TextEditingController controller;
  final String label;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? maxLength;
  final bool autofocus;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    enabled: enabled,
    onTapOutside: (_) => FocusScope.of(context).unfocus(),
    decoration: InputDecoration(labelText: label, hintText: hint),
    keyboardType: keyboardType,
    validator: validator,
    maxLines: maxLines,
    maxLength: maxLength,
    autofocus: autofocus,
    onChanged: onChanged,
    textInputAction: maxLines == 1
        ? TextInputAction.next
        : TextInputAction.newline,
  );
}

class MLPPhoneField extends StatelessWidget {
  const MLPPhoneField({
    super.key,
    required this.controller,
    this.optional = false,
  });
  final TextEditingController controller;
  final bool optional;
  static String? validate(String? value, {bool optional = false}) {
    final text = (value ?? '').trim();
    if (optional && text.isEmpty) return null;
    final normalized = text.replaceAll(RegExp(r'[\s()\-]'), '');
    return RegExp(r'^\+998\d{9}$').hasMatch(normalized)
        ? null
        : '+998 va 9 xonali raqam kiriting.';
  }

  @override
  Widget build(BuildContext context) => MLPTextField(
    controller: controller,
    label: 'Telefon raqami',
    hint: '+998 90 123 45 67',
    keyboardType: TextInputType.phone,
    validator: (v) => validate(v, optional: optional),
  );
}

class MLPProgressBar extends StatelessWidget {
  const MLPProgressBar({super.key, required this.value, required this.label});
  final double value;
  final String label;
  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    value: '${(value.clamp(0, 1) * 100).round()} foiz',
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: 7,
        backgroundColor: MLPColors.elevated,
        color: MLPColors.turquoise,
      ),
    ),
  );
}

class MLPProgressRing extends StatelessWidget {
  const MLPProgressRing({
    super.key,
    required this.value,
    required this.label,
    this.size = 120,
  });
  final double value, size;
  final String label;
  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    value: '${(value.clamp(0, 1) * 100).round()} foiz',
    child: SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: value.clamp(0, 1),
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
              backgroundColor: MLPColors.elevated,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Text(
              '${(value.clamp(0, 1) * 100).round()}%',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ],
      ),
    ),
  );
}

class MLPStatCard extends StatelessWidget {
  const MLPStatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    this.caption,
    this.compact = false,
  });
  final String value, label;
  final IconData icon;
  final String? caption;
  final bool compact;
  @override
  Widget build(BuildContext context) => MLPGlassCard(
    padding: compact ? 12 : 20,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: MLPColors.turquoise, size: compact ? 18 : 24),
        SizedBox(height: compact ? 8 : 12),
        Text(
          value,
          style: compact
              ? const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)
              : Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: compact
              ? const TextStyle(fontSize: 11, color: MLPColors.secondaryText)
              : null,
        ),
        if (caption != null)
          Text(caption!, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class MLPEmptyState extends StatelessWidget {
  const MLPEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
    this.icon = Icons.spa_outlined,
  });
  final String title, message;
  final String? action;
  final VoidCallback? onAction;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 40, color: MLPColors.turquoise),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (action != null) ...[
          const SizedBox(height: 16),
          MLPPrimaryButton(label: action!, onPressed: onAction),
        ],
      ],
    ),
  );
}

class MLPLoadingState extends StatelessWidget {
  const MLPLoadingState({super.key, this.label = 'Yuklanmoqda…'});
  final String label;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: label,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(label),
          ],
        ),
      ),
    ),
  );
}

class MLPErrorState extends StatelessWidget {
  const MLPErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => MLPEmptyState(
    title: 'Amal bajarilmadi',
    message: message,
    icon: Icons.error_outline_rounded,
    action: 'Qayta urinish',
    onAction: onRetry,
  );
}

abstract final class MLPConfirmationSheet {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirm = 'Tasdiqlash',
  }) async =>
      await mlpShowSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (sheet) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.viewInsetsOf(sheet).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: Theme.of(sheet).textTheme.titleLarge),
                const SizedBox(height: 12),
                Text(message),
                const SizedBox(height: 24),
                MLPPrimaryButton(
                  label: confirm,
                  onPressed: () => Navigator.pop(sheet, true),
                ),
                const SizedBox(height: 8),
                MLPSecondaryButton(
                  label: 'Bekor qilish',
                  onPressed: () => Navigator.pop(sheet, false),
                ),
              ],
            ),
          ),
        ),
      ) ??
      false;
}

abstract final class MLPToast {
  static void show(BuildContext context, String message) =>
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
}

enum MLPOrbState { idle, listening, thinking, speaking, muted }

class MLPWelcomeHero extends StatelessWidget {
  const MLPWelcomeHero({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'MLP — fokusli hayot uchun',
    excludeSemantics: true,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 230,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(painter: _MLPHorizonPainter()),
            Padding(
              padding: const EdgeInsets.only(top: 22),
              child: Column(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [MLPColors.turquoise, MLPColors.primaryLight],
                    ).createShader(bounds),
                    child: const Text(
                      'MLP',
                      textScaler: TextScaler.noScaling,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 70,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -3,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'FOKUSLI HAYOT UCHUN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3,
                      color: MLPColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MLPHorizonPainter extends CustomPainter {
  const _MLPHorizonPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final planet = Offset(size.width * .5, size.height * .98);
    canvas.drawCircle(
      planet,
      size.height * .5,
      Paint()
        ..shader =
            const RadialGradient(
              colors: [Color(0xFFADDEFF), Color(0xFF1B87C9), Color(0x0000D1EF)],
              stops: [0, .48, 1],
            ).createShader(
              Rect.fromCircle(center: planet, radius: size.height * .5),
            ),
    );
    for (var i = 0; i < 19; i++) {
      canvas.drawCircle(
        Offset(
          ((i * 71 + 17) % 311) / 311 * size.width,
          ((i * 37 + 11) % 113) / 113 * size.height * .65,
        ),
        i % 3 == 0 ? 1 : .6,
        Paint()..color = MLPColors.secondaryText.withValues(alpha: .25),
      );
    }
    final layers = [
      (
        const Color(0xFF173257),
        [.64, .76, .59, .8, .69, .88, .72, .83, .6, .76, .67],
      ),
      (
        const Color(0xFF10233C),
        [.86, .72, .85, .69, .84, .73, .91, .76, .84, .72, .87],
      ),
      (
        const Color(0xFF0B1728),
        [.94, .9, .96, .85, .7, .61, .79, .87, .85, .97, .89],
      ),
    ];
    for (final layer in layers) {
      final path = Path()..moveTo(0, size.height);
      for (var i = 0; i < layer.$2.length; i++) {
        path.lineTo(
          i / (layer.$2.length - 1) * size.width,
          layer.$2[i] * size.height,
        );
      }
      path.lineTo(size.width, size.height);
      path.close();
      canvas.drawPath(path, Paint()..color = layer.$1);
    }
  }

  @override
  bool shouldRepaint(covariant _MLPHorizonPainter oldDelegate) => false;
}

class MLPAvatarOrb extends StatelessWidget {
  const MLPAvatarOrb({
    super.key,
    this.state = MLPOrbState.idle,
    this.size = 116,
    this.label = 'USTOZ AI demo yordamchisi',
  });
  final MLPOrbState state;
  final double size;
  final String label;
  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: AnimatedContainer(
      duration: MLPDimensions.motion(context),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: MLPColors.turquoise.withValues(
          alpha: state == MLPOrbState.idle ? .08 : .16,
        ),
        border: Border.all(
          color: state == MLPOrbState.muted
              ? MLPColors.secondaryText
              : MLPColors.turquoise,
          width: state == MLPOrbState.listening ? 4 : 1.5,
        ),
        gradient: const RadialGradient(
          colors: [Color(0xFF16274B), Color(0xFF050A19)],
        ),
        boxShadow: [
          BoxShadow(
            color: MLPColors.turquoise.withValues(alpha: .28),
            blurRadius: size * .24,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: MLPColors.primary.withValues(alpha: .18),
            blurRadius: size * .42,
            spreadRadius: 5,
          ),
        ],
      ),
      child: state == MLPOrbState.idle
          ? Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 2; i++)
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: size * .065),
                      width: size * .075,
                      height: size * .22,
                      decoration: BoxDecoration(
                        color: i == 0
                            ? MLPColors.primaryLight
                            : MLPColors.turquoise,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: MLPColors.turquoise.withValues(alpha: .7),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            )
          : Icon(
              switch (state) {
                MLPOrbState.listening => Icons.graphic_eq_rounded,
                MLPOrbState.thinking => Icons.more_horiz_rounded,
                MLPOrbState.speaking => Icons.volume_up_outlined,
                MLPOrbState.muted => Icons.mic_off_outlined,
                _ => Icons.auto_awesome_rounded,
              },
              color: MLPColors.turquoise,
              size: size * .35,
            ),
    ),
  );
}

class MLPTimerDisplay extends StatelessWidget {
  const MLPTimerDisplay({
    super.key,
    required this.seconds,
    required this.label,
  });
  final int seconds;
  final String label;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label: ${seconds ~/ 60} daqiqa ${seconds % 60} soniya',
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}',
        style: const TextStyle(
          fontSize: 56,
          fontWeight: FontWeight.w600,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    ),
  );
}

class MLPGoalCard extends StatelessWidget {
  const MLPGoalCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.onTap,
  });
  final String title, subtitle;
  final double progress;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => MLPGlassCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        MLPProgressBar(value: progress, label: title),
      ],
    ),
  );
}

class MLPTaskCard extends StatelessWidget {
  const MLPTaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.completed,
    required this.onTap,
  });
  final String title, subtitle;
  final bool completed;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => MLPGlassCard(
    onTap: onTap,
    child: Row(
      children: [
        Icon(
          completed ? Icons.check_circle_outline : Icons.radio_button_unchecked,
          color: completed ? MLPColors.success : MLPColors.secondaryText,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded),
      ],
    ),
  );
}

class MLPRewardCard extends StatelessWidget {
  const MLPRewardCard({
    super.key,
    required this.title,
    required this.status,
    required this.onTap,
    this.icon = Icons.workspace_premium_outlined,
  });
  final String title, status;
  final VoidCallback onTap;
  final IconData icon;
  @override
  Widget build(BuildContext context) => MLPGlassCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: MLPColors.warning, size: 30),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        Text(status, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}
