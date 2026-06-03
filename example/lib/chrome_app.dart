// ============================================================
// Chrome-style web browser shell.
// The tab strip sits at the very top of the window (the classic browser
// position), above a toolbar (back/forward/reload · omnibox · star · menu).
// The page area is a mock WEBSITE rendered via pageBuilder; the omnibox
// reflects the active tab's URL, and in-page links open NEW tabs through
// BrowserStyleTabBarController.of(context) — showing a page driving the strip.
//   File: example/lib/chrome_app.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:geniuslink_design_system/geniuslink_browser_tabs.dart';
import 'shell_kit.dart';

// ── a mock site keyed by tab id ──
class _Site {
  final String url;
  final String kind; // 'search' | 'article' | 'dashboard' | 'docs' | 'shop'
  const _Site(this.url, this.kind);
}

class ChromeApp extends StatefulWidget {
  const ChromeApp({super.key});
  @override
  State<ChromeApp> createState() => _ChromeAppState();
}

class _ChromeAppState extends State<ChromeApp> {
  late final BrowserStyleTabBarController _ctrl;

  final Map<int, _Site> _sites = {
    1: _Site('mail.proton.me', 'docs'),
    2: _Site('google.com/search?q=flutter+tabs', 'search'),
    3: _Site('news.ycombinator.com', 'article'),
    4: _Site('analytics.google.com', 'dashboard'),
    5: _Site('store.geniuslink.co', 'shop'),
  };

  @override
  void initState() {
    super.initState();
    _ctrl = BrowserStyleTabBarController(
      tabs: [
        BrowserTab(id: 1, title: 'Proton Mail', kind: GLTabKind.user, pinned: true),
        BrowserTab(id: 2, title: 'flutter tabs — Google Search', kind: GLTabKind.globe),
        BrowserTab(id: 3, title: 'Hacker News', kind: GLTabKind.doc),
        BrowserTab(id: 4, title: 'Analytics — Audience', kind: GLTabKind.chart),
        BrowserTab(id: 5, title: 'GeniusLink Store', kind: GLTabKind.store),
      ],
      activeId: 2,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _openSite(String title, String url, String kind, GLTabKind icon) {
    final id = _ctrl.add(title: title, kind: icon);
    _sites[id] = _Site(url, kind);
  }

  @override
  Widget build(BuildContext context) {
    return themed(
      brightness: Brightness.light,
      ext: webBrowserTheme,
      child: Builder(builder: (context) {
        final s = BrowserStyleTabBarThemeData.of(context);
        return Scaffold(
          backgroundColor: s.bg,
          body: SafeArea(
            child: Container(
              margin: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: s.surface,
                borderRadius: BorderRadius.circular(BrowserStyleTabBarThemeData.radiusXl),
                boxShadow: BrowserStyleTabBarThemeData.cardShadow,
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // ── the tab strip lives at the very top (classic browser) ──
                  // The toolbar (omnibox) is rendered inside each page so it
                  // reflects the active tab and appears in its live thumbnail.
                  Expanded(
                    child: BrowserStyleTabBar(
                      controller: _ctrl,
                      pageBuilder: (ctx, tab) => _WebPage(site: _sites[tab.id], tab: tab, onOpen: _openSite),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── omnibox toolbar + website body, rendered as the tab page ──
class _WebPage extends StatelessWidget {
  final _Site? site;
  final BrowserTab tab;
  final void Function(String title, String url, String kind, GLTabKind icon) onOpen;
  const _WebPage({required this.site, required this.tab, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    final url = site?.url ?? 'about:blank';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _toolbar(context, s, url),
        const SizedBox(height: 18),
        _body(context, s),
      ],
    );
  }

  // back / forward / reload · omnibox · star · menu
  Widget _toolbar(BuildContext context, BrowserStyleTabBarThemeData s, String url) {
    return Row(
      children: [
        GhostIconButton(Icons.arrow_back, tooltip: 'Back', size: 34, iconSize: 18),
        GhostIconButton(Icons.arrow_forward, tooltip: 'Forward', size: 34, iconSize: 18, color: s.fg4),
        GhostIconButton(Icons.refresh, tooltip: 'Reload', size: 34, iconSize: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: s.inputBg, borderRadius: BorderRadius.circular(999)),
            child: Row(children: [
              Icon(Icons.lock, size: 14, color: BrowserStyleTabBarThemeData.success),
              const SizedBox(width: 9),
              Expanded(
                child: Text(url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 13.5, color: s.fg1)),
              ),
              Icon(Icons.star_border, size: 17, color: s.fg3),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        GhostIconButton(Icons.extension_outlined, tooltip: 'Extensions', size: 34, iconSize: 18),
        GhostIconButton(Icons.more_vert, tooltip: 'Menu', size: 34, iconSize: 18),
      ],
    );
  }

  Widget _body(BuildContext context, BrowserStyleTabBarThemeData s) {
    switch (site?.kind) {
      case 'search':
        return _search(context, s);
      case 'article':
        return _article(context, s);
      case 'dashboard':
        return _dashboard(context, s);
      case 'shop':
        return _shop(context, s);
      case 'docs':
      default:
        return _docs(context, s);
    }
  }

  // ── Google-style search results, links open new tabs ──
  Widget _search(BuildContext context, BrowserStyleTabBarThemeData s) {
    final results = [
      ('Flutter — Tabs & TabBarView', 'docs.flutter.dev › cookbook › design › tabs', 'dashboard', GLTabKind.chart),
      ('Build a browser-style tab strip in Flutter', 'medium.com › flutter-community', 'article', GLTabKind.doc),
      ('GeniusLink Store — components', 'store.geniuslink.co › tabs', 'shop', GLTabKind.store),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(color: s.inputBg, borderRadius: BorderRadius.circular(999)),
          child: Row(children: [
            const Text('G', style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.displayFont, fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF4285F4))),
            const SizedBox(width: 10),
            Expanded(child: Text('flutter tabs', style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 15, color: s.fg1))),
            Icon(Icons.search, size: 18, color: s.fg3),
          ]),
        ),
        const SizedBox(height: 18),
        Text('About 1,240,000 results (0.38 seconds)', style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 12.5, color: s.fg3)),
        const SizedBox(height: 14),
        for (final r in results)
          _LinkResult(
            title: r.$1,
            crumb: r.$2,
            onTap: () => onOpen(r.$1, r.$2.split(' ').first, r.$3, r.$4),
          ),
      ],
    );
  }

  Widget _article(BuildContext context, BrowserStyleTabBarThemeData s) {
    final items = [
      ('Show HN: A browser-style tab strip widget', 412, 188),
      ('The state of Flutter desktop in 2026', 287, 96),
      ('Why ChangeNotifier is still great', 201, 143),
      ('Capturing widgets to images with RepaintBoundary', 156, 64),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xFFFF6600), borderRadius: BorderRadius.circular(3)),
            child: const Text('Y', style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.displayFont, fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Text('Hacker News', style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 15, fontWeight: FontWeight.w700, color: s.fg1)),
        ]),
        const SizedBox(height: 16),
        for (int i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 13),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${i + 1}.', style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 13.5, color: s.fg3)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(items[i].$1, style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 14, fontWeight: FontWeight.w600, color: s.fg1)),
                  const SizedBox(height: 2),
                  Text('${items[i].$2} points · ${items[i].$3} comments',
                      style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 12, color: s.fg3)),
                ]),
              ),
            ]),
          ),
      ],
    );
  }

  Widget _dashboard(BuildContext context, BrowserStyleTabBarThemeData s) {
    final bars = [42, 68, 55, 91, 73, 88, 64];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Audience overview', style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.displayFont, fontSize: 19, fontWeight: FontWeight.w700, color: s.fg1)),
        const SizedBox(height: 16),
        Row(children: [
          _metric(s, 'Users', '48.2K', '▲ 12%'),
          const SizedBox(width: 12),
          _metric(s, 'Sessions', '129K', '▲ 6%'),
          const SizedBox(width: 12),
          _metric(s, 'Bounce', '38.4%', '▼ 3%'),
        ]),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: s.surface2, border: Border.all(color: s.border), borderRadius: BorderRadius.circular(BrowserStyleTabBarThemeData.radiusLg)),
          child: SizedBox(
            height: 120,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (int i = 0; i < bars.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: bars[i] * 1.1,
                    decoration: BoxDecoration(color: const Color(0xFF4285F4).withOpacity(i == 3 ? 1 : 0.4), borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  Widget _shop(BuildContext context, BrowserStyleTabBarThemeData s) {
    final products = [
      ('Tab Strip Pro', 'SAR 120', const Color(0xFF7B61FF)),
      ('Data Grid Kit', 'SAR 240', const Color(0xFF0ACF83)),
      ('Charts Bundle', 'SAR 180', const Color(0xFFFF7262)),
      ('Icon Pack', 'SAR 60', const Color(0xFF1ABCFE)),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('GeniusLink Store', style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.displayFont, fontSize: 19, fontWeight: FontWeight.w700, color: s.fg1)),
      const SizedBox(height: 16),
      Wrap(spacing: 12, runSpacing: 12, children: [
        for (final p in products)
          Container(
            width: 150,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: s.surface2, border: Border.all(color: s.border), borderRadius: BorderRadius.circular(BrowserStyleTabBarThemeData.radiusLg)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(height: 64, decoration: BoxDecoration(color: p.$3.withOpacity(0.9), borderRadius: BorderRadius.circular(6))),
              const SizedBox(height: 10),
              Text(p.$1, style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 13.5, fontWeight: FontWeight.w600, color: s.fg1)),
              const SizedBox(height: 2),
              Text(p.$2, style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.monoFont, fontSize: 12.5, color: s.fg2)),
            ]),
          ),
      ]),
    ]);
  }

  Widget _docs(BuildContext context, BrowserStyleTabBarThemeData s) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.mail_outline, size: 20, color: const Color(0xFF6D4AFF)),
        const SizedBox(width: 10),
        Text('Inbox', style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.displayFont, fontSize: 19, fontWeight: FontWeight.w700, color: s.fg1)),
        const Spacer(),
        Text('3 unread', style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 12.5, color: s.fg3)),
      ]),
      const SizedBox(height: 14),
      for (final m in const [
        ('Figma', 'Your weekly design digest', true),
        ('GitHub', '[geniuslink] 3 new pull requests', true),
        ('Vercel', 'Deployment ready — production', true),
        ('Linear', 'GL-482 moved to In Review', false),
      ])
        Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: s.border))),
          child: Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: m.$3 ? const Color(0xFF6D4AFF) : Colors.transparent, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            SizedBox(width: 110, child: Text(m.$1, style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 13.5, fontWeight: m.$3 ? FontWeight.w700 : FontWeight.w500, color: s.fg1))),
            Expanded(child: Text(m.$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 13, color: s.fg2))),
          ]),
        ),
    ]);
  }

  Widget _metric(BrowserStyleTabBarThemeData s, String label, String value, String delta) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: s.surface2, border: Border.all(color: s.border), borderRadius: BorderRadius.circular(BrowserStyleTabBarThemeData.radiusLg)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 12, color: s.fg3)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.displayFont, fontSize: 21, fontWeight: FontWeight.w700, color: s.fg1)),
            const SizedBox(height: 4),
            Text(delta, style: const TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 12, fontWeight: FontWeight.w600, color: BrowserStyleTabBarThemeData.success)),
          ]),
        ),
      );
}

class _LinkResult extends StatefulWidget {
  final String title, crumb;
  final VoidCallback onTap;
  const _LinkResult({required this.title, required this.crumb, required this.onTap});
  @override
  State<_LinkResult> createState() => _LinkResultState();
}

class _LinkResultState extends State<_LinkResult> {
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
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.crumb, style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 12, color: s.fg3)),
            const SizedBox(height: 3),
            Text(widget.title,
                style: TextStyle(
                    fontFamily: BrowserStyleTabBarThemeData.bodyFont,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A0DAB),
                    decoration: _h ? TextDecoration.underline : TextDecoration.none,
                    decorationColor: const Color(0xFF1A0DAB))),
            const SizedBox(height: 3),
            Text('Open this result in a new tab — the page calls the controller to add it.',
                style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 12.5, height: 1.4, color: s.fg2)),
          ]),
        ),
      ),
    );
  }
}
