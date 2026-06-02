// ============================================================
// Tree — THEME.
// ------------------------------------------------------------
// The component's own ThemeExtension, mirroring the GeniusLink GL* tokens and
// matching EditableTableThemeData's philosophy: instance fields are the
// surfaces that swap dark ↔ light (lerped); static consts are the
// theme-independent brand constants and metrics.
//
//   ThemeData(extensions: [TreeThemeData.light]);   // or .dark
//   final t = TreeThemeData.of(context);            // falls back to .dark
//
//   File: lib/design_system/components/data/tree_theme.dart
// ============================================================

import 'package:flutter/material.dart';

@immutable
class TreeThemeData extends ThemeExtension<TreeThemeData> {
  // ── swappable surfaces (dark ↔ light) ──
  final Color bg; //           panel fill (toolbar / footer / gutter)
  final Color surface; //      tree body fill
  final Color inputBg; //      rename field & search field fill
  final Color hover; //        row hover tint
  final Color border; //       hairline dividers
  final Color borderStrong; // outer frame
  final Color guide; //        indent guide-lines (│ ├ └)
  final Color fg1; //          node label
  final Color fg2; //          folder label emphasis
  final Color fg3; //          icons / chevrons / hints
  final Color fg4; //          badges / disabled

  const TreeThemeData({
    required this.bg,
    required this.surface,
    required this.inputBg,
    required this.hover,
    required this.border,
    required this.borderStrong,
    required this.guide,
    required this.fg1,
    required this.fg2,
    required this.fg3,
    required this.fg4,
  });

  // ── brand + semantic palette (const) ──
  static const Color accent = Color(0xFF4A7CFF);
  static const Color success = Color(0xFF1DB88A);
  static const Color warning = Color(0xFFF97316);
  static const Color danger = Color(0xFFEF4444);

  // ── typography ──
  static const String displayFont = 'Manrope';
  static const String bodyFont = 'Inter';
  static const String monoFont = 'JetBrainsMono';

  // ── radii ──
  static const double radiusSm = 4;
  static const double radiusMd = 6;
  static const double radiusLg = 8;

  // ── metrics ──
  static const double rowHeight = 32;
  static const double indentStep = 20; // px per depth level
  static const double twistySize = 18;
  static const double iconSize = 16;
  static const double toolbarHeight = 40;
  static const double footerHeight = 34;

  // ── motion ──
  static const Duration durFast = Duration(milliseconds: 100);
  static const Duration durBase = Duration(milliseconds: 150);
  static const Curve curveStandard = Cubic(0.4, 0, 0.2, 1);

  // ── elevation ──
  static const List<BoxShadow> popShadow = [
    BoxShadow(color: Color(0x59000000), blurRadius: 24, spreadRadius: -6, offset: Offset(0, 10)),
  ];

  // ── presets ──
  static const TreeThemeData dark = TreeThemeData(
    bg: Color(0xFF111318),
    surface: Color(0xFF1A1C21),
    inputBg: Color(0xFF33353A),
    hover: Color(0xFF24272E),
    border: Color(0x6643464F),
    borderStrong: Color(0xFF434654),
    guide: Color(0xFF3A3D46),
    fg1: Color(0xFFE2E2E9),
    fg2: Color(0xFFEDEEF4),
    fg3: Color(0xFF8D90A0),
    fg4: Color(0xFF5A5D68),
  );

  static const TreeThemeData light = TreeThemeData(
    bg: Color(0xFFF7F8FA),
    surface: Color(0xFFFFFFFF),
    inputBg: Color(0xFFF1F3F8),
    hover: Color(0xFFF1F4F9),
    border: Color(0xFFE2E8F0),
    borderStrong: Color(0xFFC2C6D6),
    guide: Color(0xFFD7DCE6),
    fg1: Color(0xFF0F172A),
    fg2: Color(0xFF111827),
    fg3: Color(0xFF64748B),
    fg4: Color(0xFFAEB4C2),
  );

  /// Reads the registered extension, or falls back to [dark].
  static TreeThemeData of(BuildContext context) =>
      Theme.of(context).extension<TreeThemeData>() ?? dark;

  /// Selection-row tint at [pct] opacity over [surface] (mirrors the web
  /// `color-mix(... accent N%, surface)` highlight).
  Color selectionFill([double pct = 0.14]) => Color.alphaBlend(accent.withOpacity(pct), surface);

  @override
  TreeThemeData copyWith({
    Color? bg,
    Color? surface,
    Color? inputBg,
    Color? hover,
    Color? border,
    Color? borderStrong,
    Color? guide,
    Color? fg1,
    Color? fg2,
    Color? fg3,
    Color? fg4,
  }) =>
      TreeThemeData(
        bg: bg ?? this.bg,
        surface: surface ?? this.surface,
        inputBg: inputBg ?? this.inputBg,
        hover: hover ?? this.hover,
        border: border ?? this.border,
        borderStrong: borderStrong ?? this.borderStrong,
        guide: guide ?? this.guide,
        fg1: fg1 ?? this.fg1,
        fg2: fg2 ?? this.fg2,
        fg3: fg3 ?? this.fg3,
        fg4: fg4 ?? this.fg4,
      );

  @override
  TreeThemeData lerp(ThemeExtension<TreeThemeData>? other, double t) {
    if (other is! TreeThemeData) return this;
    return TreeThemeData(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      inputBg: Color.lerp(inputBg, other.inputBg, t)!,
      hover: Color.lerp(hover, other.hover, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      guide: Color.lerp(guide, other.guide, t)!,
      fg1: Color.lerp(fg1, other.fg1, t)!,
      fg2: Color.lerp(fg2, other.fg2, t)!,
      fg3: Color.lerp(fg3, other.fg3, t)!,
      fg4: Color.lerp(fg4, other.fg4, t)!,
    );
  }
}
