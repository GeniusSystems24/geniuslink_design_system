// ============================================================
// NavigationSidebar — THEME.
// ------------------------------------------------------------
// The component's own ThemeExtension, mirroring the GeniusLink GL* tokens and
// matching the rest of the kit (TreeThemeData / EditableTableThemeData): the
// instance fields are the surfaces that swap dark ↔ light (lerped); the static
// consts are the theme-independent brand constants, geometry and motion.
//
//   ThemeData(extensions: [NavigationSidebarThemeData.light]);   // or .dark
//   final t = NavigationSidebarThemeData.of(context);            // falls back to .dark
//
//   File: lib/design_system/components/navigation/navigation_sidebar_theme.dart
// ============================================================

import 'package:flutter/material.dart';
import 'navigation_sidebar_models.dart';

@immutable
class NavigationSidebarThemeData extends ThemeExtension<NavigationSidebarThemeData> {
  // ── swappable surfaces (dark ↔ light) ──
  final Color bg; //           page backdrop the rail/drawer floats over
  final Color surface; //      sidebar panel fill
  final Color inputBg; //      boxed-icon leaf fill / chips
  final Color hover; //        row hover tint
  final Color border; //       hairline dividers
  final Color borderStrong; // outer frame / scrollbar thumb
  final Color guide; //        the │ ├ └ connector lines
  final Color fg1; //          active / primary label
  final Color fg2; //          row label
  final Color fg3; //          icons · group labels · chevrons
  final Color fg4; //          section eyebrows · disabled

  const NavigationSidebarThemeData({
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
  static const double radiusSm = 6;
  static const double radiusMd = 8;
  static const double radiusLg = 10;
  static const double radiusXl = 12;

  // ── layout widths ──
  static const double widthExpanded = 248;
  static const double widthRail = 76;
  static const double widthDrawer = 280;

  // ── row metrics (the four roles) ──
  static const double directHeight = 42;
  static const double moduleHeight = 42;
  static const double groupHeight = 36;
  static const double itemHeight = 38;
  static const double railButton = 44;

  /// Inline step added per nesting level (drives the connector geometry).
  static const double gutter = 19;
  static const double iconTop = 20; // direct / module leading icon
  static const double iconItem = 16; // boxed leaf icon
  static const double itemBox = 28; // boxed leaf size

  /// Content inset of a row at [depth].
  static double contentInset(int depth) => 13 + depth * gutter;

  /// Column where THIS node's children draw their vertical guide.
  static double lineInset(int depth) => contentInset(depth) + 10;

  /// Horizontal stub length of the ├/└ elbow.
  static const double elbow = gutter - 8;

  // ── motion ──
  static const Duration durFast = Duration(milliseconds: 150);
  static const Duration durBase = Duration(milliseconds: 240);
  static const Duration durDrawer = Duration(milliseconds: 280);
  static const Curve curveStandard = Cubic(0.4, 0, 0.2, 1);

  // ── elevation ──
  static const List<BoxShadow> popShadow = [
    BoxShadow(color: Color(0x73000000), blurRadius: 32, spreadRadius: -8, offset: Offset(0, 12)),
  ];

  // ── default breakpoints ──
  static const NavSidebarBreakpoints breakpoints = NavSidebarBreakpoints();

  // ── presets ──
  static const NavigationSidebarThemeData dark = NavigationSidebarThemeData(
    bg: Color(0xFF111318),
    surface: Color(0xFF1E2025),
    inputBg: Color(0xFF33353A),
    hover: Color(0xFF2F3540),
    border: Color(0x66434654),
    borderStrong: Color(0xFF434654),
    guide: Color(0xFF434654),
    fg1: Color(0xFFE2E2E9),
    fg2: Color(0xFFC3C6D7),
    fg3: Color(0xFF8D90A0),
    fg4: Color(0xFF44474E),
  );

  static const NavigationSidebarThemeData light = NavigationSidebarThemeData(
    bg: Color(0xFFF7F8FA),
    surface: Color(0xFFFFFFFF),
    inputBg: Color(0xFFF1F3F8),
    hover: Color(0xFFEEF1F7),
    border: Color(0xFFE2E8F0),
    borderStrong: Color(0xFFC2C6D6),
    guide: Color(0xFFC2C6D6),
    fg1: Color(0xFF0F172A),
    fg2: Color(0xFF424754),
    fg3: Color(0xFF64748B),
    fg4: Color(0xFFC2C6D6),
  );

  /// Reads the registered extension, or falls back to [dark].
  static NavigationSidebarThemeData of(BuildContext context) =>
      Theme.of(context).extension<NavigationSidebarThemeData>() ?? dark;

  /// Accent-tinted fill over [surface] at [pct] opacity (mirrors the web
  /// `rgba(74,124,255, N)` row highlights).
  Color accentFill([double pct = 0.12]) => Color.alphaBlend(accent.withOpacity(pct), surface);

  /// Resolve a [NavBadgeTone] to its (background, foreground, border) trio.
  ({Color bg, Color fg, Color border}) badgeColors(NavBadgeTone tone) {
    switch (tone) {
      case NavBadgeTone.accent:
        return (bg: accent.withOpacity(0.16), fg: accent, border: accent.withOpacity(0.34));
      case NavBadgeTone.success:
        return (bg: success.withOpacity(0.16), fg: const Color(0xFF2BBE7C), border: success.withOpacity(0.34));
      case NavBadgeTone.warning:
        return (bg: warning.withOpacity(0.16), fg: const Color(0xFFE0A23B), border: warning.withOpacity(0.34));
      case NavBadgeTone.muted:
        return (bg: inputBg, fg: fg3, border: border);
    }
  }

  @override
  NavigationSidebarThemeData copyWith({
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
      NavigationSidebarThemeData(
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
  NavigationSidebarThemeData lerp(ThemeExtension<NavigationSidebarThemeData>? other, double t) {
    if (other is! NavigationSidebarThemeData) return this;
    return NavigationSidebarThemeData(
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
