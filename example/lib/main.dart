// ============================================================
// GeniusLink — BrowserStyleTabBar example app.
// A launcher that opens the SAME component dressed as three very different
// products — proving the tab strip is fully reusable across themes & content:
//   • ERP system   — light SaaS, built-in accounting pages
//   • Figma editor — dark design tool, custom canvas pages
//   • Chrome        — web browser, custom website pages
// plus the documentation gallery.
//
// Every screen registers its own BrowserStyleTabBarThemeData; the component
// reads it via BrowserStyleTabBarThemeData.of(context). Pages drive the strip
// through BrowserStyleTabBarController.of(context), and the hover preview
// shows each page's REAL captured frame.
//
//   Run:  cd flutter/example && flutter pub get && flutter run -d chrome
// ============================================================

import 'package:flutter/material.dart';
import 'package:geniuslink_design_system/geniuslink_design_system.dart';
import 'erp_app.dart';
import 'figma_app.dart';
import 'chrome_app.dart';
import 'browser_tabs_demo.dart';
import 'shell_kit.dart';
import 'components/all_components_demo.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeniusLink · BrowserStyleTabBar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        fontFamily: BrowserStyleTabBarThemeData.bodyFont,
        scaffoldBackgroundColor: BrowserStyleTabBarThemeData.light.bg,
        extensions: const [BrowserStyleTabBarThemeData.light],
      ),
      supportedLocales: const [Locale('en'), Locale('ar')],
      home: const LauncherScreen(),
    );
  }
}

// ════════════════════════════════════════════════════════════
// LAUNCHER
// ════════════════════════════════════════════════════════════
class LauncherScreen extends StatelessWidget {
  const LauncherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              children: [
                Text('GENIUSLINK DESIGN SYSTEM',
                    style: TextStyle(
                        fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.6, color: BrowserStyleTabBarThemeData.accent)),
                const SizedBox(height: 12),
                Text('BrowserStyleTabBar',
                    style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.displayFont, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: s.fg1)),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Text(
                    'One reusable tab strip — themed and filled three different ways. '
                    'Open each to try pinned tabs, drag-reorder, the unsaved-close guard, '
                    'the tab-list dropdown, and the live page thumbnails on hover.',
                    style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 14.5, height: 1.55, color: s.fg3),
                  ),
                ),
                const SizedBox(height: 32),
                LayoutBuilder(builder: (context, c) {
                  final cols = c.maxWidth > 760 ? 3 : (c.maxWidth > 460 ? 2 : 1);
                  return GridView.count(
                    crossAxisCount: cols,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                    childAspectRatio: 0.92,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _DemoCard(
                        title: 'ERP System',
                        subtitle: 'Light SaaS workspace · accounting pages · pinned reference · unsaved journal',
                        accent: BrowserStyleTabBarThemeData.accent,
                        preview: const _ErpThumb(),
                        onTap: () => _open(context, const ErpApp()),
                      ),
                      _DemoCard(
                        title: 'Figma-style Editor',
                        subtitle: 'Dark design tool · canvas pages · pages mutate & mark dirty',
                        accent: const Color(0xFF7B61FF),
                        preview: const _FigmaThumb(),
                        onTap: () => _open(context, const FigmaApp()),
                      ),
                      _DemoCard(
                        title: 'Chrome-style Browser',
                        subtitle: 'Web window · omnibox · links open new tabs from the page',
                        accent: const Color(0xFF4285F4),
                        preview: const _ChromeThumb(),
                        onTap: () => _open(context, const ChromeApp()),
                      ),
                      _DemoCard(
                        title: 'Documentation',
                        subtitle: 'Anatomy, states, props & the LTR / RTL specimens',
                        accent: s.fg2,
                        preview: const _DocsThumb(),
                        onTap: () => _open(context, const _GalleryRoute()),
                      ),
                      _DemoCard(
                        title: 'Full Component Gallery',
                        subtitle: 'Core · Domain · Charts · Skeletons · ComboBox · Table · Patterns · Motion',
                        accent: GeniusThemeData.blue500,
                        preview: const _ComponentsThumb(),
                        onTap: () => _open(context, const AllComponentsDemo()),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => _BackScaffold(child: screen)));
  }
}

class _DemoCard extends StatefulWidget {
  final String title, subtitle;
  final Color accent;
  final Widget preview;
  final VoidCallback onTap;
  const _DemoCard({required this.title, required this.subtitle, required this.accent, required this.preview, required this.onTap});
  @override
  State<_DemoCard> createState() => _DemoCardState();
}

class _DemoCardState extends State<_DemoCard> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: BrowserStyleTabBarThemeData.durBase,
          transform: _h ? (Matrix4.identity()..translate(0.0, -3.0)) : Matrix4.identity(),
          decoration: BoxDecoration(
            color: s.surface,
            border: Border.all(color: _h ? widget.accent.withOpacity(0.5) : s.border),
            borderRadius: BorderRadius.circular(BrowserStyleTabBarThemeData.radiusXl),
            boxShadow: _h ? BrowserStyleTabBarThemeData.cardShadow : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: widget.preview),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(widget.title,
                            style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.displayFont, fontSize: 16, fontWeight: FontWeight.w700, color: s.fg1)),
                      ),
                      Icon(Icons.arrow_outward, size: 16, color: _h ? widget.accent : s.fg3),
                    ]),
                    const SizedBox(height: 6),
                    Text(widget.subtitle, style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 12.5, height: 1.45, color: s.fg3)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── small static thumbnails for the launcher cards ──
class _MiniTabs extends StatelessWidget {
  final Color strip, active, text;
  final List<String> labels;
  final int activeIndex;
  const _MiniTabs({required this.strip, required this.active, required this.text, required this.labels, this.activeIndex = 0});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: strip,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: i == activeIndex ? active : Colors.transparent,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
              child: Text(labels[i], style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 9.5, fontWeight: FontWeight.w600, color: text)),
            ),
          ],
          const Spacer(),
          Icon(Icons.add, size: 13, color: text),
        ],
      ),
    );
  }
}

class _ErpThumb extends StatelessWidget {
  const _ErpThumb();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F8FA),
      child: Column(children: [
        const _MiniTabs(strip: Color(0xFFF7F8FA), active: Colors.white, text: Color(0xFF64748B), labels: ['Ledger', 'Journal', 'Store'], activeIndex: 1),
        Expanded(child: Container(color: Colors.white, margin: const EdgeInsets.fromLTRB(8, 0, 8, 8), padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 80, height: 8, color: const Color(0xFF0F172A)),
          const SizedBox(height: 8),
          for (int i = 0; i < 3; i++) Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [Container(width: 30, height: 6, color: const Color(0xFFE2E8F0)), const SizedBox(width: 8), Expanded(child: Container(height: 6, color: const Color(0xFFEEF1F7)))])),
        ]))),
      ]),
    );
  }
}

class _FigmaThumb extends StatelessWidget {
  const _FigmaThumb();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E1E),
      child: Column(children: [
        const _MiniTabs(strip: Color(0xFF1E1E1E), active: Color(0xFF2C2C2C), text: Color(0xFFB3B3B3), labels: ['System', 'App', 'Site'], activeIndex: 1),
        Expanded(child: Container(color: const Color(0xFF1A1A1A), margin: const EdgeInsets.fromLTRB(8, 0, 8, 8), child: Center(child: Container(width: 120, height: 70, decoration: BoxDecoration(color: const Color(0xFF222226), borderRadius: BorderRadius.circular(4)), child: Stack(children: const [
          Positioned(left: 12, top: 12, child: _Box(34, 34, Color(0xFF7B61FF), circle: true)),
          Positioned(left: 56, top: 16, child: _Box(48, 20, Color(0xFF0ACF83))),
          Positioned(left: 56, top: 42, child: _Box(40, 16, Color(0xFFFF7262))),
        ]))))),
      ]),
    );
  }
}

class _ChromeThumb extends StatelessWidget {
  const _ChromeThumb();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFDEE1E6),
      child: Column(children: [
        const _MiniTabs(strip: Color(0xFFDEE1E6), active: Colors.white, text: Color(0xFF5F6368), labels: ['Mail', 'Search', 'News'], activeIndex: 1),
        Expanded(child: Container(color: Colors.white, child: Column(children: [
          Container(height: 22, margin: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFF1F3F4), borderRadius: BorderRadius.circular(999)), padding: const EdgeInsets.symmetric(horizontal: 8), child: Row(children: [const Icon(Icons.lock, size: 9, color: Color(0xFF0ACF83)), const SizedBox(width: 5), Container(width: 90, height: 5, color: const Color(0xFFBDC1C6))])),
          Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [for (int i = 0; i < 2; i++) Padding(padding: const EdgeInsets.only(bottom: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 60, height: 5, color: const Color(0xFFE2E8F0)), const SizedBox(height: 4), Container(width: 120, height: 7, color: const Color(0xFF1A0DAB))]))]))),
        ]))),
      ]),
    );
  }
}

class _DocsThumb extends StatelessWidget {
  const _DocsThumb();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F8FA),
      padding: const EdgeInsets.all(14),
      child: GridView.count(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        physics: const NeverScrollableScrollPhysics(),
        children: [for (int i = 0; i < 6; i++) Container(decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(6)))],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  final double w, h;
  final Color c;
  final bool circle;
  const _Box(this.w, this.h, this.c, {this.circle = false});
  @override
  Widget build(BuildContext context) => Container(width: w, height: h, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(circle ? 999 : 4)));
}

// ── wraps a pushed demo with a floating "back to launcher" button ──
class _BackScaffold extends StatelessWidget {
  final Widget child;
  const _BackScaffold({required this.child});
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: child),
        Positioned(
          left: 16,
          bottom: 16,
          child: SafeArea(
            child: Material(
              color: Colors.black.withOpacity(0.62),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => Navigator.of(context).maybePop(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.arrow_back, size: 16, color: Colors.white),
                    SizedBox(width: 7),
                    Text('Demos', style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── the documentation gallery, self-contained with a theme toggle ──
class _GalleryRoute extends StatefulWidget {
  const _GalleryRoute();
  @override
  State<_GalleryRoute> createState() => _GalleryRouteState();
}

class _GalleryRouteState extends State<_GalleryRoute> {
  bool _light = true;
  @override
  Widget build(BuildContext context) {
    return themed(
      brightness: _light ? Brightness.light : Brightness.dark,
      ext: _light ? BrowserStyleTabBarThemeData.light : BrowserStyleTabBarThemeData.dark,
      child: BrowserTabsDemo(light: _light, onToggleTheme: (v) => setState(() => _light = v)),
    );
  }
}


class _ComponentsThumb extends StatelessWidget {
  const _ComponentsThumb();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F8FA),
      padding: const EdgeInsets.all(12),
      child: GridView.count(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          _IconTile(Icons.smart_button_outlined),
          _IconTile(Icons.chat_bubble_outline_rounded),
          _IconTile(Icons.bar_chart_rounded),
          _IconTile(Icons.blur_on_rounded),
          _IconTile(Icons.search_rounded),
          _IconTile(Icons.table_chart_outlined),
        ],
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final IconData icon;
  const _IconTile(this.icon);
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Icon(icon, color: GeniusThemeData.blue500, size: 24),
      );
}
