// ============================================================
// NavigationSidebar — example screen.
// ------------------------------------------------------------
// A faithful Flutter reproduction of the GeniusLink web
// "Navigation Sidebar Workbench" (design_system/components-navigation-sidebar.html):
//
//   NavShell        — orchestrates the whole chrome
//     ├ AppBar      — logo · centered search · workspace dropdown · user menu
//     ├ NavigationSidebar — the component under test (rail / drawer / tree)
//     │   footer    — ThemeToggle + "Need help?" card
//     └ SearchDialog — command palette opened from the search field
//
// A thin workbench strip on top flips LTR/RTL and simulates device widths
// (Fill · Desktop · Tablet · Mobile) so the expanded → rail → drawer breakpoints
// are demoable live. The Dark/Light switch lives in the sidebar footer, exactly
// like the reference.
//
//   File: example/lib/navigation_sidebar_demo.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:geniuslink_design_system/geniuslink_navigation_sidebar.dart';

// ── icon aliases (web icon name → Material glyph) ──
const _briefcase = Icons.work_outline;
const _scanner = Icons.qr_code_scanner;
const _ledger = Icons.menu_book_outlined;
const _switch2 = Icons.sync_alt;
const _doc = Icons.description_outlined;
const _store = Icons.storefront_outlined;
const _user = Icons.person_outline;
const _compass = Icons.explore_outlined;
const _settings = Icons.settings_outlined;
const _plus = Icons.add;
const _download = Icons.south;
const _upload = Icons.north;
const _paperclip = Icons.attach_file;
const _check = Icons.check;
const _lock = Icons.lock_outline;

NavNode<String> _leaf(String id, String label, IconData icon, {NavBadge? badge, List<String>? keys}) =>
    NavNode<String>(id: id, label: label, icon: icon, value: id, badge: badge, shortcut: keys);

NavNode<String> _group(String id, String label, List<NavNode<String>> items) =>
    NavNode<String>(id: id, label: label, children: items);

// Full mirror of the web HUB_TABS / NAV_SECTIONS tree.
final List<NavSection<String>> kNavSections = [
  NavSection(title: 'Overview', items: [
    _leaf('dashboard', 'Dashboard', _briefcase, keys: ['g', 'd']),
    _leaf('invDashboard', 'Inventory Dashboard', _scanner, keys: ['g', 'i']),
  ]),
  NavSection(title: 'Finance', items: [
    NavNode(id: 'accountsHub', label: 'Accounts', icon: _ledger, children: [
      _group('accountsHub:coa', 'Chart of Accounts', [
        _leaf('accounts', 'Chart of Accounts', _ledger),
        _leaf('accountTree', 'Account Tree', _briefcase, keys: ['g', 't']),
        _leaf('createAccount', 'Create Account', _plus),
      ]),
      _group('accountsHub:groups', 'Account Groups', [
        _leaf('group', 'Create Account Group', _briefcase),
      ]),
    ]),
    NavNode(id: 'ledgerHub', label: 'Ledger', icon: _ledger, children: [
      _group('ledgerHub:je', 'Journal Entries', [
        _leaf('journals', 'Journal Entries', _ledger, badge: const NavBadge('3'), keys: ['g', 'j']),
        _leaf('createJournal', 'Create Journal Entry', _plus),
        _leaf('journal', 'Opening Journal', _ledger),
      ]),
    ]),
    NavNode(id: 'bankingHub', label: 'Banking', icon: _switch2, children: [
      _group('bankingHub:cash', 'Cash Movements', [
        _leaf('deposit', 'Create Deposit', _download),
        _leaf('withdrawal', 'Create Withdrawal', _upload),
      ]),
      _group('bankingHub:transfers', 'Transfers', [
        _leaf('localTransfer', 'Local Transfer', _paperclip),
        _leaf('extTransfer', 'External Transfer', _compass),
      ]),
    ]),
    NavNode(id: 'reportsHub', label: 'Reports', icon: _doc, children: [
      _group('reportsHub:fin', 'Financial', [
        _leaf('trialBalance', 'Trial Balance', _ledger, keys: ['g', 'b']),
        _leaf('incomeStmt', 'Income Statement', _doc),
        _leaf('balanceSheet', 'Balance Sheet', _doc),
      ]),
      _group('reportsHub:inv', 'Inventory', [
        _leaf('invValuation', 'Inventory Valuation', _scanner),
      ]),
      _group('reportsHub:sec', 'Security', [
        _leaf('auditLog', 'Audit Log', _lock, badge: const NavBadge('12', tone: NavBadgeTone.muted)),
      ]),
    ]),
  ]),
  NavSection(title: 'Operations', items: [
    NavNode(id: 'storesHub', label: 'Inventory & Stores', icon: _store, children: [
      _group('storesHub:catalog', 'Catalog', [
        _leaf('products', 'Products', _scanner, keys: ['g', 'p']),
        _leaf('categories', 'Categories', _briefcase),
        _leaf('uom', 'Units of Measure', _compass),
        _leaf('priceLists', 'Price Lists', _ledger),
      ]),
      _group('storesHub:wh', 'Warehouses', [
        _leaf('stores', 'Warehouses', _store),
        _leaf('createStore', 'Create Warehouse', _plus),
      ]),
      _group('storesHub:stock', 'Stock Operations', [
        _leaf('inventory', 'Issue Inventory', _scanner),
        _leaf('receive', 'Receive Inventory', _download),
        _leaf('transferList', 'Stock Transfers', _paperclip),
        _leaf('adjust', 'Stock Adjustment', _settings),
        _leaf('stockTake', 'Stock Take', _check, badge: const NavBadge('New', tone: NavBadgeTone.success)),
        _leaf('barcodePrint', 'Barcode Print', _scanner),
      ]),
    ]),
    NavNode(id: 'salesHub', label: 'Sales', icon: _user, children: [
      _group('salesHub:customers', 'Customers', [
        _leaf('customers', 'Customers', _user),
        _leaf('createCustomer', 'Add Customer', _plus),
      ]),
    ]),
    NavNode(id: 'procurementHub', label: 'Procurement', icon: _briefcase, children: [
      _group('procurementHub:suppliers', 'Suppliers', [
        _leaf('suppliers', 'Suppliers', _briefcase),
        _leaf('createSupplier', 'Add Supplier', _plus),
      ]),
    ]),
  ]),
  NavSection(title: 'Administration', items: [
    NavNode(id: 'configHub', label: 'Configuration', icon: _compass, children: [
      _group('configHub:cur', 'Currencies', [
        _leaf('currencies', 'Currencies', _briefcase),
        _leaf('createCurrency', 'Add Currency', _plus),
        _leaf('exchangeRates', 'Exchange Rates', _compass, badge: const NavBadge('Live', tone: NavBadgeTone.success)),
      ]),
      _group('configHub:cal', 'Calendar', [
        _leaf('fiscalYear', 'Fiscal Year', _ledger),
      ]),
    ]),
    NavNode(id: 'adminHub', label: 'Team & Access', icon: _user, children: [
      _group('adminHub:users', 'Users', [
        _leaf('users', 'Users', _user),
        _leaf('createUser', 'Invite User', _plus),
      ]),
      _group('adminHub:access', 'Access', [
        _leaf('roles', 'Roles & Permissions', _settings),
      ]),
    ]),
    NavNode(id: 'settingsHub', label: 'Settings', icon: _settings, children: [
      _group('settingsHub:ws', 'Workspace', [
        _leaf('settingsGeneral', 'General', _settings),
        _leaf('settingsPlatform', 'Platform', _compass),
        _leaf('settingsTeam', 'Team', _user),
      ]),
    ]),
  ]),
];

// ── tenants + user (mirror the web mock) ──
const _tenants = <(int, String, String)>[
  (9, 'Al-Rashid Trading Co.', 'Enterprise'),
  (14, 'Najd Holdings', 'Business'),
  (22, 'Coastal Logistics', 'Business'),
];

// ════════════════════════════════════════════════════════════
// DEMO  (workbench)
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
  bool _searchOpen = false;
  int _tenant = 9;

  static const _bp = NavSidebarBreakpoints();
  NavSidebarMode? _prevMode;

  late final NavigationSidebarController<String> _controller = NavigationSidebarController<String>(
    sections: kNavSections,
    active: 'accounts',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setTheme(bool light) => setState(() => _light = light);

  // Mirror the web NavShell: auto-collapse to a rail on tablet, expand on
  // desktop, close the drawer on mobile — but only when the breakpoint changes,
  // so an explicit user toggle within a breakpoint is preserved.
  void _syncMode(NavSidebarMode mode) {
    if (mode == _prevMode) return;
    _prevMode = mode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (mode == NavSidebarMode.expanded) {
        _controller.collapsed = false;
      } else if (mode == NavSidebarMode.rail) {
        _controller.collapsed = true;
      } else {
        _controller.closeDrawer();
      }
    });
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
                          _syncMode(_bp.modeFor(c.maxWidth));
                          return Stack(
                            children: [
                              _NavShell(
                                controller: _controller,
                                width: c.maxWidth,
                                light: _light,
                                setTheme: _setTheme,
                                tenant: _tenant,
                                onTenant: (id) => setState(() => _tenant = id),
                                onOpenSearch: () => setState(() => _searchOpen = true),
                              ),
                              if (_searchOpen)
                                _SearchDialog(
                                  controller: _controller,
                                  onClose: () => setState(() => _searchOpen = false),
                                  onPick: (id) {
                                    _controller.navigate(id);
                                    setState(() => _searchOpen = false);
                                  },
                                ),
                            ],
                          );
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

  // ── workbench strip (LTR/RTL · device sim) — theme lives in the sidebar ──
  Widget _workbenchBar(NavigationSidebarThemeData t) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Row(
        children: [
          Container(width: 7, height: 7, decoration: const BoxDecoration(color: NavigationSidebarThemeData.accent, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'NavigationSidebar — isolated workbench · MVC',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: NavigationSidebarThemeData.monoFont, fontSize: 11, letterSpacing: 0.4, color: t.fg3),
            ),
          ),
          const Spacer(),
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
        borderRadius: BorderRadius.circular(NavigationSidebarThemeData.radiusMd),
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
// NAV SHELL — responsive AppBar + sidebar + page.
// ════════════════════════════════════════════════════════════
class _NavShell extends StatelessWidget {
  final NavigationSidebarController<String> controller;
  final double width;
  final bool light;
  final ValueChanged<bool> setTheme;
  final int tenant;
  final ValueChanged<int> onTenant;
  final VoidCallback onOpenSearch;
  const _NavShell({
    required this.controller,
    required this.width,
    required this.light,
    required this.setTheme,
    required this.tenant,
    required this.onTenant,
    required this.onOpenSearch,
  });

  static const _bp = NavSidebarBreakpoints();

  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    final mode = _bp.modeFor(width);

    Widget footer(BuildContext ctx, bool collapsed) =>
        _SidebarFooter(collapsed: collapsed, light: light, setTheme: setTheme);

    final appBar = _AppBar(
      mode: mode,
      tenant: tenant,
      onTenant: onTenant,
      onOpenSearch: onOpenSearch,
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
                  footer: footer,
                ),
              ),
            ]),
          ),
        ]),
      );
    }

    final sidebarMode = controller.collapsed ? NavSidebarMode.rail : NavSidebarMode.expanded;

    return Container(
      color: t.bg,
      child: Column(children: [
        appBar,
        Expanded(
          child: Row(children: [
            NavigationSidebar<String>(
              controller: controller,
              mode: sidebarMode,
              footer: footer,
            ),
            Expanded(child: _FauxPage(controller: controller)),
          ]),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════
// LOGO — cube mark + optional wordmark.
// ════════════════════════════════════════════════════════════
class _Logo extends StatelessWidget {
  final double size;
  final bool wordmark;
  const _Logo({this.size = 24, this.wordmark = true});

  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/logo-mark.png', width: size, height: size, fit: BoxFit.contain),
        if (wordmark) ...[
          const SizedBox(width: 10),
          Text(
            'GeniusLink',
            style: TextStyle(
              fontFamily: NavigationSidebarThemeData.displayFont,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.66,
              letterSpacing: -0.2,
              color: t.fg1,
            ),
          ),
        ],
      ],
    );
  }
}

// A 3-bar hamburger (matches the web bar+box-shadow glyph).
class _Hamburger extends StatelessWidget {
  final Color color;
  const _Hamburger({required this.color});
  @override
  Widget build(BuildContext context) {
    Widget bar() => Container(width: 18, height: 2, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [bar(), const SizedBox(height: 4), bar(), const SizedBox(height: 4), bar()],
    );
  }
}

// ════════════════════════════════════════════════════════════
// APP BAR — logo · search · workspace · user.
// ════════════════════════════════════════════════════════════
class _AppBar extends StatelessWidget {
  final NavSidebarMode mode;
  final int tenant;
  final ValueChanged<int> onTenant;
  final VoidCallback onMenu;
  final VoidCallback onOpenSearch;
  const _AppBar({required this.mode, required this.tenant, required this.onTenant, required this.onMenu, required this.onOpenSearch});

  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    final mobile = mode == NavSidebarMode.drawer;
    final tight = mode != NavSidebarMode.expanded; // compact clusters on tablet

    Widget iconBtn({required Widget child, VoidCallback? onTap}) => GestureDetector(
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.inputBg,
              borderRadius: BorderRadius.circular(NavigationSidebarThemeData.radiusLg),
              border: Border.all(color: t.border),
            ),
            child: child,
          ),
        );

    if (mobile) {
      return Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: t.surface,
          border: Border(bottom: BorderSide(color: t.border)),
        ),
        child: Row(children: [
          iconBtn(onTap: onMenu, child: _Hamburger(color: t.fg1)),
          const SizedBox(width: 10),
          const _Logo(size: 22, wordmark: false),
          const Spacer(),
          iconBtn(onTap: onOpenSearch, child: Icon(Icons.search, size: 16, color: t.fg3)),
          const SizedBox(width: 10),
          _WorkspaceMenu(tenant: tenant, onTenant: onTenant, compact: true),
          const SizedBox(width: 8),
          const _UserMenu(compact: true),
        ]),
      );
    }

    // Desktop / tablet: 3-column layout keeps the search optically centered.
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Row(children: [
        Expanded(
          child: Row(children: [
            iconBtn(onTap: onMenu, child: _Hamburger(color: t.fg1)),
            const SizedBox(width: 14),
            Flexible(child: _Logo(size: 24, wordmark: !tight)),
          ]),
        ),
        _searchField(t, tight),
        Expanded(
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            _WorkspaceMenu(tenant: tenant, onTenant: onTenant, compact: tight),
            const SizedBox(width: 12),
            _UserMenu(compact: tight),
          ]),
        ),
      ]),
    );
  }

  Widget _searchField(NavigationSidebarThemeData t, bool tight) {
    return GestureDetector(
      onTap: onOpenSearch,
      child: Container(
        height: 40,
        width: tight ? 340 : 460,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: t.inputBg,
          borderRadius: BorderRadius.circular(NavigationSidebarThemeData.radiusLg),
          border: Border.all(color: t.border),
        ),
        child: Row(children: [
          Icon(Icons.search, size: 15, color: t.fg3),
          const SizedBox(width: 9),
          Expanded(child: Text('Search tabs & actions…', style: TextStyle(fontSize: 13, color: t.fg3))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(border: Border.all(color: t.border), borderRadius: BorderRadius.circular(4)),
            child: Text('/', style: TextStyle(fontFamily: NavigationSidebarThemeData.monoFont, fontSize: 10, color: t.fg4)),
          ),
        ]),
      ),
    );
  }
}

// ── workspace dropdown ──
class _WorkspaceMenu extends StatelessWidget {
  final int tenant;
  final ValueChanged<int> onTenant;
  final bool compact;
  const _WorkspaceMenu({required this.tenant, required this.onTenant, required this.compact});

  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    final cur = _tenants.firstWhere((e) => e.$1 == tenant, orElse: () => _tenants.first);
    Widget icon(double s) => Container(
          width: s,
          height: s,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: NavigationSidebarThemeData.accent.withOpacity(0.18), borderRadius: BorderRadius.circular(7)),
          child: Icon(Icons.apartment, size: s * 0.56, color: NavigationSidebarThemeData.accent),
        );

    return _HeaderMenu(
      width: 250,
      align: _MenuAlign.start,
      button: (open) => Container(
        height: 40,
        width: compact ? 40 : null,
        padding: EdgeInsets.symmetric(horizontal: compact ? 0.0 : 9.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: open ? t.hover : t.inputBg,
          borderRadius: BorderRadius.circular(NavigationSidebarThemeData.radiusLg),
          border: Border.all(color: open ? NavigationSidebarThemeData.accent : t.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          icon(26),
          if (!compact) ...[
            const SizedBox(width: 9),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(cur.$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: t.fg1)),
                Text('TENANT ${cur.$1}', style: TextStyle(fontFamily: NavigationSidebarThemeData.monoFont, fontSize: 9.5, color: t.fg3, letterSpacing: 0.4)),
              ]),
            ),
            const SizedBox(width: 8),
            Icon(Icons.keyboard_arrow_down, size: 14, color: t.fg3),
          ],
        ]),
      ),
      menu: (close) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
          child: Text('SWITCH WORKSPACE', style: TextStyle(fontFamily: NavigationSidebarThemeData.monoFont, fontSize: 10, letterSpacing: 1.2, color: t.fg4)),
        ),
        for (final e in _tenants)
          _MenuRow(
            active: e.$1 == tenant,
            onTap: () {
              onTenant(e.$1);
              close();
            },
            child: Row(children: [
              icon(28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(e.$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: e.$1 == tenant ? NavigationSidebarThemeData.accent : t.fg1)),
                  Text('${e.$3} · Tenant ${e.$1}', style: TextStyle(fontSize: 10.5, fontFamily: NavigationSidebarThemeData.monoFont, color: t.fg3)),
                ]),
              ),
              if (e.$1 == tenant) const Icon(Icons.check, size: 15, color: NavigationSidebarThemeData.accent),
            ]),
          ),
      ]),
    );
  }
}

// ── user dropdown ──
class _UserMenu extends StatelessWidget {
  final bool compact;
  const _UserMenu({required this.compact});

  Widget _avatar(NavigationSidebarThemeData t, double s) => Container(
        width: s,
        height: s,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: NavigationSidebarThemeData.accent.withOpacity(0.16),
          shape: BoxShape.circle,
          border: Border.all(color: NavigationSidebarThemeData.accent.withOpacity(0.35)),
        ),
        child: Text('SM', style: TextStyle(fontSize: s * 0.36, fontWeight: FontWeight.w700, color: NavigationSidebarThemeData.accent)),
      );

  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    return _HeaderMenu(
      width: 240,
      align: _MenuAlign.end,
      button: (open) => Container(
        height: 40,
        padding: EdgeInsets.symmetric(horizontal: compact ? 0.0 : 6.0),
        decoration: BoxDecoration(
          color: open ? t.hover : Colors.transparent,
          borderRadius: BorderRadius.circular(NavigationSidebarThemeData.radiusLg),
          border: Border.all(color: open ? t.borderStrong : Colors.transparent),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _avatar(t, 32),
          if (!compact) ...[
            const SizedBox(width: 9),
            Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('Sara Mansour', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: t.fg1)),
              Text('Administrator', style: TextStyle(fontFamily: NavigationSidebarThemeData.monoFont, fontSize: 10, color: t.fg3, letterSpacing: 0.4)),
            ]),
            const SizedBox(width: 8),
            Icon(Icons.keyboard_arrow_down, size: 14, color: t.fg3),
          ],
        ]),
      ),
      menu: (close) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
          child: Row(children: [
            _avatar(t, 38),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text('Sara Mansour', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.fg1)),
                Text('sara.mansour@alrashid.co', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontFamily: NavigationSidebarThemeData.monoFont, color: t.fg3)),
              ]),
            ),
          ]),
        ),
        Container(height: 1, color: t.border),
        const SizedBox(height: 6),
        _MenuRow(onTap: close, child: _menuLabel(t, Icons.person_outline, 'Profile')),
        _MenuRow(onTap: close, child: _menuLabel(t, Icons.settings_outlined, 'Settings')),
        Container(height: 1, color: t.border, margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4)),
        _MenuRow(onTap: close, child: _menuLabel(t, Icons.logout, 'Sign out', danger: true)),
      ]),
    );
  }

  Widget _menuLabel(NavigationSidebarThemeData t, IconData icon, String label, {bool danger = false}) {
    final c = danger ? NavigationSidebarThemeData.danger : t.fg1;
    return Row(children: [
      Icon(icon, size: 15, color: danger ? NavigationSidebarThemeData.danger : t.fg3),
      const SizedBox(width: 10),
      Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c)),
    ]);
  }
}

// ── reusable header dropdown (overlay popover + click-outside) ──
enum _MenuAlign { start, end }

class _HeaderMenu extends StatefulWidget {
  final Widget Function(bool open) button;
  final Widget Function(VoidCallback close) menu;
  final double width;
  final _MenuAlign align;
  const _HeaderMenu({required this.button, required this.menu, required this.width, required this.align});

  @override
  State<_HeaderMenu> createState() => _HeaderMenuState();
}

class _HeaderMenuState extends State<_HeaderMenu> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;

  bool get _open => _entry != null;

  void _close() {
    _entry?.remove();
    _entry = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _entry?.remove();
    _entry = null;
    super.dispose();
  }

  void _toggle() {
    if (_open) {
      _close();
      return;
    }
    final t = NavigationSidebarThemeData.of(context);
    final themeData = Theme.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // In RTL, "start" anchors flip sides.
    final startSide = widget.align == _MenuAlign.start;
    final target = startSide
        ? (rtl ? Alignment.bottomRight : Alignment.bottomLeft)
        : (rtl ? Alignment.bottomLeft : Alignment.bottomRight);
    final follower = startSide
        ? (rtl ? Alignment.topRight : Alignment.topLeft)
        : (rtl ? Alignment.topLeft : Alignment.topRight);

    _entry = OverlayEntry(
      builder: (ctx) => Stack(children: [
        Positioned.fill(
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _close, child: const SizedBox.shrink()),
        ),
        CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          targetAnchor: target,
          followerAnchor: follower,
          offset: const Offset(0, 8),
          child: Theme(
            data: themeData,
            child: Directionality(
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: widget.width,
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: BorderRadius.circular(NavigationSidebarThemeData.radiusLg),
                    border: Border.all(color: t.borderStrong),
                    boxShadow: NavigationSidebarThemeData.popShadow,
                  ),
                  padding: const EdgeInsets.all(6),
                  child: widget.menu(_close),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
    Overlay.of(context).insert(_entry!);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggle,
        child: MouseRegion(cursor: SystemMouseCursors.click, child: widget.button(_open)),
      ),
    );
  }
}

class _MenuRow extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool active;
  const _MenuRow({required this.child, required this.onTap, this.active = false});
  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    final bg = widget.active ? t.accentFill(0.10) : (_hover ? t.hover : Colors.transparent);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7)),
          child: widget.child,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// SIDEBAR FOOTER — ThemeToggle + "Need help?" card.
// ════════════════════════════════════════════════════════════
class _SidebarFooter extends StatelessWidget {
  final bool collapsed;
  final bool light;
  final ValueChanged<bool> setTheme;
  const _SidebarFooter({required this.collapsed, required this.light, required this.setTheme});

  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);

    if (collapsed) {
      return Column(mainAxisSize: MainAxisSize.min, children: [
        // theme toggle (round indicator)
        GestureDetector(
          onTap: () => setTheme(!light),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.inputBg,
              borderRadius: BorderRadius.circular(NavigationSidebarThemeData.radiusMd),
              border: Border.all(color: t.border),
            ),
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: t.fg2, width: 2),
                color: light ? Colors.transparent : t.fg2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // help
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: t.inputBg,
            borderRadius: BorderRadius.circular(NavigationSidebarThemeData.radiusLg),
            border: Border.all(color: t.border),
          ),
          child: Icon(Icons.info_outline, size: 18, color: t.fg2),
        ),
      ]);
    }

    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // ── theme toggle (segmented Dark / Light) ──
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: t.inputBg,
          borderRadius: BorderRadius.circular(NavigationSidebarThemeData.radiusMd),
          border: Border.all(color: t.border),
        ),
        child: Row(children: [
          for (final opt in const [(false, 'DARK'), (true, 'LIGHT')])
            Expanded(
              child: GestureDetector(
                onTap: () => setTheme(opt.$1),
                child: AnimatedContainer(
                  duration: NavigationSidebarThemeData.durFast,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: light == opt.$1 ? t.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: light == opt.$1 ? const [BoxShadow(color: Color(0x33000000), blurRadius: 2, offset: Offset(0, 1))] : null,
                  ),
                  child: Text(
                    opt.$2,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 1.0,
                      color: light == opt.$1 ? t.fg1 : t.fg3,
                    ),
                  ),
                ),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      // ── help card ──
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: t.inputBg,
          borderRadius: BorderRadius.circular(NavigationSidebarThemeData.radiusXl),
          border: Border.all(color: t.border),
        ),
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: NavigationSidebarThemeData.accent.withOpacity(0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.info_outline, size: 18, color: NavigationSidebarThemeData.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('Need help?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.fg1)),
              const SizedBox(height: 1),
              Text('Go to Help Center →', style: TextStyle(fontSize: 11, color: t.fg3)),
            ]),
          ),
        ]),
      ),
    ]);
  }
}

// ════════════════════════════════════════════════════════════
// SEARCH DIALOG — command palette over the shell.
// ════════════════════════════════════════════════════════════
class _SearchHit {
  final String id;
  final String label;
  final IconData icon;
  final String crumb; // module title
  final String sub; // group label
  final NavBadge? badge;
  final List<String>? keys;
  const _SearchHit(this.id, this.label, this.icon, this.crumb, this.sub, this.badge, this.keys);
}

List<_SearchHit> _buildIndex(List<NavSection<String>> sections) {
  final out = <_SearchHit>[];
  for (final sec in sections) {
    for (final top in sec.items) {
      if (top.isLeaf) {
        out.add(_SearchHit(top.id, top.label, top.icon ?? Icons.circle, sec.title, '', top.badge, top.shortcut));
      } else {
        for (final grp in top.children) {
          final leaves = grp.hasChildren ? grp.children : [grp];
          for (final leaf in leaves) {
            out.add(_SearchHit(leaf.id, leaf.label, leaf.icon ?? Icons.circle, top.label, grp.hasChildren ? grp.label : '', leaf.badge, leaf.shortcut));
          }
        }
      }
    }
  }
  return out;
}

class _SearchDialog extends StatefulWidget {
  final NavigationSidebarController<String> controller;
  final VoidCallback onClose;
  final ValueChanged<String> onPick;
  const _SearchDialog({required this.controller, required this.onClose, required this.onPick});

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  late final List<_SearchHit> _index = _buildIndex(widget.controller.sections);
  final TextEditingController _text = TextEditingController();
  final FocusNode _focus = FocusNode();
  String _q = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<_SearchHit> get _results {
    final q = _q.trim().toLowerCase();
    if (q.isEmpty) return _index;
    final toks = q.split(RegExp(r'\s+'));
    return _index.where((h) {
      final hay = '${h.label} ${h.sub} ${h.crumb}'.toLowerCase();
      return toks.every(hay.contains);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    final results = _results;
    // group results by crumb (module)
    final groups = <String, List<_SearchHit>>{};
    for (final h in results) {
      groups.putIfAbsent(h.crumb, () => []).add(h);
    }

    return Positioned.fill(
      child: GestureDetector(
        onTap: widget.onClose,
        child: Container(
          color: const Color(0x8C08090C),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.fromLTRB(20, 90, 20, 20),
          child: GestureDetector(
            onTap: () {},
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: BorderRadius.circular(NavigationSidebarThemeData.radiusXl),
                    border: Border.all(color: t.borderStrong),
                    boxShadow: NavigationSidebarThemeData.popShadow,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    // input row
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.border))),
                      child: Row(children: [
                        Icon(Icons.search, size: 18, color: t.fg3),
                        const SizedBox(width: 11),
                        Expanded(
                          child: TextField(
                            controller: _text,
                            focusNode: _focus,
                            onChanged: (v) => setState(() => _q = v),
                            cursorColor: NavigationSidebarThemeData.accent,
                            style: TextStyle(fontSize: 15.5, color: t.fg1, fontFamily: NavigationSidebarThemeData.bodyFont),
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: 'Search tabs & actions…',
                              hintStyle: TextStyle(fontSize: 15.5, color: t.fg3),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onClose,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(border: Border.all(color: t.border), borderRadius: BorderRadius.circular(5)),
                            child: Text('ESC', style: TextStyle(fontFamily: NavigationSidebarThemeData.monoFont, fontSize: 10, color: t.fg3)),
                          ),
                        ),
                      ]),
                    ),
                    // results
                    Flexible(
                      child: results.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 28),
                              child: Text('No tabs match "$_q"', style: TextStyle(fontSize: 13.5, color: t.fg3)),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(8),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
                                  child: Text(
                                    _q.trim().isEmpty ? 'ALL TABS · ${_index.length}' : '${results.length} RESULT${results.length == 1 ? '' : 'S'}',
                                    style: TextStyle(fontFamily: NavigationSidebarThemeData.monoFont, fontSize: 10, letterSpacing: 1.2, color: t.fg4),
                                  ),
                                ),
                                for (final entry in groups.entries) ...[
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 5),
                                    child: Text(entry.key.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 10.5, letterSpacing: 1.3, color: t.fg3)),
                                  ),
                                  for (final h in entry.value) _resultRow(t, h),
                                ],
                              ]),
                            ),
                    ),
                    // footer hints
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(border: Border(top: BorderSide(color: t.border))),
                      child: Row(children: [
                        _hint(t, '↑↓', 'navigate'),
                        const SizedBox(width: 16),
                        _hint(t, '↵', 'open'),
                        const SizedBox(width: 16),
                        _hint(t, 'esc', 'close'),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _hint(NavigationSidebarThemeData t, String k, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(border: Border.all(color: t.border), borderRadius: BorderRadius.circular(4)),
        child: Text(k, style: TextStyle(fontFamily: NavigationSidebarThemeData.monoFont, fontSize: 10.5, color: t.fg3)),
      ),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontFamily: NavigationSidebarThemeData.monoFont, fontSize: 10.5, color: t.fg4)),
    ]);
  }

  Widget _resultRow(NavigationSidebarThemeData t, _SearchHit h) {
    final active = widget.controller.isActive(h.id);
    return _MenuRow(
      active: active,
      onTap: () => widget.onPick(h.id),
      child: Row(children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? t.accentFill(0.16) : t.inputBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(h.icon, size: 16, color: active ? NavigationSidebarThemeData.accent : t.fg3),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(h.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: t.fg1)),
            Text(h.sub.isEmpty ? h.crumb : h.sub, style: TextStyle(fontSize: 11, fontFamily: NavigationSidebarThemeData.monoFont, color: t.fg3)),
          ]),
        ),
        if (h.badge != null) _SearchBadge(badge: h.badge!),
      ]),
    );
  }
}

class _SearchBadge extends StatelessWidget {
  final NavBadge badge;
  const _SearchBadge({required this.badge});
  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    final c = t.badgeColors(badge.tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(999), border: Border.all(color: c.border)),
      child: Text(badge.text, style: TextStyle(fontFamily: NavigationSidebarThemeData.monoFont, fontSize: 9, fontWeight: FontWeight.w700, color: c.fg)),
    );
  }
}

// ════════════════════════════════════════════════════════════
// FAUX PAGE — muted backdrop with a live breadcrumb.
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
          Opacity(opacity: 0.55, child: Container(height: 28, width: 280, decoration: muted)),
          const SizedBox(height: 28),
          LayoutBuilder(builder: (context, c) {
            final cols = c.maxWidth > 720 ? 3 : (c.maxWidth > 440 ? 2 : 1);
            final w = (c.maxWidth - (cols - 1) * 20) / cols;
            return Wrap(spacing: 20, runSpacing: 20, children: [
              for (int i = 0; i < cols; i++)
                Opacity(opacity: 0.55, child: Container(width: w, height: 120, decoration: muted)),
            ]);
          }),
          const SizedBox(height: 24),
          Opacity(opacity: 0.55, child: Container(height: 320, decoration: muted)),
        ]),
      ),
    );
  }
}
