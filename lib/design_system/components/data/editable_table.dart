// ============================================================
// GeniusLink Design System — Editable table.
// Source parity: components-table.html.
// Architecture: MVVM. GLTableController owns row state, selection and sorting.
// ============================================================

import 'package:flutter/material.dart';
import '../../tokens.dart';
import '../core/core_components.dart';

class GLTableColumn {
  final String key;
  final String label;
  final int flex;
  final bool numeric;
  final bool editable;
  const GLTableColumn({required this.key, required this.label, this.flex = 1, this.numeric = false, this.editable = true});
}

class GLTableRowModel {
  final String id;
  final Map<String, String> cells;
  GLTableRowModel({required this.id, required Map<String, String> cells}) : cells = Map<String, String>.from(cells);

  GLTableRowModel copyWith({String? id, Map<String, String>? cells}) => GLTableRowModel(id: id ?? this.id, cells: cells ?? this.cells);
}

class GLTableController extends ChangeNotifier {
  GLTableController({List<GLTableRowModel> rows = const []}) : _rows = [...rows];

  final List<GLTableRowModel> _rows;
  final Set<String> _selected = {};
  String? _sortKey;
  bool _sortAsc = true;

  List<GLTableRowModel> get rows => List.unmodifiable(_rows);
  Set<String> get selectedIds => Set.unmodifiable(_selected);
  String? get sortKey => _sortKey;
  bool get sortAsc => _sortAsc;

  void toggleSelected(String id) {
    if (_selected.contains(id)) {
      _selected.remove(id);
    } else {
      _selected.add(id);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selected.clear();
    notifyListeners();
  }

  void editCell(String id, String key, String value) {
    GLTableRowModel? row;
    for (final candidate in _rows) {
      if (candidate.id == id) {
        row = candidate;
        break;
      }
    }
    if (row == null) return;
    row.cells[key] = value;
    notifyListeners();
  }

  void addRow(GLTableRowModel row) {
    _rows.add(row);
    notifyListeners();
  }

  void deleteSelected() {
    _rows.removeWhere((r) => _selected.contains(r.id));
    _selected.clear();
    notifyListeners();
  }

  void sortBy(String key) {
    if (_sortKey == key) {
      _sortAsc = !_sortAsc;
    } else {
      _sortKey = key;
      _sortAsc = true;
    }
    _rows.sort((a, b) {
      final av = a.cells[key] ?? '';
      final bv = b.cells[key] ?? '';
      final an = num.tryParse(av.replaceAll(RegExp(r'[^0-9\.-]'), ''));
      final bn = num.tryParse(bv.replaceAll(RegExp(r'[^0-9\.-]'), ''));
      final result = an != null && bn != null ? an.compareTo(bn) : av.compareTo(bv);
      return _sortAsc ? result : -result;
    });
    notifyListeners();
  }
}

class GLEditableTable extends StatefulWidget {
  final List<GLTableColumn> columns;
  final GLTableController? controller;
  final List<GLTableRowModel> rows;
  final bool selectable;
  final bool editable;
  final String emptyTitle;
  final String emptyBody;
  const GLEditableTable({
    super.key,
    required this.columns,
    this.controller,
    this.rows = const [],
    this.selectable = true,
    this.editable = true,
    this.emptyTitle = 'No rows yet',
    this.emptyBody = 'Created rows will appear here.',
  });

  @override
  State<GLEditableTable> createState() => _GLEditableTableState();
}

class _GLEditableTableState extends State<GLEditableTable> {
  late GLTableController _controller;
  late bool _owns;

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
    final s = GeniusThemeData.of(context);
    if (_controller.rows.isEmpty) {
      return GLCard(child: SizedBox(height: 220, child: GLStateView(icon: 'table', title: widget.emptyTitle, body: widget.emptyBody)));
    }
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < GeniusThemeData.bpMd) {
        return GLResponsiveDataCards(columns: widget.columns, controller: _controller, selectable: widget.selectable);
      }
      return GLCard(
        padding: 0,
        child: Column(children: [
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: s.border))),
            child: Row(children: [
              if (widget.selectable) const SizedBox(width: 44),
              for (final col in widget.columns)
                Expanded(
                  flex: col.flex,
                  child: InkWell(
                    onTap: () => _controller.sortBy(col.key),
                    child: Row(mainAxisAlignment: col.numeric ? MainAxisAlignment.end : MainAxisAlignment.start, children: [
                      Flexible(child: Text(col.label.toUpperCase(), overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: GeniusThemeData.monoFont, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: .8, color: GeniusThemeData.blue500))),
                      if (_controller.sortKey == col.key) Icon(_controller.sortAsc ? Icons.arrow_drop_up : Icons.arrow_drop_down, size: 18, color: GeniusThemeData.blue500),
                    ]),
                  ),
                ),
              if (widget.editable) const SizedBox(width: 44),
            ]),
          ),
          for (final row in _controller.rows) _TableDataRow(row: row, columns: widget.columns, controller: _controller, selectable: widget.selectable, editable: widget.editable),
        ]),
      );
    });
  }
}

class _TableDataRow extends StatelessWidget {
  final GLTableRowModel row;
  final List<GLTableColumn> columns;
  final GLTableController controller;
  final bool selectable;
  final bool editable;
  const _TableDataRow({required this.row, required this.columns, required this.controller, required this.selectable, required this.editable});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    final selected = controller.selectedIds.contains(row.id);
    return Container(
      minHeight: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: selected ? GeniusThemeData.blue500.withOpacity(.08) : Colors.transparent, border: Border(bottom: BorderSide(color: s.border.withOpacity(.65)))),
      child: Row(children: [
        if (selectable) SizedBox(width: 44, child: Checkbox(value: selected, onChanged: (_) => controller.toggleSelected(row.id), activeColor: GeniusThemeData.blue500)),
        for (final col in columns)
          Expanded(
            flex: col.flex,
            child: Align(
              alignment: col.numeric ? Alignment.centerRight : Alignment.centerLeft,
              child: editable && col.editable ? _EditableCell(initial: row.cells[col.key] ?? '', onSubmit: (v) => controller.editCell(row.id, col.key, v), numeric: col.numeric) : _CellText(value: row.cells[col.key] ?? '', numeric: col.numeric),
            ),
          ),
        if (editable) SizedBox(width: 44, child: GLIconButton(icon: 'edit', tooltip: 'Edit row', onPressed: () {})),
      ]),
    );
  }
}

class _CellText extends StatelessWidget {
  final String value;
  final bool numeric;
  const _CellText({required this.value, required this.numeric});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    return Text(value, textAlign: numeric ? TextAlign.end : TextAlign.start, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: numeric ? GeniusThemeData.monoFont : GeniusThemeData.bodyFont, fontSize: 12.8, fontWeight: FontWeight.w600, color: s.fg1));
  }
}

class _EditableCell extends StatefulWidget {
  final String initial;
  final bool numeric;
  final ValueChanged<String> onSubmit;
  const _EditableCell({required this.initial, required this.onSubmit, required this.numeric});

  @override
  State<_EditableCell> createState() => _EditableCellState();
}

class _EditableCellState extends State<_EditableCell> {
  late final TextEditingController _ctl = TextEditingController(text: widget.initial);
  bool _editing = false;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    if (!_editing) {
      return InkWell(onTap: () => setState(() => _editing = true), child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: _CellText(value: widget.initial, numeric: widget.numeric)));
    }
    return SizedBox(
      height: 36,
      child: TextField(
        controller: _ctl,
        autofocus: true,
        textAlign: widget.numeric ? TextAlign.end : TextAlign.start,
        style: TextStyle(fontFamily: widget.numeric ? GeniusThemeData.monoFont : GeniusThemeData.bodyFont, fontSize: 12.8, color: s.fg1),
        decoration: InputDecoration(isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), filled: true, fillColor: s.inputBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(GeniusThemeData.radiusSm), borderSide: BorderSide(color: s.border))),
        onSubmitted: (v) {
          widget.onSubmit(v);
          setState(() => _editing = false);
        },
        onTapOutside: (_) {
          widget.onSubmit(_ctl.text);
          setState(() => _editing = false);
        },
      ),
    );
  }
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
              Expanded(child: Text(row.cells[columns.first.key] ?? row.id, style: TextStyle(fontFamily: GeniusThemeData.displayFont, fontSize: 15, fontWeight: FontWeight.w800, color: s.fg1))),
            ]),
            const SizedBox(height: 10),
            for (final col in columns.skip(1))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 120, child: Text(col.label.toUpperCase(), style: TextStyle(fontFamily: GeniusThemeData.monoFont, fontSize: 10.5, color: s.fg3, fontWeight: FontWeight.w800))),
                  Expanded(child: Text(row.cells[col.key] ?? '', textAlign: col.numeric ? TextAlign.end : TextAlign.start, style: TextStyle(fontFamily: col.numeric ? GeniusThemeData.monoFont : GeniusThemeData.bodyFont, fontSize: 12.5, color: s.fg1, fontWeight: FontWeight.w700))),
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
      GLTableColumn(key: 'account', label: 'Account', flex: 2, editable: false),
      GLTableColumn(key: 'code', label: 'Code'),
      GLTableColumn(key: 'debit', label: 'Debit', numeric: true),
      GLTableColumn(key: 'credit', label: 'Credit', numeric: true),
      GLTableColumn(key: 'status', label: 'Status'),
    ];

List<GLTableRowModel> glSampleRows() => [
      GLTableRowModel(id: '1', cells: {'account': 'Cash on hand', 'code': '1010', 'debit': 'SAR 42,000', 'credit': '—', 'status': 'posted'}),
      GLTableRowModel(id: '2', cells: {'account': 'Sales revenue', 'code': '4100', 'debit': '—', 'credit': 'SAR 42,000', 'status': 'posted'}),
      GLTableRowModel(id: '3', cells: {'account': 'Inventory variance', 'code': '5140', 'debit': 'SAR 2,140', 'credit': '—', 'status': 'draft'}),
    ];
