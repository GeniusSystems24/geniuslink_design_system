// ============================================================
// ERP-style workspace shell.
// Module sidebar + app bar + the tab bar hosting the component's built-in
// accounting pages (ledger / journal / branch / dashboard / people).
// Highlights: pinned reference tab · unsaved (dirty) journal + close-guard ·
// overflow scrolling · tab-list dropdown · drag-reorder. Theme swaps
// light↔dark (watch the surfaces lerp).
//   File: example/lib/erp_app.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:geniuslink_design_system/geniuslink_design_system.dart';
import 'shell_kit.dart';

class ErpApp extends StatefulWidget {
  const ErpApp({super.key});
  @override
  State<ErpApp> createState() => _ErpAppState();
}

class _ErpAppState extends State<ErpApp> {
  bool _dark = false;
  int _module = 1;

  static const _modules = [
    (Icons.dashboard_outlined, 'Overview'),
    (Icons.account_balance_outlined, 'General Ledger'),
    (Icons.point_of_sale_outlined, 'Sales'),
    (Icons.inventory_2_outlined, 'Inventory'),
    (Icons.insights_outlined, 'Reports'),
    (Icons.groups_outlined, 'People'),
    (Icons.settings_outlined, 'Settings'),
  ];

  List<BrowserTab> get _seed => [
        BrowserTab(id: 1, title: 'Chart of Accounts', kind: GLTabKind.ledger, pinned: true),
        BrowserTab(id: 2, title: 'Opening Journal Entry — JV-2024-0042', kind: GLTabKind.doc, dirty: true),
        BrowserTab(id: 3, title: 'Trial Balance — FY2024 Q3', kind: GLTabKind.ledger),
        BrowserTab(id: 4, title: 'Downtown Central Store', kind: GLTabKind.store),
        BrowserTab(id: 5, title: 'Financial Dashboard', kind: GLTabKind.chart),
        BrowserTab(id: 6, title: 'Team Directory', kind: GLTabKind.user),
      ];

  @override
  Widget build(BuildContext context) {
    return themed(
      brightness: _dark ? Brightness.dark : Brightness.light,
      ext: _dark ? erpDark : erpLight,
      child: Builder(builder: (context) {
        final s = BrowserStyleTabBarThemeData.of(context);
        return Scaffold(
          backgroundColor: s.bg,
          body: SafeArea(
            child: Row(
              children: [
                _sidebar(s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _appBar(s),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                          child: Container(
                            decoration: BoxDecoration(
                              color: s.bg,
                              border: Border.all(color: s.border),
                              borderRadius: BorderRadius.circular(BrowserStyleTabBarThemeData.radiusXl),
                              boxShadow: _dark ? null : BrowserStyleTabBarThemeData.cardShadow,
                            ),
                            clipBehavior: Clip.antiAlias,
                            // ↓ the component, with its built-in ERP pages
                            child: BrowserStyleTabBar(tabsState: _seed),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _sidebar(BrowserStyleTabBarThemeData s) {
    return Container(
      width: 232,
      decoration: BoxDecoration(
        color: s.surface,
        border: Border(right: BorderSide(color: s.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // brand
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: BrowserStyleTabBarThemeData.accent, borderRadius: BorderRadius.circular(BrowserStyleTabBarThemeData.radiusMd)),
                  child: const Text('G', style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.displayFont, fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
                const SizedBox(width: 10),
                Text('GeniusLink',
                    style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.displayFont, fontSize: 16, fontWeight: FontWeight.w800, color: s.fg1)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
            child: Text('MODULES',
                style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.monoFont, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.9, color: s.fg3)),
          ),
          for (int i = 0; i < _modules.length; i++) _moduleRow(s, i),
          const Spacer(),
          Divider(color: s.border, height: 1),
          // user
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _avatar('MN'),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mohammed Nasser', style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 12.5, fontWeight: FontWeight.w600, color: s.fg1)),
                    Text('Accountant', style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 11, color: s.fg3)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _moduleRow(BrowserStyleTabBarThemeData s, int i) {
    final on = i == _module;
    return _Hoverable(builder: (hover) {
      return GestureDetector(
        onTap: () => setState(() => _module = i),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: on ? BrowserStyleTabBarThemeData.accent.withOpacity(0.12) : (hover ? s.hover : Colors.transparent),
            borderRadius: BorderRadius.circular(BrowserStyleTabBarThemeData.radiusMd),
          ),
          child: Row(
            children: [
              Icon(_modules[i].$1, size: 18, color: on ? BrowserStyleTabBarThemeData.accent : s.fg3),
              const SizedBox(width: 11),
              Text(_modules[i].$2,
                  style: TextStyle(
                      fontFamily: BrowserStyleTabBarThemeData.bodyFont,
                      fontSize: 13.5,
                      fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                      color: on ? s.fg1 : s.fg2)),
            ],
          ),
        ),
      );
    });
  }

  Widget _appBar(BrowserStyleTabBarThemeData s) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text('Finance', style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 13, color: s.fg3)),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.chevron_right, size: 16, color: s.fg3)),
          Text('General Ledger', style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 13, fontWeight: FontWeight.w600, color: s.fg1)),
          const Spacer(),
          // search
          Container(
            width: 240,
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: s.inputBg,
              borderRadius: BorderRadius.circular(BrowserStyleTabBarThemeData.radiusMd),
              border: Border.all(color: s.border),
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 16, color: s.fg3),
                const SizedBox(width: 8),
                Text('Search…', style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 13, color: s.fg3)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _chip(s, 'FY2024', Icons.calendar_today_outlined),
          const SizedBox(width: 8),
          GhostIconButton(
            _dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            tooltip: _dark ? 'Light theme' : 'Dark theme',
            size: 38,
            onTap: () => setState(() => _dark = !_dark),
          ),
        ],
      ),
    );
  }

  Widget _chip(BrowserStyleTabBarThemeData s, String label, IconData icon) => Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: s.borderStrong),
          borderRadius: BorderRadius.circular(BrowserStyleTabBarThemeData.radiusMd),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: s.fg2),
            const SizedBox(width: 7),
            Text(label, style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 13, fontWeight: FontWeight.w600, color: s.fg1)),
          ],
        ),
      );

  Widget _avatar(String initials) => Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: HSLColor.fromAHSL(1, 250, 0.42, 0.40).toColor(), shape: BoxShape.circle),
        child: Text(initials, style: const TextStyle(fontFamily: BrowserStyleTabBarThemeData.displayFont, fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
      );
}

// ── tiny hover helper ──
class _Hoverable extends StatefulWidget {
  final Widget Function(bool hover) builder;
  const _Hoverable({required this.builder});
  @override
  State<_Hoverable> createState() => _HoverableState();
}

class _HoverableState extends State<_Hoverable> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: widget.builder(_h),
    );
  }
}
