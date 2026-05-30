import 'package:flutter/material.dart';

/// Theme extension used by the browser-style tab strip and its overlays.
///
/// Register [dark] or [light] in `ThemeData.extensions` to control the
/// component surfaces. Static constants define design tokens that are the same
/// in both theme modes.
@immutable
class BrowserStyleTabBarThemeData
    extends ThemeExtension<BrowserStyleTabBarThemeData> {
  /// Background used by the strip container and page base.
  final Color bg;

  /// Primary surface used by active tabs, cards, and content panels.
  final Color surface;

  /// Secondary surface used by nested cards.
  final Color surface2;

  /// Input fill and close-button hover surface.
  final Color inputBg;

  /// Hover tint used by tabs, menus, and icon buttons.
  final Color hover;

  /// Hairline border color.
  final Color border;

  /// Strong border color used for dividers and popover edges.
  final Color borderStrong;

  /// Primary foreground text color.
  final Color fg1;

  /// Secondary foreground text color.
  final Color fg2;

  /// Tertiary foreground text and placeholder color.
  final Color fg3;

  /// Disabled foreground color.
  final Color fg4;

  /// Creates a theme extension for browser-style tab components.
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

  /// Primary accent color.
  static const Color accent = Color(0xFF4A7CFF);

  /// Success semantic color.
  static const Color success = Color(0xFF1DB88A);

  /// Warning semantic color.
  static const Color warning = Color(0xFFF97316);

  /// Danger semantic color.
  static const Color danger = Color(0xFFEF4444);

  /// Informational semantic color.
  static const Color info = accent;

  /// Display font family name.
  static const String displayFont = 'Manrope';

  /// Body font family name.
  static const String bodyFont = 'Inter';

  /// Monospace font family name.
  static const String monoFont = 'JetBrainsMono';

  /// Small corner radius.
  static const double radiusSm = 4;

  /// Medium corner radius.
  static const double radiusMd = 6;

  /// Large corner radius.
  static const double radiusLg = 8;

  /// Extra-large corner radius.
  static const double radiusXl = 12;

  /// Shadow used by framed cards and windows.
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 50,
      spreadRadius: -12,
      offset: Offset(0, 25),
    ),
  ];

  /// Shadow used by menus, dropdowns, previews, and dialogs.
  static const List<BoxShadow> popShadow = [
    BoxShadow(
      color: Color(0x73000000),
      blurRadius: 32,
      spreadRadius: -8,
      offset: Offset(0, 12),
    ),
  ];

  /// Fast transition duration.
  static const Duration durFast = Duration(milliseconds: 100);

  /// Base transition duration.
  static const Duration durBase = Duration(milliseconds: 150);

  /// Slow transition duration.
  static const Duration durSlow = Duration(milliseconds: 300);

  /// Slower transition duration.
  static const Duration durSlower = Duration(milliseconds: 500);

  /// Standard easing curve.
  static const Curve curveStandard = Cubic(0.4, 0, 0.2, 1);

  /// Decelerating entrance curve.
  static const Curve curveDecelerate = Cubic(0, 0, 0.2, 1);

  /// Emphasized curve used by dialogs.
  static const Curve curveEmphasized = Cubic(0.2, 0, 0, 1);

  /// Dark theme preset.
  static const BrowserStyleTabBarThemeData dark = BrowserStyleTabBarThemeData(
    bg: Color(0xFF111318),
    surface: Color(0xFF1E2025),
    surface2: Color(0xFF292D38),
    inputBg: Color(0xFF33353A),
    hover: Color(0xFF2F3540),
    border: Color(0x6643464F),
    borderStrong: Color(0xFF434654),
    fg1: Color(0xFFE2E2E9),
    fg2: Color(0xFFC3C6D7),
    fg3: Color(0xFF8D90A0),
    fg4: Color(0xFF44474E),
  );

  /// Light theme preset.
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

  /// Reads the registered extension, or falls back to [dark].
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
  BrowserStyleTabBarThemeData lerp(
    ThemeExtension<BrowserStyleTabBarThemeData>? other,
    double t,
  ) {
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
