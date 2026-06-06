// ============================================================
// ReadableTable — FILTER EDITING VIEW (nested And/Or query builder).
// ------------------------------------------------------------
// A professional, flexible editor for the ReadableTable filter-system. Where
// the compact [ReadableFilterBar] edits a flat chip list, this view edits the
// full nested tree — `A AND (B OR (C AND D))` — exactly like Attio / Notion /
// Linear advanced filters, rendered in the GeniusLink visual language.
//
//   ReadableFilterEditingView<Account>(controller: tableController)
//
// It reads `controller.filterGroup`, lets the user build conditions and nested
// subgroups, and (by default) applies the tree live via `setFilterGroup` — so
// the grid filters as you edit. Every group has an And/Or rail pill; every
// condition is column → operator → typed value (text · number · date ·
// enum · multi-select), with the operator menu adapting to the column kind.
// Fully themed via [EditableTableThemeData] and RTL-aware (the rail mirrors).
//
//   File: lib/design_system/components/data/readable_table_filter_view.dart
// ============================================================

import 'package:flutter/material.dart';
import 'editable_table_theme.dart';
import 'readable_table_models.dart';
import 'readable_table_controller.dart';
import 'readable_table_filter.dart';

/// Local, slightly-softer radii for the editor's own surfaces (the grid uses
/// the tighter DS radii; an editing canvas reads better a touch rounder).
const double _kFieldRadius = 9;
const double _kGroupRadius = 13;

/// A nested And/Or filter builder bound to a [ReadableTableController].
class ReadableFilterEditingView<T> extends StatefulWidget {
  /// The grid whose `filterGroup` this view edits.
  final ReadableTableController<T> controller;

  /// Apply edits to the controller live (default). When false the tree is held
  /// internally and only pushed when you call [ReadableFilterEditingViewState.apply].
  final bool applyLive;

  /// Outer padding around the builder.
  final EdgeInsets padding;

  /// Width of the value field column.
  final double valueWidth;

  const ReadableFilterEditingView({
    super.key,
    required this.controller,
    this.applyLive = true,
    this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 16),
    this.valueWidth = 188,
  });

  @override
  State<ReadableFilterEditingView<T>> createState() => ReadableFilterEditingViewState<T>();
}

class ReadableFilterEditingViewState<T> extends State<ReadableFilterEditingView<T>> {
  late ReadableFilterGroup _root;

  ReadableTableController<T> get _c => widget.controller;
  EditableTableThemeData get _t => EditableTableThemeData.of(context);

  @override
  void initState() {
    super.initState();
    _root = _c.filterGroup ?? ReadableFilterGroup(join: ReadableFilterJoin.all, children: [_newCondition()]);
  }

  /// The columns the user may filter on (logical indices).
  List<int> get _filterable => [for (var i = 0; i < _c.colCount; i++) if (_c.isColumnFilterable(i)) i];

  /// A fresh, empty condition on the first filterable column.
  ReadableFilter _newCondition() {
    final ci = _filterable.isNotEmpty ? _filterable.first : 0;
    final type = ci < _c.colCount ? _c.columns[ci].type : ReadableColumnType.text;
    return ReadableFilter(columnIndex: ci, op: ReadableFilterCatalog.opsFor(type).first);
  }

  void _set(ReadableFilterGroup next) {
    setState(() => _root = next);
    if (widget.applyLive) _c.setFilterGroup(next);
  }

  /// Push the current tree to the controller (used when [applyLive] is false).
  void apply() => _c.setFilterGroup(_root);

  /// The current edited tree.
  ReadableFilterGroup get value => _root;

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(_kGroupRadius + 3),
        border: Border.all(color: t.border),
      ),
      child: _GroupView<T>(
        controller: _c,
        group: _root,
        onChanged: _set,
        depth: 0,
        filterable: _filterable,
        valueWidth: widget.valueWidth,
        newCondition: _newCondition,
      ),
    );
  }
}

// ============================================================
// GROUP (recursive)
// ============================================================
class _GroupView<T> extends StatelessWidget {
  final ReadableTableController<T> controller;
  final ReadableFilterGroup group;
  final ValueChanged<ReadableFilterGroup> onChanged;
  final int depth;
  final List<int> filterable;
  final double valueWidth;
  final ReadableFilter Function() newCondition;

  const _GroupView({
    required this.controller,
    required this.group,
    required this.onChanged,
    required this.depth,
    required this.filterable,
    required this.valueWidth,
    required this.newCondition,
  });

  bool get _isRoot => depth == 0;

  @override
  Widget build(BuildContext context) {
    final t = EditableTableThemeData.of(context);
    final multi = group.children.length > 1;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final children = <Widget>[];
    if (!_isRoot) {
      children.add(Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 8, top: 2),
        child: Text(
          group.join == ReadableFilterJoin.all ? 'All of the following are true:' : 'Any of the following are true:',
          style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 13.5, color: t.fg3),
        ),
      ));
    }

    for (var i = 0; i < group.children.length; i++) {
      final child = group.children[i];
      children.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _isRoot ? 58 : 50,
            child: Padding(
              padding: const EdgeInsets.only(top: 11),
              child: i == 0
                  ? Text('Where', style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 14, color: t.fg3))
                  : const SizedBox.shrink(),
            ),
          ),
          Expanded(
            child: child is ReadableFilterGroup
                ? _GroupView<T>(
                    controller: controller,
                    group: child,
                    onChanged: (g) => onChanged(group.withChildAt(i, g)),
                    depth: depth + 1,
                    filterable: filterable,
                    valueWidth: valueWidth,
                    newCondition: newCondition,
                  )
                : _ConditionRow<T>(
                    controller: controller,
                    node: child as ReadableFilter,
                    filterable: filterable,
                    valueWidth: valueWidth,
                    onChanged: (f) => onChanged(group.withChildAt(i, f)),
                    onRemove: () => onChanged(group.withoutChildAt(i)),
                  ),
          ),
        ],
      ));
    }

    // footer actions
    children.add(Padding(
      padding: EdgeInsets.only(top: 6, left: _isRoot ? 0 : 2),
      child: Row(
        children: [
          _LinkButton(
            icon: Icons.add_rounded,
            label: 'Add condition',
            color: EditableTableThemeData.accent,
            onTap: () => onChanged(group.withChildAdded(newCondition())),
          ),
          const SizedBox(width: 4),
          _LinkButton(
            icon: Icons.add_rounded,
            label: _isRoot ? 'Add group' : 'Add subgroup',
            color: t.fg2,
            onTap: () => onChanged(group.withChildAdded(
              ReadableFilterGroup(join: ReadableFilterJoin.any, children: [newCondition()]),
            )),
          ),
          if (_isRoot) ...[
            const Spacer(),
            _LinkButton(
              label: 'Clear all',
              color: t.fg3,
              onTap: () => onChanged(ReadableFilterGroup(join: ReadableFilterJoin.all, children: [newCondition()])),
            ),
          ],
        ],
      ),
    ));

    final body = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: children);

    // rail with the And/Or pill, drawn only when 2+ children
    final content = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (multi)
            _JoinRail(
              join: group.join,
              isRtl: isRtl,
              onToggle: () => onChanged(group.toggledJoin()),
            ),
          Expanded(child: body),
        ],
      ),
    );

    if (_isRoot) return content;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: Color.alphaBlend(t.fg1.withOpacity(0.035), t.surface),
        borderRadius: BorderRadius.circular(_kGroupRadius),
        border: Border.all(color: t.border),
      ),
      child: content,
    );
  }
}

// ── the vertical rail + centered And/Or pill ──
class _JoinRail extends StatelessWidget {
  final ReadableFilterJoin join;
  final bool isRtl;
  final VoidCallback onToggle;
  const _JoinRail({required this.join, required this.isRtl, required this.onToggle});

  static const double _w = 86;
  static const double _lineX = 30;

  @override
  Widget build(BuildContext context) {
    final t = EditableTableThemeData.of(context);
    final line = t.borderStrong;
    return SizedBox(
      width: _w,
      child: Stack(
        children: [
          // vertical spine
          PositionedDirectional(start: _lineX, top: 16, bottom: 16, child: Container(width: 1.5, color: line)),
          // top + bottom stubs
          PositionedDirectional(start: _lineX, top: 16, child: Container(width: 13, height: 1.5, color: line)),
          PositionedDirectional(start: _lineX, bottom: 16, child: Container(width: 13, height: 1.5, color: line)),
          // pill, vertically centered
          PositionedDirectional(
            start: 0,
            top: 0,
            bottom: 0,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _JoinPill(join: join, onTap: onToggle),
            ),
          ),
        ],
      ),
    );
  }
}

class _JoinPill extends StatelessWidget {
  final ReadableFilterJoin join;
  final VoidCallback onTap;
  const _JoinPill({required this.join, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = EditableTableThemeData.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(11, 7, 9, 7),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(EditableTableThemeData.radiusMd),
            border: Border.all(color: t.borderStrong),
            boxShadow: const [BoxShadow(color: Color(0x0F0F172A), blurRadius: 2, offset: Offset(0, 1))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                join == ReadableFilterJoin.all ? 'And' : 'Or',
                style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 13.5, fontWeight: FontWeight.w600, color: t.fg2),
              ),
              const SizedBox(width: 7),
              const Icon(Icons.swap_vert_rounded, size: 15, color: EditableTableThemeData.accent),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// CONDITION ROW — column → operator → typed value → delete
// ============================================================
class _ConditionRow<T> extends StatefulWidget {
  final ReadableTableController<T> controller;
  final ReadableFilter node;
  final List<int> filterable;
  final double valueWidth;
  final ValueChanged<ReadableFilter> onChanged;
  final VoidCallback onRemove;

  const _ConditionRow({
    required this.controller,
    required this.node,
    required this.filterable,
    required this.valueWidth,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<_ConditionRow<T>> createState() => _ConditionRowState<T>();
}

class _ConditionRowState<T> extends State<_ConditionRow<T>> {
  late final TextEditingController _v1 = TextEditingController(text: _txt(widget.node.value));
  late final TextEditingController _v2 = TextEditingController(text: _txt(widget.node.value2));

  ReadableFilter get _node => widget.node;
  ReadableColumn<T> get _col => widget.controller.columns[_node.columnIndex];
  ReadableColumnType get _type => _col.type;
  EditableTableThemeData get _t => EditableTableThemeData.of(context);

  static String _txt(Object? v) => v == null ? '' : (v is DateTime ? '' : v.toString());

  @override
  void didUpdateWidget(covariant _ConditionRow<T> old) {
    super.didUpdateWidget(old);
    // keep the text fields in sync when the node is replaced externally
    final n1 = _txt(widget.node.value), n2 = _txt(widget.node.value2);
    if (n1 != _v1.text) _v1.text = n1;
    if (n2 != _v2.text) _v2.text = n2;
  }

  @override
  void dispose() {
    _v1.dispose();
    _v2.dispose();
    super.dispose();
  }

  bool get _isDate => _type == ReadableColumnType.date;
  bool get _isNum => _type == ReadableColumnType.number || _type == ReadableColumnType.progress;

  // ── edits ──
  void _changeColumn(int ci) {
    final type = widget.controller.columns[ci].type;
    final op = ReadableFilterCatalog.opsFor(type).first;
    _v1.clear();
    _v2.clear();
    widget.onChanged(ReadableFilter(columnIndex: ci, op: op));
  }

  void _changeOp(ReadableFilterOp op) {
    // keep operands that still make sense; clear when the arity shifts
    final wasArity = ReadableFilterCatalog.arity(_node.op);
    final nowArity = ReadableFilterCatalog.arity(op);
    if (wasArity == nowArity) {
      widget.onChanged(_node.copyWith(op: op));
    } else {
      _v1.clear();
      _v2.clear();
      widget.onChanged(ReadableFilter(columnIndex: _node.columnIndex, op: op));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ops = ReadableFilterCatalog.opsFor(_type);
    final arity = ReadableFilterCatalog.arity(_node.op);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // column
                _SelectBox<int>(
                  grip: true,
                  width: 196,
                  value: _node.columnIndex,
                  items: widget.filterable,
                  labelOf: (ci) => widget.controller.columns[ci].label.isEmpty ? 'Column ${ci + 1}' : widget.controller.columns[ci].label,
                  onChanged: _changeColumn,
                ),
                // operator
                _SelectBox<ReadableFilterOp>(
                  width: 150,
                  value: _node.op,
                  items: ops,
                  labelOf: (op) => ReadableFilterCatalog.label(op, _type),
                  onChanged: _changeOp,
                ),
                // value(s)
                if (arity != ReadableFilterArity.none) _valueControl(arity),
              ],
            ),
          ),
          const SizedBox(width: 6),
          _IconButton(icon: Icons.delete_outline_rounded, danger: true, tooltip: 'Remove condition', onTap: widget.onRemove),
        ],
      ),
    );
  }

  // ── value control per arity / type ──
  Widget _valueControl(ReadableFilterArity arity) {
    if (arity == ReadableFilterArity.set) return _multiSelect();
    if (arity == ReadableFilterArity.two) {
      return SizedBox(
        width: widget.valueWidth + 70,
        child: Row(
          children: [
            Expanded(child: _isDate ? _dateField(second: false) : _numField(_v1, 'From', second: false)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('and', style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 13, color: _t.fg3)),
            ),
            Expanded(child: _isDate ? _dateField(second: true) : _numField(_v2, 'To', second: true)),
          ],
        ),
      );
    }
    // arity == one
    if (_isDate) return SizedBox(width: widget.valueWidth, child: _dateField(second: false));
    if (_isNum) return SizedBox(width: widget.valueWidth, child: _numField(_v1, 'Value', second: false));
    // enum / color → pick from distinct values; else free text
    if (_type == ReadableColumnType.enumBadge || _type == ReadableColumnType.color) {
      final values = widget.controller.distinctValues(_node.columnIndex);
      if (values.isNotEmpty) {
        final current = (_node.value?.toString().isNotEmpty ?? false) ? _node.value.toString() : values.first;
        return _SelectBox<String>(
          width: widget.valueWidth,
          value: values.contains(current) ? current : values.first,
          items: values,
          labelOf: (s) => s,
          onChanged: (s) => widget.onChanged(_node.copyWith(value: s)),
        );
      }
    }
    return SizedBox(width: widget.valueWidth, child: _textField(_v1, 'Enter a value'));
  }

  Widget _fieldShell({required Widget child}) {
    final t = _t;
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(_kFieldRadius),
        border: Border.all(color: t.borderStrong),
      ),
      child: child,
    );
  }

  Widget _textField(TextEditingController ctrl, String hint) {
    final t = _t;
    return _fieldShell(
      child: TextField(
        controller: ctrl,
        onChanged: (v) => widget.onChanged(_node.copyWith(value: v, clearValue: v.isEmpty)),
        cursorColor: EditableTableThemeData.accent,
        style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 14, color: t.fg1),
        decoration: _dec(hint),
      ),
    );
  }

  Widget _numField(TextEditingController ctrl, String hint, {required bool second}) {
    final t = _t;
    return _fieldShell(
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        onChanged: (v) {
          final n = num.tryParse(v.trim());
          widget.onChanged(second
              ? _node.copyWith(value2: n, clearValue2: n == null)
              : _node.copyWith(value: n, clearValue: n == null));
        },
        cursorColor: EditableTableThemeData.accent,
        style: TextStyle(fontFamily: EditableTableThemeData.monoFont, fontSize: 13.5, color: t.fg1),
        decoration: _dec(hint),
      ),
    );
  }

  Widget _dateField({required bool second}) {
    final t = _t;
    final value = (second ? _node.value2 : _node.value) as DateTime?;
    String label() {
      if (value == null) return second ? 'End date' : 'Pick a date';
      String two(int n) => n.toString().padLeft(2, '0');
      return '${value.year}-${two(value.month)}-${two(value.day)}';
    }

    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: DateTime(now.year - 60),
          lastDate: DateTime(now.year + 60),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: (t.bg.computeLuminance() < 0.5 ? const ColorScheme.dark() : const ColorScheme.light())
                  .copyWith(primary: EditableTableThemeData.accent),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          widget.onChanged(second ? _node.copyWith(value2: picked) : _node.copyWith(value: picked));
        }
      },
      child: _fieldShell(
        child: Row(
          children: [
            Icon(Icons.event_outlined, size: 15, color: t.fg3),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: EditableTableThemeData.monoFont, fontSize: 13.5, color: value == null ? t.fg3 : t.fg1)),
            ),
          ],
        ),
      ),
    );
  }

  // multi-select for isAnyOf / isNoneOf
  Widget _multiSelect() {
    final t = _t;
    final values = widget.controller.distinctValues(_node.columnIndex);
    final sel = _node.options;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          final result = await showDialog<Set<String>>(
            context: context,
            barrierColor: Colors.black.withOpacity(0.32),
            builder: (_) => _MultiSelectDialog(theme: t, title: _col.label, all: values, initial: sel),
          );
          if (result != null) widget.onChanged(_node.copyWith(options: result));
        },
        child: Container(
          width: widget.valueWidth,
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(_kFieldRadius),
            border: Border.all(color: t.borderStrong),
          ),
          child: Row(
            children: [
              Expanded(child: _selSummary(sel)),
              const SizedBox(width: 4),
              Icon(Icons.expand_more_rounded, size: 16, color: t.fg3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selSummary(Set<String> sel) {
    final t = _t;
    if (sel.isEmpty) {
      return Text('Select…', style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 14, color: t.fg3));
    }
    final list = sel.toList();
    final first = list.first;
    final extra = list.length - 1;
    return Row(
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: t.selectionFill(0.12),
              borderRadius: BorderRadius.circular(EditableTableThemeData.radiusSm + 6),
              border: Border.all(color: EditableTableThemeData.accent.withOpacity(0.35)),
            ),
            child: Text(first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontFamily: EditableTableThemeData.bodyFont, fontSize: 12.5, fontWeight: FontWeight.w600, color: EditableTableThemeData.accent)),
          ),
        ),
        if (extra > 0) ...[
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: t.inputBg, borderRadius: BorderRadius.circular(EditableTableThemeData.radiusSm + 6)),
            child: Text('+$extra',
                style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 12, fontWeight: FontWeight.w600, color: t.fg2)),
          ),
        ],
      ],
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
        isDense: true,
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        hintText: hint,
        hintStyle: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 14, color: _t.fg3),
      );
}

// ============================================================
// Shared little widgets
// ============================================================

/// A rounded select field: optional drag grip, optional leading dot/avatar,
/// the value label, and a trailing chevron — the DS field look.
class _SelectBox<V> extends StatelessWidget {
  final V value;
  final List<V> items;
  final String Function(V) labelOf;
  final ValueChanged<V> onChanged;
  final Widget? Function(V)? leadingOf;
  final double width;
  final bool grip;

  const _SelectBox({
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    this.leadingOf,
    required this.width,
    this.grip = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = EditableTableThemeData.of(context);
    final leading = leadingOf?.call(value);
    return Container(
      width: width,
      height: 38,
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(_kFieldRadius),
        border: Border.all(color: t.borderStrong),
      ),
      child: Row(
        children: [
          if (grip)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9),
              height: double.infinity,
              decoration: BoxDecoration(
                border: BorderDirectional(end: BorderSide(color: t.border)),
              ),
              child: Icon(Icons.drag_indicator_rounded, size: 16, color: t.fg4),
            ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: grip ? 9 : 11, right: 6),
              child: Row(
                children: [
                  if (leading != null) ...[leading, const SizedBox(width: 8)],
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<V>(
                        value: value,
                        isExpanded: true,
                        isDense: true,
                        icon: Icon(Icons.expand_more_rounded, size: 16, color: t.fg3),
                        dropdownColor: t.surface,
                        borderRadius: BorderRadius.circular(_kFieldRadius),
                        style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 14, color: t.fg1),
                        items: [
                          for (final it in items)
                            DropdownMenuItem<V>(
                              value: it,
                              child: Row(
                                children: [
                                  if (leadingOf != null && leadingOf!(it) != null) ...[leadingOf!(it)!, const SizedBox(width: 8)],
                                  Flexible(child: Text(labelOf(it), overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            ),
                        ],
                        onChanged: (v) => v == null ? null : onChanged(v),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A text link action (Add condition / Add subgroup / Clear all).
class _LinkButton extends StatefulWidget {
  final IconData? icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _LinkButton({this.icon, required this.label, required this.color, required this.onTap});

  @override
  State<_LinkButton> createState() => _LinkButtonState();
}

class _LinkButtonState extends State<_LinkButton> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final t = EditableTableThemeData.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: _hover ? t.hover : Colors.transparent,
            borderRadius: BorderRadius.circular(EditableTableThemeData.radiusSm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[Icon(widget.icon, size: 16, color: widget.color), const SizedBox(width: 7)],
              Text(widget.label,
                  style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 14, fontWeight: FontWeight.w600, color: widget.color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatefulWidget {
  final IconData icon;
  final bool danger;
  final String tooltip;
  final VoidCallback onTap;
  const _IconButton({required this.icon, this.danger = false, required this.tooltip, required this.onTap});

  @override
  State<_IconButton> createState() => _IconButtonState();
}

class _IconButtonState extends State<_IconButton> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final t = EditableTableThemeData.of(context);
    final fg = _hover ? (widget.danger ? EditableTableThemeData.danger : t.fg1) : t.fg3;
    final bg = !_hover
        ? Colors.transparent
        : (widget.danger ? EditableTableThemeData.danger.withOpacity(0.12) : t.hover);
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(EditableTableThemeData.radiusSm)),
            child: Icon(widget.icon, size: 17, color: fg),
          ),
        ),
      ),
    );
  }
}

/// The multi-select sheet for `is any of` / `is none of`.
class _MultiSelectDialog extends StatefulWidget {
  final EditableTableThemeData theme;
  final String title;
  final List<String> all;
  final Set<String> initial;
  const _MultiSelectDialog({required this.theme, required this.title, required this.all, required this.initial});

  @override
  State<_MultiSelectDialog> createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<_MultiSelectDialog> {
  late final Set<String> _sel = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 340,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(_kGroupRadius),
            border: Border.all(color: t.borderStrong),
            boxShadow: EditableTableThemeData.popShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title.isEmpty ? 'Select values' : widget.title,
                  style: TextStyle(fontFamily: EditableTableThemeData.displayFont, fontSize: 16, fontWeight: FontWeight.w700, color: t.fg1)),
              const SizedBox(height: 14),
              if (widget.all.isEmpty)
                Text('No values', style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 13, color: t.fg3))
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        for (final v in widget.all)
                          _Selectable(
                            label: v,
                            selected: _sel.contains(v),
                            theme: t,
                            onTap: () => setState(() => _sel.contains(v) ? _sel.remove(v) : _sel.add(v)),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _LinkButton(label: 'Cancel', color: t.fg2, onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(_sel),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(color: EditableTableThemeData.accent, borderRadius: BorderRadius.circular(EditableTableThemeData.radiusMd)),
                      child: const Text('Apply',
                          style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Selectable extends StatelessWidget {
  final String label;
  final bool selected;
  final EditableTableThemeData theme;
  final VoidCallback onTap;
  const _Selectable({required this.label, required this.selected, required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? theme.selectionFill(0.14) : theme.inputBg,
            borderRadius: BorderRadius.circular(EditableTableThemeData.radiusSm + 4),
            border: Border.all(color: selected ? EditableTableThemeData.accent : theme.border, width: selected ? 1.3 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check_rounded, size: 14, color: EditableTableThemeData.accent),
                const SizedBox(width: 5),
              ],
              Text(label,
                  style: TextStyle(
                      fontFamily: EditableTableThemeData.bodyFont,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? theme.fg1 : theme.fg2)),
            ],
          ),
        ),
      ),
    );
  }
}
