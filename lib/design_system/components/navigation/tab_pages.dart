// ignore_for_file: deprecated_member_use

// ============================================================
// GLTabPage — realistic, content-rich pages per workspace tab kind.
// Rendered full-size in the active tab's content surface AND scaled down
// inside the hover preview, so the thumbnail is a true miniature of the
// real page (not a skeleton). Token-driven. Mirrors TabPages.jsx.
//   File: lib/design_system/components/navigation/tab_pages.dart
// ============================================================

import 'package:flutter/material.dart';
import 'browser_style_tab_bar_theme.dart';
import 'tab_models.dart';

const _blue = BrowserStyleTabBarThemeData.accent;

// ── tone → color (status pills / amounts) ──
Color _tone(BuildContext c, String tone) {
  final s = BrowserStyleTabBarThemeData.of(c);
  switch (tone) {
    case 'success':
      return BrowserStyleTabBarThemeData.success;
    case 'warning':
      return BrowserStyleTabBarThemeData.warning;
    case 'info':
      return _blue;
    case 'danger':
      return BrowserStyleTabBarThemeData.danger;
    default:
      return s.fg3;
  }
}

// ── small building blocks ──────────────────────────────────
class _Pill extends StatelessWidget {
  final String text;
  final String tone;
  const _Pill(this.text, {this.tone = 'neutral'});
  @override
  Widget build(BuildContext context) {
    final c = _tone(context, tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text,
          style: TextStyle(
              fontFamily: BrowserStyleTabBarThemeData.bodyFont,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.44,
              color: c)),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final bool primary;
  const _Btn(this.label, {this.primary = false});
  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: primary ? _blue : Colors.transparent,
        borderRadius:
            BorderRadius.circular(BrowserStyleTabBarThemeData.radiusMd),
        border:
            Border.all(color: primary ? Colors.transparent : s.borderStrong),
      ),
      child: Text(label,
          style: TextStyle(
              fontFamily: BrowserStyleTabBarThemeData.bodyFont,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: primary ? Colors.white : s.fg1)),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final double hue;
  final double size;
  const _Avatar(this.name, {this.hue = 230, this.size = 30});
  @override
  Widget build(BuildContext context) {
    final parts = name.split(' ').where((w) => w.isNotEmpty).take(2).toList();
    final initials = parts.map((w) => w[0]).join();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _oklchApprox(hue),
        shape: BoxShape.circle,
      ),
      child: Text(initials,
          style: TextStyle(
              fontFamily: BrowserStyleTabBarThemeData.displayFont,
              fontSize: size * 0.38,
              fontWeight: FontWeight.w700,
              color: Colors.white)),
    );
  }

  // Approximate oklch(0.42 0.09 hue) avatar fills with HSL.
  static Color _oklchApprox(double hue) =>
      HSLColor.fromAHSL(1, hue % 360, 0.42, 0.40).toColor();
}

class _Card extends StatelessWidget {
  final Widget child;
  final double pad;
  const _Card({required this.child, this.pad = 0});
  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: s.bg,
        border: Border.all(color: s.border),
        borderRadius:
            BorderRadius.circular(BrowserStyleTabBarThemeData.radiusLg),
      ),
      child: child,
    );
  }
}

class _Header extends StatelessWidget {
  final String crumb, title;
  final String? desc;
  final List<Widget> actions;
  const _Header(
      {required this.crumb,
      required this.title,
      this.desc,
      this.actions = const []});
  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(crumb,
                  style: TextStyle(
                      fontFamily: BrowserStyleTabBarThemeData.monoFont,
                      fontSize: 11,
                      letterSpacing: 0.44,
                      color: s.fg3)),
              const SizedBox(height: 7),
              Text(title,
                  style: TextStyle(
                      fontFamily: BrowserStyleTabBarThemeData.displayFont,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      color: s.fg1)),
              if (desc != null) ...[
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Text(desc!,
                      style: TextStyle(
                          fontFamily: BrowserStyleTabBarThemeData.bodyFont,
                          fontSize: 13.5,
                          height: 1.5,
                          color: s.fg3)),
                ),
              ],
            ],
          ),
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(width: 20),
          Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final String? delta;
  final bool up;
  const _Stat(
      {required this.label, required this.value, this.delta, this.up = true});
  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    return Expanded(
      child: _Card(
        pad: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontFamily: BrowserStyleTabBarThemeData.bodyFont,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: s.fg3)),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontFamily: BrowserStyleTabBarThemeData.displayFont,
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: s.fg1)),
            if (delta != null) ...[
              const SizedBox(height: 6),
              Text('${up ? '▲' : '▼'} $delta',
                  style: TextStyle(
                      fontFamily: BrowserStyleTabBarThemeData.bodyFont,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: up
                          ? BrowserStyleTabBarThemeData.success
                          : BrowserStyleTabBarThemeData.danger)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── generic data table ─────────────────────────────────────
class _Col {
  final String label;
  final int? flex; // null => use fixed width
  final double? width;
  final bool end;
  const _Col(this.label, {this.flex, this.width, this.end = false});
}

class _Cell {
  final String? v;
  final Widget? node;
  final bool strong;
  final bool mono;
  final bool pill;
  final String? tone;
  const _Cell(
      {this.v,
      this.node,
      this.strong = false,
      this.mono = false,
      this.pill = false,
      this.tone});
}

class _Table extends StatelessWidget {
  final List<_Col> cols;
  final List<List<_Cell>> rows;
  final Set<int> highlight;
  const _Table(
      {required this.cols, required this.rows, this.highlight = const {}});

  Widget _slot(_Col c, Widget child) {
    final aligned = Align(
        alignment: c.end ? Alignment.centerRight : Alignment.centerLeft,
        child: child);
    if (c.flex != null) return Expanded(flex: c.flex!, child: aligned);
    return SizedBox(width: c.width, child: aligned);
  }

  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    return _Card(
      child: Column(
        children: [
          // header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: s.border))),
            child: Row(
              children: cols
                  .map((c) => _slot(
                        c,
                        Text(c.label.toUpperCase(),
                            style: TextStyle(
                                fontFamily:
                                    BrowserStyleTabBarThemeData.monoFont,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: s.fg3)),
                      ))
                  .toList(),
            ),
          ),
          // rows
          for (int ri = 0; ri < rows.length; ri++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              decoration: BoxDecoration(
                color: highlight.contains(ri)
                    ? _blue.withOpacity(0.07)
                    : Colors.transparent,
                border: ri < rows.length - 1
                    ? Border(bottom: BorderSide(color: s.border))
                    : null,
              ),
              child: Row(
                children: [
                  for (int ci = 0; ci < cols.length; ci++)
                    _slot(cols[ci], _buildCell(context, rows[ri][ci]))
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCell(BuildContext context, _Cell cell) {
    final s = BrowserStyleTabBarThemeData.of(context);
    if (cell.node != null) return cell.node!;
    if (cell.pill) return _Pill(cell.v ?? '', tone: cell.tone ?? 'neutral');
    final color = cell.tone != null
        ? _tone(context, cell.tone!)
        : (cell.strong ? s.fg1 : s.fg2);
    return Text(cell.v ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
            fontFamily: cell.mono
                ? BrowserStyleTabBarThemeData.monoFont
                : BrowserStyleTabBarThemeData.bodyFont,
            fontSize: 13,
            fontWeight: cell.strong ? FontWeight.w600 : FontWeight.w500,
            color: color));
  }
}

String _sar(String n) => 'SAR $n';

// ── PAGES ───────────────────────────────────────────────────
class _PageLedger extends StatelessWidget {
  final BrowserTab tab;
  const _PageLedger(this.tab);
  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    final rows = [
      ['1000', 'Cash on Hand', 'Asset', '24,500.00'],
      ['1010', 'Bank — NCB Current', 'Asset', '318,920.45'],
      ['1200', 'Accounts Receivable', 'Asset', '87,340.00'],
      ['1400', 'Inventory', 'Asset', '156,200.00'],
      ['2000', 'Accounts Payable', 'Liability', '64,180.30'],
      ['3000', "Owner's Capital", 'Equity', '400,000.00'],
      ['4000', 'Sales Revenue', 'Income', '512,660.00'],
      ['5000', 'Cost of Goods Sold', 'Expense', '233,410.00'],
      ['6000', 'Salaries Expense', 'Expense', '96,000.00'],
    ];
    const toneFor = {
      'Asset': 'info',
      'Liability': 'warning',
      'Equity': 'neutral',
      'Income': 'success',
      'Expense': 'danger',
    };
    Widget filter(String t, {bool grow = false}) {
      final chip = Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: grow ? s.inputBg : Colors.transparent,
          border: Border.all(color: s.borderStrong),
          borderRadius:
              BorderRadius.circular(BrowserStyleTabBarThemeData.radiusMd),
        ),
        child: Text(t,
            style: TextStyle(
                fontFamily: BrowserStyleTabBarThemeData.bodyFont,
                fontSize: 13,
                color: grow ? s.fg3 : s.fg2)),
      );
      return grow ? Expanded(child: chip) : chip;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          crumb: 'Accounting / General Ledger',
          title: tab.title,
          desc:
              'Every posting account in the workspace, grouped by classification with live balances.',
          actions: const [_Btn('Export'), _Btn('New account', primary: true)],
        ),
        const SizedBox(height: 20),
        Row(children: [
          filter('Search accounts…', grow: true),
          const SizedBox(width: 10),
          filter('All types ▾'),
          const SizedBox(width: 10),
          filter('FY 2024 ▾'),
        ]),
        const SizedBox(height: 16),
        _Table(
          cols: const [
            _Col('Code', width: 70),
            _Col('Account', flex: 1),
            _Col('Type', width: 120),
            _Col('Balance', width: 150, end: true),
          ],
          highlight: const {1},
          rows: [
            for (final r in rows)
              [
                _Cell(v: r[0], mono: true),
                _Cell(v: r[1], strong: true),
                _Cell(v: r[2], pill: true, tone: toneFor[r[2]]),
                _Cell(v: _sar(r[3]), mono: true, strong: true),
              ]
          ],
        ),
      ],
    );
  }
}

class _PageDoc extends StatelessWidget {
  final BrowserTab tab;
  const _PageDoc(this.tab);
  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    final lines = [
      ['1000', 'Cash on Hand', '120,000.00', ''],
      ['1010', 'Bank — NCB Current', '280,000.00', ''],
      ['1400', 'Inventory', '156,200.00', ''],
      ['3000', "Owner's Capital", '', '556,200.00'],
    ];
    final meta = [
      ['Date', '01 Jan 2024'],
      ['Reference', 'JV-2024-0042'],
      ['Period', 'FY2024 · P1'],
      ['Prepared by', 'M. Nasser'],
    ];
    Widget total(String label, String value, {Color? color}) => Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(label.toUpperCase(),
                style: TextStyle(
                    fontFamily: BrowserStyleTabBarThemeData.monoFont,
                    fontSize: 10.5,
                    letterSpacing: 0.5,
                    color: s.fg3)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontFamily: BrowserStyleTabBarThemeData.monoFont,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color ?? s.fg1)),
          ],
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          crumb: 'Accounting / Journal',
          title: tab.title,
          actions: const [
            _Pill('UNSAVED', tone: 'warning'),
            _Btn('Discard'),
            _Btn('Post entry', primary: true)
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            for (int i = 0; i < meta.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(
                child: _Card(
                  pad: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meta[i][0].toUpperCase(),
                          style: TextStyle(
                              fontFamily: BrowserStyleTabBarThemeData.monoFont,
                              fontSize: 10.5,
                              letterSpacing: 0.5,
                              color: s.fg3)),
                      const SizedBox(height: 6),
                      Text(meta[i][1],
                          style: TextStyle(
                              fontFamily: BrowserStyleTabBarThemeData.bodyFont,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: s.fg1)),
                    ],
                  ),
                ),
              ),
            ]
          ],
        ),
        const SizedBox(height: 16),
        _Table(
          cols: const [
            _Col('Code', width: 70),
            _Col('Account', flex: 1),
            _Col('Debit', width: 140, end: true),
            _Col('Credit', width: 140, end: true),
          ],
          rows: [
            for (final l in lines)
              [
                _Cell(v: l[0], mono: true),
                _Cell(v: l[1], strong: true),
                _Cell(
                    v: l[2].isNotEmpty ? _sar(l[2]) : '—',
                    mono: true,
                    tone: l[2].isEmpty ? 'neutral' : null),
                _Cell(
                    v: l[3].isNotEmpty ? _sar(l[3]) : '—',
                    mono: true,
                    tone: l[3].isEmpty ? 'neutral' : null),
              ]
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            total('Total debit', 'SAR 556,200.00'),
            const SizedBox(width: 40),
            total('Total credit', 'SAR 556,200.00'),
            const SizedBox(width: 40),
            total('Difference', 'SAR 0.00',
                color: BrowserStyleTabBarThemeData.success),
          ],
        ),
      ],
    );
  }
}

class _PageStore extends StatelessWidget {
  final BrowserTab tab;
  const _PageStore(this.tab);
  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    final details = [
      ['Address', 'King Fahd Rd, Al Olaya, Riyadh'],
      ['Manager', 'Sara Al-Otaibi'],
      ['Hours', '09:00 – 23:00 · Daily'],
      ['Phone', '+966 11 555 0123'],
      ['Tax ID', '3001-4429-77'],
    ];
    final shift = [
      ['Sara Al-Otaibi', 'Manager', '200'],
      ['Lina Haddad', 'Cashier', '30'],
      ['Khalid Faisal', 'Inventory', '140'],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // banner
        Container(
          height: 96,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(BrowserStyleTabBarThemeData.radiusLg),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                HSLColor.fromAHSL(1, 250, 0.35, 0.38).toColor(),
                HSLColor.fromAHSL(1, 220, 0.32, 0.32).toColor()
              ],
            ),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BRANCH · RYD-01',
                        style: TextStyle(
                            fontFamily: BrowserStyleTabBarThemeData.monoFont,
                            fontSize: 11,
                            letterSpacing: 0.5,
                            color: Colors.white.withOpacity(0.7))),
                    const SizedBox(height: 4),
                    Text(tab.title,
                        style: const TextStyle(
                            fontFamily: BrowserStyleTabBarThemeData.displayFont,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ],
                ),
              ),
              const Align(
                  alignment: Alignment.topRight,
                  child: _Pill('OPEN', tone: 'success')),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(children: const [
          _Stat(
              label: "Today's sales",
              value: 'SAR 18,420',
              delta: '6.2% vs avg',
              up: true),
          SizedBox(width: 12),
          _Stat(
              label: 'Transactions',
              value: '142',
              delta: '12 in last hour',
              up: true),
          SizedBox(width: 12),
          _Stat(
              label: 'Avg basket',
              value: 'SAR 129.70',
              delta: '1.4%',
              up: false),
        ]),
        const SizedBox(height: 18),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: _Card(
                  pad: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Store details',
                          style: TextStyle(
                              fontFamily: BrowserStyleTabBarThemeData.bodyFont,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: s.fg1)),
                      const SizedBox(height: 12),
                      for (int i = 0; i < details.length; i++)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                              border: i < details.length - 1
                                  ? Border(bottom: BorderSide(color: s.border))
                                  : null),
                          child: Row(
                            children: [
                              Text(details[i][0],
                                  style: TextStyle(
                                      fontFamily:
                                          BrowserStyleTabBarThemeData.bodyFont,
                                      fontSize: 13,
                                      color: s.fg3)),
                              const Spacer(),
                              Flexible(
                                child: Text(details[i][1],
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        fontFamily: BrowserStyleTabBarThemeData
                                            .bodyFont,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: s.fg1)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 5,
                child: _Card(
                  pad: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('On shift',
                          style: TextStyle(
                              fontFamily: BrowserStyleTabBarThemeData.bodyFont,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: s.fg1)),
                      const SizedBox(height: 12),
                      for (final p in shift)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              _Avatar(p[0], hue: double.parse(p[2]), size: 32),
                              const SizedBox(width: 11),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p[0],
                                      style: TextStyle(
                                          fontFamily:
                                              BrowserStyleTabBarThemeData
                                                  .bodyFont,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: s.fg1)),
                                  Text(p[1],
                                      style: TextStyle(
                                          fontFamily:
                                              BrowserStyleTabBarThemeData
                                                  .bodyFont,
                                          fontSize: 11.5,
                                          color: s.fg3)),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PageDashboard extends StatelessWidget {
  final BrowserTab tab;
  const _PageDashboard(this.tab);
  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    final bars = [
      ['Jan', 58],
      ['Feb', 72],
      ['Mar', 49],
      ['Apr', 81],
      ['May', 66],
      ['Jun', 94],
      ['Jul', 77]
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          crumb: 'Overview',
          title: tab.title,
          desc: 'Live financial position across all branches, month to date.',
          actions: const [
            _Btn('Last 7 months ▾'),
            _Btn('Export report', primary: true)
          ],
        ),
        const SizedBox(height: 20),
        Row(children: const [
          _Stat(
              label: 'Revenue MTD',
              value: 'SAR 512,660',
              delta: '8.4%',
              up: true),
          SizedBox(width: 12),
          _Stat(
              label: 'Expenses MTD',
              value: 'SAR 329,410',
              delta: '3.1%',
              up: false),
          SizedBox(width: 12),
          _Stat(
              label: 'Net profit',
              value: 'SAR 183,250',
              delta: '18.2%',
              up: true),
          SizedBox(width: 12),
          _Stat(
              label: 'Cash position',
              value: 'SAR 343,420',
              delta: '2.0%',
              up: true),
        ]),
        const SizedBox(height: 16),
        _Card(
          pad: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Monthly revenue',
                      style: TextStyle(
                          fontFamily: BrowserStyleTabBarThemeData.bodyFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: s.fg1)),
                  const _Pill('▲ 8.4% YoY', tone: 'success'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 150,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (int i = 0; i < bars.length; i++) ...[
                      if (i > 0) const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 46),
                              child: Container(
                                width: double.infinity,
                                height: ((bars[i][1] as int) / 100) * 122,
                                decoration: BoxDecoration(
                                  color:
                                      i == 5 ? _blue : _blue.withOpacity(0.28),
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(bars[i][0] as String,
                                style: TextStyle(
                                    fontFamily:
                                        BrowserStyleTabBarThemeData.monoFont,
                                    fontSize: 11,
                                    color: s.fg3)),
                          ],
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PagePeople extends StatelessWidget {
  final BrowserTab tab;
  const _PagePeople(this.tab);
  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    final people = [
      [
        'Sara Al-Otaibi',
        'Branch Manager',
        'Riyadh',
        'Active',
        'success',
        '200'
      ],
      [
        'Mohammed Nasser',
        'Accountant',
        'Head Office',
        'Active',
        'success',
        '250'
      ],
      ['Lina Haddad', 'Cashier', 'Riyadh', 'On leave', 'warning', '30'],
      ['Khalid Faisal', 'Inventory Lead', 'Jeddah', 'Active', 'success', '140'],
      ['Noura Saleh', 'Sales Associate', 'Riyadh', 'Invited', 'info', '320'],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          crumb: 'Organization',
          title: tab.title,
          desc: 'Team members with workspace access and their current status.',
          actions: const [_Btn('Filter'), _Btn('Invite people', primary: true)],
        ),
        const SizedBox(height: 20),
        _Table(
          cols: const [
            _Col('Name', flex: 1),
            _Col('Role', width: 160),
            _Col('Location', width: 130),
            _Col('Status', width: 110, end: true),
          ],
          rows: [
            for (final p in people)
              [
                _Cell(
                  node: Row(children: [
                    _Avatar(p[0], hue: double.parse(p[5]), size: 30),
                    const SizedBox(width: 11),
                    Flexible(
                      child: Text(p[0],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontFamily: BrowserStyleTabBarThemeData.bodyFont,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: s.fg1)),
                    ),
                  ]),
                ),
                _Cell(v: p[1]),
                _Cell(v: p[2]),
                _Cell(v: p[3], pill: true, tone: p[4]),
              ]
          ],
        ),
      ],
    );
  }
}

class _PageGeneric extends StatelessWidget {
  final BrowserTab tab;
  const _PageGeneric(this.tab);
  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    final activity = [
      ['Posted JV-2024-0042', '2m ago'],
      ['Reconciled NCB account', '1h ago'],
      ['Added store · Jeddah North', '3h ago'],
      ['Invited Noura Saleh', 'Yesterday'],
    ];
    final platforms = [
      ['Salla', true],
      ['Zid', true],
      ['Foodics POS', false]
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          crumb: 'Workspace',
          title: tab.title,
          desc: 'Overview of recent activity and connected services.',
          actions: const [_Btn('Settings', primary: true)],
        ),
        const SizedBox(height: 20),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Card(
                  pad: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recent activity',
                          style: TextStyle(
                              fontFamily: BrowserStyleTabBarThemeData.bodyFont,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: s.fg1)),
                      const SizedBox(height: 12),
                      for (int i = 0; i < activity.length; i++)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                              border: i < activity.length - 1
                                  ? Border(bottom: BorderSide(color: s.border))
                                  : null),
                          child: Row(
                            children: [
                              Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                      color: _blue, shape: BoxShape.circle)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(activity[i][0],
                                    style: TextStyle(
                                        fontFamily: BrowserStyleTabBarThemeData
                                            .bodyFont,
                                        fontSize: 13,
                                        color: s.fg1)),
                              ),
                              Text(activity[i][1],
                                  style: TextStyle(
                                      fontFamily:
                                          BrowserStyleTabBarThemeData.monoFont,
                                      fontSize: 11.5,
                                      color: s.fg3)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _Card(
                  pad: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Connected platforms',
                          style: TextStyle(
                              fontFamily: BrowserStyleTabBarThemeData.bodyFont,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: s.fg1)),
                      const SizedBox(height: 12),
                      for (int i = 0; i < platforms.length; i++)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                              border: i < platforms.length - 1
                                  ? Border(bottom: BorderSide(color: s.border))
                                  : null),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(platforms[i][0] as String,
                                    style: TextStyle(
                                        fontFamily: BrowserStyleTabBarThemeData
                                            .bodyFont,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: s.fg1)),
                              ),
                              if (platforms[i][1] as bool)
                                const _Pill('Connected', tone: 'success')
                              else
                                const _Btn('Connect'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Full-size page for a tab. Fluid width — fills its container.
class GLTabPage extends StatelessWidget {
  /// Tab model used to select the demo page type and title.
  final BrowserTab tab;

  /// Creates a content page for [tab].
  const GLTabPage({super.key, required this.tab});
  @override
  Widget build(BuildContext context) {
    switch (tab.kind) {
      case GLTabKind.ledger:
        return _PageLedger(tab);
      case GLTabKind.doc:
        return _PageDoc(tab);
      case GLTabKind.store:
        return _PageStore(tab);
      case GLTabKind.chart:
        return _PageDashboard(tab);
      case GLTabKind.user:
        return _PagePeople(tab);
      case GLTabKind.globe:
        return _PageGeneric(tab);
    }
  }
}
