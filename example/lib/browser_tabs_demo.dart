// ============================================================
// BrowserStyleTabBar — gallery / documentation screen.
// Flutter mirror of design_system/components-browsertabs.html:
// the live LTR + RTL specimens and the anatomy / states / props docs.
//   File: example/lib/browser_tabs_demo.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:geniuslink_design_system/geniuslink_browser_tabs.dart';

class BrowserTabsDemo extends StatelessWidget {
  final ValueChanged<bool>? onToggleTheme; // true => light
  final bool light;
  const BrowserTabsDemo({super.key, this.onToggleTheme, this.light = false});

  @override
  Widget build(BuildContext context) {
    return _Shell(
      title: 'BrowserStyleTabBar',
      subtitle: 'GeniusLink Design System · V2 Stage D',
      light: light,
      onToggleTheme: onToggleTheme,
      children: [
        _Section(
          title: 'Workspace Tabs',
          desc:
              'Modern browser-style tab strip: the rounded active tab merges with the surface below; inactive tabs are muted with hairline separators. Pinned tabs (icon-only) anchor on the start edge; right-click any tab for close / duplicate / pin actions; drag to reorder; overflow chevrons appear when tabs run off the edge. The ▾ button lists every open tab; closing an unsaved tab prompts before discarding. Resting the pointer on any tab (≈0.5s) raises a mini-page preview — the page’s REAL captured frame, with its current state and data. Add (+), close (×), unsaved dot, truncation, and ←/→/Home/End keyboard nav. Dark/light + RTL.',
          child: const BrowserStyleTabBar(),
        ),
        _Section(
          title: 'LTR & RTL',
          desc:
              'The same component mirrored — pinned anchor, separators, close buttons, overflow chevrons and the + button all flip with direction. The context menu opens at the cursor in both directions.',
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: BrowserStyleTabBar(
              tabsState: [
                BrowserTab(id: 11, title: 'دليل الحسابات', kind: GLTabKind.ledger, pinned: true),
                BrowserTab(id: 12, title: 'قيد افتتاحي — JV-2024-0042', kind: GLTabKind.doc, dirty: true),
                BrowserTab(id: 13, title: 'لوحة التحكم', kind: GLTabKind.chart),
                BrowserTab(id: 14, title: 'ميزان المراجعة — الربع الثالث', kind: GLTabKind.ledger),
              ],
            ),
          ),
        ),
        _Section(
          title: 'Documentation',
          desc: 'Anatomy, states and props for the component.',
          child: const _DocsGrid(),
        ),
      ],
    );
  }
}

// ── Shell ──
class _Shell extends StatelessWidget {
  final String title, subtitle;
  final List<Widget> children;
  final bool light;
  final ValueChanged<bool>? onToggleTheme;
  const _Shell({required this.title, required this.subtitle, required this.children, required this.light, this.onToggleTheme});
  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('GENIUSLINK DESIGN SYSTEM',
                              style: TextStyle(
                                  fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.65, color: BrowserStyleTabBarThemeData.accent)),
                          const SizedBox(height: 10),
                          Text(title,
                              style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.displayFont, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.7, color: s.fg1)),
                          const SizedBox(height: 6),
                          Text(subtitle, style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 14, color: s.fg3)),
                        ],
                      ),
                    ),
                    if (onToggleTheme != null)
                      _ThemeToggle(light: light, onChanged: onToggleTheme!),
                  ],
                ),
                const SizedBox(height: 32),
                for (final c in children) ...[c, const SizedBox(height: 40)],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  final bool light;
  final ValueChanged<bool> onChanged;
  const _ThemeToggle({required this.light, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    return GestureDetector(
      onTap: () => onChanged(!light),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: s.surface,
            border: Border.all(color: s.borderStrong),
            borderRadius: BorderRadius.circular(BrowserStyleTabBarThemeData.radiusMd),
          ),
          child: Row(
            children: [
              Icon(light ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 15, color: s.fg2),
              const SizedBox(width: 8),
              Text(light ? 'Light' : 'Dark',
                  style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 13, fontWeight: FontWeight.w600, color: s.fg1)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section ──
class _Section extends StatelessWidget {
  final String title, desc;
  final Widget child;
  const _Section({required this.title, required this.desc, required this.child});
  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(width: 4, height: 22, color: BrowserStyleTabBarThemeData.accent, margin: const EdgeInsets.only(right: 12)),
          Text(title, style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 16, fontWeight: FontWeight.w700, color: s.fg1)),
        ]),
        const SizedBox(height: 8),
        Text(desc, style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 13, height: 1.55, color: s.fg3)),
        const SizedBox(height: 18),
        child,
      ],
    );
  }
}

// ── Spec card ──
class _Spec extends StatelessWidget {
  final String label;
  final Widget child;
  const _Spec({required this.label, required this.child});
  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: s.surface,
        border: Border.all(color: s.border),
        borderRadius: BorderRadius.circular(BrowserStyleTabBarThemeData.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.monoFont, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: BrowserStyleTabBarThemeData.accent)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final String tone;
  const _Pill(this.text, {this.tone = 'neutral'});
  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    final c = {'info': BrowserStyleTabBarThemeData.accent, 'warning': BrowserStyleTabBarThemeData.warning, 'success': BrowserStyleTabBarThemeData.success, 'neutral': s.fg3}[tone] ?? s.fg3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 11, fontWeight: FontWeight.w700, color: c)),
    );
  }
}

Widget _bullets(BuildContext context, List<String> items, {Color? color}) {
  final s = BrowserStyleTabBarThemeData.of(context);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final i in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('•  ', style: TextStyle(fontSize: 13, color: color ?? s.fg3, height: 1.55)),
              Expanded(child: Text(i, style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 13, height: 1.55, color: color ?? s.fg2))),
            ],
          ),
        ),
    ],
  );
}

class _DocsGrid extends StatelessWidget {
  const _DocsGrid();
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = (c.maxWidth / 300).floor().clamp(1, 3);
      final cards = <Widget>[
        _Spec(label: 'Anatomy', child: _bullets(context, const [
          'Strip container (sits on --gl-bg)',
          'Pinned region · icon-only · anchored',
          'Scrolling tab region + overflow chevrons',
          'Tab = leading icon · label · dirty dot / close ×',
          'New-tab (+) · tab-list (▾) buttons',
          'Content surface that merges with the active tab',
          'Right-click context menu',
          'Dirty-close confirmation dialog',
        ])),
        _Spec(
          label: 'States',
          child: Wrap(spacing: 8, runSpacing: 8, children: const [
            _Pill('Active', tone: 'info'),
            _Pill('Inactive'),
            _Pill('Hover'),
            _Pill('Pinned'),
            _Pill('Dirty', tone: 'warning'),
            _Pill('Dragging'),
            _Pill('Focused', tone: 'info'),
            _Pill('Overflow'),
            _Pill('Preview', tone: 'info'),
          ]),
        ),
        _Spec(label: 'Live mini-page preview', child: _bullets(context, const [
          'Hover-intent: appears after the pointer rests ~480ms',
          'Thumbnail is the page’s REAL captured frame (RepaintBoundary)',
          'Reflects its live state, data & scroll — not a stub',
          'Active tab is recaptured on hover; others show last frame',
          'Caret points to the tab; flips above when low; non-interactive',
        ])),
        _Spec(label: 'Context menu', child: _bullets(context, const [
          'Close tab',
          'Close other tabs',
          'Close tabs to the right',
          'Duplicate tab',
          'Pin / Unpin tab',
        ])),
        _Spec(label: 'Overflow & jump', child: _bullets(context, const [
          '‹ › chevrons fade in only when the strip overflows',
          '▾ tab-list dropdown lists every open tab',
          'Active row highlighted · pinned / dirty marked',
          'Pick jumps to the tab · Esc / outside-click closes',
        ])),
        _Spec(label: 'Unsaved guard', child: _bullets(context, const [
          'Closing a dirty tab opens a confirm dialog',
          'Discard & close — danger, drops edits',
          'Save & close — clears dirty, then closes',
          'Cancel / Esc / backdrop — keep the tab',
        ])),
        _Spec(label: 'Keyboard', child: _bullets(context, const [
          '← / → — previous / next tab',
          'Home / End — first / last tab',
          'Right-click / long-press — context menu · Esc closes it',
        ])),
        Builder(builder: (context) {
          final s = BrowserStyleTabBarThemeData.of(context);
          return _Spec(
            label: 'Props',
            child: Text(
              'tabsState?: List<BrowserTab>\n'
              'controller?: BrowserStyleTab\n'
              '  BarController  (ChangeNotifier)\n'
              'pageBuilder?: (ctx, tab) => W\n'
              'BrowserTab(id, title, kind,\n'
              '  dirty?, pinned?)',
              style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.monoFont, fontSize: 12.5, height: 1.7, color: s.fg2),
            ),
          );
        }),
        _Spec(label: 'Controller', child: _bullets(context, const [
          'State is a BrowserStyleTabBarController (ChangeNotifier)',
          'Pages reach it: BrowserStyleTabBarController.of(context)',
          'of(...) may return null (reused outside a tab bar)',
          'select · add · close · duplicate · pin · reorder · setDirty',
        ])),
        _Spec(
          label: "Do & Don't",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bullets(context, const ['✓ Pin long-lived references (chart of accounts).', '✓ Warn on closing a dirty tab.'], color: BrowserStyleTabBarThemeData.success),
              const SizedBox(height: 8),
              _bullets(context, const ['✗ More than ~3 pinned tabs.', '✗ Hiding the active tab off-screen on open.'], color: BrowserStyleTabBarThemeData.danger),
            ],
          ),
        ),
      ];
      return GridView.count(
        crossAxisCount: cols,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.82,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: cards,
      );
    });
  }
}
