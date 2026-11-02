import 'package:flutter/material.dart';

import '../app/theme/mlp_design_system.dart';
import '../core/design_system/mlp_liquid_glass.dart';

class PremiumScaffold extends StatelessWidget {
  const PremiumScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.safeArea = true,
  });

  final Widget body;
  final Widget? bottomNavigationBar;
  final EdgeInsets padding;
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      children: [
        // Use MLP liquid glass background
        const Positioned.fill(
          child: MLPLiquidBackground(),
        ),
        // Content
        Padding(
          padding: padding,
          child: safeArea ? SafeArea(child: body) : body,
        ),
      ],
    );

    return Scaffold(
      backgroundColor: MLPColors.background,
      extendBody: bottomNavigationBar != null,
      body: content,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
