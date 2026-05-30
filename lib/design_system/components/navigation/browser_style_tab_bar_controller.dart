// ============================================================
// BrowserStyleTabBarController — the tab strip's state, as a ChangeNotifier.
// ------------------------------------------------------------
// Single source of truth for the open tabs, the active tab, and the live
// page thumbnails. The widget delegates every op here, and the SAME
// controller is exposed to the page content via an InheritedNotifier so any
// page can drive the strip:
//
//   final tabs = BrowserStyleTabBarController.of(context); // may be null
//   tabs?.add(title: 'New report', kind: GLTabKind.chart);
//   tabs?.setDirty(myId, true);
//
// `of` returns null when a widget isn't hosted inside a BrowserStyleTabBar,
// so pages can be reused stand-alone.
//
//   File: lib/design_system/components/navigation/browser_style_tab_bar_controller.dart
// ============================================================

import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'tab_models.dart';

class BrowserStyleTabBarController extends ChangeNotifier {
  BrowserStyleTabBarController({List<BrowserTab>? tabs, int? activeId})
      : _tabs = [...(tabs ?? _defaults())] {
    _seed = _tabs.fold<int>(0, (m, t) => t.id > m ? t.id : m);
    _activeId = activeId ?? (_tabs.length > 1 ? _tabs[1].id : (_tabs.isNotEmpty ? _tabs.first.id : null));
  }

  static List<BrowserTab> _defaults() => [
        BrowserTab(id: 1, title: 'Chart of Accounts', kind: GLTabKind.ledger, pinned: true),
        BrowserTab(id: 2, title: 'Opening Journal Entry — JV-2024-0042', kind: GLTabKind.doc, dirty: true),
        BrowserTab(id: 3, title: 'Downtown Central Store', kind: GLTabKind.store),
        BrowserTab(id: 4, title: 'Dashboard', kind: GLTabKind.chart),
        BrowserTab(id: 5, title: 'Trial Balance — FY2024 Q3', kind: GLTabKind.ledger),
      ];

  final List<BrowserTab> _tabs;
  int? _activeId;
  late int _seed;
  final Map<int, ui.Image> _snaps = {};

  // ── reads ──────────────────────────────────────────────────
  List<BrowserTab> get tabs => List.unmodifiable(_tabs);
  int? get activeId => _activeId;
  int get length => _tabs.length;
  bool isActive(int id) => id == _activeId;

  BrowserTab? get activeTab => tabById(_activeId);
  BrowserTab? tabById(int? id) {
    if (id == null) return null;
    for (final t in _tabs) {
      if (t.id == id) return t;
    }
    return null;
  }

  List<BrowserTab> get pinned => _tabs.where((t) => t.pinned).toList();
  List<BrowserTab> get unpinned => _tabs.where((t) => !t.pinned).toList();

  /// Visual order: pinned first (in their relative order), then the rest.
  List<BrowserTab> get ordered => [...pinned, ...unpinned];

  bool canCloseOthers(int id) => _tabs.any((t) => t.id != id && !t.pinned);
  bool canCloseRight(int id) {
    final oi = ordered.indexWhere((t) => t.id == id);
    if (oi < 0) return false;
    return ordered.skip(oi + 1).any((t) => !t.pinned);
  }

  // ── live page thumbnails ───────────────────────────────────
  ui.Image? snapshot(int id) => _snaps[id];
  void setSnapshot(int id, ui.Image img) {
    final old = _snaps[id];
    if (identical(old, img)) return;
    _snaps[id] = img;
    old?.dispose();
    // No notifyListeners(): snapshots don't affect the strip's layout, and
    // the open preview is refreshed directly by the widget. Avoids churn.
  }

  void _dropSnapshot(int id) {
    _snaps.remove(id)?.dispose();
  }

  // ── mutations ──────────────────────────────────────────────
  void select(int id) {
    if (_activeId == id || !_tabs.any((t) => t.id == id)) return;
    _activeId = id;
    notifyListeners();
  }

  /// Adds a tab and (by default) activates it. Returns the new id.
  int add({String? title, GLTabKind? kind, bool activate = true, bool pinned = false, int? at}) {
    final id = ++_seed;
    final tab = BrowserTab(
      id: id,
      title: title ?? 'New Tab',
      kind: kind ?? kNewTabCycle[id % kNewTabCycle.length],
      pinned: pinned,
    );
    if (at != null && at >= 0 && at <= _tabs.length) {
      _tabs.insert(at, tab);
    } else {
      _tabs.add(tab);
    }
    if (activate) _activeId = id;
    notifyListeners();
    return id;
  }

  void close(int id) {
    final i = _tabs.indexWhere((t) => t.id == id);
    if (i < 0) return;
    final wasActive = _activeId == id;
    final ord = ordered;
    final oi = ord.indexWhere((t) => t.id == id);
    _tabs.removeAt(i);
    _dropSnapshot(id);
    if (wasActive) {
      if (_tabs.isEmpty) {
        _activeId = null;
      } else {
        final candidates = ord.where((t) => t.id != id && _tabs.any((n) => n.id == t.id)).toList();
        final idx = oi.clamp(0, candidates.length - 1);
        _activeId = candidates.isEmpty ? _tabs.first.id : candidates[idx].id;
      }
    }
    notifyListeners();
  }

  void closeOthers(int id) {
    _tabs.removeWhere((t) => t.id != id && !t.pinned);
    for (final key in _snaps.keys.toList()) {
      if (!_tabs.any((t) => t.id == key)) _dropSnapshot(key);
    }
    _activeId = id;
    notifyListeners();
  }

  void closeToRight(int id) {
    final oi = ordered.indexWhere((t) => t.id == id);
    if (oi < 0) return;
    final kill = ordered.skip(oi + 1).where((t) => !t.pinned).map((t) => t.id).toSet();
    if (kill.isEmpty) return;
    _tabs.removeWhere((t) => kill.contains(t.id));
    for (final k in kill) {
      _dropSnapshot(k);
    }
    if (kill.contains(_activeId)) _activeId = id;
    notifyListeners();
  }

  int duplicate(int id) {
    final i = _tabs.indexWhere((t) => t.id == id);
    if (i < 0) return -1;
    final nid = ++_seed;
    _tabs.insert(i + 1, _tabs[i].copyWith(id: nid, dirty: false, pinned: false));
    _activeId = nid;
    notifyListeners();
    return nid;
  }

  void togglePin(int id) => setPinned(id, !(tabById(id)?.pinned ?? false));

  void setPinned(int id, bool pinned) {
    final t = tabById(id);
    if (t == null || t.pinned == pinned) return;
    t.pinned = pinned;
    notifyListeners();
  }

  void reorder(int fromId, int toId) {
    if (fromId == toId) return;
    final from = _tabs.indexWhere((t) => t.id == fromId);
    final to = _tabs.indexWhere((t) => t.id == toId);
    if (from < 0 || to < 0) return;
    _tabs.insert(to, _tabs.removeAt(from));
    notifyListeners();
  }

  void setDirty(int id, bool dirty) {
    final t = tabById(id);
    if (t == null || t.dirty == dirty) return;
    t.dirty = dirty;
    notifyListeners();
  }

  void rename(int id, String title) {
    final t = tabById(id);
    if (t == null || t.title == title) return;
    t.title = title;
    notifyListeners();
  }

  /// Escape hatch for arbitrary edits; call inside and we notify after.
  void mutate(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  @override
  void dispose() {
    for (final img in _snaps.values) {
      img.dispose();
    }
    _snaps.clear();
    super.dispose();
  }

  // ── inherited lookup ───────────────────────────────────────
  /// The controller hosting [context], or null if not inside a tab bar.
  static BrowserStyleTabBarController? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BrowserStyleTabBarScope>()?.controller;

  /// Non-listening variant (use in callbacks / initState).
  static BrowserStyleTabBarController? read(BuildContext context) =>
      (context.getElementForInheritedWidgetOfExactType<BrowserStyleTabBarScope>()?.widget as BrowserStyleTabBarScope?)
          ?.controller;
}

/// Exposes the controller to descendants; rebuilds dependents on notify.
class BrowserStyleTabBarScope extends InheritedNotifier<BrowserStyleTabBarController> {
  const BrowserStyleTabBarScope({super.key, required BrowserStyleTabBarController controller, required super.child})
      : super(notifier: controller);

  BrowserStyleTabBarController get controller => notifier!;
}
