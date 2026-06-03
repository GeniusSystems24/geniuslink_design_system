// ============================================================
// ReadableTable — VIEW (read-only, generic display grid · MVC).
// ------------------------------------------------------------
// A thin render of a ReadableTableController<T>. Shares EditableTable's visual
// language (it reuses EditableTableThemeData — identical header, hairline
// grid, surfaces, type ramp) but it DISPLAYS typed row values rather than
// editing strings, adding the read-only interaction layer a display grid
// needs — selection, keyboard navigation and click-to-sort.
//
// Generic over the row value type T: each row is one strongly-typed T and
// every ReadableColumn<T> renders itself from that value via `cell`.
//
// Provide a [controller] (full MVC: select/add/delete/replace from anywhere),
// OR the convenience [columns] + [rows] (the widget owns a controller). The
// controller is published to descendants via [ReadableTableScope] so any
// child can call `ReadableTableController.of<T>(context)`.
//
//   ReadableTable<Account>(
//     selectionMode: ReadableSelectionMode.multiRow,
//     columns: [
//       ReadableColumn('Code', width: 90, sortable: true,
//         sortKey: (a) => a.code, cell: (ctx, a) => Text(a.code)),
//       ReadableColumn('Balance', align: ReadableAlign.end, sortable: true,
//         sortKey: (a) => a.balance, cell: (ctx, a) => Text(a.fmt)),
//     ],
//     rows: accounts,
//     onRowSelectionChanged: (rows) => print(rows), // List<Account>
//   )
//
//   File: lib/design_system/components/data/readable_table.dart
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'editable_table_theme.dart';
import 'readable_table_models.dart';
import 'readable_table_controller.dart';

class ReadableTable<T> extends StatefulWidget {
  /// Drive / observe the grid externally. When null the widget builds and owns
  /// a controller from [columns] + [rows].
  final ReadableTableController<T>? controller;

  /// Column schema (required when [controller] is null).
  final List<ReadableColumn<T>>? columns;

  /// Row values (used when [controller] is null).
  final List<T>? rows;

  /// What the user can select (used when [controller] is null; also keeps an
  /// external controller's mode in sync).
  final ReadableSelectionMode selectionMode;

  // ── presentation ────────────────────────────────────────────
  final bool showHeader;
  final bool zebra;
  final bool hoverHighlight;
  final double rowMinHeight;
  final EdgeInsets cellPadding;
  final Widget? emptyState;

  // ── seeds (controller-less convenience) ─────────────────────
  final Set<int>? initialSelectedRows;
  final Set<ReadableCell>? initialSelectedCells;
  final int? initialSortColumn;
  final bool initialSortAscending;

  // ── callbacks ───────────────────────────────────────────────
  /// Fires with the original row **values** whenever the row selection changes.
  final ValueChanged<List<T>>? onRowSelectionChanged;

  /// Fires with the set of selected cells whenever it changes.
  final ValueChanged<Set<ReadableCell>>? onCellSelectionChanged;

  /// Fires when a row is activated (tap / Enter), with its value + index.
  final void Function(T value, int index)? onRowTap;

  /// Fires whenever the sort changes — (column or null, ascending).
  final void Function(int? column, bool ascending)? onSortChanged;

  const ReadableTable({
    super.key,
    this.controller,
    this.columns,
    this.rows,
    this.selectionMode = ReadableSelectionMode.none,
    this.showHeader = true,
    this.zebra = false,
    this.hoverHighlight = false,
    this.rowMinHeight = 52,
    this.cellPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    this.emptyState,
    this.initialSelectedRows,
    this.initialSelectedCells,
    this.initialSortColumn,
    this.initialSortAscending = true,
    this.onRowSelectionChanged,
    this.onCellSelectionChanged,
    this.onRowTap,
    this.onSortChanged,
  }) : assert(controller != null || columns != null,
            'Provide a controller, or columns (+ rows).');

  @override
  State<ReadableTable<T>> createState() => _ReadableTableState<T>();
}

class _ReadableTableState<T> extends State<ReadableTable<T>> {
  late ReadableTableController<T> _controller;
  bool _ownsController = false;
  int _hovered = -1;
  final FocusNode _focus = FocusNode(debugLabel: 'ReadableTable');

  // change-detection snapshots for the callbacks
  Set<int> _lastSelRows = {};
  Set<ReadableCell> _lastSelCells = {};
  int? _lastSortCol;
  ReadableSortDir _lastSortDir = ReadableSortDir.none;

  EditableTableThemeData get _t => EditableTableThemeData.of(context);

  @override
  void initState() {
    super.initState();
    _attach();
  }

  void _attach() {
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
      if (_controller.selectionMode != widget.selectionMode &&
          widget.selectionMode != ReadableSelectionMode.none) {
        _controller.setSelectionMode(widget.selectionMode);
      }
    } else {
      _controller = ReadableTableController<T>(
        columns: widget.columns!,
        rows: widget.rows,
        selectionMode: widget.selectionMode,
        selectedRows: widget.initialSelectedRows,
        selectedCells: widget.initialSelectedCells,
        sortColumn: widget.initialSortColumn,
        sortAscending: widget.initialSortAscending,
      );
      _ownsController = true;
    }
    _lastSelRows = _controller.selectedRowIndices;
    _lastSelCells = _controller.selectedCells;
    _lastSortCol = _controller.sortColumn;
    _lastSortDir = _controller.sortDir;
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant ReadableTable<T> old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      _controller.removeListener(_onControllerChanged);
      if (_ownsController) _controller.dispose();
      _attach();
    } else if (widget.controller == null && widget.selectionMode != _controller.selectionMode) {
      _controller.setSelectionMode(widget.selectionMode);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    // emit selection / sort callbacks on real change
    final sr = _controller.selectedRowIndices;
    if (!_setEq(sr, _lastSelRows)) {
      _lastSelRows = sr;
      widget.onRowSelectionChanged?.call(_controller.selectedRows);
    }
    final sc = _controller.selectedCells;
    if (!_cellSetEq(sc, _lastSelCells)) {
      _lastSelCells = sc;
      widget.onCellSelectionChanged?.call(sc);
    }
    if (_controller.sortColumn != _lastSortCol || _controller.sortDir != _lastSortDir) {
      _lastSortCol = _controller.sortColumn;
      _lastSortDir = _controller.sortDir;
      widget.onSortChanged?.call(_controller.sortColumn, _controller.sortDir != ReadableSortDir.desc);
    }
    if (mounted) setState(() {});
  }

  bool _setEq(Set<int> a, Set<int> b) => a.length == b.length && a.containsAll(b);
  bool _cellSetEq(Set<ReadableCell> a, Set<ReadableCell> b) => a.length == b.length && a.containsAll(b);

  // ── keyboard ───────────────────────────────────────────────
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final c = _controller;
    if (!c.isInteractive) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    if (c.rowCount == 0) return KeyEventResult.ignored;
    final k = event.logicalKey;
    final mod = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
    final shift = HardwareKeyboard.instance.isShiftPressed;
    final lastRow = c.rowCount - 1;
    final lastCol = c.colCount - 1;

    if (mod && k == LogicalKeyboardKey.keyA) {
      c.selectAll();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.f1 || (mod && k == LogicalKeyboardKey.slash) || event.character == '?') {
      _showShortcuts();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.escape) {
      c.clearSelection();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowUp) {
      c.moveActive(-1, 0, extend: shift);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowDown) {
      c.moveActive(1, 0, extend: shift);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowLeft) {
      c.moveActive(0, -1, extend: shift);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowRight) {
      c.moveActive(0, 1, extend: shift);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.home) {
      c.moveActiveTo(mod ? 0 : c.activeRow, 0, extend: shift);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.end) {
      c.moveActiveTo(mod ? lastRow : c.activeRow, lastCol, extend: shift);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.pageUp) {
      c.moveActiveTo(0, c.activeCol, extend: shift);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.pageDown) {
      c.moveActiveTo(lastRow, c.activeCol, extend: shift);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.space) {
      c.toggleActive();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      widget.onRowTap?.call(c.rowAt(c.activeRow), c.activeRow);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ── geometry ───────────────────────────────────────────────
  Alignment _alignment(ReadableAlign a) => switch (a) {
        ReadableAlign.end => Alignment.centerRight,
        ReadableAlign.center => Alignment.center,
        ReadableAlign.start => Alignment.centerLeft,
      };

  Widget _sizedCell({required ReadableColumn<T> col, required Widget child}) {
    return col.width != null ? SizedBox(width: col.width, child: child) : Expanded(flex: col.flex, child: child);
  }

  // ── build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final t = _t;
    final c = _controller;
    final table = Container(
      decoration: BoxDecoration(
        border: Border.all(color: t.borderStrong),
        borderRadius: BorderRadius.circular(EditableTableThemeData.radiusMd),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showHeader) _header(t),
          if (c.rowCount == 0)
            _empty(t)
          else
            for (var r = 0; r < c.rowCount; r++) _row(t, r),
        ],
      ),
    );

    final scoped = ReadableTableScope(controller: c, child: table);

    if (!c.isInteractive) return scoped;

    return Focus(
      focusNode: _focus,
      onKeyEvent: _onKey,
      child: GestureDetector(
        onTap: () => _focus.requestFocus(),
        behavior: HitTestBehavior.opaque,
        child: scoped,
      ),
    );
  }

  Widget _header(EditableTableThemeData t) {
    return Container(
      decoration: BoxDecoration(
        color: t.bg,
        border: Border(bottom: BorderSide(color: t.borderStrong)),
      ),
      child: Row(
        children: [
          for (var ci = 0; ci < _controller.colCount; ci++) _headerCell(t, ci),
        ],
      ),
    );
  }

  Widget _headerCell(EditableTableThemeData t, int ci) {
    final col = _controller.columns[ci];
    final sorted = _controller.sortColumn == ci && _controller.sortDir != ReadableSortDir.none;
    final asc = _controller.sortDir == ReadableSortDir.asc;

    final label = Text(
      col.label.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: EditableTableThemeData.bodyFont,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: sorted ? EditableTableThemeData.accent : t.fg3,
      ),
    );

    final arrow = col.sortable
        ? Icon(
            sorted ? (asc ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded) : Icons.unfold_more_rounded,
            size: 13,
            color: sorted ? EditableTableThemeData.accent : t.fg4,
          )
        : null;

    final mainAxis = switch (col.align) {
      ReadableAlign.end => MainAxisAlignment.end,
      ReadableAlign.center => MainAxisAlignment.center,
      ReadableAlign.start => MainAxisAlignment.start,
    };

    Widget content = Padding(
      padding: widget.cellPadding,
      child: Row(
        mainAxisAlignment: mainAxis,
        children: [
          Flexible(child: label),
          if (arrow != null) ...[const SizedBox(width: 5), arrow],
        ],
      ),
    );

    if (col.sortable) {
      content = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _controller.sortByColumn(ci),
          child: content,
        ),
      );
    }
    return _sizedCell(col: col, child: content);
  }

  Widget _row(EditableTableThemeData t, int r) {
    final c = _controller;
    final value = c.rowAt(r);
    final hovered = widget.hoverHighlight && _hovered == r;
    final rowSelected = c.selectionMode == ReadableSelectionMode.singleRow ||
            c.selectionMode == ReadableSelectionMode.multiRow
        ? c.isRowSelected(r)
        : false;
    final isActive = c.isInteractive && _focus.hasFocus && c.activeRow == r;
    final cellMode = c.selectionMode == ReadableSelectionMode.singleCell ||
        c.selectionMode == ReadableSelectionMode.multiCell;
    final rowMode = c.selectionMode == ReadableSelectionMode.singleRow ||
        c.selectionMode == ReadableSelectionMode.multiRow;

    Color bg;
    if (rowSelected) {
      bg = t.selectionFill(0.12);
    } else if (hovered) {
      bg = t.hover;
    } else if (widget.zebra && r.isOdd) {
      bg = Color.alphaBlend(t.bg.withOpacity(0.5), t.surface);
    } else {
      bg = t.surface;
    }

    final clickable = widget.onRowTap != null || c.isInteractive;

    Widget rowWidget = Container(
      constraints: BoxConstraints(minHeight: widget.rowMinHeight),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: BorderSide(color: t.border),
          left: rowMode && rowSelected
              ? const BorderSide(color: EditableTableThemeData.accent, width: 2)
              : BorderSide.none,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var ci = 0; ci < c.colCount; ci++) _bodyCell(t, r, ci, value, isActive, cellMode),
        ],
      ),
    );

    if (!cellMode && clickable) {
      rowWidget = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _focus.requestFocus();
          if (rowMode) {
            c.selectRowAt(
              r,
              additive: HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed,
              range: HardwareKeyboard.instance.isShiftPressed,
            );
          }
          widget.onRowTap?.call(value, r);
        },
        child: rowWidget,
      );
    }

    if (widget.hoverHighlight || clickable) {
      rowWidget = MouseRegion(
        cursor: clickable ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _hovered = r),
        onExit: (_) => setState(() => _hovered = _hovered == r ? -1 : _hovered),
        child: rowWidget,
      );
    }
    return rowWidget;
  }

  Widget _bodyCell(EditableTableThemeData t, int r, int ci, T value, bool rowActive, bool cellMode) {
    final c = _controller;
    final col = c.columns[ci];
    final cellSelected = cellMode && c.isCellSelected(r, ci);
    final cellActive = cellMode && rowActive && c.activeCol == ci;

    Widget box = Container(
      padding: widget.cellPadding,
      decoration: cellSelected
          ? BoxDecoration(
              color: t.selectionFill(0.14),
              border: Border.all(
                color: cellActive ? EditableTableThemeData.accent : EditableTableThemeData.accent.withOpacity(0.45),
                width: cellActive ? 1.5 : 1,
              ),
            )
          : (cellActive
              ? BoxDecoration(border: Border.all(color: EditableTableThemeData.accent.withOpacity(0.5), width: 1.5))
              : null),
      child: Align(alignment: _alignment(col.align), child: col.cell(context, value)),
    );

    if (cellMode) {
      box = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _focus.requestFocus();
          c.selectCellAt(
            r,
            ci,
            additive: HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed,
            range: HardwareKeyboard.instance.isShiftPressed,
          );
          widget.onRowTap?.call(value, r);
        },
        child: MouseRegion(cursor: SystemMouseCursors.click, child: box),
      );
    }
    return _sizedCell(col: col, child: box);
  }

  Widget _empty(EditableTableThemeData t) {
    return Container(
      height: 96,
      alignment: Alignment.center,
      color: t.surface,
      child: widget.emptyState ??
          Text('No rows', style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 13, color: t.fg3)),
    );
  }

  // ── shortcut cheatsheet ────────────────────────────────────
  void _showShortcuts() {
    final t = _t;
    final c = _controller;
    final cell = c.selectionMode == ReadableSelectionMode.singleCell ||
        c.selectionMode == ReadableSelectionMode.multiCell;
    final multi = c.selectionMode == ReadableSelectionMode.multiRow ||
        c.selectionMode == ReadableSelectionMode.multiCell;
    final rows = <List<String>>[
      ['↑ ↓', 'Move active row'],
      if (cell) ['← →', 'Move active cell'],
      ['Space', multi ? 'Toggle selection' : 'Select'],
      if (multi) ['Shift + ↑↓${cell ? '←→' : ''}', 'Extend selection'],
      if (multi) ['${_modLabel()} + A', 'Select all'],
      ['Enter', 'Activate (onRowTap)'],
      ['Home / End', 'Row start / end'],
      ['${_modLabel()} + Home / End', 'Grid corners'],
      ['Esc', 'Clear selection'],
      ['Click header', 'Sort column'],
    ];
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 360,
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(EditableTableThemeData.radiusLg),
              border: Border.all(color: t.borderStrong),
              boxShadow: EditableTableThemeData.popShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('KEYBOARD',
                    style: TextStyle(
                        fontFamily: EditableTableThemeData.bodyFont,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: EditableTableThemeData.accent)),
                const SizedBox(height: 4),
                Text('ReadableTable shortcuts',
                    style: TextStyle(
                        fontFamily: EditableTableThemeData.displayFont, fontSize: 18, fontWeight: FontWeight.w700, color: t.fg1)),
                const SizedBox(height: 16),
                for (final r in rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: t.inputBg,
                            borderRadius: BorderRadius.circular(EditableTableThemeData.radiusSm),
                            border: Border.all(color: t.border),
                          ),
                          child: Text(r[0],
                              style: TextStyle(fontFamily: EditableTableThemeData.monoFont, fontSize: 11.5, color: t.fg2)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(r[1],
                              style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 13, color: t.fg1)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: EditableTableThemeData.accent,
                        borderRadius: BorderRadius.circular(EditableTableThemeData.radiusMd),
                      ),
                      child: const Text('Got it',
                          style: TextStyle(
                              fontFamily: EditableTableThemeData.bodyFont, fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _modLabel() {
    final isApple = defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.iOS;
    return isApple ? '⌘' : 'Ctrl';
  }
}
