// ============================================================
// EditableTable — MODEL.
// ------------------------------------------------------------
// Pure data: the column schema that configures the table, the cell address
// used by the controller for selection, and the value-formatting helpers.
// No widgets, no state — this layer is what a host customises to describe
// its own table (a chart of accounts, an invoice's line items, anything).
//
//   File: lib/design_system/components/data/editable_table_models.dart
// ============================================================

import 'package:flutter/widgets.dart';

/// One row of data — a column-key → cell-value map. Values are kept as
/// strings (what the user types); the host parses on read. Kept deliberately
/// generic so the widget carries no business-model coupling.
typedef EditableRow = Map<String, String>;

/// Everything a [EditableCellBuilder] needs to paint a custom, read-only cell:
/// the value, its address, the whole row (for cross-column rendering), the
/// owning column, and the cell's current selected / invalid state. A
/// [requestEdit] callback lets a custom cell open the normal editor on tap.
@immutable
class EditableCellData {
  final int row;
  final int col;
  final String value;
  final EditableRow rowData;
  final EditableColumn column;
  final bool selected;
  final bool invalid;

  /// Opens the standard inline editor for this cell (no-op while editing).
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

/// Builds the read-only content of a cell — a host hook for chips, badges,
/// progress bars, icons, links… Returned widget replaces the default text.
/// The cell stays selectable/editable; this only changes how it *looks* when
/// not being edited.
typedef EditableCellBuilder = Widget Function(BuildContext context, EditableCellData cell);

/// Row-aware validator for a column. Receives the cell [value] and the full
/// [row] it belongs to (so it can validate against sibling cells), and
/// returns an error message, or null when valid.
typedef EditableCellValidator = String? Function(String value, EditableRow row);

/// How a column's cells edit & render. The concrete column subclasses in
/// `editable_table_columns.dart` (NumericColumn, DateColumn, …) each set the
/// right kind; you rarely pass [type] by hand.
enum EditableColumnType {
  /// Free text — inline text editor.
  text,

  /// Numeric — right-aligned by default, auto-grouped (1,234.00) on commit,
  /// summable in the totals footer.
  number,

  /// One of [EditableColumn.options] — edits via a dropdown menu (no typing).
  select,

  /// Free text with an attached suggestions dropdown (type OR pick).
  combo,

  /// ISO date `YYYY-MM-DD` — masked keyboard entry + a calendar picker button.
  date,

  /// 24h time `HH:mm` — masked keyboard entry + a clock picker button.
  time,

  /// A colour, stored as a `#RRGGBB` hex string — swatch cell + colour menu.
  color,

  /// Read-only — value shown but never editable.
  readonly,

  /// Read-only value computed from the whole row (see [EditableColumn]'s
  /// `ComputedColumn`); recomputes whenever the row changes.
  computed,
}

/// Horizontal alignment of a column's content.
enum CellAlign { start, end }

/// The schema for a single column. This is the customisation surface: a host
/// builds a `List<EditableColumn>` to define its table.
@immutable
class EditableColumn {
  /// Stable key into each [EditableRow].
  final String key;

  /// Header label.
  final String label;

  /// Fixed pixel width of the column.
  final double width;

  /// Content alignment (number columns default to [CellAlign.end]).
  final CellAlign align;

  /// Render the cell value in the monospace family (codes, amounts).
  final bool mono;

  /// Required — empty cells flag red and feed the validation badge.
  final bool required;

  /// Editing / rendering behaviour.
  final EditableColumnType type;

  /// Choices for [EditableColumnType.select].
  final List<String> options;

  /// Include this (numeric) column in the totals footer sum.
  final bool includeInTotal;

  /// Optional custom formatter applied on commit (overrides the built-in
  /// number grouping). Receives the raw typed string, returns the stored one.
  final String Function(String raw)? format;

  /// Optional validator — return an error message, or null when valid. Runs
  /// in addition to [required]. Value-only; for cross-column rules use
  /// [cellValidator].
  final String? Function(String value)? validate;

  /// Row-aware validator — like [validate] but also receives the whole row,
  /// so it can flag a cell based on its siblings (e.g. "end ≥ start", or
  /// "total must equal qty × price"). Runs after [validate].
  final EditableCellValidator? cellValidator;

  /// Optional custom renderer for the cell's read-only content. When set, the
  /// default text is replaced by whatever this returns (a chip, badge, bar…).
  /// Editing still uses the standard editor / select menu.
  final EditableCellBuilder? cellBuilder;

  const EditableColumn({
    required this.key,
    required this.label,
    this.width = 160,
    CellAlign? align,
    this.mono = false,
    this.required = false,
    this.type = EditableColumnType.text,
    this.options = const [],
    this.includeInTotal = false,
    this.format,
    this.validate,
    this.cellValidator,
    this.cellBuilder,
  }) : align = align ?? (type == EditableColumnType.number ? CellAlign.end : CellAlign.start);

  /// The blank value a new row should hold for this column (first option for
  /// a select, empty otherwise).
  String get blankValue =>
      type == EditableColumnType.select && options.isNotEmpty ? options.first : '';

  /// Validation error for [value] under this column, or null when valid.
  /// Pass [row] to also run the row-aware [cellValidator].
  String? errorFor(String value, [EditableRow? row]) {
    final v = value.trim();
    if (required && v.isEmpty) return 'Required';
    if (validate != null) {
      final e = validate!(value);
      if (e != null) return e;
    }
    if (cellValidator != null && row != null) {
      final e = cellValidator!(value, row);
      if (e != null) return e;
    }
    return null;
  }

  // ── polymorphic behaviour (overridden by the typed subclasses) ──

  /// Whether the cell opens the standard inline text editor (text / number /
  /// date / time / combo). Picker-only kinds (select, color) and the
  /// non-editable kinds (readonly, computed) return false.
  bool get editableInline =>
      type == EditableColumnType.text ||
      type == EditableColumnType.number ||
      type == EditableColumnType.date ||
      type == EditableColumnType.time ||
      type == EditableColumnType.combo;

  /// Whether the cell can never be edited (readonly / computed).
  bool get isReadOnly =>
      type == EditableColumnType.readonly || type == EditableColumnType.computed;

  /// The string this column shows for [row]. Stored value for most kinds;
  /// `ComputedColumn` overrides this to derive it from the whole row.
  String displayValue(EditableRow row) => row[key] ?? '';

  /// Normalises a freshly-typed value on commit. Base honours an explicit
  /// [format] callback, else groups numbers; subclasses override to clamp /
  /// reformat dates, times, numerics.
  String normalize(String raw) {
    if (format != null) return format!(raw);
    if (type == EditableColumnType.number) return EditableTableFormat.group(raw);
    return raw;
  }
}

/// An immutable cell address (row + column index) — the controller's cursor.
@immutable
class CellRef {
  final int row;
  final int col;
  const CellRef(this.row, this.col);

  CellRef copyWith({int? row, int? col}) => CellRef(row ?? this.row, col ?? this.col);

  @override
  bool operator ==(Object other) => other is CellRef && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => 'CellRef($row, $col)';
}

/// Sort direction for a column header. [none] means unsorted.
enum SortDir { none, asc, desc }

/// Value-formatting helpers shared by the controller and the view.
class EditableTableFormat {
  EditableTableFormat._();

  /// Spreadsheet-style column letter: 0 → A, 1 → B, … (wraps past Z).
  static String columnLetter(int i) {
    var n = i;
    final buf = StringBuffer();
    do {
      buf.write(String.fromCharCode(65 + (n % 26)));
      n = (n ~/ 26) - 1;
    } while (n >= 0);
    return String.fromCharCodes(buf.toString().codeUnits.reversed);
  }

  /// Parses a possibly-grouped numeric string ("1,234.5") to a double, or
  /// null when it isn't a number.
  static double? parseNumber(String v) {
    final s = v.replaceAll(',', '').trim();
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  /// Groups a numeric string to "#,##0.00"; passes blank/non-numeric through
  /// untouched so partial input is never destroyed. [decimals] controls the
  /// fractional digits (default 2).
  static String group(String v, [int decimals = 2]) {
    final s = v.trim();
    if (s.isEmpty) return '';
    final n = parseNumber(s);
    return n == null ? v : formatNumber(n, decimals);
  }

  /// Renders [n] with thousands separators and [decimals] fractional digits.
  static String formatNumber(double n, [int decimals = 2]) {
    final d = decimals < 0 ? 0 : decimals;
    final neg = n < 0;
    final fixed = n.abs().toStringAsFixed(d);
    final dot = fixed.indexOf('.');
    final intPart = dot < 0 ? fixed : fixed.substring(0, dot);
    final frac = dot < 0 ? '' : fixed.substring(dot + 1);
    final buf = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    return '${neg ? '-' : ''}$buf${frac.isEmpty ? '' : '.$frac'}';
  }
}
