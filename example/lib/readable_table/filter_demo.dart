// ============================================================
// ReadableTable — FILTER SYSTEM preview (standalone).
// A focused demo of the advanced filter layer: a typed `Account` grid with a
// ReadableFilterBar mounted above it. Exercises the whole system —
//   • Quick search   — cross-column substring match
//   • Filter chips    — per-column predicates with the typed editor
//                       (text · enum · number · date operands)
//   • AND / OR        — toggle how chips combine
//   • Enable / disable — keep a chip but stop applying it (the dot)
//   • Programmatic    — preset buttons drive controller.setFilters([...])
//   • Live readout    — visible-of-total count + the active predicate summary
// Selection stays in master space, so filtering + multi-select compose.
//
//   Run standalone:
//     cd geniuslink_design_system_flutter/example
//     flutter run -d chrome -t lib/readable_table/filter_demo.dart
//
//   File: example/lib/readable_table/filter_demo.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:geniuslink_design_system/geniuslink_readable_table.dart';

void main() => runApp(const FilterDemoApp());

/// A minimal host so the file runs on its own (`flutter run -t …`).
class FilterDemoApp extends StatelessWidget {
  const FilterDemoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'ReadableTable · Filter System',
      debugShowCheckedModeBanner: false,
      home: ReadableFilterDemo(),
    );
  }
}

// ── the typed row value ──
class Account {
  final String code, name, arabic, type, status, region;
  final double balance;
  final DateTime opened;
  const Account(this.code, this.name, this.arabic, this.type, this.status, this.region, this.balance, this.opened);
}

class ReadableFilterDemo extends StatefulWidget {
  const ReadableFilterDemo({super.key});
  @override
  State<ReadableFilterDemo> createState() => _ReadableFilterDemoState();
}

class _ReadableFilterDemoState extends State<ReadableFilterDemo> {
  bool _light = true;
  bool _rtl = false;
  late ReadableTableController<Account> _controller;

  // logical column indices — kept as names so the preset buttons read clearly
  static const int colCode = 0, colAccount = 1, colType = 2, colStatus = 3, colRegion = 4, colBalance = 5, colOpened = 6;

  @override
  void initState() {
    super.initState();
    _controller = ReadableTableController<Account>(
      columns: _columns(),
      rows: List<Account>.from(_seed),
      selectionMode: ReadableSelectionMode.multiRow,
      // seed one filter so the bar opens with a visible chip
      filters: [ReadableFilter.anyOf(colType, const {'Asset', 'Expense'})],
    );
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── seed data — varied types / statuses / regions / dates for the filters ──
  static final List<Account> _seed = [
    Account('1010', 'Petty Cash', 'صندوق النقد', 'Asset', 'Reconciled', 'Riyadh', 4200, DateTime(2021, 1, 12)),
    Account('1020', 'Bank · SNB Main', 'بنك الأهلي', 'Asset', 'Reconciled', 'Riyadh', 182540, DateTime(2021, 3, 4)),
    Account('1030', 'Bank · Al Rajhi', 'بنك الراجحي', 'Asset', 'Pending', 'Jeddah', 96120, DateTime(2022, 6, 18)),
    Account('1110', 'Accounts Receivable', 'الذمم المدينة', 'Asset', 'Pending', 'Dammam', 64800, DateTime(2022, 9, 30)),
    Account('1210', 'Inventory', 'المخزون', 'Asset', 'Reconciled', 'Jeddah', 231450, DateTime(2023, 2, 14)),
    Account('2010', 'Accounts Payable', 'الذمم الدائنة', 'Liability', 'Pending', 'Riyadh', -74100, DateTime(2021, 5, 22)),
    Account('2110', 'VAT Payable', 'ضريبة القيمة المضافة', 'Liability', 'Flagged', 'Dammam', -18940, DateTime(2023, 7, 8)),
    Account('2210', 'Short-term Loan', 'قرض قصير الأجل', 'Liability', 'Reconciled', 'Riyadh', -75000, DateTime(2022, 11, 2)),
    Account('3010', 'Share Capital', 'رأس المال', 'Equity', 'Reconciled', 'Riyadh', -500000, DateTime(2021, 1, 1)),
    Account('3110', 'Retained Earnings', 'أرباح محتجزة', 'Equity', 'Pending', 'Jeddah', -212400, DateTime(2023, 12, 31)),
    Account('4010', 'Sales Revenue', 'إيرادات المبيعات', 'Revenue', 'Pending', 'Jeddah', -640200, DateTime(2023, 4, 19)),
    Account('4110', 'Service Revenue', 'إيرادات الخدمات', 'Revenue', 'Flagged', 'Dammam', -154300, DateTime(2023, 8, 27)),
    Account('5010', 'Cost of Goods Sold', 'تكلفة البضاعة', 'Expense', 'Reconciled', 'Jeddah', 388900, DateTime(2022, 3, 11)),
    Account('5210', 'Salaries Expense', 'مصروف الرواتب', 'Expense', 'Pending', 'Riyadh', 156000, DateTime(2021, 7, 15)),
    Account('5310', 'Rent Expense', 'مصروف الإيجار', 'Expense', 'Reconciled', 'Riyadh', 48000, DateTime(2022, 2, 1)),
    Account('5410', 'Utilities', 'المرافق', 'Expense', 'Flagged', 'Dammam', 19600, DateTime(2023, 5, 9)),
    Account('5510', 'Marketing', 'التسويق', 'Expense', 'Pending', 'Jeddah', 53400, DateTime(2023, 9, 21)),
    Account('5610', 'Software Subscriptions', 'اشتراكات البرامج', 'Expense', 'Reconciled', 'Riyadh', 27300, DateTime(2023, 1, 6)),
  ];

  Color _typeColor(String type) {
    switch (type) {
      case 'Asset':
      case 'Revenue':
        return EditableTableThemeData.success;
      case 'Liability':
        return EditableTableThemeData.danger;
      case 'Expense':
        return EditableTableThemeData.warning;
      default:
        return EditableTableThemeData.accent; // Equity
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Reconciled':
        return EditableTableThemeData.success;
      case 'Flagged':
        return EditableTableThemeData.danger;
      default:
        return EditableTableThemeData.warning; // Pending
    }
  }

  List<ReadableColumn<Account>> _columns() => [
        ReadableColumn<Account>(
          'Code',
          width: 84,
          sortable: true,
          sortKey: (a) => a.code,
          copyText: (a) => a.code,
          cell: (ctx, a) => Text(a.code,
              style: TextStyle(fontFamily: EditableTableThemeData.monoFont, fontSize: 12.5, color: EditableTableThemeData.of(ctx).fg3)),
        ),
        ReadableColumn.text<Account>('Account', value: (a) => a.name, secondary: (a) => a.arabic, flex: 3, sortable: true),
        ReadableColumn.enumBadge<Account>('Type', value: (a) => a.type, color: _typeColor, width: 116),
        ReadableColumn.enumBadge<Account>('Status', value: (a) => a.status, color: _statusColor, width: 118),
        ReadableColumn.text<Account>('Region', value: (a) => a.region, width: 110, sortable: true),
        ReadableColumn.number<Account>('Balance', value: (a) => a.balance, decimals: 2, width: 140),
        ReadableColumn.date<Account>('Opened', value: (a) => a.opened, width: 120),
      ];

  // ── preset filters — all via the same controller API the bar drives ──
  void _presetHighBalance() => _controller.setFilters([ReadableFilter.number(colBalance, ReadableFilterOp.greater, 100000)]);
  void _presetAssets() => _controller.setFilters([ReadableFilter.anyOf(colType, const {'Asset'})]);
  void _presetOpened2023() => _controller.setFilters([
        ReadableFilter.date(colOpened, ReadableFilterOp.between, DateTime(2023, 1, 1), DateTime(2023, 12, 31)),
      ]);
  void _presetFlaggedExpenses() {
    _controller
      ..setFilterJoin(ReadableFilterJoin.all)
      ..setFilters([
        ReadableFilter.anyOf(colStatus, const {'Flagged', 'Pending'}),
        ReadableFilter.text(colAccount, ReadableFilterOp.contains, 'e'),
      ]);
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
                constraints: const BoxConstraints(maxWidth: 1020),
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
                                      fontFamily: EditableTableThemeData.bodyFont, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.6, color: EditableTableThemeData.accent)),
                              const SizedBox(height: 10),
                              Text('ReadableTable · Filter system',
                                  style: TextStyle(
                                      fontFamily: EditableTableThemeData.displayFont, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: t.fg1)),
                              const SizedBox(height: 8),
                              Text(
                                'A typed, per-column filter layer over the read-only grid. Use the quick-search, '
                                'add filters from the ＋ Filter editor (column → condition → operand), toggle AND / OR '
                                'between chips, or disable a chip with its dot. The preset buttons below drive the same '
                                'controller API. The grid filters live; multi-select still works on the visible rows.',
                                style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 14, height: 1.5, color: t.fg3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(children: [
                          _MiniToggle(on: _light, onIcon: Icons.light_mode_outlined, offIcon: Icons.dark_mode_outlined, onLabel: 'Light', offLabel: 'Dark', onChanged: (v) => setState(() => _light = v)),
                          const SizedBox(height: 8),
                          _MiniToggle(on: _rtl, onIcon: Icons.format_textdirection_r_to_l_rounded, offIcon: Icons.format_textdirection_l_to_r_rounded, onLabel: 'RTL', offLabel: 'LTR', onChanged: (v) => setState(() => _rtl = v)),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 26),

                    // filter bar + table, both in the chosen direction
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
                            rowMinHeight: 52,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // programmatic presets
                    Text('PROGRAMMATIC PRESETS',
                        style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: t.fg3)),
                    const SizedBox(height: 4),
                    Text('Each calls controller.setFilters([…]) — the bar reflects it instantly.',
                        style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 12.5, color: t.fg3)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _OpButton(icon: Icons.trending_up_rounded, label: 'Balance > 100,000', onTap: _presetHighBalance),
                        _OpButton(icon: Icons.account_balance_wallet_outlined, label: 'Assets only', onTap: _presetAssets),
                        _OpButton(icon: Icons.event_outlined, label: 'Opened in 2023', onTap: _presetOpened2023),
                        _OpButton(icon: Icons.flag_outlined, label: 'Open + name has “e”', onTap: _presetFlaggedExpenses),
                        _OpButton(icon: Icons.restart_alt_rounded, label: 'Clear all', onTap: _controller.clearFilters),
                      ],
                    ),

                    const SizedBox(height: 18),
                    _ReadoutCard(controller: _controller),
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

// ── live readout: visible/total + active predicate summaries ──
class _ReadoutCard extends StatelessWidget {
  final ReadableTableController<Account> controller;
  const _ReadoutCard({required this.controller});
  @override
  Widget build(BuildContext context) {
    final t = EditableTableThemeData.of(context);
    final c = controller;
    final active = c.filters.where((f) => f.enabled && f.isComplete).toList();
    final join = c.filterJoin == ReadableFilterJoin.all ? 'AND' : 'OR';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(EditableTableThemeData.radiusLg),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.filter_alt_outlined, size: 16, color: EditableTableThemeData.accent),
            const SizedBox(width: 9),
            Text('${c.rowCount} of ${c.totalRowCount} rows',
                style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 13.5, fontWeight: FontWeight.w700, color: t.fg1)),
            const SizedBox(width: 10),
            if (c.selectedCount > 0)
              Text('· ${c.selectedCount} selected',
                  style: TextStyle(fontFamily: EditableTableThemeData.monoFont, fontSize: 11.5, color: t.fg3)),
            const Spacer(),
            if (c.query.trim().isNotEmpty)
              Text('search: “${c.query.trim()}”',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: EditableTableThemeData.monoFont, fontSize: 11.5, color: EditableTableThemeData.accent)),
          ]),
          if (active.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (var i = 0; i < active.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 44,
                      child: i == 0
                          ? const SizedBox.shrink()
                          : Text(join,
                              style: const TextStyle(
                                  fontFamily: EditableTableThemeData.monoFont, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: EditableTableThemeData.accent)),
                    ),
                    Expanded(
                      child: Text(
                        ReadableFilterCatalog.summary(active[i], c.columns[active[i].columnIndex]),
                        style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 13, color: t.fg1),
                      ),
                    ),
                  ],
                ),
              ),
          ] else ...[
            const SizedBox(height: 8),
            Text('No active filters — every row is visible.',
                style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 12.5, color: t.fg3)),
          ],
        ],
      ),
    );
  }
}

// ── small shared controls (kept local to the file) ──
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

class _MiniToggle extends StatelessWidget {
  final bool on;
  final IconData onIcon, offIcon;
  final String onLabel, offLabel;
  final ValueChanged<bool> onChanged;
  const _MiniToggle({required this.on, required this.onIcon, required this.offIcon, required this.onLabel, required this.offLabel, required this.onChanged});
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
            Text(on ? onLabel : offLabel, style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 13, fontWeight: FontWeight.w600, color: t.fg1)),
          ]),
        ),
      ),
    );
  }
}
