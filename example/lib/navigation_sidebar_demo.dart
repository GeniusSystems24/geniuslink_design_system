// ============================================================
// NavigationSidebar — example screen.
// ------------------------------------------------------------
// Reproduces the GeniusLink web "Navigation Sidebar Workbench"
// (design_system/components-navigation-sidebar.html): an app shell with a top
// bar (brand · search · workspace · account) and the NavigationSidebar down the
// side, over a muted faux page. A workbench strip lets you flip Light/Dark,
// LTR/RTL, and a device-width simulator (Fill · Desktop · Tablet · Mobile) so
// the expanded → rail → drawer responsive behaviour is demoable live.
//
//   File: example/lib/navigation_sidebar_demo.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:geniuslink_design_system/geniuslink_navigation_sidebar.dart';

// ── nav data (mirrors the web SIDEBAR_NAV / HUB_TABS subset) ──────────────
NavNode<String> _leaf(String id, String label, IconData icon, {NavBadge? badge, List<String>? keys}) =>
    NavNode<String>(id: id, label: label, icon: icon, value: id, badge: badge, shortcut: keys);

final List<NavSection<String>> kNavSections = [
  NavSection(title: 'Overview', items: [
    _leaf('dashboard', 'Dashboard', Icons.work_outline, keys: ['g', 'd']),
    _leaf('invDashboard', 'Inventory Dashboard', Icons.qr_code_scanner, keys: ['g', 'i']),
  ]),
  NavSection(title: 'Finance', items: [
    NavNode(id: 'accountsHub', label: 'Accounts', icon: Icons.menu_book_outlined, children: [
      NavNode(id: 'accountsHub:coa', label: 'Chart of Accounts', children: [
        _leaf('accounts', 'Chart of Accounts', Icons.menu_book_outlined),
        _leaf('accountTree', 'Account Tree', Icons.account_tree_outlined, keys: ['g', 't']),
        _leaf('createAccount', 'Create Account', Icons.add),
      ]),
      NavNode(id: 'accountsHub:groups', label: 'Account Groups', children: [
        _leaf('group', 'Create Account Group', Icons.work_outline),
      ]),
    ]),
    NavNode(id: 'ledgerHub', label: 'Ledger', icon: Icons.menu_book_outlined, children: [
      NavNode(id: 'ledgerHub:je', label: 'Journal Entries', children: [
        _leaf('journals', 'Journal Entries', Icons.menu_book_outlined, badge: const NavBadge('3'), keys: ['g', 'j']),
        _leaf('createJournal', 'Create Journal Entry', Icons.add),
        _leaf('journal', 'Opening Journal', Icons.menu_book_outlined),
      ]),
    ]),
    NavNode(id: 'bankingHub', label: 'Banking', icon: Icons.sync_alt, children: [
      NavNode(id: 'bankingHub:cash', label: 'Cash Movements', children: [
        _leaf('deposit', 'Create Deposit', Icons.south),
        _leaf('withdrawal', 'Create Withdrawal', Icons.north),
      ]),
      NavNode(id: 'bankingHub:transfers', label: 'Transfers', children: [
        _leaf('localTransfer', 'Local Transfer', Icons.attach_file),
        _leaf('extTransfer', 'External Transfer', Icons.explore_outlined),
      ]),
    ]),
    NavNode(id: 'reportsHub', label: 'Reports', icon: Icons.description_outlined, children: [
      NavNode(id: 'reportsHub:fin', label: 'Financial', children: [
        _leaf('trialBalance', 'Trial Balance', Icons.menu_book_outlined, keys: ['g', 'b']),
        _leaf('incomeStmt', 'Income Statement', Icons.description_outlined),
        _leaf('balanceSheet', 'Balance Sheet', Icons.description_outlined),
      ]),
      NavNode(id: 'reportsHub:sec', label: 'Security', children: [
        _leaf('auditLog', 'Audit Log', Icons.lock_outline, badge: const NavBadge('12', tone: NavBadgeTone.muted)),
      ]),
    ]),
  ]),
  NavSection(title: 'Operations', items: [
    NavNode(id: 'storesHub', label: 'Inventory & Stores', icon: Icons.storefront_outlined, children: [
      NavNode(id: 'storesHub:catalog', label: 'Catalog', children: [
        _leaf('products', 'Products', Icons.qr_code_scanner, keys: ['g', 'p']),
        _leaf('categories', 'Categories', Icons.work_outline),
        _leaf('priceLists', 'Price Lists', Icons.menu_book_outlined),
      ]),
      NavNode(id: 'storesHub:stock', label: 'Stock Operations', children: [
        _leaf('receive', 'Receive Inventory', Icons.south),
        _leaf('transferList', 'Stock Transfers', Icons.attach_file),
        _leaf('stockTake', 'Stock Take', Icons.check, badge: const NavBadge('New', tone: NavBadgeTone.success)),
      ]),
    ]),
    NavNode(id: 'salesHub', label: 'Sales', icon: Icons.person_outline, children: [
      NavNode(id: 'salesHub:customers', label: 'Customers', children: [
        _leaf('customers', 'Customers', Icons.person_outline),
        _leaf('createCustomer', 'Add Customer', Icons.add),
      ]),
    ]),
    NavNode(id: 'procurementHub', label: 'Procurement', icon: Icons.work_outline, children: [
      NavNode(id: 'procurementHub:suppliers', label: 'Suppliers', children: [
        _leaf('suppliers', 'Suppliers', Icons.work_outline),
        _leaf('createSupplier', 'Add Supplier', Icons.add),
      ]),
    ]),
  ]),
  NavSection(title: 'Administration', items: [
    NavNode(id: 'configHub', label: 'Configuration', icon: Icons.explore_outlined, children: [
      NavNode(id: 'configHub:cur', label: 'Currencies', children: [
        _leaf('currencies', 'Currencies', Icons.work_outline),
        _leaf('exchangeRates', 'Exchange Rates', Icons.explore_outlined, badge: const NavBadge('Live', tone: NavBadgeTone.success)),
      ]),
    ]),
    NavNode(id: 'adminHub', label: 'Team & Access', icon: Icons.person_outline, children: [
      NavNode(id: 'adminHub:users', label: 'Users', children: [
        _leaf('users', 'Users', Icons.person_outline),
        _leaf('roles', 'Roles & Permissions', Icons.settings_outlined),
      ]),
    ]),
    _leaf('settingsHub', 'Settings', Icons.settings_outlined),
  ]),
];

// ════════════════════════════════════════════════════════════
// DEMO
// ════════════════════════════════════════════════════════════
class NavigationSidebarDemo extends StatefulWidget {
  const NavigationSidebarDemo({super.key});
  @override
  State<NavigationSidebarDemo> createState() => _NavigationSidebarDemoState();
}

enum _Device { fill, desktop, tablet, mobile }

const _devices = <(_Device, String, double?)>[
  (_Device.fill, 'Fill', null),
  (_Device.desktop, 'Desktop · 1280', 1280),
  (_Device.tablet, 'Tablet · 900', 900),
  (_Device.mobile, 'Mobile · 390', 390),
];

class _NavigationSidebarDemoState extends State<NavigationSidebarDemo> {
  bool _light = false;
  TextDirection _dir = TextDirection.ltr;
  _Device _device = _Device.fill;

  late final NavigationSidebarController<String> _controller = NavigationSidebarController<String>(
    sections: kNavSections,
    active: 'accounts',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ext = _light ? NavigationSidebarThemeData.light : NavigationSidebarThemeData.dark;
    return Theme(
      data: ThemeData(
        brightness: _light ? Brightness.light : Brightness.dark,
        useMaterial3: true,
        fontFamily: NavigationSidebarThemeData.bodyFont,
        scaffoldBackgroundColor: ext.bg,
        extensions: [ext],
      ),
      child: Builder(builder: (context) {
        final t = NavigationSidebarThemeData.of(context);
        final dev = _devices.firstWhere((d) => d.$1 == _device);
        return Directionality(
          textDirection: _dir,
          child: Scaffold(
            backgroundColor: t.bg,
            body: Column(
              children: [
                _workbenchBar(t),
                Expanded(
                  child: Container(
                    color: t.bg,
                    padding: EdgeInsets.all(dev.$3 != null ? 20.0 : 0.0),
                    alignment: Alignment.center,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(dev.$3 != null ? 14.0 : 0.0),
                      child: Container(
                        width: dev.$3,
                        decoration: BoxDecoration(
                          color: t.bg,
                          border: dev.$3 != null ? Border.all(color: t.borderStrong) : null,
                          borderRadius: BorderRadius.circular(dev.$3 != null ? 14.0 : 0.0),
                          boxShadow: dev.$3 != null ? NavigationSidebarThemeData.popShadow : null,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: LayoutBuilder(builder: (context, c) {
                          return _NavShell(controller: _controller, width: c.maxWidth);
                        }),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ── workbench strip (Light/Dark · LTR/RTL · device sim) ──
  Widget _workbenchBar(NavigationSidebarThemeData t) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Row(
        children: [
          Container(width: 7, height: 7, decoration: const BoxDecoration(color: NavigationSidebarThemeData.accent, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Text(
            'NavigationSidebar · MVC',
            style: TextStyle(fontFamily: NavigationSidebarThemeData.monoFont, fontSize: 11, letterSpacing: 0.4, color: t.fg3),
          ),
          const Spacer(),
          _seg<bool>(t, const [(false, 'Dark'), (true, 'Light')], _light, (v) => setState(() => _light = v)),
          const SizedBox(width: 8),
          _seg<TextDirection>(t, const [(TextDirection.ltr, 'LTR'), (TextDirection.rtl, 'RTL')], _dir, (v) => setState(() => _dir = v)),
          const SizedBox(width: 8),
          _seg<_Device>(t, [for (final d in _devices) (d.$1, d.$2)], _device, (v) => setState(() => _device = v)),
        ],
      ),
    );
  }

  Widget _seg<V>(NavigationSidebarThemeData t, List<(V, String)> options, V value, ValueChanged<V> onPick) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: t.inputBg,
        borderRadius: BorderRadius.circular(NavigationSidebarThemeData.radiusSm),
        border: Border.all(color: t.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final o in options)
            GestureDetector(
              onTap: () => onPick(o.$1),
              child: AnimatedContainer(
                duration: NavigationSidebarThemeData.durFast,
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: o.$1 == value ? t.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: o.$1 == value ? const [BoxShadow(color: Color(0x40000000), blurRadius: 2, offset: Offset(0, 1))] : null,
                ),
                child: Text(
                  o.$2,
                  style: TextStyle(
                    fontFamily: NavigationSidebarThemeData.monoFont,
                    fontSize: 10,
                    letterSpacing: 0.4,
                    color: o.$1 == value ? t.fg1 : t.fg3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// NAV SHELL — responsive composition of AppBar + sidebar + page.
// ════════════════════════════════════════════════════════════
class _NavShell extends StatelessWidget {
  final NavigationSidebarController<String> controller;
  final double width;
  const _NavShell({required this.controller, required this.width});

  static const _bp = NavSidebarBreakpoints();

  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    final mode = _bp.modeFor(width);

    final header = (BuildContext ctx, bool collapsed) => _SidebarBrand(collapsed: collapsed);
    final footer = (BuildContext ctx, bool collapsed) => _SidebarFooter(collapsed: collapsed);

    final appBar = _AppBar(
      mode: mode,
      onMenu: () => mode == NavSidebarMode.drawer ? controller.toggleDrawer() : controller.toggleCollapsed(),
    );

    if (mode == NavSidebarMode.drawer) {
      return Container(
        color: t.bg,
        child: Column(children: [
          appBar,
          Expanded(
            child: Stack(children: [
              Positioned.fill(child: _FauxPage(controller: controller)),
              Positioned.fill(
                child: NavigationSidebar<String>(
                  controller: controller,
                  mode: NavSidebarMode.drawer,
                  header: header,
                  footer: footer,
                ),
              ),
            ]),
          ),
        ]),
      );
    }

    final sidebarMode = mode == NavSidebarMode.rail
        ? NavSidebarMode.rail
        : (controller.collapsed ? NavSidebarMode.rail : NavSidebarMode.expanded);

    return Container(
      color: t.bg,
      child: Column(children: [
        appBar,
        Expanded(
          child: Row(children: [
            NavigationSidebar<String>(
              controller: controller,
              mode: sidebarMode,
              header: header,
              footer: footer,
            ),
            Expanded(child: _FauxPage(controller: controller)),
          ]),
        ),
      ]),
    );
  }
}

// ── brand mark (sidebar header slot) ──
class _SidebarBrand extends StatelessWidget {
  final bool collapsed;
  const _SidebarBrand({required this.collapsed});
  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    final mark = Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: NavigationSidebarThemeData.accent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.bolt, size: 18, color: Colors.white),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
      child: Row(
        mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          mark,
          if (!collapsed) ...[
            const SizedBox(width: 10),
            Text('GeniusLink',
                style: TextStyle(fontFamily: NavigationSidebarThemeData.displayFont, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.2, color: t.fg1)),
          ],
        ],
      ),
    );
  }
}

// ── footer slot: theme/help (decorative) ──
class _SidebarFooter extends StatelessWidget {
  final bool collapsed;
  const _SidebarFooter({required this.collapsed});
  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    if (collapsed) {
      return Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: t.border),
          borderRadius: BorderRadius.circular(NavigationSidebarThemeData.radiusLg),
        ),
        child: Icon(Icons.help_outline, size: 20, color: t.fg3),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.accentFill(0.08),
        borderRadius: BorderRadius.circular(NavigationSidebarThemeData.radiusLg),
        border: Border.all(color: NavigationSidebarThemeData.accent.withOpacity(0.25)),
      ),
      child: Row(children: [
        Icon(Icons.help_outline, size: 18, color: NavigationSidebarThemeData.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Need a hand?', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: t.fg1)),
            Text('Docs & shortcuts', style: TextStyle(fontSize: 11, color: t.fg3)),
          ]),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════
// APP BAR — brand · search · workspace · account.
// ════════════════════════════════════════════════════════════
class _AppBar extends StatelessWidget {
  final NavSidebarMode mode;
  final VoidCallback onMenu;
  const _AppBar({required this.mode, required this.onMenu});

  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    final mobile = mode == NavSidebarMode.drawer;

    final iconBtn = (IconData icon) => GestureDetector(
          onTap: onMenu,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.inputBg,
              borderRadius: BorderRadius.circular(NavigationSidebarThemeData.radiusLg),
              border: Border.all(color: t.border),
            ),
            child: Icon(icon, size: 18, color: t.fg2),
          ),
        );

    return Container(
      height: mobile ? 56.0 : 62.0,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Row(children: [
        iconBtn(Icons.menu),
        const SizedBox(width: 14),
        if (!mobile)
          Text('GeniusLink',
              style: TextStyle(fontFamily: NavigationSidebarThemeData.displayFont, fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.3, color: t.fg1)),
        const Spacer(),
        if (!mobile) Expanded(flex: 4, child: _searchField(t)),
        if (!mobile) const Spacer(),
        const SizedBox(width: 12),
        _workspaceChip(t, compact: mobile),
        const SizedBox(width: 10),
        _avatar(t),
      ]),
    );
  }

  Widget _searchField(NavigationSidebarThemeData t) {
    return Container(
      height: 40,
      constraints: const BoxConstraints(maxWidth: 480),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: t.inputBg,
        borderRadius: BorderRadius.circular(NavigationSidebarThemeData.radiusLg),
        border: Border.all(color: t.border),
      ),
      child: Row(children: [
        Icon(Icons.search, size: 16, color: t.fg3),
        const SizedBox(width: 9),
        Expanded(child: Text('Search tabs & actions…', style: TextStyle(fontSize: 13, color: t.fg3))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(border: Border.all(color: t.border), borderRadius: BorderRadius.circular(4)),
          child: Text('/', style: TextStyle(fontFamily: NavigationSidebarThemeData.monoFont, fontSize: 11, color: t.fg4)),
        ),
      ]),
    );
  }

  Widget _workspaceChip(NavigationSidebarThemeData t, {required bool compact}) {
    return Container(
      height: 40,
      padding: EdgeInsets.symmetric(horizontal: compact ? 0.0 : 9.0),
      width: compact ? 40.0 : null,
      decoration: BoxDecoration(
        color: t.inputBg,
        borderRadius: BorderRadius.circular(NavigationSidebarThemeData.radiusLg),
        border: Border.all(color: t.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: NavigationSidebarThemeData.accent.withOpacity(0.18), borderRadius: BorderRadius.circular(7)),
          child: const Icon(Icons.apartment, size: 15, color: NavigationSidebarThemeData.accent),
        ),
        if (!compact) ...[
          const SizedBox(width: 9),
          Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Al-Rashid Trading', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: t.fg1)),
            Text('TENANT 9', style: TextStyle(fontFamily: NavigationSidebarThemeData.monoFont, fontSize: 9, color: t.fg3, letterSpacing: 0.4)),
          ]),
          const SizedBox(width: 8),
          Icon(Icons.keyboard_arrow_down, size: 14, color: t.fg3),
        ],
      ]),
    );
  }

  Widget _avatar(NavigationSidebarThemeData t) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: NavigationSidebarThemeData.accent.withOpacity(0.16),
        shape: BoxShape.circle,
        border: Border.all(color: NavigationSidebarThemeData.accent.withOpacity(0.35)),
      ),
      child: const Text('SM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: NavigationSidebarThemeData.accent)),
    );
  }
}

// ════════════════════════════════════════════════════════════
// FAUX PAGE — a muted backdrop with a live breadcrumb + skeleton.
// ════════════════════════════════════════════════════════════
class _FauxPage extends StatelessWidget {
  final NavigationSidebarController<String> controller;
  const _FauxPage({required this.controller});

  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    final activeId = controller.active;
    final node = activeId == null ? null : controller.node(activeId);
    final ancestors = activeId == null
        ? const <String>[]
        : NavOps.ancestorsOf<String>(controller.sections, activeId)
            .map((id) => controller.node(id)?.label ?? id)
            .toList();
    final crumb = [...ancestors, if (node != null) node.label].join('  ·  ');

    final muted = BoxDecoration(
      color: t.surface,
      borderRadius: BorderRadius.circular(NavigationSidebarThemeData.radiusMd),
      border: Border.all(color: t.border),
    );

    return Container(
      color: t.bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(40, 32, 40, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            (crumb.isEmpty ? 'Workspace' : crumb).toUpperCase(),
            style: TextStyle(fontFamily: NavigationSidebarThemeData.monoFont, fontSize: 11, letterSpacing: 1.6, color: t.fg4),
          ),
          const SizedBox(height: 14),
          Text(
            node?.label ?? 'Select a destination',
            style: TextStyle(fontFamily: NavigationSidebarThemeData.displayFont, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: t.fg1),
          ),
          const SizedBox(height: 28),
          LayoutBuilder(builder: (context, c) {
            final cols = c.maxWidth > 720 ? 3 : (c.maxWidth > 440 ? 2 : 1);
            final w = (c.maxWidth - (cols - 1) * 20) / cols;
            return Wrap(spacing: 20, runSpacing: 20, children: [
              for (int i = 0; i < 3; i++)
                Opacity(opacity: 0.6, child: Container(width: w, height: 120, decoration: muted)),
            ]);
          }),
          const SizedBox(height: 24),
          Opacity(opacity: 0.6, child: Container(height: 320, decoration: muted)),
        ]),
      ),
    );
  }
}
