// ============================================================
// EditableTable — VIEW.
// ------------------------------------------------------------
// A thin, customisable render of EditableTableController. Holds no business
// logic: every gesture and keystroke is forwarded to the controller, and the
// widget rebuilds from its state. Excel-style editing — click to select, type
// to overwrite, Enter ↓ / Tab →, ⌘C/⌘X/⌘V, ⌘Z undo/redo, click a header to
// sort, an optional per-row actions column and a totals footer.
//
//   // self-contained (owns a controller built from columns):
//   EditableTable(columns: myCols, initialRows: seed)
//
//   // host-driven (share/observe the controller):
//   EditableTable(controller: myController)
//
//   File: lib/design_system/components/data/editable_table.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'editable_table_models.dart';
import 'editable_table_columns.dart';
import 'editable_table_controller.dart';
import 'editable_table_theme.dart';

class EditableTable extends StatefulWidget {
  /// Column schema. Required when [controller] is null.
  final List<EditableColumn>? columns;

  /// Initial data when this widget owns its controller.
  final List<EditableRow>? initialRows;

  /// Drive/observe from outside. When null the widget owns a private one
  /// (built from [columns] + [initialRows]).
  final EditableTableController? controller;

  /// Toolbar with the validation badge, clipboard hint and undo/redo.
  final bool showToolbar;

  /// Leading row-number gutter (A1-style).
  final bool showRowNumbers;

  /// Trailing actions column (insert-below + delete per row).
  final bool showActions;

  /// Totals footer summing every column flagged [EditableColumn.includeInTotal].
  final bool showTotals;

  /// Label shown in the footer's first cell.
  final String totalsLabel;

  /// Optional unit suffix shown under the grid (e.g. "SAR").
  final String? unitLabel;

  /// Show a confirmation popup before deleting a row (delete button, context
  /// menu, and ⌘/Ctrl+Delete). When false, rows delete immediately.
  final bool confirmDelete;

  /// Pressing Tab on the very last cell appends a new row and jumps into it.
  /// Set false to keep Tab clamped at the grid's end.
  final bool growOnTab;

  /// Show the “?” keyboard-shortcuts reference button in the toolbar.
  final bool showShortcutsHelp;

  /// Notified with the full row set whenever the data changes.
  final ValueChanged<List<EditableRow>>? onChanged;

  const EditableTable({
    super.key,
    this.columns,
    this.initialRows,
    this.controller,
    this.showToolbar = true,
    this.showRowNumbers = true,
    this.showActions = true,
    this.showTotals = false,
    this.totalsLabel = 'Total',
    this.unitLabel,
    this.confirmDelete = true,
    this.growOnTab = true,
    this.showShortcutsHelp = true,
    this.onChanged,
  }) : assert(columns != null || controller != null, 'Provide columns or a controller.');

  @override
  State<EditableTable> createState() => _EditableTableState();
}

class _EditableTableState extends State<EditableTable> {
  late EditableTableController _controller;
  bool _ownsController = false;

  final FocusNode _gridFocus = FocusNode(debugLabel: 'EditableTable.grid');
  final FocusNode _editFocus = FocusNode(debugLabel: 'EditableTable.editor');
  final TextEditingController _text = TextEditingController();
  final ScrollController _hScroll = ScrollController();

  bool _wasEditing = false;
  String _lastSignature = '';
  CellRef? _lastSel;

  /// Stamped on whichever cell is currently selected so we can scroll it into
  /// view (both axes) after a keyboard / programmatic move.
  final GlobalKey _activeCellKey = GlobalKey();

  EditableTableThemeData get _t => EditableTableThemeData.of(context);

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        EditableTableController(columns: widget.columns!, rows: widget.initialRows);
    _ownsController = widget.controller == null;
    _controller.addListener(_syncEditor);
    _lastSignature = _signature();
  }

  @override
  void didUpdateWidget(covariant EditableTable old) {
    super.didUpdateWidget(old);
    if (widget.controller != null && widget.controller != _controller) {
      _controller.removeListener(_syncEditor);
      if (_ownsController) _controller.dispose();
      _controller = widget.controller!;
      _ownsController = false;
      _controller.addListener(_syncEditor);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_syncEditor);
    if (_ownsController) _controller.dispose();
    _gridFocus.dispose();
    _editFocus.dispose();
    _text.dispose();
    _hScroll.dispose();
    super.dispose();
  }

  // Seed the editing field when an edit session opens; emit data changes.
  void _syncEditor() {
    if (_controller.editing && !_wasEditing) {
      _text.text = _controller.draft;
      _text.selection = TextSelection.collapsed(offset: _text.text.length);
      WidgetsBinding.instance.addPostFrameCallback((_) => _editFocus.requestFocus());
    }
    _wasEditing = _controller.editing;

    // Scroll a freshly-selected cell fully into view (horizontal via our own
    // SingleChildScrollView, vertical via any enclosing scrollable).
    if (_controller.selection != _lastSel) {
      _lastSel = _controller.selection;
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealActiveCell());
    }

    final sig = _signature();
    if (sig != _lastSignature) {
      _lastSignature = sig;
      widget.onChanged?.call(_controller.rows);
    }
  }

  /// Brings the selected cell fully on-screen. `Scrollable.ensureVisible`
  /// walks up every enclosing scrollable, so one pair of calls handles the
  /// inner horizontal scroller AND an outer vertical list. Calling it with
  /// both alignment policies scrolls the minimum amount needed (no jump when
  /// the cell is already visible).
  void _revealActiveCell() {
    final ctx = _activeCellKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
    );
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
  }

  String _signature() => _controller.rows.map((r) => r.values.join('\u0001')).join('\u0002');

  // ── keyboard (navigation mode) ─────────────────────────────
  KeyEventResult _onGridKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final c = _controller;
    if (c.editing) return KeyEventResult.ignored;
    final k = event.logicalKey;
    final mod = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
    final shift = HardwareKeyboard.instance.isShiftPressed;

    if (mod) {
      if (k == LogicalKeyboardKey.keyZ) {
        shift ? c.redo() : c.undo();
        return KeyEventResult.handled;
      }
      if (k == LogicalKeyboardKey.keyY) {
        c.redo();
        return KeyEventResult.handled;
      }
      if (k == LogicalKeyboardKey.keyC) {
        c.copyCell();
        return KeyEventResult.handled;
      }
      if (k == LogicalKeyboardKey.keyX) {
        if (!c.columns[c.selection.col].isReadOnly) c.copyCell(cut: true);
        return KeyEventResult.handled;
      }
      if (k == LogicalKeyboardKey.keyV) {
        if (!c.columns[c.selection.col].isReadOnly) c.pasteCell();
        return KeyEventResult.handled;
      }
      if (k == LogicalKeyboardKey.keyD) {
        c.duplicateSelectedRow();
        return KeyEventResult.handled;
      }
      if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
        c.addRow();
        return KeyEventResult.handled;
      }
      if (k == LogicalKeyboardKey.backspace || k == LogicalKeyboardKey.delete) {
        _maybeDelete(c.selection.row);
        return KeyEventResult.handled;
      }
      if (k == LogicalKeyboardKey.home) return _nav(() => c.select(0, 0));
      if (k == LogicalKeyboardKey.end) return _nav(() => c.select(c.rowCount - 1, c.colCount - 1));
      if (k == LogicalKeyboardKey.slash) {
        _showShortcuts();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (k == LogicalKeyboardKey.arrowUp) return _nav(() => c.moveSelection(-1, 0));
    if (k == LogicalKeyboardKey.arrowDown) return _nav(() => c.moveSelection(1, 0));
    if (k == LogicalKeyboardKey.arrowLeft) return _nav(() => c.moveSelection(0, -1));
    if (k == LogicalKeyboardKey.arrowRight) return _nav(() => c.moveSelection(0, 1));
    if (k == LogicalKeyboardKey.home) return _nav(() => c.select(c.selection.row, 0));
    if (k == LogicalKeyboardKey.end) return _nav(() => c.select(c.selection.row, c.colCount - 1));
    if (k == LogicalKeyboardKey.tab) {
      return _nav(() => c.tabNext(grow: widget.growOnTab, backward: shift));
    }
    if (k == LogicalKeyboardKey.f2) {
      _activateSelected();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      _activateSelected();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.backspace || k == LogicalKeyboardKey.delete) {
      if (!c.columns[c.selection.col].isReadOnly) {
        c.writeCell(c.selection.row, c.selection.col, '');
      }
      return KeyEventResult.handled;
    }
    final ch = event.character;
    if (ch != null && ch.length == 1 && ch.trim().isNotEmpty) {
      final col = c.columns[c.selection.col];
      if (col.editableInline) {
        c.beginEdit(ch);
      } else if (col.type == EditableColumnType.select || col.type == EditableColumnType.color) {
        _activateSelected();
      }
      // readonly / computed — ignore typing
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _nav(VoidCallback fn) {
    fn();
    return KeyEventResult.handled;
  }

  void _commitMove(int dr, int dc, {bool grow = true}) {
    _controller.commit(dr: dr, dc: dc, move: true, grow: grow);
    _gridFocus.requestFocus();
  }

  void _cancel() {
    _controller.cancelEdit();
    _gridFocus.requestFocus();
  }

  // Opens the right editor for the selected cell by column kind.
  void _activateSelected() {
    final c = _controller;
    final col = c.columns[c.selection.col];
    if (col.isReadOnly) return; // readonly / computed — nothing to edit
    switch (col.type) {
      case EditableColumnType.select:
        _openSelectMenu(c.selection.row, c.selection.col);
        break;
      case EditableColumnType.color:
        _openColorMenu(c.selection.row, c.selection.col);
        break;
      default:
        c.beginEdit(); // text / number / date / time / combo
    }
  }

  Future<void> _openSelectMenu(int r, int col) async {
    final c = _controller;
    final column = c.columns[col];
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;
    // Anchor near the grid's top-left; good enough without per-cell geometry.
    final origin = box.localToGlobal(const Offset(80, 80), ancestor: overlay);
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(origin.dx, origin.dy, origin.dx + 1, origin.dy + 1),
      items: [
        for (final opt in column.options)
          PopupMenuItem<String>(
            value: opt,
            height: 38,
            child: Text(opt, style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 13, color: _t.fg1)),
          ),
      ],
    );
    if (selected != null) {
      c.select(r, col);
      c.writeCell(r, col, selected);
    }
    _gridFocus.requestFocus();
  }

  // ── color cell + picker ────────────────────────────────────
  Widget _colorCell(EditableTableThemeData t, String hex) {
    final c = _parseHex(hex);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: c ?? Colors.transparent,
            borderRadius: BorderRadius.circular(EditableTableThemeData.radiusSm),
            border: Border.all(color: t.borderStrong),
          ),
          child: c == null ? Icon(Icons.block, size: 12, color: t.fg4) : null,
        ),
        const SizedBox(width: 8),
        Text(
          hex.isEmpty ? '—' : hex.toUpperCase(),
          style: TextStyle(fontFamily: EditableTableThemeData.monoFont, fontSize: 12, color: hex.isEmpty ? t.fg4 : t.fg1),
        ),
      ],
    );
  }

  static Color? _parseHex(String hex) {
    var s = hex.trim().replaceAll('#', '');
    if (s.length == 6) s = 'FF$s';
    if (s.length != 8) return null;
    final v = int.tryParse(s, radix: 16);
    return v == null ? null : Color(v);
  }

  Future<void> _openColorMenu(int r, int col) async {
    final c = _controller;
    final column = c.columns[col];
    final swatches = column is ColorPickerColumn ? column.swatches : kEditableSwatches;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    final box = context.findRenderObject() as RenderBox?;
    if (overlay == null || box == null) return;
    final origin = box.localToGlobal(const Offset(80, 80), ancestor: overlay);
    final t = _t;
    final picked = await showMenu<String>(
      context: context,
      color: t.surface,
      position: RelativeRect.fromLTRB(origin.dx, origin.dy, origin.dx + 1, origin.dy + 1),
      items: [
        PopupMenuItem<String>(
          enabled: false,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: SizedBox(
            width: 180,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final hex in swatches)
                  _SwatchDot(hex: hex, onTap: () => Navigator.pop(context, hex)),
              ],
            ),
          ),
        ),
      ],
    );
    if (picked != null) {
      c.select(r, col);
      c.writeCell(r, col, picked.toUpperCase());
    }
    _gridFocus.requestFocus();
  }

  // ── combo suggestions (free text + pick) ───────────────────
  Future<void> _openComboMenu(EditableColumn col) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    final box = context.findRenderObject() as RenderBox?;
    if (overlay == null || box == null) return;
    final origin = box.localToGlobal(const Offset(80, 80), ancestor: overlay);
    final t = _t;
    final picked = await showMenu<String>(
      context: context,
      color: t.surface,
      position: RelativeRect.fromLTRB(origin.dx, origin.dy, origin.dx + 1, origin.dy + 1),
      items: [
        for (final opt in col.options)
          PopupMenuItem<String>(
            value: opt,
            height: 38,
            child: Text(opt, style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 13, color: t.fg1)),
          ),
      ],
    );
    if (picked != null) {
      _controller.updateDraft(picked);
      _controller.commit(); // write in place, end edit
    }
    _gridFocus.requestFocus();
  }

  // ── date / time pickers (assist the masked editors) ────────
  Future<void> _pickDate(EditableColumn col) async {
    final cur = EditableTemporal.parseDate(_text.text) ?? DateTime.now();
    final first = col is DateColumn ? (col.first ?? DateTime(1900)) : DateTime(1900);
    final last = col is DateColumn ? (col.last ?? DateTime(2100)) : DateTime(2100);
    final picked = await showDatePicker(
      context: context,
      initialDate: cur.isBefore(first) ? first : (cur.isAfter(last) ? last : cur),
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      _controller.updateDraft(EditableTemporal.formatDate(picked));
      _controller.commit();
    }
    _gridFocus.requestFocus();
  }

  Future<void> _pickTime() async {
    final parsed = EditableTemporal.parseTime(_text.text);
    final init = parsed == null ? TimeOfDay.now() : TimeOfDay(hour: parsed.$1, minute: parsed.$2);
    final picked = await showTimePicker(context: context, initialTime: init);
    if (picked != null) {
      _controller.updateDraft(EditableTemporal.formatTime(picked.hour, picked.minute));
      _controller.commit();
    }
    _gridFocus.requestFocus();
  }

  // ── build ──────────────────────────────────────────────────
  double get _totalWidth {
    var w = 0.0;
    if (widget.showRowNumbers) w += EditableTableThemeData.gutterWidth;
    for (final c in _controller.columns) {
      w += c.width;
    }
    if (widget.showActions) w += EditableTableThemeData.actionsWidth;
    return w;
  }

  @override
  Widget build(BuildContext context) {
    return EditableTableScope(
      controller: _controller,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _t;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showToolbar) _toolbar(t),
              Focus(
                focusNode: _gridFocus,
                onKeyEvent: _onGridKey,
                child: GestureDetector(
                  onTap: () => _gridFocus.requestFocus(),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: t.borderStrong),
                      borderRadius: BorderRadius.circular(EditableTableThemeData.radiusMd),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SingleChildScrollView(
                      controller: _hScroll,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: _totalWidth,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _header(t),
                            for (var r = 0; r < _controller.rowCount; r++) _row(t, r),
                            if (widget.showTotals) _footer(t),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _statusBar(t),
            ],
          );
        },
      ),
    );
  }

  // ── toolbar ────────────────────────────────────────────────
  Widget _toolbar(EditableTableThemeData t) {
    final invalid = _controller.invalidCount;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          if (invalid == 0)
            _pill('All valid', EditableTableThemeData.success, t)
          else
            _pill('$invalid required field${invalid > 1 ? 's' : ''} empty', EditableTableThemeData.danger, t),
          const SizedBox(width: 10),
          if (_controller.flash != null)
            Text(_controller.flash!,
                style: TextStyle(fontFamily: EditableTableThemeData.monoFont, fontSize: 11, color: t.fg3)),
          const Spacer(),
          if (widget.showShortcutsHelp) ...[
            _toolIcon(Icons.keyboard_outlined, 'Keyboard shortcuts (⌘/)', true, _showShortcuts, t),
            const SizedBox(width: 6),
          ],
          _toolIcon(Icons.undo_rounded, 'Undo (Ctrl+Z)', _controller.canUndo, _controller.undo, t),
          const SizedBox(width: 6),
          _toolIcon(Icons.redo_rounded, 'Redo (Ctrl+Shift+Z)', _controller.canRedo, _controller.redo, t),
        ],
      ),
    );
  }

  Widget _pill(String text, Color color, EditableTableThemeData t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.16),
          borderRadius: BorderRadius.circular(EditableTableThemeData.radiusLg),
        ),
        child: Text(text.toUpperCase(),
            style: TextStyle(
                fontFamily: EditableTableThemeData.bodyFont,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: color)),
      );

  Widget _toolIcon(IconData icon, String tip, bool enabled, VoidCallback onTap, EditableTableThemeData t) {
    return _HoverButton(
      enabled: enabled,
      tooltip: tip,
      builder: (hover) => Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: hover ? t.hover : t.inputBg,
          border: Border.all(color: t.border),
          borderRadius: BorderRadius.circular(EditableTableThemeData.radiusSm),
        ),
        child: Icon(icon, size: 16, color: enabled ? t.fg1 : t.fg4),
      ),
      onTap: enabled ? onTap : null,
    );
  }

  // ── header ─────────────────────────────────────────────────
  Widget _header(EditableTableThemeData t) {
    final cells = <Widget>[];
    if (widget.showRowNumbers) {
      cells.add(_headerCell(t, width: EditableTableThemeData.gutterWidth, child: const SizedBox()));
    }
    for (var ci = 0; ci < _controller.columns.length; ci++) {
      final col = _controller.columns[ci];
      final sorted = _controller.sortColumn == ci && _controller.sortDir != SortDir.none;
      cells.add(_headerCell(
        t,
        width: col.width,
        active: _controller.selection.col == ci,
        onTap: () => _controller.sortByColumn(ci),
        child: Row(
          mainAxisAlignment: col.align == CellAlign.end ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                '${EditableTableFormat.columnLetter(ci)} · ${col.label}${col.required ? ' *' : ''}',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontFamily: EditableTableThemeData.bodyFont,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: _controller.selection.col == ci ? EditableTableThemeData.accent : t.fg3),
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
      ));
    }
    if (widget.showActions) {
      cells.add(_headerCell(
        t,
        width: EditableTableThemeData.actionsWidth,
        center: true,
        child: Text('ACTIONS',
            style: TextStyle(
                fontFamily: EditableTableThemeData.bodyFont,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: t.fg3)),
      ));
    }
    return Container(
      height: EditableTableThemeData.headerHeight,
      decoration: BoxDecoration(
        color: t.bg,
        border: Border(bottom: BorderSide(color: t.borderStrong)),
      ),
      child: Row(children: cells),
    );
  }

  Widget _headerCell(EditableTableThemeData t,
      {required double width, required Widget child, bool active = false, bool center = false, VoidCallback? onTap}) {
    return SizedBox(
      width: width,
      child: Material(
        color: active ? t.selectionFill() : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          mouseCursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
          child: Container(
            alignment: center ? Alignment.center : Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: child,
          ),
        ),
      ),
    );
  }

  // ── data row ───────────────────────────────────────────────
  Widget _row(EditableTableThemeData t, int r) {
    final isSelRow = _controller.selection.row == r;
    final cells = <Widget>[];

    if (widget.showRowNumbers) {
      cells.add(GestureDetector(
        onTap: () {
          _controller.select(r, 0);
          _gridFocus.requestFocus();
        },
        child: Container(
          width: EditableTableThemeData.gutterWidth,
          height: EditableTableThemeData.rowHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelRow ? t.selectionFill() : t.bg,
            border: Border(
              right: BorderSide(color: t.borderStrong),
              bottom: BorderSide(color: t.border),
            ),
          ),
          child: Text('${r + 1}',
              style: TextStyle(
                  fontFamily: EditableTableThemeData.monoFont,
                  fontSize: 11,
                  fontWeight: isSelRow ? FontWeight.w700 : FontWeight.w400,
                  color: isSelRow ? EditableTableThemeData.accent : t.fg3)),
        ),
      ));
    }

    for (var ci = 0; ci < _controller.columns.length; ci++) {
      cells.add(_dataCell(t, r, ci));
    }

    if (widget.showActions) {
      cells.add(_actionsCell(t, r, isSelRow));
    }

    return GestureDetector(
      onSecondaryTapDown: (d) => _openRowMenu(r, d.globalPosition),
      onLongPressStart: (d) => _openRowMenu(r, d.globalPosition),
      child: Row(children: cells),
    );
  }

  Widget _dataCell(EditableTableThemeData t, int r, int ci) {
    final col = _controller.columns[ci];
    final active = _controller.isSelected(r, ci);
    final isEditing = active && _controller.editing;
    final value = _controller.cellValue(r, ci); // raw stored (for editing/validation)
    final shown = _controller.displayAt(r, ci); // resolves ComputedColumn
    final invalid = col.errorFor(value, _controller.rowMap(r)) != null;
    final alignEnd = col.align == CellAlign.end;

    final border = Border(
      right: BorderSide(color: t.border),
      bottom: BorderSide(color: t.border),
    );

    Widget content;
    if (isEditing) {
      content = _editor(t, col, alignEnd);
    } else if (col.cellBuilder != null) {
      content = col.cellBuilder!(
        context,
        EditableCellData(
          row: r,
          col: ci,
          value: shown,
          rowData: _controller.rowMap(r),
          column: col,
          selected: active,
          invalid: invalid,
          requestEdit: () {
            _controller.select(r, ci);
            _activateSelected();
          },
        ),
      );
    } else if (col.type == EditableColumnType.color) {
      content = _colorCell(t, shown);
    } else {
      content = Text(
        shown,
        overflow: TextOverflow.ellipsis,
        textAlign: alignEnd ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          fontFamily: col.mono ? EditableTableThemeData.monoFont : EditableTableThemeData.bodyFont,
          fontStyle: col.type == EditableColumnType.computed ? FontStyle.italic : FontStyle.normal,
          fontSize: 13,
          color: shown.isEmpty
              ? t.fg4
              : (col.isReadOnly ? t.fg3 : t.fg1),
        ),
      );
    }

    return GestureDetector(
      key: active ? _activeCellKey : null,
      onTap: () {
        _controller.select(r, ci);
        _gridFocus.requestFocus();
      },
      onDoubleTap: () {
        _controller.select(r, ci);
        _activateSelected();
      },
      child: MouseRegion(
        cursor: col.isReadOnly ? SystemMouseCursors.basic : SystemMouseCursors.cell,
        child: Container(
          width: col.width,
          height: EditableTableThemeData.rowHeight,
          alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
          padding: isEditing ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: active ? t.selectionFill() : t.surface,
            border: border,
          ),
          foregroundDecoration: active
              ? BoxDecoration(border: Border.all(color: EditableTableThemeData.accent, width: 2))
              : (invalid
                  ? BoxDecoration(border: Border.all(color: EditableTableThemeData.danger, width: 1))
                  : null),
          child: content,
        ),
      ),
    );
  }

  Widget _editor(EditableTableThemeData t, EditableColumn col, bool alignEnd) {
    // Per-kind keyboard + masking.
    final isNumber = col.type == EditableColumnType.number;
    final isDate = col.type == EditableColumnType.date;
    final isTime = col.type == EditableColumnType.time;

    final formatters = <TextInputFormatter>[
      if (isDate) DateInputFormatter(),
      if (isTime) TimeInputFormatter(),
    ];

    final keyboard = (isNumber || isDate || isTime)
        ? const TextInputType.numberWithOptions(decimal: true, signed: true)
        : TextInputType.text;

    // Suffix picker button for date / time / combo.
    Widget? suffix;
    if (isDate) {
      suffix = _editorSuffix(t, Icons.calendar_today_outlined, 'Pick a date', () => _pickDate(col));
    } else if (isTime) {
      suffix = _editorSuffix(t, Icons.schedule_outlined, 'Pick a time', _pickTime);
    } else if (col.type == EditableColumnType.combo) {
      suffix = _editorSuffix(t, Icons.arrow_drop_down_rounded, 'Suggestions', () => _openComboMenu(col));
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _cancel,
        const SingleActivator(LogicalKeyboardKey.enter): () => _commitMove(1, 0),
        const SingleActivator(LogicalKeyboardKey.numpadEnter): () => _commitMove(1, 0),
        const SingleActivator(LogicalKeyboardKey.tab): () => _commitMove(0, 1, grow: widget.growOnTab),
        const SingleActivator(LogicalKeyboardKey.tab, shift: true): () => _commitMove(0, -1),
      },
      child: TextField(
        controller: _text,
        focusNode: _editFocus,
        autofocus: true,
        inputFormatters: formatters,
        onChanged: _controller.updateDraft,
        onSubmitted: (_) => _commitMove(1, 0),
        onTapOutside: (_) => _commitMove(0, 0),
        keyboardType: keyboard,
        textAlign: alignEnd ? TextAlign.right : TextAlign.left,
        cursorColor: EditableTableThemeData.accent,
        style: TextStyle(
          fontFamily: col.mono ? EditableTableThemeData.monoFont : EditableTableThemeData.bodyFont,
          fontSize: 13,
          color: t.fg1,
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: t.surface,
          hintText: isDate ? 'YYYY-MM-DD' : (isTime ? 'HH:mm' : null),
          hintStyle: TextStyle(color: t.fg4, fontSize: 12.5),
          contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          suffixIcon: suffix,
          suffixIconConstraints: const BoxConstraints(minWidth: 30, minHeight: 30),
        ),
      ),
    );
  }

  /// A compact icon button shown at a cell editor's trailing edge.
  Widget _editorSuffix(EditableTableThemeData t, IconData icon, String tip, VoidCallback onTap) {
    return Tooltip(
      message: tip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Icon(icon, size: 16, color: EditableTableThemeData.accent),
          ),
        ),
      ),
    );
  }

  Widget _actionsCell(EditableTableThemeData t, int r, bool isSelRow) {
    return Container(
      width: EditableTableThemeData.actionsWidth,
      height: EditableTableThemeData.rowHeight,
      decoration: BoxDecoration(
        color: isSelRow ? t.selectionFill(0.06) : t.surface,
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _rowActionBtn(Icons.add_rounded, 'Insert row below', t.fg2, () => _controller.insertRowAt(r + 1), t),
          const SizedBox(width: 6),
          _rowActionBtn(Icons.delete_outline_rounded, 'Delete row', EditableTableThemeData.danger,
              () => _maybeDelete(r), t),
        ],
      ),
    );
  }

  Widget _rowActionBtn(IconData icon, String tip, Color color, VoidCallback onTap, EditableTableThemeData t) {
    return _HoverButton(
      enabled: true,
      tooltip: tip,
      builder: (hover) => Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: hover ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(EditableTableThemeData.radiusSm),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
      onTap: onTap,
    );
  }

  // ── totals footer ──────────────────────────────────────────
  Widget _footer(EditableTableThemeData t) {
    final cells = <Widget>[];
    if (widget.showRowNumbers) {
      cells.add(SizedBox(width: EditableTableThemeData.gutterWidth, height: EditableTableThemeData.footerHeight));
    }
    for (var ci = 0; ci < _controller.columns.length; ci++) {
      final col = _controller.columns[ci];
      var label = ci == 0 ? widget.totalsLabel : '';
      if (col.includeInTotal) {
        label = EditableTableFormat.formatNumber(_controller.columnTotal(col));
      }
      cells.add(Container(
        width: col.width,
        height: EditableTableThemeData.footerHeight,
        alignment: col.align == CellAlign.end ? Alignment.centerRight : Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(border: Border(right: BorderSide(color: t.border))),
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: col.includeInTotal ? EditableTableThemeData.monoFont : EditableTableThemeData.bodyFont,
            fontSize: col.includeInTotal ? 13 : 10,
            fontWeight: FontWeight.w700,
            letterSpacing: col.includeInTotal ? 0 : 0.5,
            color: col.includeInTotal ? t.fg1 : t.fg3,
          ),
        ),
      ));
    }
    if (widget.showActions) {
      cells.add(Container(
        width: EditableTableThemeData.actionsWidth,
        height: EditableTableThemeData.footerHeight,
        alignment: Alignment.center,
        child: _rowActionBtn(Icons.add_rounded, 'Add row at end', t.fg2, _controller.addRow, t),
      ));
    }
    return Container(
      decoration: BoxDecoration(
        color: t.bg,
        border: Border(top: BorderSide(color: t.borderStrong, width: 2)),
      ),
      child: Row(children: cells),
    );
  }

  // ── status bar (hints + unit) ──────────────────────────────
  Widget _statusBar(EditableTableThemeData t) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_controller.rowCount} rows · type to edit · Enter ↓ · Tab → (adds a row at the end) · ⌘D dup · ⌘⌫ delete · ⌘Z undo · ⌘/ shortcuts',
              style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 12, color: t.fg3),
            ),
          ),
          if (widget.unitLabel != null) ...[
            const SizedBox(width: 12),
            Text(widget.unitLabel!,
                style: TextStyle(fontFamily: EditableTableThemeData.monoFont, fontSize: 11, color: t.fg3)),
          ],
        ],
      ),
    );
  }

  // ── overlays ───────────────────────────────────────────────
  Future<void> _openRowMenu(int r, Offset globalPos) async {
    _controller.select(r, _controller.selection.col);
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;
    final t = _t;
    TextStyle item(Color c) => TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 13, color: c);
    final choice = await showMenu<String>(
      context: context,
      color: t.surface,
      position: RelativeRect.fromLTRB(globalPos.dx, globalPos.dy, globalPos.dx + 1, globalPos.dy + 1),
      items: [
        PopupMenuItem(value: 'above', height: 40, child: Row(children: [Icon(Icons.vertical_align_top_rounded, size: 15, color: t.fg2), const SizedBox(width: 10), Text('Insert row above', style: item(t.fg1))])),
        PopupMenuItem(value: 'below', height: 40, child: Row(children: [Icon(Icons.vertical_align_bottom_rounded, size: 15, color: t.fg2), const SizedBox(width: 10), Text('Insert row below', style: item(t.fg1))])),
        PopupMenuItem(value: 'duplicate', height: 40, child: Row(children: [Icon(Icons.copy_all_rounded, size: 15, color: t.fg2), const SizedBox(width: 10), Text('Duplicate row', style: item(t.fg1))])),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'delete', height: 40, child: Row(children: [const Icon(Icons.delete_outline_rounded, size: 15, color: EditableTableThemeData.danger), const SizedBox(width: 10), Text('Delete row', style: item(EditableTableThemeData.danger))])),
      ],
    );
    switch (choice) {
      case 'above':
        _controller.insertRowAt(r);
        break;
      case 'below':
        _controller.insertRowAt(r + 1);
        break;
      case 'duplicate':
        _controller.duplicateRowAt(r);
        break;
      case 'delete':
        _maybeDelete(r);
        break;
    }
    _gridFocus.requestFocus();
  }

  /// Delete row [r] — through a confirmation popup when [widget.confirmDelete],
  /// or immediately otherwise.
  void _maybeDelete(int r) {
    if (widget.confirmDelete) {
      _confirmDelete(r);
    } else {
      _controller.deleteRowAt(r);
      _gridFocus.requestFocus();
    }
  }

  // ── keyboard shortcuts reference ───────────────────────────
  Future<void> _showShortcuts() async {
    final t = _t;
    const mod = '⌘/Ctrl';
    final groups = <String, List<List<String>>>{
      'Navigate': [
        ['↑ ↓ ← →', 'Move between cells'],
        ['Tab / ⇧Tab', 'Next / previous cell'],
        ['Home / End', 'First / last column'],
        ['$mod+Home / End', 'First / last cell'],
      ],
      'Edit': [
        ['Type', 'Overwrite the cell'],
        ['Enter / F2', 'Edit, or open a select'],
        ['Enter ↓ · Tab →', 'Commit & move'],
        ['Tab at end', 'Append a new row'],
        ['⌫ / Delete', 'Clear the cell'],
        ['Esc', 'Cancel editing'],
      ],
      'Rows & clipboard': [
        ['$mod+Enter', 'Add a row'],
        ['$mod+D', 'Duplicate row'],
        ['$mod+⌫', 'Delete row'],
        ['$mod+C / X / V', 'Copy / cut / paste cell'],
        ['$mod+Z / ⇧Z', 'Undo / redo'],
      ],
    };

    await showDialog<void>(
      context: context,
      builder: (ctx) => Theme(
        data: Theme.of(context),
        child: Dialog(
          backgroundColor: t.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EditableTableThemeData.radiusLg)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.keyboard_outlined, size: 18, color: EditableTableThemeData.accent),
                      const SizedBox(width: 9),
                      Text('Keyboard shortcuts',
                          style: TextStyle(
                              fontFamily: EditableTableThemeData.displayFont,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: t.fg1)),
                      const Spacer(),
                      _HoverButton(
                        enabled: true,
                        tooltip: 'Close',
                        onTap: () => Navigator.pop(ctx),
                        builder: (h) => Icon(Icons.close_rounded, size: 18, color: h ? t.fg1 : t.fg3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  for (final entry in groups.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 6),
                      child: Text(entry.key.toUpperCase(),
                          style: TextStyle(
                              fontFamily: EditableTableThemeData.bodyFont,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: EditableTableThemeData.accent)),
                    ),
                    for (final pair in entry.value)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 150,
                              child: Text(pair[0],
                                  style: TextStyle(
                                      fontFamily: EditableTableThemeData.monoFont,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: t.fg1)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(pair[1],
                                  style: TextStyle(
                                      fontFamily: EditableTableThemeData.bodyFont, fontSize: 12.5, color: t.fg3)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
    _gridFocus.requestFocus();
  }

  Future<void> _confirmDelete(int r) async {
    final t = _t;
    final name = _controller.rows[r].values.firstWhere((v) => v.trim().isNotEmpty, orElse: () => 'this row');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Theme(
        data: Theme.of(context),
        child: AlertDialog(
          backgroundColor: t.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EditableTableThemeData.radiusLg)),
          title: Text('Delete row ${r + 1}?',
              style: TextStyle(fontFamily: EditableTableThemeData.displayFont, fontSize: 16, fontWeight: FontWeight.w700, color: t.fg1)),
          content: Text('“$name” will be permanently removed.',
              style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 13, height: 1.5, color: t.fg3)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: TextStyle(color: t.fg2))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: EditableTableThemeData.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) _controller.deleteRowAt(r);
    _gridFocus.requestFocus();
  }
}

/// Small hover-aware tap target used for toolbar + row actions.
class _HoverButton extends StatefulWidget {
  final bool enabled;
  final String? tooltip;
  final Widget Function(bool hover) builder;
  final VoidCallback? onTap;
  const _HoverButton({required this.enabled, required this.builder, this.tooltip, this.onTap});
  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final child = MouseRegion(
      cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(onTap: widget.onTap, child: widget.builder(_hover && widget.enabled)),
    );
    if (widget.tooltip == null) return child;
    return Tooltip(message: widget.tooltip!, waitDuration: const Duration(milliseconds: 450), child: child);
  }
}

/// A single tappable colour swatch used inside the [ColorPickerColumn] menu.
class _SwatchDot extends StatelessWidget {
  final String hex;
  final VoidCallback onTap;
  const _SwatchDot({required this.hex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _EditableTableState._parseHex(hex) ?? Colors.transparent;
    return Tooltip(
      message: hex.toUpperCase(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(EditableTableThemeData.radiusSm),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(EditableTableThemeData.radiusSm),
            border: Border.all(color: const Color(0x33000000)),
          ),
        ),
      ),
    );
  }
}
