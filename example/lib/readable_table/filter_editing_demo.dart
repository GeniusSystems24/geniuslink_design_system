// ============================================================
// ReadableTable — FilterEditingView preview (standalone).
// A focused demo of the nested And/Or query builder driving a live grid:
//   • ReadableFilterEditingView edits the controller's nested filter tree
//   • the ReadableTable below it re-filters live as you build the query
//   • build conditions, nest subgroups, toggle And/Or rail pills, pick
//     typed values (text · enum · number · date · multi-select)
//   • light / dark + LTR / RTL (the rail mirrors)
//
//   Run standalone:
//     cd geniuslink_design_system_flutter/example
//     flutter run -d chrome -t lib/readable_table/filter_editing_demo.dart
//
//   File: example/lib/readable_table/filter_editing_demo.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:geniuslink_design_system/geniuslink_readable_table.dart';

void main() => runApp(const FilterEditingDemoApp());

class FilterEditingDemoApp extends StatelessWidget {
  const FilterEditingDemoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'ReadableTable · FilterEditingView',
      debugShowCheckedModeBanner: false,
      home: FilterEditingDemo(),
    );
  }
}

// ── row value ──
class Deal {
  final String company, owner, stage, health, region;
  final double value;
  final DateTime nextMeeting;
  const Deal(this.company, this.owner, this.stage, this.health, this.region, this.value, this.nextMeeting);
}

class FilterEditingDemo extends StatefulWidget {
  const FilterEditingDemo({super.key});
  @override
  State<FilterEditingDemo> createState() => _FilterEditingDemoState();
}

class _FilterEditingDemoState extends State<FilterEditingDemo> {
  bool _light = true;
  bool _rtl = false;
  late final ReadableTableController<Deal> _controller;

  static const int colCompany = 0, colOwner = 1, colStage = 2, colHealth = 3, colRegion = 4, colValue = 5, colMeeting = 6;

  @override
  void initState() {
    super.initState();
    _controller = ReadableTableController<Deal>(
      columns: _columns(),
      rows: List<Deal>.from(_seed),
      selectionMode: ReadableSelectionMode.multiRow,
      // seed a nested tree:  Owner is Davon  AND  ( Stage any of …  AND ( Health is Critical OR Region is Riyadh ) )
      filterGroup: ReadableFilterGroup(join: ReadableFilterJoin.all, children: [
        ReadableFilter.text(colOwner, ReadableFilterOp.equals, 'Davon Larson'),
        ReadableFilterGroup(join: ReadableFilterJoin.all, children: [
          ReadableFilter.anyOf(colStage, const {'Negotiation', 'Review'}),
          ReadableFilterGroup(join: ReadableFilterJoin.any, children: [
            ReadableFilter(columnIndex: colHealth, op: ReadableFilterOp.equals, value: 'Critical'),
            ReadableFilter(columnIndex: colRegion, op: ReadableFilterOp.equals, value: 'Riyadh'),
          ]),
        ]),
      ]),
    );
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _healthColor(String s) => switch (s) {
        'Critical' => EditableTableThemeData.danger,
        'At risk' => EditableTableThemeData.warning,
        _ => EditableTableThemeData.success,
      };
  Color _stageColor(String s) => switch (s) {
        'Won' => EditableTableThemeData.success,
        'Lost' => EditableTableThemeData.danger,
        'Negotiation' => EditableTableThemeData.accent,
        _ => const Color(0xFF8B5CF6),
      };

  List<ReadableColumn<Deal>> _columns() => [
        ReadableColumn.text<Deal>('Company', value: (d) => d.company, flex: 3, sortable: true),
        ReadableColumn.text<Deal>('Owner', value: (d) => d.owner, width: 150, sortable: true),
        ReadableColumn.enumBadge<Deal>('Stage', value: (d) => d.stage, color: _stageColor, width: 132),
        ReadableColumn.enumBadge<Deal>('Health', value: (d) => d.health, color: _healthColor, width: 116),
        ReadableColumn.text<Deal>('Region', value: (d) => d.region, width: 112, sortable: true),
        ReadableColumn.number<Deal>('Value', value: (d) => d.value, decimals: 0, suffix: ' SAR', width: 134),
        ReadableColumn.date<Deal>('Next meeting', value: (d) => d.nextMeeting, width: 138),
      ];

  static final List<Deal> _seed = [
    Deal('Najd Logistics', 'Davon Larson', 'Negotiation', 'Critical', 'Riyadh', 184000, DateTime(2025, 1, 14)),
    Deal('Tihama Foods', 'Davon Larson', 'Review', 'At risk', 'Jeddah', 92000, DateTime(2025, 1, 9)),
    Deal('Rua Real Estate', 'Davon Larson', 'Review', 'Healthy', 'Riyadh', 240000, DateTime(2025, 2, 3)),
    Deal('Sahar Retail', 'Davon Larson', 'Negotiation', 'Critical', 'Dammam', 76000, DateTime(2025, 1, 21)),
    Deal('Abuilk Cloud', 'Mira Haddad', 'Won', 'Healthy', 'Riyadh', 410000, DateTime(2025, 1, 30)),
    Deal('Qarya Telecom', 'Mira Haddad', 'Negotiation', 'At risk', 'Jeddah', 158000, DateTime(2025, 2, 11)),
    Deal('Wadi Pharma', 'Yousef Rahimi', 'Review', 'Critical', 'Riyadh', 67000, DateTime(2025, 1, 7)),
    Deal('Manar Energy', 'Yousef Rahimi', 'Lost', 'Critical', 'Dammam', 320000, DateTime(2025, 1, 18)),
    Deal('Bahr Maritime', 'Davon Larson', 'Negotiation', 'Healthy', 'Jeddah', 205000, DateTime(2025, 2, 6)),
    Deal('Salwa Group', 'Mira Haddad', 'Review', 'Critical', 'Riyadh', 88000, DateTime(2025, 1, 25)),
  ];

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
                constraints: const BoxConstraints(maxWidth: 1040),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(28, 38, 28, 80),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('GENIUSLINK DESIGN SYSTEM',
                                  style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.6, color: EditableTableThemeData.accent)),
                              const SizedBox(height: 10),
                              Text('FilterEditingView',
                                  style: TextStyle(fontFamily: EditableTableThemeData.displayFont, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: t.fg1)),
                              const SizedBox(height: 8),
                              Text(
                                'A nested And / Or query builder for the ReadableTable filter-system. Build conditions, '
                                'nest subgroups, toggle a rail pill to switch a group between matching all or any of its rows, '
                                'and pick typed values. The grid below re-filters live as you edit.',
                                style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 14, height: 1.5, color: t.fg3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(children: [
                          _MiniToggle(on: _light, onLabel: 'Light', offLabel: 'Dark', onChanged: (v) => setState(() => _light = v)),
                          const SizedBox(height: 8),
                          _MiniToggle(on: _rtl, onLabel: 'RTL', offLabel: 'LTR', onChanged: (v) => setState(() => _rtl = v)),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 26),

                    Directionality(
                      textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // the builder
                          ReadableFilterEditingView<Deal>(controller: _controller),
                          const SizedBox(height: 18),
                          // live count
                          Row(
                            children: [
                              Icon(Icons.filter_alt_outlined, size: 16, color: EditableTableThemeData.accent),
                              const SizedBox(width: 8),
                              Text('${_controller.rowCount} of ${_controller.totalRowCount} deals match',
                                  style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 13.5, fontWeight: FontWeight.w700, color: t.fg1)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // the live grid — with the inline column-filter row
                          ReadableTable<Deal>(controller: _controller, hoverHighlight: true, rowMinHeight: 50, showColumnFilters: true),
                        ],
                      ),
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

class _MiniToggle extends StatelessWidget {
  final bool on;
  final String onLabel, offLabel;
  final ValueChanged<bool> onChanged;
  const _MiniToggle({required this.on, required this.onLabel, required this.offLabel, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final t = EditableTableThemeData.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onChanged(!on),
        child: Container(
          width: 92,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(color: t.surface, border: Border.all(color: t.border), borderRadius: BorderRadius.circular(EditableTableThemeData.radiusMd)),
          child: Text(on ? onLabel : offLabel, textAlign: TextAlign.center, style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 13, fontWeight: FontWeight.w600, color: t.fg1)),
        ),
      ),
    );
  }
}
