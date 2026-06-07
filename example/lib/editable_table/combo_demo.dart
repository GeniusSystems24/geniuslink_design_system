// ============================================================
// EditableTable — COMBO column demo (standalone).
// Shows ComboBoxColumn cells backed by the first-party
// `smart_auto_suggest_box` package: click a Category / Unit / Tag cell, then
// type to filter the suggestions, ↑ ↓ to move, Enter / click to pick — or type
// a free value and press Tab / Enter to commit it as-is.
//
// Note the MaterialApp wiring: `SmartAutoSuggestBoxLocalizations.delegate` +
// `GlobalMaterialLocalizations.delegate` are added so the suggest overlay is
// fully localized (EN / AR). This is the recommended setup for any app that
// hosts EditableTable combo columns.
//
//   Run standalone:
//     cd geniuslink_design_system_flutter/example
//     flutter run -d chrome -t lib/editable_table/combo_demo.dart
//
//   File: example/lib/editable_table/combo_demo.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:smart_auto_suggest_box/smart_auto_suggest_box.dart';
import 'package:geniuslink_design_system/geniuslink_editable_table.dart';

void main() => runApp(const ComboDemoApp());

class ComboDemoApp extends StatelessWidget {
  const ComboDemoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EditableTable · Combo columns',
      debugShowCheckedModeBanner: false,
      // The suggest box ships its own localizations — register the delegate
      // (plus the Material/Widgets globals) so the overlay reads correctly in
      // every supported locale.
      localizationsDelegates: const [
        SmartAutoSuggestBoxLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
      home: const ComboDemo(),
    );
  }
}

class ComboDemo extends StatefulWidget {
  const ComboDemo({super.key});
  @override
  State<ComboDemo> createState() => _ComboDemoState();
}

class _ComboDemoState extends State<ComboDemo> {
  bool _light = true;
  bool _rtl = false;

  // Suggestion pools for the combo columns.
  static const _categories = [
    'Assets', 'Liabilities', 'Equity', 'Revenue', 'Cost of sales',
    'Operating expense', 'Payroll', 'Marketing', 'Utilities', 'Travel',
  ];
  static const _units = ['each', 'box', 'kg', 'litre', 'hour', 'day', 'month', 'service'];
  static const _tags = ['urgent', 'recurring', 'capex', 'opex', 'billable', 'internal', 'review'];

  late final List<EditableColumn> _columns = [
    const EditableColumn(key: 'item', label: 'Item', width: 200, required: true),
    ComboBoxColumn(key: 'category', label: 'Category', options: _categories, width: 190),
    ComboBoxColumn(key: 'unit', label: 'Unit', options: _units, width: 150),
    NumericColumn(key: 'qty', label: 'Qty', decimals: 0, width: 100),
    ComboBoxColumn(key: 'tag', label: 'Tag', options: _tags, width: 160),
  ];

  late final List<EditableRow> _rows = [
    {'item': 'Cloud hosting', 'category': 'Operating expense', 'unit': 'month', 'qty': '12', 'tag': 'recurring'},
    {'item': 'Steel sheets', 'category': 'Cost of sales', 'unit': 'kg', 'qty': '480', 'tag': 'capex'},
    {'item': 'Consultancy', 'category': '', 'unit': 'hour', 'qty': '40', 'tag': 'billable'},
    {'item': 'Office rent', 'category': 'Operating expense', 'unit': 'month', 'qty': '1', 'tag': ''},
    {'item': 'Ad campaign', 'category': 'Marketing', 'unit': 'service', 'qty': '3', 'tag': 'review'},
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
                constraints: const BoxConstraints(maxWidth: 980),
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
                              Text('EditableTable · Combo columns',
                                  style: TextStyle(fontFamily: EditableTableThemeData.displayFont, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: t.fg1)),
                              const SizedBox(height: 8),
                              Text(
                                'The Category, Unit and Tag columns are ComboBoxColumn cells. Click one and start '
                                'typing: the smart_auto_suggest_box overlay filters as you type — ↑ ↓ to move, Enter or '
                                'click to pick, or type a free value and Tab / Enter to commit it.',
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
                      child: EditableTable(
                        columns: _columns,
                        initialRows: _rows,
                        showTotals: false,
                        unitLabel: 'line items',
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
