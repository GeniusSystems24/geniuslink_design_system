// ============================================================
// Tree — CONTROLLER  (generic over the node's value type `T`).
// ------------------------------------------------------------
// The single source of truth and all of the tree's logic, as a
// ChangeNotifier. The view (Tree) is a thin render of this state and forwards
// every gesture / keystroke here. The same controller is exposed to row
// content via an InheritedNotifier so any descendant can drive the tree:
//
//   final t = TreeController.of<Account>(context);   // may be null
//   t?.addChild(parentId);
//
// Holds: the (immutable) node forest as the working copy, the expanded set,
// the tri-state checked set, single selection, a keyboard focus cursor, the
// search query, the inline-rename target, and one undo/redo history covering
// every structural change. Nodes are immutable, so a snapshot is just the
// previous `List<TreeNode<T>>` reference — undo is a swap, never a deep clone.
//
//   File: lib/design_system/components/data/tree_controller.dart
// ============================================================

import 'package:flutter/widgets.dart';
import 'tree_models.dart';

class TreeController<T> extends ChangeNotifier {
  TreeController({
    required List<TreeNode<T>> roots,
    Set<TreeNodeId>? expanded,
    Set<TreeNodeId>? checked,
    TreeNodeId? selected,
    Set<TreeNodeId>? selection,
    this.selectionMode = TreeSelectionMode.single,
    this.historyLimit = 200,
  })  : _roots = List.unmodifiable(roots),
        _expanded = {...?expanded},
        _checked = {...?checked},
        _selection = {...?selection, if (selected != null) selected},
        _selected = selected {
    _focused = selected;
    _anchor = selected;
  }

  final int historyLimit;

  /// What clicks / keyboard selection do. Mutable so a host can flip
  /// single ↔ multi at runtime (e.g. entering a “select” mode).
  TreeSelectionMode selectionMode;

  List<TreeNode<T>> _roots;
  final Set<TreeNodeId> _expanded;
  final Set<TreeNodeId> _checked; // fully-checked LEAVES (branches derive)
  final Set<TreeNodeId> _selection; // click/keyboard selection (multi)
  TreeNodeId? _anchor; // range anchor for Shift-select
  TreeNodeId? _selected;
  TreeNodeId? _focused;
  String _query = '';
  TreeNodeId? _editing;

  final List<List<TreeNode<T>>> _past = [];
  final List<List<TreeNode<T>>> _future = [];

  int _seq = 0;

  // ── reads ──────────────────────────────────────────────────
  List<TreeNode<T>> get roots => _roots;
  String get query => _query;
  TreeNodeId? get selected => _selected;
  TreeNodeId? get focused => _focused ?? _selected;
  TreeNodeId? get editing => _editing;
  bool get canUndo => _past.isNotEmpty;
  bool get canRedo => _future.isNotEmpty;
  int get nodeCount => TreeOps.count<T>(_roots);
  bool get filtering => _query.trim().isNotEmpty;

  bool isExpanded(TreeNodeId id) => _expanded.contains(id);
  bool isSelected(TreeNodeId id) => _selection.contains(id) || _selected == id;
  TreeNode<T>? node(TreeNodeId id) => TreeOps.find<T>(_roots, id);

  /// Every selected node id (click/keyboard selection). In single mode this is
  /// at most one; in multi mode any number. Empty when nothing is selected.
  Set<TreeNodeId> get selection => Set<TreeNodeId>.from(_selection);

  /// The selected nodes' values, in visible (top-to-bottom) order — for group
  /// actions (delete, move, export…).
  List<TreeNode<T>> get selectedNodes {
    final order = <TreeNode<T>>[];
    for (final r in visibleRows()) {
      if (_selection.contains(r.node.id)) order.add(r.node);
    }
    return order;
  }

  int get selectionCount => _selection.length;

  /// The strongly-typed value behind [id], or null.
  T? valueOf(TreeNodeId id) => node(id)?.value;

  /// Ids of every checked leaf (the meaningful selection for a host).
  Set<TreeNodeId> get checkedLeafIds => {..._checked};

  /// How many nodes currently match the search query (0 when not filtering).
  int get matchCount {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return 0;
    var n = 0;
    TreeOps.walk<T>(_roots, (node, _) {
      if (node.label.toLowerCase().contains(q)) n++;
    });
    return n;
  }

  // ── flatten (expansion + filter) ───────────────────────────
  /// The visible rows in render order. While searching, only matches and
  /// their ancestors are shown, and ancestor folders are force-expanded so
  /// the hits are revealed.
  List<TreeRow<T>> visibleRows() {
    final q = _query.trim().toLowerCase();
    final filter = q.isNotEmpty;

    final matched = <TreeNodeId>{};
    final onPath = <TreeNodeId>{}; // ancestors of a match
    if (filter) {
      void rec(List<TreeNode<T>> nodes, List<TreeNodeId> path) {
        for (final n in nodes) {
          if (n.label.toLowerCase().contains(q)) {
            matched.add(n.id);
            onPath.addAll(path);
          }
          if (n.children.isNotEmpty) rec(n.children, [...path, n.id]);
        }
      }

      rec(_roots, const []);
    }

    bool visible(TreeNode<T> n) => !filter || matched.contains(n.id) || onPath.contains(n.id);
    bool expandedFor(TreeNode<T> n) => filter ? onPath.contains(n.id) : _expanded.contains(n.id);

    final rows = <TreeRow<T>>[];
    void emit(List<TreeNode<T>> nodes, int depth, List<bool> ancestorHasNext) {
      final shown = filter ? nodes.where(visible).toList() : nodes;
      for (var i = 0; i < shown.length; i++) {
        final n = shown[i];
        final isLast = i == shown.length - 1;
        final expanded = expandedFor(n);
        rows.add(TreeRow<T>(
          node: n,
          depth: depth,
          expanded: expanded,
          hasChildren: n.hasChildren,
          isLast: isLast,
          ancestorHasNext: List<bool>.of(ancestorHasNext),
        ));
        if (n.hasChildren && expanded) {
          emit(n.children, depth + 1, [...ancestorHasNext, !isLast]);
        }
      }
    }

    emit(_roots, 0, const []);
    return rows;
  }

  // ── checks (tri-state, derived from leaves) ────────────────
  TreeCheck checkState(TreeNode<T> n) {
    final leaves = TreeOps.leafIds<T>(n);
    if (leaves.isEmpty) return _checked.contains(n.id) ? TreeCheck.all : TreeCheck.none;
    final on = leaves.where(_checked.contains).length;
    if (on == 0) return TreeCheck.none;
    if (on == leaves.length) return TreeCheck.all;
    return TreeCheck.some;
  }

  /// Toggle a node's check: cascades to every leaf beneath it (a lone leaf
  /// toggles itself). Pure state — not part of structural undo history.
  void toggleCheck(TreeNodeId id) {
    final n = node(id);
    if (n == null) return;
    final leaves = TreeOps.leafIds<T>(n);
    final targets = leaves.isEmpty ? [id] : leaves;
    final allOn = targets.every(_checked.contains);
    if (allOn) {
      _checked.removeAll(targets);
    } else {
      _checked.addAll(targets);
    }
    notifyListeners();
  }

  void setChecked(Iterable<TreeNodeId> ids) {
    _checked
      ..clear()
      ..addAll(ids);
    notifyListeners();
  }

  // ── expansion ──────────────────────────────────────────────
  void expand(TreeNodeId id) {
    if (_expanded.add(id)) notifyListeners();
  }

  void collapse(TreeNodeId id) {
    if (_expanded.remove(id)) notifyListeners();
  }

  void toggle(TreeNodeId id) {
    _expanded.contains(id) ? _expanded.remove(id) : _expanded.add(id);
    notifyListeners();
  }

  void expandAll() {
    _expanded.clear();
    TreeOps.walk<T>(_roots, (n, _) {
      if (n.isFolder) _expanded.add(n.id);
    });
    notifyListeners();
  }

  void collapseAll() {
    _expanded.clear();
    notifyListeners();
  }

  /// Expand only the [node] and its ancestors so a deep node is revealed.
  void revealNode(TreeNodeId id) {
    for (final a in TreeOps.ancestorsOf<T>(_roots, id)) {
      _expanded.add(a);
    }
    _expanded.add(id);
    _focused = id;
    notifyListeners();
  }

  // ── selection + keyboard focus ─────────────────────────────
  void select(TreeNodeId id) {
    final n = node(id);
    if (n == null || !n.selectable) return;
    _selected = id;
    _focused = id;
    _anchor = id;
    _selection
      ..clear()
      ..add(id);
    notifyListeners();
  }

  /// Pointer/keyboard selection honouring modifier keys and [selectionMode]:
  ///   • plain     → select only [id] (resets the set)
  ///   • toggle    → Ctrl/⌘-click: add/remove [id], keep the rest (multi only)
  ///   • range     → Shift-click: select the contiguous visible range from the
  ///                 anchor to [id] (multi only)
  /// Falls back to single behaviour when [selectionMode] isn't multi.
  void selectWith(TreeNodeId id, {bool toggle = false, bool range = false}) {
    final n = node(id);
    if (n == null || !n.selectable || selectionMode == TreeSelectionMode.none) return;
    if (selectionMode == TreeSelectionMode.single) {
      select(id);
      return;
    }
    if (range && _anchor != null) {
      final rows = visibleRows();
      final a = rows.indexWhere((r) => r.node.id == _anchor);
      final b = rows.indexWhere((r) => r.node.id == id);
      if (a >= 0 && b >= 0) {
        final lo = a < b ? a : b, hi = a < b ? b : a;
        _selection.clear();
        for (var i = lo; i <= hi; i++) {
          if (rows[i].node.selectable) _selection.add(rows[i].node.id);
        }
      }
    } else if (toggle) {
      if (_selection.contains(id)) {
        _selection.remove(id);
      } else {
        _selection.add(id);
      }
      _anchor = id;
    } else {
      _selection
        ..clear()
        ..add(id);
      _anchor = id;
    }
    _selected = id;
    _focused = id;
    notifyListeners();
  }

  /// Select every selectable, currently-visible node (multi mode).
  void selectAllVisible() {
    if (selectionMode != TreeSelectionMode.multi) return;
    _selection
      ..clear()
      ..addAll(visibleRows().where((r) => r.node.selectable).map((r) => r.node.id));
    notifyListeners();
  }

  /// Clear the click/keyboard selection (leaves checkboxes alone).
  void clearSelection() {
    if (_selection.isEmpty && _selected == null) return;
    _selection.clear();
    _selected = null;
    notifyListeners();
  }

  void focus(TreeNodeId id) {
    _focused = id;
    notifyListeners();
  }

  /// Move the keyboard cursor by [delta] rows through the visible list.
  void moveFocus(int delta) {
    final rows = visibleRows();
    if (rows.isEmpty) return;
    final cur = focused;
    var idx = rows.indexWhere((r) => r.node.id == cur);
    if (idx < 0) idx = delta > 0 ? -1 : rows.length;
    final next = (idx + delta).clamp(0, rows.length - 1);
    _focused = rows[next].node.id;
    notifyListeners();
  }

  void focusFirst() {
    final rows = visibleRows();
    if (rows.isEmpty) return;
    _focused = rows.first.node.id;
    notifyListeners();
  }

  void focusLast() {
    final rows = visibleRows();
    if (rows.isEmpty) return;
    _focused = rows.last.node.id;
    notifyListeners();
  }

  /// → key: expand a collapsed folder, else step into the first child.
  void focusInto() {
    final id = focused;
    if (id == null) return;
    final n = node(id);
    if (n == null) return;
    if (n.isFolder && n.hasChildren && !_expanded.contains(id)) {
      _expanded.add(id);
      notifyListeners();
    } else if (n.hasChildren) {
      _focused = n.children.first.id;
      notifyListeners();
    }
  }

  /// ← key: collapse an expanded folder, else step out to the parent.
  void focusOut() {
    final id = focused;
    if (id == null) return;
    final n = node(id);
    if (n != null && n.isFolder && n.hasChildren && _expanded.contains(id)) {
      _expanded.remove(id);
      notifyListeners();
      return;
    }
    final ancestors = TreeOps.ancestorsOf<T>(_roots, id);
    if (ancestors.isNotEmpty) {
      _focused = ancestors.last;
      notifyListeners();
    }
  }

  /// Toggle / activate the focused row: folders expand, leaves select.
  /// Returns the activated leaf node (for the host to open), or null.
  TreeNode<T>? activateFocused() {
    final id = focused;
    if (id == null) return null;
    final n = node(id);
    if (n == null) return null;
    if (n.isFolder) {
      toggle(id);
      return null;
    }
    select(id);
    return n;
  }

  // ── search ─────────────────────────────────────────────────
  void setQuery(String q) {
    if (q == _query) return;
    _query = q;
    notifyListeners();
  }

  // ── history plumbing ───────────────────────────────────────
  void _apply(List<TreeNode<T>> next) {
    _past.add(_roots);
    if (_past.length > historyLimit) _past.removeAt(0);
    _future.clear();
    _roots = List.unmodifiable(next);
    notifyListeners();
  }

  TreeNodeId _newId() => 'gen-${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  TreeNode<T> _cloneFresh(TreeNode<T> n) =>
      n.copyWith(id: _newId(), children: [for (final c in n.children) _cloneFresh(c)]);

  // ── structural edits (undoable) ────────────────────────────
  /// Append a new child under [parentId], expand it, select & begin renaming
  /// the new node. Returns the new node's id.
  TreeNodeId addChild(TreeNodeId parentId, {String label = 'New item', bool folder = false, T? value}) {
    final id = _newId();
    final child = TreeNode<T>(id: id, label: label, folder: folder ? true : null, value: value);
    _apply(TreeOps.mapNode<T>(_roots, parentId, (p) => p.copyWith(
          folder: true,
          children: [...p.children, child],
        )));
    _expanded.add(parentId);
    _selected = id;
    _focused = id;
    _editing = id;
    return id;
  }

  /// Insert a sibling immediately after [id] (or append at root if [id] has
  /// no parent and isn't found nested). Returns the new node's id.
  TreeNodeId addSibling(TreeNodeId id, {String label = 'New item', T? value}) {
    final newId = _newId();
    final sibling = TreeNode<T>(id: newId, label: label, value: value);
    final ancestors = TreeOps.ancestorsOf<T>(_roots, id);
    if (ancestors.isEmpty) {
      // Root-level sibling.
      final out = <TreeNode<T>>[];
      for (final n in _roots) {
        out.add(n);
        if (n.id == id) out.add(sibling);
      }
      _apply(out);
    } else {
      _apply(TreeOps.insertAfter<T>(_roots, id, sibling));
    }
    _selected = newId;
    _focused = newId;
    _editing = newId;
    return newId;
  }

  /// Remove [id] and everything beneath it.
  void remove(TreeNodeId id) {
    final ancestors = TreeOps.ancestorsOf<T>(_roots, id);
    _apply(TreeOps.removeNode<T>(_roots, id));
    final gone = TreeOps.find<T>(_roots, id) == null;
    if (gone) {
      _checked.removeAll(_checked.where((c) => TreeOps.find<T>(_roots, c) == null).toList());
      _selection.remove(id);
      if (_selected == id) _selected = ancestors.isNotEmpty ? ancestors.last : null;
      if (_focused == id) _focused = _selected;
      if (_editing == id) _editing = null;
    }
  }

  /// Remove every node in the current multi-selection (and their subtrees), as
  /// a single undoable step. Ancestors are dropped from the work-list so a
  /// parent + child selected together don't double-remove. Returns the count.
  int removeSelected() {
    if (_selection.isEmpty) return 0;
    // Keep only the topmost selected nodes (skip any whose ancestor is selected).
    final ids = _selection.where((id) {
      final anc = TreeOps.ancestorsOf<T>(_roots, id).toSet();
      return !anc.any(_selection.contains);
    }).toList();
    var next = _roots.toList();
    for (final id in ids) {
      next = TreeOps.removeNode<T>(next, id);
    }
    _apply(next);
    _selection.clear();
    _checked.removeAll(_checked.where((c) => TreeOps.find<T>(_roots, c) == null).toList());
    if (_selected != null && TreeOps.find<T>(_roots, _selected!) == null) _selected = null;
    _focused = _selected;
    return ids.length;
  }

  /// Duplicate [id] (with a fresh id subtree) as the next sibling.
  TreeNodeId? duplicate(TreeNodeId id) {
    final original = node(id);
    if (original == null) return null;
    final copy = _cloneFresh(original).copyWith(label: '${original.label} copy');
    final ancestors = TreeOps.ancestorsOf<T>(_roots, id);
    if (ancestors.isEmpty) {
      final out = <TreeNode<T>>[];
      for (final n in _roots) {
        out.add(n);
        if (n.id == id) out.add(copy);
      }
      _apply(out);
    } else {
      _apply(TreeOps.insertAfter<T>(_roots, id, copy));
    }
    _selected = copy.id;
    _focused = copy.id;
    return copy.id;
  }

  // ── inline rename ──────────────────────────────────────────
  void beginEdit(TreeNodeId id) {
    _editing = id;
    _focused = id;
    notifyListeners();
  }

  void cancelEdit() {
    if (_editing == null) return;
    _editing = null;
    notifyListeners();
  }

  /// Commit an inline rename. Empty / unchanged labels just close the editor.
  void commitEdit(TreeNodeId id, String label) {
    final trimmed = label.trim();
    final current = node(id);
    _editing = null;
    if (current == null || trimmed.isEmpty || trimmed == current.label) {
      notifyListeners();
      return;
    }
    _apply(TreeOps.mapNode<T>(_roots, id, (n) => n.copyWith(label: trimmed)));
  }

  // ── undo / redo ────────────────────────────────────────────
  void undo() {
    if (_past.isEmpty) return;
    _future.add(_roots);
    _roots = _past.removeLast();
    notifyListeners();
  }

  void redo() {
    if (_future.isEmpty) return;
    _past.add(_roots);
    _roots = _future.removeLast();
    notifyListeners();
  }

  /// Replace the whole forest (resets history). For host-driven reloads.
  void replaceRoots(List<TreeNode<T>> roots) {
    _past.clear();
    _future.clear();
    _roots = List.unmodifiable(roots);
    notifyListeners();
  }

  // ── InheritedNotifier access ───────────────────────────────
  static TreeController<T>? of<T>(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<TreeScope<T>>();
    return scope?.controller;
  }
}

/// Exposes a [TreeController] to the subtree so any descendant (custom row
/// content, toolbars built by the host) can read/drive the tree and rebuild
/// when it changes.
class TreeScope<T> extends InheritedNotifier<TreeController<T>> {
  const TreeScope({super.key, required TreeController<T> controller, required super.child})
      : super(notifier: controller);

  TreeController<T> get controller => notifier!;
}
