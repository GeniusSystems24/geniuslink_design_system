// ============================================================
// EditableTable — demo gallery.
// Shows the SAME widget configured two ways, now exercising the five new
// customisation hooks:
//   1. Keyboard shortcuts  — full set + the ⌘/ reference popup (in-widget)
//   2. confirmDelete       — optional delete-confirmation popup (toggle below)
//   3. Tab grows the table — Tab on the last cell appends a row (growOnTab)
//   4. cellBuilder         — the account "Type" cell renders as a colour chip
//   5. cellValidator       — row-aware rules: qty > 0, and Line Total must
//                            equal Qty × Unit Price (validated against siblings)
//   File: example/lib/editable_table_demo.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:geniuslink_design_system/geniuslink_editable_table.dart';

class EditableTableDemo extends StatefulWidget {
  const EditableTableDemo({super.key});
  @override
  State<EditableTableDemo> createState() => _EditableTableDemoState();
}

class _EditableTableDemoState extends State<EditableTableDemo> {
  bool _light = true;
  bool _confirmDelete = true;

  // colour for an account type chip (feature 4: cellBuilder)
  static Color _typeColor(String type) {
    switch (type) {
      case 'Asset':
      case 'Income':
        return EditableTableThemeData.success;
      case 'Liability':
        return EditableTableThemeData.danger;
      case 'Expense':
        return EditableTableThemeData.warning;
      default:
        return EditableTableThemeData.accent; // Equity
    }
  }

  // ── chart-of-accounts schema (number + select + chip cellBuilder) ──
  List<EditableColumn> get _accountCols => [
        const EditableColumn(key: 'code', label: 'Code', width: 110, mono: true, required: true),
        const EditableColumn(key: 'name', label: 'Account', width: 230, required: true),
        EditableColumn(
          key: 'type',
          label: 'Type',
          width: 150,
          type: EditableColumnType.select,
          options: const ['Asset', 'Liability', 'Equity', 'Income', 'Expense'],
          // feature 4 — render the value as a tappable colour chip.
          cellBuilder: (context, cell) {
            if (cell.value.isEmpty) return const SizedBox.shrink();
            final c = _typeColor(cell.value);
            return GestureDetector(
              onTap: cell.requestEdit,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: c.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: c.withOpacity(0.5)),
                ),
                child: Text(cell.value,
                    style: TextStyle(
                        fontFamily: EditableTableThemeData.bodyFont,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: c)),
              ),
            );
          },
        ),
        EditableColumn(
          key: 'bal',
          label: 'Balance',
          width: 150,
          mono: true,
          type: EditableColumnType.number,
          includeInTotal: true,
          // feature 5 — simple value validator (no negatives).
          validate: (v) {
            final n = EditableTableFormat.parseNumber(v);
            if (n != null && n < 0) return 'No negatives';
            return null;
          },
        ),
      ];

  final _accountRows = const [
    {'code': '1001', 'name': 'Cash Box', 'type': 'Asset', 'bal': '42,500.00'},
    {'code': '1100', 'name': 'Bank · NCB Main', 'type': 'Asset', 'bal': '186,420.00'},
    {'code': '2001', 'name': 'Accounts Payable', 'type': 'Liability', 'bal': '23,140.00'},
    {'code': '4001', 'name': 'Sales Revenue', 'type': 'Income', 'bal': '89,200.00'},
  ];

  // ── invoice line-items schema (row-aware cross-column validation) ──
  List<EditableColumn> get _lineCols => [
        const EditableColumn(key: 'item', label: 'Item', width: 230, required: true),
        EditableColumn(
          key: 'qty',
          label: 'Qty',
          width: 90,
          type: EditableColumnType.number,
          // feature 5 — must be a positive whole number.
          cellValidator: (v, row) {
            final n = EditableTableFormat.parseNumber(v);
            if (n == null || n <= 0) return 'Qty > 0';
            if (n != n.roundToDouble()) return 'Whole number';
            return null;
          },
        ),
        const EditableColumn(key: 'price', label: 'Unit Price', width: 130, mono: true, type: EditableColumnType.number),
        EditableColumn(
          key: 'total',
          label: 'Line Total',
          width: 140,
          mono: true,
          type: EditableColumnType.number,
          includeInTotal: true,
          // feature 5 — row-aware: Total must equal Qty × Unit Price.
          cellValidator: (v, row) {
            final qty = EditableTableFormat.parseNumber(row['qty'] ?? '');
            final price = EditableTableFormat.parseNumber(row['price'] ?? '');
            final total = EditableTableFormat.parseNumber(v);
            if (qty == null || price == null || total == null) return null;
            if ((qty * price - total).abs() > 0.01) return '≠ Qty × Price';
            return null;
          },
        ),
      ];

  final _lineRows = const [
    {'item': 'Design retainer', 'qty': '1', 'price': '8,000.00', 'total': '8,000.00'},
    {'item': 'Frontend build (hrs)', 'qty': '40', 'price': '320.00', 'total': '12,800.00'},
    {'item': 'QA & handoff', 'qty': '1', 'price': '2,500.00', 'total': '2,500.00'},
  ];

  // ── one column of every kind (the new typed columns) ──
  List<EditableColumn> get _allCols => [
        const ReadonlyColumn(key: 'id', label: 'ID', width: 70, mono: true),
        const EditableColumn(key: 'task', label: 'Task', width: 190, required: true),
        const NumericColumn(key: 'qty', label: 'Qty', width: 80, min: 0, decimals: 0),
        const NumericColumn(key: 'price', label: 'Price', width: 110, min: 0, decimals: 2),
        ComputedColumn(
          key: 'total',
          label: 'Total',
          width: 120,
          mono: true,
          align: CellAlign.end,
          includeInTotal: true,
          compute: (r) {
            final q = EditableTableFormat.parseNumber(r['qty'] ?? '') ?? 0;
            final p = EditableTableFormat.parseNumber(r['price'] ?? '') ?? 0;
            return EditableTableFormat.formatNumber(q * p);
          },
        ),
        const DateColumn(key: 'due', label: 'Due date', width: 140),
        const TimeColumn(key: 'at', label: 'At', width: 100),
        const DropdownColumn(key: 'status', label: 'Status', width: 130, options: ['Open', 'Active', 'Done']),
        const ComboBoxColumn(key: 'tag', label: 'Tag', width: 150, options: ['Design', 'Build', 'QA', 'Research']),
        const ColorPickerColumn(key: 'color', label: 'Colour', width: 150),
      ];

  final _allRows = const [
    {'id': '001', 'task': 'Wireframes', 'qty': '2', 'price': '500.00', 'due': '2024-11-20', 'at': '09:30', 'status': 'Done', 'tag': 'Design', 'color': '#4A7CFF'},
    {'id': '002', 'task': 'Component build', 'qty': '8', 'price': '320.00', 'due': '2024-12-02', 'at': '14:00', 'status': 'Active', 'tag': 'Build', 'color': '#1DB88A'},
    {'id': '003', 'task': 'Accessibility pass', 'qty': '1', 'price': '900.00', 'due': '2024-12-10', 'at': '11:15', 'status': 'Open', 'tag': 'QA', 'color': '#F97316'},
  ];

  int _accountCount = 4;

  @override
  Widget build(BuildContext context) {
    final ext = _light ? EditableTableThemeData.light : EditableTableThemeData.dark;
    return Theme(
      data: ThemeData(
        brightness: _light ? Brightness.light : Brightness.dark,
        useMaterial3: true,
        fontFamily: EditableTableThemeData.bodyFont,
        scaffoldBackgroundColor: ext.bg,
        extensions: [ext],
      ),
      child: Builder(builder: (context) {
        final t = EditableTableThemeData.of(context);
        return Scaffold(
          backgroundColor: t.bg,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(28, 40, 28, 80),
                  children: [
                    // header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('GENIUSLINK DESIGN SYSTEM',
                                  style: TextStyle(
                                      fontFamily: EditableTableThemeData.bodyFont,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.6,
                                      color: EditableTableThemeData.accent)),
                              const SizedBox(height: 10),
                              Text('EditableTable',
                                  style: TextStyle(
                                      fontFamily: EditableTableThemeData.displayFont,
                                      fontSize: 34,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.6,
                                      color: t.fg1)),
                              const SizedBox(height: 8),
                              Text(
                                'Customisable, Excel-style data-entry grid — built MVC. Full keyboard control '
                                '(press the ⌨ button or ⌘/ for the cheatsheet), optional delete confirmation, '
                                'Tab-to-grow, per-column chip renderers and row-aware validation.',
                                style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 14, height: 1.5, color: t.fg3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        _ThemeToggle(light: _light, onChanged: (v) => setState(() => _light = v)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // options row
                    _OptionRow(
                      label: 'Confirm before delete',
                      sub: 'Shows a popup; turn off to delete instantly',
                      value: _confirmDelete,
                      onChanged: (v) => setState(() => _confirmDelete = v),
                    ),
                    const SizedBox(height: 28),

                    // chart of accounts
                    _SectionTitle('Chart of accounts',
                        '$_accountCount rows · Type renders as a chip (cellBuilder) · Balance rejects negatives', t),
                    const SizedBox(height: 14),
                    EditableTable(
                      columns: _accountCols,
                      initialRows: List<EditableRow>.from(_accountRows.map((e) => Map<String, String>.from(e))),
                      showTotals: true,
                      unitLabel: 'SAR',
                      confirmDelete: _confirmDelete,
                      onChanged: (rows) => setState(() => _accountCount = rows.length),
                    ),

                    const SizedBox(height: 40),

                    // invoice line items
                    _SectionTitle('Invoice line items',
                        'Row-aware validation: Qty > 0, and Line Total must equal Qty × Unit Price · Tab past the last cell to add a row', t),
                    const SizedBox(height: 14),
                    EditableTable(
                      columns: _lineCols,
                      initialRows: List<EditableRow>.from(_lineRows.map((e) => Map<String, String>.from(e))),
                      showTotals: true,
                      totalsLabel: 'Subtotal',
                      unitLabel: 'SAR',
                      confirmDelete: _confirmDelete,
                      // growOnTab defaults to true — try Tab on the bottom-right cell.
                    ),

                    const SizedBox(height: 40),

                    // every column type
                    _SectionTitle('Every column type',
                        'Readonly · text · NumericColumn (min/decimals) · ComputedColumn · DateColumn · TimeColumn · DropdownColumn · ComboBoxColumn · ColorPickerColumn — scroll right', t),
                    const SizedBox(height: 14),
                    EditableTable(
                      columns: _allCols,
                      initialRows: List<EditableRow>.from(_allRows.map((e) => Map<String, String>.from(e))),
                      showTotals: true,
                      totalsLabel: 'Total',
                      unitLabel: 'SAR',
                      confirmDelete: _confirmDelete,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title, sub;
  final EditableTableThemeData t;
  const _SectionTitle(this.title, this.sub, this.t);
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontFamily: EditableTableThemeData.displayFont, fontSize: 18, fontWeight: FontWeight.w700, color: t.fg1)),
        const SizedBox(height: 3),
        Text(sub, style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 12.5, height: 1.4, color: t.fg3)),
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  final String label, sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _OptionRow({required this.label, required this.sub, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final t = EditableTableThemeData.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(EditableTableThemeData.radiusLg),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontFamily: EditableTableThemeData.bodyFont, fontSize: 13.5, fontWeight: FontWeight.w600, color: t.fg1)),
                const SizedBox(height: 2),
                Text(sub, style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 12, color: t.fg3)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: EditableTableThemeData.accent,
          ),
        ],
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  final bool light;
  final ValueChanged<bool> onChanged;
  const _ThemeToggle({required this.light, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final t = EditableTableThemeData.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onChanged(!light),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: t.surface,
            border: Border.all(color: t.border),
            borderRadius: BorderRadius.circular(EditableTableThemeData.radiusMd),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(light ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 15, color: t.fg2),
            const SizedBox(width: 8),
            Text(light ? 'Light' : 'Dark',
                style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 13, fontWeight: FontWeight.w600, color: t.fg1)),
          ]),
        ),
      ),
    );
  }
}
