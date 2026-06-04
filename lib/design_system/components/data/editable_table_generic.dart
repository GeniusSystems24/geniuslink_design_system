// ============================================================
// EditableTable — GENERIC ROW TYPE (reference design).
// ------------------------------------------------------------
// Phase 03 of the new-requirements work: make EditableTable accept a generic
// row type `T` that defines the structure of the data being displayed and
// edited, instead of the loose `Map<String,String>` rows it ships with today.
//
// This file is a SELF-CONTAINED reference for the migration. It mirrors the
// pattern the kit already uses for `ReadableTable<T>` (see
// readable_table_models.dart / readable_table_controller.dart): rows are a
// `List<T>`, each column carries typed `value` / `setValue` accessors, and the
// controller is `EditableTableController<T>`. It lives alongside the existing
// string-map implementation so that table keeps compiling during the port —
// the final step is to fold these signatures into editable_table_models.dart,
// editable_table_columns.dart, editable_table_controller.dart and
// editable_table.dart (each `EditableRow` becomes `T`, each `row[key]` becomes
// `column.value(row)`, each write becomes `column.setValue(row, raw)`).
//
//   File: lib/design_system/components/data/editable_table_generic.dart
// ============================================================

import 'package:flutter/widgets.dart';

/// Horizontal alignment of a column's content.
enum CellAlign { start, end }

/// How a column edits & renders. (Unchanged from the current model.)
enum EditableColumnType { text, number, select, combo, date, time, color, readonly, computed }

/// Everything a custom cell renderer needs — now generic over the row value.
@immutable
class EditableCellData<T> {
  final int row;
  final int col;
  final String value;
  final T rowData; // ← the typed row, was EditableRow (a map)
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

/// Row-aware validator — receives the cell value and the whole typed row, so a
/// rule can check sibling fields (e.g. `end >= start`).
typedef EditableCellValidator<T> = String? Function(String value, T row);

/// The schema for one column, generic over the row value [T].
///
/// The two accessors ARE the contract that replaces the string-keyed map:
///   • [value] reads the cell's display string from the typed row, and
///   • [setValue] returns a NEW row with an edit applied. A null [setValue]
///     marks the column read-only (computed / display columns).
///
/// Because [setValue] returns a fresh, immutable row, the controller's
/// undo/redo history is just a stack of `List<T>` references — no deep clone
/// of a mutable map per keystroke.
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

  /// Read the cell's string for [row].
  final String Function(T row) value;

  /// Apply [raw] to [row], returning a new row. Null ⇒ read-only.
  final T Function(T row, String raw)? setValue;

  /// Normalise a freshly-typed value on commit (group numbers, reformat dates…).
  final String Function(String raw)? normalize;

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
          type == EditableColumnType.date ||
          type == EditableColumnType.time ||
          type == EditableColumnType.combo);

  String displayValue(T row) => value(row);

  String? errorFor(String v, [T? row]) {
    final s = v.trim();
    if (required && s.isEmpty) return 'Required';
    final e = validate?.call(v);
    if (e != null) return e;
    if (row != null) return cellValidator?.call(v, row);
    return null;
  }
}

// ── ergonomic typed-column constructors (mirror the existing subclasses) ──

/// Numeric column — right-aligned, monospace, optional clamp & decimals.
class NumericColumn<T> extends EditableColumn<T> {
  NumericColumn({
    required super.label,
    required super.value,
    super.setValue,
    super.width = 130,
    super.includeInTotal = false,
    super.cellBuilder,
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
    super.width = 160,
  }) : super(type: EditableColumnType.select, options: options);
}

/// Read-only column derived from the whole row (no [setValue]).
class ComputedColumn<T> extends EditableColumn<T> {
  ComputedColumn({
    required super.label,
    required String Function(T row) compute,
    super.width = 150,
    super.includeInTotal = false,
    super.cellBuilder,
  }) : super(type: EditableColumnType.computed, value: compute);
}

// ── backwards compatibility: the legacy string-map table is just T = EditableRow ──

/// The old row shape. Existing call sites keep working by using these helpers.
typedef EditableRow = Map<String, String>;

/// A map-backed column — reproduces the pre-generic `EditableColumn(key: …)`.
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
// Controller — generic over T. (Essentials; full body mirrors the existing
// EditableTableController, with `EditableRow` → `T` and map access → accessors.)
// ════════════════════════════════════════════════════════════
class EditableTableController<T> extends ChangeNotifier {
  EditableTableController({required List<EditableColumn<T>> columns, required List<T> rows})
      : columns = List.unmodifiable(columns),
        _rows = List<T>.from(rows);

  final List<EditableColumn<T>> columns;
  final List<T> _rows;
  final List<List<T>> _past = [];
  final List<List<T>> _future = [];

  List<T> get rows => List.unmodifiable(_rows);
  int get rowCount => _rows.length;
  int get colCount => columns.length;
  T rowAt(int r) => _rows[r];

  /// The string shown in cell (r, c) — via the column's accessor, not a map.
  String cellText(int r, int c) => columns[c].value(_rows[r]);

  // Immutable rows ⇒ a snapshot is a shallow list copy (no per-cell clone).
  List<T> _snapshot() => List<T>.from(_rows);

  void _apply(List<T> next, {bool record = true}) {
    if (record) {
      _past.add(_snapshot());
      _future.clear();
    }
    _rows
      ..clear()
      ..addAll(next);
    notifyListeners();
  }

  /// Commit an edit to cell (r, c) through the column's typed setter.
  void writeCell(int r, int c, String raw) {
    final col = columns[c];
    if (col.isReadOnly) return;
    final value = col.normalize?.call(raw) ?? raw;
    final next = List<T>.from(_rows);
    next[r] = col.setValue!(next[r], value);
    _apply(next);
  }

  // Typed structural ops — same surface as ReadableTableController<T>.
  void replaceRowAt(int r, T row) => _apply(List<T>.from(_rows)..[r] = row);
  void insertRowAt(int r, T row) => _apply(List<T>.from(_rows)..insert(r, row));
  void deleteRowAt(int r) => _apply(List<T>.from(_rows)..removeAt(r));
  void setRows(List<T> rows) => _apply(List<T>.from(rows));

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
}

// ════════════════════════════════════════════════════════════
// Worked example — a typed chart-of-accounts line item.
// ════════════════════════════════════════════════════════════
//
// @immutable
// class Account {
//   final String code, nameEn, type;
//   final int qty;
//   final double price;
//   const Account({required this.code, required this.nameEn, required this.type,
//                   required this.qty, required this.price});
//   double get total => qty * price;
//   Account copyWith({String? code, String? nameEn, String? type, int? qty, double? price}) =>
//       Account(code: code ?? this.code, nameEn: nameEn ?? this.nameEn, type: type ?? this.type,
//               qty: qty ?? this.qty, price: price ?? this.price);
// }
//
// final columns = <EditableColumn<Account>>[
//   EditableColumn(label: 'Code',  value: (a) => a.code,  setValue: (a, v) => a.copyWith(code: v)),
//   EditableColumn(label: 'Account', value: (a) => a.nameEn, setValue: (a, v) => a.copyWith(nameEn: v)),
//   DropdownColumn(label: 'Type', options: const ['Asset','Liability','Equity','Revenue','Expense'],
//                  value: (a) => a.type, setValue: (a, v) => a.copyWith(type: v)),
//   NumericColumn(label: 'Qty',   value: (a) => '${a.qty}',
//                  setValue: (a, v) => a.copyWith(qty: int.tryParse(v) ?? a.qty), decimals: 0),
//   NumericColumn(label: 'Unit price', value: (a) => a.price.toStringAsFixed(2),
//                  setValue: (a, v) => a.copyWith(price: double.tryParse(v) ?? a.price)),
//   ComputedColumn(label: 'Total', compute: (a) => a.total.toStringAsFixed(2)),
// ];
//
// EditableTable<Account>(columns: columns, rows: accounts,
//   onChanged: (List<Account> next) => save(next));
