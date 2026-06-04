// ============================================================
// Tree — MODEL  (generic over the node's value type `T`).
// ------------------------------------------------------------
// Pure data: the immutable node schema a host builds to describe its tree
// (a file explorer, a category outline, an org chart, a chart of accounts …),
// the flattened "visible row" the view renders, and small lookup helpers. No
// widgets, no mutable state — expansion / selection / checks all live in the
// controller, keyed by node id, so this layer carries no UI coupling.
//
// `TreeNode<T>` carries a **typed** `value` of type `T` (the strongly-typed
// host payload — an Account, a FileMeta, a Person, …) alongside the loose
// `data` map kept for ad-hoc metadata. Make the whole tree `TreeNode<Account>`
// and `node.value` is an `Account`, with no casting at the call site.
//
//   File: lib/design_system/components/data/tree_models.dart
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show IconData;

/// Stable identity of a node. Kept as a String so hosts can use their own
/// keys (paths, uuids, db ids) without adapting.
typedef TreeNodeId = String;

/// The schema for a single node, generic over its [value] type [T]. This is
/// the customisation surface: a host composes a `List<TreeNode<T>>` (each with
/// its own `children`) to define the whole tree. Immutable — structural edits
/// in the controller produce new node objects via [copyWith], which makes
/// undo/redo a cheap reference swap.
@immutable
class TreeNode<T> {
  /// Unique, stable id across the whole tree.
  final TreeNodeId id;

  /// Display label (also what inline-rename and search match against).
  final String label;

  /// Child nodes. Empty for a leaf (or for an empty folder — see [folder]).
  final List<TreeNode<T>> children;

  /// Strongly-typed host payload travelling with the node. `null` for nodes
  /// that carry no domain object (e.g. structural group headers).
  final T? value;

  /// Optional leading icon override. When null the view picks a sensible
  /// default (folder-open / folder / leaf dot) from the node's role.
  final IconData? icon;

  /// Optional trailing badge text (a count, a status, a shortcut…).
  final String? badge;

  /// Whether this node can hold children — i.e. renders a disclosure twisty
  /// and accepts "add child". When null it's inferred: a node is a folder iff
  /// it currently has children. Set `true` for an empty folder, `false` to
  /// force a leaf even though children were supplied.
  final bool? folder;

  /// When false the row can't be selected (still expandable / shown).
  final bool selectable;

  /// Arbitrary, loosely-typed metadata travelling with the node. Prefer
  /// [value] for the primary payload; use this for incidental flags.
  final Map<String, Object?> data;

  const TreeNode({
    required this.id,
    required this.label,
    this.children = const [],
    this.value,
    this.icon,
    this.badge,
    this.folder,
    this.selectable = true,
    this.data = const {},
  });

  /// Does this node act as a folder (expandable / can receive children)?
  bool get isFolder => folder ?? children.isNotEmpty;

  /// Has at least one child right now.
  bool get hasChildren => children.isNotEmpty;

  TreeNode<T> copyWith({
    TreeNodeId? id,
    String? label,
    List<TreeNode<T>>? children,
    Object? value = _sentinel,
    IconData? icon,
    Object? badge = _sentinel,
    Object? folder = _sentinel,
    bool? selectable,
    Map<String, Object?>? data,
  }) =>
      TreeNode<T>(
        id: id ?? this.id,
        label: label ?? this.label,
        children: children ?? this.children,
        value: value == _sentinel ? this.value : value as T?,
        icon: icon ?? this.icon,
        badge: badge == _sentinel ? this.badge : badge as String?,
        folder: folder == _sentinel ? this.folder : folder as bool?,
        selectable: selectable ?? this.selectable,
        data: data ?? this.data,
      );

  static const Object _sentinel = Object();

  @override
  bool operator ==(Object other) => other is TreeNode<T> && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// One row produced by flattening the tree for the current expansion / filter
/// state. Carries everything the view needs to paint a single line, including
/// the ancestor "has a following sibling" flags used to draw the indent
/// guide-lines (│ ├ └).
@immutable
class TreeRow<T> {
  final TreeNode<T> node;

  /// Nesting depth (0 for roots).
  final int depth;

  /// Whether this node is currently expanded (only meaningful for folders).
  final bool expanded;

  /// Whether the node has children to disclose.
  final bool hasChildren;

  /// Whether the node is the last among its visible siblings (└ vs ├).
  final bool isLast;

  /// For each ancestor depth, whether that ancestor has a following sibling —
  /// i.e. whether to draw a continuing vertical guide at that column.
  final List<bool> ancestorHasNext;

  const TreeRow({
    required this.node,
    required this.depth,
    required this.expanded,
    required this.hasChildren,
    required this.isLast,
    required this.ancestorHasNext,
  });
}

/// Tri-state check status of a node (derived from its leaves).
enum TreeCheck { none, some, all }

/// What a [Tree] lets the user select via clicks / keyboard (independent of the
/// checkbox layer, which is always available when `showCheckboxes` is on).
enum TreeSelectionMode {
  /// No click-selection layer (display / navigation only).
  none,

  /// Exactly one node at a time (the classic behaviour).
  single,

  /// Any number of nodes — Ctrl/⌘-click toggles one, Shift-click selects the
  /// contiguous visible range from the anchor, plain click resets to one.
  multi,
}

/// Static helpers shared by the controller and the view. Each is generic over
/// the node value type [T]; the type argument is normally inferred from the
/// `List<TreeNode<T>>` you pass in.
class TreeOps {
  TreeOps._();

  /// Depth-first walk; [visit] receives each node and its ancestor path.
  static void walk<T>(List<TreeNode<T>> roots, void Function(TreeNode<T> node, List<TreeNode<T>> ancestors) visit) {
    void rec(List<TreeNode<T>> nodes, List<TreeNode<T>> path) {
      for (final n in nodes) {
        visit(n, path);
        if (n.children.isNotEmpty) rec(n.children, [...path, n]);
      }
    }

    rec(roots, const []);
  }

  /// Total node count.
  static int count<T>(List<TreeNode<T>> roots) {
    var n = 0;
    walk<T>(roots, (_, __) => n++);
    return n;
  }

  /// Find a node by id, or null.
  static TreeNode<T>? find<T>(List<TreeNode<T>> roots, TreeNodeId id) {
    TreeNode<T>? hit;
    walk<T>(roots, (n, _) {
      if (n.id == id) hit = n;
    });
    return hit;
  }

  /// Ancestor ids of [id], outermost-first (empty if root or missing).
  static List<TreeNodeId> ancestorsOf<T>(List<TreeNode<T>> roots, TreeNodeId id) {
    List<TreeNodeId>? result;
    void rec(List<TreeNode<T>> nodes, List<TreeNodeId> path) {
      for (final n in nodes) {
        if (n.id == id) {
          result = path;
          return;
        }
        if (n.children.isNotEmpty) rec(n.children, [...path, n.id]);
      }
    }

    rec(roots, const []);
    return result ?? const [];
  }

  /// All leaf ids beneath (and including, if leaf) [node].
  static List<TreeNodeId> leafIds<T>(TreeNode<T> node) {
    final out = <TreeNodeId>[];
    void rec(TreeNode<T> n) {
      if (n.children.isEmpty) {
        out.add(n.id);
      } else {
        for (final c in n.children) rec(c);
      }
    }

    rec(node);
    return out;
  }

  /// All ids beneath (and including) [node].
  static List<TreeNodeId> subtreeIds<T>(TreeNode<T> node) {
    final out = <TreeNodeId>[];
    void rec(TreeNode<T> n) {
      out.add(n.id);
      for (final c in n.children) rec(c);
    }

    rec(node);
    return out;
  }

  /// Rebuild [nodes], replacing the node matching [id] with `transform(node)`.
  static List<TreeNode<T>> mapNode<T>(List<TreeNode<T>> nodes, TreeNodeId id, TreeNode<T> Function(TreeNode<T>) transform) {
    return [
      for (final n in nodes)
        if (n.id == id)
          transform(n)
        else if (n.children.isEmpty)
          n
        else
          n.copyWith(children: mapNode<T>(n.children, id, transform)),
    ];
  }

  /// Rebuild [nodes] with [id] (and its subtree) removed.
  static List<TreeNode<T>> removeNode<T>(List<TreeNode<T>> nodes, TreeNodeId id) {
    final out = <TreeNode<T>>[];
    for (final n in nodes) {
      if (n.id == id) continue;
      out.add(n.children.isEmpty ? n : n.copyWith(children: removeNode<T>(n.children, id)));
    }
    return out;
  }

  /// Rebuild [nodes], inserting [toAdd] immediately after the node [afterId]
  /// at whatever depth it lives.
  static List<TreeNode<T>> insertAfter<T>(List<TreeNode<T>> nodes, TreeNodeId afterId, TreeNode<T> toAdd) {
    final out = <TreeNode<T>>[];
    for (final n in nodes) {
      out.add(n.children.isEmpty ? n : n.copyWith(children: insertAfter<T>(n.children, afterId, toAdd)));
      if (n.id == afterId) out.add(toAdd);
    }
    return out;
  }
}
