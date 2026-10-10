import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const background = Color(0xFF050816);
  static const background2 = Color(0xFF080D1F);
  static const surface = Color(0xFF0D1328);
  static const surface2 = Color(0xFF111936);
  static const surface3 = Color(0xFF18213F);
  static const border = Color(0xFF26304F);
  static const borderSoft = Color(0xFF1A2444);

  static const primary = Color(0xFF7C5CFF);
  static const primary2 = Color(0xFF4B6BFF);
  static const cyan = Color(0xFF22D3EE);
  static const emerald = Color(0xFF10B981);
  static const gold = Color(0xFFF59E0B);
  static const orange = Color(0xFFFFB020);
  static const rose = Color(0xFFF43F5E);
  static const red = Colors.red;
  static const violet = Color(0xFFA855F7);

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFA1A1AA);
  static const textMuted = Color(0xFF6B7280);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primary2],
  );

  static const energyGradient = SweepGradient(
    colors: [cyan, primary2, primary, emerald, cyan],
  );

  static const premiumBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF08112B), background, Color(0xFF02040D)],
  );

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gold, orange],
  );

  static Color categoryColor(String name) {
    switch (name.toLowerCase()) {
      case 'health':
        return emerald;
      case 'study':
        return primary2;
      case 'mind':
        return violet;
      case 'faith':
        return gold;
      case 'money':
        return cyan;
      default:
        return textMuted;
    }
  }
}
