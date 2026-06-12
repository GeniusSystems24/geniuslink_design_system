<!--
  ChatGPT Codex skill · GeniusLink Design System
  Component: NavigationSidebar
  Scope: read this before writing or editing Flutter code that uses NavigationSidebar from
  the geniuslink_design_system package. It is the authoritative how-to-use guide.
-->

# Codex skill — GeniusLink NavigationSidebar

**When this applies.** You are working in a Flutter project that depends on
`geniuslink_design_system` and the task involves NavigationSidebar — a responsive app navigation sidebar with expanded / rail / drawer modes, badges and shortcut hints.

**How to use this file.** Follow the import, theme-registration and controller
patterns below exactly. Prefer the typed constructors and controller operations
shown here over hand-rolled widgets. Keep edits idiomatic to the package
(Model → Controller → View → Theme; controllers are the single source of truth
and are exposed to descendants via `<Component>Controller.of(context)`). Do not
invent APIs that are not listed here — if something is missing, check the source
files referenced at the bottom.

---

# GeniusLink · NavigationSidebar

A themeable, responsive **app navigation sidebar**. One data model (titled
**sections** of a **node tree**) renders in three modes the host picks from the
available width: a full **expanded** labelled tree with `│ ├ └` connectors, an
icon-only **rail** whose modules open a grouped hover **flyout**, and an
off-canvas **drawer** with a scrim for small screens. Active-screen highlight,
auto-expanding ancestors, badges, two-key shortcut hints, header/footer slots.

## Import & theme

```dart
import 'package:geniuslink_design_system/geniuslink_navigation_sidebar.dart';

ThemeData(extensions: const [NavigationSidebarThemeData.light]); // + .dark
```

## Quick start

```dart
NavigationSidebar<String>(
  sections: mySections,             // List<NavSection<String>>
  active: 'accounts',
  mode: NavSidebarMode.expanded,
  onNavigate: (node) => openScreen(node.value!),
);
```

Each node is a `NavNode<T>` carrying a typed `value`; compose a
`List<NavSection<T>>`. A node's **role is derived from position**: depth-0 leaf =
flat *direct* destination; depth-0 branch = collapsible *module*; nested branch =
*group* header; nested leaf = *item* (boxed icon).

```dart
final sections = <NavSection<String>>[
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
  ]),
];
```

## Responsive — three modes (host derives `mode` from width)

```dart
LayoutBuilder(builder: (context, c) {
  final mode = const NavSidebarBreakpoints().modeFor(c.maxWidth); // expanded ≥1200 · rail ≥768 · else drawer
  if (mode == NavSidebarMode.drawer) {
    return Stack(children: [
      page,
      Positioned.fill(child: NavigationSidebar<String>(controller: nav, mode: NavSidebarMode.drawer)),
    ]); // open via nav.openDrawer(); tapping a destination navigates *and* dismisses
  }
  return Row(children: [
    NavigationSidebar<String>(controller: nav, mode: mode),   // expanded or rail
    Expanded(child: page),
  ]);
});
```

## Options & slots

```dart
NavigationSidebar<T>(
  controller: nav,                 // or sections + active
  mode: NavSidebarMode.expanded,   // expanded · rail · drawer
  showGuides: true,                // │ ├ └ connectors
  railFlyouts: true,               // module hover flyouts in the rail
  drawerTitle: 'Navigation',
  header: (ctx, collapsed) => Brand(collapsed: collapsed),   // logo slot
  footer: (ctx, collapsed) => HelpCard(collapsed: collapsed),
  onNavigate: (node) {},
);
```

## Driving it — `NavigationSidebarController`

```dart
final nav = NavigationSidebarController<String>(sections: sections, active: 'accounts');
nav.navigate('settingsHub');   // sets active + auto-opens ancestors + closes the drawer
nav.toggleCollapsed();         // expanded ⇄ rail
nav.openDrawer();              // mobile
nav.expandAll();

NavigationSidebarController.of<String>(context)?.navigate('dashboard');  // from page content
```

## Badges

`NavBadge('Live', tone: NavBadgeTone.success)` — a pill on the row (a dot on a
collapsed module / rail icon). Tones include `success` and friends.

## Gotchas

- The view **does not guess** the layout — you pass `mode`. Use
  `NavSidebarBreakpoints().modeFor(width)` in a `LayoutBuilder`.
- `value` is the host payload you switch screens on; `id` is the stable identity
  for active-state / expansion.
- Role (direct / module / group / item) is **positional** — nest accordingly to
  get the intended visual treatment.
- Drawer mode needs to overlay the page (e.g. `Stack` + `Positioned.fill`); a
  destination tap navigates and dismisses.
- Register `NavigationSidebarThemeData` or you get the dark preset.

## Reference

- **Examples (read first):** `EXAMPLES.md` in this folder — professional, varied, copy-ready scenarios.
- Demo: `example/lib/navigation_sidebar_demo.dart` (app bar + sidebar + faux page,
  live Light/Dark, LTR/RTL, device-width simulator)
- Interactive: `docs/components-navigation-sidebar.html`
- Source: `lib/design_system/components/navigation/navigation_sidebar_*.dart`
