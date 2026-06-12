# EditableTable — professional examples

Realistic, varied recipes. Each is self-contained; assume the import and theme
registration from the skill are in place.

---

## 1 · Invoice line-items editor (computed totals + cross-column validation)

A classic data-entry grid: typed columns, a derived `Total`, a footer that sums,
and a row-aware validator that flags a tampered line total.

```dart
class InvoiceLines extends StatelessWidget {
  const InvoiceLines({super.key});

  static String _money(num n) => EditableTableFormat.formatNumber(n);
  static num _num(String? s) => EditableTableFormat.parseNumber(s ?? '') ?? 0;

  @override
  Widget build(BuildContext context) {
    return EditableTable(
      columns: [
        const ReadonlyColumn(key: 'sku', label: 'SKU', mono: true, width: 110),
        const EditableColumn(key: 'item', label: 'Description', required: true),
        const NumericColumn(key: 'qty', label: 'Qty', min: 0, decimals: 0, width: 90),
        const NumericColumn(key: 'price', label: 'Unit price', min: 0, decimals: 2),
        ComputedColumn(
          key: 'total', label: 'Line total', includeInTotal: true,
          compute: (r) => _money(_num(r['qty']) * _num(r['price'])),
        ),
        // Allow a manual override but flag it if it disagrees with qty × price.
        EditableColumn(
          key: 'override', label: 'Billed', 
          cellValidator: (value, row) {
            if (value.trim().isEmpty) return null;
            final expected = _num(row['qty']) * _num(row['price']);
            return (_num(value) - expected).abs() > 0.01 ? '≠ Qty × Price' : null;
          },
        ),
      ],
      initialRows: const [
        {'sku': 'DSK-01', 'item': 'Standing desk', 'qty': '2', 'price': '1850.00'},
        {'sku': 'CHR-04', 'item': 'Ergonomic chair', 'qty': '4', 'price': '920.00'},
      ],
      showTotals: true,
      totalsLabel: 'Subtotal',
      unitLabel: 'SAR',
      growOnTab: true,             // Tab past the last cell appends a line
      onChanged: (rows) => debugPrint('${rows.length} lines'),
    );
  }
}
```

---

## 2 · Typed `EditableTable<T>` — product price list with an async vendor combo

Use the **generic** barrel when each row is a real model. Note the async
`fetchOptions` on the combo (local-first, loads more on miss) and a
`CheckboxColumn`.

```dart
import 'package:geniuslink_design_system/geniuslink_editable_table_generic.dart';

@immutable
class PriceRow {
  final String name; final int qty; final double cost; final String vendor; final bool active;
  const PriceRow({required this.name, this.qty = 0, this.cost = 0, this.vendor = '', this.active = true});
  PriceRow copyWith({String? name, int? qty, double? cost, String? vendor, bool? active}) => PriceRow(
    name: name ?? this.name, qty: qty ?? this.qty, cost: cost ?? this.cost,
    vendor: vendor ?? this.vendor, active: active ?? this.active);
}

class PriceListEditor extends StatefulWidget {
  const PriceListEditor({super.key});
  @override State<PriceListEditor> createState() => _PriceListEditorState();
}

class _PriceListEditorState extends State<PriceListEditor> {
  late final EditableTableController<PriceRow> c = EditableTableController<PriceRow>(
    columns: [
      EditableColumn(label: 'Product', value: (r) => r.name, setValue: (r, v) => r.copyWith(name: v)),
      NumericColumn(label: 'Qty', decimals: 0, value: (r) => '${r.qty}',
        setValue: (r, v) => r.copyWith(qty: int.tryParse(v) ?? r.qty)),
      NumericColumn(label: 'Cost', decimals: 2, includeInTotal: true, value: (r) => r.cost.toStringAsFixed(2),
        setValue: (r, v) => r.copyWith(cost: double.tryParse(v) ?? r.cost)),
      ComboBoxColumn(
        label: 'Vendor',
        options: const ['Acme Corp', 'Globex', 'Initech'],   // shown instantly
        fetchOptions: (q) => _searchVendors(q),               // loaded on miss
        remoteMinChars: 1,
        value: (r) => r.vendor, setValue: (r, v) => r.copyWith(vendor: v),
      ),
      CheckboxColumn(label: 'Active', value: (r) => r.active ? '1' : '0',
        setValue: (r, v) => r.copyWith(active: v == '1')),
    ],
    rows: const [
      PriceRow(name: 'Toner cartridge', qty: 50, cost: 38.0, vendor: 'Globex'),
      PriceRow(name: 'A4 paper (box)', qty: 120, cost: 22.5, vendor: 'Acme Corp'),
    ],
    newRow: () => const PriceRow(name: ''),               // enables Add-row + Tab-to-grow
    selectionMode: EditableSelectionMode.multiRow,         // Shift/⌘-click ranges; ⌘C copies TSV
  );

  static Future<List<String>> _searchVendors(String q) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    const all = ['Soylent', 'Umbrella', 'Stark Supplies', 'Wayne Ent.', 'Cyberdyne'];
    return all.where((v) => v.toLowerCase().contains(q.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    Row(children: [
      FilledButton.icon(onPressed: c.addRow, icon: const Icon(Icons.add), label: const Text('Add product')),
      const SizedBox(width: 8),
      OutlinedButton(onPressed: c.deleteSelectedRows, child: const Text('Delete selected')),
      const Spacer(),
      IconButton(onPressed: c.canUndo ? c.undo : null, icon: const Icon(Icons.undo)),
      IconButton(onPressed: c.canRedo ? c.redo : null, icon: const Icon(Icons.redo)),
    ]),
    const SizedBox(height: 8),
    Expanded(child: EditableTable<PriceRow>(controller: c, showTotals: true, unitLabel: 'SAR')),
  ]);

  @override void dispose() { c.dispose(); super.dispose(); }
}
```

---

## 3 · Status as a coloured chip via `cellBuilder` (cell stays editable)

```dart
DropdownColumn(
  key: 'status', label: 'Status', options: const ['Open', 'Active', 'Done'],
  cellBuilder: (context, cell) {
    const tones = {'Open': Color(0xFFF97316), 'Active': Color(0xFF4A7CFF), 'Done': Color(0xFF1DB88A)};
    final tone = tones[cell.value] ?? Theme.of(context).disabledColor;
    return GestureDetector(
      onTap: cell.requestEdit,                       // tap the chip to open the dropdown
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: tone.withOpacity(0.14), borderRadius: BorderRadius.circular(999)),
        child: Text(cell.value.isEmpty ? '—' : cell.value,
          style: TextStyle(color: tone, fontWeight: FontWeight.w700, fontSize: 12)),
      ),
    );
  },
);
```

---

## 4 · Arabic / RTL budget sheet, driven from a controller

```dart
final budget = EditableTableController(
  columns: const [
    EditableColumn(key: 'bnd', label: 'البند', required: true),
    NumericColumn(key: 'mizan', label: 'المبلغ', min: 0, decimals: 2, includeInTotal: true),
  ],
  rows: const [
    {'bnd': 'الرواتب', 'mizan': '120,000.00'},
    {'bnd': 'الإيجار', 'mizan': '35,000.00'},
  ],
);

Directionality(
  textDirection: TextDirection.rtl,            // header, gutter, handles, arrows all mirror
  child: EditableTable(controller: budget, showTotals: true, totalsLabel: 'الإجمالي', unitLabel: 'ر.س'),
);

// load from your API in one undoable step:
Future<void> reload() async => budget.setRows(await api.loadBudget());
```
