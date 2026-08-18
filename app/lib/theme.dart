import 'package:flutter/material.dart';

/// Tokens do design system (spec 2026-06-08). Toda cor da UI sai daqui.
abstract class AppColors {
  static const background = Color(0xFF0A0A0F);
  static const surface = Color(0xFF12121A);
  static const border = Color(0xFF1E1E2E);
  static const goldPrimary = Color(0xFFD4AF37);
  static const goldLight = Color(0xFFF0D060);
  static const upGreen = Color(0xFF00C896);
  static const downRed = Color(0xFFFF4D6A);
  static const textPrimary = Color(0xFFF0F0F0);
  static const textSecondary = Color(0xFF8888A0);
}

abstract class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

abstract class AppRadius {
  static const card = 12.0;
  static const control = 8.0; // inputs, abas, chips
}

/// Cores de indicadores técnicos — distintas dos tokens semânticos de
/// alta/queda (upGreen/downRed) para não confundir leitura do gráfico.
abstract class IndicatorColors {
  static const smaFast = AppColors.goldLight; // SMA 9
  static const smaSlow = AppColors.textSecondary; // SMA 21
  static const rsi = AppColors.goldLight;
}

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  fontFamily: 'Inter',
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.goldPrimary,
    secondary: AppColors.goldLight,
    surface: AppColors.surface,
    error: AppColors.downRed,
    onPrimary: AppColors.background,
    onSurface: AppColors.textPrimary,
  ),
  dividerColor: AppColors.border,
  textTheme: const TextTheme(
    headlineLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
    headlineMedium: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    titleMedium: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    bodyMedium: TextStyle(color: AppColors.textPrimary),
    bodySmall: TextStyle(color: AppColors.textSecondary),
    labelMedium: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
  ),
  cardTheme: CardThemeData(
    color: AppColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
      side: const BorderSide(color: AppColors.border),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.goldPrimary,
    foregroundColor: AppColors.background,
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      side: const BorderSide(color: AppColors.goldPrimary),
      foregroundColor: AppColors.goldPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control)),
    ),
  ),
  segmentedButtonTheme: SegmentedButtonThemeData(
    style: SegmentedButton.styleFrom(
      selectedBackgroundColor: AppColors.goldPrimary,
      selectedForegroundColor: AppColors.background,
      foregroundColor: AppColors.textSecondary,
      side: const BorderSide(color: AppColors.border),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surface,
    labelStyle: const TextStyle(color: AppColors.textSecondary),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.control),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.control),
      borderSide: const BorderSide(color: AppColors.goldPrimary),
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.surface,
    selectedItemColor: AppColors.goldPrimary,
    unselectedItemColor: AppColors.textSecondary,
    type: BottomNavigationBarType.fixed,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.background,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
  ),
);

// ponytail: spec pede ThemeMode.system com dark default; tema claro não desenhado
// na spec — só dark implementado. Adicionar lightTheme quando design existir.
