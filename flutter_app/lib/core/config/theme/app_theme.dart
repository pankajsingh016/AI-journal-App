import 'package:flutter/material.dart';

import 'theme_extension.dart';
import 'theme_palette.dart';

/// Builds ThemeData from a [ThemePalette]. Use [light] and [dark] with a theme id.
class AppTheme {
  AppTheme._();

  static ThemeData light([String? themeId]) {
    final p = ThemePalette.byId(themeId ?? ThemePalette.idWarm) ?? ThemePalette.getDefault();
    return _buildLight(p);
  }

  static ThemeData dark([String? themeId]) {
    final p = ThemePalette.byId(themeId ?? ThemePalette.idWarm) ?? ThemePalette.getDefault();
    return _buildDark(p);
  }

  static ThemeData _buildLight(ThemePalette p) {
    return ThemeData(
      useMaterial3: true,
      extensions: [p.extensionLight],
      colorScheme: ColorScheme.light(
        primary: p.primary,
        onPrimary: Colors.white,
        primaryContainer: p.primaryLight.withValues(alpha: 0.4),
        onPrimaryContainer: p.primaryDark,
        secondary: p.inspiration,
        onSecondary: p.onSurfaceLight,
        surface: p.surfaceLight,
        onSurface: p.onSurfaceLight,
        surfaceContainerHighest: p.surfaceVariantLight,
        onSurfaceVariant: p.onSurfaceVariantLight,
        outline: p.outlineLight,
        error: p.error,
        onError: Colors.white,
        errorContainer: p.error.withValues(alpha: 0.12),
        onErrorContainer: p.error,
      ),
      scaffoldBackgroundColor: p.surfaceLight,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: p.surfaceLight,
        foregroundColor: p.onSurfaceLight,
        titleTextStyle: TextStyle(
          color: p.onSurfaceLight,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: p.cardLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.outlineLight.withValues(alpha: 0.7)),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.cardLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.outlineLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: p.onSurfaceVariantLight),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.cardLight,
        selectedItemColor: p.primary,
        unselectedItemColor: p.onSurfaceVariantLight,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.cardLight,
        indicatorColor: p.primary.withValues(alpha: 0.12),
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: p.primary,
            );
          }
          return TextStyle(
            fontSize: 12,
            color: p.onSurfaceVariantLight,
          );
        }),
      ),
      textTheme: _textTheme(p.onSurfaceLight),
      dividerColor: p.outlineLight.withValues(alpha: 0.8),
    );
  }

  static ThemeData _buildDark(ThemePalette p) {
    return ThemeData(
      useMaterial3: true,
      extensions: [p.extensionDark],
      colorScheme: ColorScheme.dark(
        primary: p.primaryLight,
        onPrimary: p.primaryDark,
        primaryContainer: p.primaryDark,
        onPrimaryContainer: p.primaryLight,
        secondary: p.inspirationMuted,
        onSecondary: p.onSurfaceDark,
        surface: p.surfaceDark,
        onSurface: p.onSurfaceDark,
        surfaceContainerHighest: p.surfaceVariantDark,
        onSurfaceVariant: p.onSurfaceVariantDark,
        outline: p.outlineDark,
        error: p.error,
        onError: Colors.white,
        errorContainer: p.error.withValues(alpha: 0.25),
        onErrorContainer: const Color(0xFFFECACA),
      ),
      scaffoldBackgroundColor: p.surfaceDark,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: p.surfaceDark,
        foregroundColor: p.onSurfaceDark,
        titleTextStyle: TextStyle(
          color: p.onSurfaceDark,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: p.surfaceVariantDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.outlineDark.withValues(alpha: 0.5)),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceVariantDark,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.outlineDark.withValues(alpha: 0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.primaryLight, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: p.onSurfaceVariantDark),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.surfaceVariantDark,
        selectedItemColor: p.primaryLight,
        unselectedItemColor: p.onSurfaceVariantDark,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surfaceVariantDark,
        indicatorColor: p.primaryLight.withValues(alpha: 0.2),
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: p.primaryLight,
            );
          }
          return TextStyle(
            fontSize: 12,
            color: p.onSurfaceVariantDark,
          );
        }),
      ),
      textTheme: _textTheme(p.onSurfaceDark),
      dividerColor: p.outlineDark.withValues(alpha: 0.6),
    );
  }

  static TextTheme _textTheme(Color onSurface) {
    return TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: onSurface,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: onSurface,
        letterSpacing: 0.2,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: onSurface,
        height: 1.45,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: onSurface,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: onSurface.withValues(alpha: 0.85),
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: onSurface,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: onSurface.withValues(alpha: 0.85),
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: onSurface.withValues(alpha: 0.7),
        letterSpacing: 0.3,
      ),
    );
  }
}
