// ============================================================
// ERP Console — SHELL.
// ------------------------------------------------------------
// One realistic admin console that hosts all THREE design-system components
// at once, each doing its real job:
//   • BrowserStyleTabBar — the open-screens tab strip + content surface
//   • Tree               — the module navigator in the left sidebar
//   • EditableTable      — the data grid inside every screen (via the page)
//
// The Tree and the TabBar are kept in sync through a shared
// BrowserStyleTabBarController: picking a leaf in the tree opens/activates
// its tab; switching tabs re-selects the matching tree node. A top bar
// carries a Light/Dark switch and an LTR (EN) / RTL (AR) switch — the whole
// console flips direction and language live.
//   File: example/lib/erp_console.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:geniuslink_design_system/geniuslink_browser_tabs.dart';
import 'package:geniuslink_design_system/geniuslink_tree.dart';
import 'package:geniuslink_design_system/geniuslink_editable_table.dart';

import 'shell_kit.dart';
import 'erp_console_data.dart';
import 'erp_console_pages.dart';

class ErpConsole extends StatefulWidget {
  const ErpConsole({super.key});
  @override
  State<ErpConsole> createState() => _ErpConsoleState();
}

class _ErpConsoleState extends State<ErpConsole> {
  bool _light = true;
  bool _ar = false;

  late final BrowserStyleTabBarController _tabs;
  late TreeController _tree;

  /// tab.id ↔ screen.id, so tree ⇄ tabs can find each other.
  final Map<int, String> _tabScreen = {};

  @override
  void initState() {
    super.initState();
    // Seed tabs from the first three screens.
    final seed = <BrowserTab>[];
    for (var i = 0; i < 3; i++) {
      final s = erpScreens[i];
      final id = i + 1;
      seed.add(BrowserTab(id: id, title: s.title(_ar), kind: s.kind, dirty: s.dirty, pinned: i == 0));
      _tabScreen[id] = s.id;
    }
    _tabs = BrowserStyleTabBarController(tabs: seed, activeId: 1);
    _tabs.addListener(_onTabsChanged);
    _tree = _buildTree();
  }

  TreeController _buildTree() => TreeController(
        roots: erpNavTree(_ar),
        expanded: {'finance', 'sales', 'inventory'},
        selected: 'coa',
      );

  @override
  void dispose() {
    _tabs.removeListener(_onTabsChanged);
    _tabs.dispose();
    _tree.dispose();
    super.dispose();
  }

  // ── tree → tabs ────────────────────────────────────────────
  void _onTreeSelected(TreeNode node) {
    final screenId = node.data['screen'] as String?;
    if (screenId == null) return; // a folder — ignore
    // Already open? activate it.
    for (final entry in _tabScreen.entries) {
      if (entry.value == screenId) {
        _tabs.select(entry.key);
        return;
      }
    }
    // Otherwise open a new tab for this screen.
    final s = erpScreenById(screenId);
    if (s == null) return;
    final id = _tabs.add(title: s.title(_ar), kind: s.kind, activate: true);
    _tabScreen[id] = screenId;
  }

  // ── tabs → tree ────────────────────────────────────────────
  void _onTabsChanged() {
    final active = _tabs.activeId;
    if (active != null) {
      final screenId = _tabScreen[active];
      if (screenId != null && _tree.selected != screenId && _tree.node(screenId) != null) {
        _tree.select(screenId);
      }
    }
    // Drop mappings for tabs that were closed.
    final live = _tabs.tabs.map((t) => t.id).toSet();
    _tabScreen.removeWhere((k, v) => !live.contains(k));
    if (mounted) setState(() {});
  }

  // ── language / direction flip ──────────────────────────────
  void _toggleLang() {
    final old = _tree;
    final sel = old.selected;
    setState(() {
      _ar = !_ar;
      // Rebuild the tree in the new language, preserving selection/expansion.
      // The Tree widget is keyed on language, so the old controller's widget
      // unmounts this frame — defer its disposal until after that happens.
      _tree = TreeController(
        roots: erpNavTree(_ar),
        expanded: {'finance', 'sales', 'inventory'},
        selected: sel,
      );
    });
    // Re-title open tabs in the new language. The controller notifies its own
    // listeners (incl. this widget) — kept outside setState to avoid nesting.
    _tabs.mutate(() {
      for (final t in _tabs.tabs) {
        final sid = _tabScreen[t.id];
        final s = sid == null ? null : erpScreenById(sid);
        if (s != null) t.title = s.title(_ar);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final ext = _light ? erpLight : erpDark;
    return Directionality(
      textDirection: _ar ? TextDirection.rtl : TextDirection.ltr,
      child: themed(
        brightness: _light ? Brightness.light : Brightness.dark,
        ext: ext,
        child: Builder(builder: (context) {
          final s = BrowserStyleTabBarThemeData.of(context);
          return Scaffold(
            backgroundColor: s.bg,
            body: SafeArea(
              child: Column(
                children: [
                  _topBar(s),
                  Expanded(
                    child: Row(
                      children: [
                        _moduleRail(s),
                        _navPanel(s),
                        Expanded(child: _workspace(s)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── top bar ────────────────────────────────────────────────
  Widget _topBar(BrowserStyleTabBarThemeData s) {
    return Container(
      height: 52,
      padding: const EdgeInsetsDirectional.only(start: 16, end: 12),
      decoration: BoxDecoration(
        color: s.surface,
        border: Border(bottom: BorderSide(color: s.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: BrowserStyleTabBarThemeData.accent,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.hub, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text(
            tr(_ar, 'GeniusLink ERP', 'جينيوس لينك ERP'),
            style: TextStyle(
                fontFamily: BrowserStyleTabBarThemeData.displayFont,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: s.fg1),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: BrowserStyleTabBarThemeData.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              tr(_ar, 'FY2024', '٢٠٢٤'),
              style: const TextStyle(
                  fontFamily: BrowserStyleTabBarThemeData.monoFont,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: BrowserStyleTabBarThemeData.accent),
            ),
          ),
          const Spacer(),
          _segToggle(
            s,
            leftIcon: Icons.translate,
            leftLabel: 'EN',
            rightLabel: 'ع',
            rightSelected: _ar,
            onTap: _toggleLang,
          ),
          const SizedBox(width: 10),
          _segToggle(
            s,
            leftIcon: Icons.light_mode_outlined,
            leftLabel: tr(_ar, 'Light', 'فاتح'),
            rightLabel: tr(_ar, 'Dark', 'داكن'),
            rightSelected: !_light,
            onTap: () => setState(() => _light = !_light),
          ),
          const SizedBox(width: 8),
          GhostIconButton(Icons.notifications_none_rounded, tooltip: tr(_ar, 'Alerts', 'تنبيهات')),
          GhostIconButton(Icons.settings_outlined, tooltip: tr(_ar, 'Settings', 'إعدادات')),
          const SizedBox(width: 4),
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Color(0xFF1DB88A), shape: BoxShape.circle),
            child: const Text('NA', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _segToggle(
    BrowserStyleTabBarThemeData s, {
    required IconData leftIcon,
    required String leftLabel,
    required String rightLabel,
    required bool rightSelected,
    required VoidCallback onTap,
  }) {
    Widget seg(String label, bool selected, {IconData? icon}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? BrowserStyleTabBarThemeData.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: selected ? Colors.white : s.fg3),
                const SizedBox(width: 5),
              ],
              Text(label,
                  style: TextStyle(
                      fontFamily: BrowserStyleTabBarThemeData.bodyFont,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : s.fg2)),
            ],
          ),
        );
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: s.inputBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: s.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              seg(leftLabel, !rightSelected, icon: leftIcon),
              seg(rightLabel, rightSelected),
            ],
          ),
        ),
      ),
    );
  }

  // ── module rail (icon strip) ───────────────────────────────
  Widget _moduleRail(BrowserStyleTabBarThemeData s) {
    final mods = [
      (Icons.account_balance_outlined, 'finance', tr(_ar, 'Finance', 'المالية')),
      (Icons.point_of_sale_outlined, 'sales', tr(_ar, 'Sales', 'المبيعات')),
      (Icons.inventory_2_outlined, 'inventory', tr(_ar, 'Inventory', 'المخزون')),
    ];
    final activeScreen = _tabScreen[_tabs.activeId];
    final activeModule = activeScreen == null
        ? null
        : TreeOps.ancestorsOf(_tree.roots, activeScreen).isNotEmpty
            ? TreeOps.ancestorsOf(_tree.roots, activeScreen).first
            : null;
    return Container(
      width: 56,
      decoration: BoxDecoration(
        color: s.surface,
        border: Border(
          right: BorderSide(color: s.border),
          left: BorderSide(color: s.border),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          for (final m in mods) ...[
            _railItem(s, m.$1, m.$3, active: m.$2 == activeModule, onTap: () {
              _tree.expand(m.$2);
            }),
            const SizedBox(height: 6),
          ],
          const Spacer(),
          _railItem(s, Icons.bar_chart_rounded, tr(_ar, 'Reports', 'تقارير'), active: false, onTap: () {}),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _railItem(BrowserStyleTabBarThemeData s, IconData icon, String tip,
      {required bool active, required VoidCallback onTap}) {
    return Tooltip(
      message: tip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? BrowserStyleTabBarThemeData.accent.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 20, color: active ? BrowserStyleTabBarThemeData.accent : s.fg3),
          ),
        ),
      ),
    );
  }

  // ── tree navigation panel ──────────────────────────────────
  Widget _navPanel(BrowserStyleTabBarThemeData s) {
    return Container(
      width: 256,
      decoration: BoxDecoration(
        color: s.bg,
        border: Border(right: BorderSide(color: s.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 10),
            child: Text(
              tr(_ar, 'NAVIGATOR', 'المستكشف'),
              style: TextStyle(
                  fontFamily: BrowserStyleTabBarThemeData.monoFont,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: s.fg3),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(10, 0, 10, 12),
              child: Theme(
                // Add the Tree's own ThemeExtension alongside the console's,
                // so the navigator inherits the right light/dark surfaces
                // without dropping the tab-bar theme for descendants.
                data: Theme.of(context).copyWith(
                  extensions: [
                    ...Theme.of(context).extensions.values,
                    _light ? TreeThemeData.light : TreeThemeData.dark,
                  ],
                ),
                child: Tree(
                  key: ValueKey('tree-${_ar ? 'ar' : 'en'}'),
                  controller: _tree,
                  showToolbar: true,
                  showSearch: true,
                  showFooter: false,
                  editable: false,
                  dense: true,
                  onSelected: _onTreeSelected,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── workspace (tab bar + active screen) ────────────────────
  Widget _workspace(BrowserStyleTabBarThemeData s) {
    return Container(
      color: s.bg,
      child: BrowserStyleTabBar(
        controller: _tabs,
        pageBuilder: (context, tab) {
          final screenId = _tabScreen[tab.id];
          final screen = screenId == null ? null : erpScreenById(screenId);
          if (screen == null) {
            return Container(
              color: s.bg,
              alignment: Alignment.center,
              child: Text(tr(_ar, 'No screen', 'لا توجد شاشة'), style: TextStyle(color: s.fg3)),
            );
          }
          // EditableTable reads its OWN ThemeExtension — provide it here,
          // merged with the console's so the tab-bar theme is preserved.
          return Theme(
            data: Theme.of(context).copyWith(
              extensions: [
                ...Theme.of(context).extensions.values,
                _light ? EditableTableThemeData.light : EditableTableThemeData.dark,
              ],
            ),
            child: ErpScreenPage(screen: screen, ar: _ar),
          );
        },
      ),
    );
  }
}
