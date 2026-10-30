import 'package:flutter/material.dart';
import '../design/mlp_colors.dart';

class XpChip extends StatelessWidget {
  const XpChip({super.key, required this.xp, this.isSmall = false});
  final int xp;
  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 12, vertical: isSmall ? 3 : 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [MlpColors.purple, MlpColors.blue]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: MlpColors.gold, size: isSmall ? 12 : 14),
          const SizedBox(width: 4),
          Text(
            '+$xp XP',
            style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700,
              fontSize: isSmall ? 11 : 13,
            ),
          ),
        ],
      ),
    );
  }
}

class CoinChip extends StatelessWidget {
  const CoinChip({super.key, required this.coins, this.isSmall = false});
  final int coins;
  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 12, vertical: isSmall ? 3 : 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [MlpColors.gold, MlpColors.goldDark]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(isSmall ? '🪙' : '🪙', style: TextStyle(fontSize: isSmall ? 12 : 14)),
          const SizedBox(width: 4),
          Text(
            '$coins',
            style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700,
              fontSize: isSmall ? 11 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
