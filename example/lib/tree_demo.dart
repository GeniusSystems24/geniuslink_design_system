// ============================================================
// Tree — demo / test screen  →  ACCOUNT TREE (typed + real Tree widget).
// Drives the library's Tree<Account> widget (not a hand-rolled list) and proves
// every requirement interactively:
//   • Single / multi select — a segmented control flips TreeController.selectionMode
//   • Shift / Ctrl / ⌘       — range + toggle selection (handled by the widget)
//   • Checkboxes             — optional tri-state check column (showCheckboxes)
//   • Add node               — Add child / Add sibling under the focused node
//   • Delete node            — remove the focused node, or every selected node
//   • Selected-nodes list    — a live panel reads controller.selectedNodes
//   • Keyboard + scroll-on-focus — ↑↓ ←→ navigate (RTL-aware), far rows scroll in
//   • LTR / RTL              — a direction toggle wraps the widget
//   File: example/lib/tree_demo.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:geniuslink_design_system/geniuslink_tree.dart';
import 'account_tree_data.dart';

const Map<String, Color> _typeDot = {
  'Asset': Color(0xFF4A7CFF),
  'Liability': Color(0xFFF97316),
  'Equity': Color(0xFF1DB88A),
  'Income': Color(0xFF38BDF8),
  'Expense': Color(0xFFEF4444),
};

int _nodeTotal(TreeNode<Account> n) =>
    n.children.isEmpty ? (n.value?.balance ?? 0) : n.children.fold(0, (s, c) => s + _nodeTotal(c));

String _fmt(num n) {
  final whole = n.abs().floor();
  final s = whole.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return '${n < 0 ? '-' : ''}$b';
}

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
  bool _rtl = false;
  bool _checkboxes = false;
  int _seq = 0;

  late final TreeController<Account> _c = TreeController<Account>(
    roots: kAccountTreeRoots,
    expanded: _groupCodes(kAccountTreeRoots, 1),
    selectionMode: TreeSelectionMode.multi,
  );

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _setMode(TreeSelectionMode m) {
    setState(() {
      _c.selectionMode = m;
      _c.clearSelection();
    });
  }

  // The "current" node to act on: the focused/selected one, else first root.
  TreeNodeId get _target => _c.focused ?? _c.selected ?? (_c.selectedNodes.isNotEmpty ? _c.selectedNodes.first.id : kAccountTreeRoots.first.id);

  void _addChild() {
    _seq++;
    _c.addChild(_target, label: 'New account $_seq', value: Account(code: 'NEW-$_seq', nameEn: 'New account $_seq', nameAr: 'حساب جديد', type: 'Asset', balance: 0));
  }

  void _addSibling() {
    _seq++;
    _c.addSibling(_target, label: 'New sibling $_seq', value: Account(code: 'SIB-$_seq', nameEn: 'New sibling $_seq', nameAr: 'حساب شقيق', type: 'Asset', balance: 0));
  }

  void _deleteSelected() {
    if (_c.selectionCount > 0) {
      _c.removeSelected();
    } else {
      _c.remove(_target);
    }
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
                constraints: const BoxConstraints(maxWidth: 1080),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(28, 36, 28, 80),
                  children: [
                    _header(t),
                    const SizedBox(height: 24),
                    _controlsBar(t),
                    const SizedBox(height: 14),
                    _actionsBar(t),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 560,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // the real Tree<Account> widget
                          Expanded(
                            flex: 3,
                            child: Container(
                              decoration: BoxDecoration(
                                color: t.surface,
                                border: Border.all(color: t.border),
                                borderRadius: BorderRadius.circular(TreeThemeData.radiusLg),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Directionality(
                                textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
                                child: Tree<Account>(
                                    controller: _c,
                                    showCheckboxes: _checkboxes,
                                    showSearch: true,
                                    showToolbar: true,
                                    showFooter: true,
                                    iconBuilder: (row) => _typeIcon(row.node.value?.type),
                                    trailingBuilder: (ctx, row) => _trailing(ctx, row.node),
                                    onActivated: (n) => ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Opened ledger ${n.id} · ${n.label}'), duration: const Duration(seconds: 1)),
                                    ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // live selected-nodes panel
                          Expanded(flex: 2, child: _selectedPanel(t)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Tip — focus the tree (click a row) then: ↑↓ move · ←→ collapse/expand (RTL-aware) · '
                      'Shift+↑↓ extend · ⌘/Ctrl-click toggle · Shift-click range · ⌘/Ctrl+A select all · '
                      'Space checks (when checkboxes on) · F2 rename · Delete removes · navigating far scrolls into view.',
                      style: TextStyle(fontFamily: TreeThemeData.bodyFont, fontSize: 12.5, height: 1.5, color: t.fg3),
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
                Text('Tree · Account Tree',
                    style: TextStyle(fontFamily: TreeThemeData.displayFont, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: t.fg1)),
                const SizedBox(width: 12),
                Text('شجرة الحسابات', textDirection: TextDirection.rtl, style: TextStyle(fontSize: 19, color: t.fg3)),
              ]),
              const SizedBox(height: 8),
              Text(
                'The library Tree<Account> widget — a five-level, strongly-typed chart of accounts. '
                'Pick single or multi select; Shift / Ctrl / ⌘ extend the selection or use the checkbox column; '
                'add a child or sibling and delete nodes; the panel on the right lists the live selection. '
                'Search, keyboard navigation and scroll-on-focus are built into the widget.',
                style: TextStyle(fontSize: 14, height: 1.5, color: t.fg3),
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
    );
  }

  // ── controls: selection mode + checkboxes ──
  Widget _controlsBar(TreeThemeData t) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('SELECT', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: t.fg3)),
        _Segmented<TreeSelectionMode>(
          value: _c.selectionMode,
          options: const {
            TreeSelectionMode.none: 'None',
            TreeSelectionMode.single: 'Single',
            TreeSelectionMode.multi: 'Multi',
          },
          onChanged: _setMode,
        ),
        _CheckToggle(
          on: _checkboxes,
          label: 'Checkboxes',
          onChanged: (v) => setState(() => _checkboxes = v),
        ),
      ],
    );
  }

  // ── actions: add / delete / clear / undo ──
  Widget _actionsBar(TreeThemeData t) {
    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: [
        _OpButton(icon: Icons.subdirectory_arrow_right_rounded, label: 'Add child', onTap: _addChild),
        _OpButton(icon: Icons.add_rounded, label: 'Add sibling', onTap: _addSibling),
        _OpButton(
            icon: Icons.delete_outline_rounded,
            label: _c.selectionCount > 1 ? 'Delete ${_c.selectionCount} selected' : 'Delete node',
            onTap: _deleteSelected),
        _OpButton(icon: Icons.layers_clear_outlined, label: 'Clear selection', onTap: _c.clearSelection),
        _OpButton(icon: Icons.unfold_more_rounded, label: 'Expand all', onTap: _c.expandAll),
        _OpButton(icon: Icons.unfold_less_rounded, label: 'Collapse', onTap: _c.collapseAll),
        _OpButton(icon: Icons.undo_rounded, label: 'Undo', onTap: _c.canUndo ? _c.undo : null),
      ],
    );
  }

  // ── live selected-nodes panel ──
  Widget _selectedPanel(TreeThemeData t) {
    final nodes = _c.selectedNodes;
    final checked = _c.checkedLeafIds;
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(TreeThemeData.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 16, color: TreeThemeData.accent),
                const SizedBox(width: 9),
                Text('Selected nodes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: t.fg1)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(color: TreeThemeData.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
                  child: Text('${nodes.length}',
                      style: TextStyle(fontFamily: TreeThemeData.monoFont, fontSize: 12, fontWeight: FontWeight.w700, color: TreeThemeData.accent)),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: t.border),
          Expanded(
            child: nodes.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app_outlined, size: 24, color: t.fg4),
                          const SizedBox(height: 10),
                          Text(_c.selectionMode == TreeSelectionMode.none ? 'Selection is off' : 'Nothing selected',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.fg2)),
                          const SizedBox(height: 4),
                          Text(_c.selectionMode == TreeSelectionMode.multi ? 'Shift / ⌘-click rows to multi-select' : 'Click a row to select it',
                              textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: t.fg3)),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: nodes.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: t.border),
                    itemBuilder: (ctx, i) => _selRow(t, nodes[i]),
                  ),
          ),
          if (_checkboxes) ...[
            Divider(height: 1, color: t.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.check_box_outlined, size: 14, color: t.fg3),
                  const SizedBox(width: 8),
                  Text('${checked.length} leaves checked',
                      style: TextStyle(fontFamily: TreeThemeData.monoFont, fontSize: 11.5, color: t.fg3)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _selRow(TreeThemeData t, TreeNode<Account> n) {
    final acc = n.value;
    final dot = _typeDot[acc?.type] ?? t.fg3;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Text(n.id, style: TextStyle(fontFamily: TreeThemeData.monoFont, fontSize: 11.5, color: t.fg3)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(n.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.fg1)),
          ),
          const SizedBox(width: 8),
          Text('${_fmt(_nodeTotal(n))} SAR',
              style: TextStyle(fontFamily: TreeThemeData.monoFont, fontSize: 11.5, color: t.fg2)),
        ],
      ),
    );
  }

  // ── per-row builders for the Tree widget ──
  IconData? _typeIcon(String? type) {
    switch (type) {
      case 'Asset':
        return Icons.account_balance_wallet_outlined;
      case 'Liability':
        return Icons.credit_card_outlined;
      case 'Equity':
        return Icons.pie_chart_outline_rounded;
      case 'Income':
        return Icons.trending_up_rounded;
      case 'Expense':
        return Icons.trending_down_rounded;
      default:
        return null; // let the widget infer folder / leaf
    }
  }

  Widget _trailing(BuildContext ctx, TreeNode<Account> n) {
    final t = TreeThemeData.of(ctx);
    final acc = n.value;
    final total = _nodeTotal(n);
    final dr = acc?.isDebitNature ?? true;
    final c = dr ? TreeThemeData.accent : TreeThemeData.warning;
    final dot = _typeDot[acc?.type] ?? t.fg3;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        if (acc != null) ...[
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(acc.nameAr, style: TextStyle(fontSize: 12, color: t.fg4)),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(color: c.withOpacity(0.15), border: Border.all(color: c.withOpacity(0.35)), borderRadius: BorderRadius.circular(999)),
            child: Text(dr ? 'DR' : 'CR', style: TextStyle(fontFamily: TreeThemeData.monoFont, fontSize: 9.5, fontWeight: FontWeight.w700, color: c)),
          ),
          const SizedBox(width: 12),
        ],
        Text('${_fmt(total)} SAR', style: TextStyle(fontFamily: TreeThemeData.monoFont, fontSize: 12, fontWeight: FontWeight.w600, color: t.fg2)),
      ],
    );
  }
}

// ════════════════════ small controls ════════════════════

class _Segmented<T> extends StatelessWidget {
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;
  const _Segmented({required this.value, required this.options, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final t = TreeThemeData.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(TreeThemeData.radiusMd), border: Border.all(color: t.border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (final e in options.entries)
          GestureDetector(
            onTap: () => onChanged(e.key),
            child: AnimatedContainer(
              duration: TreeThemeData.durBase,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
              decoration: BoxDecoration(
                color: value == e.key ? TreeThemeData.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(TreeThemeData.radiusSm),
              ),
              child: Text(e.value,
                  style: TextStyle(
                      fontFamily: TreeThemeData.bodyFont, fontSize: 12.5, fontWeight: FontWeight.w600, color: value == e.key ? Colors.white : t.fg2)),
            ),
          ),
      ]),
    );
  }
}

class _CheckToggle extends StatelessWidget {
  final bool on;
  final String label;
  final ValueChanged<bool> onChanged;
  const _CheckToggle({required this.on, required this.label, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final t = TreeThemeData.of(context);
    return GestureDetector(
      onTap: () => onChanged(!on),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: on ? TreeThemeData.accent.withOpacity(0.12) : t.surface,
            border: Border.all(color: on ? TreeThemeData.accent.withOpacity(0.5) : t.border),
            borderRadius: BorderRadius.circular(TreeThemeData.radiusMd),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(on ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, size: 16, color: on ? TreeThemeData.accent : t.fg3),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: t.fg1)),
          ]),
        ),
      ),
    );
  }
}

class _OpButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _OpButton({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final t = TreeThemeData.of(context);
    final enabled = onTap != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: t.surface,
            border: Border.all(color: t.border),
            borderRadius: BorderRadius.circular(TreeThemeData.radiusMd),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 15, color: enabled ? TreeThemeData.accent : t.fg4),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: enabled ? t.fg1 : t.fg4)),
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
    final t = TreeThemeData.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onChanged(!on),
        child: Container(
          width: 96,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(color: t.surface, border: Border.all(color: t.border), borderRadius: BorderRadius.circular(TreeThemeData.radiusMd)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(on ? onIcon : offIcon, size: 15, color: t.fg2),
            const SizedBox(width: 8),
            Text(on ? onLabel : offLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.fg1)),
          ]),
        ),
      ),
    );
  }
}
