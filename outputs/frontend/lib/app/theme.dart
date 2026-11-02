import 'package:flutter/material.dart';

abstract final class AppTokens {
  static const teal = Color(0xFF167C73);
  static const ink = Color(0xFF182F3D);
  static const background = Color(0xFFF6F8F7);
  static const mint = Color(0xFFE4F4EE);
  static const blue = Color(0xFFECF5FD);
  static const lavender = Color(0xFFF0EEFA);
  static const radius = 19.0;
  static const gutter = 24.0;
}

ThemeData appTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppTokens.teal,
        brightness: brightness,
      ).copyWith(
        primary: dark ? const Color(0xFF8AD4C8) : AppTokens.teal,
        surface: dark ? const Color(0xFF192D31) : Colors.white,
        onSurface: dark ? const Color(0xFFE6F1EE) : AppTokens.ink,
        onSurfaceVariant: dark
            ? const Color(0xFFBACBC7)
            : const Color(0xFF586C76),
      );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: 'Inter',
    fontFamilyFallback: const [
      'Noto Sans JP',
      'Hiragino Sans',
      'Yu Gothic',
      'sans-serif',
    ],
    scaffoldBackgroundColor: dark
        ? const Color(0xFF102024)
        : AppTokens.background,
    textTheme: TextTheme(
      headlineMedium: TextStyle(
        fontSize: 27,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
        letterSpacing: -.6,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.45,
        color: scheme.onSurface,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.4,
        color: scheme.onSurfaceVariant,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontFamilyFallback: ['Noto Sans JP'],
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: dark ? scheme.outlineVariant : const Color(0xFFE5ECEB),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide.none,
      backgroundColor: dark ? scheme.surfaceContainerHigh : AppTokens.mint,
      selectedColor: dark ? const Color(0xFF294B45) : const Color(0xFFC7E4D8),
      labelStyle: TextStyle(
        fontFamily: 'Inter',
        fontFamilyFallback: const ['Noto Sans JP'],
        color: dark ? scheme.primary : const Color(0xFF0D605A),
        fontSize: 12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: dark ? const Color(0xFF294B45) : AppTokens.mint,
      height: 78,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xFF102024) : AppTokens.background,
      surfaceTintColor: Colors.transparent,
    ),
  );
}

Color softColor(BuildContext context, Color light) =>
    Theme.of(context).brightness == Brightness.dark
    ? Theme.of(context).colorScheme.surfaceContainerHigh
    : light;
