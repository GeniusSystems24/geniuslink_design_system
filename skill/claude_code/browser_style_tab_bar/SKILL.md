---
name: geniuslink-browser-style-tab-bar
description: >
  How to use the GeniusLink BrowserStyleTabBar — a browser-style workspace tab
  strip for Flutter with pinned/closable/dirty tabs, drag-reorder, context menu,
  overflow dropdown, live mini-page previews, and state-preserving pages. Use
  when building or modifying a Flutter multi-tab workspace UI with the
  `geniuslink_design_system` package, or wiring a `BrowserStyleTabBarController`.
---

# GeniusLink · BrowserStyleTabBar

A browser-style workspace tab strip — pinned / closable / dirty tabs,
drag-to-reorder, a context menu, an overflow dropdown, a dirty-close confirm
dialog, and **live mini-page previews** on hover. It renders the strip **and**
the active page below it, and by default **keeps every page's state alive**
across tab switches.

## Import & theme

```dart
import 'package:geniuslink_design_system/geniuslink_browser_tabs.dart';

ThemeData(extensions: const [BrowserStyleTabBarThemeData.light]); // + .dark
```

## Quick start

```dart
const BrowserStyleTabBar();   // self-contained, default tab set

// seed your own:
BrowserStyleTabBar(tabsState: [
  BrowserTab(id: 1, title: 'Chart of Accounts', kind: GLTabKind.ledger, pinned: true),
  BrowserTab(id: 2, title: 'Journal Entry', kind: GLTabKind.doc, dirty: true),
  BrowserTab(id: 3, title: 'Dashboard', kind: GLTabKind.chart),
]);

// external controller + custom pages:
BrowserStyleTabBar(controller: myController, pageBuilder: (ctx, tab) => MyPage(tab));
```

Provide `tabsState` (widget owns a controller) **or** a `controller:`.
`pageBuilder` supplies content for each tab (used both in the active surface and,
scaled, in the hover preview); omit it for the built-in `GLTabPage` per kind.

## The tab — `BrowserTab`

```dart
BrowserTab({
  required int id,          // stable identity
  required String title,
  required GLTabKind kind,  // ledger · doc · store · chart · user · globe
  bool dirty = false,       // unsaved dot + close-confirm
  bool pinned = false,      // icon-only, anchored to the start edge
});
```

`GLTabKind` drives the leading icon, preview layout and default page. Pinned tabs
render icon-only and sort to the start; a `dirty` tab shows an unsaved dot and
triggers a confirm dialog on close.

## State-preserving pages

By default each tab's page is **built once and kept mounted** in an
`IndexedStack` — switching preserves scroll, form input and controllers with no
rebuild. Opt into rebuild-on-revisit with `lazyPages: true`.

```dart
BrowserStyleTabBar(controller: c, pageBuilder: buildPage);                  // state survives
BrowserStyleTabBar(controller: c, pageBuilder: buildPage, lazyPages: true); // rebuild each visit
```

## Embedding options

```dart
BrowserStyleTabBar(
  controller: c,
  pageBuilder: buildPage,
  showChrome: true,        // bordered rounded card. false = edge-to-edge in an app shell
  fillContent: false,      // true = page fills all height; false caps at 440px
  scrollContent: true,     // wrap page in a vertical scroll (false = page scrolls itself)
  contentPadding: const EdgeInsets.all(24),
  contentBackground: null, // defaults to theme surface
  onAddTab: null,          // intercept the + button (else controller.add())
);
```

## Driving it — `BrowserStyleTabBarController`

```dart
final tabs = BrowserStyleTabBarController(tabs: [...], activeId: 2);
tabs.add(title: 'New report', kind: GLTabKind.chart);   // → new id; activates
tabs.select(id); tabs.setDirty(id, true); tabs.togglePin(id);
tabs.rename(id, 'Q3 Trial Balance'); tabs.duplicate(id);
tabs.reorder(fromId, toId);
tabs.close(id); tabs.closeOthers(id); tabs.closeToRight(id);

// reads
tabs.tabs; tabs.activeTab; tabs.length; tabs.ordered;  // pinned-first
tabs.canCloseOthers(id); tabs.canCloseRight(id);

// from a page:
BrowserStyleTabBarController.of(context)?.add(title: 'Detail', kind: GLTabKind.doc);
```

Full op set: `select · add · close · closeOthers · closeToRight · duplicate ·
togglePin · setPinned · reorder · setDirty · rename · mutate` (escape hatch).
`of(context)` returns **null** outside a tab bar (pages stay reusable
stand-alone); `read(context)` is the non-listening variant for callbacks/initState.

## Keyboard & pointer

Focus the strip: `←→` move (visual direction, RTL-aware), `Home/End` first/last.
Right-click / long-press a tab → context menu (close, close others, close to the
right, duplicate, pin/unpin). Drag a tab to reorder.

## Gotchas

- Tab `id`s must be **stable & unique** — selection/reorder/close key on them.
- `pageBuilder` is also used for the scaled hover preview — keep it pure / cheap
  enough to render twice.
- State-preservation is the default (`IndexedStack`); pass `lazyPages: true` only
  if you *want* pages to reset on revisit.
- `of(context)` is null outside a tab bar — guard it in reusable pages.
- Register `BrowserStyleTabBarThemeData` or you get the dark preset.

## Reference

- **Examples (read first):** `EXAMPLES.md` in this folder — professional, varied, copy-ready scenarios.
- Demo / shells: `example/lib/` (ERP Console, Figma- and Chrome-style shells)
- Interactive: `docs/components-browser-style-tab-bar.html`
- Source: `lib/design_system/components/navigation/browser_style_tab_bar*.dart`,
  `tab_models.dart`, `tab_pages.dart`
