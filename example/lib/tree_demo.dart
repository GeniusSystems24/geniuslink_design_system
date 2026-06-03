// ============================================================
// Tree — demo gallery  →  ACCOUNT TREE (typed + keyboard-driven).
// ------------------------------------------------------------
// Mirrors the GeniusLink "Account Tree" web tool, and showcases two library
// capabilities:
//   1. GENERIC VALUE TYPE — the whole tree is `TreeNode<Account>`, so every
//      row reads a strongly-typed `node.value` (an [Account]) with no casts.
//   2. KEYBOARD CONTROL    — full arrow navigation, Enter/Space to open or
//      toggle, / to search, * / \ to expand / collapse all, ? for a cheatsheet.
//
// An interactive five-level chart of accounts with KPI summary cards, a
// recursive search that matches code + English + Arabic (live in-row
// highlighting), colour-coded type filter chips, roll-up balances with share
// bars, DR / CR nature pills, leaf-count badges and an accounting-equation
// balance check. Expansion / selection / query are driven by the library's
// `TreeController<Account>`; rows are painted with `TreeThemeData` (dark/light).
//   File: example/lib/tree_demo.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geniuslink_design_system/geniuslink_tree.dart';
import 'account_tree_data.dart';

// ── account-type palette (mirrors the web TYPE_DOT map) ──
const Map<String, Color> _typeDot = {
  'Asset': Color(0xFF4A7CFF),
  'Liability': Color(0xFFF97316),
  'Equity': Color(0xFF1DB88A),
  'Income': Color(0xFF38BDF8),
  'Expense': Color(0xFFEF4444),
};
const List<String> _typeOrder = ['Asset', 'Liability', 'Equity', 'Income', 'Expense'];

// ── tree maths (read the typed value, no casting) ──
int _nodeTotal(TreeNode<Account> n) =>
    n.children.isEmpty ? (n.value?.balance ?? 0) : n.children.fold(0, (s, c) => s + _nodeTotal(c));
int _leafCount(TreeNode<Account> n) =>
    n.children.isEmpty ? 1 : n.children.fold(0, (s, c) => s + _leafCount(c));

String _searchable(TreeNode<Account> n) => '${n.id} ${n.label} ${n.value?.nameAr ?? ''}'.toLowerCase();

/// Recursive filter: keep a node if it (or any descendant) matches; a hit
/// retains its whole subtree, a deep hit keeps its ancestors.
List<TreeNode<Account>> _filterTree(List<TreeNode<Account>> nodes, String q) {
  final needle = q.trim().toLowerCase();
  if (needle.isEmpty) return nodes;
  TreeNode<Account>? walk(TreeNode<Account> n) {
    final self = _searchable(n).contains(needle);
    final kids = n.children.isEmpty ? const <TreeNode<Account>>[] : n.children.map(walk).whereType<TreeNode<Account>>().toList();
    if (self) return n;
    if (kids.isNotEmpty) return n.copyWith(children: kids);
    return null;
  }

  return nodes.map(walk).whereType<TreeNode<Account>>().toList();
}

int _countMatches(List<TreeNode<Account>> nodes, String q) {
  final needle = q.trim().toLowerCase();
  if (needle.isEmpty) return 0;
  var c = 0;
  void w(TreeNode<Account> n) {
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
Set<String> _groupCodes(List<TreeNode<Account>> nodes, int maxD) {
  final out = <String>{};
  void w(List<TreeNode<Account>> ns, int d) {
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
  String? _focusId; // keyboard cursor

  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode(debugLabel: 'AccountTree.search');
  final FocusNode _panelFocus = FocusNode(debugLabel: 'AccountTree.panel');
  late final TreeController<Account> _c =
      TreeController<Account>(roots: kAccountTreeRoots, expanded: _groupCodes(kAccountTreeRoots, 1));

  static const List<String> _samples = ['1111', 'Bank', 'البنك', 'Cash', 'Loan', '5512'];

  @override
  void initState() {
    super.initState();
    // Repaint the panel's focus ring when keyboard focus enters / leaves.
    _panelFocus.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _c.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _panelFocus.dispose();
    super.dispose();
  }

  void _runQuery(String q) {
    _searchCtrl.value = TextEditingValue(text: q, selection: TextSelection.collapsed(offset: q.length));
    _c.setQuery(q);
  }

  // ── keyboard ───────────────────────────────────────────────
  List<TreeNode<Account>> _flatVisible(List<TreeNode<Account>> nodes, bool searching) {
    final out = <TreeNode<Account>>[];
    void rec(List<TreeNode<Account>> ns) {
      for (final n in ns) {
        out.add(n);
        final open = searching || _c.isExpanded(n.id);
        if (n.children.isNotEmpty && open) rec(n.children);
      }
    }

    rec(nodes);
    return out;
  }

  KeyEventResult _onPanelKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    final shift = HardwareKeyboard.instance.isShiftPressed;

    if (k == LogicalKeyboardKey.slash && !shift) {
      _searchFocus.requestFocus();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.slash && shift) {
      _showShortcuts();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.asterisk) {
      _c.expandAll();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.backslash) {
      _c.collapseAll();
      return KeyEventResult.handled;
    }

    final searching = _c.query.trim().isNotEmpty;
    final byType = _typeFilter == 'all' ? kAccountTreeRoots : kAccountTreeRoots.where((n) => n.value?.type == _typeFilter).toList();
    final visible = _filterTree(byType, _c.query);
    final flat = _flatVisible(visible, searching);
    if (flat.isEmpty) return KeyEventResult.ignored;
    final idx = _focusId == null ? -1 : flat.indexWhere((n) => n.id == _focusId);
    final cur = idx >= 0 ? flat[idx] : null;

    switch (k) {
      case LogicalKeyboardKey.arrowDown:
        setState(() => _focusId = flat[(idx + 1).clamp(0, flat.length - 1)].id);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        setState(() => _focusId = flat[(idx <= 0 ? 0 : idx - 1)].id);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.home:
        setState(() => _focusId = flat.first.id);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.end:
        setState(() => _focusId = flat.last.id);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        if (cur != null && cur.children.isNotEmpty) {
          if (!searching && !_c.isExpanded(cur.id)) {
            _c.expand(cur.id);
          } else {
            setState(() => _focusId = cur.children.first.id);
          }
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        if (cur != null && cur.children.isNotEmpty && !searching && _c.isExpanded(cur.id)) {
          _c.collapse(cur.id);
        } else if (cur != null) {
          final anc = TreeOps.ancestorsOf<Account>(visible, cur.id);
          if (anc.isNotEmpty) setState(() => _focusId = anc.last);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
      case LogicalKeyboardKey.space:
        if (cur == null) return KeyEventResult.ignored;
        if (cur.children.isNotEmpty) {
          _c.toggle(cur.id);
        } else {
          setState(() => _opened = cur.id);
          _c.select(cur.id);
        }
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _onSearchKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    if (e.logicalKey == LogicalKeyboardKey.escape) {
      _runQuery('');
      _panelFocus.requestFocus();
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.arrowDown) {
      _panelFocus.requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _focusRow(TreeNode<Account> n) {
    _panelFocus.requestFocus();
    setState(() => _focusId = n.id);
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
                        _typeFilter == 'all' ? kAccountTreeRoots : kAccountTreeRoots.where((n) => n.value?.type == _typeFilter).toList();
                    final visible = _filterTree(byType, query);
                    final matches = _countMatches(byType, query);

                    int totalOf(String type) =>
                        kAccountTreeRoots.where((n) => n.value?.type == type).fold(0, (s, n) => s + _nodeTotal(n));
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
                'TreeNode<Account> — a strongly-typed five-level chart of accounts. '
                'Search by code or name, filter by type, navigate by keyboard (press ? for shortcuts), '
                'and open a posting account. Balances roll up from the leaves; the equation badge confirms the books balance.',
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
              const SizedBox(width: 8),
              _toolBtn(t, Icons.keyboard_outlined, 'Shortcuts', _showShortcuts),
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
      child: Focus(
        onKeyEvent: _onSearchKey,
        child: TextField(
          controller: _searchCtrl,
          focusNode: _searchFocus,
          onChanged: _c.setQuery,
          style: TextStyle(color: t.fg1, fontSize: 13.5),
          cursorColor: TreeThemeData.accent,
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Search by code, English or Arabic name…   ( / )',
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
      ),
    );
  }

  Widget _toolBtn(TreeThemeData t, IconData icon, String label, VoidCallback onTap) {
    return _Hoverable(builder: (hover) {
      return Tooltip(
        message: label,
        child: InkWell(
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
  Widget _treePanel(TreeThemeData t, List<TreeNode<Account>> visible, bool searching, String query, int totalAccounts, int visibleAccounts) {
    return Focus(
      focusNode: _panelFocus,
      onKeyEvent: _onPanelKey,
      child: Container(
        decoration: BoxDecoration(
          color: t.surface,
          border: Border.all(color: _panelFocus.hasFocus ? TreeThemeData.accent.withOpacity(0.5) : t.border),
          borderRadius: BorderRadius.circular(TreeThemeData.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // title row
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 12, 0),
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
                        Text('5 levels · click or use ↑↓ ← → · Enter opens a leaf', style: TextStyle(fontSize: 12, color: t.fg3)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(searching ? '$visibleAccounts of $totalAccounts' : '$totalAccounts accounts',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: t.fg3)),
                  ),
                  _Hoverable(builder: (hover) {
                    return Tooltip(
                      message: 'Keyboard shortcuts  ·  ?',
                      child: InkWell(
                        onTap: _showShortcuts,
                        borderRadius: BorderRadius.circular(TreeThemeData.radiusSm),
                        child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.keyboard_outlined, size: 16, color: hover ? t.fg1 : t.fg3)),
                      ),
                    );
                  }),
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
                            focusId: _focusId,
                            onFocus: _focusRow,
                            onOpen: (node) {
                              setState(() {
                                _opened = node.id;
                                _focusId = node.id;
                              });
                              _c.select(node.id);
                            },
                          ),
                      ],
                    ),
            ),
            if (_opened != null) _openedStrip(t),
          ],
        ),
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
    final acc = _c.valueOf(_opened!);
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
            const TextSpan(text: 'Opened ledger for '),
            TextSpan(text: acc?.nameEn ?? _opened, style: TextStyle(fontWeight: FontWeight.w700, color: t.fg1)),
            TextSpan(text: '  ·  ', style: TextStyle(color: t.fg4)),
            TextSpan(text: _opened, style: TextStyle(fontFamily: TreeThemeData.monoFont, color: t.fg3)),
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

  // ── shortcuts cheatsheet ──
  static const List<List<String>> _shortcutRows = [
    ['↑  ↓', 'Move between rows'],
    ['←  →', 'Collapse / out · expand / in'],
    ['Home  End', 'Jump to first / last'],
    ['Enter / Space', 'Open a leaf · toggle a group'],
    ['/', 'Focus the search field'],
    ['Esc', 'Clear search'],
    ['*  \\', 'Expand all · collapse all'],
    ['?', 'This cheatsheet'],
  ];

  void _showShortcuts() {
    final t = TreeThemeData.of(context);
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 440,
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(TreeThemeData.radiusLg),
              border: Border.all(color: t.borderStrong),
              boxShadow: TreeThemeData.popShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.keyboard_outlined, size: 18, color: TreeThemeData.accent),
                  const SizedBox(width: 9),
                  Text('Keyboard shortcuts',
                      style: TextStyle(fontFamily: TreeThemeData.displayFont, fontSize: 16, fontWeight: FontWeight.w700, color: t.fg1)),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.of(ctx).pop(),
                    borderRadius: BorderRadius.circular(TreeThemeData.radiusSm),
                    child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.close, size: 16, color: t.fg3)),
                  ),
                ]),
                const SizedBox(height: 14),
                for (final s in _shortcutRows)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      SizedBox(
                        width: 130,
                        child: Text(s[0],
                            style: TextStyle(fontFamily: TreeThemeData.monoFont, fontSize: 12.5, fontWeight: FontWeight.w700, color: t.fg2)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(s[1], style: TextStyle(fontSize: 13, color: t.fg3))),
                    ]),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// One account row — recursive, with the 4-column account layout.
// ════════════════════════════════════════════════════════════
class _AccountRow extends StatefulWidget {
  final TreeNode<Account> node;
  final int depth;
  final int rootTotal;
  final bool forceOpen;
  final TreeController<Account> controller;
  final String query;
  final String? focusId;
  final ValueChanged<TreeNode<Account>> onFocus;
  final ValueChanged<TreeNode<Account>> onOpen;

  const _AccountRow({
    required this.node,
    required this.depth,
    required this.rootTotal,
    required this.forceOpen,
    required this.controller,
    required this.query,
    required this.focusId,
    required this.onFocus,
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
    final acc = n.value;
    final hasKids = n.children.isNotEmpty;
    final open = widget.forceOpen || widget.controller.isExpanded(n.id);
    final total = _nodeTotal(n);
    final share = widget.rootTotal > 0 ? total / widget.rootTotal : 0.0;
    final dot = _typeDot[acc?.type] ?? t.fg3;
    final isDebit = acc?.isDebitNature ?? true;
    final indent = 14.0 + widget.depth * 22.0;
    final isSel = widget.controller.isSelected(n.id);
    final isFocus = widget.focusId == n.id;

    final row = MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          widget.onFocus(n);
          hasKids ? widget.controller.toggle(n.id) : widget.onOpen(n);
        },
        child: Container(
          padding: EdgeInsets.only(left: indent, right: 12, top: 9, bottom: 9),
          decoration: BoxDecoration(
            color: isSel
                ? Color.alphaBlend(TreeThemeData.accent.withOpacity(0.12), t.surface)
                : (_hover ? t.hover : Colors.transparent),
            borderRadius: BorderRadius.circular(5),
            border: (isSel || isFocus)
                ? Border.all(color: TreeThemeData.accent.withOpacity(isSel ? 0.45 : 0.7), width: isFocus && !isSel ? 1.5 : 1)
                : null,
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
                      child: _hl(acc?.nameAr ?? '', widget.query, TextStyle(fontSize: 12, color: t.fg4)),
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
              SizedBox(width: 64, child: Align(alignment: Alignment.centerLeft, child: _naturePill(t, isDebit))),
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
                    focusId: widget.focusId,
                    onFocus: widget.onFocus,
                    onOpen: widget.onOpen,
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _naturePill(TreeThemeData t, bool dr) {
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
