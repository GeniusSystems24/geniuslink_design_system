// ============================================================
// BrowserStyleTabBar — modern browser-style tab strip (full).
// ------------------------------------------------------------
// Faithful Flutter port of design_system/BrowserTabs.jsx.
//
// State lives in a [BrowserStyleTabBarController] (ChangeNotifier). Pass one
// in to drive it from outside / read it from pages via
// `BrowserStyleTabBarController.of(context)`, or omit it and the widget owns
// a private controller (seeded from [tabsState]).
//
// Features: active/inactive/hover/pressed · closable · add (+) · select ·
// overflow scroll + chevrons · pinned tabs (icon-only, anchored) ·
// right-click context menu (close / close others / close to the right /
// duplicate / pin·unpin) · unsaved (dirty) indicator · dirty-close confirm
// dialog · tab-list dropdown · LIVE mini-page preview (a real captured frame
// of the page with its current state/data) · long-title truncation +
// tooltip · drag-to-reorder · keyboard (←/→/Home/End) · dark/light · RTL.
//   File: lib/design_system/components/navigation/browser_style_tab_bar.dart
// ============================================================

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'browser_style_tab_bar_theme.dart';
import 'browser_style_tab_bar_controller.dart';
import 'tab_models.dart';
import 'tab_pages.dart';
import 'tab_overlays.dart';

class BrowserStyleTabBar extends StatefulWidget {
  /// Seed state used only when [controller] is null. Defaults to the JSX set.
  final List<BrowserTab>? tabsState;

  /// External state. When provided the widget does NOT own/dispose it, and
  /// the same instance is what pages see via `BrowserStyleTabBarController.of`.
  final BrowserStyleTabBarController? controller;

  /// Optional custom content for each tab (active surface + hover preview).
  /// Falls back to the built-in [GLTabPage] when null.
  final TabPageBuilder? pageBuilder;

  // ── shell / embedding options (all default to the standalone card look) ──

  /// Draw the outer bordered, rounded card around the strip + content. Set
  /// false to embed the bar edge-to-edge inside a larger app shell.
  final bool showChrome;

  /// Let the content surface fill all available height (wrapped in an
  /// [Expanded]) instead of the default `maxHeight: 440` cap. Use for a
  /// full-window workspace where each tab hosts a full screen.
  final bool fillContent;

  /// Padding around the active page inside the content surface.
  final EdgeInsets contentPadding;

  /// Wrap the active page in a vertical [SingleChildScrollView]. Set false
  /// when the hosted page manages its own scrolling.
  final bool scrollContent;

  /// Background of the content surface (defaults to the theme `surface`).
  final Color? contentBackground;

  /// Intercept the New-tab (+) button. When provided it is called instead of
  /// the controller's built-in `add()` (e.g. to open a real screen).
  final VoidCallback? onAddTab;

  const BrowserStyleTabBar({
    super.key,
    this.tabsState,
    this.controller,
    this.pageBuilder,
    this.showChrome = true,
    this.fillContent = false,
    this.contentPadding = const EdgeInsets.all(24),
    this.scrollContent = true,
    this.contentBackground,
    this.onAddTab,
  });

  @override
  State<BrowserStyleTabBar> createState() => _BrowserStyleTabBarState();
}

class _BrowserStyleTabBarState extends State<BrowserStyleTabBar> {
  late BrowserStyleTabBarController _ctrl;
  bool _ownsCtrl = false;

  int? _dragId;
  int? _overId;

  bool _chevStart = false;
  bool _chevEnd = false;

  final _scroll = ScrollController();
  final _caretKey = GlobalKey();
  final _focusNode = FocusNode();
  final _boundaryKey = GlobalKey(); // wraps the active page → captured to image
  Timer? _captureTimer;

  // overlay handles
  OverlayEntry? _menuEntry;
  OverlayEntry? _listEntry;
  OverlayEntry? _previewEntry;
  int? _previewId;
  bool get _listOpen => _listEntry != null;

  @override
  void initState() {
    super.initState();
    _ctrl = widget.controller ??
        BrowserStyleTabBarController(tabs: widget.tabsState);
    _ownsCtrl = widget.controller == null;
    _ctrl.addListener(_onCtrl);
    _scroll.addListener(_measure);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measure();
      _scheduleCapture(); // first frame of the initial active page
    });
  }

  @override
  void didUpdateWidget(covariant BrowserStyleTabBar old) {
    super.didUpdateWidget(old);
    if (widget.controller != old.controller) {
      _ctrl.removeListener(_onCtrl);
      if (_ownsCtrl) _ctrl.dispose();
      _ctrl = widget.controller ??
          BrowserStyleTabBarController(tabs: widget.tabsState);
      _ownsCtrl = widget.controller == null;
      _ctrl.addListener(_onCtrl);
    }
  }

  void _onCtrl() {
    if (mounted) setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    _scheduleCapture(); // active tab changed / page edited → refresh its frame
  }

  @override
  void dispose() {
    _captureTimer?.cancel();
    _hideAllOverlays();
    _ctrl.removeListener(_onCtrl);
    if (_ownsCtrl) _ctrl.dispose();
    _scroll.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── live thumbnail capture ──
  // Captures the REAL rendered frame of the active page. Event-driven
  // (debounced) so each visited tab keeps a fresh thumbnail without polling.
  void _scheduleCapture() {
    _captureTimer?.cancel();
    _captureTimer = Timer(const Duration(milliseconds: 260), _captureActive);
  }

  Future<void> _captureActive() async {
    final id = _ctrl.activeId;
    if (id == null || !mounted) return;
    final ro = _boundaryKey.currentContext?.findRenderObject();
    if (ro is! RenderRepaintBoundary) return;
    if (ro.debugNeedsPaint) {
      _scheduleCapture(); // not painted yet — try again shortly
      return;
    }
    try {
      final img = await ro.toImage(pixelRatio: 0.6);
      if (!mounted) {
        img.dispose();
        return;
      }
      _ctrl.setSnapshot(id, img);
      if (_previewId == id)
        _previewEntry?.markNeedsBuild(); // refresh open preview
    } catch (_) {/* boundary not ready; ignore */}
  }

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
    final target = (_scroll.offset + 220 * (towardEnd ? 1 : -1))
        .clamp(0.0, _scroll.position.maxScrollExtent);
    _scroll.animateTo(target,
        duration: BrowserStyleTabBarThemeData.durSlow,
        curve: BrowserStyleTabBarThemeData.curveStandard);
  }

  // ── close (with dirty guard) ──
  Future<void> _requestClose(int id) async {
    final t = _ctrl.tabById(id);
    if (t == null) return;
    if (t.dirty) {
      final r = await showGLDirtyCloseDialog(context, t);
      if (r == 'discard') {
        _ctrl.close(id);
      } else if (r == 'save') {
        _ctrl.setDirty(id, false);
        _ctrl.close(id);
      }
    } else {
      _ctrl.close(id);
    }
  }

  void _add() {
    if (widget.onAddTab != null) {
      widget.onAddTab!();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients)
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });
      return;
    }
    _ctrl.add();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
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
    final ord = _ctrl.ordered;
    if (ord.isEmpty) return KeyEventResult.handled;
    final i = ord.indexWhere((t) => t.id == _ctrl.activeId);
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
    if (ni >= 0 && ni < ord.length) _ctrl.select(ord[ni].id);
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
    if (mounted) setState(() {});
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
    final t = _ctrl.tabById(id);
    if (t == null) return;
    final items = <TabMenuItem>[
      TabMenuItem(
          icon: Icons.close,
          label: 'Close tab',
          hint: 'Del',
          danger: true,
          run: () => _requestClose(id)),
      TabMenuItem(
          icon: Icons.clear_all,
          label: 'Close other tabs',
          disabled: !_ctrl.canCloseOthers(id),
          run: () => _ctrl.closeOthers(id)),
      TabMenuItem(
          icon: Icons.east,
          label: 'Close tabs to the right',
          disabled: !_ctrl.canCloseRight(id),
          run: () => _ctrl.closeToRight(id)),
      const TabMenuItem.divider(),
      TabMenuItem(
          icon: Icons.content_copy_outlined,
          label: 'Duplicate tab',
          run: () => _ctrl.duplicate(id)),
      TabMenuItem(
          icon: Icons.push_pin_outlined,
          label: t.pinned ? 'Unpin tab' : 'Pin tab',
          run: () => _ctrl.togglePin(id)),
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
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    _listEntry = OverlayEntry(
      builder: (ctx) => _DismissLayer(
        onDismiss: _hideList,
        child: TabListDropdown(
          anchor: anchor,
          tabs: _ctrl.ordered,
          activeId: _ctrl.activeId ?? -1,
          onPick: _ctrl.select,
          onClose: _hideList,
        ),
      ),
    );
    Overlay.of(context).insert(_listEntry!);
    setState(() {});
  }

  // hover LIVE mini-page preview
  void _requestPreview(int id, Rect anchor) {
    if (_dragId != null || _menuEntry != null || _listEntry != null) return;
    if (_previewId == id) return;
    _hidePreview();
    final tab = _ctrl.tabById(id);
    if (tab == null) return;
    _previewId = id;
    // Active tab → grab a fresh frame right now so the preview is exact.
    if (id == _ctrl.activeId) _captureActive();
    _previewEntry = OverlayEntry(
      // Reads the latest snapshot each build; markNeedsBuild() refreshes it
      // when a fresh frame lands.
      builder: (ctx) => MiniPagePreview(
        tab: _ctrl.tabById(id) ?? tab,
        anchor: anchor,
        snapshot: _ctrl.snapshot(id),
        pageBuilder: widget.pageBuilder,
        scope: _scopeFor,
      ),
    );
    Overlay.of(context).insert(_previewEntry!);
  }

  void _cancelPreview(int id) {
    if (_previewId == id) _hidePreview();
  }

  /// Wraps [child] so a page built inside the overlay can still reach the
  /// controller via `BrowserStyleTabBarController.of(context)`.
  Widget _scopeFor(Widget child) =>
      BrowserStyleTabBarScope(controller: _ctrl, child: child);

  // ════════ BUILD ════════
  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    final activeTab = _ctrl.activeTab;

    final content = _buildContent(s, activeTab);
    return BrowserStyleTabBarScope(
      controller: _ctrl,
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: _onKey,
        child: GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          child: Container(
            decoration: widget.showChrome
                ? BoxDecoration(
                    color: s.bg,
                    border: Border.all(color: s.border),
                    borderRadius: BorderRadius.circular(
                        BrowserStyleTabBarThemeData.radiusLg),
                  )
                : BoxDecoration(color: s.bg),
            clipBehavior: widget.showChrome ? Clip.antiAlias : Clip.none,
            child: Column(
              mainAxisSize:
                  widget.fillContent ? MainAxisSize.max : MainAxisSize.min,
              children: [
                _buildStrip(s),
                if (widget.fillContent) Expanded(child: content) else content,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStrip(BrowserStyleTabBarThemeData s) {
    final pinned = _ctrl.pinned;
    final unpinned = _ctrl.unpinned;
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      color: s.bg,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // pinned region — anchored, does not scroll
          if (pinned.isNotEmpty) ...[
            for (int i = 0; i < pinned.length; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              _tabChip(pinned[i], compact: true, first: i == 0),
            ],
            Container(
              width: 1,
              height: 24,
              margin: const EdgeInsets.only(left: 4, right: 4, top: 8),
              color: s.borderStrong,
            ),
          ],
          _chevron(false, _chevStart, s),
          // scrolling region
          Expanded(
            child: SingleChildScrollView(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (int i = 0; i < unpinned.length; i++) ...[
                    if (i > 0) const SizedBox(width: 2),
                    _draggableTab(unpinned[i], i == 0 && pinned.isEmpty),
                  ],
                ],
              ),
            ),
          ),
          _chevron(true, _chevEnd, s),
          const SizedBox(width: 4),
          _IconBtn(icon: Icons.add, tooltip: 'New tab', onTap: _add),
          const SizedBox(width: 2),
          _IconBtn(
              key: _caretKey,
              icon: Icons.expand_more,
              tooltip: 'Show all tabs',
              active: _listOpen,
              onTap: _toggleList),
        ],
      ),
    );
  }

  Widget _draggableTab(BrowserTab tab, bool first) {
    final active = _ctrl.isActive(tab.id);
    final isOver = _overId == tab.id && _dragId != tab.id;
    return DragTarget<int>(
      onWillAcceptWithDetails: (d) => d.data != tab.id,
      onMove: (_) {
        if (_overId != tab.id) setState(() => _overId = tab.id);
      },
      onLeave: (_) {
        if (_overId == tab.id) setState(() => _overId = null);
      },
      onAcceptWithDetails: (d) {
        _ctrl.reorder(d.data, tab.id);
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
        feedback: _StaticTab(tab: tab, active: active, feedback: true),
        childWhenDragging: Opacity(
            opacity: 0.4,
            child: IgnorePointer(child: _StaticTab(tab: tab, active: active))),
        child: _tabChip(tab, compact: false, first: first, isOver: isOver),
      ),
    );
  }

  Widget _tabChip(BrowserTab tab,
      {required bool compact, required bool first, bool isOver = false}) {
    return _TabChip(
      key: ValueKey('tab-${tab.id}'),
      tab: tab,
      active: _ctrl.isActive(tab.id),
      compact: compact,
      first: first,
      isOver: isOver,
      onSelect: () {
        _hidePreview();
        _ctrl.select(tab.id);
      },
      onClose: () => _requestClose(tab.id),
      onContextMenu: (offset) => _openMenu(offset, tab.id),
      onPreviewRequest: (rect) => _requestPreview(tab.id, rect),
      onPreviewCancel: () => _cancelPreview(tab.id),
    );
  }

  Widget _chevron(bool towardEnd, bool show, BrowserStyleTabBarThemeData s) {
    return AnimatedContainer(
      duration: BrowserStyleTabBarThemeData.durBase,
      curve: BrowserStyleTabBarThemeData.curveStandard,
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

  Widget _buildContent(BrowserStyleTabBarThemeData s, BrowserTab? activeTab) {
    final bg = widget.contentBackground ?? s.surface;
    final decoration = BoxDecoration(
      color: bg,
      border: Border(top: BorderSide(color: s.border)),
    );
    if (activeTab == null) {
      return Container(
        decoration: decoration,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Text('No open tabs — press + to start.',
              style: TextStyle(
                  fontFamily: BrowserStyleTabBarThemeData.bodyFont,
                  fontSize: 13,
                  color: s.fg3)),
        ),
      );
    }

    // KeyedSubtree keeps each tab's page state distinct across switches.
    final page = KeyedSubtree(
      key: ValueKey('tabpage-content-${activeTab.id}'),
      child: widget.pageBuilder?.call(context, activeTab) ??
          GLTabPage(tab: activeTab),
    );

    final Widget body = widget.scrollContent
        ? SingleChildScrollView(
            key: PageStorageKey('tabpage-${activeTab.id}'),
            padding: widget.contentPadding,
            child: page,
          )
        : Padding(padding: widget.contentPadding, child: page);

    // RepaintBoundary lets us capture the REAL rendered page (with its live
    // state/data) into the hover thumbnail.
    final boundaryChild = widget.fillContent
        ? SizedBox.expand(child: body)
        : ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 440), child: body);

    return Container(
      decoration: decoration,
      child: RepaintBoundary(key: _boundaryKey, child: boundaryChild),
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
        widget.onPreviewRequest(box.localToGlobal(Offset.zero) & box.size);
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
    final s = BrowserStyleTabBarThemeData.of(context);
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
          duration: BrowserStyleTabBarThemeData.durBase,
          curve: BrowserStyleTabBarThemeData.curveStandard,
          height: 36,
          width: widget.compact ? 40 : null,
          constraints: widget.compact
              ? null
              : const BoxConstraints(minWidth: 120, maxWidth: 200),
          padding: widget.compact
              ? EdgeInsets.zero
              : const EdgeInsetsDirectional.only(start: 12, end: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (widget.isOver)
                PositionedDirectional(
                  start: -1,
                  top: 6,
                  bottom: 6,
                  child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                          color: BrowserStyleTabBarThemeData.accent,
                          borderRadius: BorderRadius.circular(2))),
                ),
              if (!active && !widget.first && !widget.isOver)
                PositionedDirectional(
                    start: 0,
                    top: 9,
                    bottom: 9,
                    child: Container(width: 1, color: s.border)),
              _content(s, tab, active, fg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(
      BrowserStyleTabBarThemeData s, BrowserTab tab, bool active, Color fg) {
    if (widget.compact) {
      return Stack(
        children: [
          Center(
              child: Icon(glTabIcon(tab.kind),
                  size: 14,
                  color: active ? BrowserStyleTabBarThemeData.accent : s.fg3)),
          if (tab.dirty)
            PositionedDirectional(
              top: 7,
              end: 7,
              child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: BrowserStyleTabBarThemeData.warning,
                      shape: BoxShape.circle)),
            ),
        ],
      );
    }
    return Row(
      children: [
        Icon(glTabIcon(tab.kind),
            size: 14,
            color: active ? BrowserStyleTabBarThemeData.accent : s.fg3),
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
                fontFamily: BrowserStyleTabBarThemeData.bodyFont,
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

  Widget _trailing(BrowserStyleTabBarThemeData s, BrowserTab tab, bool active) {
    if (tab.dirty && !_hover) {
      return Container(
        width: 8,
        height: 8,
        margin: const EdgeInsetsDirectional.only(end: 4),
        decoration: const BoxDecoration(
            color: BrowserStyleTabBarThemeData.warning, shape: BoxShape.circle),
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
            child:
                Icon(Icons.close, size: 12, color: _closeHover ? s.fg1 : s.fg3),
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
  const _StaticTab(
      {required this.tab, required this.active, this.feedback = false});
  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
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
          Icon(glTabIcon(tab.kind),
              size: 14,
              color: active ? BrowserStyleTabBarThemeData.accent : s.fg3),
          const SizedBox(width: 8),
          Flexible(
            child: Text(tab.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontFamily: BrowserStyleTabBarThemeData.bodyFont,
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: active ? s.fg1 : s.fg2)),
          ),
        ],
      ),
    );
    if (!feedback) return chip;
    return Material(
        color: Colors.transparent, child: Opacity(opacity: 0.9, child: chip));
  }
}

// ── flat icon button used for + / ▾ / chevrons ──
class _IconBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool active;
  final double size;
  final VoidCallback onTap;
  const _IconBtn(
      {super.key,
      required this.icon,
      required this.tooltip,
      this.active = false,
      this.size = 32,
      required this.onTap});
  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
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
