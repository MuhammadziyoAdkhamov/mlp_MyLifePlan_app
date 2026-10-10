import 'package:flutter/material.dart';

import '../core/app_colors.dart';

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
    final content = Container(
      decoration: const BoxDecoration(gradient: AppColors.premiumBackground),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.14),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withOpacity(0.22), blurRadius: 90),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyan.withOpacity(0.08),
                boxShadow: [
                  BoxShadow(color: AppColors.cyan.withOpacity(0.16), blurRadius: 90),
                ],
              ),
            ),
          ),
          Padding(padding: padding, child: safeArea ? SafeArea(child: body) : body),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: content,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
