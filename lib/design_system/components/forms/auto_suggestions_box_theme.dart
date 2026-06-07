// ============================================================
// AutoSuggestionsBox — THEME.
// ------------------------------------------------------------
// The component's own ThemeExtension, mirroring the GeniusLink GL* tokens and
// matching the EditableTable / Tree surfaces so the box drops into the same
// console. Instance fields swap dark ↔ light (lerped); static consts are the
// theme-independent brand constants.
//
//   ThemeData(extensions: [AutoSuggestionsBoxThemeData.light]);   // or .dark
//   final t = AutoSuggestionsBoxThemeData.of(context);            // → .dark fallback
//
//   File: lib/design_system/components/forms/auto_suggestions_box_theme.dart
// ============================================================

import 'package:flutter/material.dart';

@immutable
class AutoSuggestionsBoxThemeData extends ThemeExtension<AutoSuggestionsBoxThemeData> {
  // ── swappable surfaces (dark ↔ light) ──
  final Color fieldBg; //      input fill (resting)
  final Color fieldBgFocus; // input fill (focused)
  final Color overlayBg; //    dropdown panel fill
  final Color hover; //        hovered / highlighted row tint
  final Color border; //       resting field + panel border
  final Color borderFocus; //  focused field border
  final Color fg1; //          primary text (label, typed value)
  final Color fg2; //          secondary (description)
  final Color fg3; //          hint / leading icon
  final Color groupFg; //      group header text

  const AutoSuggestionsBoxThemeData({
    required this.fieldBg,
    required this.fieldBgFocus,
    required this.overlayBg,
    required this.hover,
    required this.border,
    required this.borderFocus,
    required this.fg1,
    required this.fg2,
    required this.fg3,
    required this.groupFg,
  });

  // ── brand + semantic palette (const) ──
  static const Color accent = Color(0xFF4A7CFF);
  static const Color danger = Color(0xFFEF4444);

  // ── typography ──
  static const String displayFont = 'Manrope';
  static const String bodyFont = 'Inter';

  // ── radii ──
  static const double radiusSm = 4;
  static const double radiusMd = 6;
  static const double radiusLg = 8;

  // ── metrics ──
  static const double fieldHeight = 40;
  static const double rowHeight = 38;
  static const double overlayGap = 4; //   space between field and panel
  static const double overlayMaxWidth = 560;

  // ── motion ──
  static const Duration durFast = Duration(milliseconds: 110);
  static const Duration durBase = Duration(milliseconds: 160);
  static const Curve curveStandard = Cubic(0.4, 0, 0.2, 1);

  // ── elevation ──
  static const List<BoxShadow> overlayShadow = [
    BoxShadow(color: Color(0x2E0B1220), blurRadius: 24, spreadRadius: -4, offset: Offset(0, 12)),
    BoxShadow(color: Color(0x140B1220), blurRadius: 6, spreadRadius: -2, offset: Offset(0, 2)),
  ];

  // ── presets ──
  static const AutoSuggestionsBoxThemeData dark = AutoSuggestionsBoxThemeData(
    fieldBg: Color(0xFF1E2025),
    fieldBgFocus: Color(0xFF23262C),
    overlayBg: Color(0xFF202329),
    hover: Color(0xFF2C313B),
    border: Color(0xFF3A3D47),
    borderFocus: accent,
    fg1: Color(0xFFE6E7EE),
    fg2: Color(0xFF9DA1B0),
    fg3: Color(0xFF6E7280),
    groupFg: Color(0xFF7E8290),
  );

  static const AutoSuggestionsBoxThemeData light = AutoSuggestionsBoxThemeData(
    fieldBg: Color(0xFFFFFFFF),
    fieldBgFocus: Color(0xFFFFFFFF),
    overlayBg: Color(0xFFFFFFFF),
    hover: Color(0xFFEFF3FF),
    border: Color(0xFFC2C6D6),
    borderFocus: accent,
    fg1: Color(0xFF0F172A),
    fg2: Color(0xFF64748B),
    fg3: Color(0xFF94A0B4),
    groupFg: Color(0xFF8A92A4),
  );

  /// Reads the registered extension, or falls back to [dark].
  static AutoSuggestionsBoxThemeData of(BuildContext context) =>
      Theme.of(context).extension<AutoSuggestionsBoxThemeData>() ?? dark;

  /// A tint of the accent over the overlay surface (selected-row fill).
  Color accentWash([double pct = 0.12]) => Color.alphaBlend(accent.withOpacity(pct), overlayBg);

  @override
  AutoSuggestionsBoxThemeData copyWith({
    Color? fieldBg,
    Color? fieldBgFocus,
    Color? overlayBg,
    Color? hover,
    Color? border,
    Color? borderFocus,
    Color? fg1,
    Color? fg2,
    Color? fg3,
    Color? groupFg,
  }) =>
      AutoSuggestionsBoxThemeData(
        fieldBg: fieldBg ?? this.fieldBg,
        fieldBgFocus: fieldBgFocus ?? this.fieldBgFocus,
        overlayBg: overlayBg ?? this.overlayBg,
        hover: hover ?? this.hover,
        border: border ?? this.border,
        borderFocus: borderFocus ?? this.borderFocus,
        fg1: fg1 ?? this.fg1,
        fg2: fg2 ?? this.fg2,
        fg3: fg3 ?? this.fg3,
        groupFg: groupFg ?? this.groupFg,
      );

  @override
  AutoSuggestionsBoxThemeData lerp(ThemeExtension<AutoSuggestionsBoxThemeData>? other, double t) {
    if (other is! AutoSuggestionsBoxThemeData) return this;
    return AutoSuggestionsBoxThemeData(
      fieldBg: Color.lerp(fieldBg, other.fieldBg, t)!,
      fieldBgFocus: Color.lerp(fieldBgFocus, other.fieldBgFocus, t)!,
      overlayBg: Color.lerp(overlayBg, other.overlayBg, t)!,
      hover: Color.lerp(hover, other.hover, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t)!,
      fg1: Color.lerp(fg1, other.fg1, t)!,
      fg2: Color.lerp(fg2, other.fg2, t)!,
      fg3: Color.lerp(fg3, other.fg3, t)!,
      groupFg: Color.lerp(groupFg, other.groupFg, t)!,
    );
  }
}
