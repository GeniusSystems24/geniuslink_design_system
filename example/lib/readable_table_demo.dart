// ============================================================
// ReadableTable — demo gallery (generic · MVC · read-only).
// A typed `Account` display grid driven by ReadableTableController<Account>.
// Exercises every requirement of the read-only table:
//   • Column KINDS    — ReadableColumn.text / .number / .enumBadge / .date +
//                       a boolean (check) column + a progress column
//   • Selection modes — none · singleRow · multiRow · singleCell · multiCell
//   • Keyboard + RTL  — arrows follow the VISUAL direction (RTL toggle);
//                       Shift extends, Space toggles, ⌘/Ctrl+A all, Esc clears
//   • Scroll-on-focus — navigating to an off-screen row pulls it into view
//   • Resize / reorder— drag a header edge to resize, long-press to reorder
//   • Copy (TSV)      — ⌘C, or the Copy button → selection as tab-separated text
//   File: example/lib/readable_table_demo.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:geniuslink_design_system/geniuslink_readable_table.dart';

// ── the typed row value (now with a date + boolean field) ──
class Account {
  final String code, name, arabic, type, nature;
  final double balance;
  final DateTime opened;
  final bool active;
  final double utilisation; // 0..1
  const Account(this.code, this.name, this.arabic, this.type, this.nature, this.balance, this.opened, this.active,
      this.utilisation);

  Account copyWith({double? balance, bool? active}) =>
      Account(code, name, arabic, type, nature, balance ?? this.balance, opened, active ?? this.active, utilisation);
}

class ReadableTableDemo extends StatefulWidget {
  const ReadableTableDemo({super.key});
  @override
  State<ReadableTableDemo> createState() => _ReadableTableDemoState();
}

class _ReadableTableDemoState extends State<ReadableTableDemo> {
  bool _light = true;
  bool _rtl = false;
  late ReadableTableController<Account> _controller;
  int _seq = 0;
  String _tsvPreview = '';

  // 24 rows — enough to scroll and to exercise scroll-on-focus.
  static final List<Account> _seed = _buildSeed();

  static List<Account> _buildSeed() {
    const base = [
      ['1001', 'Cash Box', 'صندوق النقد', 'Asset', 'DR', 42500.0],
      ['1100', 'Bank · NCB Main', 'بنك الأهلي', 'Asset', 'DR', 186420.0],
      ['1110', 'Bank · Rajhi', 'بنك الراجحي', 'Asset', 'DR', 98230.0],
      ['1200', 'Accounts Receivable', 'الذمم المدينة', 'Asset', 'DR', 64120.0],
      ['1300', 'Inventory', 'المخزون', 'Asset', 'DR', 132900.0],
      ['1500', 'Fixed Assets', 'الأصول الثابتة', 'Asset', 'DR', 410000.0],
      ['2001', 'Accounts Payable', 'الذمم الدائنة', 'Liability', 'CR', 23140.0],
      ['2100', 'VAT Payable', 'ضريبة القيمة المضافة', 'Liability', 'CR', 18750.0],
      ['2200', 'Short-term Loan', 'قرض قصير الأجل', 'Liability', 'CR', 75000.0],
      ['2300', 'Accrued Salaries', 'رواتب مستحقة', 'Liability', 'CR', 31200.0],
      ['3001', 'Share Capital', 'رأس المال', 'Equity', 'CR', 500000.0],
      ['3100', 'Retained Earnings', 'أرباح محتجزة', 'Equity', 'CR', 212400.0],
      ['4001', 'Sales Revenue', 'إيرادات المبيعات', 'Income', 'CR', 289200.0],
      ['4100', 'Service Revenue', 'إيرادات الخدمات', 'Income', 'CR', 154300.0],
      ['4200', 'Other Income', 'إيرادات أخرى', 'Income', 'CR', 22800.0],
      ['5001', 'Cost of Goods Sold', 'تكلفة البضاعة', 'Expense', 'DR', 142800.0],
      ['5200', 'Salaries Expense', 'مصروف الرواتب', 'Expense', 'DR', 96400.0],
      ['5300', 'Rent Expense', 'مصروف الإيجار', 'Expense', 'DR', 48000.0],
      ['5400', 'Utilities', 'المرافق', 'Expense', 'DR', 19600.0],
      ['5500', 'Marketing', 'التسويق', 'Expense', 'DR', 53400.0],
      ['5600', 'Depreciation', 'الإهلاك', 'Expense', 'DR', 41000.0],
      ['5700', 'Software Subscriptions', 'اشتراكات البرامج', 'Expense', 'DR', 27300.0],
      ['5800', 'Travel', 'السفر', 'Expense', 'DR', 16850.0],
      ['5900', 'Professional Fees', 'أتعاب مهنية', 'Expense', 'DR', 38900.0],
    ];
    final d0 = DateTime(2021, 1, 1);
    return [
      for (var i = 0; i < base.length; i++)
        Account(
          base[i][0] as String,
          base[i][1] as String,
          base[i][2] as String,
          base[i][3] as String,
          base[i][4] as String,
          base[i][5] as double,
          d0.add(Duration(days: i * 47)),
          i % 5 != 0,
          ((base[i][5] as double) / 500000.0).clamp(0.03, 1),
        ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _controller = ReadableTableController<Account>(
      columns: _columns(),
      rows: List<Account>.from(_seed),
      selectionMode: ReadableSelectionMode.multiRow,
      selectedRows: const {0, 1},
      sortColumn: 4,
      sortAscending: false,
    );
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _typeColor(String type) {
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

  // ── typed columns using the REAL ReadableColumn.<kind> factories ──
  List<ReadableColumn<Account>> _columns() => [
        // TEXT (mono code)
        ReadableColumn<Account>(
          'Code',
          width: 84,
          sortable: true,
          sortKey: (a) => a.code,
          copyText: (a) => a.code,
          cell: (ctx, a) => Text(a.code,
              style: TextStyle(
                  fontFamily: EditableTableThemeData.monoFont, fontSize: 12.5, color: EditableTableThemeData.of(ctx).fg3)),
        ),
        // TEXT (two-line / bilingual) — via the factory
        ReadableColumn.text<Account>(
          'Account',
          value: (a) => a.name,
          secondary: (a) => a.arabic,
          flex: 3,
          sortable: true,
        ),
        // ENUM badge — coloured pill
        ReadableColumn.enumBadge<Account>(
          'Type',
          value: (a) => a.type,
          color: _typeColor,
          width: 116,
        ),
        // BOOLEAN — a check / dash, with a flat copyText
        ReadableColumn<Account>(
          'Active',
          width: 84,
          align: ReadableAlign.center,
          sortable: true,
          sortKey: (a) => a.active ? 1 : 0,
          copyText: (a) => a.active ? 'yes' : 'no',
          cell: (ctx, a) {
            final t = EditableTableThemeData.of(ctx);
            return Icon(a.active ? Icons.check_circle_rounded : Icons.remove_circle_outline_rounded,
                size: 17, color: a.active ? EditableTableThemeData.success : t.fg4);
          },
        ),
        // DATE — via the factory (ISO mono)
        ReadableColumn.date<Account>(
          'Opened',
          value: (a) => a.opened,
          width: 116,
        ),
        // PROGRESS — labelled bar
        ReadableColumn.progress<Account>(
          'Utilisation',
          value: (a) => a.utilisation,
          width: 132,
        ),
        // NUMBER — grouped, 2 decimals, right-aligned mono
        ReadableColumn.number<Account>(
          'Balance',
          value: (a) => a.balance,
          decimals: 2,
          width: 138,
        ),
      ];

  // ── controller-op handlers ──
  void _selectExpenses() => _controller.selectRowsWhere((a) => a.type == 'Expense');

  // Programmatic filtering — same API the filter bar drives. Column 6 is Balance.
  void _filterBigBalances() => _controller.setFilters([
        ReadableFilter.number(6, ReadableFilterOp.greater, 100000),
      ]);

  void _addRow() {
    _seq++;
    final acc = Account('90${_seq.toString().padLeft(2, '0')}', 'New Ledger $_seq', 'حساب جديد', 'Asset', 'DR',
        1000.0 * _seq, DateTime.now(), true, 0.2);
    if (_controller.rows.any((a) => a.type == 'Asset')) {
      _controller.addRowWhere((a) => a.type == 'Asset', acc, after: true, firstOnly: false);
    } else {
      _controller.addRow(acc);
    }
  }

  void _deleteSelected() {
    if (_controller.selectedRowIndices.isNotEmpty) {
      _controller.deleteSelectedRows();
    } else {
      _controller.deleteRowsWhere((a) => a.balance < 25000);
    }
  }

  Future<void> _copySelection() async {
    final n = await _controller.copySelectionToClipboard(includeHeader: true);
    setState(() => _tsvPreview = n == 0 ? '(nothing selected)' : _controller.copySelectionAsTsv(includeHeader: true));
    if (mounted && n > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Copied $n line(s) as TSV to the clipboard'), duration: const Duration(seconds: 2)),
      );
    }
  }

  void _reset() {
    _controller.clearFilters();
    _controller.setRows(List<Account>.from(_seed));
    setState(() => _tsvPreview = '');
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
        return Scaffold(
          backgroundColor: t.bg,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(28, 40, 28, 80),
                  children: [
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
                              Text('ReadableTable',
                                  style: TextStyle(
                                      fontFamily: EditableTableThemeData.displayFont,
                                      fontSize: 34,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.6,
                                      color: t.fg1)),
                              const SizedBox(height: 8),
                              Text(
                                'Generic read-only grid typed over Account — 24 rows. Columns use the typed '
                                'ReadableColumn factories: text · enum-badge · boolean · date · progress · number. '
                                'Pick a selection mode, then click / Shift-click / ⌘-click rows or cells; drag a '
                                'header edge to resize and long-press a header to reorder; ⌘C (or Copy) exports the '
                                'selection as TSV. Toggle RTL to see arrow keys follow the visual direction.',
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
                    const SizedBox(height: 24),

                    _ModePicker(mode: _controller.selectionMode, onChanged: (m) => _controller.setSelectionMode(m)),
                    const SizedBox(height: 14),

                    // live selection readout
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: t.surface,
                        borderRadius: BorderRadius.circular(EditableTableThemeData.radiusLg),
                        border: Border.all(color: t.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 16, color: EditableTableThemeData.accent),
                          const SizedBox(width: 9),
                          Text('${_controller.selectedCount} selected',
                              style: TextStyle(
                                  fontFamily: EditableTableThemeData.bodyFont, fontSize: 13.5, fontWeight: FontWeight.w600, color: t.fg1)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _controller.selectionMode == ReadableSelectionMode.none ? 'Display only — no selection layer' : _summary(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontFamily: EditableTableThemeData.monoFont, fontSize: 11.5, color: t.fg3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // the table — wrapped in the chosen direction, with the
                    // advanced filter bar mounted above it.
                    Directionality(
                      textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ReadableFilterBar<Account>(
                            controller: _controller,
                            searchHint: 'Search accounts…',
                            itemNoun: 'account',
                            itemNounPlural: 'accounts',
                          ),
                          const SizedBox(height: 12),
                          ReadableTable<Account>(
                            controller: _controller,
                            hoverHighlight: true,
                            rowMinHeight: 54,
                            onRowTap: (a, i) => debugPrint('tapped ${a.code}'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text('CONTROLLER OPERATIONS',
                        style: TextStyle(
                            fontFamily: EditableTableThemeData.bodyFont, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: t.fg3)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _OpButton(icon: Icons.filter_alt_outlined, label: 'Select Expenses', onTap: _selectExpenses),
                        _OpButton(icon: Icons.select_all_rounded, label: 'Select all', onTap: () => _controller.selectAllRows()),
                        _OpButton(icon: Icons.bolt_rounded, label: 'Filter: balance > 100k', onTap: _filterBigBalances),
                        _OpButton(icon: Icons.copy_all_rounded, label: 'Copy selection (TSV)', onTap: _copySelection),
                        _OpButton(icon: Icons.add_rounded, label: 'Add after Assets', onTap: _addRow),
                        _OpButton(icon: Icons.delete_outline_rounded, label: 'Delete selected', onTap: _deleteSelected),
                        _OpButton(icon: Icons.restart_alt_rounded, label: 'Reset', onTap: _reset),
                      ],
                    ),

                    if (_tsvPreview.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _TsvPreview(t: t, tsv: _tsvPreview),
                    ],

                    const SizedBox(height: 14),
                    Text(
                        'Tip — click the table, then use the keyboard: ↑↓ move · Shift extends · Space toggles · ⌘/Ctrl+A all · ⌘C copy · Esc clear · ? cheatsheet.',
                        style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 12.5, color: t.fg3)),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  String _summary() {
    final mode = _controller.selectionMode;
    if (mode == ReadableSelectionMode.singleCell || mode == ReadableSelectionMode.multiCell) {
      return _controller.selectedCells.map((c) => '${_controller.rowAt(c.row).code}·C${c.col}').take(6).join('  ');
    }
    return _controller.selectedRows.map((a) => a.code).take(10).join('  ');
  }
}

// ── TSV preview card ──
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
            Text(label, style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 12.5, fontWeight: FontWeight.w600, color: t.fg1)),
          ]),
        ),
      ),
    );
  }
}

class _ModePicker extends StatelessWidget {
  final ReadableSelectionMode mode;
  final ValueChanged<ReadableSelectionMode> onChanged;
  const _ModePicker({required this.mode, required this.onChanged});

  static const _labels = {
    ReadableSelectionMode.none: 'None',
    ReadableSelectionMode.singleRow: 'Single Row',
    ReadableSelectionMode.multiRow: 'Multi Row',
    ReadableSelectionMode.singleCell: 'Single Cell',
    ReadableSelectionMode.multiCell: 'Multi Cell',
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
          for (final m in ReadableSelectionMode.values)
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
