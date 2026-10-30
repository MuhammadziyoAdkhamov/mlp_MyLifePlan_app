import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Shared product tokens. Preview capability labels do not use success color.
abstract final class MLPColors {
  static const background = Color(0xFF040916);
  static const secondary = Color(0xFF0C1422);
  static const elevated = Color(0xFF172334);
  static const border = Color(0xFF26344A);
  static const primary = Color(0xFFA855F7);
  static const primaryLight = Color(0xFFB6A3FF);
  static const turquoise = Color(0xFF00D1FF);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
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

/// Secondary Material routes use the same accessibility policy as the shell.
class MLPPageTransitionsBuilder extends CupertinoPageTransitionsBuilder {
  const MLPPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return super.buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
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
      cupertinoOverrideTheme: const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: MLPColors.turquoise,
        barBackgroundColor: Color(0xB30C1422),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: MLPPageTransitionsBuilder(),
          TargetPlatform.android: MLPPageTransitionsBuilder(),
          TargetPlatform.windows: MLPPageTransitionsBuilder(),
          TargetPlatform.macOS: MLPPageTransitionsBuilder(),
          TargetPlatform.linux: MLPPageTransitionsBuilder(),
          TargetPlatform.fuchsia: MLPPageTransitionsBuilder(),
        },
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: MLPColors.elevated.withValues(alpha: .88),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: BorderSide(
            color: Colors.white.withValues(alpha: .16),
            width: .8,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: MLPColors.elevated.withValues(alpha: .86),
        modalBackgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: Colors.white.withValues(alpha: .24),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: MLPColors.turquoise,
        selectionColor: MLPColors.turquoise.withValues(alpha: .25),
        selectionHandleColor: MLPColors.turquoise,
      ),
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
      textTheme: text
          .copyWith(
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
          )
          .apply(
            fontFamily: 'Segoe UI',
            bodyColor: MLPColors.text,
            displayColor: MLPColors.text,
          )
          .copyWith(
            bodySmall: const TextStyle(
              fontFamily: 'Segoe UI',
              fontSize: 12,
              height: 1.5,
              color: MLPColors.secondaryText,
            ),
          ),
      dividerColor: MLPColors.border,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: MLPColors.text,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: .04),
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
          backgroundColor: MLPColors.turquoise,
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
        labelStyle: const TextStyle(
          fontSize: 12,
          color: MLPColors.text,
          fontFamily: 'Segoe UI',
        ),
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
