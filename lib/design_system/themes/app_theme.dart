// ============================================================
// GeniusLink Design System — Flutter Theme  (V2, documentation)
// ------------------------------------------------------------
// Builds light + dark ThemeData from GL* tokens. Widgets read from
// Theme.of(context) / GLColors — they never hardcode values.
//
// File placement:  lib/design_system/themes/app_theme.dart
//   MaterialApp(
//     theme: GLTheme.light, darkTheme: GLTheme.dark,
//     themeMode: ThemeMode.system,
//     locale: ..., supportedLocales: [Locale('en'), Locale('ar')],
//   )
// RTL is automatic via Directionality from the active locale.
// ============================================================

import 'package:flutter/material.dart';
import '../tokens/tokens.dart';
import '../tokens/gl_surfaces.dart';

class GLTheme {
  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData get light => _build(Brightness.light);

  static ThemeData _build(Brightness b) {
    final dark = b == Brightness.dark;

    final scheme = ColorScheme(
      brightness: b,
      primary: GLColors.blue500,
      onPrimary: Colors.white,
      secondary: GLColors.markerGreen,
      onSecondary: Colors.white,
      error: GLColors.danger,
      onError: Colors.white,
      surface: dark ? GLColors.darkCard : GLColors.lightSurface,
      onSurface: dark ? GLColors.darkFg1 : GLColors.lightFg1,
      background: dark ? GLColors.darkBg : GLColors.lightBg,
      onBackground: dark ? GLColors.darkFg1 : GLColors.lightFg1,
      outline: dark ? GLColors.darkFg4 : GLColors.lightBorder,
    );

    final fg1 = dark ? GLColors.darkFg1 : GLColors.lightFg1;
    final fg2 = dark ? GLColors.darkFg2 : GLColors.lightFg2;
    final fg3 = dark ? GLColors.darkFg3 : GLColors.lightFg3;

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.background,

      textTheme: TextTheme(
        displayLarge: GLType.h1.copyWith(color: fg1),
        titleMedium:  GLType.h2.copyWith(color: fg1),
        bodyMedium:   GLType.body14.copyWith(color: fg2),
        bodySmall:    GLType.caption.copyWith(color: fg3),
        labelSmall:   GLType.label.copyWith(color: fg2),
      ),

      // Inputs — 40px tall, 4px radius, hairline border, blue focus.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? GLColors.darkInput : GLColors.lightInput,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GLRadius.sm),
          borderSide: BorderSide(color: dark ? GLColors.darkFg4 : GLColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GLRadius.sm),
          borderSide: const BorderSide(color: GLColors.blue500, width: 2),
        ),
      ),

      // Primary button — solid blue, 4px radius, Inter 600/14.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(0, 44)), // a11y touch target
          backgroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.disabled)) return GLColors.blue500.withOpacity(0.4);
            if (s.contains(WidgetState.pressed))  return const Color(0xFF3D6DEB);
            if (s.contains(WidgetState.hovered))  return const Color(0xFF5E8DFF);
            return GLColors.blue500;
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(GLRadius.sm))),
          textStyle: WidgetStateProperty.all(GLType.body14.copyWith(fontWeight: FontWeight.w600)),
          animationDuration: GLDur.base,
        ),
      ),

      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GLRadius.lg),
          side: BorderSide(color: dark ? GLColors.darkBorder : GLColors.lightBorder),
        ),
      ),

      dividerColor: dark ? GLColors.darkBorder : GLColors.lightBorder,

      // Semantic surface/foreground roles (mirror colors_and_type.css).
      extensions: <ThemeExtension<dynamic>>[
        dark ? GLSurfaces.dark : GLSurfaces.light,
      ],

      // Default motion for page transitions.
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}
