// ============================================================
// ReadableTable — CONTROLLER.
// ------------------------------------------------------------
// The single source of truth for the read-only display grid, as a
// ChangeNotifier. The view (ReadableTable) is a thin render of this state and
// forwards every gesture/key here. The same controller is exposed to row /
// page content via an InheritedNotifier so any descendant can drive the grid:
//
//   final t = ReadableTableController.of<Account>(context); // may be null
//   t?.selectRowWhere((a) => a.overdue);
//
// Generic over the row value type T. Rich, intention-revealing operations:
//
//   SELECT rows by   index · value · where
//   ADD    rows by   index · where · end
//   DELETE rows by   index · where · value
//   REPLACE row by   index · value · where · firstWhere
//
// plus cell selection (cell modes), keyboard navigation and click-to-sort.
//
//   File: lib/design_system/components/data/readable_table_controller.dart
// ============================================================

import 'package:flutter/widgets.dart';
import 'readable_table_models.dart';

class ReadableTableController<T> extends ChangeNotifier {
  ReadableTableController({
    required List<ReadableColumn<T>> columns,
    List<T>? rows,
    this.selectionMode = ReadableSelectionMode.none,
    Set<int>? selectedRows,
    Set<ReadableCell>? selectedCells,
    int? sortColumn,
    bool sortAscending = true,
  })  : columns = List.unmodifiable(columns),
        _rows = [...?rows] {
    _selRows.addAll(selectedRows ?? const {});
    _selCells.addAll(selectedCells ?? const {});
    if (sortColumn != null && sortColumn >= 0 && sortColumn < columns.length) {
      _sortCol = sortColumn;
      _sortDir = ReadableSortDir.none; // forced through sortByColumn below
      _applySort(sortColumn, sortAscending ? ReadableSortDir.asc : ReadableSortDir.desc, notify: false);
    }
  }

  final List<ReadableColumn<T>> columns;

  /// What the user can select. Mutable so the view's `selectionMode:` can
  /// drive it; clears the selection when the kind of selection changes.
  ReadableSelectionMode selectionMode;

  final List<T> _rows;
  final Set<int> _selRows = {}; // row indices into _rows (current order)
  final Set<ReadableCell> _selCells = {};

  int _activeRow = 0;
  int _activeCol = 0;
  int _anchorRow = 0;
  int _anchorCol = 0;

  int? _sortCol;
  ReadableSortDir _sortDir = ReadableSortDir.none;

  // ── reads ──────────────────────────────────────────────────
  List<T> get rows => List.unmodifiable(_rows);
  int get rowCount => _rows.length;
  int get colCount => columns.length;
  T rowAt(int index) => _rows[index];

  Set<int> get selectedRowIndices => Set<int>.from(_selRows);
  List<T> get selectedRows => (_selRows.toList()..sort()).map((i) => _rows[i]).toList();
  Set<ReadableCell> get selectedCells => Set<ReadableCell>.from(_selCells);
  int get selectedCount => _isCellMode ? _selCells.length : _selRows.length;

  int get activeRow => _activeRow;
  int get activeCol => _activeCol;
  int? get sortColumn => _sortCol;
  ReadableSortDir get sortDir => _sortDir;

  bool isRowSelected(int index) => _selRows.contains(index);
  bool isCellSelected(int row, int col) => _selCells.contains(ReadableCell(row, col));

  bool get _isRowMode =>
      selectionMode == ReadableSelectionMode.singleRow || selectionMode == ReadableSelectionMode.multiRow;
  bool get _isCellMode =>
      selectionMode == ReadableSelectionMode.singleCell || selectionMode == ReadableSelectionMode.multiCell;
  bool get _isMulti =>
      selectionMode == ReadableSelectionMode.multiRow || selectionMode == ReadableSelectionMode.multiCell;
  bool get isInteractive => selectionMode != ReadableSelectionMode.none;

  // ── selection-mode swap ────────────────────────────────────
  void setSelectionMode(ReadableSelectionMode mode) {
    if (mode == selectionMode) return;
    selectionMode = mode;
    _selRows.clear();
    _selCells.clear();
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // SELECT ROWS — by index · value · where
  // ════════════════════════════════════════════════════════════

  /// Select the row at [index]. [additive] toggles it within the existing
  /// selection (multi only); [range] extends from the anchor to [index].
  void selectRowAt(int index, {bool additive = false, bool range = false}) {
    if (!_isRowMode || index < 0 || index >= _rows.length) return;
    _activeRow = index;
    if (selectionMode == ReadableSelectionMode.singleRow) {
      _selRows
        ..clear()
        ..add(index);
      _anchorRow = index;
    } else if (range) {
      final lo = index < _anchorRow ? index : _anchorRow;
      final hi = index < _anchorRow ? _anchorRow : index;
      if (!additive) _selRows.clear();
      for (var i = lo; i <= hi; i++) {
        _selRows.add(i);
      }
    } else if (additive) {
      _selRows.contains(index) ? _selRows.remove(index) : _selRows.add(index);
      _anchorRow = index;
    } else {
      _selRows
        ..clear()
        ..add(index);
      _anchorRow = index;
    }
    notifyListeners();
  }

  /// Select the first row whose value `==` [value]. [additive] adds it to the
  /// current selection (multi) instead of replacing.
  void selectRowByValue(T value, {bool additive = false}) {
    final i = _rows.indexOf(value);
    if (i >= 0) selectRowAt(i, additive: additive);
  }

  /// Select every row matching [test]. Replaces the selection unless
  /// [additive]. In single-row mode only the last match survives.
  void selectRowsWhere(bool Function(T value) test, {bool additive = false}) {
    if (!_isRowMode) return;
    if (!additive) _selRows.clear();
    int? last;
    for (var i = 0; i < _rows.length; i++) {
      if (test(_rows[i])) {
        _selRows.add(i);
        last = i;
      }
    }
    if (selectionMode == ReadableSelectionMode.singleRow && _selRows.length > 1 && last != null) {
      _selRows
        ..clear()
        ..add(last);
    }
    if (last != null) _activeRow = last;
    notifyListeners();
  }

  /// Select all rows (multi-row) — no-op in other modes.
  void selectAllRows() {
    if (selectionMode != ReadableSelectionMode.multiRow) return;
    _selRows
      ..clear()
      ..addAll(List<int>.generate(_rows.length, (i) => i));
    notifyListeners();
  }

  void clearSelection() {
    if (_selRows.isEmpty && _selCells.isEmpty) return;
    _selRows.clear();
    _selCells.clear();
    notifyListeners();
  }

  // ── cell selection (cell modes) ────────────────────────────
  void selectCellAt(int row, int col, {bool additive = false, bool range = false}) {
    if (!_isCellMode || row < 0 || row >= _rows.length || col < 0 || col >= colCount) return;
    _activeRow = row;
    _activeCol = col;
    if (selectionMode == ReadableSelectionMode.singleCell) {
      _selCells
        ..clear()
        ..add(ReadableCell(row, col));
      _anchorRow = row;
      _anchorCol = col;
    } else if (range) {
      final loR = row < _anchorRow ? row : _anchorRow;
      final hiR = row < _anchorRow ? _anchorRow : row;
      final loC = col < _anchorCol ? col : _anchorCol;
      final hiC = col < _anchorCol ? _anchorCol : col;
      if (!additive) _selCells.clear();
      for (var r = loR; r <= hiR; r++) {
        for (var c = loC; c <= hiC; c++) {
          _selCells.add(ReadableCell(r, c));
        }
      }
    } else if (additive) {
      final cell = ReadableCell(row, col);
      _selCells.contains(cell) ? _selCells.remove(cell) : _selCells.add(cell);
      _anchorRow = row;
      _anchorCol = col;
    } else {
      _selCells
        ..clear()
        ..add(ReadableCell(row, col));
      _anchorRow = row;
      _anchorCol = col;
    }
    notifyListeners();
  }

  void selectAllCells() {
    if (selectionMode != ReadableSelectionMode.multiCell) return;
    _selCells.clear();
    for (var r = 0; r < _rows.length; r++) {
      for (var c = 0; c < colCount; c++) {
        _selCells.add(ReadableCell(r, c));
      }
    }
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // ADD ROWS — by index · where · end
  // ════════════════════════════════════════════════════════════

  /// Append [value] as the last row.
  void addRow(T value) => _structural(() => _rows.add(value));

  /// Insert [value] at [index] (clamped to `0..rowCount`).
  void insertRowAt(int index, T value) =>
      _structural(() => _rows.insert(index.clamp(0, _rows.length), value));

  /// Insert [value] adjacent to rows matching [test] — [after] the match by
  /// default, or before it. With [firstOnly] (default) only the first match is
  /// used; otherwise [value] is inserted next to every match.
  void addRowWhere(bool Function(T value) test, T value, {bool after = true, bool firstOnly = true}) {
    _structural(() {
      final hits = <int>[];
      for (var i = 0; i < _rows.length; i++) {
        if (test(_rows[i])) {
          hits.add(i);
          if (firstOnly) break;
        }
      }
      // insert from the end so earlier indices stay valid
      for (final i in hits.reversed) {
        _rows.insert(after ? i + 1 : i, value);
      }
    });
  }

  // ════════════════════════════════════════════════════════════
  // DELETE ROWS — by index · where · value
  // ════════════════════════════════════════════════════════════

  /// Remove the row at [index].
  void deleteRowAt(int index) {
    if (index < 0 || index >= _rows.length) return;
    _structural(() => _rows.removeAt(index));
  }

  /// Remove the first row whose value `==` [value].
  void deleteRowByValue(T value) {
    final i = _rows.indexOf(value);
    if (i >= 0) deleteRowAt(i);
  }

  /// Remove every row matching [test]. Returns the number removed.
  int deleteRowsWhere(bool Function(T value) test) {
    final before = _rows.length;
    _structural(() => _rows.removeWhere(test));
    return before - _rows.length;
  }

  /// Remove every currently-selected row (row modes).
  void deleteSelectedRows() {
    if (_selRows.isEmpty) return;
    final doomed = _selRows.toList()..sort((a, b) => b.compareTo(a));
    _structural(() {
      for (final i in doomed) {
        if (i >= 0 && i < _rows.length) _rows.removeAt(i);
      }
    });
  }

  // ════════════════════════════════════════════════════════════
  // REPLACE ROW — by index · value · where · firstWhere
  // ════════════════════════════════════════════════════════════

  /// Replace the row at [index] with [value].
  void replaceRowAt(int index, T value) {
    if (index < 0 || index >= _rows.length) return;
    _structural(() => _rows[index] = value);
  }

  /// Replace the first row equal to [oldValue] with [newValue].
  void replaceRowByValue(T oldValue, T newValue) {
    final i = _rows.indexOf(oldValue);
    if (i >= 0) replaceRowAt(i, newValue);
  }

  /// Replace every row matching [test] with `update(currentValue)`. Returns
  /// the number replaced.
  int replaceRowsWhere(bool Function(T value) test, T Function(T value) update) {
    var n = 0;
    _structural(() {
      for (var i = 0; i < _rows.length; i++) {
        if (test(_rows[i])) {
          _rows[i] = update(_rows[i]);
          n++;
        }
      }
    });
    return n;
  }

  /// Replace only the first row matching [test] with `update(currentValue)`.
  void replaceFirstWhere(bool Function(T value) test, T Function(T value) update) {
    _structural(() {
      for (var i = 0; i < _rows.length; i++) {
        if (test(_rows[i])) {
          _rows[i] = update(_rows[i]);
          break;
        }
      }
    });
  }

  /// Replace the entire row set (e.g. load from a data source). Clears the
  /// selection; keeps the sort column applied if any.
  void setRows(List<T> values) {
    _rows
      ..clear()
      ..addAll(values);
    _selRows.clear();
    _selCells.clear();
    if (_sortCol != null && _sortDir != ReadableSortDir.none) {
      _applySort(_sortCol!, _sortDir, notify: false);
    }
    _clampActive();
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // SORT
  // ════════════════════════════════════════════════════════════

  /// Click a sortable header: cycles asc → desc. Reorders the rows and remaps
  /// the selection / cursor so they follow their rows.
  void sortByColumn(int ci) {
    if (ci < 0 || ci >= colCount || !columns[ci].sortable) return;
    final dir = (_sortCol == ci && _sortDir == ReadableSortDir.asc) ? ReadableSortDir.desc : ReadableSortDir.asc;
    _applySort(ci, dir);
  }

  /// Clear the sort indicator (does not restore the original order).
  void clearSort() {
    if (_sortCol == null) return;
    _sortCol = null;
    _sortDir = ReadableSortDir.none;
    notifyListeners();
  }

  void _applySort(int ci, ReadableSortDir dir, {bool notify = true}) {
    final col = columns[ci];
    final mul = dir == ReadableSortDir.asc ? 1 : -1;
    final order = List<int>.generate(_rows.length, (i) => i);
    order.sort((a, b) {
      final ka = col.sortKey?.call(_rows[a]) ?? _rows[a].toString();
      final kb = col.sortKey?.call(_rows[b]) ?? _rows[b].toString();
      int cmp;
      try {
        cmp = Comparable.compare(ka, kb);
      } catch (_) {
        cmp = ka.toString().compareTo(kb.toString());
      }
      return cmp * mul;
    });
    final reordered = [for (final i in order) _rows[i]];
    final remap = <int, int>{};
    for (var n = 0; n < order.length; n++) {
      remap[order[n]] = n;
    }
    final newSelRows = {for (final i in _selRows) remap[i]!};
    final newSelCells = {for (final c in _selCells) ReadableCell(remap[c.row]!, c.col)};
    _selRows
      ..clear()
      ..addAll(newSelRows);
    _selCells
      ..clear()
      ..addAll(newSelCells);
    _activeRow = remap[_activeRow] ?? 0;
    _anchorRow = remap[_anchorRow] ?? 0;
    _rows
      ..clear()
      ..addAll(reordered);
    _sortCol = ci;
    _sortDir = dir;
    if (notify) notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // KEYBOARD NAVIGATION (driven by the view)
  // ════════════════════════════════════════════════════════════
  void moveActive(int dRow, int dCol, {bool extend = false}) {
    if (_rows.isEmpty) return;
    final lastRow = _rows.length - 1;
    final lastCol = colCount - 1;
    final nr = (_activeRow + dRow).clamp(0, lastRow);
    final nc = _isCellMode ? (_activeCol + dCol).clamp(0, lastCol) : _activeCol;
    if (_isRowMode) {
      selectRowAt(nr, range: extend && _isMulti);
    } else if (_isCellMode) {
      selectCellAt(nr, nc, range: extend && _isMulti);
    }
  }

  void moveActiveTo(int row, int col, {bool extend = false}) {
    if (_rows.isEmpty) return;
    final r = row.clamp(0, _rows.length - 1);
    final c = col.clamp(0, colCount - 1);
    if (_isRowMode) {
      selectRowAt(r, range: extend && _isMulti);
    } else if (_isCellMode) {
      selectCellAt(r, c, range: extend && _isMulti);
    }
  }

  void toggleActive() {
    if (_isRowMode) {
      selectRowAt(_activeRow, additive: _isMulti);
    } else if (_isCellMode) {
      selectCellAt(_activeRow, _activeCol, additive: _isMulti);
    }
  }

  void selectAll() => _isCellMode ? selectAllCells() : selectAllRows();

  // ── internals ──────────────────────────────────────────────
  /// Runs a structural mutation, then remaps the selection / cursor by value
  /// identity so they keep pointing at the same rows where possible.
  void _structural(void Function() mutate) {
    final selValues = (_selRows.toList()..sort()).map((i) => _rows[i]).toList();
    final activeValue = (_activeRow >= 0 && _activeRow < _rows.length) ? _rows[_activeRow] : null;
    mutate();
    _selRows.clear();
    for (final v in selValues) {
      final i = _rows.indexOf(v);
      if (i >= 0) _selRows.add(i);
    }
    if (activeValue != null) {
      final i = _rows.indexOf(activeValue);
      if (i >= 0) _activeRow = i;
    }
    _selCells.removeWhere((c) => c.row >= _rows.length || c.col >= colCount);
    _clampActive();
    notifyListeners();
  }

  void _clampActive() {
    _activeRow = _activeRow.clamp(0, _rows.isEmpty ? 0 : _rows.length - 1);
    _activeCol = _activeCol.clamp(0, colCount == 0 ? 0 : colCount - 1);
    _anchorRow = _anchorRow.clamp(0, _rows.isEmpty ? 0 : _rows.length - 1);
    _anchorCol = _anchorCol.clamp(0, colCount == 0 ? 0 : colCount - 1);
  }

  // ── inherited lookup ───────────────────────────────────────
  static ReadableTableController<T>? of<T>(BuildContext context) =>
      (context.dependOnInheritedWidgetOfExactType<ReadableTableScope>()?.controller) as ReadableTableController<T>?;

  static ReadableTableController<T>? read<T>(BuildContext context) =>
      ((context.getElementForInheritedWidgetOfExactType<ReadableTableScope>()?.widget as ReadableTableScope?)
          ?.controller) as ReadableTableController<T>?;
}

/// Exposes a [ReadableTableController] to descendants; rebuilds dependents on
/// notify. (Untyped at the inherited layer; `of<T>` casts on read.)
class ReadableTableScope extends InheritedNotifier<ChangeNotifier> {
  const ReadableTableScope({super.key, required this.controller, required super.child})
      : super(notifier: controller);

  final ChangeNotifier controller;
}
