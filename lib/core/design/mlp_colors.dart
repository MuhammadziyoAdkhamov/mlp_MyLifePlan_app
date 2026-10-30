import 'package:flutter/material.dart';

/// MYLife Plan 3.0 Color System — Dark Navy + Purple/Electric Blue
class MlpColors {
  const MlpColors._();

  // Backgrounds — navy dark
  static const bg0 = Color(0xFF070B18);  // deepest background
  static const bg1 = Color(0xFF0C1229);  // main scaffold bg
  static const bg2 = Color(0xFF111836);  // card surface
  static const bg3 = Color(0xFF182244);  // elevated card
  static const bg4 = Color(0xFF1F2A52);  // hover / pressed

  // Borders
  static const border = Color(0xFF26326A);
  static const borderSoft = Color(0xFF1C244F);

  // Primary — Purple
  static const purple = Color(0xFF7C5CFF);
  static const purpleLight = Color(0xFFA78BFA);
  static const purpleDark = Color(0xFF5B3FCC);

  // Accent — Electric Blue
  static const blue = Color(0xFF3B82F6);
  static const blueLight = Color(0xFF60A5FA);
  static const electric = Color(0xFF22D3EE);

  // Semantic
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFF43F5E);
  static const info = Color(0xFF6366F1);

  // Text
  static const text1 = Color(0xFFF1F5F9);  // primary
  static const text2 = Color(0xFF94A3B8);  // secondary
  static const text3 = Color(0xFF64748B);  // muted
  static const text4 = Color(0xFF475569);  // disabled

  // XP / Gold
  static const gold = Color(0xFFFBBF24);
  static const goldDark = Color(0xFFD97706);

  // Gradients
  static const gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purple, blue],
  );

  static const gradientBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0C1229), Color(0xFF070B18)],
  );

  static const gradientGold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gold, goldDark],
  );

  static const gradientSuccess = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, Color(0xFF059669)],
  );
}
