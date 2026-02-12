import 'package:flutter/material.dart';

/// Extra colors used across the app (streak, prompt card, etc.)
/// so they adapt to the selected color theme.
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.success,
    required this.successMuted,
    required this.inspiration,
    required this.inspirationMuted,
  });

  final Color success;
  final Color successMuted;
  final Color inspiration;
  final Color inspirationMuted;

  @override
  AppThemeColors copyWith({
    Color? success,
    Color? successMuted,
    Color? inspiration,
    Color? inspirationMuted,
  }) {
    return AppThemeColors(
      success: success ?? this.success,
      successMuted: successMuted ?? this.successMuted,
      inspiration: inspiration ?? this.inspiration,
      inspirationMuted: inspirationMuted ?? this.inspirationMuted,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      success: Color.lerp(success, other.success, t)!,
      successMuted: Color.lerp(successMuted, other.successMuted, t)!,
      inspiration: Color.lerp(inspiration, other.inspiration, t)!,
      inspirationMuted: Color.lerp(inspirationMuted, other.inspirationMuted, t)!,
    );
  }

  /// Get app theme colors from context. Use in widgets instead of [AppColors].
  static AppThemeColors of(BuildContext context) {
    return Theme.of(context).extension<AppThemeColors>()!;
  }
}
