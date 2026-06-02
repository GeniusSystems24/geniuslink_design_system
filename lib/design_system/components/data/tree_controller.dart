// ============================================================
// Tree — CONTROLLER.
// ------------------------------------------------------------
// The single source of truth and all of the tree's logic, as a
// ChangeNotifier. The view (Tree) is a thin render of this state and forwards
// every gesture / keystroke here. The same controller is exposed to row
// content via an InheritedNotifier so any descendant can drive the tree:
//
//   final t = TreeController.of(context);   // may be null
//   t?.addChild(parentId);
//
// Holds: the (immutable) node forest as the working copy, the expanded set,
// the tri-state checked set, single selection, a keyboard focus cursor, the
// search query, the inline-rename target, and one undo/redo history covering
// every structural change. Nodes are immutable, so a snapshot is just the
// previous `List<TreeNode>` reference — undo is a swap, never a deep clone.
//
//   File: lib/design_system/components/data/tree_controller.dart
// ============================================================

import 'package:flutter/widgets.dart';
import 'tree_models.dart';

class TreeController extends ChangeNotifier {
  TreeController({
    required List<TreeNode> roots,
    Set<TreeNodeId>? expanded,
    Set<TreeNodeId>? checked,
    TreeNodeId? selected,
    this.historyLimit = 200,
  })  : _roots = List.unmodifiable(roots),
        _expanded = {...?expanded},
        _checked = {...?checked},
        _selected = selected {
    _focused = selected;
  }

  final int historyLimit;

  List<TreeNode> _roots;
  final Set<TreeNodeId> _expanded;
  final Set<TreeNodeId> _checked; // fully-checked LEAVES (branches derive)
  TreeNodeId? _selected;
  TreeNodeId? _focused;
  String _query = '';
  TreeNodeId? _editing;

  final List<List<TreeNode>> _past = [];
  final List<List<TreeNode>> _future = [];

  int _seq = 0;

  // ── reads ──────────────────────────────────────────────────
  List<TreeNode> get roots => _roots;
  String get query => _query;
  TreeNodeId? get selected => _selected;
  TreeNodeId? get focused => _focused ?? _selected;
  TreeNodeId? get editing => _editing;
  bool get canUndo => _past.isNotEmpty;
  bool get canRedo => _future.isNotEmpty;
  int get nodeCount => TreeOps.count(_roots);
  bool get filtering => _query.trim().isNotEmpty;

  bool isExpanded(TreeNodeId id) => _expanded.contains(id);
  bool isSelected(TreeNodeId id) => _selected == id;
  TreeNode? node(TreeNodeId id) => TreeOps.find(_roots, id);

  /// Ids of every checked leaf (the meaningful selection for a host).
  Set<TreeNodeId> get checkedLeafIds => {..._checked};

  /// How many nodes currently match the search query (0 when not filtering).
  int get matchCount {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return 0;
    var n = 0;
    TreeOps.walk(_roots, (node, _) {
      if (node.label.toLowerCase().contains(q)) n++;
    });
    return n;
  }

  // ── flatten (expansion + filter) ───────────────────────────
  /// The visible rows in render order. While searching, only matches and
  /// their ancestors are shown, and ancestor folders are force-expanded so
  /// the hits are revealed.
  List<TreeRow> visibleRows() {
    final q = _query.trim().toLowerCase();
    final filter = q.isNotEmpty;

    final matched = <TreeNodeId>{};
    final onPath = <TreeNodeId>{}; // ancestors of a match
    if (filter) {
      void rec(List<TreeNode> nodes, List<TreeNodeId> path) {
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

    bool visible(TreeNode n) => !filter || matched.contains(n.id) || onPath.contains(n.id);
    bool expandedFor(TreeNode n) => filter ? onPath.contains(n.id) : _expanded.contains(n.id);

    final rows = <TreeRow>[];
    void emit(List<TreeNode> nodes, int depth, List<bool> ancestorHasNext) {
      final shown = filter ? nodes.where(visible).toList() : nodes;
      for (var i = 0; i < shown.length; i++) {
        final n = shown[i];
        final isLast = i == shown.length - 1;
        final expanded = expandedFor(n);
        rows.add(TreeRow(
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
  TreeCheck checkState(TreeNode n) {
    final leaves = TreeOps.leafIds(n);
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
    final leaves = TreeOps.leafIds(n);
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
    TreeOps.walk(_roots, (n, _) {
      if (n.isFolder) _expanded.add(n.id);
    });
    notifyListeners();
  }

  void collapseAll() {
    _expanded.clear();
    notifyListeners();
  }

  // ── selection + keyboard focus ─────────────────────────────
  void select(TreeNodeId id) {
    final n = node(id);
    if (n == null || !n.selectable) return;
    _selected = id;
    _focused = id;
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
    final ancestors = TreeOps.ancestorsOf(_roots, id);
    if (ancestors.isNotEmpty) {
      _focused = ancestors.last;
      notifyListeners();
    }
  }

  // ── search ─────────────────────────────────────────────────
  void setQuery(String q) {
    if (q == _query) return;
    _query = q;
    notifyListeners();
  }

  // ── history plumbing ───────────────────────────────────────
  void _apply(List<TreeNode> next) {
    _past.add(_roots);
    if (_past.length > historyLimit) _past.removeAt(0);
    _future.clear();
    _roots = List.unmodifiable(next);
    notifyListeners();
  }

  TreeNodeId _newId() => 'gen-${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  TreeNode _cloneFresh(TreeNode n) =>
      n.copyWith(id: _newId(), children: [for (final c in n.children) _cloneFresh(c)]);

  // ── structural edits (undoable) ────────────────────────────
  /// Append a new child under [parentId], expand it, select & begin renaming
  /// the new node. Returns the new node's id.
  TreeNodeId addChild(TreeNodeId parentId, {String label = 'New item', bool folder = false}) {
    final id = _newId();
    final child = TreeNode(id: id, label: label, folder: folder ? true : null);
    _apply(TreeOps.mapNode(_roots, parentId, (p) => p.copyWith(
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
  TreeNodeId addSibling(TreeNodeId id, {String label = 'New item'}) {
    final newId = _newId();
    final sibling = TreeNode(id: newId, label: label);
    final ancestors = TreeOps.ancestorsOf(_roots, id);
    if (ancestors.isEmpty) {
      // Root-level sibling.
      final out = <TreeNode>[];
      for (final n in _roots) {
        out.add(n);
        if (n.id == id) out.add(sibling);
      }
      _apply(out);
    } else {
      _apply(TreeOps.insertAfter(_roots, id, sibling));
    }
    _selected = newId;
    _focused = newId;
    _editing = newId;
    return newId;
  }

  /// Remove [id] and everything beneath it.
  void remove(TreeNodeId id) {
    final ancestors = TreeOps.ancestorsOf(_roots, id);
    _apply(TreeOps.removeNode(_roots, id));
    final gone = TreeOps.find(_roots, id) == null;
    if (gone) {
      _checked.removeAll(_checked.where((c) => TreeOps.find(_roots, c) == null).toList());
      if (_selected == id) _selected = ancestors.isNotEmpty ? ancestors.last : null;
      if (_focused == id) _focused = _selected;
      if (_editing == id) _editing = null;
    }
  }

  /// Duplicate [id] (with a fresh id subtree) as the next sibling.
  TreeNodeId? duplicate(TreeNodeId id) {
    final original = node(id);
    if (original == null) return null;
    final copy = _cloneFresh(original).copyWith(label: '${original.label} copy');
    final ancestors = TreeOps.ancestorsOf(_roots, id);
    if (ancestors.isEmpty) {
      final out = <TreeNode>[];
      for (final n in _roots) {
        out.add(n);
        if (n.id == id) out.add(copy);
      }
      _apply(out);
    } else {
      _apply(TreeOps.insertAfter(_roots, id, copy));
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
    _apply(TreeOps.mapNode(_roots, id, (n) => n.copyWith(label: trimmed)));
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
  void replaceRoots(List<TreeNode> roots) {
    _past.clear();
    _future.clear();
    _roots = List.unmodifiable(roots);
    notifyListeners();
  }

  // ── InheritedNotifier access ───────────────────────────────
  static TreeController? of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<TreeScope>();
    return scope?.controller;
  }
}

/// Exposes a [TreeController] to the subtree so any descendant (custom row
/// content, toolbars built by the host) can read/drive the tree and rebuild
/// when it changes.
class TreeScope extends InheritedNotifier<TreeController> {
  const TreeScope({super.key, required TreeController controller, required super.child})
      : super(notifier: controller);

  TreeController get controller => notifier!;
}
