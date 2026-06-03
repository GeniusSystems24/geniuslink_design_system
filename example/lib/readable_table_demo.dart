// ============================================================
// ReadableTable — demo gallery.
// The read-only display grid exercised across its interaction layer:
//   1. Selection modes — none · singleRow · multiRow · singleCell · multiCell
//      (switch live with the segmented control)
//   2. Keyboard        — arrows move, Shift extends, Space toggles, ⌘/Ctrl+A
//      selects all, Esc clears, ? shows the cheatsheet (focus the table first)
//   3. Column sort     — click a sortable header to cycle asc → desc; the
//      Balance / Qty columns sort numerically, text columns alphabetically;
//      the Status pill column sorts via a custom sortKeyOf
//   4. Rich widget cells — status pills, two-line bilingual text, progress
//      bars — all survive selection + sorting untouched
//   File: example/lib/readable_table_demo.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:geniuslink_design_system/geniuslink_readable_table.dart';

class ReadableTableDemo extends StatefulWidget {
  const ReadableTableDemo({super.key});
  @override
  State<ReadableTableDemo> createState() => _ReadableTableDemoState();
}

class _ReadableTableDemoState extends State<ReadableTableDemo> {
  bool _light = true;
  ReadableSelectionMode _mode = ReadableSelectionMode.multiRow;

  Set<int> _selRows = {0};
  Set<ReadableCell> _selCells = {};

  // ── data: chart-of-accounts ledger ──
  static const _accounts = [
    // code, name, arabic, type, nature, balance
    ['1001', 'Cash Box', 'صندوق النقد', 'Asset', 'DR', 42500.00],
    ['1100', 'Bank · NCB Main', 'بنك الأهلي', 'Asset', 'DR', 186420.00],
    ['2001', 'Accounts Payable', 'الذمم الدائنة', 'Liability', 'CR', 23140.00],
    ['3001', 'Share Capital', 'رأس المال', 'Equity', 'CR', 500000.00],
    ['4001', 'Sales Revenue', 'إيرادات المبيعات', 'Income', 'CR', 289200.00],
    ['5001', 'Cost of Goods Sold', 'تكلفة البضاعة', 'Expense', 'DR', 142800.00],
    ['5200', 'Salaries Expense', 'مصروف الرواتب', 'Expense', 'DR', 96400.00],
  ];

  double get _maxBal => _accounts.map((a) => a[5] as double).reduce((a, b) => a > b ? a : b);

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

  // ── cells ──
  List<List<Widget>> _buildRows(EditableTableThemeData t) {
    return [
      for (final a in _accounts)
        [
          // code (mono)
          Text(a[0] as String, style: TextStyle(fontFamily: EditableTableThemeData.monoFont, fontSize: 12.5, color: t.fg3)),
          // two-line bilingual name
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a[1] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 13.5, fontWeight: FontWeight.w600, color: t.fg1)),
              const SizedBox(height: 2),
              Text(a[2] as String,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 11.5, color: t.fg3)),
            ],
          ),
          // type chip
          _Chip(label: a[3] as String, color: _typeColor(a[3] as String)),
          // nature pill (DR/CR)
          _Pill(label: a[4] as String, color: a[4] == 'DR' ? EditableTableThemeData.accent : EditableTableThemeData.warning),
          // balance + share bar
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_fmt(a[5] as double),
                  style: TextStyle(fontFamily: EditableTableThemeData.monoFont, fontSize: 12.5, fontWeight: FontWeight.w600, color: t.fg1)),
              const SizedBox(height: 5),
              SizedBox(
                width: 110,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: ((a[5] as double) / _maxBal).clamp(0.02, 1),
                    minHeight: 3,
                    backgroundColor: t.inputBg,
                    valueColor: AlwaysStoppedAnimation(_typeColor(a[3] as String).withOpacity(0.8)),
                  ),
                ),
              ),
            ],
          ),
        ],
    ];
  }

  // Custom sort keys for the non-text cells (Type chip, Nature pill, Balance).
  Comparable? _sortKeyOf(int row, int col) {
    final a = _accounts[row];
    switch (col) {
      case 0:
        return a[0] as String; // code (string, but stable)
      case 1:
        return (a[1] as String).toLowerCase(); // name
      case 2:
        return a[3] as String; // type
      case 3:
        return a[4] as String; // nature DR/CR
      case 4:
        return a[5] as double; // balance — numeric
      default:
        return null;
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
        final selCount = _mode == ReadableSelectionMode.singleCell || _mode == ReadableSelectionMode.multiCell
            ? _selCells.length
            : _selRows.length;
        return Scaffold(
          backgroundColor: t.bg,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
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
                              Text('ReadableTable',
                                  style: TextStyle(
                                      fontFamily: EditableTableThemeData.displayFont,
                                      fontSize: 34,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.6,
                                      color: t.fg1)),
                              const SizedBox(height: 8),
                              Text(
                                'Read-only display grid sharing the EditableTable look. Five selection modes, '
                                'full keyboard control (focus the table, then arrows / Shift / Space / ⌘A / Esc — '
                                'press ? for the cheatsheet) and click-to-sort headers. Rich widget cells — pills, '
                                'bilingual text, progress bars — survive selection and sorting.',
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

                    // selection-mode segmented control
                    _ModePicker(
                      mode: _mode,
                      onChanged: (m) => setState(() {
                        _mode = m;
                        _selRows = {};
                        _selCells = {};
                      }),
                    ),
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
                          Text('$selCount selected',
                              style: TextStyle(
                                  fontFamily: EditableTableThemeData.bodyFont, fontSize: 13.5, fontWeight: FontWeight.w600, color: t.fg1)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _mode == ReadableSelectionMode.none
                                  ? 'Display only — no selection layer'
                                  : _selectionSummary(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontFamily: EditableTableThemeData.monoFont, fontSize: 11.5, color: t.fg3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // the table
                    ReadableTable(
                      key: ValueKey(_mode), // reset internal state on mode change
                      selectionMode: _mode,
                      hoverHighlight: true,
                      rowMinHeight: 56,
                      initialSelectedRows: _selRows,
                      initialSelectedCells: _selCells,
                      onRowSelectionChanged: (s) => setState(() => _selRows = s),
                      onCellSelectionChanged: (s) => setState(() => _selCells = s),
                      sortKeyOf: _sortKeyOf,
                      columns: const [
                        ReadableColumn('Code', width: 80, sortable: true),
                        ReadableColumn('Account', flex: 3, sortable: true),
                        ReadableColumn('Type', width: 120, sortable: true),
                        ReadableColumn('Nature', width: 86, align: ReadableAlign.center, sortable: true),
                        ReadableColumn('Balance', width: 150, align: ReadableAlign.end, sortable: true),
                      ],
                      rows: _buildRows(t),
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

  String _selectionSummary() {
    if (_mode == ReadableSelectionMode.singleCell || _mode == ReadableSelectionMode.multiCell) {
      final codes = _selCells.map((c) => '${_accounts[c.row][0]}·C${c.col}').take(6).join('  ');
      return codes;
    }
    final codes = (_selRows.toList()..sort()).map((r) => _accounts[r][0] as String).take(8).join('  ');
    return codes;
  }
}

// ── chip / pill used as rich cells ──
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
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(fontFamily: EditableTableThemeData.monoFont, fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
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
