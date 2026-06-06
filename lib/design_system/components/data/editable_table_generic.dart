// ============================================================
// EditableTable — GENERIC ROW TYPE  (Model + Controller).
// ------------------------------------------------------------
// A first-class, strongly-typed editable grid: rows are a `List<T>` of an
// immutable value, and every `EditableColumn<T>` reads a cell with
// `value: (T) => String` and writes one with `setValue: (T, raw) => T`. This
// mirrors the shipped `ReadableTable<T>` precedent and replaces the loose
// `Map<String,String>` of the original table.
//
// This file is the Model + Controller; the widget lives in
// editable_table_generic_view.dart, and both are exported from the
// `geniuslink_editable_table_generic.dart` barrel. It reuses
// `EditableTableThemeData` (the shared table theme) at the view layer.
//
//   File: lib/design_system/components/data/editable_table_generic.dart
// ============================================================

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

/// Horizontal alignment of a column's content.
enum CellAlign { start, end }

/// Sort direction for a column.
enum SortDir { none, asc, desc }

/// How a column edits & renders.
enum EditableColumnType { text, number, select, date, checkbox, computed, readonly }

/// An immutable cell address (row + visual? no — LOGICAL column index).
@immutable
class CellRef {
  final int row;
  final int col;
  const CellRef(this.row, this.col);
  @override
  bool operator ==(Object o) => o is CellRef && o.row == row && o.col == col;
  @override
  int get hashCode => Object.hash(row, col);
}

/// Everything a custom cell renderer needs — generic over the row value.
@immutable
class EditableCellData<T> {
  final int row;
  final int col;
  final String value;
  final T rowData;
  final EditableColumn<T> column;
  final bool selected;
  final bool invalid;
  final VoidCallback requestEdit;
  const EditableCellData({
    required this.row,
    required this.col,
    required this.value,
    required this.rowData,
    required this.column,
    required this.selected,
    required this.invalid,
    required this.requestEdit,
  });
}

typedef EditableCellBuilder<T> = Widget Function(BuildContext context, EditableCellData<T> cell);
typedef EditableCellValidator<T> = String? Function(String value, T row);

/// The schema for one column, generic over the row value [T].
@immutable
class EditableColumn<T> {
  final String label;
  final double width;
  final CellAlign align;
  final bool mono;
  final bool required;
  final EditableColumnType type;
  final List<String> options;
  final bool includeInTotal;

  /// Read the cell's display string for [row].
  final String Function(T row) value;

  /// Apply [raw] to [row], returning a NEW row. Null ⇒ read-only.
  final T Function(T row, String raw)? setValue;

  /// Normalise a freshly-typed value on commit (group numbers, reformat dates…).
  final String Function(String raw)? normalize;

  /// Typed sort key. Defaults to the display string.
  final Comparable Function(T row)? sortKey;

  final String? Function(String value)? validate;
  final EditableCellValidator<T>? cellValidator;
  final EditableCellBuilder<T>? cellBuilder;

  const EditableColumn({
    required this.label,
    required this.value,
    this.setValue,
    this.width = 160,
    CellAlign? align,
    this.mono = false,
    this.required = false,
    this.type = EditableColumnType.text,
    this.options = const [],
    this.includeInTotal = false,
    this.normalize,
    this.sortKey,
    this.validate,
    this.cellValidator,
    this.cellBuilder,
  }) : align = align ?? (type == EditableColumnType.number ? CellAlign.end : CellAlign.start);

  bool get isReadOnly =>
      setValue == null || type == EditableColumnType.readonly || type == EditableColumnType.computed;

  bool get editableInline =>
      !isReadOnly &&
      (type == EditableColumnType.text ||
          type == EditableColumnType.number ||
          type == EditableColumnType.date);

  String displayValue(T row) => value(row);

  Comparable sortValue(T row) => sortKey?.call(row) ?? value(row);

  String? errorFor(String v, [T? row]) {
    final s = v.trim();
    if (required && s.isEmpty) return 'Required';
    final e = validate?.call(v);
    if (e != null) return e;
    if (row != null) return cellValidator?.call(v, row);
    return null;
  }
}

// ── ergonomic typed-column constructors ──

/// Numeric column — right-aligned, monospace, optional clamp & decimals.
class NumericColumn<T> extends EditableColumn<T> {
  NumericColumn({
    required super.label,
    required super.value,
    super.setValue,
    super.width = 120,
    super.includeInTotal = false,
    super.required,
    super.sortKey,
    super.cellBuilder,
    super.validate,
    num? min,
    num? max,
    int decimals = 2,
  }) : super(
          type: EditableColumnType.number,
          mono: true,
          normalize: (raw) {
            final n = double.tryParse(raw.replaceAll(',', '').trim());
            if (n == null) return raw;
            var v = n;
            if (min != null && v < min) v = min.toDouble();
            if (max != null && v > max) v = max.toDouble();
            return v.toStringAsFixed(decimals < 0 ? 2 : decimals);
          },
        );
}

/// Strict dropdown — value must be one of [options].
class DropdownColumn<T> extends EditableColumn<T> {
  DropdownColumn({
    required super.label,
    required super.value,
    required super.setValue,
    required List<String> options,
    super.width = 150,
    super.sortKey,
    super.cellBuilder,
  }) : super(type: EditableColumnType.select, options: options);
}

/// A masked date column (YYYY-MM-DD), edited inline.
class DateColumn<T> extends EditableColumn<T> {
  DateColumn({
    required super.label,
    required super.value,
    super.setValue,
    super.width = 140,
    super.required,
    super.sortKey,
  }) : super(type: EditableColumnType.date, mono: true);
}

/// A boolean column rendered & toggled as a checkbox.
class CheckboxColumn<T> extends EditableColumn<T> {
  CheckboxColumn({
    required super.label,
    required super.value, // '1'/'true' ⇒ checked
    required super.setValue,
    super.width = 92,
    super.sortKey,
  }) : super(type: EditableColumnType.checkbox, align: CellAlign.start);
}

/// Read-only column derived from the whole row (no [setValue]).
class ComputedColumn<T> extends EditableColumn<T> {
  ComputedColumn({
    required super.label,
    required String Function(T row) compute,
    super.width = 130,
    super.includeInTotal = false,
    super.cellBuilder,
    super.sortKey,
  }) : super(type: EditableColumnType.computed, value: compute);
}

// ── backwards compatibility: the legacy string-map table is just T = EditableRow ──
typedef EditableRow = Map<String, String>;

EditableColumn<EditableRow> mapColumn(
  String key,
  String label, {
  double width = 160,
  EditableColumnType type = EditableColumnType.text,
  bool readOnly = false,
}) =>
    EditableColumn<EditableRow>(
      label: label,
      width: width,
      type: type,
      value: (r) => r[key] ?? '',
      setValue: readOnly ? null : (r, v) => {...r, key: v},
    );

// ════════════════════════════════════════════════════════════
// Controller — generic over T. The single source of truth for rows, the
// selection cursor, the edit draft, sort, column layout (resize + reorder)
// and undo/redo. Published to page content via [EditableTableScope].
// ════════════════════════════════════════════════════════════
class EditableTableController<T> extends ChangeNotifier {
  EditableTableController({
    required List<EditableColumn<T>> columns,
    required List<T> rows,
    this.newRow,
  })  : columns = List.unmodifiable(columns),
        _rows = List<T>.from(rows) {
    _order.addAll(List<int>.generate(columns.length, (i) => i));
  }

  final List<EditableColumn<T>> columns;
  final List<T> _rows;

  /// Factory for a blank row (enables Add-row / Tab-to-grow). Optional.
  final T Function()? newRow;

  CellRef _sel = const CellRef(0, 0);
  bool _editing = false;
  String _draft = '';

  int? _sortCol;
  SortDir _sortDir = SortDir.none;

  final List<int> _order = [];
  final Map<int, double> _widthOverride = {};
  static const double columnMinWidth = 64;
  static const double columnMaxWidth = 520;

  final List<List<T>> _past = [];
  final List<List<T>> _future = [];

  // ── reads ──
  List<T> get rows => List.unmodifiable(_rows);
  int get rowCount => _rows.length;
  int get colCount => columns.length;
  T rowAt(int r) => _rows[r];
  CellRef get selection => _sel;
  bool get editing => _editing;
  String get draft => _draft;
  int? get sortColumn => _sortCol;
  SortDir get sortDir => _sortDir;
  bool get canUndo => _past.isNotEmpty;
  bool get canRedo => _future.isNotEmpty;

  bool isSelected(int r, int c) => _sel.row == r && _sel.col == c;

  /// Display string for cell (row, LOGICAL col).
  String cellText(int r, int c) => columns[c].value(_rows[r]);

  // ── column layout (visual order + width overrides) ──
  List<int> get columnOrder => List<int>.unmodifiable(_order);
  int logicalColumnAt(int visual) =>
      _order.isEmpty ? visual : _order[visual.clamp(0, _order.length - 1)];
  EditableColumn<T> columnAt(int visual) => columns[logicalColumnAt(visual)];
  double widthOf(int visual) {
    final li = logicalColumnAt(visual);
    return _widthOverride[li] ?? columns[li].width;
  }

  bool hasWidthOverride(int visual) => _widthOverride.containsKey(logicalColumnAt(visual));

  void resizeColumn(int visual, double delta,
      {double min = columnMinWidth, double max = columnMaxWidth}) {
    final li = logicalColumnAt(visual);
    final base = _widthOverride[li] ?? columns[li].width;
    _widthOverride[li] = (base + delta).clamp(min, max);
    notifyListeners();
  }

  void resetColumnWidth(int visual) {
    if (_widthOverride.remove(logicalColumnAt(visual)) != null) notifyListeners();
  }

  void moveColumn(int fromVisual, int toVisual) {
    if (_order.isEmpty) return;
    final from = fromVisual.clamp(0, _order.length - 1);
    final to = toVisual.clamp(0, _order.length - 1);
    if (from == to) return;
    final li = _order.removeAt(from);
    _order.insert(to, li);
    notifyListeners();
  }

  // ── history ──
  List<T> _snapshot() => List<T>.from(_rows);
  void _apply(List<T> next, {bool record = true}) {
    if (record) {
      _past.add(_snapshot());
      _future.clear();
    }
    _rows
      ..clear()
      ..addAll(next);
    _clampSelection();
    notifyListeners();
  }

  void _clampSelection() {
    final r = _sel.row.clamp(0, _rows.isEmpty ? 0 : _rows.length - 1);
    final c = _sel.col.clamp(0, colCount - 1);
    if (r != _sel.row || c != _sel.col) _sel = CellRef(r, c);
  }

  // ── selection / navigation (pure) ──
  void select(int r, int c) {
    final next = CellRef(r.clamp(0, rowCount - 1), c.clamp(0, colCount - 1));
    if (next == _sel && !_editing) return;
    _sel = next;
    _editing = false;
    notifyListeners();
  }

  /// Move the cursor by (dr, dc). When [grow] and the move runs off the last
  /// row, a new blank row is appended (needs [newRow]).
  void moveSelection(int dr, int dc, {bool grow = false}) {
    if (_editing) _editing = false;
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
    if (r >= rowCount && grow && newRow != null) {
      _apply(List<T>.from(_rows)..add(newRow!()));
      r = rowCount - 1;
    }
    r = r.clamp(0, rowCount - 1);
    c = c.clamp(0, colCount - 1);
    final next = CellRef(r, c);
    if (next == _sel) {
      notifyListeners();
      return;
    }
    _sel = next;
    notifyListeners();
  }

  // ── editing ──
  void beginEdit({String? initial}) {
    final col = columns[_sel.col];
    if (col.isReadOnly || col.type == EditableColumnType.checkbox) return;
    _draft = initial ?? col.value(_rows[_sel.row]);
    _editing = true;
    notifyListeners();
  }

  void setDraft(String v) {
    _draft = v;
    // no notify — the field owns its text; commit applies it.
  }

  void cancelEdit() {
    if (!_editing) return;
    _editing = false;
    notifyListeners();
  }

  /// Commit the draft (or [valueOverride]) to the active cell and optionally
  /// move the cursor. One undoable step.
  void commitEdit({String? valueOverride, int moveDr = 0, int moveDc = 0, bool grow = false}) {
    final col = columns[_sel.col];
    final raw = valueOverride ?? _draft;
    if (!col.isReadOnly) {
      final v = col.normalize?.call(raw) ?? raw;
      final next = List<T>.from(_rows);
      next[_sel.row] = col.setValue!(next[_sel.row], v);
      _apply(next);
    }
    _editing = false;
    if (moveDr != 0 || moveDc != 0) {
      moveSelection(moveDr, moveDc, grow: grow);
    } else {
      notifyListeners();
    }
  }

  /// Toggle a checkbox cell (boolean column) at (r, c). One undoable step.
  void toggleCheckbox(int r, int c) {
    final col = columns[c];
    if (col.type != EditableColumnType.checkbox || col.setValue == null) return;
    final cur = truthy(col.value(_rows[r]));
    final next = List<T>.from(_rows);
    next[r] = col.setValue!(next[r], cur ? '0' : '1');
    _sel = CellRef(r, c);
    _apply(next);
  }

  /// Whether a string cell value reads as boolean-true.
  static bool truthy(String v) {
    final s = v.trim().toLowerCase();
    return s == '1' || s == 'true' || s == 'yes' || s == 'y';
  }

  // ── direct write (no cursor move) ──
  void writeCell(int r, int c, String raw) {
    final col = columns[c];
    if (col.isReadOnly) return;
    final v = col.normalize?.call(raw) ?? raw;
    final next = List<T>.from(_rows);
    next[r] = col.setValue!(next[r], v);
    _apply(next);
  }

  void clearCell(int r, int c) {
    final col = columns[c];
    if (col.isReadOnly) return;
    writeCell(r, c, '');
  }

  // ── row ops ──
  void addRow([T? row]) {
    final v = row ?? newRow?.call();
    if (v == null) return;
    _apply(List<T>.from(_rows)..add(v));
    _sel = CellRef(rowCount - 1, 0);
    notifyListeners();
  }

  void insertRowAt(int index, [T? row]) {
    final v = row ?? newRow?.call();
    if (v == null) return;
    final i = index.clamp(0, _rows.length);
    _apply(List<T>.from(_rows)..insert(i, v));
    _sel = CellRef(i, 0);
    notifyListeners();
  }

  void duplicateRowAt(int index) {
    if (index < 0 || index >= _rows.length) return;
    _apply(List<T>.from(_rows)..insert(index + 1, _rows[index]));
    _sel = CellRef(index + 1, _sel.col);
    notifyListeners();
  }

  void deleteRowAt(int index) {
    if (index < 0 || index >= _rows.length) return;
    _apply(List<T>.from(_rows)..removeAt(index));
  }

  void deleteSelectedRow() => deleteRowAt(_sel.row);
  void duplicateSelectedRow() => duplicateRowAt(_sel.row);

  void replaceRowAt(int r, T row) => _apply(List<T>.from(_rows)..[r] = row);
  void setRows(List<T> rows, {bool record = true}) => _apply(List<T>.from(rows), record: record);

  // ── sort ──
  void sortByColumn(int ci) {
    final dir = (_sortCol == ci && _sortDir == SortDir.asc) ? SortDir.desc : SortDir.asc;
    final mul = dir == SortDir.asc ? 1 : -1;
    final col = columns[ci];
    final sorted = List<T>.from(_rows)..sort((a, b) => col.sortValue(a).compareTo(col.sortValue(b)) * mul);
    _sortCol = ci;
    _sortDir = dir;
    _apply(sorted);
  }

  void clearSort() {
    _sortCol = null;
    _sortDir = SortDir.none;
    notifyListeners();
  }

  // ── totals ──
  double columnTotal(EditableColumn<T> col) {
    var sum = 0.0;
    for (final r in _rows) {
      final n = double.tryParse(col.value(r).replaceAll(',', '').trim());
      if (n != null) sum += n;
    }
    return sum;
  }

  // ── clipboard (TSV) ──
  String _san(String s) => s.replaceAll('\t', ' ').replaceAll(RegExp(r'[\r\n]+'), ' ');

  String rowsAsTsv(Iterable<int> rowIndices, {bool includeHeader = false}) {
    final rs = rowIndices.where((r) => r >= 0 && r < rowCount).toSet().toList()..sort();
    if (rs.isEmpty) return '';
    final buf = <String>[];
    if (includeHeader) buf.add([for (final c in columns) _san(c.label)].join('\t'));
    for (final r in rs) {
      buf.add([for (var c = 0; c < colCount; c++) _san(cellText(r, c))].join('\t'));
    }
    return buf.join('\n');
  }

  String cellsAsTsv(Iterable<CellRef> cells) {
    final list = cells.where((c) => c.row >= 0 && c.row < rowCount && c.col >= 0 && c.col < colCount).toList();
    if (list.isEmpty) return '';
    final r0 = list.map((c) => c.row).reduce((a, b) => a < b ? a : b);
    final r1 = list.map((c) => c.row).reduce((a, b) => a > b ? a : b);
    final c0 = list.map((c) => c.col).reduce((a, b) => a < b ? a : b);
    final c1 = list.map((c) => c.col).reduce((a, b) => a > b ? a : b);
    final set = list.toSet();
    final buf = <String>[];
    for (var r = r0; r <= r1; r++) {
      final cells = <String>[];
      for (var c = c0; c <= c1; c++) {
        cells.add(set.contains(CellRef(r, c)) ? _san(cellText(r, c)) : '');
      }
      buf.add(cells.join('\t'));
    }
    return buf.join('\n');
  }

  Future<int> copyRowsToClipboard(Iterable<int> rowIndices, {bool includeHeader = false}) async {
    final tsv = rowsAsTsv(rowIndices, includeHeader: includeHeader);
    if (tsv.isEmpty) return 0;
    await Clipboard.setData(ClipboardData(text: tsv));
    return tsv.split('\n').length;
  }

  Future<bool> copyCellsToClipboard(Iterable<CellRef> cells) async {
    final tsv = cellsAsTsv(cells);
    if (tsv.isEmpty) return false;
    await Clipboard.setData(ClipboardData(text: tsv));
    return true;
  }

  /// Copy the current single-cell selection to the OS clipboard.
  Future<void> copySelectionToClipboard() => copyCellsToClipboard([_sel]);

  // ── undo / redo ──
  void undo() {
    if (_past.isEmpty) return;
    _future.add(_snapshot());
    _apply(_past.removeLast(), record: false);
  }

  void redo() {
    if (_future.isEmpty) return;
    _past.add(_snapshot());
    _apply(_future.removeLast(), record: false);
  }

  // ── inherited lookup ──
  static EditableTableController<R>? of<R>(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EditableTableScope<R>>()?.controller;
}

/// Publishes an [EditableTableController] to descendant page content.
class EditableTableScope<T> extends InheritedNotifier<EditableTableController<T>> {
  const EditableTableScope({super.key, required EditableTableController<T> controller, required super.child})
      : super(notifier: controller);

  EditableTableController<T> get controller => notifier!;
}

// ── small format helpers reused by hosts ──
class EditableTableFormat {
  EditableTableFormat._();
  static String columnLetter(int i) {
    var n = i, s = '';
    do {
      s = String.fromCharCode(65 + (n % 26)) + s;
      n = (n ~/ 26) - 1;
    } while (n >= 0);
    return s;
  }

  static double? parseNumber(String v) => double.tryParse(v.replaceAll(',', '').trim());

  static String formatNumber(num n, {int decimals = 2}) {
    final s = n.toStringAsFixed(decimals);
    final parts = s.split('.');
    final intPart = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
    return parts.length > 1 ? '$intPart.${parts[1]}' : intPart;
  }
}
