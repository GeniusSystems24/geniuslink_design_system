// ============================================================
// GeniusLink Design System — component examples app.
// A launcher with ONE example screen per component, plus focused sub-demos:
//   • All Components       — the ERP Console: Tree + BrowserStyleTabBar + EditableTable
//   • BrowserStyleTabBar   — the tab-strip showcase (pin, drag-reorder, overflow, thumbnails)
//   • EditableTable        — the Excel-style data-entry grid
//   • EditableTable Combo  — ComboBoxColumn cells powered by AutoSuggestionsBox
//   • AutoSuggestionsBox   — the typed auto-suggest field (static/grouped/async/hybrid)
//   • ReadableTable        — the read-only display grid
//   • ReadableTable Filter — the per-column filter system
//   • FilterEditingView    — the grouped AND/OR visual filter builder
//   • Tree                 — the chart-of-accounts tree
//   • NavigationSidebar    — the app nav rail (expanded / collapsed / drawer)
//
// Every screen registers its own ThemeExtension; each component reads it via
// <Component>ThemeData.of(context). All screens run live in Light/Dark and
// EN / AR (RTL). The top-level MaterialApp registers the global localization
// delegates so the Material date/time pickers localize in AR.
//
//   Run:  cd geniuslink_design_system_flutter/example && flutter pub get && flutter run -d chrome
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:geniuslink_design_system/geniuslink_browser_tabs.dart';
import 'browser_tabs_demo.dart';
import 'editable_table_demo.dart';
import 'editable_table/combo_demo.dart';
import 'auto_suggestions_box_demo.dart';
import 'readable_table_demo.dart';
import 'readable_table/filter_demo.dart';
import 'readable_table/filter_editing_demo.dart';
import 'tree_demo.dart';
import 'navigation_sidebar_demo.dart';
import 'erp_console.dart';
import 'shell_kit.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeniusLink · Component Examples',
      debugShowCheckedModeBanner: false,
      // Registered app-wide so the Material date/time pickers (and any other
      // localized widgets) read correctly in AR as well as EN.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        fontFamily: BrowserStyleTabBarThemeData.bodyFont,
        scaffoldBackgroundColor: BrowserStyleTabBarThemeData.light.bg,
        extensions: const [BrowserStyleTabBarThemeData.light],
      ),
      supportedLocales: const [Locale('en'), Locale('ar')],
      home: const LauncherScreen(),
    );
  }
}

// ════════════════════════════════════════════════════════════
// LAUNCHER
// ════════════════════════════════════════════════════════════
class LauncherScreen extends StatelessWidget {
  const LauncherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              children: [
                Text('GENIUSLINK DESIGN SYSTEM',
                    style: TextStyle(
                        fontFamily: BrowserStyleTabBarThemeData.bodyFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                        color: BrowserStyleTabBarThemeData.accent)),
                const SizedBox(height: 12),
                Text('Component Examples',
                    style: TextStyle(
                        fontFamily: BrowserStyleTabBarThemeData.displayFont,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        color: s.fg1)),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Text(
                    'One example screen per component — BrowserStyleTabBar, EditableTable, '
                    'ReadableTable and the Tree — plus focused demos for the combo auto-suggest '
                    'editor and the ReadableTable filter system, and an all-in-one console that '
                    'runs them together. Open any to try it live in Light / Dark and EN / AR (RTL).',
                    style: TextStyle(
                        fontFamily: BrowserStyleTabBarThemeData.bodyFont,
                        fontSize: 14.5,
                        height: 1.55,
                        color: s.fg3),
                  ),
                ),
                const SizedBox(height: 32),
                LayoutBuilder(builder: (context, c) {
                  final cols =
                      c.maxWidth > 760 ? 3 : (c.maxWidth > 460 ? 2 : 1);
                  return GridView.count(
                    crossAxisCount: cols,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                    childAspectRatio: 0.92,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _DemoCard(
                        title: 'All Components — ERP Console',
                        subtitle:
                            'Tree navigator + BrowserStyleTabBar + EditableTable working together in one console · Light/Dark · EN/AR (RTL)',
                        accent: const Color(0xFF4A7CFF),
                        preview: const _ErpConsoleThumb(),
                        onTap: () => _open(context, const ErpConsole()),
                      ),
                      _DemoCard(
                        title: 'BrowserStyleTabBar',
                        subtitle:
                            'Tab strip · pin, drag-reorder, unsaved-close guard, overflow menu, live hover thumbnails · state-preserving pages',
                        accent: BrowserStyleTabBarThemeData.accent,
                        preview: const _ErpThumb(),
                        onTap: () => _open(context, const _GalleryRoute()),
                      ),
                      _DemoCard(
                        title: 'EditableTable',
                        subtitle:
                            'Excel-style data-entry grid · typed generic rows · resize & reorder columns · copy as TSV · sort · undo',
                        accent: BrowserStyleTabBarThemeData.success,
                        preview: const _EditableTableThumb(),
                        onTap: () => _open(context, const EditableTableDemo()),
                      ),
                      _DemoCard(
                        title: 'EditableTable — Combo cells',
                        subtitle:
                            'ComboBoxColumn powered by the native AutoSuggestionsBox · type to filter, ↑ ↓ to move, Enter / click to pick, or free text',
                        accent: BrowserStyleTabBarThemeData.success,
                        preview: const _ComboThumb(),
                        onTap: () => _open(context, const ComboDemo()),
                      ),
                      _DemoCard(
                        title: 'AutoSuggestionsBox',
                        subtitle:
                            'Typed auto-suggest field · static / grouped / async / hybrid sources · match highlighting · keyboard nav · free text',
                        accent: const Color(0xFF4A7CFF),
                        preview: const _SuggestThumb(),
                        onTap: () =>
                            _open(context, const AutoSuggestionsBoxDemo()),
                      ),
                      _DemoCard(
                        title: 'ReadableTable',
                        subtitle:
                            'Read-only display grid · typed column kinds · resize / reorder · multi-select & copy · keyboard nav · scroll-on-focus',
                        accent: const Color(0xFF4A7CFF),
                        preview: const _ReadableTableThumb(),
                        onTap: () => _open(context, const ReadableTableDemo()),
                      ),
                      _DemoCard(
                        title: 'ReadableTable — Filter system',
                        subtitle:
                            'Per-column filters · operators by type · live visible/total readout · combine predicates · clear all',
                        accent: const Color(0xFF4A7CFF),
                        preview: const _FilterThumb(),
                        onTap: () => _open(context, const ReadableFilterDemo()),
                      ),
                      _DemoCard(
                        title: 'FilterEditingView',
                        subtitle:
                            'Visual filter builder · grouped AND / OR conditions · per-column operators · nested groups · add / remove rules',
                        accent: const Color(0xFF4A7CFF),
                        preview: const _FilterEditingThumb(),
                        onTap: () => _open(context, const FilterEditingDemo()),
                      ),
                      _DemoCard(
                        title: 'Tree',
                        subtitle:
                            'Chart-of-accounts tree · single & multi-select · add / remove nodes · code/EN/AR search · roll-up balances',
                        accent: const Color(0xFF4A7CFF),
                        preview: const _TreeThumb(),
                        onTap: () => _open(context, const TreeDemo()),
                      ),
                      _DemoCard(
                        title: 'NavigationSidebar',
                        subtitle:
                            'App nav rail · expanded tree + collapsed rail with flyouts + mobile drawer · badges · responsive · Light/Dark · LTR/RTL',
                        accent: const Color(0xFF4A7CFF),
                        preview: const _NavSidebarThumb(),
                        onTap: () =>
                            _open(context, const NavigationSidebarDemo()),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => _BackScaffold(child: screen)));
  }
}

class _DemoCard extends StatefulWidget {
  final String title, subtitle;
  final Color accent;
  final Widget preview;
  final VoidCallback onTap;
  const _DemoCard(
      {required this.title,
      required this.subtitle,
      required this.accent,
      required this.preview,
      required this.onTap});
  @override
  State<_DemoCard> createState() => _DemoCardState();
}

class _DemoCardState extends State<_DemoCard> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: BrowserStyleTabBarThemeData.durBase,
          transform: _h
              ? (Matrix4.identity()..translate(0.0, -3.0))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: s.surface,
            border: Border.all(
                color: _h ? widget.accent.withOpacity(0.5) : s.border),
            borderRadius:
                BorderRadius.circular(BrowserStyleTabBarThemeData.radiusXl),
            boxShadow: _h ? BrowserStyleTabBarThemeData.cardShadow : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: widget.preview),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(widget.title,
                            style: TextStyle(
                                fontFamily:
                                    BrowserStyleTabBarThemeData.displayFont,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: s.fg1)),
                      ),
                      Icon(Icons.arrow_outward,
                          size: 16, color: _h ? widget.accent : s.fg3),
                    ]),
                    const SizedBox(height: 6),
                    Text(widget.subtitle,
                        style: TextStyle(
                            fontFamily: BrowserStyleTabBarThemeData.bodyFont,
                            fontSize: 12.5,
                            height: 1.45,
                            color: s.fg3)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── small static thumbnails for the launcher cards ──
class _MiniTabs extends StatelessWidget {
  final Color strip, active, text;
  final List<String> labels;
  final int activeIndex;
  const _MiniTabs(
      {required this.strip,
      required this.active,
      required this.text,
      required this.labels,
      this.activeIndex = 0});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: strip,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: i == activeIndex ? active : Colors.transparent,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(6)),
              ),
              child: Text(labels[i],
                  style: TextStyle(
                      fontFamily: BrowserStyleTabBarThemeData.bodyFont,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: text)),
            ),
          ],
          const Spacer(),
          Icon(Icons.add, size: 13, color: text),
        ],
      ),
    );
  }
}

class _ErpThumb extends StatelessWidget {
  const _ErpThumb();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F8FA),
      child: Column(children: [
        const _MiniTabs(
            strip: Color(0xFFF7F8FA),
            active: Colors.white,
            text: Color(0xFF64748B),
            labels: ['Ledger', 'Journal', 'Store'],
            activeIndex: 1),
        Expanded(
            child: Container(
                color: Colors.white,
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                padding: const EdgeInsets.all(10),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          width: 80, height: 8, color: const Color(0xFF0F172A)),
                      const SizedBox(height: 8),
                      for (int i = 0; i < 3; i++)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(children: [
                              Container(
                                  width: 30,
                                  height: 6,
                                  color: const Color(0xFFE2E8F0)),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Container(
                                      height: 6,
                                      color: const Color(0xFFEEF1F7)))
                            ])),
                    ]))),
      ]),
    );
  }
}

class _EditableTableThumb extends StatelessWidget {
  const _EditableTableThumb();
  @override
  Widget build(BuildContext context) {
    const line = Color(0xFFE2E8F0);
    return Container(
      color: const Color(0xFFF7F8FA),
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFC2C6D6)),
            borderRadius: BorderRadius.circular(5)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          Container(
              height: 16,
              color: const Color(0xFFF7F8FA),
              child: Row(children: [
                for (int i = 0; i < 4; i++)
                  Expanded(
                      child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          height: 4,
                          color: const Color(0xFFBDC1C6))),
              ])),
          Container(height: 1, color: const Color(0xFFC2C6D6)),
          for (int r = 0; r < 3; r++)
            Expanded(
                child: Row(children: [
              for (int cIdx = 0; cIdx < 4; cIdx++)
                Expanded(
                    child: Container(
                  margin: const EdgeInsets.all(0.5),
                  decoration: BoxDecoration(
                    color: r == 1 && cIdx == 2
                        ? const Color(0x1A4A7CFF)
                        : Colors.white,
                    border: r == 1 && cIdx == 2
                        ? Border.all(color: const Color(0xFF4A7CFF), width: 1.5)
                        : Border.all(color: line, width: 0.5),
                  ),
                  child: Center(
                      child: Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          color: const Color(0xFFEEF1F7))),
                )),
            ])),
          Container(
              height: 14,
              decoration: const BoxDecoration(
                  color: Color(0xFFF7F8FA),
                  border: Border(
                      top: BorderSide(color: Color(0xFFC2C6D6), width: 1.5)))),
        ]),
      ),
    );
  }
}

class _ReadableTableThumb extends StatelessWidget {
  const _ReadableTableThumb();
  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF4A7CFF);
    const line = Color(0xFFE2E8F0);
    const selFill = Color(0x1A4A7CFF);
    return Container(
      color: const Color(0xFFF7F8FA),
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFC2C6D6)),
            borderRadius: BorderRadius.circular(5)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          // header with a sorted column arrow
          Container(
              height: 16,
              color: const Color(0xFFF7F8FA),
              child: Row(children: [
                for (int i = 0; i < 4; i++)
                  Expanded(
                      child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Row(children: [
                      Expanded(
                          child: Container(
                              height: 4,
                              color:
                                  i == 3 ? accent : const Color(0xFFBDC1C6))),
                      if (i == 3)
                        const Icon(Icons.arrow_downward_rounded,
                            size: 7, color: accent),
                    ]),
                  )),
              ])),
          Container(height: 1, color: const Color(0xFFC2C6D6)),
          // rows — two selected (accent fill + left bar)
          for (int r = 0; r < 4; r++)
            Expanded(
                child: Container(
              decoration: BoxDecoration(
                color: (r == 1 || r == 2) ? selFill : Colors.white,
                border: Border(
                  bottom: const BorderSide(color: line, width: 0.5),
                  left: (r == 1 || r == 2)
                      ? const BorderSide(color: accent, width: 2)
                      : BorderSide.none,
                ),
              ),
              child: Row(children: [
                for (int cIdx = 0; cIdx < 4; cIdx++)
                  Expanded(
                      child: Center(
                          child: cIdx == 1
                              ? Container(
                                  height: 5,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFFD7DCE6),
                                      borderRadius: BorderRadius.circular(2)))
                              : (cIdx == 2
                                  ? Container(
                                      width: 18,
                                      height: 7,
                                      decoration: BoxDecoration(
                                          color: accent.withOpacity(0.18),
                                          borderRadius:
                                              BorderRadius.circular(999)))
                                  : Container(
                                      height: 4,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 6),
                                      color: const Color(0xFFEEF1F7))))),
              ]),
            )),
        ]),
      ),
    );
  }
}

class _ErpConsoleThumb extends StatelessWidget {
  const _ErpConsoleThumb();
  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF4A7CFF);
    const border = Color(0xFFE2E8F0);
    Widget treeRow(int indent, bool folder, {bool sel = false}) => Container(
          height: 8,
          margin: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            SizedBox(width: 5.0 * indent),
            Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                    color: folder
                        ? accent.withOpacity(0.8)
                        : const Color(0xFFBDC1C6),
                    borderRadius: BorderRadius.circular(folder ? 1.5 : 2.5))),
            const SizedBox(width: 4),
            Expanded(
                child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                        color: sel
                            ? accent.withOpacity(0.5)
                            : const Color(0xFFD7DCE6),
                        borderRadius: BorderRadius.circular(2)))),
          ]),
        );
    return Container(
      color: const Color(0xFFF7F8FA),
      padding: const EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFC2C6D6)),
            borderRadius: BorderRadius.circular(6)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          // top bar
          Container(
              height: 14,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(children: [
                Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                        color: accent, borderRadius: BorderRadius.circular(2))),
                const Spacer(),
                Container(
                    width: 16,
                    height: 6,
                    decoration: BoxDecoration(
                        color: const Color(0xFFEEF1F7),
                        borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 4),
                Container(
                    width: 16,
                    height: 6,
                    decoration: BoxDecoration(
                        color: accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(3))),
              ])),
          Container(height: 1, color: border),
          Expanded(
              child: Row(children: [
            // tree sidebar
            Container(
                width: 58,
                color: const Color(0xFFF7F8FA),
                padding: const EdgeInsets.all(7),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      treeRow(0, true),
                      treeRow(1, false, sel: true),
                      treeRow(1, false),
                      treeRow(0, true),
                      treeRow(1, false),
                      treeRow(0, true),
                    ])),
            Container(width: 1, color: border),
            // workspace
            Expanded(
                child: Container(
                    color: const Color(0xFFF7F8FA),
                    padding: const EdgeInsets.all(7),
                    child: Column(children: [
                      // tabs
                      Row(children: [
                        Container(
                            width: 26,
                            height: 9,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(3)),
                                border: Border.all(color: border))),
                        const SizedBox(width: 2),
                        Container(
                            width: 22,
                            height: 9,
                            decoration: BoxDecoration(
                                color: const Color(0xFFEDEFF3),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(3)))),
                      ]),
                      const SizedBox(height: 5),
                      // KPI strip
                      Row(children: [
                        for (int i = 0; i < 3; i++) ...[
                          if (i > 0) const SizedBox(width: 4),
                          Expanded(
                              child: Container(
                                  height: 16,
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(3),
                                      border: Border.all(color: border)))),
                        ],
                      ]),
                      const SizedBox(height: 5),
                      // table
                      Expanded(
                          child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(color: border)),
                              child: Column(children: [
                                Container(
                                    height: 7,
                                    decoration: const BoxDecoration(
                                        color: Color(0xFFF1F3F8),
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(3)))),
                                for (int i = 0; i < 4; i++)
                                  Expanded(
                                      child: Container(
                                          decoration: BoxDecoration(
                                              border: Border(
                                                  bottom: BorderSide(
                                                      color: border,
                                                      width: 0.5))))),
                              ]))),
                    ]))),
          ])),
        ]),
      ),
    );
  }
}

class _TreeThumb extends StatelessWidget {
  const _TreeThumb();
  @override
  Widget build(BuildContext context) {
    const folder = Color(0xFF4A7CFF);
    const guide = Color(0xFFD7DCE6);
    Widget row(int indent, bool isFolder, {bool sel = false}) => Container(
          height: 13,
          margin: const EdgeInsets.symmetric(vertical: 1.5),
          decoration: BoxDecoration(
            color: sel ? const Color(0x1A4A7CFF) : Colors.transparent,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Row(children: [
            SizedBox(width: 8.0 * indent),
            if (indent > 0)
              Container(
                  width: 1,
                  height: 13,
                  color: guide,
                  margin: const EdgeInsets.only(right: 5)),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isFolder
                    ? folder.withOpacity(0.85)
                    : const Color(0xFFBDC1C6),
                borderRadius: BorderRadius.circular(isFolder ? 2 : 4),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
                child: Container(
                    height: 4,
                    color: isFolder
                        ? const Color(0xFFBDC1C6)
                        : const Color(0xFFD7DCE6))),
            const SizedBox(width: 8),
          ]),
        );
    return Container(
      color: const Color(0xFFF7F8FA),
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFC2C6D6)),
            borderRadius: BorderRadius.circular(5)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          Container(
              height: 16,
              color: const Color(0xFFF7F8FA),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: const Color(0xFFBDC1C6),
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 5),
                Expanded(
                    child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                            color: const Color(0xFFEEF1F7),
                            borderRadius: BorderRadius.circular(3)))),
              ])),
          Container(height: 1, color: const Color(0xFFC2C6D6)),
          Expanded(
              child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.start, children: [
              row(0, true),
              row(1, true),
              row(2, false),
              row(2, false, sel: true),
              row(1, false),
              row(0, false),
            ]),
          )),
        ]),
      ),
    );
  }
}

class _NavSidebarThumb extends StatelessWidget {
  const _NavSidebarThumb();
  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF4A7CFF);
    const border = Color(0xFFE2E8F0);
    Widget eyebrow() => Container(
        width: 22,
        height: 3,
        margin: const EdgeInsets.only(bottom: 5, top: 3),
        color: const Color(0xFFC2C6D6));
    Widget navRow({bool sel = false, bool box = false, double indent = 0}) =>
        Container(
          height: 11,
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: sel ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(children: [
            SizedBox(width: 6.0 * indent),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: sel
                    ? Colors.white
                    : (box ? Colors.transparent : const Color(0xFFBDC1C6)),
                border: box ? Border.all(color: const Color(0xFFC2C6D6)) : null,
                borderRadius: BorderRadius.circular(box ? 2 : 3.5),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
                child: Container(
                    height: 3,
                    color: sel ? Colors.white : const Color(0xFFD7DCE6))),
          ]),
        );
    return Container(
      color: const Color(0xFFF7F8FA),
      child: Column(children: [
        // app bar
        Container(
            height: 16,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 7),
            child: Row(children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: accent, borderRadius: BorderRadius.circular(2.5))),
              const SizedBox(width: 6),
              Expanded(
                  child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                          color: const Color(0xFFEEF1F7),
                          borderRadius: BorderRadius.circular(3)))),
              const SizedBox(width: 6),
              Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Color(0x294A7CFF), shape: BoxShape.circle)),
            ])),
        Container(height: 1, color: border),
        Expanded(
            child: Row(children: [
          // sidebar
          Container(
              width: 78,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(8, 9, 8, 8),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    eyebrow(),
                    navRow(),
                    navRow(),
                    eyebrow(),
                    navRow(),
                    navRow(indent: 1, sel: true),
                    navRow(indent: 1, box: true),
                    navRow(),
                  ])),
          Container(width: 1, color: border),
          // page
          Expanded(
              child: Container(
                  color: const Color(0xFFF7F8FA),
                  padding: const EdgeInsets.all(9),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            width: 40,
                            height: 8,
                            decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(2))),
                        const SizedBox(height: 9),
                        Row(children: [
                          for (int i = 0; i < 3; i++) ...[
                            if (i > 0) const SizedBox(width: 6),
                            Expanded(
                                child: Container(
                                    height: 26,
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: border)))),
                          ],
                        ]),
                        const SizedBox(height: 6),
                        Expanded(
                            child: Container(
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: border)))),
                      ]))),
        ])),
      ]),
    );
  }
}

// (removed unused launcher thumbnails: _FigmaThumb, _ChromeThumb, _DocsThumb, _Box)

// ── AutoSuggestionsBox: a search field with an open suggestions overlay ──
class _SuggestThumb extends StatelessWidget {
  const _SuggestThumb();
  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF4A7CFF);
    const line = Color(0xFFE2E8F0);
    Widget row({bool first = false}) => Container(
          height: 13,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: first ? const Color(0xFFEEF3FF) : Colors.white,
            border: Border(
                left: BorderSide(
                    color: first ? accent : Colors.transparent, width: 2)),
          ),
          child: Row(children: [
            Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                    color: Color(0xFFD7DCE6), shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Container(width: 14, height: 4, color: const Color(0xFFD7DCE6)),
            Container(width: 9, height: 4, color: accent),
            Container(width: 7, height: 4, color: const Color(0xFFD7DCE6)),
          ]),
        );
    return Container(
      color: const Color(0xFFF7F8FA),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // the field
        Container(
          height: 22,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: accent, width: 1.4),
              borderRadius: BorderRadius.circular(5)),
          child: Row(children: [
            const Icon(Icons.search_rounded, size: 11, color: accent),
            const SizedBox(width: 6),
            Container(width: 30, height: 4, color: const Color(0xFF0F172A)),
            Container(
                width: 1.5,
                height: 11,
                margin: const EdgeInsets.only(left: 1),
                color: accent),
          ]),
        ),
        const SizedBox(height: 4),
        // overlay
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: line),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            row(first: true),
            Container(height: 0.5, color: line),
            row(),
            Container(height: 0.5, color: line),
            row()
          ]),
        ),
      ]),
    );
  }
}

// ── EditableTable combo cell: a cell in edit mode with an auto-suggest overlay ──
class _ComboThumb extends StatelessWidget {
  const _ComboThumb();
  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF4A7CFF);
    const line = Color(0xFFE2E8F0);
    Widget sugg(String pre, String hit, String post, {bool first = false}) =>
        Container(
          height: 12,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          color: first ? const Color(0xFFEEF3FF) : Colors.white,
          alignment: Alignment.centerLeft,
          child: Row(children: [
            Container(width: 10, height: 4, color: const Color(0xFFD7DCE6)),
            Container(width: 6, height: 4, color: accent),
            Container(width: 8, height: 4, color: const Color(0xFFD7DCE6)),
          ]),
        );
    return Container(
      color: const Color(0xFFF7F8FA),
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFC2C6D6)),
            borderRadius: BorderRadius.circular(5)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          // header
          Container(
              height: 14,
              color: const Color(0xFFF7F8FA),
              child: Row(children: [
                for (int i = 0; i < 3; i++)
                  Expanded(
                      child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          height: 4,
                          color: const Color(0xFFBDC1C6))),
              ])),
          Container(height: 1, color: const Color(0xFFC2C6D6)),
          // a normal row
          SizedBox(
              height: 13,
              child: Row(children: [
                for (int i = 0; i < 3; i++)
                  Expanded(
                      child: Container(
                          decoration: const BoxDecoration(
                              border: Border(
                                  right: BorderSide(color: line, width: 0.5))),
                          child: Center(
                              child: Container(
                                  height: 4,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  color: const Color(0xFFEEF1F7))))),
              ])),
          // the editing row: middle cell is active + overlay
          Expanded(
              child: Stack(clipBehavior: Clip.none, children: [
            Row(children: [
              Expanded(
                  child: Container(
                      decoration: const BoxDecoration(
                          border: Border(
                              right: BorderSide(color: line, width: 0.5))))),
              Expanded(
                  child: Container(
                      decoration: BoxDecoration(
                          color: const Color(0x1A4A7CFF),
                          border: Border.all(color: accent, width: 1.5)),
                      child: Center(
                          child: Container(
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              color: accent)))),
              Expanded(
                  child: Container(
                      decoration: const BoxDecoration(
                          border: Border(
                              left: BorderSide(color: line, width: 0.5))))),
            ]),
            // suggestions overlay hanging under the active cell
            Positioned(
              left: 0,
              right: 0,
              top: 14,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: accent.withOpacity(0.45)),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 2))
                      ]),
                  clipBehavior: Clip.antiAlias,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    sugg('', '', '', first: true),
                    Container(height: 0.5, color: line),
                    sugg('', '', '')
                  ]),
                ),
              ),
            ),
          ])),
        ]),
      ),
    );
  }
}

// ── ReadableTable filter system: a filter chip bar above a filtered grid ──
class _FilterThumb extends StatelessWidget {
  const _FilterThumb();
  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF4A7CFF);
    const line = Color(0xFFE2E8F0);
    Widget chip({bool active = false}) => Container(
          height: 11,
          padding: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: active ? accent.withOpacity(0.14) : Colors.white,
            border: Border.all(
                color:
                    active ? accent.withOpacity(0.5) : const Color(0xFFC2C6D6)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(children: [
            Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                    color: active ? accent : const Color(0xFFBDC1C6),
                    shape: BoxShape.circle)),
            const SizedBox(width: 3),
            Container(
                width: active ? 16 : 12,
                height: 3,
                color: active ? accent : const Color(0xFFC2C6D6)),
          ]),
        );
    return Container(
      color: const Color(0xFFF7F8FA),
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFC2C6D6)),
            borderRadius: BorderRadius.circular(5)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          // filter bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
            decoration: const BoxDecoration(
                color: Color(0xFFF7F8FA),
                border: Border(bottom: BorderSide(color: Color(0xFFC2C6D6)))),
            child: Row(children: [
              const Icon(Icons.filter_alt_outlined, size: 10, color: accent),
              const SizedBox(width: 5),
              chip(active: true),
              const SizedBox(width: 4),
              chip(),
              const Spacer(),
              Container(
                  width: 14,
                  height: 7,
                  decoration: BoxDecoration(
                      color: const Color(0xFFEEF1F7),
                      borderRadius: BorderRadius.circular(3))),
            ]),
          ),
          // header
          Container(
              height: 12,
              color: Colors.white,
              child: Row(children: [
                for (int i = 0; i < 4; i++)
                  Expanded(
                      child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          height: 3,
                          color: const Color(0xFFBDC1C6))),
              ])),
          Container(height: 1, color: line),
          // filtered rows (fewer, with one highlighted as match)
          for (int r = 0; r < 3; r++)
            Expanded(
                child: Container(
              decoration: BoxDecoration(
                  border:
                      Border(bottom: const BorderSide(color: line, width: 0.5)),
                  color: r == 0 ? accent.withOpacity(0.05) : Colors.white),
              child: Row(children: [
                for (int cIdx = 0; cIdx < 4; cIdx++)
                  Expanded(
                      child: Center(
                          child: Container(
                              height: 3,
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              color: cIdx == 1
                                  ? const Color(0xFFD7DCE6)
                                  : const Color(0xFFEEF1F7)))),
              ]),
            )),
        ]),
      ),
    );
  }
}

// ── FilterEditingView: the grouped condition builder card ──
class _FilterEditingThumb extends StatelessWidget {
  const _FilterEditingThumb();
  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF4A7CFF);
    const line = Color(0xFFE2E8F0);
    Widget pill(Color c, double w) => Container(
        width: w,
        height: 7,
        decoration:
            BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)));
    Widget condition() => Container(
          margin: const EdgeInsets.only(bottom: 5),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: line),
              borderRadius: BorderRadius.circular(4)),
          child: Row(children: [
            pill(const Color(0xFFD7DCE6), 22),
            const SizedBox(width: 4),
            pill(accent.withOpacity(0.18), 16),
            const SizedBox(width: 4),
            Expanded(child: pill(const Color(0xFFEEF1F7), 0)),
            const SizedBox(width: 4),
            const Icon(Icons.close, size: 8, color: Color(0xFFBDC1C6)),
          ]),
        );
    return Container(
      color: const Color(0xFFF7F8FA),
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFC2C6D6)),
            borderRadius: BorderRadius.circular(6)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          // title bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: line))),
            child: Row(children: [
              const Icon(Icons.tune, size: 11, color: accent),
              const SizedBox(width: 5),
              pill(const Color(0xFF0F172A), 34),
              const Spacer(),
              Container(
                  width: 16,
                  height: 9,
                  decoration: BoxDecoration(
                      color: accent.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(3))),
            ]),
          ),
          // grouped conditions (AND/OR group with nested rows)
          Expanded(
              child: Container(
            padding: const EdgeInsets.all(8),
            child: Container(
              padding: const EdgeInsets.fromLTRB(7, 7, 7, 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                border: Border.all(color: accent.withOpacity(0.35)),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(3)),
                          child: const SizedBox(width: 14, height: 4)),
                      const SizedBox(width: 5),
                      pill(const Color(0xFFC2C6D6), 18),
                    ]),
                    const SizedBox(height: 6),
                    condition(),
                    condition(),
                  ]),
            ),
          )),
        ]),
      ),
    );
  }
}

// ── wraps a pushed demo with a floating "back to launcher" button ──
class _BackScaffold extends StatelessWidget {
  final Widget child;
  const _BackScaffold({required this.child});
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: child),
        Positioned(
          left: 16,
          bottom: 16,
          child: SafeArea(
            child: Material(
              color: Colors.black.withOpacity(0.62),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => Navigator.of(context).maybePop(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.arrow_back, size: 16, color: Colors.white),
                    SizedBox(width: 7),
                    Text('Demos',
                        style: TextStyle(
                            fontFamily: BrowserStyleTabBarThemeData.bodyFont,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── the documentation gallery, self-contained with a theme toggle ──
class _GalleryRoute extends StatefulWidget {
  const _GalleryRoute();
  @override
  State<_GalleryRoute> createState() => _GalleryRouteState();
}

class _GalleryRouteState extends State<_GalleryRoute> {
  bool _light = true;
  @override
  Widget build(BuildContext context) {
    return themed(
      brightness: _light ? Brightness.light : Brightness.dark,
      ext: _light
          ? BrowserStyleTabBarThemeData.light
          : BrowserStyleTabBarThemeData.dark,
      child: BrowserTabsDemo(
          light: _light, onToggleTheme: (v) => setState(() => _light = v)),
    );
  }
}
