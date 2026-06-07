// ============================================================
// AutoSuggestionsBox — demo screen.
// Shows the four flavours the component supports:
//   1. Static string list           (plain values)
//   2. Rich grouped suggestions     (icon + description + section headers)
//   3. Async source                 (debounced fake-network search + spinner)
//   4. Free-text + custom match     (prefix / words / fuzzy strategies)
//
//   Run standalone:
//     cd geniuslink_design_system_flutter/example
//     flutter run -d chrome -t lib/auto_suggestions_box_demo.dart
//
//   File: example/lib/auto_suggestions_box_demo.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:geniuslink_design_system/geniuslink_auto_suggestions_box.dart';

void main() => runApp(const AutoSuggestionsDemoApp());

class AutoSuggestionsDemoApp extends StatelessWidget {
  const AutoSuggestionsDemoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'AutoSuggestionsBox',
      debugShowCheckedModeBanner: false,
      home: AutoSuggestionsBoxDemo(),
    );
  }
}

class AutoSuggestionsBoxDemo extends StatefulWidget {
  const AutoSuggestionsBoxDemo({super.key});
  @override
  State<AutoSuggestionsBoxDemo> createState() => _AutoSuggestionsBoxDemoState();
}

class _AutoSuggestionsBoxDemoState extends State<AutoSuggestionsBoxDemo> {
  bool _light = true;
  bool _rtl = false;
  AutoSuggestionMatch _match = AutoSuggestionMatch.contains;

  String _lastPick = '—';
  List<String> _tags = const [];
  late final AutoSuggestionsBoxController<String> _teamCtrl = AutoSuggestionsBoxController<String>(
    multiSelect: true,
    source: StringSuggestions.source(const [
      'Design', 'Engineering', 'Research', 'Marketing', 'Sales', 'Finance',
      'Legal', 'Support', 'Operations', 'Product', 'Data', 'Security',
    ]),
  );

  @override
  void dispose() {
    _teamCtrl.dispose();
    super.dispose();
  }

  // 1 ── plain strings
  static const _fruits = [
    'Apple', 'Apricot', 'Avocado', 'Banana', 'Blackberry', 'Blueberry', 'Cherry',
    'Clementine', 'Coconut', 'Cranberry', 'Date', 'Dragonfruit', 'Fig', 'Grape',
    'Grapefruit', 'Guava', 'Kiwi', 'Lemon', 'Lime', 'Lychee', 'Mango', 'Melon',
    'Nectarine', 'Orange', 'Papaya', 'Passionfruit', 'Peach', 'Pear', 'Pineapple',
    'Plum', 'Pomegranate', 'Raspberry', 'Strawberry', 'Tangerine', 'Watermelon',
  ];

  // 2 ── rich, grouped accounts (icon + description + group)
  static final _accounts = <AutoSuggestion<String>>[
    AutoSuggestion(value: '1000', label: 'Cash on hand', description: '1000 · Current asset', icon: Icons.payments_outlined, group: 'Assets', keywords: ['money']),
    AutoSuggestion(value: '1100', label: 'Accounts receivable', description: '1100 · Current asset', icon: Icons.request_quote_outlined, group: 'Assets'),
    AutoSuggestion(value: '1200', label: 'Inventory', description: '1200 · Current asset', icon: Icons.inventory_2_outlined, group: 'Assets'),
    AutoSuggestion(value: '2000', label: 'Accounts payable', description: '2000 · Current liability', icon: Icons.account_balance_wallet_outlined, group: 'Liabilities'),
    AutoSuggestion(value: '2100', label: 'Accrued expenses', description: '2100 · Current liability', icon: Icons.receipt_long_outlined, group: 'Liabilities'),
    AutoSuggestion(value: '3000', label: 'Share capital', description: '3000 · Equity', icon: Icons.savings_outlined, group: 'Equity'),
    AutoSuggestion(value: '4000', label: 'Sales revenue', description: '4000 · Income', icon: Icons.trending_up_rounded, group: 'Income', keywords: ['turnover']),
    AutoSuggestion(value: '5000', label: 'Cost of goods sold', description: '5000 · Expense', icon: Icons.trending_down_rounded, group: 'Expense', keywords: ['cogs']),
    AutoSuggestion(value: '5100', label: 'Payroll', description: '5100 · Expense', icon: Icons.groups_outlined, group: 'Expense', keywords: ['salaries', 'wages']),
    AutoSuggestion(value: '5200', label: 'Marketing', description: '5200 · Expense', icon: Icons.campaign_outlined, group: 'Expense', keywords: ['advertising']),
  ];

  // 3 ── async: pretend network search over a country list
  static const _countries = [
    'Argentina', 'Australia', 'Austria', 'Bahrain', 'Belgium', 'Brazil', 'Canada',
    'Chile', 'China', 'Denmark', 'Egypt', 'Finland', 'France', 'Germany', 'Greece',
    'India', 'Indonesia', 'Iraq', 'Ireland', 'Italy', 'Japan', 'Jordan', 'Kuwait',
    'Lebanon', 'Malaysia', 'Mexico', 'Morocco', 'Netherlands', 'New Zealand',
    'Norway', 'Oman', 'Portugal', 'Qatar', 'Saudi Arabia', 'Singapore', 'Spain',
    'Sweden', 'Switzerland', 'Turkey', 'United Arab Emirates', 'United Kingdom',
    'United States', 'Vietnam',
  ];

  late final AutoSuggestionsSource<String> _asyncSource = AutoSuggestionsSource.async((q) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    final query = q.trim().toLowerCase();
    final hits = _countries.where((c) => c.toLowerCase().contains(query)).toList();
    return [for (final c in hits) AutoSuggestion<String>(value: c, label: c, icon: Icons.public_rounded)];
  });

  void _onPick(String label) => setState(() => _lastPick = label);

  @override
  Widget build(BuildContext context) {
    final ext = _light ? AutoSuggestionsBoxThemeData.light : AutoSuggestionsBoxThemeData.dark;
    return Theme(
      data: ThemeData(
        brightness: _light ? Brightness.light : Brightness.dark,
        useMaterial3: true,
        fontFamily: AutoSuggestionsBoxThemeData.bodyFont,
        scaffoldBackgroundColor: _light ? const Color(0xFFF4F6FA) : const Color(0xFF141519),
        extensions: [ext],
      ),
      child: Builder(builder: (context) {
        final t = AutoSuggestionsBoxThemeData.of(context);
        final bg = _light ? const Color(0xFFF4F6FA) : const Color(0xFF141519);
        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Directionality(
                  textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(28, 40, 28, 96),
                    children: [
                      // header
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('GENIUSLINK DESIGN SYSTEM',
                                style: TextStyle(fontFamily: AutoSuggestionsBoxThemeData.bodyFont, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.6, color: AutoSuggestionsBoxThemeData.accent)),
                            const SizedBox(height: 10),
                            Text('AutoSuggestionsBox',
                                style: TextStyle(fontFamily: AutoSuggestionsBoxThemeData.displayFont, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: t.fg1)),
                            const SizedBox(height: 8),
                            Text('Type to filter, ↑ ↓ to move, Enter or click to pick. Static, grouped, and async sources — with match highlighting.',
                                style: TextStyle(fontFamily: AutoSuggestionsBoxThemeData.bodyFont, fontSize: 14, height: 1.5, color: t.fg2)),
                          ]),
                        ),
                        const SizedBox(width: 16),
                        Column(children: [
                          _MiniToggle(on: _light, onLabel: 'Light', offLabel: 'Dark', onChanged: (v) => setState(() => _light = v)),
                          const SizedBox(height: 8),
                          _MiniToggle(on: _rtl, onLabel: 'RTL', offLabel: 'LTR', onChanged: (v) => setState(() => _rtl = v)),
                        ]),
                      ]),
                      const SizedBox(height: 30),

                      // 1 · static strings
                      _Section(
                        t: t,
                        index: '01',
                        title: 'Static list',
                        note: 'A plain List<String>. Filtered locally as you type.',
                        child: AutoSuggestionsBox<String>(
                          source: StringSuggestions.source(_fruits),
                          hintText: 'Search a fruit…',
                          onSelected: (s) => _onPick(s.label),
                        ),
                      ),

                      // 2 · rich grouped
                      _Section(
                        t: t,
                        index: '02',
                        title: 'Grouped · icon + description',
                        note: 'Section headers, leading glyphs and a secondary line. Searches labels + keywords.',
                        child: AutoSuggestionsBox<String>(
                          items: _accounts,
                          hintText: 'Find an account…',
                          leading: Icon(Icons.account_tree_outlined, size: 18, color: t.fg3),
                          maxVisibleRows: 6,
                          onSelected: (s) => _onPick('${s.label}  (${s.value})'),
                        ),
                      ),

                      // 3 · async
                      _Section(
                        t: t,
                        index: '03',
                        title: 'Async source · custom builders',
                        note: 'Debounced “network” search with custom loadingBuilder, emptyBuilder and itemBuilder.',
                        child: AutoSuggestionsBox<String>(
                          source: _asyncSource,
                          hintText: 'Search a country…',
                          onSelected: (s) => _onPick(s.label),
                          loadingBuilder: (context, q) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                            child: Row(children: [
                              SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AutoSuggestionsBoxThemeData.accent)),
                              const SizedBox(width: 10),
                              Text('Looking up “$q”…', style: TextStyle(fontFamily: AutoSuggestionsBoxThemeData.bodyFont, fontSize: 13, color: t.fg2)),
                            ]),
                          ),
                          emptyBuilder: (context, q) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                            child: Row(children: [
                              Icon(Icons.public_off_rounded, size: 16, color: t.fg3),
                              const SizedBox(width: 8),
                              Text('No country matches “$q”', style: TextStyle(fontFamily: AutoSuggestionsBoxThemeData.bodyFont, fontSize: 13, color: t.fg2)),
                            ]),
                          ),
                          itemBuilder: (context, s, highlighted) => Row(children: [
                            Icon(Icons.public_rounded, size: 17, color: highlighted ? AutoSuggestionsBoxThemeData.accent : t.fg3),
                            const SizedBox(width: 10),
                            Expanded(child: Text(s.label, style: TextStyle(fontFamily: AutoSuggestionsBoxThemeData.bodyFont, fontSize: 13.5, fontWeight: FontWeight.w500, color: t.fg1))),
                            Icon(Icons.north_west_rounded, size: 13, color: t.fg3),
                          ]),
                        ),
                      ),

                      // 4 · match strategy
                      _Section(
                        t: t,
                        index: '04',
                        title: 'Match strategy + free text',
                        note: 'Switch how the query is tested. Unmatched text commits as-is on Enter.',
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            for (final m in AutoSuggestionMatch.values)
                              _MatchChip(t: t, label: m.name, on: _match == m, onTap: () => setState(() => _match = m)),
                          ]),
                          const SizedBox(height: 12),
                          AutoSuggestionsBox<String>(
                            key: ValueKey(_match), // rebuild the source on strategy change
                            source: AutoSuggestionsSource.list(
                              [for (final f in _fruits) AutoSuggestion<String>(value: f, label: f)],
                              match: _match,
                            ),
                            hintText: 'Try “ble”, “rry”, or a free value…',
                            highlightMatch: _match,
                            onSelected: (s) => _onPick(s.label),
                            onSubmitted: (raw) => _onPick('“$raw” (free text)'),
                          ),
                        ]),
                      ),

                      // 5 · multi-select
                      _Section(
                        t: t,
                        index: '05',
                        title: 'Multi-select',
                        note: 'Tap (or Enter) toggles rows — the overlay stays open and shows a count. Chosen tags appear below.',
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          AutoSuggestionsBox<String>(
                            controller: _teamCtrl,
                            multiSelect: true,
                            hintText: 'Choose teams…',
                            onSelectionChanged: (items) => setState(() => _tags = [for (final i in items) i.label]),
                          ),
                          if (_tags.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(spacing: 8, runSpacing: 8, children: [
                              for (final tag in _tags)
                                Container(
                                  padding: const EdgeInsets.fromLTRB(11, 6, 7, 6),
                                  decoration: BoxDecoration(
                                    color: AutoSuggestionsBoxThemeData.accent.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: AutoSuggestionsBoxThemeData.accent.withOpacity(0.45)),
                                  ),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Text(tag, style: TextStyle(fontFamily: AutoSuggestionsBoxThemeData.bodyFont, fontSize: 12.5, fontWeight: FontWeight.w600, color: t.fg1)),
                                    const SizedBox(width: 5),
                                    GestureDetector(
                                      onTap: () => setState(() {
                                        _teamCtrl.removeSelectedValue(tag);
                                        _tags = _teamCtrl.selectedValues;
                                      }),
                                      child: Icon(Icons.close_rounded, size: 14, color: t.fg3),
                                    ),
                                  ]),
                                ),
                            ]),
                          ],
                        ]),
                      ),

                      const SizedBox(height: 6),
                      // last pick readout
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: t.overlayBg,
                          borderRadius: BorderRadius.circular(AutoSuggestionsBoxThemeData.radiusMd),
                          border: Border.all(color: t.border),
                        ),
                        child: Row(children: [
                          Icon(Icons.check_circle_outline_rounded, size: 16, color: AutoSuggestionsBoxThemeData.accent),
                          const SizedBox(width: 8),
                          Text('Last picked:', style: TextStyle(fontFamily: AutoSuggestionsBoxThemeData.bodyFont, fontSize: 13, color: t.fg2)),
                          const SizedBox(width: 6),
                          Expanded(child: Text(_lastPick, style: TextStyle(fontFamily: AutoSuggestionsBoxThemeData.bodyFont, fontSize: 13, fontWeight: FontWeight.w600, color: t.fg1))),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _Section extends StatelessWidget {
  final AutoSuggestionsBoxThemeData t;
  final String index, title, note;
  final Widget child;
  const _Section({required this.t, required this.index, required this.title, required this.note, required this.child});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Text(index, style: TextStyle(fontFamily: AutoSuggestionsBoxThemeData.displayFont, fontSize: 12, fontWeight: FontWeight.w800, color: AutoSuggestionsBoxThemeData.accent)),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontFamily: AutoSuggestionsBoxThemeData.displayFont, fontSize: 16, fontWeight: FontWeight.w700, color: t.fg1)),
        ]),
        const SizedBox(height: 4),
        Text(note, style: TextStyle(fontFamily: AutoSuggestionsBoxThemeData.bodyFont, fontSize: 12.5, height: 1.45, color: t.fg2)),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}

class _MatchChip extends StatelessWidget {
  final AutoSuggestionsBoxThemeData t;
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _MatchChip({required this.t, required this.label, required this.on, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AutoSuggestionsBoxThemeData.durFast,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: on ? AutoSuggestionsBoxThemeData.accent : t.fieldBg,
            border: Border.all(color: on ? AutoSuggestionsBoxThemeData.accent : t.border),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(label,
              style: TextStyle(
                  fontFamily: AutoSuggestionsBoxThemeData.bodyFont,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: on ? Colors.white : t.fg2)),
        ),
      ),
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
    final t = AutoSuggestionsBoxThemeData.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onChanged(!on),
        child: Container(
          width: 92,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(color: t.fieldBg, border: Border.all(color: t.border), borderRadius: BorderRadius.circular(AutoSuggestionsBoxThemeData.radiusMd)),
          child: Text(on ? onLabel : offLabel, textAlign: TextAlign.center, style: TextStyle(fontFamily: AutoSuggestionsBoxThemeData.bodyFont, fontSize: 13, fontWeight: FontWeight.w600, color: t.fg1)),
        ),
      ),
    );
  }
}
