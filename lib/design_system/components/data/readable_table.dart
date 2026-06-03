// ============================================================
// ReadableTable — VIEW (read-only display grid).
// ------------------------------------------------------------
// The read-only sibling of EditableTable: same visual language (it reuses
// EditableTableThemeData — identical header, hairline grid, surfaces, type
// ramp) but it renders arbitrary **widget** cells and carries no editing,
// selection or keyboard model. Use it for ledgers, lists, matrices and any
// table that only displays — status pills, two-line bilingual text, progress
// bars, links, anything — laid out with flexible or fixed column widths.
//
//   ReadableTable(
//     columns: const [
//       ReadableColumn('Code', width: 90),
//       ReadableColumn('Account', flex: 2),
//       ReadableColumn('Balance', align: ReadableAlign.end),
//     ],
//     rows: [
//       [Text('1001'), Text('Cash Box'), Text('42,500.00')],
//       ...
//     ],
//   )
//
//   File: lib/design_system/components/data/readable_table.dart
// ============================================================

import 'package:flutter/material.dart';
import 'editable_table_theme.dart';

/// Horizontal placement of a column's header + cell content.
enum ReadableAlign { start, center, end }

/// One column descriptor. Either [width] (fixed px) or [flex] (proportional,
/// filling the remaining width) sizes the column.
@immutable
class ReadableColumn {
  /// Header label (uppercased on render). Empty string → blank header cell.
  final String label;

  /// Fixed pixel width. When null the column flexes by [flex].
  final double? width;

  /// Proportional weight when [width] is null.
  final int flex;

  /// Content alignment (header + body).
  final ReadableAlign align;

  const ReadableColumn(this.label, {this.width, this.flex = 1, this.align = ReadableAlign.start});
}

class ReadableTable extends StatefulWidget {
  /// Column schema.
  final List<ReadableColumn> columns;

  /// Row data — one `List<Widget>` per row, aligned to [columns] by index.
  /// Cells are arbitrary widgets and are placed/aligned by the table.
  final List<List<Widget>> rows;

  /// Render the uppercase header row.
  final bool showHeader;

  /// Alternate a faint fill on odd rows.
  final bool zebra;

  /// Tint a row on pointer hover.
  final bool hoverHighlight;

  /// Minimum height of every data row.
  final double rowMinHeight;

  /// Padding inside every header / body cell.
  final EdgeInsets cellPadding;

  /// Notified with the row index when a row is tapped.
  final ValueChanged<int>? onRowTap;

  /// Placeholder shown when [rows] is empty.
  final Widget? emptyState;

  const ReadableTable({
    super.key,
    required this.columns,
    required this.rows,
    this.showHeader = true,
    this.zebra = false,
    this.hoverHighlight = false,
    this.rowMinHeight = 52,
    this.cellPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    this.onRowTap,
    this.emptyState,
  });

  @override
  State<ReadableTable> createState() => _ReadableTableState();
}

class _ReadableTableState extends State<ReadableTable> {
  int _hovered = -1;

  EditableTableThemeData get _t => EditableTableThemeData.of(context);

  Alignment _alignment(ReadableAlign a) => switch (a) {
        ReadableAlign.end => Alignment.centerRight,
        ReadableAlign.center => Alignment.center,
        ReadableAlign.start => Alignment.centerLeft,
      };

  Widget _cell({required ReadableColumn col, required Widget child}) {
    final box = Padding(
      padding: widget.cellPadding,
      child: Align(alignment: _alignment(col.align), child: child),
    );
    return col.width != null ? SizedBox(width: col.width, child: box) : Expanded(flex: col.flex, child: box);
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: t.borderStrong),
        borderRadius: BorderRadius.circular(EditableTableThemeData.radiusMd),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showHeader) _header(t),
          if (widget.rows.isEmpty)
            _empty(t)
          else
            for (var r = 0; r < widget.rows.length; r++) _row(t, r),
        ],
      ),
    );
  }

  Widget _header(EditableTableThemeData t) {
    return Container(
      decoration: BoxDecoration(
        color: t.bg,
        border: Border(bottom: BorderSide(color: t.borderStrong)),
      ),
      child: Row(
        children: [
          for (final col in widget.columns)
            _cell(
              col: col,
              child: Text(
                col.label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: EditableTableThemeData.bodyFont,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: t.fg3,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(EditableTableThemeData t, int r) {
    final cells = widget.rows[r];
    final hovered = widget.hoverHighlight && _hovered == r;
    final bg = hovered
        ? t.hover
        : (widget.zebra && r.isOdd ? Color.alphaBlend(t.bg.withOpacity(0.5), t.surface) : t.surface);

    Widget row = Container(
      constraints: BoxConstraints(minHeight: widget.rowMinHeight),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var ci = 0; ci < widget.columns.length; ci++)
            _cell(
              col: widget.columns[ci],
              child: ci < cells.length ? cells[ci] : const SizedBox.shrink(),
            ),
        ],
      ),
    );

    if (widget.onRowTap != null) {
      row = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onRowTap!(r),
        child: row,
      );
    }
    if (widget.hoverHighlight || widget.onRowTap != null) {
      row = MouseRegion(
        cursor: widget.onRowTap != null ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _hovered = r),
        onExit: (_) => setState(() => _hovered = _hovered == r ? -1 : _hovered),
        child: row,
      );
    }
    return row;
  }

  Widget _empty(EditableTableThemeData t) {
    return Container(
      height: 96,
      alignment: Alignment.center,
      color: t.surface,
      child: widget.emptyState ??
          Text(
            'No rows',
            style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 13, color: t.fg3),
          ),
    );
  }
}
