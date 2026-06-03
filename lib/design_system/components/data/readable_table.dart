// ============================================================
// ReadableTable — VIEW (read-only display grid).
// ------------------------------------------------------------
// The read-only sibling of EditableTable: same visual language (it reuses
// EditableTableThemeData — identical header, hairline grid, surfaces, type
// ramp) but it renders arbitrary **widget** cells. It does NOT edit values;
// instead it adds the read-only interaction layer a display grid needs:
//
//   • Selection — five modes via [ReadableSelectionMode]:
//       none · singleRow · multiRow · singleCell · multiCell
//     Pointer: click selects; Ctrl/⌘-click toggles; Shift-click extends a
//     range (linear for rows, rectangular for cells).
//   • Keyboard — arrows move the active cell/row, Shift+arrows extend a
//     multi-selection, Space/Enter toggles, Ctrl/⌘+A selects all, Esc clears,
//     Home/End jump to row edges, Ctrl/⌘+Home/End jump to the grid corners.
//     Press ? (or ⌘/) for the in-widget shortcut cheatsheet.
//   • Column sort — mark a column [ReadableColumn.sortable]; click its header
//     to cycle asc → desc. Numeric-looking text sorts numerically; otherwise
//     case-insensitive string sort. Provide [ReadableTable.sortKeyOf] for
//     non-text cells (pills, bars, …).
//
//   ReadableTable(
//     selectionMode: ReadableSelectionMode.multiRow,
//     columns: const [
//       ReadableColumn('Code', width: 90, sortable: true),
//       ReadableColumn('Account', flex: 2, sortable: true),
//       ReadableColumn('Balance', align: ReadableAlign.end, sortable: true),
//     ],
//     rows: [
//       [Text('1001'), Text('Cash Box'), Text('42,500.00')],
//       ...
//     ],
//     onRowSelectionChanged: (rows) => print(rows), // original indices
//   )
//
//   File: lib/design_system/components/data/readable_table.dart
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'editable_table_theme.dart';

/// Horizontal placement of a column's header + cell content.
enum ReadableAlign { start, center, end }

/// What a [ReadableTable] lets the user select.
enum ReadableSelectionMode {
  /// No selection layer (display only). Default — fully backward-compatible.
  none,

  /// Exactly one row at a time.
  singleRow,

  /// Any number of rows (Ctrl/⌘-click toggles, Shift-click / Shift+arrows
  /// extend a range, Ctrl/⌘+A selects all).
  multiRow,

  /// Exactly one cell at a time.
  singleCell,

  /// Any number of cells (Ctrl/⌘-click toggles, Shift extends a rectangle).
  multiCell,
}

/// A cell address by **original** (pre-sort) row index + column index.
@immutable
class ReadableCell {
  final int row;
  final int col;
  const ReadableCell(this.row, this.col);

  @override
  bool operator ==(Object other) => other is ReadableCell && other.row == row && other.col == col;
  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => 'ReadableCell($row, $col)';
}

/// One column descriptor. Either [width] (fixed px) or [flex] (proportional,
/// filling the remaining width) sizes the column.
@immutable
class ReadableColumn {
  /// Header label (uppercased on render). Empty string → blank header cell.
  final String label;

  /// Fixed pixel width. When null the column flexes by [flex].
  final double? width;

  /// Proportional weight when [width] is null.
  final int flex;

  /// Content alignment (header + body).
  final ReadableAlign align;

  /// Whether the header is clickable to sort by this column.
  final bool sortable;

  const ReadableColumn(
    this.label, {
    this.width,
    this.flex = 1,
    this.align = ReadableAlign.start,
    this.sortable = false,
  });
}

class ReadableTable extends StatefulWidget {
  /// Column schema.
  final List<ReadableColumn> columns;

  /// Row data — one `List<Widget>` per row, aligned to [columns] by index.
  /// Cells are arbitrary widgets and are placed/aligned by the table.
  final List<List<Widget>> rows;

  /// Render the uppercase header row.
  final bool showHeader;

  /// Alternate a faint fill on odd rows.
  final bool zebra;

  /// Tint a row on pointer hover.
  final bool hoverHighlight;

  /// Minimum height of every data row.
  final double rowMinHeight;

  /// Padding inside every header / body cell.
  final EdgeInsets cellPadding;

  /// Notified with the **original** row index when a row is tapped. Fires in
  /// every selection mode (and even when [selectionMode] is none).
  final ValueChanged<int>? onRowTap;

  /// Placeholder shown when [rows] is empty.
  final Widget? emptyState;

  // ── selection ───────────────────────────────────────────────
  /// What the user can select. Defaults to [ReadableSelectionMode.none].
  final ReadableSelectionMode selectionMode;

  /// Original row indices selected initially (row modes only).
  final Set<int>? initialSelectedRows;

  /// Cells selected initially (cell modes only).
  final Set<ReadableCell>? initialSelectedCells;

  /// Fires with the full set of selected **original** row indices whenever it
  /// changes (row modes).
  final ValueChanged<Set<int>>? onRowSelectionChanged;

  /// Fires with the full set of selected cells whenever it changes
  /// (cell modes).
  final ValueChanged<Set<ReadableCell>>? onCellSelectionChanged;

  // ── sorting ─────────────────────────────────────────────────
  /// Resolve a comparable sort key for a cell. Receives the **original** row
  /// index + column index. When null the table reads the text out of `Text`
  /// cells (numeric-looking strings sort numerically). Provide this for
  /// non-text cells (status pills, progress bars, custom widgets…).
  final Comparable? Function(int rowIndex, int colIndex)? sortKeyOf;

  /// Column to sort by initially (must be [ReadableColumn.sortable]).
  final int? initialSortColumn;

  /// Initial sort direction.
  final bool initialSortAscending;

  /// Fires whenever the sort changes — (columnIndex or null, ascending).
  final void Function(int? column, bool ascending)? onSortChanged;

  const ReadableTable({
    super.key,
    required this.columns,
    required this.rows,
    this.showHeader = true,
    this.zebra = false,
    this.hoverHighlight = false,
    this.rowMinHeight = 52,
    this.cellPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    this.onRowTap,
    this.emptyState,
    this.selectionMode = ReadableSelectionMode.none,
    this.initialSelectedRows,
    this.initialSelectedCells,
    this.onRowSelectionChanged,
    this.onCellSelectionChanged,
    this.sortKeyOf,
    this.initialSortColumn,
    this.initialSortAscending = true,
    this.onSortChanged,
  });

  // mode helpers
  bool get _isRowMode =>
      selectionMode == ReadableSelectionMode.singleRow || selectionMode == ReadableSelectionMode.multiRow;
  bool get _isCellMode =>
      selectionMode == ReadableSelectionMode.singleCell || selectionMode == ReadableSelectionMode.multiCell;
  bool get _isMulti =>
      selectionMode == ReadableSelectionMode.multiRow || selectionMode == ReadableSelectionMode.multiCell;
  bool get _interactive => selectionMode != ReadableSelectionMode.none;

  @override
  State<ReadableTable> createState() => _ReadableTableState();
}

class _ReadableTableState extends State<ReadableTable> {
  int _hovered = -1; // display index under the pointer

  // selection (always by ORIGINAL row index)
  final Set<int> _selRows = {};
  final Set<ReadableCell> _selCells = {};

  // active cursor — display row position (into _order) + column
  int _activeDisplay = 0;
  int _activeCol = 0;
  // shift-range anchor
  int _anchorDisplay = 0;
  int _anchorCol = 0;

  // sort
  int? _sortCol;
  late bool _sortAsc;
  late List<int> _order; // display order → original row index

  final FocusNode _focus = FocusNode(debugLabel: 'ReadableTable');

  EditableTableThemeData get _t => EditableTableThemeData.of(context);

  @override
  void initState() {
    super.initState();
    _selRows.addAll(widget.initialSelectedRows ?? const {});
    _selCells.addAll(widget.initialSelectedCells ?? const {});
    _sortCol = widget.initialSortColumn;
    _sortAsc = widget.initialSortAscending;
    _rebuildOrder();
  }

  @override
  void didUpdateWidget(covariant ReadableTable old) {
    super.didUpdateWidget(old);
    if (old.rows.length != widget.rows.length || old.columns.length != widget.columns.length) {
      _selRows.removeWhere((r) => r >= widget.rows.length);
      _selCells.removeWhere((c) => c.row >= widget.rows.length || c.col >= widget.columns.length);
      if (_sortCol != null && _sortCol! >= widget.columns.length) _sortCol = null;
      _rebuildOrder();
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  // ── sorting ────────────────────────────────────────────────
  void _rebuildOrder() {
    _order = List<int>.generate(widget.rows.length, (i) => i);
    final col = _sortCol;
    if (col == null) return;
    _order.sort((a, b) {
      final ka = _sortKey(a, col);
      final kb = _sortKey(b, col);
      int cmp;
      if (ka == null && kb == null) {
        cmp = 0;
      } else if (ka == null) {
        cmp = 1; // nulls last
      } else if (kb == null) {
        cmp = -1;
      } else if (ka.runtimeType == kb.runtimeType) {
        cmp = ka.compareTo(kb);
      } else {
        cmp = ka.toString().compareTo(kb.toString());
      }
      return _sortAsc ? cmp : -cmp;
    });
  }

  Comparable? _sortKey(int origRow, int col) {
    if (widget.sortKeyOf != null) return widget.sortKeyOf!(origRow, col);
    final text = _extractText(origRow, col);
    if (text == null || text.isEmpty) return null;
    final cleaned = text.replaceAll(',', '').trim();
    final n = num.tryParse(cleaned);
    if (n != null) return n;
    return text.toLowerCase();
  }

  /// Best-effort text extraction for the default sort key — handles a bare
  /// `Text` cell (the common ledger case). Anything richer should supply
  /// [ReadableTable.sortKeyOf].
  String? _extractText(int origRow, int col) {
    if (origRow >= widget.rows.length || col >= widget.rows[origRow].length) return null;
    final w = widget.rows[origRow][col];
    if (w is Text) return w.data ?? w.textSpan?.toPlainText();
    return null;
  }

  void _toggleSort(int col) {
    setState(() {
      if (_sortCol == col) {
        _sortAsc = !_sortAsc;
      } else {
        _sortCol = col;
        _sortAsc = true;
      }
      _rebuildOrder();
    });
    widget.onSortChanged?.call(_sortCol, _sortAsc);
  }

  // ── selection plumbing ─────────────────────────────────────
  void _emitRows() => widget.onRowSelectionChanged?.call(Set<int>.from(_selRows));
  void _emitCells() => widget.onCellSelectionChanged?.call(Set<ReadableCell>.from(_selCells));

  bool _modPressed() => HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
  bool _shiftPressed() => HardwareKeyboard.instance.isShiftPressed;

  void _selectRowAt(int display, {required bool toggle, required bool range}) {
    if (!widget._isRowMode) return;
    final orig = _order[display];
    setState(() {
      _activeDisplay = display;
      if (widget.selectionMode == ReadableSelectionMode.singleRow) {
        _selRows
          ..clear()
          ..add(orig);
        _anchorDisplay = display;
      } else if (range) {
        final lo = display < _anchorDisplay ? display : _anchorDisplay;
        final hi = display < _anchorDisplay ? _anchorDisplay : display;
        if (!toggle) _selRows.clear();
        for (var d = lo; d <= hi; d++) {
          _selRows.add(_order[d]);
        }
      } else if (toggle) {
        _selRows.contains(orig) ? _selRows.remove(orig) : _selRows.add(orig);
        _anchorDisplay = display;
      } else {
        _selRows
          ..clear()
          ..add(orig);
        _anchorDisplay = display;
      }
    });
    _emitRows();
  }

  void _selectCellAt(int display, int col, {required bool toggle, required bool range}) {
    if (!widget._isCellMode) return;
    final orig = _order[display];
    setState(() {
      _activeDisplay = display;
      _activeCol = col;
      if (widget.selectionMode == ReadableSelectionMode.singleCell) {
        _selCells
          ..clear()
          ..add(ReadableCell(orig, col));
        _anchorDisplay = display;
        _anchorCol = col;
      } else if (range) {
        final loR = display < _anchorDisplay ? display : _anchorDisplay;
        final hiR = display < _anchorDisplay ? _anchorDisplay : display;
        final loC = col < _anchorCol ? col : _anchorCol;
        final hiC = col < _anchorCol ? _anchorCol : col;
        if (!toggle) _selCells.clear();
        for (var d = loR; d <= hiR; d++) {
          for (var c = loC; c <= hiC; c++) {
            _selCells.add(ReadableCell(_order[d], c));
          }
        }
      } else if (toggle) {
        final cell = ReadableCell(orig, col);
        _selCells.contains(cell) ? _selCells.remove(cell) : _selCells.add(cell);
        _anchorDisplay = display;
        _anchorCol = col;
      } else {
        _selCells
          ..clear()
          ..add(ReadableCell(orig, col));
        _anchorDisplay = display;
        _anchorCol = col;
      }
    });
    _emitCells();
  }

  bool _rowSelected(int orig) => _selRows.contains(orig);
  bool _cellSelected(int orig, int col) => _selCells.contains(ReadableCell(orig, col));

  // ── keyboard ───────────────────────────────────────────────
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!widget._interactive) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    if (widget.rows.isEmpty) return KeyEventResult.ignored;
    final k = event.logicalKey;
    final mod = _modPressed();
    final shift = _shiftPressed();
    final lastDisplay = _order.length - 1;
    final lastCol = widget.columns.length - 1;

    // select-all
    if (mod && k == LogicalKeyboardKey.keyA) {
      setState(() {
        if (widget.selectionMode == ReadableSelectionMode.multiRow) {
          _selRows
            ..clear()
            ..addAll(_order);
        } else if (widget.selectionMode == ReadableSelectionMode.multiCell) {
          _selCells.clear();
          for (final o in _order) {
            for (var c = 0; c <= lastCol; c++) {
              _selCells.add(ReadableCell(o, c));
            }
          }
        }
      });
      widget._isRowMode ? _emitRows() : _emitCells();
      return KeyEventResult.handled;
    }

    // help — ? (Shift+/) or ⌘/Ctrl+/ or F1
    if (k == LogicalKeyboardKey.f1 ||
        (mod && k == LogicalKeyboardKey.slash) ||
        event.character == '?') {
      _showShortcuts();
      return KeyEventResult.handled;
    }

    // clear
    if (k == LogicalKeyboardKey.escape) {
      setState(() {
        _selRows.clear();
        _selCells.clear();
      });
      widget._isRowMode ? _emitRows() : _emitCells();
      return KeyEventResult.handled;
    }

    int nd = _activeDisplay.clamp(0, lastDisplay);
    int nc = _activeCol.clamp(0, lastCol);
    bool moved = false;

    if (k == LogicalKeyboardKey.arrowUp) {
      nd = (nd - 1).clamp(0, lastDisplay);
      moved = true;
    } else if (k == LogicalKeyboardKey.arrowDown) {
      nd = (nd + 1).clamp(0, lastDisplay);
      moved = true;
    } else if (k == LogicalKeyboardKey.arrowLeft && widget._isCellMode) {
      nc = (nc - 1).clamp(0, lastCol);
      moved = true;
    } else if (k == LogicalKeyboardKey.arrowRight && widget._isCellMode) {
      nc = (nc + 1).clamp(0, lastCol);
      moved = true;
    } else if (k == LogicalKeyboardKey.home) {
      if (mod) nd = 0;
      nc = 0;
      moved = true;
    } else if (k == LogicalKeyboardKey.end) {
      if (mod) nd = lastDisplay;
      nc = lastCol;
      moved = true;
    } else if (k == LogicalKeyboardKey.pageUp) {
      nd = 0;
      moved = true;
    } else if (k == LogicalKeyboardKey.pageDown) {
      nd = lastDisplay;
      moved = true;
    }

    if (moved) {
      // Shift+move on a multi-mode extends the selection from the anchor;
      // a plain move sets a single selection (and resets the anchor).
      if (shift && widget._isMulti) {
        widget._isRowMode
            ? _selectRowAt(nd, toggle: false, range: true)
            : _selectCellAt(nd, nc, toggle: false, range: true);
      } else {
        if (widget._isRowMode) {
          _selectRowAt(nd, toggle: false, range: false);
        } else {
          _selectCellAt(nd, nc, toggle: false, range: false);
        }
      }
      return KeyEventResult.handled;
    }

    // toggle current with Space (multi) / commit with Enter
    if (k == LogicalKeyboardKey.space) {
      if (widget._isRowMode) {
        _selectRowAt(nd, toggle: widget._isMulti, range: false);
      } else {
        _selectCellAt(nd, nc, toggle: widget._isMulti, range: false);
      }
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      widget.onRowTap?.call(_order[nd]);
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

  Widget _sizedCell({required ReadableColumn col, required Widget child}) {
    return col.width != null ? SizedBox(width: col.width, child: child) : Expanded(flex: col.flex, child: child);
  }

  // ── build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final t = _t;
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
          if (widget.rows.isEmpty)
            _empty(t)
          else
            for (var d = 0; d < _order.length; d++) _row(t, d),
        ],
      ),
    );

    if (!widget._interactive) return table;

    return Focus(
      focusNode: _focus,
      onKeyEvent: _onKey,
      child: GestureDetector(
        onTap: () => _focus.requestFocus(),
        behavior: HitTestBehavior.opaque,
        child: table,
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
          for (var c = 0; c < widget.columns.length; c++) _headerCell(t, c),
        ],
      ),
    );
  }

  Widget _headerCell(EditableTableThemeData t, int c) {
    final col = widget.columns[c];
    final sorted = _sortCol == c;
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
            sorted
                ? (_sortAsc ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded)
                : Icons.unfold_more_rounded,
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
          onTap: () => _toggleSort(c),
          child: content,
        ),
      );
    }

    return _sizedCell(col: col, child: content);
  }

  Widget _row(EditableTableThemeData t, int display) {
    final orig = _order[display];
    final cells = widget.rows[orig];
    final hovered = widget.hoverHighlight && _hovered == display;
    final rowSelected = widget._isRowMode && _rowSelected(orig);
    final isActive = widget._interactive && _focus.hasFocus && _activeDisplay == display;

    Color bg;
    if (rowSelected) {
      bg = t.selectionFill(0.12);
    } else if (hovered) {
      bg = t.hover;
    } else if (widget.zebra && display.isOdd) {
      bg = Color.alphaBlend(t.bg.withOpacity(0.5), t.surface);
    } else {
      bg = t.surface;
    }

    final clickable = widget.onRowTap != null || widget._interactive;

    Widget rowWidget = Container(
      constraints: BoxConstraints(minHeight: widget.rowMinHeight),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: BorderSide(color: t.border),
          left: widget._isRowMode && rowSelected
              ? const BorderSide(color: EditableTableThemeData.accent, width: 2)
              : BorderSide.none,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var ci = 0; ci < widget.columns.length; ci++)
            _bodyCell(t, display, orig, ci, ci < cells.length ? cells[ci] : const SizedBox.shrink(), isActive),
        ],
      ),
    );

    // Row-level pointer handling (row modes + plain onRowTap).
    if (widget._isCellMode) {
      // cell modes attach taps per-cell; only manage hover at row level
    } else if (clickable) {
      rowWidget = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _focus.requestFocus();
          if (widget._isRowMode) {
            _selectRowAt(display, toggle: _modPressed(), range: _shiftPressed());
          }
          widget.onRowTap?.call(orig);
        },
        child: rowWidget,
      );
    }

    if (widget.hoverHighlight || clickable) {
      rowWidget = MouseRegion(
        cursor: clickable ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _hovered = display),
        onExit: (_) => setState(() => _hovered = _hovered == display ? -1 : _hovered),
        child: rowWidget,
      );
    }
    return rowWidget;
  }

  Widget _bodyCell(EditableTableThemeData t, int display, int orig, int ci, Widget child, bool rowActive) {
    final col = widget.columns[ci];
    final cellSelected = widget._isCellMode && _cellSelected(orig, ci);
    final cellActive = widget._isCellMode && rowActive && _activeCol == ci;

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
      child: Align(alignment: _alignment(col.align), child: child),
    );

    if (widget._isCellMode) {
      box = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _focus.requestFocus();
          _selectCellAt(display, ci, toggle: _modPressed(), range: _shiftPressed());
          widget.onRowTap?.call(orig);
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
          Text(
            'No rows',
            style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 13, color: t.fg3),
          ),
    );
  }

  // ── shortcut cheatsheet ────────────────────────────────────
  void _showShortcuts() {
    final t = _t;
    final cell = widget._isCellMode;
    final multi = widget._isMulti;
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
      builder: (ctx) {
        return Center(
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
                          fontFamily: EditableTableThemeData.displayFont,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: t.fg1)),
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
                                style: TextStyle(
                                    fontFamily: EditableTableThemeData.monoFont, fontSize: 11.5, color: t.fg2)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(r[1],
                                style: TextStyle(
                                    fontFamily: EditableTableThemeData.bodyFont, fontSize: 13, color: t.fg1)),
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
                                fontFamily: EditableTableThemeData.bodyFont,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _modLabel() {
    final isApple = defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.iOS;
    return isApple ? '⌘' : 'Ctrl';
  }
}
