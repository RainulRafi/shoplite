import 'package:flutter/material.dart';

// ============================================
// All app colors live here. Screens should not define their own colors;
// they should get colors from here through context.colors. When the theme
// changes (Light <-> Dark), Flutter automatically redraws every screen.
// ============================================
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color bg; // Screen background
  final Color surface; // Cards, sheets, and dialogs
  final Color border; // Subtle outline (instead of a shadow)
  final Color ink; // Primary text
  final Color muted; // Secondary text
  final Color faint; // Faint text (captions)
  final Color subtle; // Input hint text
  final Color field; // Fill color for inputs and image tiles
  final Color track; // Empty part of skeletons and progress indicators
  final Color accent; // Filled button color (with onAccent text)
  final Color accentFg; // Accent-colored text or icons on a surface
  final Color onAccent; // Text displayed on the accent color
  final Color highlight; // Small emphasis, such as a discount badge
  final Color danger; // Errors and warnings
  final Color success; // Success

  const AppColors({
    required this.bg,
    required this.surface,
    required this.border,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.subtle,
    required this.field,
    required this.track,
    required this.accent,
    required this.accentFg,
    required this.onAccent,
    required this.highlight,
    required this.danger,
    required this.success,
  });

  static const light = AppColors(
    bg: Color(0xFFF4EFE7),
    surface: Color(0xFFFBF8F2),
    border: Color(0xFFE2D9CB),
    ink: Color(0xFF2B2622),
    muted: Color(0xFF6A5F54),
    faint: Color(0xFF766A5E),
    subtle: Color(0xFF80756A),
    field: Color(0xFFEFE8DD),
    track: Color(0xFFE6DDCF),
    accent: Color(0xFF5B3F2E),
    accentFg: Color(0xFF5B3F2E),
    onAccent: Color(0xFFFBF8F2),
    highlight: Color(0xFF94600F),
    danger: Color(0xFFA82B22),
    success: Color(0xFF4E6B34),
  );

  static const dark = AppColors(
    bg: Color(0xFF1C1815),
    surface: Color(0xFF26211D),
    border: Color(0xFF3A332D),
    ink: Color(0xFFEDE6DB),
    muted: Color(0xFFB5AA9B),
    faint: Color(0xFF9A8F82),
    subtle: Color(0xFF8C8278),
    field: Color(0xFF2E2823),
    track: Color(0xFF3A332D),
    accent: Color(0xFF8C5E3C),
    accentFg: Color(0xFFDDAE7C),
    onAccent: Color(0xFFFBF8F2),
    highlight: Color(0xFFD9A05B),
    danger: Color(0xFFE57368),
    success: Color(0xFF9DB87A),
  );

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? border,
    Color? ink,
    Color? muted,
    Color? faint,
    Color? subtle,
    Color? field,
    Color? track,
    Color? accent,
    Color? accentFg,
    Color? onAccent,
    Color? highlight,
    Color? danger,
    Color? success,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      border: border ?? this.border,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      faint: faint ?? this.faint,
      subtle: subtle ?? this.subtle,
      field: field ?? this.field,
      track: track ?? this.track,
      accent: accent ?? this.accent,
      accentFg: accentFg ?? this.accentFg,
      onAccent: onAccent ?? this.onAccent,
      highlight: highlight ?? this.highlight,
      danger: danger ?? this.danger,
      success: success ?? this.success,
    );
  }

  // Flutter smoothly blends colors when switching from Light to Dark; this defines how.
  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      bg: mix(bg, other.bg),
      surface: mix(surface, other.surface),
      border: mix(border, other.border),
      ink: mix(ink, other.ink),
      muted: mix(muted, other.muted),
      faint: mix(faint, other.faint),
      subtle: mix(subtle, other.subtle),
      field: mix(field, other.field),
      track: mix(track, other.track),
      accent: mix(accent, other.accent),
      accentFg: mix(accentFg, other.accentFg),
      onAccent: mix(onAccent, other.onAccent),
      highlight: mix(highlight, other.highlight),
      danger: mix(danger, other.danger),
      success: mix(success, other.success),
    );
  }
}

// Use `context.colors.ink` inside build() to get the current theme's color.
extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
