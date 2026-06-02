// ============================================================
// EditableTable — TYPED COLUMNS.
// ------------------------------------------------------------
// Ergonomic subclasses of [EditableColumn], one per input kind. Each one is
// just a thin constructor that picks the right [EditableColumnType] and
// carries any kind-specific config, plus (where useful) a polymorphic
// `normalize` / `displayValue` override. The view dispatches editors by type
// and reads the extra config with `is` checks, so columns stay pure data.
//
//   final cols = <EditableColumn>[
//     EditableColumn(key: 'name', label: 'Name', required: true),     // text
//     NumericColumn(key: 'qty', label: 'Qty', min: 0, decimals: 0),
//     DateColumn(key: 'due', label: 'Due date'),
//     TimeColumn(key: 'at', label: 'Time'),
//     ComboBoxColumn(key: 'tag', label: 'Tag', options: ['A', 'B']),
//     DropdownColumn(key: 'status', label: 'Status', options: ['Open', 'Done']),
//     ColorPickerColumn(key: 'color', label: 'Colour'),
//     ReadonlyColumn(key: 'id', label: 'ID'),
//     ComputedColumn(key: 'total', label: 'Total',
//         compute: (r) => '${(num.tryParse(r['qty'] ?? '0') ?? 0) * 2}'),
//   ];
//
//   File: lib/design_system/components/data/editable_table_columns.dart
// ============================================================

import 'package:flutter/services.dart';
import 'editable_table_models.dart';

/// A numeric column with optional [min] / [max] clamp and fixed [decimals].
/// Right-aligned & monospace by default; summable via [includeInTotal].
class NumericColumn extends EditableColumn {
  final num? min;
  final num? max;

  /// Fractional digits kept on commit. `0` for integers; `-1` to leave the
  /// typed precision untouched (still grouped).
  final int decimals;

  const NumericColumn({
    required super.key,
    required super.label,
    super.width = 130,
    super.align,
    super.mono = true,
    super.required = false,
    super.includeInTotal = false,
    super.validate,
    super.cellValidator,
    super.cellBuilder,
    this.min,
    this.max,
    this.decimals = 2,
  }) : super(type: EditableColumnType.number);

  @override
  String normalize(String raw) {
    final n = EditableTableFormat.parseNumber(raw);
    if (n == null) return raw;
    var v = n;
    if (min != null && v < min!) v = min!.toDouble();
    if (max != null && v > max!) v = max!.toDouble();
    return EditableTableFormat.formatNumber(v, decimals < 0 ? 2 : decimals);
  }
}

/// An ISO `YYYY-MM-DD` date column: masked keyboard entry plus a calendar
/// button that opens the Material date picker. [first] / [last] bound the
/// picker's range.
class DateColumn extends EditableColumn {
  final DateTime? first;
  final DateTime? last;

  const DateColumn({
    required super.key,
    required super.label,
    super.width = 150,
    super.mono = true,
    super.required = false,
    super.validate,
    super.cellValidator,
    super.cellBuilder,
    this.first,
    this.last,
  }) : super(type: EditableColumnType.date, align: CellAlign.start);

  @override
  String normalize(String raw) {
    final d = EditableTemporal.parseDate(raw);
    return d == null ? raw : EditableTemporal.formatDate(d);
  }
}

/// A 24-hour `HH:mm` time column: masked keyboard entry plus a clock button
/// that opens the Material time picker.
class TimeColumn extends EditableColumn {
  const TimeColumn({
    required super.key,
    required super.label,
    super.width = 130,
    super.mono = true,
    super.required = false,
    super.validate,
    super.cellValidator,
    super.cellBuilder,
  }) : super(type: EditableColumnType.time, align: CellAlign.start);

  @override
  String normalize(String raw) {
    final t = EditableTemporal.parseTime(raw);
    return t == null ? raw : EditableTemporal.formatTime(t.$1, t.$2);
  }
}

/// A combo box — a free-text field with an attached suggestions dropdown.
/// The user may type any value OR pick one of [options].
class ComboBoxColumn extends EditableColumn {
  const ComboBoxColumn({
    required super.key,
    required super.label,
    required List<String> options,
    super.width = 180,
    super.align,
    super.mono = false,
    super.required = false,
    super.validate,
    super.cellValidator,
    super.cellBuilder,
  }) : super(type: EditableColumnType.combo, options: options);
}

/// A strict dropdown — the value must be one of [options] (no free typing).
/// Edits via a popup menu.
class DropdownColumn extends EditableColumn {
  const DropdownColumn({
    required super.key,
    required super.label,
    required List<String> options,
    super.width = 160,
    super.align,
    super.required = false,
    super.validate,
    super.cellValidator,
    super.cellBuilder,
  }) : super(type: EditableColumnType.select, options: options);
}

/// A colour column — the cell shows a swatch + the stored `#RRGGBB` hex, and
/// editing opens a swatch menu built from [swatches].
class ColorPickerColumn extends EditableColumn {
  final List<String> swatches;

  const ColorPickerColumn({
    required super.key,
    required super.label,
    super.width = 150,
    super.mono = true,
    super.required = false,
    super.validate,
    super.cellValidator,
    super.cellBuilder,
    this.swatches = kEditableSwatches,
  }) : super(type: EditableColumnType.color, align: CellAlign.start);
}

/// A non-editable column — the value is shown (or rendered via [cellBuilder])
/// but can never be selected into an editor.
class ReadonlyColumn extends EditableColumn {
  const ReadonlyColumn({
    required super.key,
    required super.label,
    super.width = 160,
    super.align,
    super.mono = false,
    super.includeInTotal = false,
    super.cellBuilder,
  }) : super(type: EditableColumnType.readonly);
}

/// A read-only column whose value is derived from the whole row by [compute],
/// recomputed on every change (e.g. `qty × price`, a status, a concatenation).
class ComputedColumn extends EditableColumn {
  /// Derives the display string from the current row.
  final String Function(EditableRow row) compute;

  const ComputedColumn({
    required super.key,
    required super.label,
    required this.compute,
    super.width = 150,
    super.align,
    super.mono = false,
    super.includeInTotal = false,
    super.cellBuilder,
  }) : super(type: EditableColumnType.computed);

  @override
  String displayValue(EditableRow row) => compute(row);
}

/// The default swatch palette offered by [ColorPickerColumn].
const List<String> kEditableSwatches = [
  '#4A7CFF', '#1DB88A', '#F97316', '#EF4444', '#A855F7',
  '#0EA5E9', '#EAB308', '#EC4899', '#64748B', '#111318',
];

// ════════════════════════════════════════════════════════════
// Date / time parsing + masked keyboard input
// ════════════════════════════════════════════════════════════

/// Pure parse / format helpers for the date & time columns. Dates are ISO
/// `YYYY-MM-DD`; times are 24h `HH:mm` — both matching the HTML
/// `<input type=date|time>` value formats.
class EditableTemporal {
  EditableTemporal._();

  static DateTime? parseDate(String s) {
    final m = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(s.trim());
    if (m == null) return null;
    final y = int.parse(m[1]!), mo = int.parse(m[2]!), da = int.parse(m[3]!);
    if (mo < 1 || mo > 12 || da < 1 || da > 31) return null;
    final d = DateTime(y, mo, da);
    if (d.month != mo || d.day != da) return null; // rejects e.g. 02-30
    return d;
  }

  static String formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Returns `(hour, minute)` or null.
  static (int, int)? parseTime(String s) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(s.trim());
    if (m == null) return null;
    final h = int.parse(m[1]!), mi = int.parse(m[2]!);
    if (h > 23 || mi > 59) return null;
    return (h, mi);
  }

  static String formatTime(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

/// Masks digit input to `YYYY-MM-DD` as the user types (auto-inserts dashes,
/// caps at 8 digits) — mirrors a web date field's segmented entry.
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldV, TextEditingValue newV) {
    var digits = newV.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 8) digits = digits.substring(0, 8);
    final b = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 4 || i == 6) b.write('-');
      b.write(digits[i]);
    }
    final s = b.toString();
    return TextEditingValue(text: s, selection: TextSelection.collapsed(offset: s.length));
  }
}

/// Masks digit input to `HH:mm` (auto-inserts the colon, caps at 4 digits).
class TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldV, TextEditingValue newV) {
    var digits = newV.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 4) digits = digits.substring(0, 4);
    final b = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 2) b.write(':');
      b.write(digits[i]);
    }
    final s = b.toString();
    return TextEditingValue(text: s, selection: TextSelection.collapsed(offset: s.length));
  }
}
