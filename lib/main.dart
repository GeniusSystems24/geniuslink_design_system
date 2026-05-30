// ============================================================
// GeniusLink — BrowserStyleTabBar demo entrypoint.
//   File: lib/main.dart
//   Run:  flutter run -d chrome   (or any device)
// ============================================================

import 'package:flutter/material.dart';
import 'design_system/themes/app_theme.dart';
import 'design_system/documentation_examples/browser_tabs_demo.dart';

void main() => runApp(const GeniusLinkApp());

class GeniusLinkApp extends StatefulWidget {
  const GeniusLinkApp({super.key});
  @override
  State<GeniusLinkApp> createState() => _GeniusLinkAppState();
}

class _GeniusLinkAppState extends State<GeniusLinkApp> {
  bool _light = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeniusLink · BrowserStyleTabBar',
      debugShowCheckedModeBanner: false,
      theme: GLTheme.light,
      darkTheme: GLTheme.dark,
      themeMode: _light ? ThemeMode.light : ThemeMode.dark,
      // English + Arabic; Directionality flips automatically per locale,
      // and the RTL specimen forces rtl locally regardless.
      supportedLocales: const [Locale('en'), Locale('ar')],
      home: BrowserTabsDemo(
        light: _light,
        onToggleTheme: (v) => setState(() => _light = v),
      ),
    );
  }
}
