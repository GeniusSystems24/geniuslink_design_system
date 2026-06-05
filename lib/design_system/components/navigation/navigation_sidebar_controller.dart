// ============================================================
// NavigationSidebar — CONTROLLER.
// ------------------------------------------------------------
// The single source of truth for the sidebar, as a ChangeNotifier. The view
// (NavigationSidebar) is a thin render of this state and forwards every gesture
// to it. The controller is also published to descendants via an
// InheritedNotifier scope, so page content can drive the nav:
//
//   final nav = NavigationSidebarController.of<String>(context);
//   nav?.navigate('settingsHub');
//
// Holds: the immutable section forest, the active node id, the expanded-module
// set (auto-opening the active node's ancestors), the collapsed (rail) flag,
// the mobile-drawer open flag, and an optional search query for the filter.
//
//   File: lib/design_system/components/navigation/navigation_sidebar_controller.dart
// ============================================================

import 'package:flutter/widgets.dart';
import 'navigation_sidebar_models.dart';

class NavigationSidebarController<T> extends ChangeNotifier {
  NavigationSidebarController({
    required List<NavSection<T>> sections,
    NavNodeId? active,
    Set<NavNodeId>? expanded,
    bool collapsed = false,
    bool drawerOpen = false,
    bool autoExpandActive = true,
  })  : _sections = List.unmodifiable(sections),
        _active = active,
        _expanded = {...?expanded},
        _collapsed = collapsed,
        _drawerOpen = drawerOpen,
        _autoExpandActive = autoExpandActive {
    if (_autoExpandActive && active != null) {
      _expanded.addAll(NavOps.ancestorsOf<T>(_sections, active));
    }
  }

  List<NavSection<T>> _sections;
  NavNodeId? _active;
  final Set<NavNodeId> _expanded;
  bool _collapsed;
  bool _drawerOpen;
  final bool _autoExpandActive;
  String _query = '';

  // ── reads ──────────────────────────────────────────────────
  List<NavSection<T>> get sections => _sections;
  NavNodeId? get active => _active;
  bool get collapsed => _collapsed;
  bool get drawerOpen => _drawerOpen;
  String get query => _query;
  bool get filtering => _query.trim().isNotEmpty;

  bool isExpanded(NavNodeId id) => _expanded.contains(id);
  bool isActive(NavNodeId id) => _active == id;

  /// Whether [id] is on the path to the active node (used to accent-tint an
  /// ancestor module/group even while the leaf itself is the active row).
  bool ownsActive(NavNodeId id) =>
      _active != null && NavOps.ancestorsOf<T>(_sections, _active!).contains(id);

  NavNode<T>? node(NavNodeId id) => NavOps.find<T>(_sections, id);

  /// The strongly-typed value behind the active node, or null.
  T? get activeValue => _active == null ? null : node(_active!)?.value;

  // ── navigation ─────────────────────────────────────────────
  /// Make [id] the active destination. Auto-opens its ancestor modules and
  /// closes the mobile drawer (so a drawer tap navigates *and* dismisses).
  void navigate(NavNodeId id) {
    final n = node(id);
    if (n == null || !n.enabled) return;
    var changed = false;
    if (_active != id) {
      _active = id;
      changed = true;
    }
    if (_autoExpandActive) {
      for (final a in NavOps.ancestorsOf<T>(_sections, id)) {
        changed |= _expanded.add(a);
      }
    }
    if (_drawerOpen) {
      _drawerOpen = false;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  // ── expansion ──────────────────────────────────────────────
  void expand(NavNodeId id) {
    if (_expanded.add(id)) notifyListeners();
  }

  void collapse(NavNodeId id) {
    if (_expanded.remove(id)) notifyListeners();
  }

  void toggleNode(NavNodeId id) {
    _expanded.contains(id) ? _expanded.remove(id) : _expanded.add(id);
    notifyListeners();
  }

  void expandAll() {
    NavOps.walk<T>(_sections, (n, _) {
      if (n.hasChildren) _expanded.add(n.id);
    });
    notifyListeners();
  }

  void collapseAll() {
    if (_expanded.isEmpty) return;
    _expanded.clear();
    notifyListeners();
  }

  // ── rail (collapse) ────────────────────────────────────────
  set collapsed(bool v) {
    if (_collapsed == v) return;
    _collapsed = v;
    notifyListeners();
  }

  void toggleCollapsed() => collapsed = !_collapsed;

  // ── mobile drawer ──────────────────────────────────────────
  set drawerOpen(bool v) {
    if (_drawerOpen == v) return;
    _drawerOpen = v;
    notifyListeners();
  }

  void openDrawer() => drawerOpen = true;
  void closeDrawer() => drawerOpen = false;
  void toggleDrawer() => drawerOpen = !_drawerOpen;

  // ── search filter (optional) ───────────────────────────────
  void setQuery(String q) {
    if (q == _query) return;
    _query = q;
    notifyListeners();
  }

  /// Ids that match the current query, plus their ancestors (so the matches
  /// are reachable). Empty when not filtering.
  Set<NavNodeId> matchSet() {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const {};
    final matched = <NavNodeId>{};
    final onPath = <NavNodeId>{};
    void rec(List<NavNode<T>> nodes, List<NavNodeId> path) {
      for (final n in nodes) {
        if (n.label.toLowerCase().contains(q)) {
          matched.add(n.id);
          onPath.addAll(path);
        }
        if (n.hasChildren) rec(n.children, [...path, n.id]);
      }
    }

    for (final s in _sections) {
      rec(s.items, const []);
    }
    return {...matched, ...onPath};
  }

  // ── host-driven reload ─────────────────────────────────────
  /// Replace the whole section forest (e.g. permissions changed).
  void replaceSections(List<NavSection<T>> sections) {
    _sections = List.unmodifiable(sections);
    if (_active != null && node(_active!) == null) _active = null;
    notifyListeners();
  }

  // ── InheritedNotifier access ───────────────────────────────
  static NavigationSidebarController<T>? of<T>(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<NavigationSidebarScope<T>>();
    return scope?.controller;
  }
}

/// Exposes a [NavigationSidebarController] to the subtree so any descendant
/// (a page, a custom header/footer) can read/drive the sidebar and rebuild
/// when it changes.
class NavigationSidebarScope<T> extends InheritedNotifier<NavigationSidebarController<T>> {
  const NavigationSidebarScope({
    super.key,
    required NavigationSidebarController<T> controller,
    required super.child,
  }) : super(notifier: controller);

  NavigationSidebarController<T> get controller => notifier!;
}
