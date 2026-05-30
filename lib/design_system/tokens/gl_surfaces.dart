// ============================================================
// GLSurfaces — semantic surface/foreground colors as a ThemeExtension.
// ------------------------------------------------------------
// The CSS side aliases roles (--gl-bg / --gl-surface / --gl-hover /
// --gl-input-bg / --gl-border / --gl-border-strong / --gl-fg-1..4)
// that swap wholesale between dark & light. ColorScheme only covers a
// few of these, so this extension carries the full set 1:1 with
// colors_and_type.css. Read it with `GLSurfaces.of(context)` — never
// hardcode a hex inside a widget.
//
// File placement:  lib/design_system/tokens/gl_surfaces.dart
// ============================================================

import 'package:flutter/material.dart';
import 'tokens.dart';

@immutable
class GLSurfaces extends ThemeExtension<GLSurfaces> {
  final Color bg;           // --gl-bg          page / strip container
  final Color surface;      // --gl-surface     card / active-tab content
  final Color surface2;     // --gl-surface-2   nested card
  final Color inputBg;      // --gl-input-bg    input fill / close-hover
  final Color hover;        // --gl-hover       hover tint
  final Color border;       // --gl-border      hairline
  final Color borderStrong; // --gl-border-strong  solid divider
  final Color fg1;          // --gl-fg-1        primary text
  final Color fg2;          // --gl-fg-2        secondary
  final Color fg3;          // --gl-fg-3        tertiary / placeholder
  final Color fg4;          // --gl-fg-4        disabled

  const GLSurfaces({
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

  // ---- DARK (Figma primary / dominant) ----
  static const dark = GLSurfaces(
    bg: GLColors.darkBg,
    surface: GLColors.darkCard,
    surface2: GLColors.darkCard2,
    inputBg: GLColors.darkInput,
    hover: GLColors.darkHover,
    border: GLColors.darkBorder,
    borderStrong: Color(0xFF434654), // rgb(67,70,84)
    fg1: GLColors.darkFg1,
    fg2: GLColors.darkFg2,
    fg3: GLColors.darkFg3,
    fg4: GLColors.darkFg4,
  );

  // ---- LIGHT ----
  static const light = GLSurfaces(
    bg: GLColors.lightBg,
    surface: GLColors.lightSurface,
    surface2: GLColors.lightSurface,
    inputBg: GLColors.lightInput,
    hover: GLColors.lightHover,
    border: GLColors.lightBorder,
    borderStrong: Color(0xFFC2C6D6), // rgb(194,198,214)
    fg1: GLColors.lightFg1,
    fg2: GLColors.lightFg2,
    fg3: GLColors.lightFg3,
    fg4: GLColors.lightFg4,
  );

  static GLSurfaces of(BuildContext context) =>
      Theme.of(context).extension<GLSurfaces>() ?? dark;

  @override
  GLSurfaces copyWith({
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
      GLSurfaces(
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
  GLSurfaces lerp(ThemeExtension<GLSurfaces>? other, double t) {
    if (other is! GLSurfaces) return this;
    return GLSurfaces(
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
