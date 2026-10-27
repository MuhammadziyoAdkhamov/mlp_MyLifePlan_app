import 'package:flutter/material.dart';
import '../../app/theme/mlp_design_system.dart';

class MLPScaffold extends StatelessWidget {
  const MLPScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });
  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar, floatingActionButton;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: title == null ? null : MLPAppBar(title: title!, actions: actions),
    body: SafeArea(child: body),
    bottomNavigationBar: bottomNavigationBar,
    floatingActionButton: floatingActionButton,
    resizeToAvoidBottomInset: true,
  );
}

class MLPAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MLPAppBar({super.key, required this.title, this.actions});
  final String title;
  final List<Widget>? actions;
  @override
  Size get preferredSize => const Size.fromHeight(64);
  @override
  Widget build(BuildContext context) => AppBar(
    toolbarHeight: 64,
    title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
    actions: actions,
  );
}

class MLPFloatingTabBar extends StatelessWidget {
  const MLPFloatingTabBar({
    super.key,
    required this.index,
    required this.onChanged,
  });
  final int index;
  final ValueChanged<int> onChanged;
  static const labels = ['Bugun', 'Maqsadlar', 'Fokus', 'Ustoz', 'Profil'];
  static const icons = [
    Icons.wb_sunny_outlined,
    Icons.flag_outlined,
    Icons.timelapse_rounded,
    Icons.auto_awesome_outlined,
    Icons.person_outline_rounded,
  ];
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: MLPColors.elevated,
        border: Border.all(color: MLPColors.border),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: List.generate(
          labels.length,
          (i) => Expanded(
            child: Semantics(
              selected: index == i,
              button: true,
              label: labels[i],
              excludeSemantics: true,
              child: InkWell(
                onTap: () => onChanged(i),
                borderRadius: BorderRadius.circular(22),
                child: AnimatedContainer(
                  duration: MLPDimensions.motion(context),
                  constraints: const BoxConstraints(minHeight: 72),
                  margin: const EdgeInsets.all(4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: i == index
                        ? MLPColors.primary.withValues(alpha: .18)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icons[i],
                        color: i == index
                            ? MLPColors.primaryLight
                            : MLPColors.secondaryText,
                        size: 23,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        labels[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: i == index
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: i == index
                              ? MLPColors.primaryLight
                              : MLPColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
  Widget build(BuildContext context) => FilledButton(
    onPressed: busy ? null : onPressed,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (busy) ...[
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
        ] else if (icon != null) ...[
          Icon(icon, size: 19),
          const SizedBox(width: 8),
        ],
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
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
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
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
  Widget build(BuildContext context) => Material(
    color: accent ? MLPColors.elevated : MLPColors.secondary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(MLPDimensions.cardRadius),
      side: const BorderSide(color: MLPColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(padding: EdgeInsets.all(padding), child: child),
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
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
    ],
  );
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
  });
  final String value, label;
  final IconData icon;
  final String? caption;
  @override
  Widget build(BuildContext context) => MLPGlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: MLPColors.turquoise),
        const SizedBox(height: 12),
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        Text(label),
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
      await showModalBottomSheet<bool>(
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
      ),
      child: Icon(
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
