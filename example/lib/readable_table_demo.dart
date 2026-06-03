// ============================================================
// ReadableTable — demo gallery (generic · MVC).
// A read-only display grid of a typed `Account` value, driven by a
// ReadableTableController<Account>. Exercises the full interaction layer:
//   1. Selection modes — none · singleRow · multiRow · singleCell · multiCell
//      (segmented control → controller.setSelectionMode)
//   2. Keyboard        — arrows move, Shift extends, Space toggles, ⌘/Ctrl+A
//      selects all, Esc clears, ? cheatsheet (focus the table first)
//   3. Column sort     — click a sortable header; numeric vs string via sortKey
//   4. Controller ops  — select / add / delete / replace by index · value ·
//      where · firstWhere, wired to the buttons below the table
//   File: example/lib/readable_table_demo.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:geniuslink_design_system/geniuslink_readable_table.dart';

// ── the typed row value ──
class Account {
  final String code, name, arabic, type, nature;
  final double balance;
  const Account(this.code, this.name, this.arabic, this.type, this.nature, this.balance);

  Account copyWith({double? balance}) =>
      Account(code, name, arabic, type, nature, balance ?? this.balance);
}

class ReadableTableDemo extends StatefulWidget {
  const ReadableTableDemo({super.key});
  @override
  State<ReadableTableDemo> createState() => _ReadableTableDemoState();
}

class _ReadableTableDemoState extends State<ReadableTableDemo> {
  bool _light = true;
  late ReadableTableController<Account> _controller;
  int _seq = 0; // for unique synthetic codes

  static const _seed = [
    Account('1001', 'Cash Box', 'صندوق النقد', 'Asset', 'DR', 42500.00),
    Account('1100', 'Bank · NCB Main', 'بنك الأهلي', 'Asset', 'DR', 186420.00),
    Account('2001', 'Accounts Payable', 'الذمم الدائنة', 'Liability', 'CR', 23140.00),
    Account('3001', 'Share Capital', 'رأس المال', 'Equity', 'CR', 500000.00),
    Account('4001', 'Sales Revenue', 'إيرادات المبيعات', 'Income', 'CR', 289200.00),
    Account('5001', 'Cost of Goods Sold', 'تكلفة البضاعة', 'Expense', 'DR', 142800.00),
    Account('5200', 'Salaries Expense', 'مصروف الرواتب', 'Expense', 'DR', 96400.00),
  ];

  @override
  void initState() {
    super.initState();
    _controller = ReadableTableController<Account>(
      columns: _columns(),
      rows: List<Account>.from(_seed),
      selectionMode: ReadableSelectionMode.multiRow,
      selectedRows: const {0},
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

  double get _maxBal => _seed.map((a) => a.balance).reduce((a, b) => a > b ? a : b);

  String _fmt(double n) {
    final s = n.toStringAsFixed(2);
    final p = s.split('.');
    final intPart = p[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
    return '$intPart.${p[1]}';
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

  // ── typed columns: each renders itself from an Account ──
  List<ReadableColumn<Account>> _columns() => [
        ReadableColumn<Account>(
          'Code',
          width: 80,
          sortable: true,
          sortKey: (a) => a.code,
          cell: (ctx, a) => Text(a.code,
              style: TextStyle(
                  fontFamily: EditableTableThemeData.monoFont,
                  fontSize: 12.5,
                  color: EditableTableThemeData.of(ctx).fg3)),
        ),
        ReadableColumn<Account>(
          'Account',
          flex: 3,
          sortable: true,
          sortKey: (a) => a.name.toLowerCase(),
          cell: (ctx, a) {
            final t = EditableTableThemeData.of(ctx);
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 13.5, fontWeight: FontWeight.w600, color: t.fg1)),
                const SizedBox(height: 2),
                Text(a.arabic,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 11.5, color: t.fg3)),
              ],
            );
          },
        ),
        ReadableColumn<Account>(
          'Type',
          width: 120,
          sortable: true,
          sortKey: (a) => a.type,
          cell: (ctx, a) => _Chip(label: a.type, color: _typeColor(a.type)),
        ),
        ReadableColumn<Account>(
          'Nature',
          width: 86,
          align: ReadableAlign.center,
          sortable: true,
          sortKey: (a) => a.nature,
          cell: (ctx, a) => _Pill(label: a.nature, color: a.nature == 'DR' ? EditableTableThemeData.accent : EditableTableThemeData.warning),
        ),
        ReadableColumn<Account>(
          'Balance',
          width: 150,
          align: ReadableAlign.end,
          sortable: true,
          sortKey: (a) => a.balance, // numeric sort
          cell: (ctx, a) {
            final t = EditableTableThemeData.of(ctx);
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_fmt(a.balance),
                    style: TextStyle(fontFamily: EditableTableThemeData.monoFont, fontSize: 12.5, fontWeight: FontWeight.w600, color: t.fg1)),
                const SizedBox(height: 5),
                SizedBox(
                  width: 110,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: (a.balance / _maxBal).clamp(0.02, 1),
                      minHeight: 3,
                      backgroundColor: t.inputBg,
                      valueColor: AlwaysStoppedAnimation(_typeColor(a.type).withOpacity(0.8)),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ];

  // ── controller-op handlers (select / add / delete / replace) ──
  void _selectExpenses() => _controller.selectRowsWhere((a) => a.type == 'Expense');

  void _addRowAfterAssets() {
    _seq++;
    final acc = Account('90${_seq.toString().padLeft(2, '0')}', 'New Ledger $_seq', 'حساب جديد', 'Asset', 'DR', 1000.0 * _seq);
    // ADD by where — insert after the last Asset; falls back to end.
    if (_controller.rows.any((a) => a.type == 'Asset')) {
      _controller.addRowWhere((a) => a.type == 'Asset', acc, after: true, firstOnly: false);
    } else {
      _controller.addRow(acc); // ADD by end
    }
  }

  void _deleteSelected() {
    if (_controller.selectedRowIndices.isNotEmpty) {
      _controller.deleteSelectedRows();
    } else {
      // DELETE by where — drop every zero/low balance as a fallback demo
      _controller.deleteRowsWhere((a) => a.balance < 50000);
    }
  }

  void _bumpFirstAsset() {
    // REPLACE by firstWhere — first Asset gets +10%.
    _controller.replaceFirstWhere(
      (a) => a.type == 'Asset',
      (a) => a.copyWith(balance: a.balance * 1.1),
    );
  }

  void _reset() => _controller.setRows(List<Account>.from(_seed));

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
                                'Generic, MVC, read-only display grid — typed over `Account`. A '
                                'ReadableTableController owns the rows; the buttons below drive it with '
                                'select / add / delete / replace by index · value · where · firstWhere. '
                                'Five selection modes, full keyboard control (focus the table, then arrows / '
                                'Shift / Space / ⌘A / Esc — ? for the cheatsheet) and click-to-sort headers.',
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

                    _ModePicker(
                      mode: _controller.selectionMode,
                      onChanged: (m) => _controller.setSelectionMode(m),
                    ),
                    const SizedBox(height: 14),

                    // live selection readout (from the controller)
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
                              _controller.selectionMode == ReadableSelectionMode.none
                                  ? 'Display only — no selection layer'
                                  : _summary(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontFamily: EditableTableThemeData.monoFont, fontSize: 11.5, color: t.fg3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // the table — driven by the external controller
                    ReadableTable<Account>(
                      controller: _controller,
                      hoverHighlight: true,
                      rowMinHeight: 56,
                      onRowTap: (a, i) => debugPrint('tapped ${a.code}'),
                    ),
                    const SizedBox(height: 16),

                    // controller-op buttons
                    Text('CONTROLLER OPERATIONS',
                        style: TextStyle(
                            fontFamily: EditableTableThemeData.bodyFont, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: t.fg3)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _OpButton(icon: Icons.filter_alt_outlined, label: 'Select where type = Expense', onTap: _selectExpenses),
                        _OpButton(icon: Icons.add_rounded, label: 'Add after Assets', onTap: _addRowAfterAssets),
                        _OpButton(icon: Icons.delete_outline_rounded, label: 'Delete selected', onTap: _deleteSelected),
                        _OpButton(icon: Icons.trending_up_rounded, label: 'Replace first Asset +10%', onTap: _bumpFirstAsset),
                        _OpButton(icon: Icons.restart_alt_rounded, label: 'Reset rows', onTap: _reset),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text('Tip — click the table, then use the keyboard. Click any sortable header to sort.',
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
    return _controller.selectedRows.map((a) => a.code).take(8).join('  ');
  }
}

// ── chip / pill cells ──
class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label,
          style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
      child: Text(label,
          style: TextStyle(fontFamily: EditableTableThemeData.monoFont, fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
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
