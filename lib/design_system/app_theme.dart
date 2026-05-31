// ============================================================
// GeniusLink Design System — Flutter app theme helpers.
// ============================================================

import 'package:flutter/material.dart';
import 'tokens.dart';

class GeniusAppTheme {
  const GeniusAppTheme._();

  static ThemeData light({Iterable<ThemeExtension<dynamic>> extensions = const []}) => _theme(
        brightness: Brightness.light,
        tokens: GeniusThemeData.light,
        extensions: extensions,
      );

  static ThemeData dark({Iterable<ThemeExtension<dynamic>> extensions = const []}) => _theme(
        brightness: Brightness.dark,
        tokens: GeniusThemeData.dark,
        extensions: extensions,
      );

  static ThemeData _theme({required Brightness brightness, required GeniusThemeData tokens, Iterable<ThemeExtension<dynamic>> extensions = const []}) {
    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      fontFamily: GeniusThemeData.bodyFont,
      scaffoldBackgroundColor: tokens.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: GeniusThemeData.blue500,
        brightness: brightness,
        primary: GeniusThemeData.blue500,
        error: GeniusThemeData.danger500,
      ),
      extensions: <ThemeExtension<dynamic>>[
        tokens,
        tokens.browserTabsAdapter,
        // ...extensions,
      ],
      dividerColor: tokens.border,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: tokens.surface,
        contentTextStyle: TextStyle(fontFamily: GeniusThemeData.bodyFont, color: tokens.fg1),
      ),
    );
  }
}
