// ============================================================
// GeniusLink Design System — Flutter foundation tokens.
// Mirrors design_system/tokens.css and FOUNDATIONS.md.
// Architecture: foundations are stateless token objects consumed by MVVM/MVC
// components; widgets never import HTML/CSS.
// ============================================================

import 'package:flutter/material.dart';
import 'components/navigation/browser_style_tab_bar_theme.dart';

@immutable
class GeniusThemeData extends ThemeExtension<GeniusThemeData> {
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color inputBg;
  final Color hover;
  final Color border;
  final Color borderStrong;
  final Color fg1;
  final Color fg2;
  final Color fg3;
  final Color fg4;

  const GeniusThemeData({
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

  static const Color blue500 = Color(0xFF4A7CFF);
  static const Color success500 = Color(0xFF1DB88A);
  static const Color warning500 = Color(0xFFF97316);
  static const Color danger500 = Color(0xFFEF4444);

  static const String displayFont = 'Manrope';
  static const String bodyFont = 'Inter';
  static const String monoFont = 'JetBrainsMono';
  static const String arabicFont = 'NotoNaskhArabic';

  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space10 = 40;
  static const double space16 = 64;
  static const double space20 = 80;

  static const double radiusXs = 2;
  static const double radiusSm = 4;
  static const double radiusMd = 6;
  static const double radiusLg = 8;
  static const double radiusXl = 12;
  static const double radiusPill = 999;

  static const double contentMax = 720;
  static const double contentWide = 1120;
  static const double gutter = 24;
  static const double bpSm = 480;
  static const double bpMd = 768;
  static const double bpLg = 1024;
  static const double bpXl = 1280;

  static const Duration durInstant = Duration.zero;
  static const Duration durFast = Duration(milliseconds: 100);
  static const Duration durBase = Duration(milliseconds: 150);
  static const Duration durModerate = Duration(milliseconds: 200);
  static const Duration durSlow = Duration(milliseconds: 300);
  static const Duration durSlower = Duration(milliseconds: 500);
  static const Duration stagger = Duration(milliseconds: 40);

  static const Curve easeStandard = Cubic(0.4, 0, 0.2, 1);
  static const Curve easeOut = Cubic(0, 0, 0.2, 1);
  static const Curve easeIn = Cubic(0.4, 0, 1, 1);
  static const Curve easeEmphasized = Cubic(0.2, 0, 0, 1);

  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x40000000), blurRadius: 50, spreadRadius: -12, offset: Offset(0, 25)),
  ];

  static const List<BoxShadow> popShadow = [
    BoxShadow(color: Color(0x73000000), blurRadius: 32, spreadRadius: -8, offset: Offset(0, 12)),
  ];

  static const GeniusThemeData dark = GeniusThemeData(
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

  static const GeniusThemeData light = GeniusThemeData(
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

  static GeniusThemeData fromBrowserTabs(BrowserStyleTabBarThemeData src) => GeniusThemeData(
        bg: src.bg,
        surface: src.surface,
        surface2: src.surface2,
        inputBg: src.inputBg,
        hover: src.hover,
        border: src.border,
        borderStrong: src.borderStrong,
        fg1: src.fg1,
        fg2: src.fg2,
        fg3: src.fg3,
        fg4: src.fg4,
      );

  static GeniusThemeData of(BuildContext context) {
    final explicit = Theme.of(context).extension<GeniusThemeData>();
    if (explicit != null) return explicit;
    final browser = Theme.of(context).extension<BrowserStyleTabBarThemeData>();
    if (browser != null) return fromBrowserTabs(browser);
    return Theme.of(context).brightness == Brightness.light ? light : dark;
  }

  BrowserStyleTabBarThemeData get browserTabsAdapter => BrowserStyleTabBarThemeData(
        bg: bg,
        surface: surface,
        surface2: surface2,
        inputBg: inputBg,
        hover: hover,
        border: border,
        borderStrong: borderStrong,
        fg1: fg1,
        fg2: fg2,
        fg3: fg3,
        fg4: fg4,
      );

  Color tone(String tone) {
    switch (tone) {
      case 'info':
        return blue500;
      case 'success':
        return success500;
      case 'warning':
        return warning500;
      case 'danger':
        return danger500;
      default:
        return fg3;
    }
  }

  @override
  GeniusThemeData copyWith({
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
      GeniusThemeData(
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
  GeniusThemeData lerp(ThemeExtension<GeniusThemeData>? other, double t) {
    if (other is! GeniusThemeData) return this;
    return GeniusThemeData(
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

Color glToneColor(BuildContext context, String tone) => GeniusThemeData.of(context).tone(tone);

TextStyle glTextStyle(BuildContext context, {double size = 13, FontWeight weight = FontWeight.w500, Color? color, String? family, double? height, double? letterSpacing}) {
  final s = GeniusThemeData.of(context);
  return TextStyle(
    fontFamily: family ?? GeniusThemeData.bodyFont,
    fontSize: size,
    fontWeight: weight,
    color: color ?? s.fg1,
    height: height,
    letterSpacing: letterSpacing,
  );
}
