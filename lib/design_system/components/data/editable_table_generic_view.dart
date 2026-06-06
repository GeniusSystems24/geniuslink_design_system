// ============================================================
// EditableTable — GENERIC ROW TYPE  (View).
// ------------------------------------------------------------
// The `EditableTable<T>` widget: a thin render of an
// `EditableTableController<T>`. Inline editing (text / number / date / select /
// checkbox), click-to-sort, drag-to-resize + long-press-to-reorder columns,
// TSV copy, full keyboard navigation (RTL-mirrored) and scroll-on-focus.
//
// Reuses the shared table theme (`EditableTableThemeData`) and the
// direction-aware keyboard helper (`horizontalStep`).
//
//   File: lib/design_system/components/data/editable_table_generic_view.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../key_directions.dart';
import 'editable_table_theme.dart';
import 'editable_table_generic.dart';

class EditableTable<T> extends StatefulWidget {
  /// Provide columns + rows (widget owns a controller) …
  final List<EditableColumn<T>>? columns;
  final List<T>? rows;

  /// … or pass a [controller] to drive / observe it externally.
  final EditableTableController<T>? controller;

  /// Blank-row factory — enables the Add (+) action and Tab-to-grow.
  final T Function()? newRow;

  /// Emitted on every data change (edit / add / delete / sort).
  final ValueChanged<List<T>>? onChanged;

  final bool showToolbar;
  final bool showRowNumbers;
  final bool showActions;
  final bool showTotals;
  final String totalsLabel;
  final bool growOnTab;

  /// Fixed height of the scrollable body region.
  final double bodyHeight;

  const EditableTable({
    super.key,
    this.columns,
    this.rows,
    this.controller,
    this.newRow,
    this.onChanged,
    this.showToolbar = true,
    this.showRowNumbers = true,
    this.showActions = true,
    this.showTotals = true,
    this.totalsLabel = 'Total',
    this.growOnTab = true,
    this.bodyHeight = 380,
  }) : assert(columns != null || controller != null, 'Provide columns or a controller.');

  @override
  State<EditableTable<T>> createState() => _EditableTableState<T>();
}

class _EditableTableState<T> extends State<EditableTable<T>> {
  late EditableTableController<T> _controller;
  bool _ownsController = false;

  final FocusNode _gridFocus = FocusNode(debugLabel: 'EditableTable.grid');
  final ScrollController _hScroll = ScrollController();
  final ScrollController _vScroll = ScrollController();
  final GlobalKey _activeKey = GlobalKey();
  CellRef? _lastSel;
  List<T>? _lastRows;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        EditableTableController<T>(columns: widget.columns!, rows: widget.rows ?? const [], newRow: widget.newRow);
    _ownsController = widget.controller == null;
    _controller.addListener(_onModel);
    _lastSel = _controller.selection;
    _lastRows = _controller.rows;
  }

  @override
  void didUpdateWidget(covariant EditableTable<T> old) {
    super.didUpdateWidget(old);
    if (widget.controller != null && widget.controller != _controller) {
      _controller.removeListener(_onModel);
      if (_ownsController) _controller.dispose();
      _controller = widget.controller!;
      _ownsController = false;
      _controller.addListener(_onModel);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onModel);
    if (_ownsController) _controller.dispose();
    _gridFocus.dispose();
    _hScroll.dispose();
    _vScroll.dispose();
    super.dispose();
  }

  void _onModel() {
    if (!mounted) return;
    setState(() {});
    // notify host of data changes
    if (widget.onChanged != null && !_sameRows(_controller.rows, _lastRows)) {
      _lastRows = _controller.rows;
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onChanged!(_controller.rows));
    }
    // scroll the active cell into view when the cursor moves
    if (_controller.selection != _lastSel) {
      _lastSel = _controller.selection;
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureActiveVisible());
    }
  }

  bool _sameRows(List<T> a, List<T>? b) {
    if (b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i])) return false;
    }
    return true;
  }

  void _ensureActiveVisible() {
    final ctx = _activeKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx,
        alignment: 0.5, alignmentPolicy: ScrollPositionAlignmentPolicy.explicit, duration: const Duration(milliseconds: 120));
  }

  EditableTableThemeData get _t => EditableTableThemeData.of(context);

  double get _totalWidth {
    var w = 0.0;
    if (widget.showRowNumbers) w += EditableTableThemeData.gutterWidth;
    for (var v = 0; v < _controller.colCount; v++) {
      w += _controller.widthOf(v);
    }
    if (widget.showActions) w += EditableTableThemeData.actionsWidth;
    return w;
  }

  // ════════ keyboard ════════
  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final c = _controller;
    final k = e.logicalKey;
    final dir = Directionality.of(context);
    final meta = HardwareKeyboard.instance.isMetaPressed || HardwareKeyboard.instance.isControlPressed;
    final shift = HardwareKeyboard.instance.isShiftPressed;

    if (c.editing) return KeyEventResult.ignored; // the field handles its own keys

    if (meta) {
      final low = k.keyLabel.toLowerCase();
      if (low == 'c') {
        c.copySelectionToClipboard();
        return KeyEventResult.handled;
      }
      if (low == 'z') {
        shift ? c.redo() : c.undo();
        return KeyEventResult.handled;
      }
      if (low == 'y') {
        c.redo();
        return KeyEventResult.handled;
      }
      if (k == LogicalKeyboardKey.enter) {
        c.addRow();
        return KeyEventResult.handled;
      }
      if (k == LogicalKeyboardKey.backspace || k == LogicalKeyboardKey.delete) {
        c.deleteSelectedRow();
        return KeyEventResult.handled;
      }
      if (k == LogicalKeyboardKey.home) {
        c.select(0, 0);
        return KeyEventResult.handled;
      }
      if (k == LogicalKeyboardKey.end) {
        c.select(c.rowCount - 1, c.colCount - 1);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    final step = horizontalStep(k, dir);
    if (step != 0) {
      c.moveSelection(0, step);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowDown) {
      c.moveSelection(1, 0);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowUp) {
      c.moveSelection(-1, 0);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.tab) {
      final s = shift ? -1 : 1;
      c.moveSelection(0, dir == TextDirection.rtl ? -s : s, grow: !shift && widget.growOnTab);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.home) {
      c.select(c.selection.row, 0);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.end) {
      c.select(c.selection.row, c.colCount - 1);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.f2) {
      _activateActive();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.space) {
      final col = c.columns[c.selection.col];
      if (col.type == EditableColumnType.checkbox) {
        c.toggleCheckbox(c.selection.row, c.selection.col);
        return KeyEventResult.handled;
      }
    }
    if (k == LogicalKeyboardKey.backspace || k == LogicalKeyboardKey.delete) {
      c.clearCell(c.selection.row, c.selection.col);
      return KeyEventResult.handled;
    }
    // type-to-edit (printable single char)
    final ch = e.character;
    if (ch != null && ch.length == 1 && ch.codeUnitAt(0) >= 32 && !meta) {
      final col = c.columns[c.selection.col];
      if (col.editableInline) {
        c.beginEdit(initial: ch);
        return KeyEventResult.handled;
      }
      if (col.type == EditableColumnType.select) {
        _activateActive();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void _activateActive() {
    final c = _controller;
    final col = c.columns[c.selection.col];
    if (col.type == EditableColumnType.checkbox) {
      c.toggleCheckbox(c.selection.row, c.selection.col);
    } else if (col.type == EditableColumnType.select) {
      _openSelectMenu(c.selection.row, c.selection.col);
    } else if (col.editableInline) {
      c.beginEdit();
    }
  }

  Future<void> _openSelectMenu(int r, int ci) async {
    final c = _controller;
    final col = c.columns[ci];
    c.select(r, ci);
    final box = _activeKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;
    final pos = RelativeRect.fromRect(
      Rect.fromPoints(box.localToGlobal(Offset.zero, ancestor: overlay),
          box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay)),
      Offset.zero & overlay.size,
    );
    final picked = await showMenu<String>(
      context: context,
      position: pos,
      items: [for (final o in col.options) PopupMenuItem<String>(value: o, height: 38, child: Text(o))],
    );
    if (picked != null) c.writeCell(r, ci, picked);
    _gridFocus.requestFocus();
  }

  // ════════ build ════════
  @override
  Widget build(BuildContext context) {
    final t = _t;
    return EditableTableScope<T>(
      controller: _controller,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showToolbar) _toolbar(t),
          if (widget.showToolbar) const SizedBox(height: 10),
          Focus(
            focusNode: _gridFocus,
            onKeyEvent: _onKey,
            child: GestureDetector(
              onTap: () => _gridFocus.requestFocus(),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: t.borderStrong),
                  borderRadius: BorderRadius.circular(EditableTableThemeData.radiusMd),
                ),
                clipBehavior: Clip.antiAlias,
                child: Scrollbar(
                  controller: _hScroll,
                  child: SingleChildScrollView(
                    controller: _hScroll,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: _totalWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _headerRow(t),
                          SizedBox(
                            height: widget.bodyHeight,
                            child: Scrollbar(
                              controller: _vScroll,
                              child: SingleChildScrollView(
                                controller: _vScroll,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (var r = 0; r < _controller.rowCount; r++) _dataRow(t, r),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (widget.showTotals) _footerRow(t),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── toolbar ──
  Widget _toolbar(EditableTableThemeData t) {
    return Row(
      children: [
        _tbBtn(t, Icons.add_rounded, 'Add row', _controller.newRow == null ? null : () => _controller.addRow()),
        const SizedBox(width: 6),
        _tbBtn(t, Icons.copy_all_rounded, 'Copy selection (⌘C)', () => _controller.copySelectionToClipboard()),
        const Spacer(),
        _tbBtn(t, Icons.undo_rounded, 'Undo (⌘Z)', _controller.canUndo ? _controller.undo : null),
        const SizedBox(width: 6),
        _tbBtn(t, Icons.redo_rounded, 'Redo (⌘⇧Z)', _controller.canRedo ? _controller.redo : null),
      ],
    );
  }

  Widget _tbBtn(EditableTableThemeData t, IconData icon, String tip, VoidCallback? onTap) {
    final enabled = onTap != null;
    return Tooltip(
      message: tip,
      child: Material(
        color: t.surface,
        borderRadius: BorderRadius.circular(EditableTableThemeData.radiusSm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(EditableTableThemeData.radiusSm),
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: t.border),
              borderRadius: BorderRadius.circular(EditableTableThemeData.radiusSm),
            ),
            child: Icon(icon, size: 16, color: enabled ? t.fg2 : t.fg4),
          ),
        ),
      ),
    );
  }

  // ── header ──
  Widget _headerRow(EditableTableThemeData t) {
    final cells = <Widget>[];
    if (widget.showRowNumbers) {
      cells.add(Container(
        width: EditableTableThemeData.gutterWidth,
        height: EditableTableThemeData.headerHeight,
        decoration: BoxDecoration(
          color: t.bg,
          border: Border(right: BorderSide(color: t.border), bottom: BorderSide(color: t.borderStrong)),
        ),
      ));
    }
    for (var v = 0; v < _controller.colCount; v++) {
      cells.add(_columnHeader(t, v));
    }
    if (widget.showActions) {
      cells.add(Container(
        width: EditableTableThemeData.actionsWidth,
        height: EditableTableThemeData.headerHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: t.bg,
          border: Border(left: BorderSide(color: t.border), bottom: BorderSide(color: t.borderStrong)),
        ),
        child: Text('ACTIONS',
            style: TextStyle(
                fontFamily: EditableTableThemeData.bodyFont,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: t.fg3)),
      ));
    }
    return Row(children: cells);
  }

  Widget _columnHeader(EditableTableThemeData t, int v) {
    final li = _controller.logicalColumnAt(v);
    final col = _controller.columns[li];
    final width = _controller.widthOf(v);
    final sorted = _controller.sortColumn == li && _controller.sortDir != SortDir.none;
    final active = _controller.selection.col == li;

    Widget inner() => Material(
          color: active ? t.selectionFill() : t.bg,
          child: InkWell(
            onTap: () => _controller.sortByColumn(li),
            child: Container(
              width: width,
              height: EditableTableThemeData.headerHeight,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.borderStrong))),
              child: Row(
                mainAxisAlignment: col.align == CellAlign.end ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      '${EditableTableFormat.columnLetter(v)} · ${col.label}${col.required ? ' *' : ''}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontFamily: EditableTableThemeData.bodyFont,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: active ? EditableTableThemeData.accent : t.fg3),
                    ),
                  ),
                  if (sorted)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(_controller.sortDir == SortDir.asc ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 11, color: EditableTableThemeData.accent),
                    ),
                ],
              ),
            ),
          ),
        );

    final draggable = LongPressDraggable<int>(
      data: v,
      axis: Axis.horizontal,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: width,
          height: EditableTableThemeData.headerHeight,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: t.surface,
            border: Border.all(color: EditableTableThemeData.accent),
            borderRadius: BorderRadius.circular(EditableTableThemeData.radiusSm),
            boxShadow: EditableTableThemeData.popShadow,
          ),
          child: Text(col.label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontFamily: EditableTableThemeData.bodyFont, fontSize: 11, fontWeight: FontWeight.w700, color: t.fg1)),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: inner()),
      child: inner(),
    );

    return SizedBox(
      width: width,
      child: DragTarget<int>(
        onWillAcceptWithDetails: (d) => d.data != v,
        onAcceptWithDetails: (d) => _controller.moveColumn(d.data, v),
        builder: (ctx, cand, rej) => Stack(
          children: [
            draggable,
            if (cand.isNotEmpty)
              PositionedDirectional(top: 0, bottom: 0, start: 0, width: 3, child: Container(color: EditableTableThemeData.accent)),
            PositionedDirectional(top: 0, bottom: 0, end: -5, width: 11, child: _resizeHandle(t, v)),
          ],
        ),
      ),
    );
  }

  Widget _resizeHandle(EditableTableThemeData t, int v) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onDoubleTap: () => _controller.resetColumnWidth(v),
        onHorizontalDragUpdate: (d) {
          final rtl = Directionality.of(context) == TextDirection.rtl;
          _controller.resizeColumn(v, rtl ? -d.delta.dx : d.delta.dx);
        },
        child: Center(
          child: Container(
            width: 2,
            height: EditableTableThemeData.headerHeight * 0.6,
            decoration: BoxDecoration(
              color: _controller.hasWidthOverride(v) ? EditableTableThemeData.accent : t.borderStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  // ── data row ──
  Widget _dataRow(EditableTableThemeData t, int r) {
    final selRow = _controller.selection.row == r;
    final cells = <Widget>[];
    if (widget.showRowNumbers) {
      cells.add(Container(
        width: EditableTableThemeData.gutterWidth,
        height: EditableTableThemeData.rowHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selRow ? t.selectionFill() : t.bg,
          border: Border(right: BorderSide(color: t.borderStrong), bottom: BorderSide(color: t.border)),
        ),
        child: Text('${r + 1}',
            style: TextStyle(
                fontFamily: EditableTableThemeData.monoFont,
                fontSize: 11,
                fontWeight: selRow ? FontWeight.w700 : FontWeight.w400,
                color: selRow ? EditableTableThemeData.accent : t.fg3)),
      ));
    }
    for (var v = 0; v < _controller.colCount; v++) {
      cells.add(_dataCell(t, r, v));
    }
    if (widget.showActions) {
      cells.add(Container(
        width: EditableTableThemeData.actionsWidth,
        height: EditableTableThemeData.rowHeight,
        decoration: BoxDecoration(
          color: selRow ? t.selectionFill(0.06) : t.surface,
          border: Border(bottom: BorderSide(color: t.border)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _rowAct(t, Icons.content_copy_rounded, 'Duplicate', () => _controller.duplicateRowAt(r)),
            _rowAct(t, Icons.delete_outline_rounded, 'Delete', () => _controller.deleteRowAt(r), danger: true),
          ],
        ),
      ));
    }
    return Row(children: cells);
  }

  Widget _rowAct(EditableTableThemeData t, IconData icon, String tip, VoidCallback onTap, {bool danger = false}) {
    return Tooltip(
      message: tip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(EditableTableThemeData.radiusSm),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, size: 15, color: danger ? EditableTableThemeData.danger : t.fg3),
        ),
      ),
    );
  }

  Widget _dataCell(EditableTableThemeData t, int r, int v) {
    final ci = _controller.logicalColumnAt(v);
    final col = _controller.columns[ci];
    final width = _controller.widthOf(v);
    final active = _controller.isSelected(r, ci);
    final editing = active && _controller.editing;
    final raw = _controller.cellText(r, ci);
    final invalid = col.errorFor(raw, _controller.rowAt(r)) != null;
    final alignEnd = col.align == CellAlign.end;

    Widget content;
    if (editing && col.editableInline) {
      content = _CellEditor(
        key: ValueKey('edit-$r-$ci'),
        initial: _controller.draft,
        mono: col.mono,
        alignEnd: alignEnd,
        theme: t,
        onChanged: _controller.setDraft,
        onCommit: (move) {
          final rtl = Directionality.of(context) == TextDirection.rtl;
          if (move == _EditMove.down) {
            _controller.commitEdit(moveDr: 1);
          } else if (move == _EditMove.next) {
            _controller.commitEdit(moveDc: rtl ? -1 : 1, grow: widget.growOnTab);
          } else {
            _controller.commitEdit();
          }
          _gridFocus.requestFocus();
        },
        onCancel: () {
          _controller.cancelEdit();
          _gridFocus.requestFocus();
        },
      );
    } else if (col.cellBuilder != null) {
      content = col.cellBuilder!(
        context,
        EditableCellData<T>(
          row: r,
          col: ci,
          value: raw,
          rowData: _controller.rowAt(r),
          column: col,
          selected: active,
          invalid: invalid,
          requestEdit: () {
            _controller.select(r, ci);
            _activateActive();
          },
        ),
      );
    } else if (col.type == EditableColumnType.checkbox) {
      content = _checkboxCell(t, r, ci, raw);
    } else {
      content = Text(
        col.type == EditableColumnType.select && raw.isEmpty ? '—' : raw,
        overflow: TextOverflow.ellipsis,
        textAlign: alignEnd ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          fontFamily: col.mono ? EditableTableThemeData.monoFont : EditableTableThemeData.bodyFont,
          fontStyle: col.type == EditableColumnType.computed ? FontStyle.italic : FontStyle.normal,
          fontSize: 12.5,
          color: raw.isEmpty ? t.fg4 : (col.isReadOnly ? t.fg3 : t.fg1),
        ),
      );
    }

    final cell = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _gridFocus.requestFocus();
        if (active && !editing) {
          _activateActive();
        } else {
          _controller.select(r, ci);
        }
      },
      onDoubleTap: () {
        _controller.select(r, ci);
        _activateActive();
      },
      child: Container(
        width: width,
        height: EditableTableThemeData.rowHeight,
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        padding: editing ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: active ? t.selectionFill() : t.surface,
          border: Border(right: BorderSide(color: t.border), bottom: BorderSide(color: t.border)),
        ),
        foregroundDecoration: active
            ? BoxDecoration(border: Border.all(color: EditableTableThemeData.accent, width: 1.5))
            : (invalid ? BoxDecoration(border: Border.all(color: EditableTableThemeData.danger)) : null),
        child: content,
      ),
    );
    return active ? KeyedSubtree(key: _activeKey, child: cell) : cell;
  }

  Widget _checkboxCell(EditableTableThemeData t, int r, int ci, String raw) {
    final on = EditableTableController.truthy(raw);
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => _controller.toggleCheckbox(r, ci),
        child: Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? EditableTableThemeData.accent : Colors.transparent,
            border: Border.all(color: on ? EditableTableThemeData.accent : t.borderStrong, width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: on ? const Icon(Icons.check_rounded, size: 13, color: Colors.white) : null,
        ),
      ),
    );
  }

  // ── footer (totals) ──
  Widget _footerRow(EditableTableThemeData t) {
    final cells = <Widget>[];
    if (widget.showRowNumbers) {
      cells.add(Container(
        width: EditableTableThemeData.gutterWidth,
        height: EditableTableThemeData.footerHeight,
        decoration: BoxDecoration(color: t.bg, border: Border(top: BorderSide(color: t.borderStrong, width: 1.5))),
      ));
    }
    for (var v = 0; v < _controller.colCount; v++) {
      final col = _controller.columnAt(v);
      final width = _controller.widthOf(v);
      var label = v == 0 ? widget.totalsLabel : '';
      if (col.includeInTotal) label = EditableTableFormat.formatNumber(_controller.columnTotal(col));
      cells.add(Container(
        width: width,
        height: EditableTableThemeData.footerHeight,
        alignment: col.align == CellAlign.end ? Alignment.centerRight : Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: t.bg,
          border: Border(top: BorderSide(color: t.borderStrong, width: 1.5), right: BorderSide(color: t.border)),
        ),
        child: Text(label,
            style: TextStyle(
                fontFamily: col.includeInTotal ? EditableTableThemeData.monoFont : EditableTableThemeData.bodyFont,
                fontSize: col.includeInTotal ? 12.5 : 10,
                fontWeight: FontWeight.w700,
                letterSpacing: col.includeInTotal ? 0 : 0.5,
                color: col.includeInTotal ? t.fg1 : t.fg3)),
      ));
    }
    if (widget.showActions) {
      cells.add(Container(
        width: EditableTableThemeData.actionsWidth,
        height: EditableTableThemeData.footerHeight,
        decoration: BoxDecoration(color: t.bg, border: Border(top: BorderSide(color: t.borderStrong, width: 1.5))),
      ));
    }
    return Row(children: cells);
  }
}

enum _EditMove { none, down, next }

/// Inline single-line editor for a text / number / date cell.
class _CellEditor extends StatefulWidget {
  final String initial;
  final bool mono;
  final bool alignEnd;
  final EditableTableThemeData theme;
  final ValueChanged<String> onChanged;
  final ValueChanged<_EditMove> onCommit;
  final VoidCallback onCancel;
  const _CellEditor({
    super.key,
    required this.initial,
    required this.mono,
    required this.alignEnd,
    required this.theme,
    required this.onChanged,
    required this.onCommit,
    required this.onCancel,
  });
  @override
  State<_CellEditor> createState() => _CellEditorState();
}

class _CellEditorState extends State<_CellEditor> {
  late final TextEditingController _tc;
  late final FocusNode _fn;

  @override
  void initState() {
    super.initState();
    _tc = TextEditingController(text: widget.initial);
    _tc.selection = TextSelection.collapsed(offset: _tc.text.length);
    _fn = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fn.requestFocus());
  }

  @override
  void dispose() {
    _tc.dispose();
    _fn.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode n, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    if (e.logicalKey == LogicalKeyboardKey.escape) {
      widget.onCancel();
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.tab) {
      widget.onChanged(_tc.text);
      widget.onCommit(_EditMove.next);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Focus(
      onKeyEvent: _onKey,
      child: TextField(
        controller: _tc,
        focusNode: _fn,
        onChanged: widget.onChanged,
        onSubmitted: (_) {
          widget.onChanged(_tc.text);
          widget.onCommit(_EditMove.down);
        },
        textAlign: widget.alignEnd ? TextAlign.right : TextAlign.left,
        cursorColor: EditableTableThemeData.accent,
        style: TextStyle(
            fontFamily: widget.mono ? EditableTableThemeData.monoFont : EditableTableThemeData.bodyFont,
            fontSize: 12.5,
            color: t.fg1),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: t.inputBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
          border: const OutlineInputBorder(borderSide: BorderSide.none),
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide.none),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
