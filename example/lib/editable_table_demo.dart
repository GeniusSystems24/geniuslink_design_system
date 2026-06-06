// ============================================================
// EditableTable<T> — demo gallery (GENERIC typed rows).
// A strongly-typed invoice editor: rows are an immutable `InvoiceRow`, not a
// Map. Exercises every new requirement of the generic table:
//   • Generic row type      — EditableTable<InvoiceRow> over a List<InvoiceRow>
//   • Typed model           — value/setValue accessors, copyWith, no casts
//   • In-table editing       — text · number · date · dropdown · checkbox
//   • Column resize          — drag a header's trailing edge (double-tap resets)
//   • Column reorder         — long-press a header and drag it
//   • Copy cells/rows (TSV)  — ⌘C copies the active cell; toolbar copies rows
//   • Keyboard nav + LTR/RTL — arrows follow the VISUAL direction (RTL toggle)
//   • Scroll-on-focus        — Tab/arrows pull the active cell into view
//   File: example/lib/editable_table_demo.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:geniuslink_design_system/geniuslink_editable_table_generic.dart';

// ════════════════════════════════════════════════════════════
// The typed row — immutable, with copyWith. THIS is the model the table edits.
// ════════════════════════════════════════════════════════════
@immutable
class InvoiceRow {
  final String id;
  final String item;
  final String category; // Service · Hardware · License · Travel · Support
  final int qty;
  final double unitPrice;
  final double discountPct;
  final DateTime? due;
  final bool paid;

  const InvoiceRow({
    required this.id,
    required this.item,
    required this.category,
    required this.qty,
    required this.unitPrice,
    required this.discountPct,
    required this.due,
    required this.paid,
  });

  /// The derived line total — a real computed property of the typed row.
  double get net => qty * unitPrice * (1 - discountPct / 100);

  InvoiceRow copyWith({
    String? id,
    String? item,
    String? category,
    int? qty,
    double? unitPrice,
    double? discountPct,
    Object? due = _sentinel,
    bool? paid,
  }) =>
      InvoiceRow(
        id: id ?? this.id,
        item: item ?? this.item,
        category: category ?? this.category,
        qty: qty ?? this.qty,
        unitPrice: unitPrice ?? this.unitPrice,
        discountPct: discountPct ?? this.discountPct,
        due: due == _sentinel ? this.due : due as DateTime?,
        paid: paid ?? this.paid,
      );

  static const Object _sentinel = Object();
}

const _categories = ['Service', 'Hardware', 'License', 'Travel', 'Support'];

String _iso(DateTime? d) =>
    d == null ? '' : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime? _parseIso(String s) {
  final m = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(s.trim());
  if (m == null) return null;
  final y = int.parse(m.group(1)!), mo = int.parse(m.group(2)!), da = int.parse(m.group(3)!);
  if (mo < 1 || mo > 12 || da < 1 || da > 31) return null;
  return DateTime(y, mo, da);
}

class EditableTableDemo extends StatefulWidget {
  const EditableTableDemo({super.key});
  @override
  State<EditableTableDemo> createState() => _EditableTableDemoState();
}

class _EditableTableDemoState extends State<EditableTableDemo> {
  bool _light = true;
  bool _rtl = false;
  late EditableTableController<InvoiceRow> _controller;
  int _newSeq = 0;
  String _tsvPreview = '';

  @override
  void initState() {
    super.initState();
    _controller = EditableTableController<InvoiceRow>(
      columns: _columns(),
      rows: _seed(),
      selectionMode: EditableSelectionMode.multiRow,
      newRow: () {
        _newSeq++;
        return InvoiceRow(
            id: 'NEW-$_newSeq', item: '', category: 'Service', qty: 1, unitPrice: 0, discountPct: 0, due: null, paid: false);
      },
    );
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 26 rows — enough to scroll vertically and exercise scroll-on-focus.
  List<InvoiceRow> _seed() {
    const items = [
      'Design retainer', 'Frontend build', 'Backend API', 'QA automation', 'Cloud hosting',
      'SSL certificate', 'Domain renewal', 'On-site training', 'Data migration', 'Security audit',
      'Mobile build', 'Accessibility pass', 'Load testing', 'Analytics setup', 'CMS license',
      'Support hours', 'Server hardware', 'Network switch', 'Travel · Riyadh', 'Travel · Jeddah',
      'Workshop facilitation', 'Penetration test', 'Backup service', 'Monitoring license',
      'Performance tuning', 'Content audit',
    ];
    final cats = ['Service', 'Service', 'Service', 'Service', 'License', 'License', 'License', 'Service',
      'Service', 'Service', 'Service', 'Service', 'Service', 'Service', 'License', 'Support',
      'Hardware', 'Hardware', 'Travel', 'Travel', 'Service', 'Service', 'License', 'License', 'Service', 'Service'];
    final base = DateTime(2025, 1, 6);
    return [
      for (var i = 0; i < items.length; i++)
        InvoiceRow(
          id: 'INV-${(101 + i)}',
          item: items[i],
          category: cats[i],
          qty: 1 + (i * 3) % 12,
          unitPrice: 250.0 + (i % 9) * 175.0,
          discountPct: (i % 4 == 0) ? 10 : 0,
          due: base.add(Duration(days: i * 5)),
          paid: i % 3 == 0,
        ),
    ];
  }

  Color _catColor(String c) {
    switch (c) {
      case 'Hardware':
        return EditableTableThemeData.warning;
      case 'License':
        return EditableTableThemeData.accent;
      case 'Travel':
        return EditableTableThemeData.danger;
      case 'Support':
        return const Color(0xFF8C5BE6);
      default:
        return EditableTableThemeData.success; // Service
    }
  }

  List<EditableColumn<InvoiceRow>> _columns() => [
        // read-only id (no setValue)
        EditableColumn<InvoiceRow>(
          label: 'Invoice',
          width: 96,
          mono: true,
          type: EditableColumnType.readonly,
          value: (r) => r.id,
          sortKey: (r) => r.id,
        ),
        // text
        EditableColumn<InvoiceRow>(
          label: 'Item',
          width: 200,
          required: true,
          value: (r) => r.item,
          setValue: (r, v) => r.copyWith(item: v),
          sortKey: (r) => r.item.toLowerCase(),
        ),
        // enum / dropdown — rendered as a coloured chip
        DropdownColumn<InvoiceRow>(
          label: 'Category',
          width: 138,
          options: _categories,
          value: (r) => r.category,
          setValue: (r, v) => r.copyWith(category: v),
          sortKey: (r) => r.category,
          cellBuilder: (ctx, cell) {
            final c = _catColor(cell.value);
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
                        fontFamily: EditableTableThemeData.bodyFont, fontSize: 11.5, fontWeight: FontWeight.w700, color: c)),
              ),
            );
          },
        ),
        // number (integer)
        NumericColumn<InvoiceRow>(
          label: 'Qty',
          width: 76,
          decimals: 0,
          min: 0,
          value: (r) => '${r.qty}',
          setValue: (r, v) => r.copyWith(qty: int.tryParse(v.replaceAll(',', '')) ?? r.qty),
          sortKey: (r) => r.qty,
          validate: (v) => (int.tryParse(v.replaceAll(',', '')) ?? -1) < 0 ? '≥ 0' : null,
        ),
        // number (money)
        NumericColumn<InvoiceRow>(
          label: 'Unit price',
          width: 116,
          decimals: 2,
          min: 0,
          value: (r) => r.unitPrice.toStringAsFixed(2),
          setValue: (r, v) => r.copyWith(unitPrice: double.tryParse(v.replaceAll(',', '')) ?? r.unitPrice),
          sortKey: (r) => r.unitPrice,
        ),
        // number (percent)
        NumericColumn<InvoiceRow>(
          label: 'Disc %',
          width: 86,
          decimals: 0,
          min: 0,
          max: 100,
          value: (r) => r.discountPct.toStringAsFixed(0),
          setValue: (r, v) => r.copyWith(discountPct: double.tryParse(v) ?? r.discountPct),
          sortKey: (r) => r.discountPct,
        ),
        // computed (read-only, summed in the footer)
        ComputedColumn<InvoiceRow>(
          label: 'Net total',
          width: 128,
          includeInTotal: true,
          compute: (r) => EditableTableFormat.formatNumber(r.net),
          sortKey: (r) => r.net,
        ),
        // date
        DateColumn<InvoiceRow>(
          label: 'Due date',
          width: 132,
          value: (r) => _iso(r.due),
          setValue: (r, v) => r.copyWith(due: _parseIso(v)),
          sortKey: (r) => _iso(r.due),
        ),
        // boolean / checkbox
        CheckboxColumn<InvoiceRow>(
          label: 'Paid',
          width: 78,
          value: (r) => r.paid ? '1' : '0',
          setValue: (r, v) => r.copyWith(paid: EditableTableController.truthy(v)),
          sortKey: (r) => r.paid ? 1 : 0,
        ),
      ];

  double get _grandTotal => _controller.rows.fold(0.0, (s, r) => s + r.net);
  int get _paidCount => _controller.rows.where((r) => r.paid).length;

  String _selectionSummary() {
    final c = _controller;
    if (c.selectionMode == EditableSelectionMode.none) return 'Selection off';
    if (c.selectionIsCellMode) {
      return c.selectedCells.map((s) => '${c.rowAt(s.row).id}·${EditableTableFormat.columnLetter(s.col)}').take(8).join('  ');
    }
    return c.selectedRows.map((r) => r.id).take(10).join('  ');
  }

  Future<void> _copySelection() async {
    final n = await _controller.copySelectionTsvToClipboard(includeHeader: _controller.selectionIsRowMode);
    setState(() => _tsvPreview = n == 0 ? '' : _controller.selectionAsTsv(includeHeader: _controller.selectionIsRowMode));
    if (mounted && n > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Copied $n line(s) as TSV'), duration: const Duration(seconds: 2)),
      );
    }
  }

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
        final sel = _controller.selection;
        final selRow = _controller.rowCount > 0 ? _controller.rowAt(sel.row) : null;
        return Scaffold(
          backgroundColor: t.bg,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(28, 36, 28, 80),
                  children: [
                    // ── header ──
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
                              Text('EditableTable<InvoiceRow>',
                                  style: TextStyle(
                                      fontFamily: EditableTableThemeData.displayFont,
                                      fontSize: 31,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.6,
                                      color: t.fg1)),
                              const SizedBox(height: 8),
                              Text(
                                'A strongly-typed grid — each row is an immutable InvoiceRow, edited through '
                                'value / setValue accessors (no Map). Click a cell and type to edit; Tab / Enter '
                                'commit and move; drag a header edge to resize; long-press a header to reorder. '
                                'Pick a selection mode (rows / cells, single / multi) then click · Shift-click · '
                                '⌘/Ctrl-click to select; ⌘C copies the selection as TSV. Toggle RTL to see arrows follow the visual direction.',
                                style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 14, height: 1.5, color: t.fg3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(children: [
                          _MiniToggle(
                              on: _light,
                              onIcon: Icons.light_mode_outlined,
                              offIcon: Icons.dark_mode_outlined,
                              onLabel: 'Light',
                              offLabel: 'Dark',
                              onChanged: (v) => setState(() => _light = v)),
                          const SizedBox(height: 8),
                          _MiniToggle(
                              on: _rtl,
                              onIcon: Icons.format_textdirection_r_to_l_rounded,
                              offIcon: Icons.format_textdirection_l_to_r_rounded,
                              onLabel: 'RTL',
                              offLabel: 'LTR',
                              onChanged: (v) => setState(() => _rtl = v)),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // ── selection-mode picker ──
                    Row(
                      children: [
                        Text('SELECT',
                            style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: t.fg3)),
                        const SizedBox(width: 12),
                        Expanded(child: _ModePicker(mode: _controller.selectionMode, onChanged: (m) => _controller.setSelectionMode(m))),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── live typed-data inspector ──
                    _Inspector(
                      t: t,
                      lines: [
                        _InspectorLine('Rows', '${_controller.rowCount}  ·  $_paidCount paid  ·  net ${EditableTableFormat.formatNumber(_grandTotal)} SAR'),
                        _InspectorLine('Selection',
                            _controller.selectionMode == EditableSelectionMode.none ? 'off' : '${_controller.selectedCount} selected   ${_selectionSummary()}'),
                        _InspectorLine('Active cell',
                            'row ${sel.row + 1} · ${EditableTableFormat.columnLetter(sel.col)} (${_controller.columns[sel.col].label})'),
                        _InspectorLine('Active InvoiceRow',
                            selRow == null ? '—' : '${selRow.id} · ${selRow.item.isEmpty ? '(empty)' : selRow.item} · qty ${selRow.qty} · net ${EditableTableFormat.formatNumber(selRow.net)}'),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // ── feature buttons ──
                    Wrap(
                      spacing: 9,
                      runSpacing: 9,
                      children: [
                        _OpButton(icon: Icons.copy_all_rounded, label: 'Copy selection (TSV)', onTap: _copySelection),
                        _OpButton(icon: Icons.select_all_rounded, label: 'Select all', onTap: () => _controller.selectAll()),
                        _OpButton(icon: Icons.deselect_rounded, label: 'Clear selection', onTap: () => _controller.clearSelection()),
                        _OpButton(
                            icon: Icons.delete_sweep_outlined,
                            label: 'Delete selected rows',
                            onTap: () => _controller.deleteSelectedRows()),
                        _OpButton(icon: Icons.add_rounded, label: 'Add row', onTap: () => _controller.addRow()),
                        _OpButton(icon: Icons.restart_alt_rounded, label: 'Reset', onTap: () {
                          _controller.setRows(_seed());
                          setState(() => _tsvPreview = '');
                        }),
                      ],
                    ),

                    if (_tsvPreview.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _TsvPreview(t: t, tsv: _tsvPreview),
                    ],
                    const SizedBox(height: 18),

                    // ── the typed table (wrapped in the chosen direction) ──
                    Directionality(
                      textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
                      child: EditableTable<InvoiceRow>(
                        controller: _controller,
                        bodyHeight: 360,
                        totalsLabel: 'Total',
                      ),
                    ),
                    const SizedBox(height: 16),

                    _Legend(t: t),
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

// ── live inspector card ──
class _InspectorLine {
  final String label, value;
  _InspectorLine(this.label, this.value);
}

class _Inspector extends StatelessWidget {
  final EditableTableThemeData t;
  final List<_InspectorLine> lines;
  const _Inspector({required this.t, required this.lines});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(EditableTableThemeData.radiusLg),
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0) Divider(height: 15, color: t.border),
            Row(
              children: [
                SizedBox(
                  width: 132,
                  child: Text(lines[i].label,
                      style: TextStyle(
                          fontFamily: EditableTableThemeData.bodyFont,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: t.fg3)),
                ),
                Expanded(
                  child: Text(lines[i].value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: EditableTableThemeData.monoFont, fontSize: 12.5, color: t.fg1)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final EditableTableThemeData t;
  const _Legend({required this.t});
  @override
  Widget build(BuildContext context) {
    const tips = [
      ['Edit', 'Click a cell + type, or double-click / Enter. Tab → · Enter ↓ commit & move.'],
      ['Select', 'Pick a mode above, then click · Shift-click (range) · ⌘/Ctrl-click (toggle) · ⌘A all.'],
      ['Resize', 'Drag a header\'s trailing edge. Double-tap the grip to reset.'],
      ['Reorder', 'Long-press a header and drag it onto another (blue drop line).'],
      ['Sort', 'Click a header to sort by its typed key (asc → desc).'],
      ['Copy', '⌘/Ctrl + C copies the selection (rows or a cell rectangle) as TSV.'],
      ['Keyboard', 'Arrows / Tab move (RTL-mirrored) · Shift+arrows extend · Space toggles Paid · ⌘Z undo.'],
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: BorderRadius.circular(EditableTableThemeData.radiusLg),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < tips.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 74,
                  child: Text(tips[i][0],
                      style: TextStyle(
                          fontFamily: EditableTableThemeData.bodyFont,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: EditableTableThemeData.accent)),
                ),
                Expanded(
                  child: Text(tips[i][1],
                      style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 12.5, height: 1.45, color: t.fg2)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _OpButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OpButton({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final t = EditableTableThemeData.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: t.surface,
            border: Border.all(color: t.border),
            borderRadius: BorderRadius.circular(EditableTableThemeData.radiusMd),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 15, color: EditableTableThemeData.accent),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontFamily: EditableTableThemeData.bodyFont, fontSize: 12.5, fontWeight: FontWeight.w600, color: t.fg1)),
          ]),
        ),
      ),
    );
  }
}

class _MiniToggle extends StatelessWidget {
  final bool on;
  final IconData onIcon, offIcon;
  final String onLabel, offLabel;
  final ValueChanged<bool> onChanged;
  const _MiniToggle({
    required this.on,
    required this.onIcon,
    required this.offIcon,
    required this.onLabel,
    required this.offLabel,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final t = EditableTableThemeData.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onChanged(!on),
        child: Container(
          width: 96,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: t.surface,
            border: Border.all(color: t.border),
            borderRadius: BorderRadius.circular(EditableTableThemeData.radiusMd),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(on ? onIcon : offIcon, size: 15, color: t.fg2),
            const SizedBox(width: 8),
            Text(on ? onLabel : offLabel,
                style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 13, fontWeight: FontWeight.w600, color: t.fg1)),
          ]),
        ),
      ),
    );
  }
}

// ── 5-mode selection picker (segmented) ──
class _ModePicker extends StatelessWidget {
  final EditableSelectionMode mode;
  final ValueChanged<EditableSelectionMode> onChanged;
  const _ModePicker({required this.mode, required this.onChanged});

  static const _labels = {
    EditableSelectionMode.none: 'None',
    EditableSelectionMode.singleRow: 'Single Row',
    EditableSelectionMode.multiRow: 'Multi Row',
    EditableSelectionMode.singleCell: 'Single Cell',
    EditableSelectionMode.multiCell: 'Multi Cell',
  };

  @override
  Widget build(BuildContext context) {
    final t = EditableTableThemeData.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: BorderRadius.circular(EditableTableThemeData.radiusLg),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          for (final m in EditableSelectionMode.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(m),
                child: AnimatedContainer(
                  duration: EditableTableThemeData.durFast,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: mode == m ? EditableTableThemeData.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(EditableTableThemeData.radiusMd),
                  ),
                  child: Text(_labels[m]!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: EditableTableThemeData.bodyFont,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: mode == m ? Colors.white : t.fg2)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── clipboard TSV preview card ──
class _TsvPreview extends StatelessWidget {
  final EditableTableThemeData t;
  final String tsv;
  const _TsvPreview({required this.t, required this.tsv});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: BorderRadius.circular(EditableTableThemeData.radiusLg),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.content_paste_rounded, size: 14, color: EditableTableThemeData.accent),
            const SizedBox(width: 7),
            Text('CLIPBOARD (TSV) — tabs shown as ⇥',
                style: TextStyle(
                    fontFamily: EditableTableThemeData.bodyFont, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1, color: t.fg3)),
          ]),
          const SizedBox(height: 10),
          SelectableText(
            tsv.replaceAll('\t', ' ⇥ '),
            style: TextStyle(fontFamily: EditableTableThemeData.monoFont, fontSize: 11.5, height: 1.5, color: t.fg2),
          ),
        ],
      ),
    );
  }
}