<!-- An interactive, per-component reference is published at docs/index.html -->

# GeniusLink Design System

[![pub package](https://img.shields.io/badge/pub-v2.4.0-4A7CFF.svg)](https://pub.dev/packages/geniuslink_design_system)
[![flutter](https://img.shields.io/badge/Flutter-%E2%89%A53.10-1DB88A.svg)](https://flutter.dev)
[![style](https://img.shields.io/badge/style-MVC-F97316.svg)](#architecture)
[![license](https://img.shields.io/badge/license-MIT-64748B.svg)](#license)

A themeable, **MVC** Flutter widget kit ported from the GeniusLink web design system. Five production-grade, self-contained components — a browser-style **tab bar**, an Excel-style **editable table** with nine typed column kinds, a read-only **readable table** with selection + sort, a customisable **tree**, and a responsive app **navigation sidebar** — all theme-aware (light **+** dark) and bilingual (LTR **+** RTL).

Both tables now ship **resizable + reorderable columns**, **typed `ReadableTable` column kinds**, and **TSV clipboard copy** (rows / cells paste straight into a spreadsheet); the `Tree` adds a **single / multi-select** layer with add & remove; and `BrowserStyleTabBar` **preserves each tab's page state** across switches. Keyboard arrows resolve to the **visual** direction in RTL, and keyboard focus **scrolls into view** in the table + tree.

> 📺 **Interactive docs:** open [`docs/index.html`](docs/index.html) in a browser for a live, per-component reference — each page mirrors the Flutter widget and runs in light / dark and LTR / RTL.

---

## Features

- 🧩 **Five components, one kit** — `BrowserStyleTabBar`, `EditableTable`, `ReadableTable`, `Tree`, `NavigationSidebar`.
- 🎨 **Self-contained theming** — each component carries its own `ThemeExtension` with ready-made `.light` / `.dark` presets. No global token file required.
- 🏛️ **Strict MVC** — immutable models, a `ChangeNotifier` controller as the single source of truth, and a thin view. Drive any component from outside, or from its own page content via an `InheritedNotifier` scope.
- ⌨️ **Full keyboard control** — spreadsheet navigation, inline editing, copy/cut/paste, undo/redo, and an in-widget shortcuts reference.
- 📐 **Resizable + reorderable columns** — drag a header edge to resize (RTL-mirrored, double-tap to reset), drag a header to reorder; both tables.
- 📋 **TSV clipboard copy** — a row, many rows, a cell or a cell rectangle serialize to tab-separated values and paste into Sheets / Excel / Numbers.
- ✅ **Tree single / multi-select** — Shift-range, Ctrl/⌘-toggle, tri-state checkboxes; group add / remove.
- ♻️ **State-preserving tabs** — every tab page is built once and kept alive, so scroll / input / controllers survive switching.
- 🌍 **RTL + dark** everywhere — mirrors via `Directionality` + `EdgeInsetsDirectional`, and arrow keys follow the **visual** direction.
- 🔌 **Lean dependencies** — pure Flutter + Material, plus the first-party [`smart_auto_suggest_box`](https://pub.dev/packages/smart_auto_suggest_box) (GeniusSystems24) powering `EditableTable` combo cells.

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
import 'package:geniuslink_design_system/geniuslink_readable_table.dart';
import 'package:geniuslink_design_system/geniuslink_tree.dart';
import 'package:geniuslink_design_system/geniuslink_navigation_sidebar.dart';
```

Register the theme extensions you use (each falls back to its `.dark` preset if absent):

```dart
MaterialApp(
  theme: ThemeData(extensions: const [
    BrowserStyleTabBarThemeData.light,
    EditableTableThemeData.light,   // also styles ReadableTable
    TreeThemeData.light,
    NavigationSidebarThemeData.light,
  ]),
  darkTheme: ThemeData(extensions: const [
    BrowserStyleTabBarThemeData.dark,
    EditableTableThemeData.dark,    // also styles ReadableTable
    TreeThemeData.dark,
    NavigationSidebarThemeData.dark,
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

It opens on a **launcher** of demos, each hosting the components in a realistic shell — an all-in-one **ERP Console** (tree sidebar + tabs + tables), an **EditableTable** gallery (every column type), a **ReadableTable** gallery (every selection mode + sort), a **Tree** gallery, plus Figma- and Chrome-style tab-bar shells.

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
| `ComboBoxColumn` | auto-suggest field (`smart_auto_suggest_box`) — type to filter, or free text | any string |
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

#### Combo cells (auto-suggest)

`ComboBoxColumn` cells are edited with the first-party
[`smart_auto_suggest_box`](https://pub.dev/packages/smart_auto_suggest_box)
package (publisher: GeniusSystems24): click a cell and type to filter the
`options` (matched text is highlighted, ↑ ↓ to move, Enter / click to pick), or
type any free value and Tab / Enter to commit it. The overlay is themed from
`EditableTableThemeData` and is RTL-aware. The grid still owns the edit
session — `EditableComboCellEditor` just bridges the suggest box to the
controller's draft.

For a fully-localized overlay, register the package delegate on your `MaterialApp`:

```dart
MaterialApp(
  localizationsDelegates: const [
    SmartAutoSuggestBoxLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [Locale('en'), Locale('ar')],
  // …
);
```

See `example/lib/editable_table/combo_demo.dart` for a runnable demo.

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

Arrow keys resolve to the **visual** direction — in an RTL (`Directionality.rtl`) layout the right arrow moves to the cell on the right (the *previous* column). Navigating to an off-screen cell scrolls it fully into view (both axes) via `Scrollable.ensureVisible`.

### Column resize & reorder

Both `EditableTable` and `ReadableTable` carry the same column-layout API on their controller, and the header is the UI for it:

- **Resize** — drag a header cell's trailing (inline-end) edge; the grid reflows live. Width is clamped to `columnMinWidth … columnMaxWidth` (64 … 520 px) and **double-tapping the handle resets** the column. The drag delta is **RTL-mirrored** (the handle sits on the visual left in RTL).
- **Reorder** — **long-press a header and drag** it onto another; a blue indicator marks the drop, and the whole grid (header, body, footer) rearranges at once. Only the *visual* order changes — sort, selection and cell values stay keyed by each column's stable **logical** index.

```dart
final c = EditableTableController(columns: cols, rows: seed);
c.resizeColumn(2, 40);          // widen the 3rd visual column by 40px
c.resetColumnWidth(2);          // back to its declared width
c.moveColumn(4, 1);             // drag column 5 → position 2
c.widthOf(0);                   // effective width of the 1st visual column
c.columnOrder;                  // [logical…] in current visual order
```

### Copy to the clipboard (TSV)

Beyond the single-cell `⌘C/⌘X/⌘V`, the controller serializes whole rows or a cell rectangle to **tab-separated values** so the result pastes straight into a spreadsheet. Tabs/newlines inside a value are flattened so one cell can't spill into its neighbours.

```dart
await c.copyRowsToClipboard([0, 2, 3], includeHeader: true);  // 3 rows → TSV
await c.copyCellsToClipboard([CellRef(0,1), CellRef(0,2), CellRef(1,1)]);
final tsv = c.rowsAsTsv([0, 1]);   // serialize without touching the clipboard
```

### Generic rows — `EditableTable<T>`

A typed-row variant (`EditableTable<T>` / `EditableColumn<T>`) lets each row be a strongly-typed immutable value instead of a `Map<String,String>` — each row is a `List<T>` of your own model and every column carries `value: (T) => String` plus `setValue: (T, raw) => T` accessors (mirroring `ReadableTable<T>`; a null `setValue` marks a read-only / computed column). It ships as its own barrel — import it **instead of** the map-backed table, since both declare the same names:

```dart
import 'package:geniuslink_design_system/geniuslink_editable_table_generic.dart';

@immutable
class InvoiceRow { final String item; final int qty; final double price; /* +copyWith */ }

final c = EditableTableController<InvoiceRow>(
  columns: [
    EditableColumn(label: 'Item',  value: (r) => r.item,  setValue: (r, v) => r.copyWith(item: v)),
    NumericColumn (label: 'Qty',   value: (r) => '${r.qty}', setValue: (r, v) => r.copyWith(qty: int.tryParse(v) ?? r.qty), decimals: 0),
    DropdownColumn(label: 'Unit',  options: ['ea','box'], value: (r) => r.unit, setValue: (r, v) => r.copyWith(unit: v)),
    DateColumn    (label: 'Due',   value: (r) => iso(r.due), setValue: (r, v) => r.copyWith(due: parse(v))),
    CheckboxColumn(label: 'Paid',  value: (r) => r.paid ? '1' : '0', setValue: (r, v) => r.copyWith(paid: v == '1')),
    ComputedColumn(label: 'Total', compute: (r) => money(r.qty * r.price), includeInTotal: true), // read-only
  ],
  rows: seed,
  newRow: () => InvoiceRow.blank(),       // enables Add-row + Tab-to-grow
);

EditableTable<InvoiceRow>(controller: c); // inline edit · sort · resize · reorder · copy · keyboard
```

Typed column constructors — `NumericColumn` (clamp + decimals), `DropdownColumn` (strict options), `DateColumn`, `CheckboxColumn`, `ComputedColumn` (read-only, derived) — declare a column's kind and editing affordance. The legacy map table is simply `T = EditableRow` via `mapColumn('key', 'Label')`. See `example/lib/editable_table_demo.dart` for a full `EditableTable<InvoiceRow>` with all kinds, resize / reorder, TSV copy and an RTL toggle.

**Selection layer.** Beyond the editing cursor, `EditableTableController<T>` carries the same five selection modes as `ReadableTable` — `EditableSelectionMode.{none, singleRow, multiRow, singleCell, multiCell}`. Click selects; **Shift-click** extends a range / rectangle, **⌘/Ctrl-click** toggles, **⌘/Ctrl+A** selects all, and **⌘/Ctrl+C** copies the selection (rows or a cell rectangle) as TSV.

```dart
final c = EditableTableController<InvoiceRow>(columns: cols, rows: seed,
    selectionMode: EditableSelectionMode.multiRow);
c.setSelectionMode(EditableSelectionMode.multiCell);   // flip at runtime
c.selectRow(2, range: true);  c.selectCell(0, 1, additive: true);
c.selectAll();  c.clearSelection();  c.deleteSelectedRows();
c.selectedRows;  c.selectedCells;  c.selectedCount;     // reads
await c.copySelectionTsvToClipboard(includeHeader: true);
```

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
c.addRow();                       // append a blank row
c.insertRowAt(2);                 // blank row at index 2
c.duplicateSelectedRow();
c.deleteRowAt(3);
c.sortByColumn(1);                // cycles asc → desc
c.setRows(loadedRows);            // replace all rows (one undo step)
c.undo();  c.redo();              // c.canUndo / c.canRedo
final rows = c.rows;             // List<EditableRow> — the current data

EditableTable(controller: c);     // observe / share it

// from inside a custom cell / page:
EditableTableController.of(context)?.addRow();
```

---

## 2 · ReadableTable

A **read-only, generic, MVC display grid** that shares the EditableTable look (it reuses `EditableTableThemeData` — identical header, hairline grid, surfaces, type ramp). Where `EditableTable` edits strings, `ReadableTable<T>` *displays* strongly-typed row values — and adds the read-only interaction layer a display grid needs: selection, keyboard navigation and click-to-sort. It's **generic over the row value type `T`**: each row is one `T`, and every `ReadableColumn<T>` renders itself from that value via `cell`, so row code reads `value.field` with no casting.

### Quick start

```dart
ReadableTable<Account>(
  selectionMode: ReadableSelectionMode.multiRow,
  columns: [
    ReadableColumn('Code', width: 90, sortable: true,
      sortKey: (a) => a.code,    cell: (ctx, a) => Text(a.code)),
    ReadableColumn('Account', flex: 2, sortable: true,
      sortKey: (a) => a.name,    cell: (ctx, a) => Text(a.name)),
    ReadableColumn('Balance', align: ReadableAlign.end, sortable: true,
      sortKey: (a) => a.balance, cell: (ctx, a) => Text(a.fmt)),
  ],
  rows: accounts,                                   // List<Account>
  onRowSelectionChanged: (rows) => debugPrint('$rows'),   // List<Account>
);
```

Columns size by `width:` (fixed px) **or** `flex:` (proportional, filling the row). Cells are arbitrary widgets — status pills, two-line bilingual text, progress bars — placed and aligned for you, no horizontal scroll. Provide `columns` + `rows` (the widget owns a controller), or pass a `controller:` to drive/observe it externally.

> **Just a grid of pre-built widgets?** Use `ReadableTable<List<Widget>>` and have each column return `value[i]`. That's exactly how the desktop `GLTable` wrapper keeps its `List<List<Widget>>` API.

### Typed column kinds

Beyond the unnamed `ReadableColumn(cell: …)` constructor, named factories declare a column's **intent** and get consistent formatting, alignment and a typed sort key for free — the same diversity of kinds as `EditableTable`, read-only:

```dart
ReadableColumn.text('Account', value: (a) => a.name, secondary: (a) => a.nameAr),  // optional 2nd line / bilingual
ReadableColumn.number('Balance', value: (a) => a.balance, decimals: 2, colorSign: true),
ReadableColumn.enumBadge('Type', value: (a) => a.type, color: typeColor),           // coloured pill
ReadableColumn.date('Opened', value: (a) => a.opened),
ReadableColumn.time('At', value: (a) => a.time),
ReadableColumn.color('Tag', hex: (a) => a.hex),                                      // swatch + hex
ReadableColumn.progress('Used', value: (a) => a.ratio),                              // labelled bar
ReadableColumn.link('Doc', text: (a) => a.ref, onTap: (a) => open(a)),
```

The renderers live in `readable_table_cells.dart` (`ReadableCells.*`) — theme-driven and intl-free. The original custom-`cell` constructor keeps working unchanged.

### Selection — five modes

Set `selectionMode:` to one of `ReadableSelectionMode.{none, singleRow, multiRow, singleCell, multiCell}` (default `none` = display only). Pointer: click selects; **Ctrl/⌘-click** toggles; **Shift-click** extends a range (linear for rows, rectangular for cells). `onRowSelectionChanged` reports the selected **values** (`List<T>`); `onCellSelectionChanged` gives a `Set<ReadableCell>`.

### Column sort

Mark a column `sortable: true` and click its header to cycle **asc → desc** (an arrow marks the active column). Supply `sortKey: (value) => Comparable` per column — numbers sort numerically, strings alphabetically. Sorting reorders the rows **and remaps the selection / cursor** so they follow their rows. `initialSortColumn` / `initialSortAscending` / `onSortChanged` round it out.

### Advanced filtering

The grid carries a typed, per-column **filter system**. The controller derives the visible rows from an immutable MASTER set on every change as `sort(filter(master))`; the selection lives in master space and is pruned to the visible rows each rebuild, so filtering, sorting and selection compose. Mount the ready-made bar with one flag:

```dart
ReadableTable<Account>(
  controller: c,
  showFilterBar: true,                 // quick-search · filter chips · AND/OR · count
  filterItemNoun: 'account', filterItemNounPlural: 'accounts',
);

// …or place the bar yourself, above the grid, for full control:
Column(children: [ ReadableFilterBar<Account>(controller: c), const SizedBox(height: 12), ReadableTable(controller: c) ]);
```

A **`ReadableFilter`** is one predicate over a logical column — a `ReadableFilterOp` + operand(s) + an `enabled` flag. The offered operators depend on the column's `ReadableColumnType` (text gets *contains / starts with / is empty*; numbers get *greater / less / between*; enums get *is any of*; dates get *is before / after / between*). Filters combine by `ReadableFilterJoin.all` (AND) or `.any` (OR), and a cross-column quick-search narrows further. Evaluation runs through each column's own `sortKey` / `copyText`, so numbers compare numerically and dates by instant.

```dart
c.addFilter(ReadableFilter.text(1, ReadableFilterOp.contains, 'cash'));   // Account contains "cash"
c.addFilter(ReadableFilter.number(6, ReadableFilterOp.between, 0, 5e4));  // Balance between 0 and 50,000
c.addFilter(ReadableFilter.anyOf(2, {'Asset', 'Income'}));               // Type is any of …
c.setFilterJoin(ReadableFilterJoin.any);                                  // OR instead of AND
c.setQuery('rajhi');                                                       // cross-column search
c.clearFilters();
```

| Group | API |
|---|---|
| **Filters** | `addFilter` · `insertFilterAt` · `updateFilterAt` · `removeFilterAt` · `toggleFilterAt` · `setFilters` · `clearFilters` |
| **Join / search** | `setFilterJoin(all\|any)` · `setQuery(str)` · `quickSearchColumns` |
| **Reads** | `filters` · `filterJoin` · `query` · `isFiltered` · `hasFilters` · `rowCount` (visible) vs `totalRowCount` · `isColumnFilterable(ci)` · `distinctValues(ci)` |

The bar itself is fully themed (`EditableTableThemeData`) and RTL-aware: a quick-search field, an **＋ Filter** button opening a column → condition → operand **editor dialog** (text / number / date-picker / multi-select), removable **chips** (tap to edit · dot to disable · ✕ to remove) with an inline **AND/OR** toggle, and a live **"N of M"** count + Clear-all.

#### Nested query builder — `ReadableFilterEditingView`

For advanced filtering — `A AND (B OR (C AND D))` — drop in the nested builder (the Attio / Notion-style surface). It edits the controller's **filter tree** and applies live:

```dart
ReadableFilterEditingView<Deal>(controller: c);          // applies live by default
```

The tree is a `ReadableFilterNode`: either a `ReadableFilter` leaf condition or a `ReadableFilterGroup` (a `join` + ordered `children`). Set one up front, or let the user build it:

```dart
c.setFilterGroup(ReadableFilterGroup(join: ReadableFilterJoin.all, children: [
  ReadableFilter.text(colOwner, ReadableFilterOp.equals, 'Davon Larson'),
  ReadableFilterGroup(join: ReadableFilterJoin.any, children: [
    ReadableFilter(columnIndex: colHealth, op: ReadableFilterOp.equals, value: 'Critical'),
    ReadableFilter.number(colValue, ReadableFilterOp.greater, 100000),
  ]),
]));
```

A non-empty tree **supersedes** the flat `filters` list for structured filtering; the quick-search still applies on top. Every group shows an **And / Or rail pill** (toggles all ⇄ any); every condition is column → operator → typed value, the value control adapting to the column kind (text · number · date-picker · enum dropdown · multi-select). **Add condition / Add subgroup / Clear all** and per-row delete round it out — all themed and RTL-aware (the rail mirrors). Pass `applyLive: false` to defer and call `state.apply()` yourself.

#### Inline column filters (header filter row)

Set `showColumnFilters: true` for a filter row directly beneath the headers — one control per column that filters on that column's value:

```dart
ReadableTable<Deal>(controller: c, showColumnFilters: true);
```

Text / number / date columns get a **contains-search** field; enum / colour columns get a **value dropdown** (All · …). They AND together and AND on top of the quick-search and any structured filters. Drive them programmatically with `c.setColumnSearch(ci, 'cash')` / `c.setColumnFilter(ci, ReadableFilter…)`, read `c.columnFilter(ci)` / `c.hasColumnFilters`, and clear with `c.clearColumnFilters()`.

### Keyboard

Focus the table (click it), then — press **?** (or `⌘/Ctrl + /`) for the in-widget cheatsheet:

| | |
|---|---|
| `↑ ↓` · `← →` | Move active row · move active cell (cell modes) |
| `Space` | Toggle (multi) / select the active row or cell |
| `⇧ + ↑↓←→` | Extend the selection (multi modes) |
| `⌘/Ctrl + A` | Select all rows / cells |
| `Enter` | Activate the active row (`onRowTap` → value + index) |
| `Home` / `End` · `⌘+Home/End` | Row edges · grid corners |
| `Esc` | Clear the selection |

### Driving it — `ReadableTableController<T>`

The controller is the single source of truth; the view is a thin render of it. It exposes intention-revealing operations — **select / add / delete / replace** rows **by index · value · where · firstWhere** — and is published to descendants via a scope (`ReadableTableController.of<T>(context)`).

```dart
final c = ReadableTableController<Account>(
  columns: columns, rows: accounts,
  selectionMode: ReadableSelectionMode.multiRow,
);

ReadableTable<Account>(controller: c);   // observe / share it
```

| Group | Operations |
|---|---|
| **Select rows** | `selectRowAt(index, {additive, range})` · `selectRowByValue(value, {additive})` · `selectRowsWhere(test, {additive})` · `selectAllRows()` · `clearSelection()` |
| **Add rows** | `insertRowAt(index, value)` · `addRowWhere(test, value, {after, firstOnly})` · `addRow(value)` *(end)* |
| **Delete rows** | `deleteRowAt(index)` · `deleteRowsWhere(test)` · `deleteRowByValue(value)` · `deleteSelectedRows()` |
| **Replace row** | `replaceRowAt(index, value)` · `replaceRowByValue(old, new)` · `replaceRowsWhere(test, update)` · `replaceFirstWhere(test, update)` |
| **Cells / sort / data** | `selectCellAt(r, c, …)` · `selectAllCells()` · `sortByColumn(ci)` · `clearSort()` · `setRows(values)` |

```dart
c.selectRowsWhere((a) => a.type == 'Expense');           // select … where
c.addRowWhere((a) => a.type == 'Asset', newAccount);     // add … where (after match)
c.deleteRowByValue(oldAccount);                          // delete … by value
c.replaceFirstWhere((a) => a.type == 'Asset',            // replace … firstWhere
    (a) => a.copyWith(balance: a.balance * 1.1));

// from inside a custom cell / page:
ReadableTableController.of<Account>(context)?.deleteSelectedRows();
```

### Column resize & reorder · copy (TSV)

The controller carries the same column-layout API as `EditableTable` — **drag a header edge to resize** (RTL-mirrored, double-tap to reset, clamped 64…520 px) and **long-press a header to reorder** it (a blue indicator marks the drop). Only the visual order changes; selection, sort and cell addresses stay keyed by logical index.

```dart
c.resizeColumn(1, 30);  c.resetColumnWidth(1);
c.moveColumn(3, 0);     c.columnOrder;   c.widthOf(0);
```

The current selection — a row, many rows, a cell or a cell rectangle — copies to the system clipboard as **tab-separated values** (wired to `⌘/Ctrl + C`). Unselected interior cells in a rectangle are emitted blank so the block keeps its shape; per-column `copyText:` supplies the flat string a widget cell can't.

```dart
await c.copySelectionToClipboard(includeHeader: true);   // → Sheets / Excel
final tsv = c.copySelectionAsTsv();                       // without the clipboard
```

### Options

```dart
ReadableTable<T>(
  controller: c,            // or columns + rows
  selectionMode: ReadableSelectionMode.none,
  showHeader: true,
  zebra: false,             // faint fill on odd rows
  hoverHighlight: true,     // tint the row under the pointer
  rowMinHeight: 52,
  cellPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  onRowTap: (value, index) {},
  emptyState: const Text('No rows'),
);
```

Defaults reproduce a plain, non-interactive ledger (`selectionMode: none`, no keyboard) — so adopting `ReadableTable` for display-only tables changes nothing until you opt into a mode.

---

## 3 · Tree

A customisable **generic** hierarchical tree / outline — file explorers, category outlines, layer panels, a chart of accounts. Every node is `TreeNode<T>` carrying a strongly-typed `value`, so row code reads `node.value` with no casting. Indent guide-lines, disclosure twisties, click / keyboard **selection** (single or multi), inline rename, search-with-highlight, tri-state checkboxes, a context menu, and undo/redo.

### Quick start

```dart
// Untyped (T = dynamic) — the simplest form:
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

Provide `roots` + `initiallyExpanded` (the widget owns a controller), or pass a `controller:` to drive / observe it externally (and to opt into multi-select — see below).

### The node — `TreeNode<T>`

Immutable schema; a host composes a `List<TreeNode<T>>`, each with its own `children`, to describe the whole tree:

| Field | Type | Meaning |
|---|---|---|
| `id` | `String` | **Required.** Stable, unique identity (path / uuid / db id). |
| `label` | `String` | **Required.** Display text — also what rename and search match. |
| `children` | `List<TreeNode<T>>` | Child nodes. Empty for a leaf. |
| `value` | `T?` | Strongly-typed host payload (`node.value` is a `T`, no cast). |
| `icon` | `IconData?` | Leading-icon override (else inferred: folder / leaf). |
| `badge` | `String?` | Trailing badge text (a count, a status…). |
| `folder` | `bool?` | Force folder/leaf. `null` ⇒ folder iff it currently has children. |
| `selectable` | `bool` | When `false` the row can't be selected (still shown / expandable). |
| `data` | `Map<String, Object?>` | Incidental metadata; prefer `value` for the payload. |

### Typed nodes — `Tree<T>`

```dart
// Each node carries a typed Account; node.value is an Account, no casts.
final roots = <TreeNode<Account>>[
  TreeNode(id: '1000', label: 'Assets',
    value: Account(code: '1000', type: 'Asset'),
    children: [ /* … */ ]),
];

Tree<Account>(
  roots: roots,
  trailingBuilder: (ctx, row) => Text(row.node.value!.nature), // DR / CR
  onActivated: (n) => openLedger(n.value!),
);
```

See `example/lib/tree_demo.dart` + `account_tree_data.dart` for a full typed
chart-of-accounts, and `docs/components-tree.html` for an interactive gallery
with three value types (`Account`, `FileMeta`, `Person`).

### Selection — single or multi

A click / keyboard **selection layer** sits on the controller, independent of the checkbox layer. Set `TreeController.selectionMode` to one of `TreeSelectionMode.{none, single, multi}` (default `single`) — it's a mutable field, so a host can flip into a "select mode" at runtime. Because the mode lives on the controller, multi-select means **passing a `controller:`**:

```dart
final t = TreeController<Account>(
  roots: roots,
  selectionMode: TreeSelectionMode.multi,
);

Tree<Account>(controller: t, onSelected: (n) {});
```

Pointer / keyboard: a plain click resets to one node; **Ctrl/⌘-click toggles** a node; **Shift-click** (and `Shift + ↑/↓`) selects the contiguous visible range from the anchor; `⌘/Ctrl + A` selects every visible node. Read the result for group actions:

```dart
t.selection;          // Set<TreeNodeId> — every selected id
t.selectedNodes;      // List<TreeNode<T>> in visible (top-to-bottom) order
t.selectionCount;     // int
t.selectWith(id, toggle: true);          // toggle one (multi)
t.selectWith(id, range: true);           // extend the range to id
t.selectAllVisible();                    // multi only
t.removeSelected();   // delete every selected node + subtree (one undo step) → count
t.clearSelection();
```

`removeSelected()` drops any node whose ancestor is also selected (so a parent + child don't double-remove) and is a single undoable step.

### Checkboxes

Independent of selection, turn on `showCheckboxes: true` for a **tri-state** check column — checking a folder checks all descendant leaves; a partially-checked folder shows a dash. `onCheckedChanged` reports the checked **leaf** ids; read them any time via `controller.checkedLeafIds`.

### Search

With `showSearch: true` (and the toolbar), typing filters the tree to matching labels **plus their ancestors** (so matches stay reachable) and highlights the hit. Drive it from code with `controller.setQuery('cash')`; `controller.filtering` / `matchCount` report state. `/` or `⌘/Ctrl + F` focuses the field, `Esc` clears it.

### Options & hooks

```dart
Tree(
  roots: roots,
  showToolbar: true,        // search + expand/collapse all + undo/redo
  showSearch: true,
  showCheckboxes: false,    // tri-state checks; onCheckedChanged gives leaf ids
  showFooter: true,
  showGuides: true,         // the │ ├ └ indent guides
  dense: false,             // compact row height
  editable: true,           // inline rename (F2 / double-click) + structural edits
  iconBuilder: (row) => row.node.isFolder ? Icons.folder : Icons.description,
  trailingBuilder: (context, row) => null,   // inject host widgets per row
  labelBuilder: (context, row) => null,      // fully replace the label cell
  contextActions: (node) => [                // extra right-click items
    TreeAction(label: 'Open', icon: Icons.open_in_new, onSelected: (c, n) {}),
  ],
  onSelected: (n) {},
  onActivated: (n) {},        // double-click / Enter on a leaf
  onCheckedChanged: (ids) {}, // Set<TreeNodeId> of checked leaves
  onChanged: (roots) {},      // structural change (add / remove / rename / move)
);
```

### Driving it — `TreeController`

```dart
final t = TreeController(roots: roots, expanded: {'src'}, selected: 'main');

// structural edits (all undoable, all route through onChanged):
t.addChild('src', label: 'new.dart');     // → new id; expands, selects, renames
t.addChild('src', folder: true);          // empty folder
t.addSibling('main', label: 'next.dart');
t.duplicate('main');                       // fresh-id subtree as next sibling
t.remove('button');
t.removeSelected();                        // group delete (multi)

// expansion / editing / history:
t.expandAll();  t.collapseAll();  t.toggle('ui');
t.beginEdit('main');                       // inline rename
t.undo();  t.redo();   // t.canUndo / t.canRedo

// from inside row content (trailingBuilder / labelBuilder / a page):
TreeController.of<Account>(context)?.addChild(parentId);
```

`TreeController.of<T>(context)` returns the host controller (or `null` outside a tree), so any row widget can drive the tree.

### Keyboard

Focus the tree body, then — press **?** for the in-widget cheatsheet:

| | |
|---|---|
| `↑ ↓` | Move the cursor between visible rows |
| `→ ←` | Expand / step into a child · collapse / step out (RTL-mirrored) |
| `Home` / `End` | First / last visible row |
| `Enter` | Toggle a folder · activate a leaf (`onActivated`) |
| `Space` | Check / uncheck (when `showCheckboxes`) |
| `⇧ + ↑↓` · `⌘/Ctrl-click` · `⇧-click` | Extend / toggle / range-select (multi) |
| `⌘/Ctrl + A` | Select all visible (multi) |
| `F2` · `Delete` | Rename · remove the focused node (`editable`) |
| `/` or `⌘/Ctrl + F` · `Esc` | Focus search · clear it |
| `*` / `\` | Expand all / collapse all |
| `⌘/Ctrl + Z` / `⇧Z` | Undo / redo |

Navigating to an off-screen row (move, expand-into, or step-out) scrolls it into view, and arrow directions follow the **visual** direction in RTL.

---

## 4 · BrowserStyleTabBar

A browser-style workspace tab strip — pinned / closable / dirty tabs, drag-to-reorder, a context menu, an overflow dropdown, a dirty-close confirm dialog, and **live mini-page previews** (the page's real captured frame on hover). It renders the strip **and** the active page below it, and (by default) **keeps every page's state alive** across tab switches.

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

Provide `tabsState` (the widget owns a controller), or pass a `controller:` to drive / observe it externally. `pageBuilder` supplies the content for each tab (used both in the active surface and, scaled, in the hover preview); omit it to get the built-in `GLTabPage` per kind.

### The tab — `BrowserTab`

```dart
BrowserTab({
  required int id,        // stable identity
  required String title,
  required GLTabKind kind, // ledger · doc · store · chart · user · globe
  bool dirty = false,     // unsaved-changes dot + close-confirm
  bool pinned = false,    // icon-only, anchored on the start edge
});
```

`GLTabKind` drives the leading icon, the preview layout and the default page; pinned tabs render icon-only and sort to the start; a `dirty` tab shows an unsaved dot and triggers a confirm dialog on close.

### State-preserving pages

By default every tab's page is **built once and kept mounted** in an `IndexedStack`, so switching tabs preserves scroll position, form input and controllers with **no rebuild** — switching only changes the visible index (each page is held alive even offstage). Opt into the cheaper build-only-the-active-page behaviour — pages reset when revisited — with `lazyPages: true`.

```dart
BrowserStyleTabBar(controller: c, pageBuilder: buildPage);          // state survives switching
BrowserStyleTabBar(controller: c, pageBuilder: buildPage, lazyPages: true); // rebuild on each visit
```

### Embedding options

```dart
BrowserStyleTabBar(
  controller: c,
  pageBuilder: buildPage,
  showChrome: true,         // the bordered, rounded card. false = edge-to-edge in an app shell
  fillContent: false,       // true = page fills all height (full-window workspace); false caps at 440px
  scrollContent: true,      // wrap the page in a vertical scroll view (false = page scrolls itself)
  contentPadding: const EdgeInsets.all(24),
  contentBackground: null,  // defaults to the theme surface
  onAddTab: null,           // intercept the + button (else the controller's add())
);
```

### Driving it — `BrowserStyleTabBarController`

```dart
final tabs = BrowserStyleTabBarController(tabs: [...], activeId: 2);

tabs.add(title: 'New report', kind: GLTabKind.chart);  // → new id; activates
tabs.select(otherId);
tabs.setDirty(myId, true);
tabs.togglePin(myId);
tabs.rename(myId, 'Q3 Trial Balance');
tabs.duplicate(myId);
tabs.reorder(fromId, toId);
tabs.close(myId);  tabs.closeOthers(myId);  tabs.closeToRight(myId);

// reads:
tabs.tabs;  tabs.activeTab;  tabs.length;  tabs.ordered;  // pinned-first order
tabs.canCloseOthers(id);  tabs.canCloseRight(id);

// any page can drive the strip:
BrowserStyleTabBarController.of(context)?.add(title: 'Detail', kind: GLTabKind.doc);
```

Full op set: `select · add · close · closeOthers · closeToRight · duplicate · togglePin · setPinned · reorder · setDirty · rename · mutate` (an escape hatch — edit inside the callback, it notifies after). `of(context)` returns **null** outside a tab bar, so pages stay reusable stand-alone; `read(context)` is the non-listening variant for callbacks / `initState`.

### Keyboard

Focus the strip: `← →` move between tabs (visual direction, RTL-aware), `Home` / `End` jump to the first / last tab. Right-click (or long-press) any tab for the context menu — close, close others, close to the right, duplicate, pin / unpin.

---

## 5 · NavigationSidebar

A themeable, responsive **app navigation sidebar** — the GeniusLink web nav ported whole. One data model (titled **sections** of a **node tree**) renders in three modes that the host picks from the available width: a full **expanded** labelled tree with `│ ├ └` connectors, an icon-only **rail** whose modules open a grouped hover **flyout**, and an off-canvas **drawer** with a scrim for small screens. Active-screen highlight, auto-expanding ancestors, badges (count / status), two-key shortcut hints, optional header/footer slots — all theme-aware and RTL-mirrored.

### Quick start

```dart
// self-contained — owns a controller seeded with your sections:
NavigationSidebar<String>(
  sections: mySections,            // List<NavSection<String>>
  active: 'accounts',
  mode: NavSidebarMode.expanded,
  onNavigate: (node) => openScreen(node.value!),
);
```

Each node is a `NavNode<T>` carrying a typed `value`; compose a `List<NavSection<T>>` to describe the whole sidebar. A node's **role** is derived from its position — a depth-0 leaf is a flat *direct* destination, a depth-0 branch is a collapsible *module*, a nested branch is a *group* header, and a nested leaf is an *item* (boxed icon):

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
        NavNode(id: 'accountTree', label: 'Account Tree', icon: Icons.account_tree_outlined, value: 'accountTree',
                badge: NavBadge('3'), shortcut: ['g', 't']),
      ]),
    ]),
  ]),
];
```

### Responsive — three modes

The view doesn't guess the layout; the host derives the `mode` from the available width (a `LayoutBuilder` + `NavSidebarBreakpoints` does it in a line) and the same controller drives all three:

```dart
LayoutBuilder(builder: (context, c) {
  final mode = const NavSidebarBreakpoints().modeFor(c.maxWidth); // expanded ≥1200 · rail ≥768 · else drawer
  if (mode == NavSidebarMode.drawer) {
    return Stack(children: [
      page,
      Positioned.fill(child: NavigationSidebar<String>(controller: nav, mode: NavSidebarMode.drawer)),
    ]); // open via nav.openDrawer(); a tap on a destination navigates *and* dismisses
  }
  return Row(children: [
    NavigationSidebar<String>(controller: nav, mode: mode), // expanded or rail
    Expanded(child: page),
  ]);
});
```

### Options & slots

```dart
NavigationSidebar<T>(
  controller: nav,                 // or sections + active
  mode: NavSidebarMode.expanded,   // expanded · rail · drawer
  showGuides: true,                // the │ ├ └ connector lines
  railFlyouts: true,               // module hover flyouts in the rail
  drawerTitle: 'Navigation',
  header: (ctx, collapsed) => Brand(collapsed: collapsed),  // logo slot
  footer: (ctx, collapsed) => HelpCard(collapsed: collapsed),
  onNavigate: (node) {},
);
```

### Driving it — `NavigationSidebarController`

```dart
final nav = NavigationSidebarController<String>(
  sections: sections, active: 'accounts',
);
nav.navigate('settingsHub');   // sets active + auto-opens ancestors + closes the drawer
nav.toggleCollapsed();         // expanded ⇄ rail
nav.openDrawer();              // mobile
nav.expandAll();

// from inside page content:
NavigationSidebarController.of<String>(context)?.navigate('dashboard');
```

Badges carry a tone — `NavBadge('Live', tone: NavBadgeTone.success)` — drawn as a pill on the row (a dot on a collapsed module / rail icon). See `example/lib/navigation_sidebar_demo.dart` for the full shell (app bar + sidebar + faux page) with live Light/Dark, LTR/RTL and a device-width simulator.

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
├── geniuslink_design_system.dart        unified barrel (exports the 5 below)
├── geniuslink_browser_tabs.dart         · BrowserStyleTabBar barrel
├── geniuslink_editable_table.dart       · EditableTable barrel
├── geniuslink_readable_table.dart       · ReadableTable barrel (shares the editable theme)
├── geniuslink_tree.dart                 · Tree barrel
├── geniuslink_navigation_sidebar.dart   · NavigationSidebar barrel
└── design_system/components/
    ├── data/
    │   ├── editable_table_models.dart        Model — columns, cell ref, formatters
    │   ├── editable_table_columns.dart       Model — typed column subclasses
    │   ├── editable_table_controller.dart    Controller — ChangeNotifier + scope
    │   ├── editable_table_theme.dart         Theme  — ThemeExtension (Editable + Readable)
    │   ├── editable_table.dart               View   — EditableTable widget
    │   ├── editable_table_combo_editor.dart  View   — ComboBoxColumn editor (smart_auto_suggest_box)
    │   ├── readable_table_models.dart          Model  — ReadableColumn<T>, cell, enums
    │   ├── readable_table_filter.dart          Model  — ReadableFilter, group tree, ops, catalog
    │   ├── readable_table_controller.dart      Controller — ChangeNotifier + scope (+ filtering)
    │   ├── readable_table.dart                 View   — ReadableTable<T> (generic · MVC)
    │   ├── readable_table_filter_bar.dart      View   — ReadableFilterBar<T> (flat chips)
    │   ├── readable_table_filter_view.dart     View   — ReadableFilterEditingView<T> (nested)
    │   └── tree_*.dart                        Tree — model · controller · theme · view
    └── navigation/
        ├── browser_style_tab_bar*.dart        BrowserStyleTabBar — MVC + overlays + pages
        └── navigation_sidebar_*.dart          NavigationSidebar — model · controller · theme · view
```

Each component follows **Model → Controller → View → Theme**: immutable data, a `ChangeNotifier` as the single source of truth, a thin view that forwards every gesture/keystroke, and a `ThemeExtension`. Controllers are exposed to descendant page content via an `InheritedNotifier` scope, so any child can drive the component.

## License

MIT © GeniusLink.
