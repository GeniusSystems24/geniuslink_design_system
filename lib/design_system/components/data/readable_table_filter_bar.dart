// ============================================================
// ReadableTable — FILTER BAR (view layer for the advanced filter system).
// ------------------------------------------------------------
// The interactive surface over a ReadableTableController's filter state. It is
// a thin render of the controller (same MVC contract as ReadableTable itself):
// it reads `controller.filters` / `.query` / `.filterJoin` and calls back into
// `addFilter` / `updateFilterAt` / `removeFilterAt` / `setQuery` …  — holding
// no filter state of its own.
//
//   ReadableFilterBar(controller: tableController)   // place ABOVE the table
//
// Pieces, all themed via EditableTableThemeData so they sit flush with the grid:
//   • a quick-search field (cross-column substring match),
//   • an "＋ Filter" button that opens the per-column editor popover,
//   • a row of removable filter CHIPS (tap to edit · ✕ to remove · the dot
//     toggles enabled), with an AND/OR segmented control between them,
//   • a results count + "Clear all".
//
//   File: lib/design_system/components/data/readable_table_filter_bar.dart
// ============================================================

import 'package:flutter/material.dart';
import 'editable_table_theme.dart';
import 'readable_table_models.dart';
import 'readable_table_controller.dart';
import 'readable_table_filter.dart';

class ReadableFilterBar<T> extends StatefulWidget {
  /// The grid this bar filters. Required — the bar holds no state of its own.
  final ReadableTableController<T> controller;

  /// Show the cross-column quick-search field.
  final bool showSearch;

  /// Show the live "N of M" results count + Clear-all.
  final bool showCount;

  /// Placeholder for the quick-search field.
  final String searchHint;

  /// Singular/plural noun for the count ("3 of 20 accounts").
  final String itemNoun;
  final String itemNounPlural;

  const ReadableFilterBar({
    super.key,
    required this.controller,
    this.showSearch = true,
    this.showCount = true,
    this.searchHint = 'Search…',
    this.itemNoun = 'row',
    this.itemNounPlural = 'rows',
  });

  @override
  State<ReadableFilterBar<T>> createState() => _ReadableFilterBarState<T>();
}

class _ReadableFilterBarState<T> extends State<ReadableFilterBar<T>> {
  late final TextEditingController _search = TextEditingController(text: widget.controller.query);
  final FocusNode _searchFocus = FocusNode();

  ReadableTableController<T> get _c => widget.controller;
  EditableTableThemeData get _t => EditableTableThemeData.of(context);

  @override
  void initState() {
    super.initState();
    _c.addListener(_sync);
  }

  void _sync() {
    if (_search.text != _c.query) _search.text = _c.query;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _c.removeListener(_sync);
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── filterable columns (logical indices) ───────────────────
  List<int> get _filterableColumns =>
      [for (var i = 0; i < _c.colCount; i++) if (_c.isColumnFilterable(i)) i];

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final filters = _c.filters;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: t.bg,
        border: Border.all(color: t.borderStrong),
        borderRadius: BorderRadius.circular(EditableTableThemeData.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // top row: search · add filter · count
          Row(
            children: [
              if (widget.showSearch) Expanded(child: _searchField(t)) else const Spacer(),
              const SizedBox(width: 8),
              _addFilterButton(t),
              if (widget.showCount) ...[
                const SizedBox(width: 10),
                _count(t),
              ],
            ],
          ),
          // chips
          if (filters.isNotEmpty) ...[
            const SizedBox(height: 9),
            _chipsRow(t, filters),
          ],
        ],
      ),
    );
  }

  // ── quick search ───────────────────────────────────────────
  Widget _searchField(EditableTableThemeData t) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: t.inputBg,
        borderRadius: BorderRadius.circular(EditableTableThemeData.radiusSm),
        border: Border.all(color: _searchFocus.hasFocus ? EditableTableThemeData.accent : t.border),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 16, color: t.fg3),
          const SizedBox(width: 7),
          Expanded(
            child: TextField(
              controller: _search,
              focusNode: _searchFocus,
              onChanged: _c.setQuery,
              cursorColor: EditableTableThemeData.accent,
              style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 13, color: t.fg1),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: widget.searchHint,
                hintStyle: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 13, color: t.fg3),
              ),
            ),
          ),
          if (_search.text.isNotEmpty)
            _IconBtn(
              icon: Icons.close_rounded,
              color: t.fg3,
              onTap: () {
                _search.clear();
                _c.setQuery('');
              },
            ),
        ],
      ),
    );
  }

  // ── add-filter button ──────────────────────────────────────
  Widget _addFilterButton(EditableTableThemeData t) {
    final filterable = _filterableColumns;
    final enabled = filterable.isNotEmpty;
    return _Pill(
      label: 'Filter',
      icon: Icons.add_rounded,
      accent: true,
      enabled: enabled,
      onTap: enabled ? () => _openEditor(context, columnChoices: filterable) : null,
    );
  }

  // ── results count + clear-all ──────────────────────────────
  Widget _count(EditableTableThemeData t) {
    final shown = _c.rowCount;
    final total = _c.totalRowCount;
    final noun = total == 1 ? widget.itemNoun : widget.itemNounPlural;
    final filtered = _c.isFiltered;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          filtered ? '$shown of $total $noun' : '$total $noun',
          style: TextStyle(
            fontFamily: EditableTableThemeData.monoFont,
            fontSize: 11.5,
            color: filtered ? EditableTableThemeData.accent : t.fg3,
          ),
        ),
        if (_c.hasFilters) ...[
          const SizedBox(width: 8),
          _Pill(label: 'Clear all', onTap: _c.clearFilters),
        ],
      ],
    );
  }

  // ── chips row + AND/OR join ────────────────────────────────
  Widget _chipsRow(EditableTableThemeData t, List<ReadableFilter> filters) {
    final children = <Widget>[];
    for (var i = 0; i < filters.length; i++) {
      if (i > 0) children.add(_joinToggle(t));
      children.add(_chip(t, i, filters[i]));
    }
    return Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: children);
  }

  Widget _joinToggle(EditableTableThemeData t) {
    final isAll = _c.filterJoin == ReadableFilterJoin.all;
    return GestureDetector(
      onTap: () => _c.setFilterJoin(isAll ? ReadableFilterJoin.any : ReadableFilterJoin.all),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: t.inputBg,
          borderRadius: BorderRadius.circular(EditableTableThemeData.radiusSm),
          border: Border.all(color: t.border),
        ),
        child: Text(
          isAll ? 'AND' : 'OR',
          style: const TextStyle(
            fontFamily: EditableTableThemeData.monoFont,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: EditableTableThemeData.accent,
          ),
        ),
      ),
    );
  }

  Widget _chip(EditableTableThemeData t, int index, ReadableFilter f) {
    final col = (f.columnIndex >= 0 && f.columnIndex < _c.colCount) ? _c.columns[f.columnIndex] : null;
    final on = f.enabled;
    final summary = col == null ? 'Filter' : ReadableFilterCatalog.summary(f, col);
    return Container(
      decoration: BoxDecoration(
        color: on ? _t.selectionFill(0.10) : t.surface,
        borderRadius: BorderRadius.circular(EditableTableThemeData.radiusSm),
        border: Border.all(color: on ? EditableTableThemeData.accent.withOpacity(0.55) : t.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // enabled toggle dot
          _HoverTap(
            onTap: () => _c.toggleFilterAt(index),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: on ? EditableTableThemeData.accent : Colors.transparent,
                  border: Border.all(
                    color: on ? EditableTableThemeData.accent : t.fg4,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
          // summary (tap to edit)
          _HoverTap(
            onTap: () => _openEditor(context, columnChoices: _filterableColumns, editIndex: index),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              child: Text(
                summary,
                style: TextStyle(
                  fontFamily: EditableTableThemeData.bodyFont,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: on ? t.fg1 : t.fg3,
                  decoration: on ? null : TextDecoration.lineThrough,
                ),
              ),
            ),
          ),
          // remove
          _HoverTap(
            onTap: () => _c.removeFilterAt(index),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 8, 6),
              child: Icon(Icons.close_rounded, size: 14, color: t.fg3),
            ),
          ),
        ],
      ),
    );
  }

  // ── editor popover ─────────────────────────────────────────
  Future<void> _openEditor(BuildContext context,
      {required List<int> columnChoices, int? editIndex}) async {
    final existing = editIndex != null ? _c.filters[editIndex] : null;
    final result = await showDialog<ReadableFilter>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (ctx) => _FilterEditorDialog<T>(
        controller: _c,
        theme: _t,
        columnChoices: columnChoices,
        initial: existing,
      ),
    );
    if (result == null) return;
    if (editIndex != null) {
      _c.updateFilterAt(editIndex, result);
    } else {
      _c.addFilter(result);
    }
  }
}

// ============================================================
// Filter editor dialog — pick column → operator → operand(s).
// ============================================================
class _FilterEditorDialog<T> extends StatefulWidget {
  final ReadableTableController<T> controller;
  final EditableTableThemeData theme;
  final List<int> columnChoices;
  final ReadableFilter? initial;

  const _FilterEditorDialog({
    required this.controller,
    required this.theme,
    required this.columnChoices,
    this.initial,
  });

  @override
  State<_FilterEditorDialog<T>> createState() => _FilterEditorDialogState<T>();
}

class _FilterEditorDialogState<T> extends State<_FilterEditorDialog<T>> {
  late int _columnIndex;
  late ReadableFilterOp _op;
  final TextEditingController _v1 = TextEditingController();
  final TextEditingController _v2 = TextEditingController();
  DateTime? _d1;
  DateTime? _d2;
  final Set<String> _options = {};

  EditableTableThemeData get t => widget.theme;
  ReadableTableController<T> get c => widget.controller;
  ReadableColumn<T> get _col => c.columns[_columnIndex];
  ReadableColumnType get _type => _col.type;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _columnIndex = init?.columnIndex ?? widget.columnChoices.first;
    if (!widget.columnChoices.contains(_columnIndex)) _columnIndex = widget.columnChoices.first;
    final ops = ReadableFilterCatalog.opsFor(_type);
    _op = init != null && ops.contains(init.op) ? init.op : ops.first;
    _hydrateOperands(init);
  }

  void _hydrateOperands(ReadableFilter? init) {
    _v1.text = '';
    _v2.text = '';
    _d1 = null;
    _d2 = null;
    _options.clear();
    if (init == null) return;
    if (init.value is DateTime) {
      _d1 = init.value as DateTime;
    } else if (init.value != null) {
      _v1.text = init.value.toString();
    }
    if (init.value2 is DateTime) {
      _d2 = init.value2 as DateTime;
    } else if (init.value2 != null) {
      _v2.text = init.value2.toString();
    }
    _options.addAll(init.options);
  }

  @override
  void dispose() {
    _v1.dispose();
    _v2.dispose();
    super.dispose();
  }

  bool get _isDate => _type == ReadableColumnType.date;
  bool get _isNumeric => _type == ReadableColumnType.number || _type == ReadableColumnType.progress;

  void _onColumnChanged(int ci) {
    setState(() {
      _columnIndex = ci;
      final ops = ReadableFilterCatalog.opsFor(_type);
      if (!ops.contains(_op)) _op = ops.first;
      _v1.text = '';
      _v2.text = '';
      _d1 = null;
      _d2 = null;
      _options.clear();
    });
  }

  ReadableFilter? _build() {
    final arity = ReadableFilterCatalog.arity(_op);
    switch (arity) {
      case ReadableFilterArity.none:
        return ReadableFilter(columnIndex: _columnIndex, op: _op);
      case ReadableFilterArity.one:
        if (_isDate) {
          if (_d1 == null) return null;
          return ReadableFilter(columnIndex: _columnIndex, op: _op, value: _d1);
        }
        if (_isNumeric) {
          final n = num.tryParse(_v1.text.trim());
          if (n == null) return null;
          return ReadableFilter(columnIndex: _columnIndex, op: _op, value: n);
        }
        if (_v1.text.trim().isEmpty) return null;
        return ReadableFilter(columnIndex: _columnIndex, op: _op, value: _v1.text.trim());
      case ReadableFilterArity.two:
        if (_isDate) {
          if (_d1 == null || _d2 == null) return null;
          return ReadableFilter(columnIndex: _columnIndex, op: _op, value: _d1, value2: _d2);
        }
        final a = num.tryParse(_v1.text.trim());
        final b = num.tryParse(_v2.text.trim());
        if (a == null || b == null) return null;
        return ReadableFilter(columnIndex: _columnIndex, op: _op, value: a, value2: b);
      case ReadableFilterArity.set:
        if (_options.isEmpty) return null;
        return ReadableFilter(columnIndex: _columnIndex, op: _op, options: {..._options});
    }
  }

  @override
  Widget build(BuildContext context) {
    final ops = ReadableFilterCatalog.opsFor(_type);
    final arity = ReadableFilterCatalog.arity(_op);
    final valid = _build() != null;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 380,
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(EditableTableThemeData.radiusLg),
            border: Border.all(color: t.borderStrong),
            boxShadow: EditableTableThemeData.popShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FILTER',
                  style: TextStyle(
                      fontFamily: EditableTableThemeData.bodyFont,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: EditableTableThemeData.accent)),
              const SizedBox(height: 4),
              Text(widget.initial == null ? 'Add filter' : 'Edit filter',
                  style: TextStyle(
                      fontFamily: EditableTableThemeData.displayFont,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: t.fg1)),
              const SizedBox(height: 16),
              _fieldLabel('Column'),
              const SizedBox(height: 6),
              _dropdown<int>(
                value: _columnIndex,
                items: [
                  for (final ci in widget.columnChoices)
                    DropdownMenuItem(
                      value: ci,
                      child: Text(c.columns[ci].label.isEmpty ? 'Column ${ci + 1}' : c.columns[ci].label,
                          style: _itemStyle()),
                    ),
                ],
                onChanged: (v) => v == null ? null : _onColumnChanged(v),
              ),
              const SizedBox(height: 12),
              _fieldLabel('Condition'),
              const SizedBox(height: 6),
              _dropdown<ReadableFilterOp>(
                value: _op,
                items: [
                  for (final op in ops)
                    DropdownMenuItem(
                      value: op,
                      child: Text(ReadableFilterCatalog.label(op, _type), style: _itemStyle()),
                    ),
                ],
                onChanged: (v) => v == null ? null : setState(() => _op = v),
              ),
              if (arity != ReadableFilterArity.none) ...[
                const SizedBox(height: 12),
                _fieldLabel('Value'),
                const SizedBox(height: 6),
                _operandEditor(arity),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _Pill(label: 'Cancel', onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: 8),
                  _Pill(
                    label: widget.initial == null ? 'Add filter' : 'Save',
                    accent: true,
                    filled: true,
                    enabled: valid,
                    onTap: valid ? () => Navigator.of(context).pop(_build()) : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── operand editors per arity / type ───────────────────────
  Widget _operandEditor(ReadableFilterArity arity) {
    switch (arity) {
      case ReadableFilterArity.none:
        return const SizedBox.shrink();
      case ReadableFilterArity.set:
        return _optionPicker();
      case ReadableFilterArity.two:
        return Row(
          children: [
            Expanded(child: _isDate ? _dateField(isSecond: false) : _numberField(_v1, 'From')),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('and', style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 12, color: t.fg3)),
            ),
            Expanded(child: _isDate ? _dateField(isSecond: true) : _numberField(_v2, 'To')),
          ],
        );
      case ReadableFilterArity.one:
        if (_isDate) return _dateField(isSecond: false);
        if (_isNumeric) return _numberField(_v1, 'Number');
        // text — offer a value suggestion menu when the column has few distincts
        return _textField(_v1, 'Text');
    }
  }

  Widget _optionPicker() {
    final values = c.distinctValues(_columnIndex);
    if (values.isEmpty) {
      return Text('No values', style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 12, color: t.fg3));
    }
    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final v in values)
              _SelectableChip(
                label: v,
                selected: _options.contains(v),
                theme: t,
                onTap: () => setState(() => _options.contains(v) ? _options.remove(v) : _options.add(v)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, String hint) {
    return _InputShell(
      theme: t,
      child: TextField(
        controller: ctrl,
        autofocus: true,
        onChanged: (_) => setState(() {}),
        cursorColor: EditableTableThemeData.accent,
        style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 13, color: t.fg1),
        decoration: _inputDecoration(hint),
      ),
    );
  }

  Widget _numberField(TextEditingController ctrl, String hint) {
    return _InputShell(
      theme: t,
      child: TextField(
        controller: ctrl,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        onChanged: (_) => setState(() {}),
        cursorColor: EditableTableThemeData.accent,
        style: TextStyle(fontFamily: EditableTableThemeData.monoFont, fontSize: 13, color: t.fg1),
        decoration: _inputDecoration(hint),
      ),
    );
  }

  Widget _dateField({required bool isSecond}) {
    final value = isSecond ? _d2 : _d1;
    String label() {
      if (value == null) return isSecond ? 'End date' : 'Pick a date';
      String two(int n) => n.toString().padLeft(2, '0');
      return '${value.year}-${two(value.month)}-${two(value.day)}';
    }

    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: DateTime(now.year - 50),
          lastDate: DateTime(now.year + 50),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: (t.bg.computeLuminance() < 0.5 ? const ColorScheme.dark() : const ColorScheme.light())
                  .copyWith(primary: EditableTableThemeData.accent),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          setState(() => isSecond ? _d2 = picked : _d1 = picked);
        }
      },
      child: _InputShell(
        theme: t,
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 14, color: t.fg3),
            const SizedBox(width: 8),
            Text(label(),
                style: TextStyle(
                    fontFamily: EditableTableThemeData.monoFont,
                    fontSize: 13,
                    color: value == null ? t.fg3 : t.fg1)),
          ],
        ),
      ),
    );
  }

  // ── small helpers ──────────────────────────────────────────
  Widget _fieldLabel(String s) => Text(
        s.toUpperCase(),
        style: TextStyle(
            fontFamily: EditableTableThemeData.bodyFont,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: t.fg3),
      );

  TextStyle _itemStyle() => TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 13, color: t.fg1);

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        isDense: true,
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        hintText: hint,
        hintStyle: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 13, color: t.fg3),
      );

  Widget _dropdown<V>({
    required V value,
    required List<DropdownMenuItem<V>> items,
    required ValueChanged<V?> onChanged,
  }) {
    return _InputShell(
      theme: t,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<V>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          isDense: true,
          dropdownColor: t.surface,
          iconEnabledColor: t.fg3,
          borderRadius: BorderRadius.circular(EditableTableThemeData.radiusSm),
          style: _itemStyle(),
        ),
      ),
    );
  }
}

// ============================================================
// Shared little widgets (kept private to the filter bar file).
// ============================================================

/// A bordered field shell matching the editable-table input look.
class _InputShell extends StatelessWidget {
  final Widget child;
  final EditableTableThemeData theme;
  const _InputShell({required this.child, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: theme.inputBg,
        borderRadius: BorderRadius.circular(EditableTableThemeData.radiusSm),
        border: Border.all(color: theme.border),
      ),
      child: child,
    );
  }
}

/// A pill button — neutral by default, accent/filled variants for primaries.
class _Pill extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool accent;
  final bool filled;
  final bool enabled;
  final VoidCallback? onTap;
  const _Pill({
    required this.label,
    this.icon,
    this.accent = false,
    this.filled = false,
    this.enabled = true,
    this.onTap,
  });

  @override
  State<_Pill> createState() => _PillState();
}

class _PillState extends State<_Pill> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = EditableTableThemeData.of(context);
    final disabled = !widget.enabled || widget.onTap == null;
    final fg = widget.filled
        ? Colors.white
        : (widget.accent ? EditableTableThemeData.accent : t.fg2);
    Color? bg;
    if (widget.filled) {
      bg = EditableTableThemeData.accent.withOpacity(disabled ? 0.4 : 1);
    } else if (_hover && !disabled) {
      bg = t.hover;
    } else {
      bg = Colors.transparent;
    }
    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: disabled ? null : widget.onTap,
        child: Opacity(
          opacity: disabled && !widget.filled ? 0.5 : 1,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: widget.icon != null ? 11 : 13, vertical: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(EditableTableThemeData.radiusMd),
              border: widget.filled
                  ? null
                  : Border.all(color: widget.accent ? EditableTableThemeData.accent.withOpacity(0.5) : t.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 15, color: fg),
                  const SizedBox(width: 5),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: EditableTableThemeData.bodyFont,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A round icon button used inside the search field.
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(padding: const EdgeInsets.all(2), child: Icon(icon, size: 15, color: color)),
      ),
    );
  }
}

/// A bare hover-highlight tap region for chip sub-targets.
class _HoverTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _HoverTap({required this.child, required this.onTap});

  @override
  State<_HoverTap> createState() => _HoverTapState();
}

class _HoverTapState extends State<_HoverTap> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Opacity(opacity: _hover ? 0.7 : 1, child: widget.child),
      ),
    );
  }
}

/// A toggleable value chip used by the `is any of` option picker.
class _SelectableChip extends StatelessWidget {
  final String label;
  final bool selected;
  final EditableTableThemeData theme;
  final VoidCallback onTap;
  const _SelectableChip({required this.label, required this.selected, required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? theme.selectionFill(0.14) : theme.inputBg,
            borderRadius: BorderRadius.circular(EditableTableThemeData.radiusSm),
            border: Border.all(
              color: selected ? EditableTableThemeData.accent : theme.border,
              width: selected ? 1.3 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check_rounded, size: 13, color: EditableTableThemeData.accent),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: EditableTableThemeData.bodyFont,
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? theme.fg1 : theme.fg2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
