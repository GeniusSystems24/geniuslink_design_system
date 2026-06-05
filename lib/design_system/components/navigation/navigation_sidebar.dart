// ============================================================
// NavigationSidebar — VIEW.
// ------------------------------------------------------------
// A thin, customisable render of NavigationSidebarController<T>. Paints the
// titled sections and their node tree in one of three modes:
//
//   • expanded — full-width labelled tree with │ ├ └ connectors, badges and
//                disclosure chevrons; the active leaf fills with the accent.
//   • rail     — icon-only column; hovering a module opens a grouped flyout.
//   • drawer   — off-canvas panel slid over the content with a scrim (place it
//                in a Stack via Positioned.fill; open via controller.drawerOpen).
//
// Every gesture is forwarded to the controller — this widget owns no nav state.
//
// Customisation surface:
//   • mode               — expanded · rail · drawer (host derives from width)
//   • header / footer     — slot builders (logo, theme toggle, help card …)
//   • showGuides          — the connector lines
//   • railFlyouts         — module hover flyouts in the rail
//   • onNavigate          — host hook fired alongside controller.navigate
//
//   File: lib/design_system/components/navigation/navigation_sidebar.dart
// ============================================================

import 'package:flutter/material.dart';
import 'navigation_sidebar_controller.dart';
import 'navigation_sidebar_models.dart';
import 'navigation_sidebar_theme.dart';

typedef NavSidebarSlotBuilder = Widget Function(BuildContext context, bool collapsed);

class NavigationSidebar<T> extends StatefulWidget {
  /// Initial sections. Required when [controller] is null.
  final List<NavSection<T>>? sections;

  /// Active id on first build (ignored when a [controller] is supplied).
  final NavNodeId? active;

  /// Ids expanded on first build (ignored when a [controller] is supplied).
  final Set<NavNodeId>? initiallyExpanded;

  /// Drive/observe from outside. When null the widget owns a private one.
  final NavigationSidebarController<T>? controller;

  /// How the sidebar is presented. Hosts typically derive this from the
  /// available width with [NavSidebarBreakpoints].
  final NavSidebarMode mode;

  // ── slots ──
  final NavSidebarSlotBuilder? header;
  final NavSidebarSlotBuilder? footer;

  /// Label shown above the drawer's close button (drawer mode).
  final String drawerTitle;

  // ── chrome toggles ──
  final bool showGuides;
  final bool railFlyouts;

  // ── callbacks ──
  final ValueChanged<NavNode<T>>? onNavigate;

  const NavigationSidebar({
    super.key,
    this.sections,
    this.active,
    this.initiallyExpanded,
    this.controller,
    this.mode = NavSidebarMode.expanded,
    this.header,
    this.footer,
    this.drawerTitle = 'Navigation',
    this.showGuides = true,
    this.railFlyouts = true,
    this.onNavigate,
  }) : assert(sections != null || controller != null, 'Provide sections or a controller.');

  @override
  State<NavigationSidebar<T>> createState() => _NavigationSidebarState<T>();
}

class _NavigationSidebarState<T> extends State<NavigationSidebar<T>> {
  late NavigationSidebarController<T> _controller;
  bool _ownsController = false;
  final ScrollController _scroll = ScrollController();

  NavigationSidebarThemeData get _t => NavigationSidebarThemeData.of(context);
  bool get _rtl => Directionality.of(context) == TextDirection.rtl;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        NavigationSidebarController<T>(
          sections: widget.sections!,
          active: widget.active,
          expanded: widget.initiallyExpanded,
          collapsed: widget.mode == NavSidebarMode.rail,
        );
    _ownsController = widget.controller == null;
    _controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(covariant NavigationSidebar<T> old) {
    super.didUpdateWidget(old);
    if (widget.controller != null && widget.controller != _controller) {
      _controller.removeListener(_onChanged);
      if (_ownsController) _controller.dispose();
      _controller = widget.controller!;
      _ownsController = false;
      _controller.addListener(_onChanged);
    }
    // Keep an owned controller's collapse flag in sync with the mode the host
    // picked (so an expanded→rail switch tracks the layout).
    if (_ownsController && widget.mode != old.mode && widget.mode != NavSidebarMode.drawer) {
      _controller.collapsed = widget.mode == NavSidebarMode.rail;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    if (_ownsController) _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _go(NavNode<T> n) {
    _controller.navigate(n.id);
    widget.onNavigate?.call(n);
  }

  bool get _railed => widget.mode == NavSidebarMode.rail || (widget.mode != NavSidebarMode.drawer && _controller.collapsed);

  @override
  Widget build(BuildContext context) {
    return NavigationSidebarScope<T>(
      controller: _controller,
      child: widget.mode == NavSidebarMode.drawer ? _buildDrawer(_t) : _buildInline(_t),
    );
  }

  // ── inline panel (expanded / rail) ─────────────────────────
  Widget _buildInline(NavigationSidebarThemeData t) {
    final railed = _railed;
    return AnimatedContainer(
      duration: NavigationSidebarThemeData.durBase,
      curve: NavigationSidebarThemeData.curveStandard,
      width: railed ? NavigationSidebarThemeData.widthRail : NavigationSidebarThemeData.widthExpanded,
      decoration: BoxDecoration(
        color: t.surface,
        border: BorderDirectional(end: BorderSide(color: t.border)),
      ),
      child: _panelContents(t, railed: railed, drawer: false),
    );
  }

  // ── drawer overlay (place in a Stack via Positioned.fill) ──
  Widget _buildDrawer(NavigationSidebarThemeData t) {
    final open = _controller.drawerOpen;
    final hidden = NavigationSidebarThemeData.widthDrawer + 8;
    return Stack(
      children: [
        // Scrim.
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !open,
            child: GestureDetector(
              onTap: _controller.closeDrawer,
              child: AnimatedOpacity(
                duration: NavigationSidebarThemeData.durDrawer,
                opacity: open ? 1 : 0,
                child: const ColoredBox(color: Color(0x8C08090C)),
              ),
            ),
          ),
        ),
        // Slide-in panel.
        AnimatedPositionedDirectional(
          duration: NavigationSidebarThemeData.durDrawer,
          curve: NavigationSidebarThemeData.curveStandard,
          top: 0,
          bottom: 0,
          start: open ? 0.0 : -hidden,
          width: NavigationSidebarThemeData.widthDrawer,
          child: Material(
            color: t.surface,
            elevation: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: t.surface,
                boxShadow: open ? NavigationSidebarThemeData.popShadow : null,
                border: BorderDirectional(end: BorderSide(color: t.border)),
              ),
              child: _panelContents(t, railed: false, drawer: true),
            ),
          ),
        ),
      ],
    );
  }

  Widget _panelContents(NavigationSidebarThemeData t, {required bool railed, required bool drawer}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (drawer) ...[
            _drawerHeader(t),
            const SizedBox(height: 2),
          ],
          if (widget.header != null) ...[
            widget.header!(context, railed),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: railed ? _railNav(t) : _expandedNav(t),
          ),
          if (widget.footer != null) ...[
            const SizedBox(height: 12),
            widget.footer!(context, railed),
          ],
        ],
      ),
    );
  }

  Widget _drawerHeader(NavigationSidebarThemeData t) {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          Text(
            widget.drawerTitle.toUpperCase(),
            style: TextStyle(
              fontFamily: NavigationSidebarThemeData.monoFont,
              fontSize: 10,
              letterSpacing: 1.4,
              color: t.fg4,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: _controller.closeDrawer,
            borderRadius: BorderRadius.circular(NavigationSidebarThemeData.radiusSm),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.close, size: 18, color: t.fg3),
            ),
          ),
        ],
      ),
    );
  }

  // ── expanded tree ──────────────────────────────────────────
  Widget _expandedNav(NavigationSidebarThemeData t) {
    return Scrollbar(
      controller: _scroll,
      child: SingleChildScrollView(
        controller: _scroll,
        primary: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final sec in _controller.sections) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: Text(
                  sec.title.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 1.4,
                    color: t.fg4,
                  ),
                ),
              ),
              for (final node in sec.items) _treeNode(t, node, 0),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }

  /// Recursive node: its own row, then (if a folder and open) its children
  /// wrapped in drawn connectors. Handles any depth.
  Widget _treeNode(NavigationSidebarThemeData t, NavNode<T> node, int depth) {
    final role = NavNodeRole.of(depth: depth, hasChildren: node.hasChildren);
    if (node.isLeaf) {
      return _NavRow<T>(
        key: ValueKey('row-${node.id}'),
        node: node,
        depth: depth,
        role: role,
        active: _controller.isActive(node.id),
        onTap: () => _go(node),
      );
    }

    final open = _controller.isExpanded(node.id);
    final ownsActive = _controller.ownsActive(node.id);
    final lx = NavigationSidebarThemeData.lineInset(depth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _NavRow<T>(
          key: ValueKey('row-${node.id}'),
          node: node,
          depth: depth,
          role: role,
          expandable: true,
          open: open,
          ownsActive: ownsActive,
          onTap: () => _controller.toggleNode(node.id),
        ),
        if (open)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < node.children.length; i++)
                _connectorWrap(
                  t,
                  child: _treeNode(t, node.children[i], depth + 1),
                  lx: lx,
                  childRole: NavNodeRole.of(
                    depth: depth + 1,
                    hasChildren: node.children[i].hasChildren,
                  ),
                  last: i == node.children.length - 1,
                ),
            ],
          ),
      ],
    );
  }

  /// Wraps a child subtree with the │ ├ └ guide lines for its header row.
  Widget _connectorWrap(
    NavigationSidebarThemeData t, {
    required Widget child,
    required double lx,
    required NavNodeRole childRole,
    required bool last,
  }) {
    if (!widget.showGuides) return child;
    final childH = _roleHeight(childRole);
    return Stack(
      children: [
        // vertical: top → child header centre
        PositionedDirectional(
          start: lx,
          top: 0,
          height: childH / 2,
          width: 1.5,
          child: ColoredBox(color: t.guide),
        ),
        // vertical: header centre → bottom (chains to the next sibling)
        if (!last)
          PositionedDirectional(
            start: lx,
            top: childH / 2,
            bottom: 0,
            width: 1.5,
            child: ColoredBox(color: t.guide),
          ),
        // elbow stub into the node
        PositionedDirectional(
          start: lx,
          top: childH / 2 - 0.75,
          width: NavigationSidebarThemeData.elbow,
          height: 1.5,
          child: ColoredBox(color: t.guide),
        ),
        child,
      ],
    );
  }

  static double _roleHeight(NavNodeRole r) {
    switch (r) {
      case NavNodeRole.direct:
        return NavigationSidebarThemeData.directHeight;
      case NavNodeRole.module:
        return NavigationSidebarThemeData.moduleHeight;
      case NavNodeRole.group:
        return NavigationSidebarThemeData.groupHeight;
      case NavNodeRole.item:
        return NavigationSidebarThemeData.itemHeight;
    }
  }

  // ── collapsed rail (icon column + hover flyouts) ───────────
  Widget _railNav(NavigationSidebarThemeData t) {
    return Scrollbar(
      controller: _scroll,
      child: SingleChildScrollView(
        controller: _scroll,
        primary: false,
        child: Column(
          children: [
            for (var si = 0; si < _controller.sections.length; si++) ...[
              if (si > 0)
                Container(
                  width: 26,
                  height: 1,
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  color: t.border,
                ),
              for (final node in _controller.sections[si].items)
                _RailItem<T>(
                  key: ValueKey('rail-${node.id}'),
                  node: node,
                  active: node.hasChildren ? _controller.ownsActive(node.id) : _controller.isActive(node.id),
                  flyouts: widget.railFlyouts,
                  rtl: _rtl,
                  onNavigate: _go,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// ROW  — one expanded-tree line, styled by role.
// ════════════════════════════════════════════════════════════
class _NavRow<T> extends StatefulWidget {
  final NavNode<T> node;
  final int depth;
  final NavNodeRole role;
  final bool expandable;
  final bool open;
  final bool active;
  final bool ownsActive;
  final VoidCallback onTap;

  const _NavRow({
    super.key,
    required this.node,
    required this.depth,
    required this.role,
    this.expandable = false,
    this.open = false,
    this.active = false,
    this.ownsActive = false,
    required this.onTap,
  });

  @override
  State<_NavRow<T>> createState() => _NavRowState<T>();
}

class _NavRowState<T> extends State<_NavRow<T>> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    final pad = NavigationSidebarThemeData.contentInset(widget.depth);
    final h = _NavigationSidebarState._roleHeight(widget.role);

    Widget content;
    switch (widget.role) {
      case NavNodeRole.direct:
      case NavNodeRole.module:
        content = _moduleOrDirect(t);
        break;
      case NavNodeRole.group:
        content = _group(t);
        break;
      case NavNodeRole.item:
        content = _item(t);
        break;
    }

    final radius = widget.role == NavNodeRole.direct || widget.role == NavNodeRole.module
        ? NavigationSidebarThemeData.radiusLg
        : NavigationSidebarThemeData.radiusMd;

    Color bg = Colors.transparent;
    if (widget.role == NavNodeRole.direct && widget.active) {
      bg = NavigationSidebarThemeData.accent;
    } else if (widget.role == NavNodeRole.item && widget.active) {
      bg = t.accentFill(0.10);
    } else if (_hover) {
      bg = t.hover;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.node.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: NavigationSidebarThemeData.durFast,
          height: h,
          padding: EdgeInsetsDirectional.only(start: pad, end: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: content,
        ),
      ),
    );
  }

  Widget _chevron(NavigationSidebarThemeData t) {
    return AnimatedRotation(
      turns: widget.open ? 0.5 : 0,
      duration: NavigationSidebarThemeData.durBase,
      curve: NavigationSidebarThemeData.curveStandard,
      child: Icon(Icons.keyboard_arrow_down, size: 16, color: t.fg3),
    );
  }

  Widget _moduleOrDirect(NavigationSidebarThemeData t) {
    final isDirect = widget.role == NavNodeRole.direct;
    final Color tint = isDirect
        ? (widget.active ? Colors.white : t.fg2)
        : (widget.ownsActive ? NavigationSidebarThemeData.accent : t.fg2);
    final bold = widget.active || widget.ownsActive;
    final moduleDot = !isDirect && !widget.open && NavOps.subtreeHasBadge(widget.node);

    return Row(
      children: [
        Icon(widget.node.icon ?? Icons.circle_outlined, size: NavigationSidebarThemeData.iconTop, color: tint),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.node.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: NavigationSidebarThemeData.bodyFont,
              fontSize: 13.5,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
              color: tint,
            ),
          ),
        ),
        if (widget.node.badge != null) ...[const SizedBox(width: 6), _NavBadgeChip(badge: widget.node.badge!)],
        if (widget.node.shortcut != null && _hover && !widget.active) ...[
          const SizedBox(width: 6),
          _ShortcutHint(keys: widget.node.shortcut!),
        ],
        if (moduleDot) ...[
          const SizedBox(width: 6),
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: NavigationSidebarThemeData.accent, shape: BoxShape.circle)),
        ],
        if (widget.expandable) ...[const SizedBox(width: 4), _chevron(t)],
      ],
    );
  }

  Widget _group(NavigationSidebarThemeData t) {
    final tint = widget.ownsActive ? NavigationSidebarThemeData.accent : t.fg3;
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: widget.ownsActive ? NavigationSidebarThemeData.accent : t.fg4,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            widget.node.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: NavigationSidebarThemeData.bodyFont,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: tint,
            ),
          ),
        ),
        if (widget.expandable) _chevron(t),
      ],
    );
  }

  Widget _item(NavigationSidebarThemeData t) {
    final active = widget.active;
    return Row(
      children: [
        Container(
          width: NavigationSidebarThemeData.itemBox,
          height: NavigationSidebarThemeData.itemBox,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(NavigationSidebarThemeData.radiusMd),
            border: Border.all(color: active ? NavigationSidebarThemeData.accent : t.border),
            color: active ? t.accentFill(0.12) : t.surface,
          ),
          child: Icon(
            widget.node.icon ?? Icons.circle,
            size: NavigationSidebarThemeData.iconItem,
            color: active ? NavigationSidebarThemeData.accent : t.fg3,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            widget.node.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: NavigationSidebarThemeData.bodyFont,
              fontSize: 12.5,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              color: active ? NavigationSidebarThemeData.accent : t.fg2,
            ),
          ),
        ),
        if (widget.node.badge != null) ...[const SizedBox(width: 6), _NavBadgeChip(badge: widget.node.badge!, small: true)],
        if (widget.node.shortcut != null && _hover && !active) ...[
          const SizedBox(width: 6),
          _ShortcutHint(keys: widget.node.shortcut!),
        ],
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// RAIL ITEM — a 44×44 icon button with an optional hover flyout.
// ════════════════════════════════════════════════════════════
class _RailItem<T> extends StatefulWidget {
  final NavNode<T> node;
  final bool active;
  final bool flyouts;
  final bool rtl;
  final ValueChanged<NavNode<T>> onNavigate;

  const _RailItem({
    super.key,
    required this.node,
    required this.active,
    required this.flyouts,
    required this.rtl,
    required this.onNavigate,
  });

  @override
  State<_RailItem<T>> createState() => _RailItemState<T>();
}

class _RailItemState<T> extends State<_RailItem<T>> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;
  bool _hover = false;
  bool _overFlyout = false;

  @override
  void dispose() {
    _removeFlyout();
    super.dispose();
  }

  void _scheduleClose() {
    Future<void>.delayed(const Duration(milliseconds: 130), () {
      if (mounted && !_hover && !_overFlyout) _removeFlyout();
    });
  }

  void _removeFlyout() {
    _entry?.remove();
    _entry = null;
  }

  void _showFlyout() {
    if (!widget.flyouts || !widget.node.hasChildren || _entry != null) return;
    final t = NavigationSidebarThemeData.of(context);
    const flyW = 248.0;
    _entry = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          width: flyW,
          child: CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            targetAnchor: widget.rtl ? Alignment.topLeft : Alignment.topRight,
            followerAnchor: widget.rtl ? Alignment.topRight : Alignment.topLeft,
            offset: Offset(widget.rtl ? -10.0 : 10.0, -4),
            child: MouseRegion(
              onEnter: (_) => _overFlyout = true,
              onExit: (_) {
                _overFlyout = false;
                _scheduleClose();
              },
              child: Directionality(
                textDirection: widget.rtl ? TextDirection.rtl : TextDirection.ltr,
                child: _RailFlyout<T>(node: widget.node, theme: t, onNavigate: (n) {
                  widget.onNavigate(n);
                  _removeFlyout();
                }),
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(_entry!);
  }

  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    final isModule = widget.node.hasChildren;
    final hasBadge = NavOps.subtreeHasBadge(widget.node);

    Color bg = Colors.transparent;
    Color fg = t.fg2;
    if (widget.active) {
      if (isModule) {
        bg = t.accentFill(0.12);
        fg = NavigationSidebarThemeData.accent;
      } else {
        bg = NavigationSidebarThemeData.accent;
        fg = Colors.white;
      }
    } else if (_hover) {
      bg = t.hover;
    }

    final badgeColor = widget.node.badge != null
        ? t.badgeColors(widget.node.badge!.tone).fg
        : NavigationSidebarThemeData.accent;

    return CompositedTransformTarget(
      link: _link,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          setState(() => _hover = true);
          _showFlyout();
        },
        onExit: (_) {
          setState(() => _hover = false);
          _scheduleClose();
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (!isModule) widget.onNavigate(widget.node);
          },
          child: Tooltip(
            message: isModule ? '' : widget.node.label,
            child: Container(
              width: NavigationSidebarThemeData.railButton,
              height: NavigationSidebarThemeData.railButton,
              margin: const EdgeInsets.symmetric(vertical: 2.5),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(NavigationSidebarThemeData.radiusLg),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(widget.node.icon ?? Icons.circle_outlined, size: 22, color: fg),
                  if (hasBadge)
                    PositionedDirectional(
                      end: 6,
                      top: 6,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: badgeColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: t.surface, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RailFlyout<T> extends StatelessWidget {
  final NavNode<T> node;
  final NavigationSidebarThemeData theme;
  final ValueChanged<NavNode<T>> onNavigate;
  const _RailFlyout({required this.node, required this.theme, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 360),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(NavigationSidebarThemeData.radiusXl),
          border: Border.all(color: t.borderStrong),
          boxShadow: NavigationSidebarThemeData.popShadow,
        ),
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
                child: Row(
                  children: [
                    Icon(node.icon ?? Icons.circle_outlined, size: 17, color: t.fg2),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        node.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.fg1, fontFamily: NavigationSidebarThemeData.bodyFont),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: t.border),
              const SizedBox(height: 4),
              for (final group in node.children) _flyoutGroup(t, group),
            ],
          ),
        ),
      ),
    );
  }

  Widget _flyoutGroup(NavigationSidebarThemeData t, NavNode<T> group) {
    final leaves = group.hasChildren ? group.children : [group];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (group.hasChildren)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 3),
            child: Text(
              group.label.toUpperCase(),
              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: t.fg4),
            ),
          ),
        for (final leaf in leaves) _flyoutRow(t, leaf),
      ],
    );
  }

  Widget _flyoutRow(NavigationSidebarThemeData t, NavNode<T> leaf) {
    return _FlyoutRow<T>(leaf: leaf, theme: t, onTap: () => onNavigate(leaf));
  }
}

class _FlyoutRow<T> extends StatefulWidget {
  final NavNode<T> leaf;
  final NavigationSidebarThemeData theme;
  final VoidCallback onTap;
  const _FlyoutRow({required this.leaf, required this.theme, required this.onTap});

  @override
  State<_FlyoutRow<T>> createState() => _FlyoutRowState<T>();
}

class _FlyoutRowState<T> extends State<_FlyoutRow<T>> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: _hover ? t.hover : Colors.transparent,
            borderRadius: BorderRadius.circular(NavigationSidebarThemeData.radiusMd),
          ),
          child: Row(
            children: [
              Icon(widget.leaf.icon ?? Icons.circle, size: 15, color: t.fg3),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.leaf.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: t.fg1, fontFamily: NavigationSidebarThemeData.bodyFont),
                ),
              ),
              if (widget.leaf.badge != null) _NavBadgeChip(badge: widget.leaf.badge!, small: true),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// SHARED LEAF WIDGETS
// ════════════════════════════════════════════════════════════
class _NavBadgeChip extends StatelessWidget {
  final NavBadge badge;
  final bool small;
  const _NavBadgeChip({required this.badge, this.small = false});

  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    final c = t.badgeColors(badge.tone);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 5 : 6, vertical: small ? 2 : 3),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.border),
      ),
      child: Text(
        badge.text,
        style: TextStyle(
          fontFamily: NavigationSidebarThemeData.monoFont,
          fontSize: small ? 9 : 9.5,
          fontWeight: FontWeight.w700,
          height: 1.1,
          color: c.fg,
        ),
      ),
    );
  }
}

class _ShortcutHint extends StatelessWidget {
  final List<String> keys;
  const _ShortcutHint({required this.keys});

  @override
  Widget build(BuildContext context) {
    final t = NavigationSidebarThemeData.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final k in keys)
          Container(
            margin: const EdgeInsetsDirectional.only(start: 3),
            constraints: const BoxConstraints(minWidth: 16),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: t.inputBg,
              borderRadius: BorderRadius.circular(NavigationSidebarThemeData.radiusSm),
              border: Border.all(color: t.border),
            ),
            child: Text(
              k.toUpperCase(),
              style: TextStyle(
                fontFamily: NavigationSidebarThemeData.monoFont,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: t.fg3,
              ),
            ),
          ),
      ],
    );
  }
}
