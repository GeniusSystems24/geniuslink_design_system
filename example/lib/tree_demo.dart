// ============================================================
// Tree — demo gallery  →  ACCOUNT TREE.
// ------------------------------------------------------------
// Rebuilt to mirror the GeniusLink "Account Tree" tool (the web
// components-tree gallery): an interactive five-level chart of accounts with
// KPI summary cards, a recursive search that matches code + English + Arabic
// (with live in-row highlighting), colour-coded type filter chips, roll-up
// balances with proportional share bars, DR / CR nature pills, leaf-count
// badges and an accounting-equation balance check.
//
// State (expansion · selection · search query) is driven by the library's own
// TreeController, painted with TreeThemeData (dark / light). Rows are rendered
// in the account-specific 4-column layout that the generic Tree view does not
// ship — proving the same MVC core re-skins into a domain widget.
// Sample data lives in account_tree_data.dart.
//   File: example/lib/tree_demo.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:geniuslink_design_system/geniuslink_tree.dart';
import 'account_tree_data.dart';

// ── account-type palette (mirrors the web TYPE_DOT / nature maps) ──
const Map<String, Color> _typeDot = {
  'Asset': Color(0xFF4A7CFF),
  'Liability': Color(0xFFF97316),
  'Equity': Color(0xFF1DB88A),
  'Income': Color(0xFF38BDF8),
  'Expense': Color(0xFFEF4444),
};
const Map<String, String> _typeNature = {
  'Asset': 'debit',
  'Expense': 'debit',
  'Liability': 'credit',
  'Equity': 'credit',
  'Income': 'credit',
};
const List<String> _typeOrder = ['Asset', 'Liability', 'Equity', 'Income', 'Expense'];

// ── tree maths ──
int _nodeTotal(TreeNode n) =>
    n.children.isEmpty ? (n.data['bal'] as int? ?? 0) : n.children.fold(0, (s, c) => s + _nodeTotal(c));
int _leafCount(TreeNode n) =>
    n.children.isEmpty ? 1 : n.children.fold(0, (s, c) => s + _leafCount(c));

String _searchable(TreeNode n) => '${n.id} ${n.label} ${n.data['ar'] ?? ''}'.toLowerCase();

/// Recursive filter: keep a node if it (or any descendant) matches; a hit
/// retains its whole subtree, a deep hit keeps its ancestors.
List<TreeNode> _filterTree(List<TreeNode> nodes, String q) {
  final needle = q.trim().toLowerCase();
  if (needle.isEmpty) return nodes;
  TreeNode? walk(TreeNode n) {
    final self = _searchable(n).contains(needle);
    final kids = n.children.isEmpty ? const <TreeNode>[] : n.children.map(walk).whereType<TreeNode>().toList();
    if (self) return n;
    if (kids.isNotEmpty) return n.copyWith(children: kids);
    return null;
  }

  return nodes.map(walk).whereType<TreeNode>().toList();
}

int _countMatches(List<TreeNode> nodes, String q) {
  final needle = q.trim().toLowerCase();
  if (needle.isEmpty) return 0;
  var c = 0;
  void w(TreeNode n) {
    if (_searchable(n).contains(needle)) c++;
    for (final k in n.children) w(k);
  }

  for (final n in nodes) w(n);
  return c;
}

/// Thousands-grouped amount with two decimals (no intl dependency).
String _fmt(num n) {
  final neg = n < 0;
  final whole = n.abs().floor();
  final s = whole.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return '${neg ? '-' : ''}${b.toString()}.00';
}

String _fmtShort(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(2)}M';
  if (n >= 1000) return '${(n / 1000).round()}K';
  return '$n';
}

/// Group ids at depth ≤ [maxD] (for the default expansion).
Set<String> _groupCodes(List<TreeNode> nodes, int maxD) {
  final out = <String>{};
  void w(List<TreeNode> ns, int d) {
    for (final n in ns) {
      if (n.children.isNotEmpty) {
        if (d <= maxD) out.add(n.id);
        w(n.children, d + 1);
      }
    }
  }

  w(nodes, 0);
  return out;
}

class TreeDemo extends StatefulWidget {
  const TreeDemo({super.key});
  @override
  State<TreeDemo> createState() => _TreeDemoState();
}

class _TreeDemoState extends State<TreeDemo> {
  bool _light = true;
  String _typeFilter = 'all';
  String? _opened;

  final TextEditingController _searchCtrl = TextEditingController();
  late final TreeController _c = TreeController(roots: kAccountTreeRoots, expanded: _groupCodes(kAccountTreeRoots, 1));

  static const List<String> _samples = ['1111', 'Bank', 'البنك', 'Cash', 'Loan', '5512'];

  @override
  void dispose() {
    _c.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _runQuery(String q) {
    _searchCtrl.value = TextEditingValue(text: q, selection: TextSelection.collapsed(offset: q.length));
    _c.setQuery(q);
  }

  @override
  Widget build(BuildContext context) {
    final ext = _light ? TreeThemeData.light : TreeThemeData.dark;
    return Theme(
      data: ThemeData(
        brightness: _light ? Brightness.light : Brightness.dark,
        useMaterial3: true,
        fontFamily: TreeThemeData.bodyFont,
        scaffoldBackgroundColor: ext.bg,
        extensions: [ext],
      ),
      child: Builder(builder: (context) {
        final t = TreeThemeData.of(context);
        return Scaffold(
          backgroundColor: t.bg,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) {
                    final query = _c.query;
                    final searching = query.trim().isNotEmpty;
                    final byType =
                        _typeFilter == 'all' ? kAccountTreeRoots : kAccountTreeRoots.where((n) => n.data['type'] == _typeFilter).toList();
                    final visible = _filterTree(byType, query);
                    final matches = _countMatches(byType, query);

                    int totalOf(String type) =>
                        kAccountTreeRoots.where((n) => n.data['type'] == type).fold(0, (s, n) => s + _nodeTotal(n));
                    final assets = totalOf('Asset'), liabilities = totalOf('Liability'), equity = totalOf('Equity');
                    final income = totalOf('Income'), expense = totalOf('Expense');
                    final balanced = (assets - (liabilities + equity)).abs() < 1;
                    final totalAccounts = kAccountTreeRoots.fold(0, (s, n) => s + _leafCount(n));
                    final visibleAccounts = visible.fold(0, (s, n) => s + _leafCount(n));

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(28, 36, 28, 80),
                      children: [
                        _header(t),
                        const SizedBox(height: 28),
                        // KPI summary
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(child: _kpi(t, 'TOTAL ASSETS', 'الأصول', _fmt(assets), _typeDot['Asset']!, 'SAR · debit balance')),
                          const SizedBox(width: 14),
                          Expanded(child: _kpi(t, 'TOTAL LIABILITIES', 'الخصوم', _fmt(liabilities), _typeDot['Liability']!, 'SAR · credit balance')),
                          const SizedBox(width: 14),
                          Expanded(child: _kpi(t, 'TOTAL EQUITY', 'حقوق الملكية', _fmt(equity), _typeDot['Equity']!, 'SAR · credit balance')),
                          const SizedBox(width: 14),
                          Expanded(child: _kpi(t, 'NET INCOME', 'صافي الدخل', _fmt(income - expense), _typeDot['Income']!, 'Income ${_fmtShort(income)} − Expense ${_fmtShort(expense)} SAR')),
                        ]),
                        const SizedBox(height: 16),
                        _toolbar(t, query, searching, matches, balanced),
                        const SizedBox(height: 16),
                        _treePanel(t, visible, searching, query, totalAccounts, visibleAccounts),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── header ──
  Widget _header(TreeThemeData t) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('GENIUSLINK DESIGN SYSTEM',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.6, color: TreeThemeData.accent)),
              const SizedBox(height: 10),
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Text('Account Tree',
                    style: TextStyle(fontFamily: TreeThemeData.displayFont, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: t.fg1)),
                const SizedBox(width: 12),
                Text('شجرة الحسابات', textDirection: TextDirection.rtl, style: TextStyle(fontSize: 20, color: t.fg3)),
              ]),
              const SizedBox(height: 8),
              Text(
                'A five-level chart of accounts. Search by code or name, filter by type, '
                'expand or collapse branches, and open a posting account. Balances roll up '
                'from the leaves and the equation badge confirms the books balance.',
                style: TextStyle(fontSize: 14, height: 1.5, color: t.fg3),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _ThemeToggle(light: _light, onChanged: (v) => setState(() => _light = v)),
      ],
    );
  }

  // ── KPI card ──
  Widget _kpi(TreeThemeData t, String label, String ar, String value, Color accent, String sub) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(TreeThemeData.radiusLg),
      child: Container(
        decoration: BoxDecoration(
          color: t.surface,
          border: Border.all(color: t.border),
          borderRadius: BorderRadius.circular(TreeThemeData.radiusLg),
        ),
        child: Stack(
          children: [
            Positioned(left: 0, top: 0, bottom: 0, width: 3, child: Container(color: accent)),
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 15, 15, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: t.fg3))),
                      const SizedBox(width: 6),
                      Text(ar, textDirection: TextDirection.rtl, style: TextStyle(fontSize: 11, color: t.fg4)),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(value, style: TextStyle(fontFamily: TreeThemeData.monoFont, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: t.fg1)),
                  const SizedBox(height: 6),
                  Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: t.fg3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── toolbar (search + try chips + type chips + balance badge) ──
  Widget _toolbar(TreeThemeData t, String query, bool searching, int matches, bool balanced) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(TreeThemeData.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _searchField(t, query, searching, matches)),
              const SizedBox(width: 12),
              _toolBtn(t, Icons.unfold_more, 'Expand all', _c.expandAll),
              const SizedBox(width: 8),
              _toolBtn(t, Icons.unfold_less, 'Collapse', _c.collapseAll),
            ],
          ),
          const SizedBox(height: 14),
          // try chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('TRY', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: t.fg3)),
              for (final q in _samples) _sampleChip(t, q, query == q),
            ],
          ),
          const SizedBox(height: 14),
          // type chips + balance badge
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _filterChip(t, 'all', 'All', null),
                    for (final ty in _typeOrder) _filterChip(t, ty, ty, _typeDot[ty]),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _balanceBadge(t, balanced),
            ],
          ),
        ],
      ),
    );
  }

  Widget _searchField(TreeThemeData t, String query, bool searching, int matches) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: _searchCtrl,
        onChanged: _c.setQuery,
        style: TextStyle(color: t.fg1, fontSize: 13.5),
        cursorColor: TreeThemeData.accent,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search by code, English or Arabic name…',
          hintStyle: TextStyle(color: t.fg3, fontSize: 13.5),
          prefixIcon: Icon(Icons.search, size: 16, color: t.fg3),
          prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 0),
          suffixIcon: searching
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$matches', style: TextStyle(fontFamily: TreeThemeData.monoFont, fontSize: 11, color: t.fg3)),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _runQuery(''),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.close, size: 14, color: t.fg3)),
                    ),
                  ],
                )
              : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          filled: true,
          fillColor: t.inputBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TreeThemeData.radiusSm),
            borderSide: BorderSide(color: t.borderStrong),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TreeThemeData.radiusSm),
            borderSide: const BorderSide(color: TreeThemeData.accent, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _toolBtn(TreeThemeData t, IconData icon, String label, VoidCallback onTap) {
    return _Hoverable(builder: (hover) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TreeThemeData.radiusSm),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: hover ? t.hover : Colors.transparent,
            border: Border.all(color: t.borderStrong),
            borderRadius: BorderRadius.circular(TreeThemeData.radiusSm),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 16, color: t.fg2),
            const SizedBox(width: 7),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: t.fg1)),
          ]),
        ),
      );
    });
  }

  Widget _sampleChip(TreeThemeData t, String q, bool on) {
    return GestureDetector(
      onTap: () => _runQuery(q),
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? Color.alphaBlend(TreeThemeData.accent.withOpacity(0.18), t.surface) : t.inputBg,
          border: Border.all(color: on ? TreeThemeData.accent : t.border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(q,
            textDirection: TextDirection.ltr,
            style: TextStyle(fontFamily: TreeThemeData.monoFont, fontSize: 11.5, color: on ? TreeThemeData.accent : t.fg2)),
      ),
    );
  }

  Widget _filterChip(TreeThemeData t, String id, String label, Color? color) {
    final active = _typeFilter == id;
    return GestureDetector(
      onTap: () => setState(() => _typeFilter = id),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active ? (color != null ? color.withOpacity(0.12) : t.hover) : Colors.transparent,
          border: Border.all(color: active ? (color ?? t.borderStrong) : t.border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (color != null) ...[
            Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 7),
          ],
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: active ? (color ?? t.fg1) : t.fg2)),
        ]),
      ),
    );
  }

  Widget _balanceBadge(TreeThemeData t, bool balanced) {
    final c = balanced ? TreeThemeData.success : TreeThemeData.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        border: Border.all(color: c.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(balanced ? Icons.check : Icons.error_outline, size: 13, color: c),
        const SizedBox(width: 8),
        Text(balanced ? 'BALANCED · A = L + E' : 'OUT OF BALANCE',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: c)),
      ]),
    );
  }

  // ── tree panel ──
  Widget _treePanel(TreeThemeData t, List<TreeNode> visible, bool searching, String query, int totalAccounts, int visibleAccounts) {
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(TreeThemeData.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // title row
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 4, height: 36, margin: const EdgeInsets.only(top: 2, right: 11), decoration: BoxDecoration(color: TreeThemeData.accent, borderRadius: BorderRadius.circular(12))),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Chart of Accounts Hierarchy', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.fg1)),
                      const SizedBox(height: 2),
                      Text('5 levels · click a group to expand, click a leaf to open its ledger', style: TextStyle(fontSize: 12, color: t.fg3)),
                    ],
                  ),
                ),
                Text(searching ? '$visibleAccounts of $totalAccounts' : '$totalAccounts accounts',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: t.fg3)),
              ],
            ),
          ),
          // column header
          Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.border))),
            child: Row(children: [
              Expanded(child: Text('ACCOUNT · الحساب', style: _colHead(t))),
              const SizedBox(width: 12),
              SizedBox(width: 64, child: Text('NATURE', style: _colHead(t))),
              const SizedBox(width: 12),
              SizedBox(width: 168, child: Text('BALANCE (SAR)', textAlign: TextAlign.right, style: _colHead(t))),
              const SizedBox(width: 12),
              const SizedBox(width: 26),
            ]),
          ),
          // body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: visible.isEmpty
                ? _emptyState(t, query)
                : Column(
                    children: [
                      for (final n in visible)
                        _AccountRow(
                          node: n,
                          depth: 0,
                          rootTotal: _nodeTotal(n),
                          forceOpen: searching,
                          controller: _c,
                          query: query,
                          onOpen: (node) {
                            setState(() => _opened = node.id);
                            _c.select(node.id);
                          },
                        ),
                    ],
                  ),
          ),
          if (_opened != null) _openedStrip(t),
        ],
      ),
    );
  }

  TextStyle _colHead(TreeThemeData t) =>
      TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: t.fg3);

  Widget _emptyState(TreeThemeData t, String query) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 44),
      alignment: Alignment.center,
      child: Column(children: [
        Icon(Icons.search_off, size: 26, color: t.fg4),
        const SizedBox(height: 12),
        Text('No accounts match “$query”', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.fg2)),
        const SizedBox(height: 4),
        Text('Try a different code or name, or clear the filters.', style: TextStyle(fontSize: 12, color: t.fg3)),
      ]),
    );
  }

  Widget _openedStrip(TreeThemeData t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Color.alphaBlend(TreeThemeData.accent.withOpacity(0.07), t.surface),
        border: Border(top: BorderSide(color: t.border)),
      ),
      child: Row(children: [
        Icon(Icons.description_outlined, size: 15, color: TreeThemeData.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(TextSpan(style: TextStyle(fontSize: 12.5, color: t.fg2), children: [
            const TextSpan(text: 'Opened ledger for account '),
            TextSpan(text: _opened, style: TextStyle(fontFamily: TreeThemeData.monoFont, fontWeight: FontWeight.w700, color: t.fg1)),
          ])),
        ),
        InkWell(
          onTap: () => setState(() => _opened = null),
          borderRadius: BorderRadius.circular(4),
          child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.close, size: 14, color: t.fg3)),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════
// One account row — recursive, with the 4-column account layout.
// ════════════════════════════════════════════════════════════
class _AccountRow extends StatefulWidget {
  final TreeNode node;
  final int depth;
  final int rootTotal;
  final bool forceOpen;
  final TreeController controller;
  final String query;
  final ValueChanged<TreeNode> onOpen;

  const _AccountRow({
    required this.node,
    required this.depth,
    required this.rootTotal,
    required this.forceOpen,
    required this.controller,
    required this.query,
    required this.onOpen,
  });

  @override
  State<_AccountRow> createState() => _AccountRowState();
}

class _AccountRowState extends State<_AccountRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = TreeThemeData.of(context);
    final n = widget.node;
    final hasKids = n.children.isNotEmpty;
    final open = widget.forceOpen || widget.controller.isExpanded(n.id);
    final total = _nodeTotal(n);
    final share = widget.rootTotal > 0 ? total / widget.rootTotal : 0.0;
    final dot = _typeDot[n.data['type']] ?? t.fg3;
    final nature = _typeNature[n.data['type']] ?? 'debit';
    final indent = 14.0 + widget.depth * 22.0;
    final isSel = widget.controller.isSelected(n.id);

    final row = MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => hasKids ? widget.controller.toggle(n.id) : widget.onOpen(n),
        child: Container(
          padding: EdgeInsets.only(left: indent, right: 12, top: 9, bottom: 9),
          decoration: BoxDecoration(
            color: isSel
                ? Color.alphaBlend(TreeThemeData.accent.withOpacity(0.12), t.surface)
                : (_hover ? t.hover : Colors.transparent),
            borderRadius: BorderRadius.circular(5),
            border: isSel ? Border.all(color: TreeThemeData.accent.withOpacity(0.45)) : null,
          ),
          child: Row(
            children: [
              // account cell
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      child: hasKids
                          ? AnimatedRotation(
                              turns: open ? 0 : -0.25,
                              duration: TreeThemeData.durBase,
                              curve: TreeThemeData.curveStandard,
                              child: Icon(Icons.expand_more, size: 14, color: t.fg3),
                            )
                          : null,
                    ),
                    const SizedBox(width: 9),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: dot,
                        shape: BoxShape.circle,
                        boxShadow: widget.depth == 0 ? [BoxShadow(color: dot.withOpacity(0.18), spreadRadius: 3)] : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _hl(n.id, widget.query, TextStyle(fontFamily: TreeThemeData.monoFont, fontSize: 11.5, color: t.fg3)),
                    const SizedBox(width: 9),
                    Flexible(
                      child: _hl(
                        n.label,
                        widget.query,
                        TextStyle(
                          fontSize: 13,
                          fontWeight: widget.depth == 0 ? FontWeight.w700 : (widget.depth == 1 ? FontWeight.w600 : FontWeight.w500),
                          color: widget.depth >= 3 ? t.fg2 : t.fg1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: _hl('${n.data['ar'] ?? ''}', widget.query, TextStyle(fontSize: 12, color: t.fg4)),
                    ),
                    if (hasKids) ...[
                      const SizedBox(width: 9),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                        decoration: BoxDecoration(color: t.inputBg, border: Border.all(color: t.border), borderRadius: BorderRadius.circular(999)),
                        child: Text('${_leafCount(n)}', style: TextStyle(fontFamily: TreeThemeData.monoFont, fontSize: 9.5, fontWeight: FontWeight.w700, color: t.fg3)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // nature
              SizedBox(width: 64, child: Align(alignment: Alignment.centerLeft, child: _naturePill(t, nature))),
              const SizedBox(width: 12),
              // balance + share bar
              SizedBox(
                width: 168,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_fmt(total),
                        style: TextStyle(fontFamily: TreeThemeData.monoFont, fontSize: 12.5, fontWeight: widget.depth == 0 ? FontWeight.w700 : FontWeight.w500, color: t.fg1)),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        height: 3,
                        width: double.infinity,
                        child: Stack(children: [
                          Container(color: t.inputBg),
                          FractionallySizedBox(
                            widthFactor: share.clamp(0.015, 1.0).toDouble(),
                            alignment: Alignment.centerLeft,
                            child: Container(color: dot.withOpacity(widget.depth == 0 ? 0.9 : 0.55)),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // open affordance
              SizedBox(
                width: 26,
                child: (!hasKids && _hover) ? Icon(Icons.chevron_right, size: 14, color: t.fg4) : null,
              ),
            ],
          ),
        ),
      ),
    );

    if (!hasKids || !open) return row;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row,
        Stack(
          children: [
            Positioned(left: indent + 7, top: 0, bottom: 13, child: Container(width: 1, color: t.guide)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final c in n.children)
                  _AccountRow(
                    node: c,
                    depth: widget.depth + 1,
                    rootTotal: widget.rootTotal,
                    forceOpen: widget.forceOpen,
                    controller: widget.controller,
                    query: widget.query,
                    onOpen: widget.onOpen,
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _naturePill(TreeThemeData t, String nature) {
    final dr = nature == 'debit';
    final c = dr ? TreeThemeData.accent : TreeThemeData.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        border: Border.all(color: c.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(dr ? 'DR' : 'CR', style: TextStyle(fontFamily: TreeThemeData.monoFont, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: c)),
    );
  }

  /// Text with the matched search span tinted, ellipsised to one line.
  Widget _hl(String text, String q, TextStyle base) {
    final needle = q.trim().toLowerCase();
    if (needle.isEmpty) {
      return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: base);
    }
    final at = text.toLowerCase().indexOf(needle);
    if (at < 0) {
      return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: base);
    }
    final mark = base.copyWith(
      backgroundColor: TreeThemeData.accent.withOpacity(0.32),
      color: base.color,
      fontWeight: FontWeight.w700,
    );
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(style: base, children: [
        TextSpan(text: text.substring(0, at)),
        TextSpan(text: text.substring(at, at + needle.length), style: mark),
        TextSpan(text: text.substring(at + needle.length)),
      ]),
    );
  }
}

// ── tiny hover wrapper ──
class _Hoverable extends StatefulWidget {
  final Widget Function(bool hover) builder;
  const _Hoverable({required this.builder});
  @override
  State<_Hoverable> createState() => _HoverableState();
}

class _HoverableState extends State<_Hoverable> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      cursor: SystemMouseCursors.click,
      child: widget.builder(_h),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  final bool light;
  final ValueChanged<bool> onChanged;
  const _ThemeToggle({required this.light, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final t = TreeThemeData.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onChanged(!light),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: t.surface,
            border: Border.all(color: t.border),
            borderRadius: BorderRadius.circular(TreeThemeData.radiusMd),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(light ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 15, color: t.fg2),
            const SizedBox(width: 8),
            Text(light ? 'Light' : 'Dark', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.fg1)),
          ]),
        ),
      ),
    );
  }
}
