// ============================================================
// GeniusLink Design System — Editable table.
// Source parity: components-table.html.
// Architecture: MVVM. GLTableController owns domain row state while
// GLEditableTable delegates grid rendering, keyboard editing, selection,
// sorting, filtering, and resize behavior to trina_grid.
// ============================================================

import 'package:flutter/material.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../tokens.dart';
import '../core/core_components.dart';

/// Supported GeniusLink table column semantics.
///
/// The values map to TrinaGrid column types while keeping the public design
/// system API independent from TrinaGrid-specific constructors.
enum GLTableColumnType { text, number, currency, percentage, select, boolean, date, time }

class GLTableColumn {
  final String key;
  final String label;
  final int flex;
  final bool numeric;
  final bool editable;
  final GLTableColumnType type;
  final List<String> options;
  final double? width;
  final double minWidth;
  final bool frozen;
  final bool sortable;
  final bool filterable;

  const GLTableColumn({
    required this.key,
    required this.label,
    this.flex = 1,
    this.numeric = false,
    this.editable = true,
    this.type = GLTableColumnType.text,
    this.options = const [],
    this.width,
    this.minWidth = 120,
    this.frozen = false,
    this.sortable = true,
    this.filterable = true,
  });
}

class GLTableRowModel {
  final String id;
  final Map<String, dynamic> cells;

  GLTableRowModel({required this.id, required Map<String, dynamic> cells}) : cells = Map<String, dynamic>.from(cells);

  GLTableRowModel copyWith({String? id, Map<String, dynamic>? cells}) => GLTableRowModel(id: id ?? this.id, cells: cells ?? this.cells);
}

class GLTableCellChange {
  final String rowId;
  final String columnKey;
  final dynamic value;
  final dynamic oldValue;

  const GLTableCellChange({required this.rowId, required this.columnKey, this.value, this.oldValue});
}

class GLTableController extends ChangeNotifier {
  GLTableController({List<GLTableRowModel> rows = const []}) : _rows = rows.map((row) => row.copyWith()).toList();

  final List<GLTableRowModel> _rows;
  final Set<String> _selected = {};
  String? _sortKey;
  bool _sortAsc = true;
  int _revision = 0;

  List<GLTableRowModel> get rows => List.unmodifiable(_rows);
  Set<String> get selectedIds => Set.unmodifiable(_selected);
  String? get sortKey => _sortKey;
  bool get sortAsc => _sortAsc;
  int get revision => _revision;

  void _markChanged() {
    _revision++;
    notifyListeners();
  }

  void setRows(List<GLTableRowModel> rows) {
    _rows
      ..clear()
      ..addAll(rows.map((row) => row.copyWith()));
    _selected.removeWhere((id) => !_rows.any((row) => row.id == id));
    _markChanged();
  }

  void setSelected(String id, bool selected) {
    selected ? _selected.add(id) : _selected.remove(id);
    _markChanged();
  }

  void replaceSelected(Set<String> ids) {
    _selected
      ..clear()
      ..addAll(ids.where((id) => _rows.any((row) => row.id == id)));
    _markChanged();
  }

  void toggleSelected(String id) => setSelected(id, !_selected.contains(id));

  void clearSelection() {
    if (_selected.isEmpty) return;
    _selected.clear();
    _markChanged();
  }

  void editCell(String id, String key, dynamic value) {
    GLTableRowModel? row;
    for (final candidate in _rows) {
      if (candidate.id == id) {
        row = candidate;
        break;
      }
    }
    if (row == null) return;
    row.cells[key] = value;
    _markChanged();
  }

  void addRow(GLTableRowModel row) {
    _rows.add(row.copyWith());
    _markChanged();
  }

  void deleteSelected() {
    if (_selected.isEmpty) return;
    _rows.removeWhere((row) => _selected.contains(row.id));
    _selected.clear();
    _markChanged();
  }

  void sortBy(String key) {
    if (_sortKey == key) {
      _sortAsc = !_sortAsc;
    } else {
      _sortKey = key;
      _sortAsc = true;
    }
    _rows.sort((a, b) {
      final av = a.cells[key];
      final bv = b.cells[key];
      final an = _asComparableNumber(av);
      final bn = _asComparableNumber(bv);
      final result = an != null && bn != null ? an.compareTo(bn) : '$av'.compareTo('$bv');
      return _sortAsc ? result : -result;
    });
    _markChanged();
  }

  static num? _asComparableNumber(dynamic value) {
    if (value is num) return value;
    return num.tryParse('$value'.replaceAll(RegExp(r'[^0-9\.-]'), ''));
  }
}

class GLEditableTable extends StatefulWidget {
  final List<GLTableColumn> columns;
  final GLTableController? controller;
  final List<GLTableRowModel> rows;
  final bool selectable;
  final bool editable;
  final bool showFilters;
  final bool responsiveCards;
  final double minGridHeight;
  final String emptyTitle;
  final String emptyBody;
  final ValueChanged<GLTableCellChange>? onCellChanged;
  final ValueChanged<TrinaGridStateManager>? onLoaded;
  final TrinaGridConfiguration? configuration;

  const GLEditableTable({
    super.key,
    required this.columns,
    this.controller,
    this.rows = const [],
    this.selectable = true,
    this.editable = true,
    this.showFilters = true,
    this.responsiveCards = false,
    this.minGridHeight = 260,
    this.emptyTitle = 'No rows yet',
    this.emptyBody = 'Created rows will appear here.',
    this.onCellChanged,
    this.onLoaded,
    this.configuration,
  });

  @override
  State<GLEditableTable> createState() => _GLEditableTableState();
}

class _GLEditableTableState extends State<GLEditableTable> {
  late GLTableController _controller;
  late bool _owns;
  TrinaGridStateManager? _stateManager;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? GLTableController(rows: widget.rows);
    _owns = widget.controller == null;
    _controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(covariant GLEditableTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_onChanged);
      if (_owns) _controller.dispose();
      _controller = widget.controller ?? GLTableController(rows: widget.rows);
      _owns = widget.controller == null;
      _controller.addListener(_onChanged);
      _stateManager = null;
    } else if (_owns && widget.rows != oldWidget.rows) {
      _controller.setRows(widget.rows);
    }
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    if (_owns) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.rows.isEmpty) {
      return GLCard(child: SizedBox(height: 220, child: GLStateView(icon: 'table', title: widget.emptyTitle, body: widget.emptyBody)));
    }

    return LayoutBuilder(builder: (context, constraints) {
      if (widget.responsiveCards && constraints.maxWidth < GeniusThemeData.bpMd) {
        return GLResponsiveDataCards(columns: widget.columns, controller: _controller, selectable: widget.selectable);
      }

      final height = _resolveGridHeight(constraints.maxHeight);
      return SizedBox(
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(GeniusThemeData.radiusLg),
          child: TrinaGrid(
            key: ValueKey('gl-table-${_controller.revision}-${widget.columns.length}-${widget.selectable}-${widget.editable}-${widget.showFilters}'),
            columns: _toTrinaColumns(context),
            rows: _toTrinaRows(),
            fitContent: constraints.maxHeight.isInfinite,
            noRowsWidget: GLStateView(icon: 'table', title: widget.emptyTitle, body: widget.emptyBody),
            configuration: widget.configuration ?? _configuration(context),
            onLoaded: (event) {
              _stateManager = event.stateManager;
              if (widget.showFilters) {
                _stateManager?.setShowColumnFilter(true, notify: false);
              }
              widget.onLoaded?.call(event.stateManager);
            },
            onChanged: _handleGridChanged,
            onRowChecked: _handleRowChecked,
          ),
        ),
      );
    });
  }

  double _resolveGridHeight(double maxHeight) {
    if (maxHeight.isFinite && maxHeight > 0) return maxHeight;
    final header = widget.showFilters ? 96.0 : 52.0;
    final body = (_controller.rows.length * 44.0).clamp(132.0, 520.0).toDouble();
    return (header + body).clamp(widget.minGridHeight, 640.0).toDouble();
  }

  List<TrinaColumn> _toTrinaColumns(BuildContext context) {
    return [
      for (var index = 0; index < widget.columns.length; index++)
        _toTrinaColumn(widget.columns[index], index == 0),
    ];
  }

  TrinaColumn _toTrinaColumn(GLTableColumn column, bool firstColumn) {
    final width = column.width ?? (column.flex.clamp(1, 6).toDouble() * 132.0);
    final align = column.numeric ? TrinaColumnTextAlign.end : TrinaColumnTextAlign.start;
    return TrinaColumn(
      title: column.label,
      field: column.key,
      type: _toTrinaColumnType(column),
      width: width,
      minWidth: column.minWidth,
      readOnly: !widget.editable || !column.editable,
      textAlign: align,
      titleTextAlign: align,
      frozen: column.frozen ? TrinaColumnFrozen.start : TrinaColumnFrozen.none,
      enableSorting: column.sortable,
      enableFilterMenuItem: column.filterable,
      enableContextMenu: true,
      enableDropToResize: true,
      enableColumnDrag: true,
      enableRowChecked: widget.selectable && firstColumn,
      enableEditingMode: widget.editable && column.editable,
      cellPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      titlePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      metadata: {'glKey': column.key, 'glLabel': column.label},
    );
  }

  TrinaColumnType _toTrinaColumnType(GLTableColumn column) {
    switch (column.type) {
      case GLTableColumnType.number:
        return TrinaColumnType.number();
      case GLTableColumnType.currency:
        return TrinaColumnType.currency(symbol: 'SAR', decimalDigits: 2);
      case GLTableColumnType.percentage:
        return TrinaColumnType.percentage(decimalDigits: 1, showSymbol: true);
      case GLTableColumnType.select:
        return TrinaColumnType.select<String>(column.options, enableColumnFilter: true);
      case GLTableColumnType.boolean:
        return TrinaColumnType.boolean(trueText: 'Yes', falseText: 'No');
      case GLTableColumnType.date:
        return TrinaColumnType.date();
      case GLTableColumnType.time:
        return TrinaColumnType.time();
      case GLTableColumnType.text:
        return TrinaColumnType.text();
    }
  }

  List<TrinaRow> _toTrinaRows() {
    return [
      for (final row in _controller.rows)
        TrinaRow(
          checked: _controller.selectedIds.contains(row.id),
          metadata: {'glRowId': row.id},
          cells: {
            for (final column in widget.columns) column.key: TrinaCell(value: row.cells[column.key] ?? ''),
          },
        ),
    ];
  }

  TrinaGridConfiguration _configuration(BuildContext context) {
    final s = GeniusThemeData.of(context);
    final style = TrinaGridStyleConfig(
      gridBackgroundColor: s.surface,
      rowColor: s.surface,
      oddRowColor: s.surface,
      evenRowColor: s.surface2,
      activatedColor: GeniusThemeData.blue500.withOpacity(.12),
      rowCheckedColor: GeniusThemeData.blue500.withOpacity(.10),
      rowHoveredColor: s.hover,
      cellColorInEditState: s.inputBg,
      cellColorInReadOnlyState: s.surface2,
      cellReadonlyColor: s.surface2,
      cellDirtyColor: GeniusThemeData.warning500.withOpacity(.14),
      borderColor: s.border,
      gridBorderColor: s.borderStrong,
      activatedBorderColor: GeniusThemeData.blue500,
      inactivatedBorderColor: s.border,
      iconColor: s.fg3,
      menuBackgroundColor: s.surface,
      columnTextStyle: glTextStyle(context, family: GeniusThemeData.monoFont, size: 11, weight: FontWeight.w800, color: GeniusThemeData.blue500, letterSpacing: .8),
      cellTextStyle: glTextStyle(context, size: 12.8, weight: FontWeight.w600, color: s.fg1),
      rowHeight: 46,
      columnHeight: 46,
      columnFilterHeight: widget.showFilters ? 42 : 0,
      gridBorderRadius: BorderRadius.circular(GeniusThemeData.radiusLg),
      gridPopupBorderRadius: BorderRadius.circular(GeniusThemeData.radiusMd),
      enableRowHoverColor: true,
      enableCellBorderVertical: false,
      enableColumnBorderVertical: false,
      enableGridBorderShadow: false,
    );

    return TrinaGridConfiguration(
      enableMoveDownAfterSelecting: true,
      enableMoveHorizontalInEditing: true,
      enableCtrlClickMultiSelect: widget.selectable,
      selectingMode: widget.selectable ? TrinaGridSelectingMode.row : TrinaGridSelectingMode.cell,
      rowSelectionCheckBoxBehavior: TrinaGridRowSelectionCheckBoxBehavior.none,
      style: style,
      scrollbar: const TrinaGridScrollbarConfig(isAlwaysShown: true, isDraggable: true),
      columnSize: const TrinaGridColumnSizeConfig(autoSizeMode: TrinaAutoSizeMode.none, resizeMode: TrinaResizeMode.normal),
    );
  }

  void _handleGridChanged(TrinaGridOnChangedEvent event) {
    final rowId = _rowIdFromTrina(event.row);
    if (rowId == null) return;
    _controller.editCell(rowId, event.column.field, event.value);
    widget.onCellChanged?.call(GLTableCellChange(rowId: rowId, columnKey: event.column.field, value: event.value, oldValue: event.oldValue));
  }

  void _handleRowChecked(TrinaGridOnRowCheckedEvent event) {
    if (!widget.selectable) return;
    final checkedRows = _stateManager?.checkedRows ?? const <TrinaRow>[];
    _controller.replaceSelected({
      for (final row in checkedRows)
        if (_rowIdFromTrina(row) != null) _rowIdFromTrina(row)!,
    });
  }

  String? _rowIdFromTrina(TrinaRow row) => row.metadata?['glRowId'] as String?;
}

class GLResponsiveDataCards extends StatelessWidget {
  final List<GLTableColumn> columns;
  final GLTableController controller;
  final bool selectable;
  const GLResponsiveDataCards({super.key, required this.columns, required this.controller, this.selectable = true});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    return Column(children: [
      for (final row in controller.rows) ...[
        GLCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (selectable) Checkbox(value: controller.selectedIds.contains(row.id), onChanged: (_) => controller.toggleSelected(row.id), activeColor: GeniusThemeData.blue500),
              Expanded(child: Text('${row.cells[columns.first.key] ?? row.id}', style: TextStyle(fontFamily: GeniusThemeData.displayFont, fontSize: 15, fontWeight: FontWeight.w800, color: s.fg1))),
            ]),
            const SizedBox(height: 10),
            for (final col in columns.skip(1))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 120, child: Text(col.label.toUpperCase(), style: TextStyle(fontFamily: GeniusThemeData.monoFont, fontSize: 10.5, color: s.fg3, fontWeight: FontWeight.w800))),
                  Expanded(child: Text('${row.cells[col.key] ?? ''}', textAlign: col.numeric ? TextAlign.end : TextAlign.start, style: TextStyle(fontFamily: col.numeric ? GeniusThemeData.monoFont : GeniusThemeData.bodyFont, fontSize: 12.5, color: s.fg1, fontWeight: FontWeight.w700))),
                ]),
              ),
          ]),
        ),
        const SizedBox(height: 10),
      ],
    ]);
  }
}

class GLTableStateBox extends StatelessWidget {
  final String kind;
  const GLTableStateBox({super.key, this.kind = 'empty'});

  @override
  Widget build(BuildContext context) {
    if (kind == 'loading') return const GLCard(child: SizedBox(height: 160, child: Center(child: GLSpinner(size: 30))));
    if (kind == 'error') return const GLCard(child: SizedBox(height: 160, child: GLStateView(icon: 'alert', title: 'Could not load rows', body: 'Retry after the table data service becomes available.', actionLabel: 'Retry', tone: GLStateTone.danger)));
    return const GLCard(child: SizedBox(height: 160, child: GLStateView(icon: 'table', title: 'No table rows', body: 'Saved records will appear here.')));
  }
}

List<GLTableColumn> glSampleColumns() => const [
      GLTableColumn(key: 'account', label: 'Account', flex: 2, editable: false, frozen: true),
      GLTableColumn(key: 'code', label: 'Code'),
      GLTableColumn(key: 'debit', label: 'Debit', numeric: true, type: GLTableColumnType.currency),
      GLTableColumn(key: 'credit', label: 'Credit', numeric: true, type: GLTableColumnType.currency),
      GLTableColumn(key: 'status', label: 'Status', type: GLTableColumnType.select, options: ['posted', 'draft', 'review']),
    ];

List<GLTableRowModel> glSampleRows() => [
      GLTableRowModel(id: '1', cells: {'account': 'Cash on hand', 'code': '1010', 'debit': 42000, 'credit': 0, 'status': 'posted'}),
      GLTableRowModel(id: '2', cells: {'account': 'Sales revenue', 'code': '4100', 'debit': 0, 'credit': 42000, 'status': 'posted'}),
      GLTableRowModel(id: '3', cells: {'account': 'Inventory variance', 'code': '5140', 'debit': 2140, 'credit': 0, 'status': 'draft'}),
    ];
