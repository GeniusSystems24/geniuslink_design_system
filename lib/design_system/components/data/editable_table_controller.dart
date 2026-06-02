// ============================================================
// EditableTable — CONTROLLER.
// ------------------------------------------------------------
// The single source of truth and all of the table's logic, as a
// ChangeNotifier. The view (EditableTable) is a thin render of this state and
// forwards every gesture/key here. The same controller is exposed to row
// content via an InheritedNotifier so any descendant can drive the grid:
//
//   final t = EditableTableController.of(context); // may be null
//   t?.addRow();
//
// Mirrors the reference logic in the web component (components-table.html):
// atomic commit (write + navigate + auto-grow in one step), pure keyboard
// navigation, a single undo/redo history covering every structural change,
// single-cell clipboard, click-to-sort, auto number formatting, validation.
//
//   File: lib/design_system/components/data/editable_table_controller.dart
// ============================================================

import 'dart:async';
import 'package:flutter/widgets.dart';
import 'editable_table_models.dart';

class EditableTableController extends ChangeNotifier {
  EditableTableController({
    required List<EditableColumn> columns,
    List<EditableRow>? rows,
    this.historyLimit = 200,
  })  : columns = List.unmodifiable(columns),
        _rows = [...?rows?.map((r) => Map<String, String>.from(r))] {
    if (_rows.isEmpty) _rows.add(blankRow());
  }

  final List<EditableColumn> columns;
  final int historyLimit;

  final List<EditableRow> _rows;
  CellRef _sel = const CellRef(0, 0);
  bool _editing = false;
  String _draft = '';
  String? _clip;
  int? _sortCol;
  SortDir _sortDir = SortDir.none;
  String? _flash;
  Timer? _flashTimer;

  final List<List<EditableRow>> _past = [];
  final List<List<EditableRow>> _future = [];

  // ── reads ──────────────────────────────────────────────────
  List<EditableRow> get rows => List.unmodifiable(_rows);
  int get rowCount => _rows.length;
  int get colCount => columns.length;
  CellRef get selection => _sel;
  bool get editing => _editing;
  String get draft => _draft;
  bool get canUndo => _past.isNotEmpty;
  bool get canRedo => _future.isNotEmpty;
  int? get sortColumn => _sortCol;
  SortDir get sortDir => _sortDir;
  String? get flash => _flash;

  String cellValue(int r, int c) => _rows[r][columns[c].key] ?? '';
  bool isSelected(int r, int c) => _sel.row == r && _sel.col == c;

  /// A copy of row [r]'s data map (for row-aware validators / custom cells).
  EditableRow rowMap(int r) => Map<String, String>.from(_rows[r]);

  /// The string shown in cell (r,c) — equals the stored value for most kinds,
  /// but resolves a `ComputedColumn` against the whole row.
  String displayAt(int r, int c) => columns[c].displayValue(_rows[r]);

  /// Count of required-but-empty (or otherwise invalid) cells across the grid.
  int get invalidCount => _rows.fold(
        0,
        (n, row) => n + columns.where((c) => c.errorFor(row[c.key] ?? '', row) != null).length,
      );

  /// Sum of a numeric column's parsed values (resolves computed columns).
  double columnTotal(EditableColumn column) => _rows.fold(
        0.0,
        (sum, row) => sum + (EditableTableFormat.parseNumber(column.displayValue(row)) ?? 0),
      );

  /// A fresh blank row honouring each column's [EditableColumn.blankValue].
  EditableRow blankRow() => {for (final c in columns) c.key: c.blankValue};

  // ── snapshot / history plumbing ────────────────────────────
  List<EditableRow> _clone() => _rows.map((r) => Map<String, String>.from(r)).toList();

  /// Replace the row set, optionally recording an undo step. Every structural
  /// or value mutation funnels through here so one stack covers them all.
  void _apply(List<EditableRow> next, {bool record = true}) {
    if (record) {
      _past.add(_clone());
      if (_past.length > historyLimit) _past.removeAt(0);
      _future.clear();
    }
    _rows
      ..clear()
      ..addAll(next.map((r) => Map<String, String>.from(r)));
    _clampSelection();
    notifyListeners();
  }

  void _clampSelection() {
    final r = _sel.row.clamp(0, _rows.isEmpty ? 0 : _rows.length - 1);
    final c = _sel.col.clamp(0, colCount - 1);
    if (r != _sel.row || c != _sel.col) _sel = CellRef(r, c);
  }

  // ── selection & navigation (pure — never mutate rows) ──────
  void select(int r, int c) {
    final next = CellRef(r.clamp(0, rowCount - 1), c.clamp(0, colCount - 1));
    if (next == _sel && !_editing) return;
    _sel = next;
    _editing = false;
    notifyListeners();
  }

  void moveSelection(int dr, int dc) {
    var r = _sel.row + dr;
    var c = _sel.col + dc;
    if (c < 0) {
      c = colCount - 1;
      r -= 1;
    }
    if (c >= colCount) {
      c = 0;
      r += 1;
    }
    r = r.clamp(0, rowCount - 1);
    c = c.clamp(0, colCount - 1);
    final next = CellRef(r, c);
    if (next == _sel) return;
    _sel = next;
    notifyListeners();
  }

  /// Tab to the next cell in reading order. When the cursor is on the very
  /// last cell (last row, last column) and [grow] is true, a fresh blank row
  /// is appended first and the cursor lands on its first cell — so Tab keeps
  /// flowing data entry without ever reaching for the mouse. Pass [backward]
  /// for Shift+Tab.
  void tabNext({bool grow = true, bool backward = false}) {
    if (backward) {
      moveSelection(0, -1);
      return;
    }
    final atLastCell = _sel.row == rowCount - 1 && _sel.col == colCount - 1;
    if (atLastCell && grow) {
      final next = _clone()..add(blankRow());
      _sel = CellRef(next.length - 1, 0);
      _apply(next);
      return;
    }
    moveSelection(0, 1);
  }

  // ── editing ────────────────────────────────────────────────
  void beginEdit([String? initial]) {
    _draft = initial ?? cellValue(_sel.row, _sel.col);
    _editing = true;
    notifyListeners();
  }

  /// Live draft update from the editing field — intentionally does NOT notify
  /// (the field owns its own text); committed value lands via [commit].
  void updateDraft(String value) => _draft = value;

  void cancelEdit() {
    if (!_editing) return;
    _editing = false;
    notifyListeners();
  }

  /// Atomic commit: format-if-numeric, write the draft, and (when [move])
  /// navigate — auto-growing a row past the end (unless [grow] is false) —
  /// all in one history step, so the typed value can never be clobbered by a
  /// follow-up update.
  void commit({int dr = 0, int dc = 0, bool move = false, bool grow = true}) {
    final col = columns[_sel.col];
    final value = _format(col, _draft);
    final next = _clone();
    next[_sel.row] = {...next[_sel.row], col.key: value};

    var target = _sel;
    if (move) {
      var r = _sel.row + dr;
      var c = _sel.col + dc;
      if (c < 0) {
        c = colCount - 1;
        r -= 1;
      }
      if (c >= colCount) {
        c = 0;
        r += 1;
      }
      if (r < 0) {
        r = 0;
        c = 0;
      }
      if (r >= next.length) {
        if (grow) {
          next.add(blankRow());
        } else {
          // Stay on the last cell rather than growing.
          r = next.length - 1;
          c = colCount - 1;
        }
      }
      target = CellRef(r.clamp(0, next.length - 1), c.clamp(0, colCount - 1));
    }
    _editing = false;
    _sel = target;
    _apply(next);
  }

  /// Directly write a cell (used by clear, cut, paste) as one history step.
  void writeCell(int r, int c, String value) {
    final next = _clone();
    next[r] = {...next[r], columns[c].key: value};
    _apply(next);
  }

  String _format(EditableColumn col, String raw) => col.normalize(raw);

  // ── clipboard (single cell) ────────────────────────────────
  void copyCell({bool cut = false}) {
    _clip = cellValue(_sel.row, _sel.col);
    if (cut) {
      writeCell(_sel.row, _sel.col, '');
      _flashHint('Cut');
    } else {
      _flashHint('Copied');
    }
  }

  void pasteCell() {
    if (_clip == null) return;
    final col = columns[_sel.col];
    writeCell(_sel.row, _sel.col, _format(col, _clip!));
    _flashHint('Pasted');
  }

  bool get hasClipboard => _clip != null;

  void _flashHint(String msg) {
    _flash = msg;
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 1100), () {
      _flash = null;
      notifyListeners();
    });
    notifyListeners();
  }

  // ── sort ───────────────────────────────────────────────────
  /// Click a header: cycles asc → desc → asc; reorders rows (undoable).
  void sortByColumn(int ci) {
    final dir = (_sortCol == ci && _sortDir == SortDir.asc) ? SortDir.desc : SortDir.asc;
    final mul = dir == SortDir.asc ? 1 : -1;
    final col = columns[ci];
    final next = _clone();
    next.sort((a, b) {
      if (col.type == EditableColumnType.number) {
        final av = EditableTableFormat.parseNumber(col.displayValue(a)) ?? 0;
        final bv = EditableTableFormat.parseNumber(col.displayValue(b)) ?? 0;
        return av.compareTo(bv) * mul;
      }
      return col.displayValue(a).toLowerCase().compareTo(col.displayValue(b).toLowerCase()) * mul;
    });
    _sortCol = ci;
    _sortDir = dir;
    _apply(next);
  }

  // ── row operations (toolbar + per-row actions + context menu) ─
  void addRow() {
    final next = _clone()..add(blankRow());
    _sel = CellRef(next.length - 1, 0);
    _apply(next);
  }

  void insertRowAt(int index) {
    final idx = index.clamp(0, _rows.length);
    final next = _clone()..insert(idx, blankRow());
    _sel = CellRef(idx, 0);
    _apply(next);
  }

  void duplicateRowAt(int index) {
    if (index < 0 || index >= _rows.length) return;
    final next = _clone()..insert(index + 1, Map<String, String>.from(_rows[index]));
    _sel = CellRef(index + 1, _sel.col);
    _apply(next);
  }

  void deleteRowAt(int index) {
    if (index < 0 || index >= _rows.length) return;
    if (_rows.length <= 1) {
      _sel = const CellRef(0, 0);
      _apply([blankRow()]);
      return;
    }
    final next = _clone()..removeAt(index);
    _sel = CellRef(_sel.row.clamp(0, next.length - 1), _sel.col);
    _apply(next);
  }

  void deleteSelectedRow() => deleteRowAt(_sel.row);

  void duplicateSelectedRow() => duplicateRowAt(_sel.row);

  // ── undo / redo ────────────────────────────────────────────
  void undo() {
    if (_past.isEmpty) return;
    _future.add(_clone());
    final prev = _past.removeLast();
    _editing = false;
    _rows
      ..clear()
      ..addAll(prev);
    _clampSelection();
    notifyListeners();
  }

  void redo() {
    if (_future.isEmpty) return;
    _past.add(_clone());
    final nextState = _future.removeLast();
    _editing = false;
    _rows
      ..clear()
      ..addAll(nextState);
    _clampSelection();
    notifyListeners();
  }

  /// Replace all rows programmatically (e.g. load from a data source). Records
  /// one undo step by default.
  void setRows(List<EditableRow> rows, {bool record = true}) {
    final next = rows.isEmpty ? [blankRow()] : rows;
    _apply(next, record: record);
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  // ── inherited lookup ───────────────────────────────────────
  static EditableTableController? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EditableTableScope>()?.controller;

  static EditableTableController? read(BuildContext context) =>
      (context.getElementForInheritedWidgetOfExactType<EditableTableScope>()?.widget as EditableTableScope?)
          ?.controller;
}

/// Exposes [controller] to descendants; rebuilds dependents on notify.
class EditableTableScope extends InheritedNotifier<EditableTableController> {
  const EditableTableScope({super.key, required EditableTableController controller, required super.child})
      : super(notifier: controller);

  EditableTableController get controller => notifier!;
}
