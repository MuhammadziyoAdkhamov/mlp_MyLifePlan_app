import 'package:flutter/material.dart';
import '../design/mlp_colors.dart';

class MlpScaffold extends StatelessWidget {
  const MlpScaffold({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.leading,
    this.bottomNavBar,
    this.withAppBar = false,
    this.padding,
    this.addBottomPadding = true,
  });

  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? bottomNavBar;
  final bool withAppBar;
  final EdgeInsetsGeometry? padding;
  final bool addBottomPadding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MlpColors.bg1,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: withAppBar && title != null
          ? AppBar(
              backgroundColor: MlpColors.bg1.withValues(alpha: 0.95),
              title: Text(title!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              centerTitle: false,
              leading: leading,
              actions: actions,
            )
          : null,
      bottomNavigationBar: bottomNavBar,
      body: Container(
        decoration: const BoxDecoration(gradient: MlpColors.gradientBg),
        child: SafeArea(
          bottom: addBottomPadding,
          child: padding != null ? Padding(padding: padding!, child: child) : child,
        ),
      ),
    );
  }
}
