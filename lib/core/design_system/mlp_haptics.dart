import 'package:flutter/services.dart';

/// Professional iOS-inspired Haptic Feedback engine for MLP
class MLPHaptics {
  const MLPHaptics._();

  /// Light tap for buttons, chips, tabs, selection changes
  static void light() {
    HapticFeedback.lightImpact();
  }

  /// Medium tap for actions like task completion, toggle switches
  static void medium() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy crisp haptic for timer start/stop, dangerous actions
  static void heavy() {
    HapticFeedback.heavyImpact();
  }

  /// Micro click for slider adjustments, wheel picker, stepper
  static void selection() {
    HapticFeedback.selectionClick();
  }

  /// Success pattern for completing a goal, finishing focus session, earning XP
  static void success() {
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 120), () {
      HapticFeedback.lightImpact();
    });
  }

  /// Error or warning alert haptic
  static void error() {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.heavyImpact();
    });
  }
}
