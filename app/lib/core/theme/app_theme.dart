import 'package:flutter/material.dart';

import 'tokens.dart';
import 'typography.dart';

ThemeData buildCyberPathTheme() {
  const scheme = ColorScheme.dark(
    primary: CpColors.primary,
    onPrimary: CpColors.onPrimary,
    secondary: CpColors.indigo,
    surface: CpColors.solidSurface,
    onSurface: CpColors.text,
    error: CpColors.error,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: CpColors.background,
    fontFamily: 'Inter',
    textTheme: TextTheme(
      headlineMedium: CpType.display(),
      titleLarge: CpType.title1(),
      titleMedium: CpType.title2(),
      bodyLarge: CpType.body(),
      bodyMedium: CpType.caption(color: CpColors.text),
      bodySmall: CpType.small(),
      labelSmall: CpType.label(),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF1B2127),
      contentTextStyle: CpType.caption(color: CpColors.text),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CpRadius.card)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF161B21),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CpRadius.cardLarge)),
      titleTextStyle: CpType.title2(),
      contentTextStyle: CpType.body(color: CpColors.textSecondary),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? CpColors.onPrimary : CpColors.text,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? CpColors.primary : CpColors.track,
      ),
      trackOutlineColor: WidgetStateProperty.all(CpColors.glassBorder),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: ZoomPageTransitionsBuilder()},
    ),
  );
}
