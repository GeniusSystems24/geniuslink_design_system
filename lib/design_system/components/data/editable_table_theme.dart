// ============================================================
// EditableTable — THEME.
// ------------------------------------------------------------
// The component's own ThemeExtension, mirroring the GeniusLink GL* tokens.
// Self-contained (same philosophy as BrowserStyleTabBarThemeData): instance
// fields are the surfaces that swap dark ↔ light (lerped); static consts are
// the theme-independent brand constants.
//
//   ThemeData(extensions: [EditableTableThemeData.light]);   // or .dark
//   final t = EditableTableThemeData.of(context);            // falls back to .dark
//
//   File: lib/design_system/components/data/editable_table_theme.dart
// ============================================================

import 'package:flutter/material.dart';

@immutable
class EditableTableThemeData extends ThemeExtension<EditableTableThemeData> {
  // ── swappable surfaces (dark ↔ light) ──
  final Color bg; //           header / footer / gutter fill
  final Color surface; //      cell fill
  final Color inputBg; //      editing field fill
  final Color hover; //        hover tint
  final Color border; //       hairline grid lines
  final Color borderStrong; // outer frame / divider
  final Color fg1; //          cell text
  final Color fg2; //          header text emphasis
  final Color fg3; //          tertiary / hints
  final Color fg4; //          empty-cell placeholder

  const EditableTableThemeData({
    required this.bg,
    required this.surface,
    required this.inputBg,
    required this.hover,
    required this.border,
    required this.borderStrong,
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
  static const double gutterWidth = 44;
  static const double actionsWidth = 88;
  static const double rowHeight = 36;
  static const double headerHeight = 34;
  static const double footerHeight = 38;

  // ── motion ──
  static const Duration durFast = Duration(milliseconds: 100);
  static const Duration durBase = Duration(milliseconds: 150);
  static const Curve curveStandard = Cubic(0.4, 0, 0.2, 1);

  // ── elevation ──
  static const List<BoxShadow> popShadow = [
    BoxShadow(color: Color(0x59000000), blurRadius: 24, spreadRadius: -6, offset: Offset(0, 10)),
  ];

  // ── presets ──
  static const EditableTableThemeData dark = EditableTableThemeData(
    bg: Color(0xFF111318),
    surface: Color(0xFF1E2025),
    inputBg: Color(0xFF33353A),
    hover: Color(0xFF2F3540),
    border: Color(0x6643464F),
    borderStrong: Color(0xFF434654),
    fg1: Color(0xFFE2E2E9),
    fg2: Color(0xFFC3C6D7),
    fg3: Color(0xFF8D90A0),
    fg4: Color(0xFF5A5D68),
  );

  static const EditableTableThemeData light = EditableTableThemeData(
    bg: Color(0xFFF7F8FA),
    surface: Color(0xFFFFFFFF),
    inputBg: Color(0xFFF1F3F8),
    hover: Color(0xFFEEF1F7),
    border: Color(0xFFE2E8F0),
    borderStrong: Color(0xFFC2C6D6),
    fg1: Color(0xFF0F172A),
    fg2: Color(0xFF424754),
    fg3: Color(0xFF64748B),
    fg4: Color(0xFFAEB4C2),
  );

  /// Reads the registered extension, or falls back to [dark].
  static EditableTableThemeData of(BuildContext context) =>
      Theme.of(context).extension<EditableTableThemeData>() ?? dark;

  /// A selection tint at [pct] opacity over [surface] (mirrors the web
  /// `color-mix(... accent N%, surface)` cell highlight).
  Color selectionFill([double pct = 0.10]) => Color.alphaBlend(accent.withOpacity(pct), surface);

  @override
  EditableTableThemeData copyWith({
    Color? bg,
    Color? surface,
    Color? inputBg,
    Color? hover,
    Color? border,
    Color? borderStrong,
    Color? fg1,
    Color? fg2,
    Color? fg3,
    Color? fg4,
  }) =>
      EditableTableThemeData(
        bg: bg ?? this.bg,
        surface: surface ?? this.surface,
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
  EditableTableThemeData lerp(ThemeExtension<EditableTableThemeData>? other, double t) {
    if (other is! EditableTableThemeData) return this;
    return EditableTableThemeData(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
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
