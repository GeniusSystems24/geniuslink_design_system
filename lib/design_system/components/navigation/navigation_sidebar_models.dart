// ============================================================
// NavigationSidebar — MODEL.
// ------------------------------------------------------------
// Pure data: the immutable schema a host builds to describe its navigation —
// a list of titled sections, each holding a tree of nodes (direct leaf · or a
// module that drills into groups → items). No widgets, no mutable state:
// expansion, the active id, the rail/drawer mode and the open-flyout all live
// in the controller, keyed by node id.
//
// The tree mirrors the GeniusLink web sidebar's four roles:
//   Section  →  Module     →  Group        →  Item        (Finance ▸ Accounts ▸ Chart of Accounts ▸ Account Tree)
//   Section  →  Direct leaf                                (Overview ▸ Dashboard)
// Role is *derived* from depth + whether the node has children — see
// [NavNodeRole.of]. The same recursion paints any depth.
//
//   File: lib/design_system/components/navigation/navigation_sidebar_models.dart
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show IconData;

/// Stable identity of a nav node (the host's own screen/route key).
typedef NavNodeId = String;

/// The four visual roles a node can take, derived from its position.
enum NavNodeRole {
  /// Depth-0 leaf — a flat top-level destination (e.g. *Dashboard*). Renders
  /// as a pill row that fills with the accent when active.
  direct,

  /// Depth-0 branch — a collapsible module (e.g. *Accounts*). Renders with its
  /// leading icon and a disclosure chevron; tints accent when it owns the
  /// active screen.
  module,

  /// Depth-≥1 branch — a sub-group header inside a module (e.g. *Chart of
  /// Accounts*). Renders uppercase with a bullet.
  group,

  /// Depth-≥1 leaf — a destination inside a group. Renders with a boxed icon.
  item;

  /// Resolve a node's role from its [depth] and whether it [hasChildren].
  static NavNodeRole of({required int depth, required bool hasChildren}) {
    if (hasChildren) return depth == 0 ? NavNodeRole.module : NavNodeRole.group;
    return depth == 0 ? NavNodeRole.direct : NavNodeRole.item;
  }
}

/// Semantic colour of a [NavBadge].
enum NavBadgeTone { accent, success, warning, muted }

/// A small trailing pill on a nav row — a count (`'3'`), a status (`'New'`,
/// `'Live'`) or any short token. In the collapsed rail it collapses to a dot.
@immutable
class NavBadge {
  final String text;
  final NavBadgeTone tone;
  const NavBadge(this.text, {this.tone = NavBadgeTone.accent});
}

/// One node in the navigation tree, generic over a strongly-typed host
/// [value] (a route, a screen enum, …) so callers read `node.value` with no
/// casting. Immutable; compose `List<NavNode<T>>` (each with `children`) to
/// describe the whole sidebar.
@immutable
class NavNode<T> {
  /// Unique, stable id across the whole sidebar (the host's screen key).
  final NavNodeId id;

  /// Display label (also what the optional search filter matches against).
  final String label;

  /// Leading icon. Optional for [NavNodeRole.group] headers (they show a
  /// bullet), required-in-spirit for everything else.
  final IconData? icon;

  /// Child nodes. Empty for a leaf.
  final List<NavNode<T>> children;

  /// Optional trailing badge (count / status / shortcut hint).
  final NavBadge? badge;

  /// Two-key "g d"-style shortcut shown on hover (purely presentational here;
  /// wiring the keystroke is the host's job).
  final List<String>? shortcut;

  /// Strongly-typed payload travelling with the node (`null` for structural
  /// nodes).
  final T? value;

  /// When false the row is shown but can't be activated.
  final bool enabled;

  const NavNode({
    required this.id,
    required this.label,
    this.icon,
    this.children = const [],
    this.badge,
    this.shortcut,
    this.value,
    this.enabled = true,
  });

  bool get hasChildren => children.isNotEmpty;
  bool get isLeaf => children.isEmpty;

  NavNode<T> copyWith({
    NavNodeId? id,
    String? label,
    IconData? icon,
    List<NavNode<T>>? children,
    NavBadge? badge,
    List<String>? shortcut,
    T? value,
    bool? enabled,
  }) =>
      NavNode<T>(
        id: id ?? this.id,
        label: label ?? this.label,
        icon: icon ?? this.icon,
        children: children ?? this.children,
        badge: badge ?? this.badge,
        shortcut: shortcut ?? this.shortcut,
        value: value ?? this.value,
        enabled: enabled ?? this.enabled,
      );

  @override
  bool operator ==(Object other) => other is NavNode<T> && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// A titled band of the sidebar (e.g. *Overview*, *Finance*). The title is the
/// small uppercase eyebrow above the band; [items] are its top-level nodes.
@immutable
class NavSection<T> {
  final String title;
  final List<NavNode<T>> items;
  const NavSection({required this.title, required this.items});
}

/// How the sidebar is currently presented. The view can derive this from the
/// available width (see [NavSidebarBreakpoints]) or a host can force it.
enum NavSidebarMode {
  /// Full-width labelled tree.
  expanded,

  /// Icon-only rail; hovering a module opens a grouped flyout.
  rail,

  /// Off-canvas drawer slid over the content (small screens), with a scrim.
  drawer,
}

/// Width thresholds that map an available width to a [NavSidebarMode] — the
/// Flutter analogue of the web `getNavMode(w)`. Tune per app.
@immutable
class NavSidebarBreakpoints {
  /// At/above this the sidebar is [NavSidebarMode.expanded].
  final double expanded;

  /// At/above this (but below [expanded]) it's a [NavSidebarMode.rail];
  /// below it the sidebar becomes a [NavSidebarMode.drawer].
  final double rail;

  const NavSidebarBreakpoints({this.expanded = 1200, this.rail = 768});

  NavSidebarMode modeFor(double width) {
    if (width >= expanded) return NavSidebarMode.expanded;
    if (width >= rail) return NavSidebarMode.rail;
    return NavSidebarMode.drawer;
  }
}

/// Static helpers shared by the controller and the view.
class NavOps {
  NavOps._();

  /// Depth-first walk over every node in [sections], with its ancestor path.
  static void walk<T>(
    List<NavSection<T>> sections,
    void Function(NavNode<T> node, List<NavNode<T>> ancestors) visit,
  ) {
    void rec(List<NavNode<T>> nodes, List<NavNode<T>> path) {
      for (final n in nodes) {
        visit(n, path);
        if (n.hasChildren) rec(n.children, [...path, n]);
      }
    }

    for (final s in sections) {
      rec(s.items, const []);
    }
  }

  /// Find a node by id across all sections, or null.
  static NavNode<T>? find<T>(List<NavSection<T>> sections, NavNodeId id) {
    NavNode<T>? hit;
    walk<T>(sections, (n, _) {
      if (n.id == id) hit = n;
    });
    return hit;
  }

  /// Ancestor ids of [id], outermost-first (empty if top-level or missing).
  static List<NavNodeId> ancestorsOf<T>(List<NavSection<T>> sections, NavNodeId id) {
    List<NavNodeId>? result;
    void rec(List<NavNode<T>> nodes, List<NavNodeId> path) {
      for (final n in nodes) {
        if (n.id == id) {
          result = path;
          return;
        }
        if (n.hasChildren) rec(n.children, [...path, n.id]);
      }
    }

    for (final s in sections) {
      rec(s.items, const []);
      if (result != null) break;
    }
    return result ?? const [];
  }

  /// True when [node] or anything beneath it carries a badge — used to mark a
  /// collapsed module/rail icon with a dot.
  static bool subtreeHasBadge<T>(NavNode<T> node) {
    if (node.badge != null) return true;
    for (final c in node.children) {
      if (subtreeHasBadge(c)) return true;
    }
    return false;
  }

  /// All leaf ids beneath (and including, if leaf) [node].
  static List<NavNodeId> leafIds<T>(NavNode<T> node) {
    final out = <NavNodeId>[];
    void rec(NavNode<T> n) {
      if (n.isLeaf) {
        out.add(n.id);
      } else {
        for (final c in n.children) rec(c);
      }
    }

    rec(node);
    return out;
  }
}
