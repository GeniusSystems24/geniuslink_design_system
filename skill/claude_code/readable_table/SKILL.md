---
name: geniuslink-readable-table
description: >
  How to use the GeniusLink ReadableTable — a read-only, generic (typed-row)
  display grid for Flutter with selection, click-to-sort, keyboard nav, and a
  full filter system (flat chips, nested query builder, inline column filters).
  Use when building or modifying Flutter UI that displays tabular data with the
  `geniuslink_design_system` package, or when wiring a `ReadableTableController`.
---

# GeniusLink · ReadableTable

A **read-only, generic, MVC display grid** that shares the EditableTable look
(reuses `EditableTableThemeData`). It is generic over the row value type `T`:
each row is one `T` and every `ReadableColumn<T>` renders from it via `cell` —
row code reads `value.field` with no casting. Adds selection, keyboard nav,
click-to-sort, and a rich filter system.

## Import & theme

```dart
import 'package:geniuslink_design_system/geniuslink_readable_table.dart';
```

ReadableTable is styled by **`EditableTableThemeData`** (shared). Register it:

```dart
ThemeData(extensions: const [EditableTableThemeData.light]); // + .dark in darkTheme
```

## Quick start

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
  rows: accounts,                                        // List<Account>
  onRowSelectionChanged: (rows) => debugPrint('$rows'),  // List<Account>
);
```

Columns size by `width:` (fixed px) **or** `flex:` (proportional). Cells are
arbitrary widgets, placed/aligned for you — no horizontal scroll. Provide
`columns` + `rows`, **or** a `controller:`. For a grid of pre-built widgets, use
`ReadableTable<List<Widget>>` and return `value[i]` per column.

## Typed column kinds (consistent format + a typed sort key for free)

```dart
ReadableColumn.text('Account', value: (a)=>a.name, secondary: (a)=>a.nameAr), // 2nd line / bilingual
ReadableColumn.number('Balance', value: (a)=>a.balance, decimals: 2, colorSign: true),
ReadableColumn.enumBadge('Type', value: (a)=>a.type, color: typeColor),       // coloured pill
ReadableColumn.date('Opened', value: (a)=>a.opened),
ReadableColumn.time('At', value: (a)=>a.time),
ReadableColumn.color('Tag', hex: (a)=>a.hex),                                  // swatch + hex
ReadableColumn.progress('Used', value: (a)=>a.ratio),                         // labelled bar
ReadableColumn.link('Doc', text: (a)=>a.ref, onTap: (a)=>open(a)),
```

The unnamed `ReadableColumn(cell: …)` constructor keeps working unchanged.

## Selection — five modes

`selectionMode: ReadableSelectionMode.{none, singleRow, multiRow, singleCell,
multiCell}` (default `none` = display only). Click selects; **Ctrl/⌘-click**
toggles; **Shift-click** extends a range (linear rows / rectangular cells).
`onRowSelectionChanged` → `List<T>`; `onCellSelectionChanged` → `Set<ReadableCell>`.

## Sort

Mark a column `sortable: true` + supply `sortKey: (value) => Comparable`. Click
the header to cycle asc → desc. `initialSortColumn` / `initialSortAscending` /
`onSortChanged` round it out. Sorting remaps selection to follow rows.

## Filtering (typed, per-column)

The controller derives visible rows as `sort(filter(master))`; selection lives in
master space and is pruned each rebuild — filter/sort/select compose.

**Ready-made flat bar** — one flag:

```dart
ReadableTable<Account>(controller: c, showFilterBar: true,
  filterItemNoun: 'account', filterItemNounPlural: 'accounts');
// or place it yourself: ReadableFilterBar<Account>(controller: c)
```

A `ReadableFilter` is one predicate over a logical column (op + operands +
`enabled`). Offered ops depend on `ReadableColumnType` (text: contains/startsWith/
isEmpty · number: greater/less/between · enum: anyOf · date: before/after/between).

```dart
c.addFilter(ReadableFilter.text(1, ReadableFilterOp.contains, 'cash'));
c.addFilter(ReadableFilter.number(6, ReadableFilterOp.between, 0, 5e4));
c.addFilter(ReadableFilter.anyOf(2, {'Asset', 'Income'}));
c.setFilterJoin(ReadableFilterJoin.any);   // OR (default AND)
c.setQuery('rajhi');                         // cross-column quick search
c.clearFilters();
```

Filter API: `addFilter · insertFilterAt · updateFilterAt · removeFilterAt ·
toggleFilterAt · setFilters · clearFilters · setFilterJoin · setQuery`.
Reads: `filters · filterJoin · query · isFiltered · hasFilters · rowCount`
(visible) vs `totalRowCount · isColumnFilterable(ci) · distinctValues(ci)`.

**Nested query builder** — `A AND (B OR (C AND D))`:

```dart
ReadableFilterEditingView<Deal>(controller: c);   // applies live; applyLive:false to defer
c.setFilterGroup(ReadableFilterGroup(join: ReadableFilterJoin.all, children: [
  ReadableFilter.text(colOwner, ReadableFilterOp.equals, 'Davon Larson'),
  ReadableFilterGroup(join: ReadableFilterJoin.any, children: [
    ReadableFilter(columnIndex: colHealth, op: ReadableFilterOp.equals, value: 'Critical'),
    ReadableFilter.number(colValue, ReadableFilterOp.greater, 100000),
  ]),
]));
```

A non-empty tree **supersedes** the flat `filters` list; quick-search still
applies on top.

**Inline column filters** (header filter row):

```dart
ReadableTable<Deal>(controller: c, showColumnFilters: true);
c.setColumnSearch(ci, 'cash'); c.setColumnFilter(ci, ReadableFilter…);
c.columnFilter(ci); c.hasColumnFilters; c.clearColumnFilters();
```

## Driving it — `ReadableTableController<T>`

Intention-revealing ops by **index · value · where · firstWhere**:

```dart
final c = ReadableTableController<Account>(columns: columns, rows: accounts,
  selectionMode: ReadableSelectionMode.multiRow);

c.selectRowsWhere((a) => a.type == 'Expense');
c.addRowWhere((a) => a.type == 'Asset', newAccount);   // after match
c.deleteRowByValue(oldAccount);
c.replaceFirstWhere((a) => a.type == 'Asset', (a) => a.copyWith(balance: a.balance*1.1));
c.sortByColumn(ci); c.clearSort(); c.setRows(values);

c.resizeColumn(1, 30); c.resetColumnWidth(1); c.moveColumn(3, 0); c.widthOf(0);
await c.copySelectionToClipboard(includeHeader: true);   // TSV

ReadableTable<Account>(controller: c);
ReadableTableController.of<Account>(context)?.deleteSelectedRows();
```

Select: `selectRowAt · selectRowByValue · selectRowsWhere · selectAllRows ·
clearSelection`. Add: `insertRowAt · addRowWhere · addRow`. Delete:
`deleteRowAt · deleteRowsWhere · deleteRowByValue · deleteSelectedRows`.
Replace: `replaceRowAt · replaceRowByValue · replaceRowsWhere · replaceFirstWhere`.

## Options

```dart
ReadableTable<T>(
  controller: c,                          // or columns + rows
  selectionMode: ReadableSelectionMode.none,
  showHeader: true, zebra: false, hoverHighlight: true,
  rowMinHeight: 52,
  cellPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  onRowTap: (value, index) {},
  emptyState: const Text('No rows'),
);
```

Defaults reproduce a plain non-interactive ledger — opting into a mode changes
nothing until you do.

## Keyboard (press ? or ⌘/Ctrl + /)

`↑↓`/`←→` move row/cell · `Space` toggle/select · `⇧+arrows` extend · `⌘/Ctrl+A`
select all · `Enter` activate (`onRowTap`) · `Home/End`, `⌘+Home/End` edges ·
`Esc` clear.

## Gotchas

- It's **read-only** — for editing use EditableTable.
- Theme is `EditableTableThemeData` (shared), not a separate Readable theme.
- A non-empty **filter tree** overrides the flat `filters` list.
- Selection is reported as **values** (`List<T>`), not indices.

## Reference

- **Examples (read first):** `EXAMPLES.md` in this folder — professional, varied, copy-ready scenarios.
- Demo: `example/lib/readable_table*` · filter demos under `example/lib/readable_table/`
- Interactive: `docs/components-readable-table.html`, `docs/components-filter-editing.html`
- Source: `lib/design_system/components/data/readable_table*.dart`
