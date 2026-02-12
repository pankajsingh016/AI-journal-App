import 'package:flutter/material.dart';

import 'theme_extension.dart';

/// One color theme: id, display info, and all colors for light/dark.
class ThemePalette {
  const ThemePalette({
    required this.id,
    required this.name,
    required this.description,
    required this.previewColors,
    // Light
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.surfaceLight,
    required this.surfaceVariantLight,
    required this.cardLight,
    required this.outlineLight,
    required this.onSurfaceLight,
    required this.onSurfaceVariantLight,
    required this.success,
    required this.successMuted,
    required this.inspiration,
    required this.inspirationMuted,
    required this.error,
    // Dark
    required this.surfaceDark,
    required this.surfaceVariantDark,
    required this.outlineDark,
    required this.onSurfaceDark,
    required this.onSurfaceVariantDark,
  });

  final String id;
  final String name;
  final String description;
  /// First 3–4 colors for theme preview swatch (e.g. primary, success, inspiration).
  final List<Color> previewColors;

  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color surfaceLight;
  final Color surfaceVariantLight;
  final Color cardLight;
  final Color outlineLight;
  final Color onSurfaceLight;
  final Color onSurfaceVariantLight;
  final Color success;
  final Color successMuted;
  final Color inspiration;
  final Color inspirationMuted;
  final Color error;
  final Color surfaceDark;
  final Color surfaceVariantDark;
  final Color outlineDark;
  final Color onSurfaceDark;
  final Color onSurfaceVariantDark;

  AppThemeColors get extensionLight => AppThemeColors(
        success: success,
        successMuted: successMuted,
        inspiration: inspiration,
        inspirationMuted: inspirationMuted,
      );

  AppThemeColors get extensionDark => AppThemeColors(
        success: success,
        successMuted: successMuted,
        inspiration: inspiration, // Use vibrant colour so icon is visible in dark mode
        inspirationMuted: inspirationMuted,
      );

  static const String idWarm = 'warm';
  static const String idSoftBlue = 'soft_blue';
  static const String idSage = 'sage';
  static const String idMonochrome = 'monochrome';
  static const String idBold = 'bold';
  static const String idCursor = 'cursor';
  static const String idVscode = 'vscode';

  /// Warm Reflection — emotional, reflective. Appeals to all ages; safe space to write.
  static final ThemePalette warm = ThemePalette(
    id: idWarm,
    name: 'Warm Reflection',
    description: 'Dusty rose & cream. Emotional, reflective; a safe space to pour out your day.',
    previewColors: [
      const Color(0xFFB56576), // primary
      const Color(0xFF6B9080), // success
      const Color(0xFFC9A227), // inspiration
      const Color(0xFFFDF8F5), // surface
    ],
    primary: const Color(0xFFB56576),
    primaryDark: const Color(0xFF8E4A58),
    primaryLight: const Color(0xFFE8B4BC),
    surfaceLight: const Color(0xFFFDF8F5),
    surfaceVariantLight: const Color(0xFFF5EDE8),
    cardLight: const Color(0xFFFFFEFC),
    outlineLight: const Color(0xFFE2D5C8),
    onSurfaceLight: const Color(0xFF3D3530),
    onSurfaceVariantLight: const Color(0xFF6B5B54),
    success: const Color(0xFF6B9080),
    successMuted: const Color(0xFFD4E5D9),
    inspiration: const Color(0xFFC9A227),
    inspirationMuted: const Color(0xFFF5E6C8),
    error: const Color(0xFFC75B5B),
    surfaceDark: const Color(0xFF2C2420),
    surfaceVariantDark: const Color(0xFF3D3530),
    outlineDark: const Color(0xFF5C524A),
    onSurfaceDark: const Color(0xFFF5EDE8),
    onSurfaceVariantDark: const Color(0xFFB8A99E),
  );

  /// Soft Blue — sky blue & soft grey. Calm, clear, and easy on the eyes.
  static final ThemePalette softBlue = ThemePalette(
    id: idSoftBlue,
    name: 'Soft Blue',
    description: 'Sky blue & soft grey. Calm and clear; ideal for focused journaling.',
    previewColors: [
      const Color(0xFF0284C7), // primary blue
      const Color(0xFF38BDF8), // light blue
      const Color(0xFF0EA5E9), // accent
      const Color(0xFFF0F9FF), // surface
    ],
    primary: const Color(0xFF0284C7),
    primaryDark: const Color(0xFF0369A1),
    primaryLight: const Color(0xFF38BDF8),
    surfaceLight: const Color(0xFFF0F9FF),
    surfaceVariantLight: const Color(0xFFE0F2FE),
    cardLight: const Color(0xFFFFFFFF),
    outlineLight: const Color(0xFFBAE6FD),
    onSurfaceLight: const Color(0xFF0C4A6E),
    onSurfaceVariantLight: const Color(0xFF0369A1),
    success: const Color(0xFF059669),
    successMuted: const Color(0xFFD1FAE5),
    inspiration: const Color(0xFF0EA5E9),
    inspirationMuted: const Color(0xFFE0F2FE),
    error: const Color(0xFFDC2626),
    surfaceDark: const Color(0xFF0C4A6E),
    surfaceVariantDark: const Color(0xFF075985),
    outlineDark: const Color(0xFF0284C7),
    onSurfaceDark: const Color(0xFFF0F9FF),
    onSurfaceVariantDark: const Color(0xFF7DD3FC),
  );

  /// Sage — muted greens with orange accent. Clean, natural, warm.
  static final ThemePalette sage = ThemePalette(
    id: idSage,
    name: 'Sage',
    description: 'Muted greens with orange. Clean, natural, and easy on the eyes.',
    previewColors: [
      const Color(0xFF4B5563), // slate primary
      const Color(0xFF10B981), // success green
      const Color(0xFFEA580C), // orange accent
      const Color(0xFFF9FAFB), // surface
    ],
    primary: const Color(0xFF4B5563),
    primaryDark: const Color(0xFF374151),
    primaryLight: const Color(0xFF6B7280),
    surfaceLight: const Color(0xFFF9FAFB),
    surfaceVariantLight: const Color(0xFFF3F4F6),
    cardLight: const Color(0xFFFFFFFF),
    outlineLight: const Color(0xFFE5E7EB),
    onSurfaceLight: const Color(0xFF111827),
    onSurfaceVariantLight: const Color(0xFF6B7280),
    success: const Color(0xFF10B981),
    successMuted: const Color(0xFFD1FAE5),
    inspiration: const Color(0xFFEA580C),
    inspirationMuted: const Color(0xFFFFEDD5),
    error: const Color(0xFFDC2626),
    surfaceDark: const Color(0xFF111827),
    surfaceVariantDark: const Color(0xFF1F2937),
    outlineDark: const Color(0xFF374151),
    onSurfaceDark: const Color(0xFFF9FAFB),
    onSurfaceVariantDark: const Color(0xFF9CA3AF),
  );

  /// Black & White — pure minimal. High contrast, no colour; for minimalist users.
  static final ThemePalette monochrome = ThemePalette(
    id: idMonochrome,
    name: 'Black & White',
    description: 'Pure minimal. High contrast, no colour; for minimalist users.',
    previewColors: [
      const Color(0xFF000000),
      const Color(0xFF404040),
      const Color(0xFF737373),
      const Color(0xFFFAFAFA),
    ],
    primary: const Color(0xFF171717),
    primaryDark: const Color(0xFF0A0A0A),
    primaryLight: const Color(0xFF404040),
    surfaceLight: const Color(0xFFFAFAFA),
    surfaceVariantLight: const Color(0xFFF5F5F5),
    cardLight: const Color(0xFFFFFFFF),
    outlineLight: const Color(0xFFE5E5E5),
    onSurfaceLight: const Color(0xFF0A0A0A),
    onSurfaceVariantLight: const Color(0xFF525252),
    success: const Color(0xFF404040),
    successMuted: const Color(0xFFF5F5F5),
    inspiration: const Color(0xFF737373),
    inspirationMuted: const Color(0xFFE5E5E5),
    error: const Color(0xFFDC2626),
    surfaceDark: const Color(0xFF0A0A0A),
    surfaceVariantDark: const Color(0xFF171717),
    outlineDark: const Color(0xFF404040),
    onSurfaceDark: const Color(0xFFFAFAFA),
    onSurfaceVariantDark: const Color(0xFFA3A3A3),
  );

  /// Bold — orange, light blue, and black. Strong contrast and energy.
  static final ThemePalette bold = ThemePalette(
    id: idBold,
    name: 'Bold',
    description: 'Orange, light blue & black. Strong contrast and energy.',
    previewColors: [
      const Color(0xFFEA580C), // orange
      const Color(0xFF38BDF8), // light blue
      const Color(0xFF0A0A0A), // black
      const Color(0xFFFAFAFA), // off-white
    ],
    primary: const Color(0xFFEA580C),
    primaryDark: const Color(0xFFC2410C),
    primaryLight: const Color(0xFFFB923C),
    surfaceLight: const Color(0xFFFAFAFA),
    surfaceVariantLight: const Color(0xFFF5F5F5),
    cardLight: const Color(0xFFFFFFFF),
    outlineLight: const Color(0xFFE5E5E5),
    onSurfaceLight: const Color(0xFF0A0A0A),
    onSurfaceVariantLight: const Color(0xFF525252),
    success: const Color(0xFF38BDF8),
    successMuted: const Color(0xFFE0F2FE),
    inspiration: const Color(0xFF38BDF8),
    inspirationMuted: const Color(0xFFE0F2FE),
    error: const Color(0xFFDC2626),
    surfaceDark: const Color(0xFF0A0A0A),
    surfaceVariantDark: const Color(0xFF171717),
    outlineDark: const Color(0xFF404040),
    onSurfaceDark: const Color(0xFFFAFAFA),
    onSurfaceVariantDark: const Color(0xFFA3A3A3),
  );

  /// Cursor — feels like Cursor IDE. Dark, modern, purple accent.
  static final ThemePalette cursor = ThemePalette(
    id: idCursor,
    name: 'Cursor',
    description: 'Feels like Cursor IDE. Dark, modern, with a purple accent.',
    previewColors: [
      const Color(0xFF8B5CF6), // violet
      const Color(0xFFA78BFA), // light violet
      const Color(0xFF1E1E1E), // dark bg
      const Color(0xFF2D2D2D), // surface
    ],
    primary: const Color(0xFF8B5CF6),
    primaryDark: const Color(0xFF6D28D9),
    primaryLight: const Color(0xFFA78BFA),
    surfaceLight: const Color(0xFFF5F5F5),
    surfaceVariantLight: const Color(0xFFEEEEEE),
    cardLight: const Color(0xFFFFFFFF),
    outlineLight: const Color(0xFFE0E0E0),
    onSurfaceLight: const Color(0xFF1E1E1E),
    onSurfaceVariantLight: const Color(0xFF525252),
    success: const Color(0xFF8B5CF6),
    successMuted: const Color(0xFFEDE9FE),
    inspiration: const Color(0xFFA78BFA),
    inspirationMuted: const Color(0xFFEDE9FE),
    error: const Color(0xFFDC2626),
    surfaceDark: const Color(0xFF1E1E1E),
    surfaceVariantDark: const Color(0xFF2D2D2D),
    outlineDark: const Color(0xFF404040),
    onSurfaceDark: const Color(0xFFE5E5E5),
    onSurfaceVariantDark: const Color(0xFFA3A3A3),
  );

  /// VS Code — feels like VS Code. Classic blue accent, Dark+ style.
  static final ThemePalette vscode = ThemePalette(
    id: idVscode,
    name: 'VS Code',
    description: 'Feels like VS Code. Classic blue accent, Dark+ style.',
    previewColors: [
      const Color(0xFF007ACC), // VS Code blue
      const Color(0xFF1E1E1E), // editor bg
      const Color(0xFF252526), // sidebar
      const Color(0xFFD4D4D4), // text
    ],
    primary: const Color(0xFF007ACC),
    primaryDark: const Color(0xFF005A9E),
    primaryLight: const Color(0xFF1E88E5),
    surfaceLight: const Color(0xFFF3F3F3),
    surfaceVariantLight: const Color(0xFFE8E8E8),
    cardLight: const Color(0xFFFFFFFF),
    outlineLight: const Color(0xFFCCCCCC),
    onSurfaceLight: const Color(0xFF333333),
    onSurfaceVariantLight: const Color(0xFF616161),
    success: const Color(0xFF007ACC),
    successMuted: const Color(0xFFE3F2FD),
    inspiration: const Color(0xFF007ACC),
    inspirationMuted: const Color(0xFFE3F2FD),
    error: const Color(0xFFDC2626),
    surfaceDark: const Color(0xFF1E1E1E),
    surfaceVariantDark: const Color(0xFF252526),
    outlineDark: const Color(0xFF3C3C3C),
    onSurfaceDark: const Color(0xFFD4D4D4),
    onSurfaceVariantDark: const Color(0xFF9D9D9D),
  );

  static final List<ThemePalette> all = [warm, softBlue, sage, monochrome, bold, cursor, vscode];

  static ThemePalette? byId(String id) {
    try {
      return all.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  static ThemePalette getDefault() => warm;
}
