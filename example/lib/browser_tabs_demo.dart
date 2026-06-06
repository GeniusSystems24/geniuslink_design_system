// ============================================================
// BrowserStyleTabBar — demo / test screen.
// Mirrors the Flutter component and proves its requirements interactively:
//   • State preservation — each tab page is a STATEFUL counter + scroll + text
//     field; switching tabs and returning keeps that state (IndexedStack
//     keep-alive). A "Keep-alive / Rebuild" toggle flips `lazyPages` so you can
//     watch state survive vs. reset.
//   • LTR / RTL          — a direction toggle wraps the live component.
//   • Keyboard           — ←/→ move (visual direction), Home/End jump; the
//                          shortcut directions follow the active Directionality.
//   File: example/lib/browser_tabs_demo.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:geniuslink_design_system/geniuslink_browser_tabs.dart';

class BrowserTabsDemo extends StatefulWidget {
  final ValueChanged<bool>? onToggleTheme; // true => light
  final bool light;
  const BrowserTabsDemo({super.key, this.onToggleTheme, this.light = false});

  @override
  State<BrowserTabsDemo> createState() => _BrowserTabsDemoState();
}

class _BrowserTabsDemoState extends State<BrowserTabsDemo> {
  bool _rtl = false;
  bool _lazy = false; // false => keep-alive (state preserved)

  // One external controller so the live demo + readouts stay in sync.
  late final BrowserStyleTabBarController _ctrl = BrowserStyleTabBarController(
    tabs: [
      BrowserTab(id: 1, title: 'Chart of Accounts', kind: GLTabKind.ledger, pinned: true),
      BrowserTab(id: 2, title: 'Journal Entry — JV-0042', kind: GLTabKind.doc, dirty: true),
      BrowserTab(id: 3, title: 'Dashboard', kind: GLTabKind.chart),
      BrowserTab(id: 4, title: 'Trial Balance — Q3', kind: GLTabKind.ledger),
      BrowserTab(id: 5, title: 'Customers', kind: GLTabKind.user),
    ],
    activeId: 1,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // Each tab gets a real stateful page — its counter / field / scroll position
  // is the thing we want to survive a tab switch.
  Widget _pageBuilder(BuildContext context, BrowserTab tab) =>
      _StatefulTabPage(key: ValueKey('page-${tab.id}-$_lazy'), tab: tab);

  @override
  Widget build(BuildContext context) {
    return _Shell(
      title: 'BrowserStyleTabBar',
      subtitle: 'GeniusLink Design System · v2.4.0',
      light: widget.light,
      onToggleTheme: widget.onToggleTheme,
      children: [
        _Section(
          title: 'State preservation (live test)',
          desc:
              'Each tab below hosts a STATEFUL page — a counter, a text field and a long scroll list. '
              'Increment the counter, type something, scroll down, then switch tabs and come back. With '
              'Keep-alive (the default) every page is built once and kept mounted, so its state survives. '
              'Flip to Rebuild (lazyPages: true) and the same round-trip resets the page — the proof the '
              'component preserves state.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _SegToggle(
                    leftLabel: 'Keep-alive',
                    rightLabel: 'Rebuild',
                    leftSelected: !_lazy,
                    leftIcon: Icons.lock_outline_rounded,
                    rightIcon: Icons.refresh_rounded,
                    onChanged: (left) => setState(() => _lazy = !left),
                  ),
                  const SizedBox(width: 10),
                  _DirToggle(rtl: _rtl, onChanged: (v) => setState(() => _rtl = v)),
                  const Spacer(),
                  _LazyBadge(lazy: _lazy),
                ],
              ),
              const SizedBox(height: 16),
              Directionality(
                textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
                child: SizedBox(
                  height: 520,
                  child: BrowserStyleTabBar(
                    controller: _ctrl,
                    pageBuilder: _pageBuilder,
                    lazyPages: _lazy,
                    fillContent: true,
                    scrollContent: false,
                  ),
                ),
              ),
            ],
          ),
        ),
        _Section(
          title: 'Default workspace strip',
          desc:
              'The component standalone — pinned (icon-only) tabs anchor on the start edge; right-click any '
              'tab for close / duplicate / pin; drag to reorder; overflow chevrons + the ▾ list appear when '
              'tabs run off the edge; closing an unsaved tab prompts first. ←/→/Home/End navigate (the arrow '
              'directions follow the layout direction).',
          child: const BrowserStyleTabBar(),
        ),
        _Section(
          title: 'Documentation',
          desc: 'Anatomy, states, keyboard and props for the component.',
          child: const _DocsGrid(),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// A real stateful page: counter + text field + scrollable list. THIS is the
// state we expect the tab bar to keep alive across switches.
// ════════════════════════════════════════════════════════════
class _StatefulTabPage extends StatefulWidget {
  final BrowserTab tab;
  const _StatefulTabPage({super.key, required this.tab});
  @override
  State<_StatefulTabPage> createState() => _StatefulTabPageState();
}

class _StatefulTabPageState extends State<_StatefulTabPage> {
  int _count = 0;
  final _scroll = ScrollController();
  final _field = TextEditingController();

  @override
  void dispose() {
    _scroll.dispose();
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: BrowserStyleTabBarThemeData.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(BrowserStyleTabBarThemeData.radiusMd),
                ),
                child: Icon(_iconFor(widget.tab.kind), size: 19, color: BrowserStyleTabBarThemeData.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(widget.tab.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: BrowserStyleTabBarThemeData.displayFont,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: s.fg1)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                    color: s.bg, borderRadius: BorderRadius.circular(999), border: Border.all(color: s.border)),
                child: Text('tab #${widget.tab.id}',
                    style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.monoFont, fontSize: 11, color: s.fg3)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // counter + text field — the live page state
          Row(
            children: [
              _CounterControl(
                value: _count,
                onMinus: () => setState(() => _count = (_count - 1).clamp(0, 9999)),
                onPlus: () => setState(() => _count++),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _field,
                  style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 14, color: s.fg1),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Type here, switch tabs, come back…',
                    hintStyle: TextStyle(color: s.fg4),
                    filled: true,
                    fillColor: s.bg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: s.border),
                        borderRadius: BorderRadius.circular(BrowserStyleTabBarThemeData.radiusMd)),
                    focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: BrowserStyleTabBarThemeData.accent, width: 1.5),
                        borderRadius: BorderRadius.circular(BrowserStyleTabBarThemeData.radiusMd)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Scroll position is also preserved — scroll this list, switch away, and return:',
              style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 12.5, color: s.fg3)),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: s.bg,
                borderRadius: BorderRadius.circular(BrowserStyleTabBarThemeData.radiusMd),
                border: Border.all(color: s.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Scrollbar(
                controller: _scroll,
                child: ListView.separated(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: 40,
                  separatorBuilder: (_, __) => Divider(height: 1, color: s.border),
                  itemBuilder: (ctx, i) => ListTile(
                    dense: true,
                    leading: Text('${(i + 1).toString().padLeft(2, '0')}',
                        style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.monoFont, fontSize: 12, color: s.fg4)),
                    title: Text('Line item ${i + 1} · ${widget.tab.title}',
                        style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 13, color: s.fg2)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(GLTabKind k) {
    switch (k) {
      case GLTabKind.ledger:
        return Icons.account_balance_outlined;
      case GLTabKind.doc:
        return Icons.description_outlined;
      case GLTabKind.store:
        return Icons.storefront_outlined;
      case GLTabKind.chart:
        return Icons.bar_chart_rounded;
      case GLTabKind.user:
        return Icons.people_outline_rounded;
      case GLTabKind.globe:
        return Icons.public_rounded;
    }
  }
}

class _CounterControl extends StatelessWidget {
  final int value;
  final VoidCallback onMinus, onPlus;
  const _CounterControl({required this.value, required this.onMinus, required this.onPlus});
  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    Widget btn(IconData ic, VoidCallback tap) => InkWell(
          onTap: tap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            child: Icon(ic, size: 18, color: s.fg2),
          ),
        );
    return Container(
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(BrowserStyleTabBarThemeData.radiusMd),
        border: Border.all(color: s.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        btn(Icons.remove_rounded, onMinus),
        Container(width: 1, height: 24, color: s.border),
        SizedBox(
          width: 52,
          child: Text('$value',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: BrowserStyleTabBarThemeData.monoFont, fontSize: 17, fontWeight: FontWeight.w700, color: BrowserStyleTabBarThemeData.accent)),
        ),
        Container(width: 1, height: 24, color: s.border),
        btn(Icons.add_rounded, onPlus),
      ]),
    );
  }
}

class _LazyBadge extends StatelessWidget {
  final bool lazy;
  const _LazyBadge({required this.lazy});
  @override
  Widget build(BuildContext context) {
    final c = lazy ? BrowserStyleTabBarThemeData.warning : BrowserStyleTabBarThemeData.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(color: c.withOpacity(0.14), borderRadius: BorderRadius.circular(999), border: Border.all(color: c.withOpacity(0.45))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(lazy ? Icons.refresh_rounded : Icons.lock_outline_rounded, size: 13, color: c),
        const SizedBox(width: 6),
        Text(lazy ? 'lazyPages: true · resets' : 'lazyPages: false · preserved',
            style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.monoFont, fontSize: 11, fontWeight: FontWeight.w700, color: c)),
      ]),
    );
  }
}

// ── segmented toggle (keep-alive vs rebuild) ──
class _SegToggle extends StatelessWidget {
  final String leftLabel, rightLabel;
  final bool leftSelected;
  final IconData leftIcon, rightIcon;
  final ValueChanged<bool> onChanged; // true => left chosen
  const _SegToggle({
    required this.leftLabel,
    required this.rightLabel,
    required this.leftSelected,
    required this.leftIcon,
    required this.rightIcon,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    Widget seg(String label, IconData ic, bool selected, VoidCallback tap) => GestureDetector(
          onTap: tap,
          child: AnimatedContainer(
            duration: BrowserStyleTabBarThemeData.durFast,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? BrowserStyleTabBarThemeData.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(BrowserStyleTabBarThemeData.radiusSm),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(ic, size: 14, color: selected ? Colors.white : s.fg3),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontFamily: BrowserStyleTabBarThemeData.bodyFont,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : s.fg2)),
            ]),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(BrowserStyleTabBarThemeData.radiusMd),
        border: Border.all(color: s.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        seg(leftLabel, leftIcon, leftSelected, () => onChanged(true)),
        seg(rightLabel, rightIcon, !leftSelected, () => onChanged(false)),
      ]),
    );
  }
}

class _DirToggle extends StatelessWidget {
  final bool rtl;
  final ValueChanged<bool> onChanged;
  const _DirToggle({required this.rtl, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    return GestureDetector(
      onTap: () => onChanged(!rtl),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: s.surface,
            border: Border.all(color: s.border),
            borderRadius: BorderRadius.circular(BrowserStyleTabBarThemeData.radiusMd),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(rtl ? Icons.format_textdirection_r_to_l_rounded : Icons.format_textdirection_l_to_r_rounded, size: 15, color: s.fg2),
            const SizedBox(width: 8),
            Text(rtl ? 'RTL' : 'LTR',
                style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 13, fontWeight: FontWeight.w600, color: s.fg1)),
          ]),
        ),
      ),
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
                    if (onToggleTheme != null) _ThemeToggle(light: light, onChanged: onToggleTheme!),
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
          Expanded(child: Text(title, style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 16, fontWeight: FontWeight.w700, color: s.fg1))),
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
        _Spec(label: 'State preservation', child: _bullets(context, const [
          'Default: every page built once, kept in an IndexedStack',
          'Scroll, text input & controllers survive tab switches',
          'lazyPages: true → only the active page is built (resets)',
          'pageBuilder supplies the page for each tab',
        ])),
        _Spec(label: 'Keyboard', child: _bullets(context, const [
          '← / → — previous / next tab (follows layout direction)',
          'Home / End — first / last tab',
          'Right-click / long-press — context menu · Esc closes it',
        ])),
        _Spec(label: 'Live mini-page preview', child: _bullets(context, const [
          'Hover-intent: appears after the pointer rests ~480ms',
          'Thumbnail is the page’s REAL captured frame (RepaintBoundary)',
          'Reflects its live state, data & scroll — not a stub',
          'Caret points to the tab; flips above when low; non-interactive',
        ])),
        _Spec(label: 'Context menu', child: _bullets(context, const [
          'Close tab',
          'Close other tabs',
          'Close tabs to the right',
          'Duplicate tab',
          'Pin / Unpin tab',
        ])),
        _Spec(label: 'Unsaved guard', child: _bullets(context, const [
          'Closing a dirty tab opens a confirm dialog',
          'Discard & close — danger, drops edits',
          'Save & close — clears dirty, then closes',
          'Cancel / Esc / backdrop — keep the tab',
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
              'lazyPages: bool = false\n'
              'fillContent · scrollContent\n'
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
