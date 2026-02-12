import 'package:flutter/material.dart';

/// Warm, reflective palette to inspire writing and honor every feeling.
/// Feels like a safe space to pour out the day.
class AppColors {
  AppColors._();

  // Primary — dusty rose: emotional, reflective, inviting to write
  static const Color primary = Color(0xFFB56576);
  static const Color primaryDark = Color(0xFF8E4A58);
  static const Color primaryLight = Color(0xFFE8B4BC);

  // Warm surfaces — cream & paper-like (light)
  static const Color surfaceLight = Color(0xFFFDF8F5);
  static const Color surfaceVariantLight = Color(0xFFF5EDE8);
  static const Color outlineLight = Color(0xFFE2D5C8);
  static const Color cardLight = Color(0xFFFFFEFC);

  // Warm dark — cozy night mode
  static const Color surfaceDark = Color(0xFF2C2420);
  static const Color surfaceVariantDark = Color(0xFF3D3530);
  static const Color outlineDark = Color(0xFF5C524A);
  static const Color onSurfaceVariantLight = Color(0xFF6B5B54);
  static const Color onSurfaceVariantDark = Color(0xFFB8A99E);

  // Success / growth — sage: calm, growth, “you showed up”
  static const Color success = Color(0xFF6B9080);
  static const Color successMuted = Color(0xFFD4E5D9);

  // Inspiration accent — warm amber for “time to write”
  static const Color inspiration = Color(0xFFC9A227);
  static const Color inspirationMuted = Color(0xFFF5E6C8);

  // Semantic
  static const Color error = Color(0xFFC75B5B);
  static const Color warning = Color(0xFFD4A03B);

  // Mood (journal) — gentle, feeling-based
  static const Color moodVerySad = Color(0xFFC75B5B);
  static const Color moodSad = Color(0xFFD4926E);
  static const Color moodNeutral = Color(0xFFC9A227);
  static const Color moodHappy = Color(0xFF7D9D7C);
  static const Color moodVeryHappy = Color(0xFF6B9080);
}
