import 'package:flutter/material.dart';

/// Shared product tokens. Preview capability labels do not use success color.
abstract final class MLPColors {
  static const background = Color(0xFF090F22);
  static const secondary = Color(0xFF101A34);
  static const elevated = Color(0xFF172342);
  static const border = Color(0xFF2B3859);
  static const primary = Color(0xFF8C6BFF);
  static const primaryLight = Color(0xFFB6A3FF);
  static const turquoise = Color(0xFF44D8CD);
  static const success = Color(0xFF51D3A1);
  static const warning = Color(0xFFF4BC68);
  static const error = Color(0xFFFF8D9E);
  static const text = Color(0xFFF7F8FF);
  static const secondaryText = Color(0xFFAAB6D5);
  static const muted = Color(0xFF7887AB);
}

abstract final class MLPDimensions {
  static const inset = 24.0;
  static const smallInset = 20.0;
  static const cardRadius = 20.0;
  static const controlRadius = 14.0;
  static const touchTarget = 48.0;
  static const compactMotion = Duration(milliseconds: 180);
  static const routeMotion = Duration(milliseconds: 240);

  static Duration motion(BuildContext context, {bool route = false}) =>
      MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : route
      ? routeMotion
      : compactMotion;
}

abstract final class MLPTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final text = base.textTheme.apply(
      bodyColor: MLPColors.text,
      displayColor: MLPColors.text,
      fontFamily: 'Segoe UI',
    );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(MLPDimensions.controlRadius),
      borderSide: const BorderSide(color: MLPColors.border),
    );
    return base.copyWith(
      scaffoldBackgroundColor: MLPColors.background,
      colorScheme: const ColorScheme.dark(
        primary: MLPColors.primary,
        onPrimary: MLPColors.background,
        secondary: MLPColors.turquoise,
        onSecondary: MLPColors.background,
        surface: MLPColors.secondary,
        onSurface: MLPColors.text,
        onSurfaceVariant: MLPColors.secondaryText,
        error: MLPColors.error,
      ),
      textTheme: text.copyWith(
        displaySmall: const TextStyle(
          fontSize: 32,
          height: 1.2,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: const TextStyle(
          fontSize: 28,
          height: 1.25,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: const TextStyle(
          fontSize: 24,
          height: 1.3,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: const TextStyle(
          fontSize: 20,
          height: 1.35,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: const TextStyle(fontSize: 16, height: 1.5),
        bodyMedium: const TextStyle(fontSize: 14, height: 1.5),
        bodySmall: const TextStyle(
          fontSize: 12,
          height: 1.5,
          color: MLPColors.secondaryText,
        ),
      ),
      dividerColor: MLPColors.border,
      appBarTheme: const AppBarTheme(
        backgroundColor: MLPColors.background,
        foregroundColor: MLPColors.text,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MLPColors.background,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(
            color: MLPColors.primaryLight,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.all(16),
        errorMaxLines: 3,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: MLPColors.primaryLight,
          foregroundColor: MLPColors.background,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: 'Segoe UI',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MLPDimensions.controlRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: MLPColors.primaryLight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          side: const BorderSide(color: MLPColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MLPDimensions.controlRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: MLPColors.primaryLight,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      chipTheme: ChipThemeData(
        selectedColor: MLPColors.primary.withValues(alpha: .18),
        side: const BorderSide(color: MLPColors.border),
        labelStyle: const TextStyle(fontSize: 12, color: MLPColors.text),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: MLPColors.elevated,
        contentTextStyle: TextStyle(color: MLPColors.text),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: MLPColors.turquoise,
      ),
    );
  }
}
