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

  const ReadableColumn(
    this.label, {
    required this.cell,
    this.width,
    this.flex = 1,
    this.align = ReadableAlign.start,
    this.sortable = false,
    this.sortKey,
  });
}
