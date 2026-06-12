# NavigationSidebar — professional examples

Realistic, varied recipes. Each assumes the import + `NavigationSidebarThemeData`
registration from the skill.

---

## 1 · Full responsive app shell (expanded / rail / drawer from width)

The view doesn't guess the layout — the host derives `mode` from the available
width and one controller drives all three.

```dart
class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final nav = NavigationSidebarController<String>(sections: _sections, active: 'dashboard');
  String _screen = 'dashboard';

  static final _sections = <NavSection<String>>[
    NavSection(title: 'Overview', items: [
      NavNode(id: 'dashboard', label: 'Dashboard', icon: Icons.dashboard_outlined,
              value: 'dashboard', shortcut: ['g', 'd']),
    ]),
    NavSection(title: 'Finance', items: [
      NavNode(id: 'accountsHub', label: 'Accounts', icon: Icons.menu_book_outlined, children: [
        NavNode(id: 'coa', label: 'Chart of Accounts', children: [
          NavNode(id: 'accounts', label: 'Chart of Accounts', icon: Icons.menu_book_outlined, value: 'accounts'),
          NavNode(id: 'accountTree', label: 'Account Tree', icon: Icons.account_tree_outlined,
                  value: 'accountTree', badge: NavBadge('3'), shortcut: ['g', 't']),
        ]),
      ]),
      NavNode(id: 'journals', label: 'Journals', icon: Icons.receipt_long_outlined,
              value: 'journals', badge: NavBadge('Live', tone: NavBadgeTone.success)),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final mode = const NavSidebarBreakpoints().modeFor(c.maxWidth); // expanded ≥1200 · rail ≥768 · else drawer
      final sidebar = NavigationSidebar<String>(
        controller: nav,
        mode: mode,
        header: (ctx, collapsed) => _Brand(collapsed: collapsed),
        footer: (ctx, collapsed) => _HelpCard(collapsed: collapsed),
        onNavigate: (node) => setState(() => _screen = node.value!),  // drawer auto-dismisses
      );
      final page = _PageFor(screen: _screen);

      if (mode == NavSidebarMode.drawer) {
        return Scaffold(
          appBar: AppBar(leading: IconButton(icon: const Icon(Icons.menu), onPressed: nav.openDrawer)),
          body: Stack(children: [
            Positioned.fill(child: page),
            Positioned.fill(child: sidebar),   // overlays with its own scrim
          ]),
        );
      }
      return Row(children: [sidebar, Expanded(child: page)]);
    });
  }

  @override void dispose() { nav.dispose(); super.dispose(); }
}
```

---

## 2 · Deep-link navigation (auto-expands ancestors)

`navigate` sets active, opens every ancestor, and closes the drawer — so routing
and the sidebar stay in sync.

```dart
// from a router / notification / command palette:
nav.navigate('accountTree');     // expands Accounts ▸ Chart of Accounts, highlights the leaf

// from inside page content:
TextButton(
  onPressed: () => NavigationSidebarController.of<String>(context)?.navigate('journals'),
  child: const Text('Go to Journals'),
);
```

---

## 3 · Collapse toggle + badges that update live

```dart
// a header button that flips expanded ⇄ rail:
IconButton(icon: const Icon(Icons.view_sidebar_outlined), onPressed: nav.toggleCollapsed);

// badges carry a tone — pill on a row, dot on a collapsed module/rail icon:
NavNode(id: 'inbox', label: 'Inbox', icon: Icons.inbox_outlined, value: 'inbox',
        badge: NavBadge('9+', tone: NavBadgeTone.danger));
NavNode(id: 'sync', label: 'Sync', icon: Icons.sync, value: 'sync',
        badge: NavBadge('Live', tone: NavBadgeTone.success));
```

---

## 4 · Self-contained sidebar (no external controller)

When you don't need to drive it from elsewhere, pass `sections` + `active`
directly:

```dart
NavigationSidebar<String>(
  sections: _sections,
  active: 'dashboard',
  mode: NavSidebarMode.expanded,
  showGuides: true,        // │ ├ └ connectors
  railFlyouts: true,       // module hover flyouts when collapsed
  onNavigate: (node) => context.go('/${node.value}'),
);
```
