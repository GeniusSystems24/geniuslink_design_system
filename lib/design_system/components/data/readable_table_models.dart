// ============================================================
// ReadableTable — MODEL.
// ------------------------------------------------------------
// Immutable data for the read-only, generic display grid:
//   • ReadableColumn<T> — one column: how to size/align it, whether it sorts,
//     how to build its cell widget from a row value, and (optionally) the
//     comparable key to sort it by.
//   • ReadableCell      — a (row, col) address into the controller's rows.
//   • enums             — alignment, selection mode, sort direction.
//
// ReadableTable is generic over the ROW VALUE type T: each row is a single
// strongly-typed T, and every column knows how to render itself from that T
// (`cell`) — so row code reads `value.field` with no casting. For the simple
// "grid of pre-built widgets" case use `T = List<Widget>` and index into it.
//
//   File: lib/design_system/components/data/readable_table_models.dart
// ============================================================

import 'package:flutter/widgets.dart';
import 'package:geniuslink_design_system/design_system/components/data/readable_table_cells.dart';

/// Horizontal placement of a column's header + cell content.
enum ReadableAlign { start, center, end }

/// What a [ReadableTable] / its controller lets the user select.
enum ReadableSelectionMode {
  /// No selection layer (display only). Default — fully backward-compatible.
  none,

  /// Exactly one row at a time.
  singleRow,

  /// Any number of rows (Ctrl/⌘-click toggles, Shift extends a range,
  /// ⌘/Ctrl+A selects all).
  multiRow,

  /// Exactly one cell at a time.
  singleCell,

  /// Any number of cells (Ctrl/⌘-click toggles, Shift extends a rectangle).
  multiCell,
}

/// Current sort direction of a column.
enum ReadableSortDir { none, asc, desc }

/// The data KIND a column renders. Mirrors `EditableTable`'s column types so a
/// read-only grid can present the same diversity of data with consistent
/// formatting and affordances — without every call site hand-writing a `cell`
/// builder. See the `ReadableColumn.<kind>` factories below.
enum ReadableColumnType {
  /// Plain text (optionally a secondary line / bilingual pair).
  text,

  /// Right-aligned, monospace number with grouping + fixed decimals.
  number,

  /// A value drawn from a small set, shown as a coloured pill (status, type…).
  enumBadge,

  /// An ISO date, shown formatted + monospace.
  date,

  /// A 24-hour `HH:mm` time, shown monospace.
  time,

  /// A `#RRGGBB` colour, shown as a swatch + hex.
  color,

  /// A 0..1 (or 0..100) ratio, shown as a labelled progress bar.
  progress,

  /// A URL / external reference, shown as a link affordance.
  link,
}

/// A cell address by row index (into the controller's current row order) +
/// column index.
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
/// filling the remaining width) sizes the column. [cell] builds the cell's
/// content widget from a row value of type [T].
@immutable
class ReadableColumn<T> {
  /// Header label (uppercased on render). Empty string → blank header cell.
  final String label;

  /// Builds the cell content for a given row value. Cells are arbitrary
  /// widgets — status pills, two-line bilingual text, progress bars, links…
  final Widget Function(BuildContext context, T value) cell;

  /// Fixed pixel width. When null the column flexes by [flex].
  final double? width;

  /// Proportional weight when [width] is null.
  final int flex;

  /// Content alignment (header + body).
  final ReadableAlign align;

  /// Whether the header is clickable to sort by this column.
  final bool sortable;

  /// Comparable key to sort this column by, derived from a row value. When a
  /// column is [sortable] but this is null, the table sorts by `value.toString()`.
  final Comparable? Function(T value)? sortKey;

  /// The semantic kind this column renders. The `.<kind>` factories set this
  /// (and an appropriate [cell] builder); the default unnamed constructor
  /// leaves it [ReadableColumnType.text] and uses the caller's [cell].
  final ReadableColumnType type;

  /// Plain-text value of this column for a row, used when COPYING selection to
  /// the clipboard (TSV). Cells render as arbitrary widgets, so this gives the
  /// copy path a flat string. When null the table falls back to [sortKey]'s
  /// result, then `value.toString()`.
  final String Function(T value)? copyText;

  const ReadableColumn(
    this.label, {
    required this.cell,
    this.width,
    this.flex = 1,
    this.align = ReadableAlign.start,
    this.sortable = false,
    this.sortKey,
    this.type = ReadableColumnType.text,
    this.copyText,
  });

  // ── typed factories — same kinds as EditableTable, read-only ──────────────
  // Each derives the cell widget so call sites declare intent, not layout.
  // (Widget construction is delegated to ReadableCells in the view layer; the
  // builders below are illustrative signatures kept null-safe and dependency
  // free in the model. The view supplies the concrete renderers.)

  /// Plain (optionally bilingual) text. [secondary] renders a muted second line.
  static ReadableColumn<T> text<T>(
    String label, {
    required String Function(T v) value,
    String Function(T v)? secondary,
    double? width,
    int flex = 1,
    ReadableAlign align = ReadableAlign.start,
    bool sortable = false,
  }) =>
      ReadableColumn<T>(
        label,
        type: ReadableColumnType.text,
        width: width,
        flex: flex,
        align: align,
        sortable: sortable,
        sortKey: (v) => value(v),
        cell: (ctx, v) => ReadableCells.text(value(v), secondary: secondary?.call(v)),
      );

  /// Right-aligned monospace number with grouping + [decimals].
  static ReadableColumn<T> number<T>(
    String label, {
    required num Function(T v) value,
    int decimals = 2,
    String? suffix,
    double? width = 130,
    bool sortable = true,
    bool colorSign = false,
  }) =>
      ReadableColumn<T>(
        label,
        type: ReadableColumnType.number,
        width: width,
        align: ReadableAlign.end,
        sortable: sortable,
        sortKey: (v) => value(v),
        cell: (ctx, v) => ReadableCells.number(value(v), decimals: decimals, suffix: suffix, colorSign: colorSign),
      );

  /// A coloured status/type pill drawn from a small enum-like set. [color]
  /// maps the string to a swatch; falls back to a neutral pill.
  static ReadableColumn<T> enumBadge<T>(
    String label, {
    required String Function(T v) value,
    Color Function(String tag)? color,
    double? width = 132,
    bool sortable = true,
  }) =>
      ReadableColumn<T>(
        label,
        type: ReadableColumnType.enumBadge,
        width: width,
        sortable: sortable,
        sortKey: (v) => value(v),
        cell: (ctx, v) => ReadableCells.badge(value(v), color: color),
      );

  /// A formatted date (monospace). [format] defaults to ISO `yyyy-MM-dd`.
  static ReadableColumn<T> date<T>(
    String label, {
    required DateTime Function(T v) value,
    String Function(DateTime d)? format,
    double? width = 124,
    bool sortable = true,
  }) =>
      ReadableColumn<T>(
        label,
        type: ReadableColumnType.date,
        width: width,
        sortable: sortable,
        sortKey: (v) => value(v),
        cell: (ctx, v) => ReadableCells.date(value(v), format: format),
      );

  /// A 24-hour `HH:mm` time (monospace).
  static ReadableColumn<T> time<T>(
    String label, {
    required String Function(T v) value,
    double? width = 96,
    bool sortable = true,
  }) =>
      ReadableColumn<T>(
        label,
        type: ReadableColumnType.time,
        width: width,
        sortable: sortable,
        sortKey: (v) => value(v),
        cell: (ctx, v) => ReadableCells.time(value(v)),
      );

  /// A colour cell — swatch + `#RRGGBB` hex.
  static ReadableColumn<T> color<T>(
    String label, {
    required String Function(T v) hex,
    double? width = 130,
  }) =>
      ReadableColumn<T>(
        label,
        type: ReadableColumnType.color,
        width: width,
        sortKey: (v) => hex(v),
        cell: (ctx, v) => ReadableCells.color(hex(v)),
      );

  /// A 0..1 ratio shown as a labelled progress bar.
  static ReadableColumn<T> progress<T>(
    String label, {
    required double Function(T v) value,
    double? width = 150,
    bool sortable = true,
  }) =>
      ReadableColumn<T>(
        label,
        type: ReadableColumnType.progress,
        width: width,
        sortable: sortable,
        sortKey: (v) => value(v),
        cell: (ctx, v) => ReadableCells.progress(value(v)),
      );

  /// A link affordance over a URL/reference.
  static ReadableColumn<T> link<T>(
    String label, {
    required String Function(T v) text,
    String Function(T v)? href,
    void Function(T v)? onTap,
    double? width,
    int flex = 1,
  }) =>
      ReadableColumn<T>(
        label,
        type: ReadableColumnType.link,
        width: width,
        flex: flex,
        sortKey: (v) => text(v),
        cell: (ctx, v) => ReadableCells.link(text(v), onTap: onTap == null ? null : () => onTap(v)),
      );
}
