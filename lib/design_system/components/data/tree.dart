// ============================================================
// Tree — VIEW.
// ------------------------------------------------------------
// A thin, customisable render of TreeController. Paints the visible rows with
// indent guide-lines, disclosure twisties, icons, optional tri-state
// checkboxes, an optional toolbar (search + expand/collapse + undo/redo) and
// an optional footer. Every gesture and keystroke is forwarded to the
// controller — this widget owns no tree state of its own.
//
// Customisation surface:
//   • showToolbar / showSearch / showCheckboxes / showFooter / showGuides
//   • dense (compact row height)
//   • iconBuilder        — override the leading icon per node
//   • trailingBuilder    — inject host widgets at the row's trailing edge
//   • labelBuilder       — fully replace the label cell (e.g. rich text)
//   • contextActions     — entries for the right-click / ⋯ menu per node
//   • onSelected / onActivated / onCheckedChanged / onChanged callbacks
//
//   File: lib/design_system/components/data/tree.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tree_controller.dart';
import 'tree_models.dart';
import 'tree_theme.dart';

/// One entry in a node's context menu (right-click or the ⋯ affordance).
class TreeAction {
  final String label;
  final IconData? icon;
  final bool danger;
  final void Function(TreeController c, TreeNode node) onSelected;
  const TreeAction({required this.label, this.icon, this.danger = false, required this.onSelected});
}

typedef TreeIconBuilder = IconData? Function(TreeRow row);
typedef TreeWidgetBuilder = Widget? Function(BuildContext context, TreeRow row);
typedef TreeActionsBuilder = List<TreeAction> Function(TreeNode node);

class Tree extends StatefulWidget {
  /// Initial forest. Required when [controller] is null.
  final List<TreeNode>? roots;

  /// Drive/observe from outside. When null the widget owns a private one.
  final TreeController? controller;

  /// Ids expanded on first build (ignored when a [controller] is supplied).
  final Set<TreeNodeId>? initiallyExpanded;

  // ── chrome toggles ──
  final bool showToolbar;
  final bool showSearch;
  final bool showCheckboxes;
  final bool showFooter;
  final bool showGuides;

  /// Compact row height.
  final bool dense;

  /// Allow inline rename (double-click / F2 / Enter) and structural edits via
  /// the context menu. When false the tree is read-only for navigation.
  final bool editable;

  // ── customisation hooks ──
  final TreeIconBuilder? iconBuilder;
  final TreeWidgetBuilder? trailingBuilder;
  final TreeWidgetBuilder? labelBuilder;
  final TreeActionsBuilder? contextActions;

  // ── callbacks ──
  final ValueChanged<TreeNode>? onSelected;
  final ValueChanged<TreeNode>? onActivated; // double-click / Enter on a leaf
  final ValueChanged<Set<TreeNodeId>>? onCheckedChanged;
  final ValueChanged<List<TreeNode>>? onChanged; // structural change

  /// Placeholder when the (filtered) tree is empty.
  final Widget? emptyState;

  const Tree({
    super.key,
    this.roots,
    this.controller,
    this.initiallyExpanded,
    this.showToolbar = true,
    this.showSearch = true,
    this.showCheckboxes = false,
    this.showFooter = true,
    this.showGuides = true,
    this.dense = false,
    this.editable = true,
    this.iconBuilder,
    this.trailingBuilder,
    this.labelBuilder,
    this.contextActions,
    this.onSelected,
    this.onActivated,
    this.onCheckedChanged,
    this.onChanged,
    this.emptyState,
  }) : assert(roots != null || controller != null, 'Provide roots or a controller.');

  @override
  State<Tree> createState() => _TreeState();
}

class _TreeState extends State<Tree> {
  late TreeController _controller;
  bool _ownsController = false;

  final FocusNode _treeFocus = FocusNode(debugLabel: 'Tree.body');
  final FocusNode _editFocus = FocusNode(debugLabel: 'Tree.editor');
  final TextEditingController _editText = TextEditingController();
  final ScrollController _scroll = ScrollController();

  String? _hovered;
  TreeNodeId? _editingNow;
  String _lastStructure = '';
  Set<TreeNodeId> _lastChecked = const {};

  TreeThemeData get _t => TreeThemeData.of(context);
  double get _rowH => widget.dense ? TreeThemeData.rowHeight - 6 : TreeThemeData.rowHeight;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        TreeController(roots: widget.roots!, expanded: widget.initiallyExpanded);
    _ownsController = widget.controller == null;
    _controller.addListener(_onModelChanged);
    _lastStructure = _structureSig();
    _lastChecked = _controller.checkedLeafIds;
  }

  @override
  void didUpdateWidget(covariant Tree old) {
    super.didUpdateWidget(old);
    if (widget.controller != null && widget.controller != _controller) {
      _controller.removeListener(_onModelChanged);
      if (_ownsController) _controller.dispose();
      _controller = widget.controller!;
      _ownsController = false;
      _controller.addListener(_onModelChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onModelChanged);
    if (_ownsController) _controller.dispose();
    _treeFocus.dispose();
    _editFocus.dispose();
    _editText.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _structureSig() {
    final b = StringBuffer();
    TreeOps.walk(_controller.roots, (n, anc) => b.write('${anc.length}:${n.id}:${n.label};'));
    return b.toString();
  }

  void _onModelChanged() {
    // Sync the inline editor field with the controller's editing target.
    final editing = widget.editable ? _controller.editing : null;
    if (editing != _editingNow) {
      _editingNow = editing;
      if (editing != null) {
        final n = _controller.node(editing);
        _editText.text = n?.label ?? '';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _editFocus.requestFocus();
          _editText.selection = TextSelection(baseOffset: 0, extentOffset: _editText.text.length);
        });
      }
    }

    // Fire host callbacks on the relevant transitions.
    final sig = _structureSig();
    if (sig != _lastStructure) {
      _lastStructure = sig;
      widget.onChanged?.call(_controller.roots);
    }
    final checked = _controller.checkedLeafIds;
    if (!_setEq(checked, _lastChecked)) {
      _lastChecked = checked;
      widget.onCheckedChanged?.call(checked);
    }

    if (mounted) setState(() {});
  }

  static bool _setEq(Set<TreeNodeId> a, Set<TreeNodeId> b) =>
      a.length == b.length && a.containsAll(b);

  // ── keyboard ───────────────────────────────────────────────
  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    if (_controller.editing != null) return KeyEventResult.ignored;

    final meta = HardwareKeyboard.instance.isMetaPressed || HardwareKeyboard.instance.isControlPressed;
    final k = e.logicalKey;

    if (meta && k == LogicalKeyboardKey.keyZ) {
      HardwareKeyboard.instance.isShiftPressed ? _controller.redo() : _controller.undo();
      return KeyEventResult.handled;
    }

    switch (k) {
      case LogicalKeyboardKey.arrowDown:
        _controller.moveFocus(1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        _controller.moveFocus(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        _controller.focusInto();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        _controller.focusOut();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.home:
        _controller.focusFirst();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.end:
        _controller.focusLast();
        return KeyEventResult.handled;
    }

    final fid = _controller.focused;
    if (fid == null) return KeyEventResult.ignored;
    final fnode = _controller.node(fid);
    if (fnode == null) return KeyEventResult.ignored;

    if (k == LogicalKeyboardKey.space && widget.showCheckboxes) {
      _controller.toggleCheck(fid);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.enter) {
      if (fnode.isFolder) {
        _controller.toggle(fid);
      } else {
        _controller.select(fid);
        widget.onActivated?.call(fnode);
      }
      return KeyEventResult.handled;
    }
    if (widget.editable && k == LogicalKeyboardKey.f2) {
      _controller.beginEdit(fid);
      return KeyEventResult.handled;
    }
    if (widget.editable &&
        (k == LogicalKeyboardKey.delete || k == LogicalKeyboardKey.backspace)) {
      _controller.remove(fid);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ── build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final t = _t;
    return TreeScope(
      controller: _controller,
      child: DefaultTextStyle(
        style: TextStyle(fontFamily: TreeThemeData.bodyFont, color: t.fg1, fontSize: 13.5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(TreeThemeData.radiusLg),
            border: Border.all(color: t.borderStrong),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(TreeThemeData.radiusLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showToolbar) _buildToolbar(t),
                Flexible(child: _buildBody(t)),
                if (widget.showFooter) _buildFooter(t),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(TreeThemeData t) {
    final rows = _controller.visibleRows();
    if (rows.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        color: t.surface,
        child: widget.emptyState ??
            Text(
              _controller.filtering ? 'No matches' : 'Empty',
              style: TextStyle(color: t.fg3, fontSize: 13),
            ),
      );
    }
    return Focus(
      focusNode: _treeFocus,
      onKeyEvent: _onKey,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _treeFocus.requestFocus(),
        child: Scrollbar(
          controller: _scroll,
          child: ListView.builder(
            controller: _scroll,
            primary: false,
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: rows.length,
            itemBuilder: (ctx, i) => _buildRow(t, rows[i]),
          ),
        ),
      ),
    );
  }

  // ── toolbar ────────────────────────────────────────────────
  Widget _buildToolbar(TreeThemeData t) {
    return Container(
      height: TreeThemeData.toolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: t.bg,
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Row(
        children: [
          if (widget.showSearch) Expanded(child: _searchField(t)) else const Spacer(),
          const SizedBox(width: 8),
          _toolBtn(t, Icons.unfold_more, 'Expand all', _controller.expandAll),
          _toolBtn(t, Icons.unfold_less, 'Collapse all', _controller.collapseAll),
          Container(width: 1, height: 18, color: t.border, margin: const EdgeInsets.symmetric(horizontal: 4)),
          _toolBtn(t, Icons.undo, 'Undo', _controller.canUndo ? _controller.undo : null),
          _toolBtn(t, Icons.redo, 'Redo', _controller.canRedo ? _controller.redo : null),
        ],
      ),
    );
  }

  Widget _searchField(TreeThemeData t) {
    return SizedBox(
      height: 28,
      child: TextField(
        onChanged: _controller.setQuery,
        style: TextStyle(color: t.fg1, fontSize: 13),
        cursorColor: TreeThemeData.accent,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search…',
          hintStyle: TextStyle(color: t.fg3, fontSize: 13),
          prefixIcon: Icon(Icons.search, size: 16, color: t.fg3),
          prefixIconConstraints: const BoxConstraints(minWidth: 30, minHeight: 0),
          filled: true,
          fillColor: t.inputBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TreeThemeData.radiusMd),
            borderSide: BorderSide(color: t.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TreeThemeData.radiusMd),
            borderSide: const BorderSide(color: TreeThemeData.accent),
          ),
        ),
      ),
    );
  }

  Widget _toolBtn(TreeThemeData t, IconData icon, String tip, VoidCallback? onTap) {
    final enabled = onTap != null;
    return Tooltip(
      message: tip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TreeThemeData.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 17, color: enabled ? t.fg3 : t.fg4),
        ),
      ),
    );
  }

  // ── footer ─────────────────────────────────────────────────
  Widget _buildFooter(TreeThemeData t) {
    final checked = _controller.checkedLeafIds.length;
    return Container(
      height: TreeThemeData.footerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: t.bg,
        border: Border(top: BorderSide(color: t.border)),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        widget.showCheckboxes && checked > 0
            ? '$checked selected · ${_controller.nodeCount} items'
            : _controller.filtering
                ? '${_controller.matchCount} matches'
                : '${_controller.nodeCount} items',
        style: TextStyle(
          color: t.fg3,
          fontSize: 11.5,
          fontFamily: TreeThemeData.monoFont,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  // ── row ────────────────────────────────────────────────────
  Widget _buildRow(TreeThemeData t, TreeRow row) {
    final n = row.node;
    final selected = _controller.isSelected(n.id);
    final focused = _controller.focused == n.id;
    final hovered = _hovered == n.id;
    final editing = widget.editable && _controller.editing == n.id;

    final bg = selected
        ? t.selectionFill()
        : hovered
            ? t.hover
            : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = n.id),
      onExit: (_) => setState(() => _hovered = _hovered == n.id ? null : _hovered),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _treeFocus.requestFocus();
          if (n.selectable) {
            _controller.select(n.id);
            widget.onSelected?.call(n);
          } else {
            _controller.focus(n.id);
          }
        },
        onDoubleTap: () {
          if (n.isFolder) {
            _controller.toggle(n.id);
          } else if (widget.editable) {
            _controller.beginEdit(n.id);
          } else {
            widget.onActivated?.call(n);
          }
        },
        onSecondaryTapDown: widget.editable || widget.contextActions != null
            ? (d) => _openMenu(n, d.globalPosition)
            : null,
        child: AnimatedContainer(
          duration: TreeThemeData.durFast,
          height: _rowH,
          decoration: BoxDecoration(
            color: bg,
            border: focused && !selected
                ? Border.all(color: TreeThemeData.accent.withOpacity(0.5), width: 1)
                : null,
          ),
          child: Row(
            children: [
              _indentAndTwisty(t, row),
              if (widget.showCheckboxes) _checkbox(t, n),
              _leadingIcon(t, row),
              const SizedBox(width: 6),
              Expanded(
                child: editing
                    ? _inlineEditor(t, n)
                    : (widget.labelBuilder?.call(context, row) ?? _label(t, row)),
              ),
              if (n.badge != null && !editing) _badge(t, n.badge!),
              if (widget.trailingBuilder != null && !editing)
                widget.trailingBuilder!(context, row) ?? const SizedBox.shrink(),
              if ((widget.editable || widget.contextActions != null) && hovered && !editing)
                _rowMenuButton(t, n),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _indentAndTwisty(TreeThemeData t, TreeRow row) {
    final width = TreeThemeData.indentStep * row.depth + TreeThemeData.twistySize + 6;
    return SizedBox(
      width: width,
      height: _rowH,
      child: CustomPaint(
        painter: widget.showGuides ? _GuidePainter(row: row, color: t.guide) : null,
        child: Align(
          alignment: Alignment.centerRight,
          child: row.hasChildren
              ? _twisty(t, row)
              : SizedBox(width: TreeThemeData.twistySize + 6),
        ),
      ),
    );
  }

  Widget _twisty(TreeThemeData t, TreeRow row) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => _controller.toggle(row.node.id),
        borderRadius: BorderRadius.circular(TreeThemeData.radiusSm),
        child: AnimatedRotation(
          turns: row.expanded ? 0.25 : 0,
          duration: TreeThemeData.durBase,
          curve: TreeThemeData.curveStandard,
          child: Icon(Icons.chevron_right, size: TreeThemeData.twistySize, color: t.fg3),
        ),
      ),
    );
  }

  Widget _checkbox(TreeThemeData t, TreeNode n) {
    final state = _controller.checkState(n);
    final on = state == TreeCheck.all;
    final partial = state == TreeCheck.some;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => _controller.toggleCheck(n.id),
        borderRadius: BorderRadius.circular(TreeThemeData.radiusSm),
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: (on || partial) ? TreeThemeData.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(TreeThemeData.radiusSm),
            border: Border.all(color: (on || partial) ? TreeThemeData.accent : t.fg4, width: 1.5),
          ),
          child: on
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : partial
                  ? const Center(
                      child: SizedBox(
                        width: 8,
                        height: 2,
                        child: DecoratedBox(decoration: BoxDecoration(color: Colors.white)),
                      ),
                    )
                  : null,
        ),
      ),
    );
  }

  Widget _leadingIcon(TreeThemeData t, TreeRow row) {
    final n = row.node;
    final custom = widget.iconBuilder?.call(row) ?? n.icon;
    final icon = custom ??
        (n.isFolder
            ? (row.expanded ? Icons.folder_open_rounded : Icons.folder_rounded)
            : Icons.insert_drive_file_outlined);
    final color = n.isFolder ? TreeThemeData.accent.withOpacity(0.85) : t.fg3;
    return Icon(icon, size: TreeThemeData.iconSize, color: n.selectable ? color : t.fg4);
  }

  Widget _label(TreeThemeData t, TreeRow row) {
    final n = row.node;
    final q = _controller.query.trim();
    final style = TextStyle(
      color: n.selectable ? (n.isFolder ? t.fg2 : t.fg1) : t.fg4,
      fontSize: 13.5,
      fontWeight: n.isFolder ? FontWeight.w600 : FontWeight.w400,
    );
    if (q.isEmpty) {
      return Text(n.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: style);
    }
    // Highlight the matched span.
    final lower = n.label.toLowerCase();
    final at = lower.indexOf(q.toLowerCase());
    if (at < 0) {
      return Text(n.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: style);
    }
    final hl = style.copyWith(
      backgroundColor: TreeThemeData.warning.withOpacity(0.28),
      color: t.fg1,
      fontWeight: FontWeight.w700,
    );
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(style: style, children: [
        TextSpan(text: n.label.substring(0, at)),
        TextSpan(text: n.label.substring(at, at + q.length), style: hl),
        TextSpan(text: n.label.substring(at + q.length)),
      ]),
    );
  }

  Widget _inlineEditor(TreeThemeData t, TreeNode n) {
    return SizedBox(
      height: _rowH - 8,
      child: TextField(
        controller: _editText,
        focusNode: _editFocus,
        style: TextStyle(color: t.fg1, fontSize: 13.5),
        cursorColor: TreeThemeData.accent,
        textInputAction: TextInputAction.done,
        onSubmitted: (v) => _controller.commitEdit(n.id, v),
        onTapOutside: (_) => _controller.commitEdit(n.id, _editText.text),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: t.inputBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TreeThemeData.radiusSm),
            borderSide: const BorderSide(color: TreeThemeData.accent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TreeThemeData.radiusSm),
            borderSide: const BorderSide(color: TreeThemeData.accent, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _badge(TreeThemeData t, String text) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: t.inputBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: t.border),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: t.fg3,
          fontSize: 10.5,
          fontFamily: TreeThemeData.monoFont,
          height: 1.1,
        ),
      ),
    );
  }

  Widget _rowMenuButton(TreeThemeData t, TreeNode n) {
    return InkWell(
      onTapDown: (d) => _openMenu(n, d.globalPosition),
      borderRadius: BorderRadius.circular(TreeThemeData.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Icon(Icons.more_horiz, size: 16, color: t.fg3),
      ),
    );
  }

  // ── context menu ───────────────────────────────────────────
  Future<void> _openMenu(TreeNode n, Offset globalPos) async {
    final t = _t;
    _controller.select(n.id);
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final pos = RelativeRect.fromRect(
      Rect.fromLTWH(globalPos.dx, globalPos.dy, 0, 0),
      Offset.zero & overlay.size,
    );

    final custom = widget.contextActions?.call(n) ?? const <TreeAction>[];
    // Menu values are closures — no enum bookkeeping, no index juggling.
    final items = <PopupMenuEntry<VoidCallback>>[];

    if (widget.editable) {
      if (n.isFolder) {
        items.add(_menuItem(t, 'Add child', Icons.add, () => _controller.addChild(n.id)));
        items.add(_menuItem(t, 'Add folder', Icons.create_new_folder_outlined,
            () => _controller.addChild(n.id, label: 'New folder', folder: true)));
      }
      items.add(_menuItem(t, 'Add sibling', Icons.playlist_add, () => _controller.addSibling(n.id)));
      items.add(_menuItem(t, 'Rename', Icons.edit_outlined, () => _controller.beginEdit(n.id)));
      items.add(_menuItem(t, 'Duplicate', Icons.copy_outlined, () => _controller.duplicate(n.id)));
    }
    if (custom.isNotEmpty) {
      if (items.isNotEmpty) items.add(const PopupMenuDivider(height: 1));
      for (final a in custom) {
        items.add(_menuItem(t, a.label, a.icon, () => a.onSelected(_controller, n), danger: a.danger));
      }
    }
    if (widget.editable) {
      items.add(const PopupMenuDivider(height: 1));
      items.add(_menuItem(t, 'Delete', Icons.delete_outline, () => _controller.remove(n.id), danger: true));
    }
    if (items.isEmpty) return;

    final pick = await showMenu<VoidCallback>(
      context: context,
      position: pos,
      color: t.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TreeThemeData.radiusMd),
        side: BorderSide(color: t.borderStrong),
      ),
      items: items,
    );
    pick?.call();
  }

  PopupMenuItem<VoidCallback> _menuItem(
    TreeThemeData t,
    String label,
    IconData? icon,
    VoidCallback onTap, {
    bool danger = false,
  }) {
    final color = danger ? TreeThemeData.danger : t.fg1;
    return PopupMenuItem<VoidCallback>(
      value: onTap,
      height: 36,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: danger ? TreeThemeData.danger : t.fg3),
            const SizedBox(width: 10),
          ],
          Text(label, style: TextStyle(color: color, fontSize: 13, fontFamily: TreeThemeData.bodyFont)),
        ],
      ),
    );
  }
}

// (Removed) legacy enum-based menu handler.

/// Paints the indent guide-lines for one row: continuing verticals for each
/// ancestor that has a following sibling, plus the ├ / └ elbow into this node.
class _GuidePainter extends CustomPainter {
  final TreeRow row;
  final Color color;
  const _GuidePainter({required this.row, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const step = TreeThemeData.indentStep;
    final mid = size.height / 2;

    // Continuing verticals for ancestors with a following sibling.
    for (var d = 0; d < row.ancestorHasNext.length; d++) {
      if (row.ancestorHasNext[d]) {
        final x = step * d + step / 2;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
    }

    if (row.depth == 0) return;

    // Elbow into this node at the node's own column.
    final x = step * (row.depth - 1) + step / 2;
    canvas.drawLine(Offset(x, 0), Offset(x, row.isLast ? mid : size.height), paint);
    canvas.drawLine(Offset(x, mid), Offset(x + step / 2 + 2, mid), paint);
  }

  @override
  bool shouldRepaint(covariant _GuidePainter old) =>
      old.row.isLast != row.isLast ||
      old.row.depth != row.depth ||
      old.color != color ||
      !_listEq(old.row.ancestorHasNext, row.ancestorHasNext);

  static bool _listEq(List<bool> a, List<bool> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
