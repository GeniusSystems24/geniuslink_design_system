// ============================================================
// BrowserStyleTabBarThemeData — the component's own ThemeExtension.
// ------------------------------------------------------------
// Self-contained: this replaces the design-system token / surface / theme
// files. Everything BrowserStyleTabBar (and its pages / overlays) needs to
// paint lives here.
//
//   • Instance fields  = the surfaces that SWAP between dark & light
//     (bg / surface / hover / border / fg1..fg4 …). These are lerped.
//   • Static const     = the brand constants that DON'T vary by theme
//     (accent + semantic palette, font families, radii, shadows, motion).
//
// Register it on your app theme:
//
//   ThemeData(
//     extensions: [BrowserStyleTabBarThemeData.dark],   // or .light
//   )
//
// then read it anywhere with `BrowserStyleTabBarThemeData.of(context)`
// (falls back to .dark if none is registered, so the widget always paints).
//
//   File: lib/design_system/components/navigation/browser_style_tab_bar_theme.dart
// ============================================================

import 'package:flutter/material.dart';

@immutable
class BrowserStyleTabBarThemeData extends ThemeExtension<BrowserStyleTabBarThemeData> {
  // ── swappable surfaces (dark ↔ light) ──────────────────────
  final Color bg; //           strip container / page base
  final Color surface; //      active-tab content / card
  final Color surface2; //     nested card
  final Color inputBg; //      input fill / close-button hover
  final Color hover; //        hover tint
  final Color border; //       hairline
  final Color borderStrong; // solid divider / pop-card edge
  final Color fg1; //          primary text
  final Color fg2; //          secondary
  final Color fg3; //          tertiary / placeholder
  final Color fg4; //          disabled

  const BrowserStyleTabBarThemeData({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.inputBg,
    required this.hover,
    required this.border,
    required this.borderStrong,
    required this.fg1,
    required this.fg2,
    required this.fg3,
    required this.fg4,
  });

  // ── brand + semantic palette (theme-independent · const) ───
  static const Color accent = Color(0xFF4A7CFF); // primary
  static const Color success = Color(0xFF1DB88A);
  static const Color warning = Color(0xFFF97316);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = accent;

  // ── typography (font families) ─────────────────────────────
  static const String displayFont = 'Manrope';
  static const String bodyFont = 'Inter';
  static const String monoFont = 'JetBrainsMono';

  // ── radii ──────────────────────────────────────────────────
  static const double radiusSm = 4;
  static const double radiusMd = 6;
  static const double radiusLg = 8;
  static const double radiusXl = 12;

  // ── elevation ──────────────────────────────────────────────
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x40000000), blurRadius: 50, spreadRadius: -12, offset: Offset(0, 25)),
  ];
  static const List<BoxShadow> popShadow = [
    BoxShadow(color: Color(0x73000000), blurRadius: 32, spreadRadius: -8, offset: Offset(0, 12)),
  ];

  // ── motion ─────────────────────────────────────────────────
  static const Duration durFast = Duration(milliseconds: 100);
  static const Duration durBase = Duration(milliseconds: 150);
  static const Duration durSlow = Duration(milliseconds: 300);
  static const Duration durSlower = Duration(milliseconds: 500);
  static const Curve curveStandard = Cubic(0.4, 0, 0.2, 1);
  static const Curve curveDecelerate = Cubic(0, 0, 0.2, 1); // enter
  static const Curve curveEmphasized = Cubic(0.2, 0, 0, 1); // dialogs

  // ── presets ────────────────────────────────────────────────
  static const BrowserStyleTabBarThemeData dark = BrowserStyleTabBarThemeData(
    bg: Color(0xFF111318),
    surface: Color(0xFF1E2025),
    surface2: Color(0xFF292D38),
    inputBg: Color(0xFF33353A),
    hover: Color(0xFF2F3540),
    border: Color(0x6643464F), // rgba(67,70,84,.4)
    borderStrong: Color(0xFF434654),
    fg1: Color(0xFFE2E2E9),
    fg2: Color(0xFFC3C6D7),
    fg3: Color(0xFF8D90A0),
    fg4: Color(0xFF44474E),
  );

  static const BrowserStyleTabBarThemeData light = BrowserStyleTabBarThemeData(
    bg: Color(0xFFF7F8FA),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFFFFFFF),
    inputBg: Color(0xFFF1F3F8),
    hover: Color(0xFFEEF1F7),
    border: Color(0xFFE2E8F0),
    borderStrong: Color(0xFFC2C6D6),
    fg1: Color(0xFF0F172A),
    fg2: Color(0xFF424754),
    fg3: Color(0xFF64748B),
    fg4: Color(0xFFC2C6D6),
  );

  /// Reads the registered extension, or falls back to [dark] so the
  /// component paints even when nothing is registered on the app theme.
  static BrowserStyleTabBarThemeData of(BuildContext context) =>
      Theme.of(context).extension<BrowserStyleTabBarThemeData>() ?? dark;

  @override
  BrowserStyleTabBarThemeData copyWith({
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? inputBg,
    Color? hover,
    Color? border,
    Color? borderStrong,
    Color? fg1,
    Color? fg2,
    Color? fg3,
    Color? fg4,
  }) =>
      BrowserStyleTabBarThemeData(
        bg: bg ?? this.bg,
        surface: surface ?? this.surface,
        surface2: surface2 ?? this.surface2,
        inputBg: inputBg ?? this.inputBg,
        hover: hover ?? this.hover,
        border: border ?? this.border,
        borderStrong: borderStrong ?? this.borderStrong,
        fg1: fg1 ?? this.fg1,
        fg2: fg2 ?? this.fg2,
        fg3: fg3 ?? this.fg3,
        fg4: fg4 ?? this.fg4,
      );

  @override
  BrowserStyleTabBarThemeData lerp(ThemeExtension<BrowserStyleTabBarThemeData>? other, double t) {
    if (other is! BrowserStyleTabBarThemeData) return this;
    return BrowserStyleTabBarThemeData(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      inputBg: Color.lerp(inputBg, other.inputBg, t)!,
      hover: Color.lerp(hover, other.hover, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      fg1: Color.lerp(fg1, other.fg1, t)!,
      fg2: Color.lerp(fg2, other.fg2, t)!,
      fg3: Color.lerp(fg3, other.fg3, t)!,
      fg4: Color.lerp(fg4, other.fg4, t)!,
    );
  }
}
