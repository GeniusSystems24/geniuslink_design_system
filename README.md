<!-- This README is also presented as an interactive web page: doc/showcase.html -->

# GeniusLink Design System

[![pub package](https://img.shields.io/badge/pub-v2.0.0-4A7CFF.svg)](https://pub.dev/packages/geniuslink_design_system)
[![flutter](https://img.shields.io/badge/Flutter-%E2%89%A53.10-1DB88A.svg)](https://flutter.dev)
[![style](https://img.shields.io/badge/style-MVC-F97316.svg)](#architecture)
[![license](https://img.shields.io/badge/license-MIT-64748B.svg)](#license)

A themeable, **MVC** Flutter widget kit ported from the GeniusLink web design system. Three production-grade, self-contained components — a browser-style **tab bar**, an Excel-style **editable table** with nine typed column kinds, and a customisable **tree** — all theme-aware (light **+** dark) and bilingual (LTR **+** RTL).

> 📺 **Visual tour:** open [`doc/showcase.html`](doc/showcase.html) in a browser for a designed walkthrough of every part and feature.

---

## Features

- 🧩 **Three components, one kit** — `BrowserStyleTabBar`, `EditableTable`, `Tree`.
- 🎨 **Self-contained theming** — each component carries its own `ThemeExtension` with ready-made `.light` / `.dark` presets. No global token file required.
- 🏛️ **Strict MVC** — immutable models, a `ChangeNotifier` controller as the single source of truth, and a thin view. Drive any component from outside, or from its own page content via an `InheritedNotifier` scope.
- ⌨️ **Full keyboard control** — spreadsheet navigation, inline editing, copy/cut/paste, undo/redo, and an in-widget shortcuts reference.
- 🌍 **RTL + dark** everywhere — mirrors via `Directionality` + `EdgeInsetsDirectional`.
- 🔌 **Zero third-party dependencies** — pure Flutter + Material.

## Install

```yaml
dependencies:
  geniuslink_design_system:
    git: # or a path/hosted source
      url: https://example.com/geniuslink_design_system.git
```

```dart
import 'package:geniuslink_design_system/geniuslink_design_system.dart';
```

Prefer a leaner import? Each component ships its own barrel:

```dart
import 'package:geniuslink_design_system/geniuslink_browser_tabs.dart';
import 'package:geniuslink_design_system/geniuslink_editable_table.dart';
import 'package:geniuslink_design_system/geniuslink_tree.dart';
```

Register the theme extensions you use (each falls back to its `.dark` preset if absent):

```dart
MaterialApp(
  theme: ThemeData(extensions: const [
    BrowserStyleTabBarThemeData.light,
    EditableTableThemeData.light,
    TreeThemeData.light,
  ]),
  darkTheme: ThemeData(extensions: const [
    BrowserStyleTabBarThemeData.dark,
    EditableTableThemeData.dark,
    TreeThemeData.dark,
  ]),
);
```

---

## Run the example

The package is a library (no `lib/main.dart`). Run the example app:

```bash
cd geniuslink_design_system_flutter/example
flutter pub get
flutter run -d chrome        # or any device / emulator
```

It opens on a **launcher** of demos, each hosting the components in a realistic shell — an all-in-one **ERP Console** (tree sidebar + tabs + tables), an **EditableTable** gallery (every column type), a **Tree** gallery, plus Figma- and Chrome-style tab-bar shells.

---

# Components

## 1 · EditableTable

An Excel-style data-entry grid. Click to select, type to overwrite, `Enter ↓` / `Tab →` to move, sort by clicking a header, undo/redo — with **nine typed column kinds**, row-aware validation, optional delete confirmation, and a totals footer.

### Quick start

```dart
EditableTable(
  columns: [
    EditableColumn(key: 'name', label: 'Account', required: true),
    NumericColumn(key: 'balance', label: 'Balance', includeInTotal: true),
  ],
  initialRows: const [
    {'name': 'Cash', 'balance': '42,500.00'},
    {'name': 'Bank', 'balance': '186,420.00'},
  ],
  showTotals: true,
  unitLabel: 'SAR',
  onChanged: (rows) => debugPrint('${rows.length} rows'),
);
```

`EditableRow` is just `Map<String, String>` — values are the strings the user typed; you parse on read. Provide `columns` + `initialRows` (the widget owns a controller), or pass a `controller:` to drive/observe it externally.

### Column types

Each kind is an ergonomic subclass of `EditableColumn` — pass the right one; the table picks the editor automatically.

| Column | Editor | Stores |
|---|---|---|
| `EditableColumn` | inline text | free text |
| `NumericColumn` | inline numeric (min/max/decimals) | grouped number `1,234.00` |
| `DateColumn` | masked `YYYY-MM-DD` + 📅 calendar button | ISO date |
| `TimeColumn` | masked `HH:mm` + 🕑 clock button | 24h time |
| `ComboBoxColumn` | free text **+** suggestions ▾ | any string |
| `DropdownColumn` | popup menu (strict) | one of `options` |
| `ColorPickerColumn` | swatch menu | `#RRGGBB` hex |
| `ReadonlyColumn` | — (never editable) | display only |
| `ComputedColumn` | — (derived from the row) | `compute(row)` |

```dart
final columns = <EditableColumn>[
  const ReadonlyColumn(key: 'id', label: 'ID', mono: true),
  const EditableColumn(key: 'task', label: 'Task', required: true),

  // Numeric — clamped, integer:
  const NumericColumn(key: 'qty', label: 'Qty', min: 0, decimals: 0),
  const NumericColumn(key: 'price', label: 'Price', min: 0, decimals: 2, includeInTotal: true),

  // Computed — recomputes on every edit:
  ComputedColumn(
    key: 'total', label: 'Total', includeInTotal: true,
    compute: (r) {
      final q = EditableTableFormat.parseNumber(r['qty'] ?? '') ?? 0;
      final p = EditableTableFormat.parseNumber(r['price'] ?? '') ?? 0;
      return EditableTableFormat.formatNumber(q * p);
    },
  ),

  // Web-style date & time fields — type with the keyboard, or use the picker button:
  const DateColumn(key: 'due', label: 'Due date'),
  const TimeColumn(key: 'at', label: 'Time'),

  // Strict dropdown vs. free-text combo:
  const DropdownColumn(key: 'status', label: 'Status', options: ['Open', 'Active', 'Done']),
  const ComboBoxColumn(key: 'tag', label: 'Tag', options: ['Design', 'Build', 'QA']),

  // Colour — cell shows a swatch + hex, edits via a swatch menu:
  const ColorPickerColumn(key: 'color', label: 'Colour'),
];
```

### Validation

Two hooks, both fed into the red cell border and the toolbar's validity badge:

```dart
// value-only
NumericColumn(
  key: 'bal', label: 'Balance',
  validate: (v) => (EditableTableFormat.parseNumber(v) ?? 0) < 0 ? 'No negatives' : null,
);

// row-aware (cross-column) — receives the whole row
EditableColumn(
  key: 'total', label: 'Line Total',
  cellValidator: (value, row) {
    final q = EditableTableFormat.parseNumber(row['qty'] ?? '');
    final p = EditableTableFormat.parseNumber(row['price'] ?? '');
    final t = EditableTableFormat.parseNumber(value);
    if (q == null || p == null || t == null) return null;
    return (q * p - t).abs() > 0.01 ? '≠ Qty × Price' : null;
  },
);
```

### Custom cell rendering

`cellBuilder` replaces a cell's read-only content with any widget (a chip, badge, progress bar…). The cell stays selectable/editable; you get the value, the whole row, selection/invalid state, and a `requestEdit` callback:

```dart
DropdownColumn(
  key: 'status', label: 'Status', options: ['Open', 'Active', 'Done'],
  cellBuilder: (context, cell) => GestureDetector(
    onTap: cell.requestEdit,
    child: Chip(label: Text(cell.value)),
  ),
);
```

### Keyboard shortcuts

Press the **⌨ button** in the toolbar (or `⌘/Ctrl + /`) for the in-widget cheatsheet.

| | |
|---|---|
| `↑ ↓ ← →` | Move between cells |
| `Tab` / `⇧Tab` | Next / previous cell — **Tab past the last cell appends a row** (`growOnTab`) |
| `Home` / `End` · `⌘+Home/End` | First / last column · first / last cell |
| Type · `Enter` / `F2` | Overwrite · edit (or open a select) |
| `Enter ↓` · `Tab →` | Commit & move |
| `⌘+Enter` · `⌘+D` · `⌘+⌫` | Add row · duplicate row · delete row |
| `⌘+C / X / V` · `⌘+Z / ⇧Z` | Copy / cut / paste cell · undo / redo |

### Options

```dart
EditableTable(
  columns: columns,
  showToolbar: true,        // validity badge, clipboard hint, shortcuts, undo/redo
  showRowNumbers: true,     // A1-style gutter
  showActions: true,        // per-row insert-below / delete
  showTotals: true,         // footer summing includeInTotal columns
  totalsLabel: 'Total',
  unitLabel: 'SAR',
  confirmDelete: true,      // popup before deleting (set false = instant)
  growOnTab: true,          // Tab on the last cell adds a new row
  showShortcutsHelp: true,  // the ⌨ reference button
);
```

### Driving it from code — `EditableTableController`

```dart
final c = EditableTableController(columns: columns, rows: seed);
c.addRow();
c.duplicateSelectedRow();
c.sortByColumn(1);
c.undo();
final picked = c.checkedLeafIds;          // Tree analogue; here use c.rows

EditableTable(controller: c);             // observe / share it

// from inside a custom cell / page:
EditableTableController.of(context)?.addRow();
```

---

## 2 · Tree

A customisable hierarchical tree / outline — file explorers, category outlines, layer panels. Indent guide-lines, disclosure twisties, inline rename, search-with-highlight, tri-state checkboxes, keyboard nav, a context menu, and undo/redo.

### Quick start

```dart
Tree(
  roots: const [
    TreeNode(id: 'src', label: 'src', folder: true, children: [
      TreeNode(id: 'main', label: 'main.dart'),
      TreeNode(id: 'ui', label: 'ui', folder: true, children: [
        TreeNode(id: 'button', label: 'button.dart', badge: 'edited'),
      ]),
    ]),
    TreeNode(id: 'readme', label: 'README.md'),
  ],
  initiallyExpanded: const {'src', 'ui'},
  onSelected: (node) => debugPrint('opened ${node.id}'),
);
```

### Options & hooks

```dart
Tree(
  roots: roots,
  showToolbar: true,        // search + expand/collapse all + undo/redo
  showSearch: true,
  showCheckboxes: false,    // tri-state checks; onCheckedChanged gives leaf ids
  showFooter: true,
  showGuides: true,         // the │ ├ └ indent guides
  dense: false,
  editable: true,           // inline rename (F2 / double-click) + structural edits
  iconBuilder: (row) => row.node.isFolder ? Icons.folder : Icons.description,
  trailingBuilder: (context, row) => null,   // inject host widgets per row
  labelBuilder: (context, row) => null,      // fully replace the label cell
  contextActions: (node) => [                // extra right-click items
    TreeAction(label: 'Open', icon: Icons.open_in_new, onSelected: (c, n) {}),
  ],
  onSelected: (n) {},
  onActivated: (n) {},        // double-click / Enter on a leaf
  onCheckedChanged: (ids) {},
  onChanged: (roots) {},      // structural change
);
```

### Driving it — `TreeController`

```dart
final t = TreeController(roots: roots, expanded: {'src'}, selected: 'main');
t.addChild('src', label: 'new.dart');
t.expandAll();
t.beginEdit('main');     // inline rename
t.undo();

// from inside row content:
TreeController.of(context)?.addChild(parentId);
```

Keyboard: `↑ ↓` move · `→ ←` expand/step-in / collapse/step-out · `Enter` toggle/activate · `F2` rename · `Space` check · `Delete` remove · `⌘Z` undo.

---

## 3 · BrowserStyleTabBar

A browser-style workspace tab strip — pinned / closable / dirty tabs, drag-to-reorder, a context menu, an overflow dropdown, a dirty-close confirm dialog, and **live mini-page previews** (the page's real captured frame on hover). Renders only the strip and drives the active-screen body.

### Quick start

```dart
// self-contained — owns a controller seeded with the default set:
const BrowserStyleTabBar();

// seed your own tabs:
BrowserStyleTabBar(tabsState: [
  BrowserTab(id: 1, title: 'Chart of Accounts', kind: GLTabKind.ledger, pinned: true),
  BrowserTab(id: 2, title: 'Journal Entry', kind: GLTabKind.doc, dirty: true),
  BrowserTab(id: 3, title: 'Dashboard', kind: GLTabKind.chart),
]);

// external controller + custom page content:
BrowserStyleTabBar(
  controller: myController,
  pageBuilder: (ctx, tab) => MyPage(tab),
);
```

### Driving it — `BrowserStyleTabBarController`

```dart
final tabs = BrowserStyleTabBarController(tabs: [...], activeId: 2);
tabs.add(title: 'New report', kind: GLTabKind.chart);
tabs.setDirty(myId, true);
tabs.select(otherId);

// any page can drive the strip:
BrowserStyleTabBarController.of(context)?.add(title: 'Detail', kind: GLTabKind.doc);
```

Ops: `select · add · close · closeOthers · closeToRight · duplicate · togglePin · reorder · setDirty · rename · mutate`. `of(context)` returns **null** outside a tab bar, so pages stay reusable stand-alone.

---

## Theming

Every component is self-contained: all of its surfaces live in one `ThemeExtension` with `.light` / `.dark` presets (lerped on theme change). Instance fields are the swappable surfaces (`bg / surface / hover / border / fg1..fg4`); static consts are the brand constants (`accent` + semantic palette, font families `Manrope` / `Inter` / `JetBrainsMono`, radii, shadows, motion).

```dart
ThemeData(extensions: const [EditableTableThemeData.light]);
final t = EditableTableThemeData.of(context); // falls back to .dark

// tweak a preset:
EditableTableThemeData.light.copyWith(surface: const Color(0xFFFBFBFD));
```

Brand tokens: blue `#4A7CFF` · green `#1DB88A` · orange `#F97316` · 4px radii · 40px controls.

## RTL & internationalisation

Wrap any component in `Directionality(textDirection: TextDirection.rtl, …)` — strips, guides, gutters, and menus all mirror. The example's **ERP Console** flips EN ⇄ AR (LTR ⇄ RTL) live.

## Architecture

```
lib/
├── geniuslink_design_system.dart        unified barrel (exports the 3 below)
├── geniuslink_browser_tabs.dart         · BrowserStyleTabBar barrel
├── geniuslink_editable_table.dart       · EditableTable barrel
├── geniuslink_tree.dart                 · Tree barrel
└── design_system/components/
    ├── data/
    │   ├── editable_table_models.dart        Model — columns, cell ref, formatters
    │   ├── editable_table_columns.dart       Model — typed column subclasses
    │   ├── editable_table_controller.dart    Controller — ChangeNotifier + scope
    │   ├── editable_table_theme.dart         Theme  — ThemeExtension
    │   ├── editable_table.dart               View   — EditableTable widget
    │   └── tree_*.dart                        Tree — model · controller · theme · view
    └── navigation/
        └── browser_style_tab_bar*.dart        BrowserStyleTabBar — MVC + overlays + pages
```

Each component follows **Model → Controller → View → Theme**: immutable data, a `ChangeNotifier` as the single source of truth, a thin view that forwards every gesture/keystroke, and a `ThemeExtension`. Controllers are exposed to descendant page content via an `InheritedNotifier` scope, so any child can drive the component.

## License

MIT © GeniusLink.
