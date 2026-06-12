---
name: geniuslink-editable-table
description: >
  How to use the GeniusLink EditableTable — an Excel-style, typed-column data-entry
  grid for Flutter (inline editing, validation, totals, column resize/reorder,
  TSV copy/paste, undo/redo, RTL). Use this whenever you build or modify Flutter
  UI that needs an editable spreadsheet-style table from the
  `geniuslink_design_system` package, or when wiring an `EditableTableController`.
---

# GeniusLink · EditableTable

An Excel-style data-entry grid. Click to select, type to overwrite, `Enter ↓` /
`Tab →` to move, click a header to sort, undo/redo — with **nine typed column
kinds**, value- and row-aware validation, optional delete confirmation, a totals
footer, drag-resize/reorder columns and TSV clipboard.

## Import & theme

```dart
import 'package:geniuslink_design_system/geniuslink_editable_table.dart';
```

Register the shared table theme extension once on your `MaterialApp` (it also
styles ReadableTable). Without it the component falls back to its `.dark` preset:

```dart
MaterialApp(
  theme:      ThemeData(extensions: const [EditableTableThemeData.light]),
  darkTheme:  ThemeData(extensions: const [EditableTableThemeData.dark]),
);
```

> **Two flavours, same names.** There are two barrels that both declare
> `EditableTable` / `EditableColumn`: the **map-backed** one above
> (`EditableRow = Map<String,String>`) and the **generic** one
> (`geniuslink_editable_table_generic.dart`, rows are your typed `T`). Import
> **exactly one per file**. Use map-backed for quick/dynamic data; use generic
> when each row is a strongly-typed immutable model.

## Quick start (map-backed)

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

`EditableRow` is `Map<String,String>` — values are the strings the user typed;
**you parse on read**. Provide `columns` + `initialRows` (the widget owns a
controller) **or** pass a `controller:` to drive/observe it externally — not both
data sources.

## Column kinds — pick the subclass, the table picks the editor

| Column | Editor | Stores |
|---|---|---|
| `EditableColumn` | inline text | free text |
| `NumericColumn` | numeric (`min`/`max`/`decimals`) | grouped `1,234.00` |
| `DateColumn` | masked `YYYY-MM-DD` + calendar button | ISO date |
| `TimeColumn` | masked `HH:mm` + clock button | 24h time |
| `ComboBoxColumn` | auto-suggest field (native `AutoSuggestionsBox`) | any string |
| `DropdownColumn` | strict popup menu | one of `options` |
| `ColorPickerColumn` | swatch menu | `#RRGGBB` |
| `ReadonlyColumn` | — never editable | display only |
| `ComputedColumn` | — derived | `compute(row)` |

```dart
final columns = <EditableColumn>[
  const ReadonlyColumn(key: 'id', label: 'ID', mono: true),
  const EditableColumn(key: 'task', label: 'Task', required: true),
  const NumericColumn(key: 'qty', label: 'Qty', min: 0, decimals: 0),
  const NumericColumn(key: 'price', label: 'Price', min: 0, decimals: 2, includeInTotal: true),
  ComputedColumn(key: 'total', label: 'Total', includeInTotal: true,
    compute: (r) {
      final q = EditableTableFormat.parseNumber(r['qty'] ?? '') ?? 0;
      final p = EditableTableFormat.parseNumber(r['price'] ?? '') ?? 0;
      return EditableTableFormat.formatNumber(q * p);
    }),
  const DateColumn(key: 'due', label: 'Due date'),
  const TimeColumn(key: 'at', label: 'Time'),
  const DropdownColumn(key: 'status', label: 'Status', options: ['Open', 'Active', 'Done']),
  const ComboBoxColumn(key: 'tag', label: 'Tag', options: ['Design', 'Build', 'QA']),
  const ColorPickerColumn(key: 'color', label: 'Colour'),
];
```

Use `EditableTableFormat.parseNumber` / `.formatNumber` when reading/writing
numeric strings — never hand-roll grouping.

### Combo cells with async (hybrid) options

`ComboBoxColumn` is edited with the native `AutoSuggestionsBox`. Add
`fetchOptions` for local-first + load-more:

```dart
ComboBoxColumn(
  key: 'vendor', label: 'Vendor',
  options: ['Acme Corp', 'Globex', 'Initech'],   // instant
  fetchOptions: (q) => api.searchVendors(q),       // loaded when local misses
  remoteMinChars: 1, remoteThreshold: 1,
)
```

## Validation (drives the red cell border + toolbar validity badge)

```dart
// value-only
NumericColumn(key: 'bal', label: 'Balance',
  validate: (v) => (EditableTableFormat.parseNumber(v) ?? 0) < 0 ? 'No negatives' : null);

// row-aware (cross-column) — receives the whole row
EditableColumn(key: 'total', label: 'Line Total',
  cellValidator: (value, row) { /* compare against row['qty'] etc. → message|null */ });
```

## Custom cell rendering

`cellBuilder` replaces a cell's read-only content with any widget; the cell stays
selectable/editable and you get `cell.value`, the row, state, and
`cell.requestEdit`:

```dart
DropdownColumn(key: 'status', label: 'Status', options: ['Open','Active','Done'],
  cellBuilder: (context, cell) => GestureDetector(
    onTap: cell.requestEdit, child: Chip(label: Text(cell.value))));
```

## Options

```dart
EditableTable(
  columns: columns,
  showToolbar: true, showRowNumbers: true, showActions: true,
  showTotals: true, totalsLabel: 'Total', unitLabel: 'SAR',
  confirmDelete: true,      // false = instant delete
  growOnTab: true,          // Tab on the last cell appends a row
  showShortcutsHelp: true,  // the ⌨ reference button (⌘/Ctrl + /)
);
```

## Driving it — `EditableTableController`

```dart
final c = EditableTableController(columns: columns, rows: seed);
c.addRow(); c.insertRowAt(2); c.duplicateSelectedRow(); c.deleteRowAt(3);
c.sortByColumn(1);          // cycles asc → desc
c.setRows(loaded);          // replace all (one undo step)
c.undo(); c.redo();         // c.canUndo / c.canRedo
final rows = c.rows;        // List<EditableRow>

// columns: resize/reorder by VISUAL index (logical indices stay stable)
c.resizeColumn(2, 40); c.resetColumnWidth(2); c.moveColumn(4, 1);
c.widthOf(0); c.columnOrder;

// clipboard (TSV → pastes into Sheets/Excel)
await c.copyRowsToClipboard([0, 2, 3], includeHeader: true);
await c.copyCellsToClipboard([CellRef(0,1), CellRef(0,2)]);

EditableTable(controller: c);                       // observe / share
EditableTableController.of(context)?.addRow();      // from a custom cell / page
```

### Generic rows — `EditableTable<T>`

Import `geniuslink_editable_table_generic.dart` **instead**. Each row is your
immutable `T`; every column carries `value: (T)=>String` + `setValue: (T,raw)=>T`
(null `setValue` ⇒ read-only). Has a 5-mode selection layer
(`EditableSelectionMode.{none,singleRow,multiRow,singleCell,multiCell}`),
`CheckboxColumn`, and `newRow:` to enable Add-row / Tab-to-grow.

```dart
final c = EditableTableController<InvoiceRow>(
  columns: [
    EditableColumn(label: 'Item', value: (r)=>r.item, setValue: (r,v)=>r.copyWith(item: v)),
    NumericColumn(label: 'Qty', value: (r)=>'${r.qty}', setValue: (r,v)=>r.copyWith(qty: int.tryParse(v) ?? r.qty), decimals: 0),
    ComputedColumn(label: 'Total', compute: (r)=>money(r.qty*r.price), includeInTotal: true),
  ],
  rows: seed, newRow: () => InvoiceRow.blank());
EditableTable<InvoiceRow>(controller: c);
```

## Keyboard (in-widget cheatsheet: ⌨ button or ⌘/Ctrl + /)

`↑↓←→` move · `Tab`/`⇧Tab` next/prev (Tab past last cell appends a row) ·
type/`Enter`/`F2` edit · `Enter ↓` / `Tab →` commit+move · `⌘+Enter` add row ·
`⌘+D` duplicate · `⌘+⌫` delete · `⌘+C/X/V` cell clipboard · `⌘+Z/⇧Z` undo/redo.
Arrows resolve to the **visual** direction (RTL-mirrored); off-screen targets
auto-scroll into view.

## RTL

Wrap in `Directionality(textDirection: TextDirection.rtl, child: …)` — header,
gutter, resize handle, menus and arrow keys all mirror.

## Gotchas

- Import **one** EditableTable barrel per file (map-backed vs generic clash).
- Don't pass both `initialRows`/`rows` **and** a `controller:` — pick one.
- Values are strings; parse with `EditableTableFormat`. Don't store typed data in
  the map-backed table — use `EditableTable<T>` for that.
- Register `EditableTableThemeData` or you silently get the dark preset.

## Reference

- **Examples (read first):** `EXAMPLES.md` in this folder — professional, varied, copy-ready scenarios.
- Demo: `example/lib/editable_table_demo.dart`, `example/lib/editable_table/combo_demo.dart`
- Interactive gallery: `docs/components-editable-table.html`
- Source: `lib/design_system/components/data/editable_table*.dart`
