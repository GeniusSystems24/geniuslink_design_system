// ============================================================
// BrowserStyleTabBar — modern browser-style tab strip (full).
// ------------------------------------------------------------
// Faithful Flutter port of design_system/BrowserTabs.jsx. Self-contained
// demo state. Features: active/inactive/hover/pressed · closable · add (+) ·
// select · overflow scroll + chevrons · pinned tabs (icon-only, anchored) ·
// right-click context menu (close / close others / close to the right /
// duplicate / pin·unpin) · unsaved (dirty) indicator · dirty-close confirm
// dialog · tab-list dropdown · hover/long-press mini-page preview ·
// long-title truncation + tooltip · drag-to-reorder · keyboard
// (←/→/Home/End) · dark/light · RTL.
//   File: lib/design_system/components/navigation/browser_style_tab_bar.dart
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../tokens/tokens.dart';
import '../../tokens/gl_surfaces.dart';
import 'tab_models.dart';
import 'tab_pages.dart';
import 'tab_overlays.dart';

class BrowserStyleTabBar extends StatefulWidget {
  /// Optional seed state. Defaults to the JSX demo set.
  final List<BrowserTab>? tabsState;
  const BrowserStyleTabBar({super.key, this.tabsState});

  @override
  State<BrowserStyleTabBar> createState() => _BrowserStyleTabBarState();
}

class _BrowserStyleTabBarState extends State<BrowserStyleTabBar> {
  late List<BrowserTab> _tabs;
  late int _active;
  int _seed = 10;

  int? _dragId;
  int? _overId;

  bool _chevStart = false;
  bool _chevEnd = false;

  final _scroll = ScrollController();
  final _caretKey = GlobalKey();
  final _focusNode = FocusNode();

  // overlay handles
  OverlayEntry? _menuEntry;
  OverlayEntry? _listEntry;
  OverlayEntry? _previewEntry;
  int? _previewId;
  bool get _listOpen => _listEntry != null;

  @override
  void initState() {
    super.initState();
    _tabs = widget.tabsState ??
        [
          BrowserTab(id: 1, title: 'Chart of Accounts', kind: GLTabKind.ledger, pinned: true),
          BrowserTab(id: 2, title: 'Opening Journal Entry — JV-2024-0042', kind: GLTabKind.doc, dirty: true),
          BrowserTab(id: 3, title: 'Downtown Central Store', kind: GLTabKind.store),
          BrowserTab(id: 4, title: 'Dashboard', kind: GLTabKind.chart),
          BrowserTab(id: 5, title: 'Trial Balance — FY2024 Q3', kind: GLTabKind.ledger),
        ];
    _active = _tabs.length > 1 ? _tabs[1].id : _tabs.first.id;
    _scroll.addListener(_measure);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void dispose() {
    _hideAllOverlays();
    _scroll.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── derived ──
  List<BrowserTab> get _pinned => _tabs.where((t) => t.pinned).toList();
  List<BrowserTab> get _unpinned => _tabs.where((t) => !t.pinned).toList();
  List<BrowserTab> get _ordered => [..._pinned, ..._unpinned];

  // ── overflow chevrons ──
  void _measure() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    final max = pos.maxScrollExtent;
    final off = pos.pixels;
    final start = max > 2 && off > 2;
    final end = max > 2 && off < max - 2;
    if (start != _chevStart || end != _chevEnd) {
      setState(() {
        _chevStart = start;
        _chevEnd = end;
      });
    }
  }

  void _scrollByDir(bool towardEnd) {
    if (!_scroll.hasClients) return;
    final target = (_scroll.offset + 220 * (towardEnd ? 1 : -1)).clamp(0.0, _scroll.position.maxScrollExtent);
    _scroll.animateTo(target, duration: GLDur.slow, curve: GLCurves.standard);
  }

  // ── tab ops ──
  void _reorder(int fromId, int toId) {
    if (fromId == toId) return;
    final from = _tabs.indexWhere((t) => t.id == fromId);
    final to = _tabs.indexWhere((t) => t.id == toId);
    if (from < 0 || to < 0) return;
    setState(() {
      final moved = _tabs.removeAt(from);
      _tabs.insert(to, moved);
    });
  }

  void _select(int id) => setState(() => _active = id);

  void _refocusAfterClose(int closedId, List<BrowserTab> next) {
    if (_active != closedId || next.isEmpty) return;
    final oi = _ordered.indexWhere((t) => t.id == closedId);
    final candidates = _ordered.where((t) => t.id != closedId && next.any((n) => n.id == t.id)).toList();
    if (candidates.isEmpty) {
      _active = next.first.id;
      return;
    }
    final idx = oi.clamp(0, candidates.length - 1);
    _active = candidates[idx].id;
  }

  void _close(int id) {
    setState(() {
      final next = _tabs.where((t) => t.id != id).toList();
      _refocusAfterClose(id, next);
      _tabs = next;
    });
  }

  Future<void> _requestClose(int id) async {
    final t = _tabs.firstWhere((x) => x.id == id);
    if (t.dirty) {
      final r = await showGLDirtyCloseDialog(context, t);
      if (r == 'discard') {
        _close(id);
      } else if (r == 'save') {
        setState(() => t.dirty = false);
        _close(id);
      }
    } else {
      _close(id);
    }
  }

  void _closeOthers(int id) {
    setState(() {
      _tabs = _tabs.where((t) => t.id == id || t.pinned).toList();
      _active = id;
    });
  }

  void _closeToRight(int id) {
    final oi = _ordered.indexWhere((t) => t.id == id);
    final killSet = _ordered.skip(oi + 1).where((t) => !t.pinned).map((t) => t.id).toSet();
    setState(() {
      _tabs = _tabs.where((t) => !killSet.contains(t.id)).toList();
      if (killSet.contains(_active)) _active = id;
    });
  }

  void _duplicate(int id) {
    final i = _tabs.indexWhere((t) => t.id == id);
    if (i < 0) return;
    final nid = ++_seed;
    final clone = _tabs[i].copyWith(id: nid, dirty: false, pinned: false);
    setState(() {
      _tabs.insert(i + 1, clone);
      _active = nid;
    });
  }

  void _togglePin(int id) {
    setState(() {
      final t = _tabs.firstWhere((x) => x.id == id);
      t.pinned = !t.pinned;
    });
  }

  void _add() {
    final id = ++_seed;
    setState(() {
      _tabs.add(BrowserTab(id: id, title: 'New Tab', kind: kNewTabCycle[id % kNewTabCycle.length]));
      _active = id;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  // ── keyboard ←/→/Home/End ──
  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    if (e.logicalKey == LogicalKeyboardKey.escape) {
      if (_menuEntry != null || _listEntry != null) {
        _hideMenu();
        _hideList();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    final keys = {
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.home,
      LogicalKeyboardKey.end,
    };
    if (!keys.contains(e.logicalKey)) return KeyEventResult.ignored;
    final ord = _ordered;
    final i = ord.indexWhere((t) => t.id == _active);
    var ni = i;
    if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
      ni = (i + 1).clamp(0, ord.length - 1);
    } else if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
      ni = (i - 1).clamp(0, ord.length - 1);
    } else if (e.logicalKey == LogicalKeyboardKey.home) {
      ni = 0;
    } else if (e.logicalKey == LogicalKeyboardKey.end) {
      ni = ord.length - 1;
    }
    if (ni >= 0 && ni < ord.length) _select(ord[ni].id);
    return KeyEventResult.handled;
  }

  // ════════ OVERLAYS ════════
  void _hideAllOverlays() {
    _hideMenu();
    _hideList();
    _hidePreview();
  }

  void _hideMenu() {
    _menuEntry?.remove();
    _menuEntry = null;
  }

  void _hideList() {
    _listEntry?.remove();
    _listEntry = null;
    if (mounted) setState(() {}); // refresh caret highlight
  }

  void _hidePreview() {
    _previewEntry?.remove();
    _previewEntry = null;
    _previewId = null;
  }

  // context menu (right-click / long-press)
  void _openMenu(Offset at, int id) {
    _hidePreview();
    _hideMenu();
    final t = _tabs.firstWhere((x) => x.id == id);
    final oi = _ordered.indexWhere((x) => x.id == id);
    final rightAllPinned = _ordered.skip(oi + 1).every((x) => x.pinned);
    final items = <TabMenuItem>[
      TabMenuItem(icon: Icons.close, label: 'Close tab', hint: 'Del', danger: true, run: () => _requestClose(id)),
      TabMenuItem(icon: Icons.clear_all, label: 'Close other tabs', disabled: _unpinned.length <= 1, run: () => _closeOthers(id)),
      TabMenuItem(icon: Icons.east, label: 'Close tabs to the right', disabled: rightAllPinned, run: () => _closeToRight(id)),
      const TabMenuItem.divider(),
      TabMenuItem(icon: Icons.content_copy_outlined, label: 'Duplicate tab', run: () => _duplicate(id)),
      TabMenuItem(icon: Icons.push_pin_outlined, label: t.pinned ? 'Unpin tab' : 'Pin tab', run: () => _togglePin(id)),
    ];
    _menuEntry = OverlayEntry(
      builder: (ctx) => _DismissLayer(
        onDismiss: _hideMenu,
        child: TabContextMenu(at: at, items: items, onClose: _hideMenu),
      ),
    );
    Overlay.of(context).insert(_menuEntry!);
  }

  // tab-list dropdown (▾)
  void _toggleList() {
    _hidePreview();
    if (_listEntry != null) {
      _hideList();
      return;
    }
    final box = _caretKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final origin = box.localToGlobal(Offset.zero);
    final anchor = origin & box.size;
    _listEntry = OverlayEntry(
      builder: (ctx) => _DismissLayer(
        onDismiss: _hideList,
        child: TabListDropdown(
          anchor: anchor,
          tabs: _ordered,
          activeId: _active,
          onPick: _select,
          onClose: _hideList,
        ),
      ),
    );
    Overlay.of(context).insert(_listEntry!);
    setState(() {}); // highlight caret
  }

  // hover mini-page preview
  void _requestPreview(int id, Rect anchor) {
    if (_dragId != null || _menuEntry != null || _listEntry != null) return;
    if (_previewId == id) return;
    _hidePreview();
    final tab = _tabs.firstWhere((t) => t.id == id);
    _previewId = id;
    _previewEntry = OverlayEntry(
      builder: (ctx) => MiniPagePreview(tab: tab, anchor: anchor),
    );
    Overlay.of(context).insert(_previewEntry!);
  }

  void _cancelPreview(int id) {
    if (_previewId == id) _hidePreview();
  }

  // ════════ BUILD ════════
  @override
  Widget build(BuildContext context) {
    final s = GLSurfaces.of(context);
    BrowserTab? activeTab;
    for (final t in _tabs) {
      if (t.id == _active) {
        activeTab = t;
        break;
      }
    }

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _onKey,
      child: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        child: Container(
          decoration: BoxDecoration(
            color: s.bg,
            border: Border.all(color: s.border),
            borderRadius: BorderRadius.circular(GLRadius.lg),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStrip(s),
              _buildContent(s, activeTab),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStrip(GLSurfaces s) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      color: s.bg,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // pinned region — anchored, does not scroll
          if (_pinned.isNotEmpty) ...[
            for (int i = 0; i < _pinned.length; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              _tabChip(_pinned[i], compact: true, first: i == 0),
            ],
            Container(
              width: 1,
              height: 24,
              margin: const EdgeInsets.only(left: 4, right: 4, top: 8),
              color: s.borderStrong,
            ),
          ],
          // start chevron
          _chevron(false, _chevStart, s),
          // scrolling region
          Expanded(
            child: SingleChildScrollView(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (int i = 0; i < _unpinned.length; i++) ...[
                    if (i > 0) const SizedBox(width: 2),
                    _draggableTab(_unpinned[i], i == 0 && _pinned.isEmpty),
                  ],
                ],
              ),
            ),
          ),
          // end chevron
          _chevron(true, _chevEnd, s),
          const SizedBox(width: 4),
          // new tab (+)
          _IconBtn(icon: Icons.add, tooltip: 'New tab', onTap: _add),
          const SizedBox(width: 2),
          // tab-list (▾)
          _IconBtn(
            key: _caretKey,
            icon: Icons.expand_more,
            tooltip: 'Show all tabs',
            active: _listOpen,
            onTap: _toggleList,
          ),
        ],
      ),
    );
  }

  Widget _draggableTab(BrowserTab tab, bool first) {
    final isOver = _overId == tab.id && _dragId != tab.id;
    final chip = _tabChip(tab, compact: false, first: first, isOver: isOver);
    return DragTarget<int>(
      onWillAcceptWithDetails: (d) => d.data != tab.id,
      onMove: (_) {
        if (_overId != tab.id) setState(() => _overId = tab.id);
      },
      onLeave: (_) {
        if (_overId == tab.id) setState(() => _overId = null);
      },
      onAcceptWithDetails: (d) {
        _reorder(d.data, tab.id);
        setState(() {
          _dragId = null;
          _overId = null;
        });
      },
      builder: (ctx, cand, rej) => Draggable<int>(
        data: tab.id,
        axis: Axis.horizontal,
        onDragStarted: () {
          _hidePreview();
          setState(() => _dragId = tab.id);
        },
        onDraggableCanceled: (_, __) => setState(() {
          _dragId = null;
          _overId = null;
        }),
        onDragEnd: (_) => setState(() {
          _dragId = null;
          _overId = null;
        }),
        feedback: _StaticTab(tab: tab, active: tab.id == _active, feedback: true),
        childWhenDragging: Opacity(opacity: 0.4, child: IgnorePointer(child: _StaticTab(tab: tab, active: tab.id == _active))),
        child: chip,
      ),
    );
  }

  Widget _tabChip(BrowserTab tab, {required bool compact, required bool first, bool isOver = false}) {
    return _TabChip(
      key: ValueKey('tab-${tab.id}'),
      tab: tab,
      active: tab.id == _active,
      compact: compact,
      first: first,
      isOver: isOver,
      onSelect: () {
        _hidePreview();
        _select(tab.id);
      },
      onClose: () => _requestClose(tab.id),
      onContextMenu: (offset) => _openMenu(offset, tab.id),
      onPreviewRequest: (rect) => _requestPreview(tab.id, rect),
      onPreviewCancel: () => _cancelPreview(tab.id),
    );
  }

  Widget _chevron(bool towardEnd, bool show, GLSurfaces s) {
    return AnimatedContainer(
      duration: GLDur.base,
      curve: GLCurves.standard,
      width: show ? 26 : 0,
      height: 32,
      margin: const EdgeInsets.only(bottom: 2),
      child: show
          ? _IconBtn(
              icon: towardEnd ? Icons.chevron_right : Icons.chevron_left,
              tooltip: towardEnd ? 'Scroll tabs forward' : 'Scroll tabs back',
              size: 26,
              onTap: () => _scrollByDir(towardEnd),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildContent(GLSurfaces s, BrowserTab? activeTab) {
    return Container(
      decoration: BoxDecoration(
        color: s.surface,
        border: Border(top: BorderSide(color: s.border)),
      ),
      child: activeTab == null
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Text('No open tabs — press + to start.',
                  style: TextStyle(fontFamily: GLFonts.body, fontSize: 13, color: s.fg3)),
            )
          : ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 440),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: GLTabPage(tab: activeTab),
              ),
            ),
    );
  }
}

// ── full-screen translucent barrier behind menus / dropdowns ──
class _DismissLayer extends StatelessWidget {
  final VoidCallback onDismiss;
  final Widget child;
  const _DismissLayer({required this.onDismiss, required this.child});
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onDismiss,
            onSecondaryTap: onDismiss,
          ),
        ),
        child,
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// TAB CHIP (active / inactive / hover / pressed + hover-intent preview)
// ════════════════════════════════════════════════════════════
class _TabChip extends StatefulWidget {
  final BrowserTab tab;
  final bool active, compact, first, isOver;
  final VoidCallback onSelect, onClose, onPreviewCancel;
  final ValueChanged<Offset> onContextMenu;
  final ValueChanged<Rect> onPreviewRequest;
  const _TabChip({
    super.key,
    required this.tab,
    required this.active,
    required this.compact,
    required this.first,
    required this.isOver,
    required this.onSelect,
    required this.onClose,
    required this.onContextMenu,
    required this.onPreviewRequest,
    required this.onPreviewCancel,
  });
  @override
  State<_TabChip> createState() => _TabChipState();
}

class _TabChipState extends State<_TabChip> {
  bool _hover = false;
  bool _closeHover = false;
  Timer? _previewTimer;

  void _armPreview() {
    _previewTimer?.cancel();
    _previewTimer = Timer(const Duration(milliseconds: 480), () {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null && box.attached) {
        final origin = box.localToGlobal(Offset.zero);
        widget.onPreviewRequest(origin & box.size);
      }
    });
  }

  void _dropPreview() {
    _previewTimer?.cancel();
    _previewTimer = null;
    widget.onPreviewCancel();
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = GLSurfaces.of(context);
    final tab = widget.tab;
    final active = widget.active;
    final bg = active ? s.surface : (_hover ? s.hover : Colors.transparent);
    final fg = active ? s.fg1 : s.fg3;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hover = true);
        _armPreview();
      },
      onExit: (_) {
        setState(() => _hover = false);
        _dropPreview();
      },
      child: GestureDetector(
        onTap: () {
          _dropPreview();
          widget.onSelect();
        },
        onSecondaryTapDown: (d) {
          _dropPreview();
          widget.onContextMenu(d.globalPosition);
        },
        onLongPressStart: (d) {
          _dropPreview();
          widget.onContextMenu(d.globalPosition);
        },
        child: AnimatedContainer(
          duration: GLDur.base,
          curve: GLCurves.standard,
          height: 36,
          width: widget.compact ? 40 : null,
          constraints: widget.compact ? null : const BoxConstraints(minWidth: 120, maxWidth: 200),
          padding: widget.compact ? EdgeInsets.zero : const EdgeInsetsDirectional.only(start: 12, end: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // drop-insertion indicator
              if (widget.isOver)
                PositionedDirectional(
                  start: -1,
                  top: 6,
                  bottom: 6,
                  child: Container(width: 2, decoration: BoxDecoration(color: GLColors.blue500, borderRadius: BorderRadius.circular(2))),
                ),
              // hairline separator before inactive (non-first) tabs
              if (!active && !widget.first && !widget.isOver)
                PositionedDirectional(
                  start: 0,
                  top: 9,
                  bottom: 9,
                  child: Container(width: 1, color: s.border),
                ),
              _content(s, tab, active, fg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(GLSurfaces s, BrowserTab tab, bool active, Color fg) {
    if (widget.compact) {
      return Stack(
        children: [
          Center(child: Icon(glTabIcon(tab.kind), size: 14, color: active ? GLColors.blue500 : s.fg3)),
          if (tab.dirty)
            PositionedDirectional(
              top: 7,
              end: 7,
              child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: GLColors.warning, shape: BoxShape.circle)),
            ),
        ],
      );
    }
    return Row(
      children: [
        Icon(glTabIcon(tab.kind), size: 14, color: active ? GLColors.blue500 : s.fg3),
        const SizedBox(width: 8),
        Expanded(
          child: Tooltip(
            message: tab.title,
            waitDuration: const Duration(milliseconds: 600),
            child: Text(
              tab.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: GLFonts.body,
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: fg,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        _trailing(s, tab, active),
      ],
    );
  }

  Widget _trailing(GLSurfaces s, BrowserTab tab, bool active) {
    if (tab.dirty && !_hover) {
      return Container(
        width: 8,
        height: 8,
        margin: const EdgeInsetsDirectional.only(end: 4),
        decoration: const BoxDecoration(color: GLColors.warning, shape: BoxShape.circle),
      );
    }
    final visible = _hover || active;
    return Opacity(
      opacity: visible ? 1 : 0,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _closeHover = true),
        onExit: (_) => setState(() => _closeHover = false),
        child: GestureDetector(
          onTap: visible
              ? () {
                  _dropPreview();
                  widget.onClose();
                }
              : null,
          child: Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _closeHover ? s.inputBg : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Icon(Icons.close, size: 12, color: _closeHover ? s.fg1 : s.fg3),
          ),
        ),
      ),
    );
  }
}

// ── static visual used for drag feedback / childWhenDragging ──
class _StaticTab extends StatelessWidget {
  final BrowserTab tab;
  final bool active;
  final bool feedback;
  const _StaticTab({required this.tab, required this.active, this.feedback = false});
  @override
  Widget build(BuildContext context) {
    final s = GLSurfaces.of(context);
    final chip = Container(
      height: 36,
      constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
      padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
      decoration: BoxDecoration(
        color: active ? s.surface : s.hover,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
        border: feedback ? Border.all(color: s.borderStrong) : null,
      ),
      child: Row(
        children: [
          Icon(glTabIcon(tab.kind), size: 14, color: active ? GLColors.blue500 : s.fg3),
          const SizedBox(width: 8),
          Flexible(
            child: Text(tab.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontFamily: GLFonts.body,
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: active ? s.fg1 : s.fg2)),
          ),
        ],
      ),
    );
    if (!feedback) return chip;
    return Material(color: Colors.transparent, child: Opacity(opacity: 0.9, child: chip));
  }
}

// ── flat icon button used for + / ▾ / chevrons ──
class _IconBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool active;
  final double size;
  final VoidCallback onTap;
  const _IconBtn({super.key, required this.icon, required this.tooltip, this.active = false, this.size = 32, required this.onTap});
  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final s = GLSurfaces.of(context);
    final on = widget.active || _hover;
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: widget.size,
            height: 32,
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              color: on ? s.hover : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(widget.icon, size: 16, color: on ? s.fg1 : s.fg3),
          ),
        ),
      ),
    );
  }
}
