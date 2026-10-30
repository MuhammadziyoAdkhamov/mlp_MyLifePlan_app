import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../demo/demo_store.dart';
import '../data/repositories/mlp_ui_repository.dart';
import '../features/focus/mlp_focus_controller.dart';
import 'router/mlp_routes.dart';
import 'theme/mlp_design_system.dart';
import '../core/design_system/mlp_widgets.dart';
import '../core/design_system/mlp_liquid_glass.dart';

class MLPEnvironment {
  MLPEnvironment({
    required this.store,
    required this.ui,
    required this.prefs,
    required this.focus,
    required this.clock,
    required this.go,
    required this.tab,
    required this.legacy,
  });
  final DemoStore store;
  final MLPLocalUiRepository ui;
  final SharedPreferences prefs;
  final MLPFocusController focus;
  final DateTime Function() clock;
  final Future<void> Function(MLPScreen, {MLPRouteArgs? args}) go;
  final void Function(int) tab;
  final Widget Function() legacy;
  Future<void> act(
    BuildContext context,
    Future<void> Function() work, {
    String? success,
  }) async {
    try {
      await work();
      if (success != null && context.mounted) MLPToast.show(context, success);
    } catch (error) {
      if (context.mounted) {
        MLPToast.show(
          context,
          error is StateError
              ? error.message
              : error is ArgumentError
              ? '${error.message}'
              : 'Amal saqlanmadi. Qayta urinib ko‘ring.',
        );
      }
    }
  }

  Future<void> info(BuildContext context, String title, String text) =>
      mlpShowDialog<void>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: Text(text)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Yopish'),
            ),
          ],
        ),
      );
}

class MLPPage extends StatelessWidget {
  const MLPPage({
    super.key,
    this.title,
    required this.children,
    this.actions,
    this.background,
  });
  final String? title;
  final Widget? background;
  final List<Widget> children;
  final List<Widget>? actions;
  @override
  Widget build(BuildContext context) {
    final body = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920),
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 12, 20, title == null ? 100 : 28),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: children,
        ),
      ),
    );
    return title == null
        ? body
        : MLPScaffold(
            title: title,
            actions: actions,
            body: body,
            background: background,
          );
  }
}

class MLPNotice extends StatelessWidget {
  const MLPNotice(this.text, {super.key, this.warning = false});
  final String text;
  final bool warning;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: MLPGlassCard(
      padding: 16,
      child: Text(
        text,
        style: TextStyle(
          color: warning ? MLPColors.warning : MLPColors.secondaryText,
          height: 1.5,
          fontSize: 12,
        ),
      ),
    ),
  );
}

class MLPMenuTile extends StatelessWidget {
  const MLPMenuTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
  });
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: MLPGlassCard(
      padding: 4,
      child: ListTile(
        minVerticalPadding: 12,
        leading: Icon(icon, color: MLPColors.turquoise),
        title: Text(title),
        subtitle: subtitle == null
            ? null
            : Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: onTap,
      ),
    ),
  );
}

class MLPMetrics extends StatelessWidget {
  const MLPMetrics({super.key, required this.items});
  final List<({String value, String label, IconData icon})> items;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final columns =
          items.length == 2 ||
              box.maxWidth < 310 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.3
          ? 2
          : 3;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: items
            .map(
              (item) => SizedBox(
                width: (box.maxWidth - (columns - 1) * 10) / columns,
                child: MLPStatCard(
                  value: item.value,
                  label: item.label,
                  icon: item.icon,
                  compact: columns == 3 && box.maxWidth < 600,
                ),
              ),
            )
            .toList(),
      );
    },
  );
}
