// ============================================================
// AutoSuggestionsBox — VIEW.
// ------------------------------------------------------------
// A text field with an anchored suggestions overlay. Type to filter, ↑ ↓ to
// move through matches, Enter / tap to pick, Esc to dismiss; when free-text is
// allowed an unmatched value commits as-is on Enter. The matched substring of
// each row is highlighted (see [AutoSuggestionsHighlight]).
//
// Rendering is a thin view over [AutoSuggestionsBoxController]: every gesture
// and key is forwarded there and the widget rebuilds from its state. The
// overlay is an [OverlayPortal] linked to the field via [CompositedTransform*],
// so it tracks scroll/resize and auto-flips above when there isn't room below.
//
//   AutoSuggestionsBox<City>(
//     source: citySource,
//     hintText: 'Search a city…',
//     onSelected: (s) => print(s.value),
//   )
//
//   File: lib/design_system/components/forms/auto_suggestions_box.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'auto_suggestions_box_models.dart';
import 'auto_suggestions_box_controller.dart';
import 'auto_suggestions_box_theme.dart';

class AutoSuggestionsBox<T> extends StatefulWidget {
  /// Provide a [source] (or [items]) — or a fully-owned [controller].
  final AutoSuggestionsSource<T>? source;

  /// Shorthand static source: a list of suggestions (filtered by `contains`).
  final List<AutoSuggestion<T>>? items;

  /// An externally-owned controller. When null, one is created from
  /// [source]/[items] and disposed with the widget.
  final AutoSuggestionsBoxController<T>? controller;

  /// Fired when a row is picked (tap or Enter on a highlighted match).
  final ValueChanged<AutoSuggestion<T>>? onSelected;

  /// Fired on every text change.
  final ValueChanged<String>? onChanged;

  /// Fired when Enter is pressed with no highlighted match and free text is
  /// allowed (a "submit raw query" affordance).
  final ValueChanged<String>? onSubmitted;

  /// Placeholder shown when empty.
  final String? hintText;

  /// Field label rendered above the box (optional).
  final String? label;

  /// Leading widget inside the field (defaults to a search icon). Pass
  /// `SizedBox.shrink()` to remove it.
  final Widget? leading;

  /// Show the clear (×) button when there's text.
  final bool clearButton;

  /// How matches are highlighted in each row.
  final AutoSuggestionMatch highlightMatch;

  /// Highlight the matched substring in bold/accent.
  final bool highlightMatches;

  /// Open the overlay when the field gains focus.
  final bool openOnFocus;

  /// Max rows visible before the overlay scrolls.
  final int maxVisibleRows;

  /// Fixed field width (otherwise fills the parent).
  final double? width;

  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;

  /// Embed mode: drop the outer border + fill and tighten padding so the box
  /// sits flush inside a host surface (e.g. an EditableTable cell). The overlay
  /// dropdown is unchanged.
  final bool bare;

  /// Override the field's min height (defaults to [AutoSuggestionsBoxThemeData.fieldHeight]).
  final double? fieldHeight;

  /// Base text style for the typed value (size/family). Falls back to the DS body.
  final TextStyle? textStyle;

  /// Pressing Escape calls this (used by embedders like a table cell to cancel
  /// the edit). When null, Escape just closes the overlay.
  final VoidCallback? onEscape;

  /// Pressing Tab / Shift+Tab calls these (commit + move to the next/prev cell).
  /// When null, Tab performs normal focus traversal.
  final VoidCallback? onTabNext;
  final VoidCallback? onTabPrev;

  /// When the field gains focus, scroll it into view inside the nearest
  /// scrollable ancestor (so a box low in a long form / list isn't left under
  /// the fold or the keyboard, and the overlay has room to open). Uses
  /// `Scrollable.ensureVisible`. Set false to opt out.
  final bool scrollOnFocus;

  /// Custom row renderer (overrides the default label/description/icon row).
  final Widget Function(BuildContext, AutoSuggestion<T>, bool highlighted)? itemBuilder;

  /// Shown inside the overlay when a non-empty query has no matches.
  final Widget Function(BuildContext, String query)? emptyBuilder;

  /// Shown inside the overlay while an async source is loading and there are no
  /// results yet (e.g. a skeleton). When null, a default spinner row is used.
  /// (A small spinner also always appears in the field's suffix while loading.)
  final Widget Function(BuildContext, String query)? loadingBuilder;

  const AutoSuggestionsBox({
    super.key,
    this.source,
    this.items,
    this.controller,
    this.onSelected,
    this.onChanged,
    this.onSubmitted,
    this.hintText,
    this.label,
    this.leading,
    this.clearButton = true,
    this.highlightMatch = AutoSuggestionMatch.contains,
    this.highlightMatches = true,
    this.openOnFocus = true,
    this.maxVisibleRows = 8,
    this.width,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.bare = false,
    this.fieldHeight,
    this.textStyle,
    this.onEscape,
    this.onTabNext,
    this.onTabPrev,
    this.scrollOnFocus = true,
    this.itemBuilder,
    this.emptyBuilder,
    this.loadingBuilder,
  }) : assert(source != null || items != null || controller != null,
            'Provide one of: source, items, or controller');

  @override
  State<AutoSuggestionsBox<T>> createState() => _AutoSuggestionsBoxState<T>();
}

class _AutoSuggestionsBoxState<T> extends State<AutoSuggestionsBox<T>> {
  late AutoSuggestionsBoxController<T> _c;
  bool _ownsController = false;

  final _overlay = OverlayPortalController();
  final _link = LayerLink();
  final _fieldKey = GlobalKey();

  late FocusNode _focus;
  bool _ownsFocus = false;
  final _scroll = ScrollController();
  // Attached to whichever overlay row is currently highlighted, so we can scroll
  // it into view using real geometry (group headers / variable heights included).
  final GlobalKey _hlRowKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _c = widget.controller ?? _buildController();
    _ownsController = widget.controller == null;
    _c.addListener(_onModel);

    _focus = widget.focusNode ?? FocusNode();
    _ownsFocus = widget.focusNode == null;
    _focus.addListener(_onFocus);
  }

  AutoSuggestionsBoxController<T> _buildController() {
    final src = widget.source ?? AutoSuggestionsSource<T>.list(widget.items ?? const []);
    return AutoSuggestionsBoxController<T>(source: src);
  }

  void _onFocus() {
    if (_focus.hasFocus) {
      if (widget.openOnFocus) _c.open();
      if (widget.scrollOnFocus) _scrollIntoView();
    } else {
      // Defer so a tap on a row (which steals focus) can complete first.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_focus.hasFocus) _c.close();
      });
    }
  }

  /// Bring the field into view inside the nearest scrollable ancestor, after the
  /// current frame (so the overlay/keyboard insets are accounted for).
  void _scrollIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_focus.hasFocus) return;
      final ctx = _fieldKey.currentContext;
      if (ctx == null) return;
      final scrollable = Scrollable.maybeOf(ctx);
      if (scrollable == null) return; // no scrollable ancestor — nothing to do
      Scrollable.ensureVisible(
        ctx,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
        duration: AutoSuggestionsBoxThemeData.durBase,
        curve: AutoSuggestionsBoxThemeData.curveStandard,
      );
    });
  }

  void _onModel() {
    if (_c.isOpen && !_overlay.isShowing) {
      _overlay.show();
    } else if (!_c.isOpen && _overlay.isShowing) {
      _overlay.hide();
    }
    if (_c.isOpen) _ensureHighlightVisible();
    if (mounted) setState(() {});
  }

  /// Keep the highlighted row visible inside the overlay as the user arrows
  /// through it. Measures the highlighted row's real position (so group headers
  /// and variable row heights are handled) and animates only when it's off-view.
  void _ensureHighlightVisible() {
    if (_c.highlightedIndex < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final ctx = _hlRowKey.currentContext;
      if (ctx == null) {
        // Target row isn't built yet (e.g. a last↔first wrap). Snap toward the
        // matching end so the next frame can fine-tune.
        if (!_scroll.hasClients) return;
        final i = _c.highlightedIndex;
        if (i == 0) {
          _scroll.jumpTo(0);
        } else if (i == _c.results.length - 1) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
        return;
      }
      final box = ctx.findRenderObject();
      if (box is! RenderBox || !box.attached) return;
      final viewport = RenderAbstractViewport.maybeOf(box);
      if (viewport == null) return;

      // Scroll offsets that align the row's top to the viewport top, and bottom
      // to the viewport bottom; between them the row is fully visible.
      final toTop = viewport.getOffsetToReveal(box, 0.0).offset;
      final toBottom = viewport.getOffsetToReveal(box, 1.0).offset;
      final lo = toBottom < toTop ? toBottom : toTop;
      final hi = toBottom < toTop ? toTop : toBottom;
      final current = _scroll.offset;

      // The row is fully visible while the scroll offset is within [lo, hi].
      double? target;
      if (current < lo) {
        target = lo; // row sits below the fold → scroll down to reveal it
      } else if (current > hi) {
        target = hi; // row sits above the fold → scroll up to reveal it
      }
      if (target == null) return; // already fully visible — don't move

      final max = _scroll.position.maxScrollExtent;
      _scroll.animateTo(
        target.clamp(0.0, max),
        duration: AutoSuggestionsBoxThemeData.durFast,
        curve: AutoSuggestionsBoxThemeData.curveStandard,
      );
    });
  }

  @override
  void didUpdateWidget(covariant AutoSuggestionsBox<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller && widget.controller != null) {
      _c.removeListener(_onModel);
      if (_ownsController) _c.dispose();
      _c = widget.controller!;
      _ownsController = false;
      _c.addListener(_onModel);
    }
  }

  @override
  void dispose() {
    _c.removeListener(_onModel);
    if (_ownsController) _c.dispose();
    _focus.removeListener(_onFocus);
    if (_ownsFocus) _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── keyboard ──
  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    switch (e.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        _c.moveHighlight(1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        _c.moveHighlight(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
        final picked = _c.commitHighlighted();
        if (picked != null) {
          widget.onSelected?.call(picked);
        } else if (_c.allowFreeText) {
          widget.onSubmitted?.call(_c.query);
          _c.close();
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
        if (widget.onEscape != null) {
          if (_c.isOpen) _c.close();
          widget.onEscape!();
          return KeyEventResult.handled;
        }
        if (_c.isOpen) {
          _c.close();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      case LogicalKeyboardKey.tab:
        final shift = HardwareKeyboard.instance.isShiftPressed;
        final cb = shift ? widget.onTabPrev : widget.onTabNext;
        if (cb != null) {
          if (_c.isOpen) _c.close();
          cb();
          return KeyEventResult.handled;
        }
        if (_c.isOpen) _c.close();
        return KeyEventResult.ignored; // let focus traversal proceed
    }
    return KeyEventResult.ignored;
  }

  void _pick(AutoSuggestion<T> s) {
    if (!s.enabled) return;
    _c.select(s);
    widget.onSelected?.call(s);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final t = AutoSuggestionsBoxThemeData.of(context);
    final field = _buildField(t);
    return SizedBox(
      width: widget.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 2),
              child: Text(widget.label!,
                  style: TextStyle(fontFamily: AutoSuggestionsBoxThemeData.bodyFont, fontSize: 12.5, fontWeight: FontWeight.w600, color: t.fg2)),
            ),
          ],
          CompositedTransformTarget(
            link: _link,
            child: OverlayPortal(
              controller: _overlay,
              overlayChildBuilder: (ctx) => _buildOverlay(ctx, t),
              child: field,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(AutoSuggestionsBoxThemeData t) {
    final focused = _focus.hasFocus;
    final bare = widget.bare;
    final leading = widget.leading ??
        (bare
            ? const SizedBox.shrink()
            : Icon(Icons.search_rounded, size: 18, color: focused ? AutoSuggestionsBoxThemeData.accent : t.fg3));
    final hasLeading = !(leading is SizedBox && leading.width == 0 && leading.height == 0);
    final hasText = _c.query.isNotEmpty;
    final minH = widget.fieldHeight ?? AutoSuggestionsBoxThemeData.fieldHeight;
    final baseStyle = (widget.textStyle ??
            TextStyle(fontFamily: AutoSuggestionsBoxThemeData.bodyFont, fontSize: 14, color: t.fg1, height: 1.2))
        .copyWith(color: t.fg1);
    return Focus(
      onKeyEvent: _onKey,
      child: TextField(
        key: _fieldKey,
        controller: _c.text,
        focusNode: _focus,
        enabled: widget.enabled,
        autofocus: widget.autofocus,
        onChanged: (v) {
          widget.onChanged?.call(v);
          if (!_c.isOpen) _c.open();
        },
        onTap: () => _c.open(),
        style: baseStyle,
        cursorColor: AutoSuggestionsBoxThemeData.accent,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: bare ? Colors.transparent : (focused ? t.fieldBgFocus : t.fieldBg),
          hintText: widget.hintText,
          hintStyle: baseStyle.copyWith(color: t.fg3, fontWeight: FontWeight.w400),
          constraints: BoxConstraints(minHeight: minH),
          contentPadding: bare
              ? const EdgeInsets.symmetric(horizontal: 9, vertical: 9)
              : const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          prefixIcon: hasLeading
              ? Padding(padding: const EdgeInsets.only(left: 11, right: 8), child: leading)
              : null,
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: _buildSuffix(t, hasText),
          suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          border: bare ? InputBorder.none : _border(t.border),
          enabledBorder: bare ? InputBorder.none : _border(t.border),
          focusedBorder: bare ? InputBorder.none : _border(t.borderFocus, width: 1.6),
          disabledBorder: bare ? InputBorder.none : _border(t.border.withOpacity(0.5)),
        ),
      ),
    );
  }

  Widget? _buildSuffix(AutoSuggestionsBoxThemeData t, bool hasText) {
    final children = <Widget>[];
    if (_c.isLoading) {
      children.add(Padding(
        padding: const EdgeInsets.only(right: 4),
        child: SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: AutoSuggestionsBoxThemeData.accent)),
      ));
    }
    if (widget.clearButton && hasText) {
      children.add(_IconBtn(
        icon: Icons.close_rounded,
        color: t.fg3,
        hoverColor: t.fg1,
        onTap: () {
          _c.clear();
          _focus.requestFocus();
        },
      ));
    } else {
      children.add(_IconBtn(
        icon: _c.isOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded,
        color: t.fg3,
        hoverColor: t.fg1,
        onTap: () {
          _c.toggle();
          _focus.requestFocus();
        },
      ));
    }
    return Padding(
      padding: const EdgeInsets.only(right: 6, left: 4),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  OutlineInputBorder _border(Color c, {double width = 1.2}) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AutoSuggestionsBoxThemeData.radiusMd),
        borderSide: BorderSide(color: c, width: width),
      );

  // ── overlay ──
  Widget _buildOverlay(BuildContext ctx, AutoSuggestionsBoxThemeData t) {
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final fieldSize = box?.size ?? const Size(280, AutoSuggestionsBoxThemeData.fieldHeight);
    final fieldW = widget.width ?? fieldSize.width;

    // Decide flip: place above when there isn't room below.
    final media = MediaQuery.of(ctx);
    final fieldTopLeft = box?.localToGlobal(Offset.zero) ?? Offset.zero;
    final spaceBelow = media.size.height - (fieldTopLeft.dy + fieldSize.height) - media.viewInsets.bottom;
    final desired = _overlayHeight(t);
    final flipUp = spaceBelow < desired + 16 && fieldTopLeft.dy > spaceBelow;

    final followerAnchor = flipUp ? Alignment.bottomLeft : Alignment.topLeft;
    final targetAnchor = flipUp ? Alignment.topLeft : Alignment.bottomLeft;
    final gap = AutoSuggestionsBoxThemeData.overlayGap;

    return Stack(children: [
      // tap-outside scrim to dismiss
      Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => _c.close(),
        ),
      ),
      CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        offset: Offset(0, flipUp ? -gap : gap),
        followerAnchor: followerAnchor,
        targetAnchor: targetAnchor,
        child: Align(
          alignment: flipUp ? Alignment.bottomLeft : Alignment.topLeft,
          child: _Panel<T>(
            width: fieldW.clamp(180.0, AutoSuggestionsBoxThemeData.overlayMaxWidth),
            theme: t,
            controller: _c,
            scroll: _scroll,
            maxVisibleRows: widget.maxVisibleRows,
            highlightMatch: widget.highlightMatch,
            highlightMatches: widget.highlightMatches,
            itemBuilder: widget.itemBuilder,
            emptyBuilder: widget.emptyBuilder,
            loadingBuilder: widget.loadingBuilder,
            hlKey: _hlRowKey,
            onPick: _pick,
            onHover: _c.highlightAt,
          ),
        ),
      ),
    ]);
  }

  double _overlayHeight(AutoSuggestionsBoxThemeData t) {
    final rows = _c.results.length.clamp(0, widget.maxVisibleRows);
    return (rows == 0 ? 56 : rows * AutoSuggestionsBoxThemeData.rowHeight + 10).toDouble();
  }
}

// ── the dropdown panel ──
class _Panel<T> extends StatelessWidget {
  final double width;
  final AutoSuggestionsBoxThemeData theme;
  final AutoSuggestionsBoxController<T> controller;
  final ScrollController scroll;
  final int maxVisibleRows;
  final AutoSuggestionMatch highlightMatch;
  final bool highlightMatches;
  final Widget Function(BuildContext, AutoSuggestion<T>, bool)? itemBuilder;
  final Widget Function(BuildContext, String)? emptyBuilder;
  final Widget Function(BuildContext, String)? loadingBuilder;
  final GlobalKey hlKey;
  final ValueChanged<AutoSuggestion<T>> onPick;
  final ValueChanged<int> onHover;

  const _Panel({
    required this.width,
    required this.theme,
    required this.controller,
    required this.scroll,
    required this.maxVisibleRows,
    required this.highlightMatch,
    required this.highlightMatches,
    required this.itemBuilder,
    required this.emptyBuilder,
    required this.loadingBuilder,
    required this.hlKey,
    required this.onPick,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final results = controller.results;
    final q = controller.query;
    final maxH = maxVisibleRows * AutoSuggestionsBoxThemeData.rowHeight + 10;

    Widget body;
    if (controller.isLoading && results.isEmpty) {
      // Async source is fetching and nothing to show yet.
      body = loadingBuilder?.call(context, q) ??
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(children: [
              SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(strokeWidth: 2, color: AutoSuggestionsBoxThemeData.accent),
              ),
              const SizedBox(width: 10),
              Text(
                q.trim().isEmpty ? 'Loading…' : 'Searching “$q”…',
                style: TextStyle(fontFamily: AutoSuggestionsBoxThemeData.bodyFont, fontSize: 13, color: t.fg2),
              ),
            ]),
          );
    } else if (results.isEmpty) {
      body = emptyBuilder?.call(context, q) ??
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(children: [
              Icon(Icons.search_off_rounded, size: 16, color: t.fg3),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  q.trim().isEmpty ? 'Type to search' : 'No matches for “$q”',
                  style: TextStyle(fontFamily: AutoSuggestionsBoxThemeData.bodyFont, fontSize: 13, color: t.fg2),
                ),
              ),
            ]),
          );
    } else {
      body = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH.toDouble()),
        child: Scrollbar(
          controller: scroll,
          child: ListView.builder(
            controller: scroll,
            padding: const EdgeInsets.symmetric(vertical: 5),
            shrinkWrap: true,
            itemCount: results.length,
            itemBuilder: (ctx, i) {
              final s = results[i];
              final isHl = controller.isHighlighted(i);
              final showGroup = s.group != null && (i == 0 || results[i - 1].group != s.group);
              final row = _Row<T>(
                key: isHl ? hlKey : null,
                theme: t,
                suggestion: s,
                query: q,
                highlighted: isHl,
                highlightMatch: highlightMatch,
                highlightMatches: highlightMatches,
                custom: itemBuilder,
                onTap: () => onPick(s),
                onHover: () => onHover(i),
              );
              if (!showGroup) return row;
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(14, i == 0 ? 4 : 9, 14, 5),
                  child: Text(
                    s.group!.toUpperCase(),
                    style: TextStyle(
                        fontFamily: AutoSuggestionsBoxThemeData.bodyFont, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: t.groupFg),
                  ),
                ),
                row,
              ]);
            },
          ),
        ),
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: t.overlayBg,
          borderRadius: BorderRadius.circular(AutoSuggestionsBoxThemeData.radiusLg),
          border: Border.all(color: t.border),
          boxShadow: AutoSuggestionsBoxThemeData.overlayShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: body,
      ),
    );
  }
}

// ── one suggestion row ──
class _Row<T> extends StatelessWidget {
  final AutoSuggestionsBoxThemeData theme;
  final AutoSuggestion<T> suggestion;
  final String query;
  final bool highlighted;
  final AutoSuggestionMatch highlightMatch;
  final bool highlightMatches;
  final Widget Function(BuildContext, AutoSuggestion<T>, bool)? custom;
  final VoidCallback onTap;
  final VoidCallback onHover;

  const _Row({
    super.key,
    required this.theme,
    required this.suggestion,
    required this.query,
    required this.highlighted,
    required this.highlightMatch,
    required this.highlightMatches,
    required this.custom,
    required this.onTap,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final s = suggestion;
    final enabled = s.enabled;

    final content = custom?.call(context, s, highlighted) ??
        Row(children: [
          if (s.icon != null) ...[
            Icon(s.icon, size: 17, color: highlighted ? AutoSuggestionsBoxThemeData.accent : t.fg3),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AutoSuggestionsHighlight(
                  text: s.label,
                  query: query,
                  match: highlightMatch,
                  enabled: highlightMatches,
                  baseStyle: TextStyle(
                      fontFamily: AutoSuggestionsBoxThemeData.bodyFont,
                      fontSize: 13.5,
                      height: 1.2,
                      color: enabled ? t.fg1 : t.fg3,
                      fontWeight: FontWeight.w500),
                ),
                if (s.description != null) ...[
                  const SizedBox(height: 1),
                  Text(s.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: AutoSuggestionsBoxThemeData.bodyFont, fontSize: 11.5, height: 1.2, color: t.fg2)),
                ],
              ],
            ),
          ),
          if (highlighted && enabled) ...[
            const SizedBox(width: 8),
            Icon(Icons.subdirectory_arrow_left_rounded, size: 14, color: t.fg3),
          ],
        ]);

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => onHover(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: AutoSuggestionsBoxThemeData.durFast,
          height: AutoSuggestionsBoxThemeData.rowHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: highlighted ? t.hover : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: highlighted && enabled ? AutoSuggestionsBoxThemeData.accent : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: content,
        ),
      ),
    );
  }
}

/// Renders [text] with the portion(s) matching [query] emphasised — the
/// design-system analogue of the package's highlight text.
class AutoSuggestionsHighlight extends StatelessWidget {
  final String text;
  final String query;
  final AutoSuggestionMatch match;
  final bool enabled;
  final TextStyle baseStyle;
  final Color? highlightColor;

  const AutoSuggestionsHighlight({
    super.key,
    required this.text,
    required this.query,
    required this.baseStyle,
    this.match = AutoSuggestionMatch.contains,
    this.enabled = true,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled || query.trim().isEmpty) {
      return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: baseStyle);
    }
    final spans = AutoSuggestionMatching.spans(text, query, match);
    if (spans.isEmpty) {
      return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: baseStyle);
    }
    final hi = baseStyle.copyWith(
      color: highlightColor ?? AutoSuggestionsBoxThemeData.accent,
      fontWeight: FontWeight.w700,
    );
    final pieces = <TextSpan>[];
    var cursor = 0;
    for (final span in spans) {
      if (span.start > cursor) pieces.add(TextSpan(text: text.substring(cursor, span.start)));
      pieces.add(TextSpan(text: text.substring(span.start, span.end), style: hi));
      cursor = span.end;
    }
    if (cursor < text.length) pieces.add(TextSpan(text: text.substring(cursor)));

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(style: baseStyle, children: pieces),
    );
  }
}

// ── tiny hover-aware icon button used in the field suffix ──
class _IconBtn extends StatefulWidget {
  final IconData icon;
  final Color color;
  final Color hoverColor;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.hoverColor, required this.onTap});
  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(widget.icon, size: 17, color: _h ? widget.hoverColor : widget.color),
        ),
      ),
    );
  }
}
