import 'package:flutter/material.dart';
import '../design/mlp_colors.dart';

class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: MlpColors.warning.withValues(alpha: 0.15),
        border: const Border(bottom: BorderSide(color: MlpColors.warning, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline_rounded, color: MlpColors.warning, size: 14),
          const SizedBox(width: 6),
          Text(
            message ?? '⚠️ DEMO rejim — Haqiqiy ma\'lumotlar saqlanmaydi',
            style: const TextStyle(color: MlpColors.warning, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
