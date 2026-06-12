# ReadableTable — professional examples

Realistic, varied recipes. Each assumes the import + `EditableTableThemeData`
registration from the skill (ReadableTable shares that theme).

---

## 1 · Accounts ledger with the ready-made filter bar

Typed column factories give formatting + sort keys for free. `showFilterBar`
mounts quick-search + chips + AND/OR + a live count.

```dart
@immutable
class Account {
  final String code, name, type, hex; final double balance; final DateTime opened;
  const Account(this.code, this.name, this.type, this.balance, this.opened, this.hex);
}

class Ledger extends StatefulWidget {
  const Ledger({super.key, required this.accounts});
  final List<Account> accounts;
  @override State<Ledger> createState() => _LedgerState();
}

class _LedgerState extends State<Ledger> {
  late final ReadableTableController<Account> c = ReadableTableController<Account>(
    selectionMode: ReadableSelectionMode.multiRow,
    columns: [
      ReadableColumn.text('Code', value: (a) => a.code, width: 90),
      ReadableColumn.text('Account', value: (a) => a.name, flex: 2),
      ReadableColumn.enumBadge('Type', value: (a) => a.type,
        color: (t) => {'Asset': const Color(0xFF1DB88A), 'Expense': const Color(0xFFF97316)}[t] ?? const Color(0xFF4A7CFF)),
      ReadableColumn.date('Opened', value: (a) => a.opened),
      ReadableColumn.color('Tag', hex: (a) => a.hex),
      ReadableColumn.number('Balance', value: (a) => a.balance, decimals: 2, colorSign: true, align: ReadableAlign.end),
    ],
    rows: widget.accounts,
  );

  @override
  Widget build(BuildContext context) => ReadableTable<Account>(
    controller: c,
    showFilterBar: true,
    filterItemNoun: 'account', filterItemNounPlural: 'accounts',
    onRowSelectionChanged: (rows) => debugPrint('${rows.length} selected'),
    onRowTap: (a, i) => openLedger(a),
  );

  @override void dispose() { c.dispose(); super.dispose(); }
}
```

Drive filters from code (e.g. a saved view):

```dart
c.addFilter(ReadableFilter.anyOf(2, {'Asset', 'Income'}));        // Type is any of …
c.addFilter(ReadableFilter.number(5, ReadableFilterOp.between, 0, 5e4));  // Balance 0–50k
c.setFilterJoin(ReadableFilterJoin.all);
c.setQuery('rajhi');
```

---

## 2 · CRM deals board — nested query builder (`A AND (B OR C)`)

Drop the Attio/Notion-style builder beside the grid; it edits the controller's
filter *tree* and applies live.

```dart
final deals = ReadableTableController<Deal>(columns: dealColumns, rows: allDeals);

// seed a structured filter (or let the user build it):
const colOwner = 1, colHealth = 3, colValue = 4;
deals.setFilterGroup(ReadableFilterGroup(join: ReadableFilterJoin.all, children: [
  ReadableFilter.text(colOwner, ReadableFilterOp.equals, 'Davon Larson'),
  ReadableFilterGroup(join: ReadableFilterJoin.any, children: [
    ReadableFilter(columnIndex: colHealth, op: ReadableFilterOp.equals, value: 'Critical'),
    ReadableFilter.number(colValue, ReadableFilterOp.greater, 100000),
  ]),
]));

Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
  SizedBox(width: 360, child: ReadableFilterEditingView<Deal>(controller: deals)),  // applies live
  const SizedBox(width: 16),
  Expanded(child: ReadableTable<Deal>(controller: deals)),
]);
```

---

## 3 · Inline header filter row + bulk action

`showColumnFilters` gives one control under each header (search field or value
dropdown). Combine with `selectRowsWhere` for a bulk operation.

```dart
final c = ReadableTableController<Account>(columns: cols, rows: rows,
  selectionMode: ReadableSelectionMode.multiRow);

List<Account> _selected = const [];

ReadableTable<Account>(
  controller: c,
  showColumnFilters: true,
  onRowSelectionChanged: (rows) => _selected = rows,   // reports the selected values (List<T>)
);

// later — act on the captured selection:
void archiveSelected() {
  for (final a in _selected) api.archive(a);
}

// or select-by-predicate, then read it back from the callback:
c.selectRowsWhere((a) => a.type == 'Expense');

// programmatic column filters:
c.setColumnSearch(1, 'cash');                 // Account contains "cash"
c.setColumnFilter(2, ReadableFilter.anyOf(2, {'Asset'}));
c.clearColumnFilters();
```

---

## 4 · A grid of pre-built widgets (`ReadableTable<List<Widget>>`)

When you already have rendered cells (e.g. migrating a legacy `List<List<Widget>>`
table), make `T = List<Widget>` and return `value[i]` per column.

```dart
ReadableTable<List<Widget>>(
  columns: [
    ReadableColumn('Customer', flex: 2, cell: (ctx, row) => row[0]),
    ReadableColumn('Plan',     width: 120, cell: (ctx, row) => row[1]),
    ReadableColumn('MRR', align: ReadableAlign.end, width: 120, cell: (ctx, row) => row[2]),
  ],
  rows: [
    [const Text('Northwind'), const Chip(label: Text('Pro')), const Text('\$1,200')],
    [const Text('Globex'),    const Chip(label: Text('Team')), const Text('\$480')],
  ],
  zebra: true,
  hoverHighlight: true,
  emptyState: const Center(child: Text('No customers yet')),
);
```

---

## 5 · Two-line bilingual cells + progress + link

```dart
ReadableTable<Project>(
  rowMinHeight: 60,
  columns: [
    ReadableColumn.text('Project', value: (p) => p.nameEn, secondary: (p) => p.nameAr, flex: 2),
    ReadableColumn.progress('Completion', value: (p) => p.ratio),       // labelled bar 0..1
    ReadableColumn.number('Budget', value: (p) => p.budget, decimals: 0, align: ReadableAlign.end),
    ReadableColumn.link('Brief', text: (p) => p.docRef, onTap: (p) => openDoc(p)),
  ],
  rows: projects,
  selectionMode: ReadableSelectionMode.singleRow,
  onRowTap: (p, i) => openProject(p),
);
```
