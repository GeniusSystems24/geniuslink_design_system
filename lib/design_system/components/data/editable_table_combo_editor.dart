// ============================================================
// EditableTable — COMBO CELL EDITOR.
// ------------------------------------------------------------
// The inline editor for [EditableColumnType.combo] columns (built by
// `ComboBoxColumn`). It embeds the design-system-native **AutoSuggestionsBox**
// (no third-party dependency) in "bare" mode so it sits flush in the cell:
// type to filter, ↑ ↓ to move through matches, Enter / click to pick, or just
// type a free value and commit.
//
// When the column supplies `fetchOptions`, the editor uses a *hybrid* source —
// the local `options` show instantly and, when the query has no (or too few)
// local matches, more are loaded asynchronously and merged in. Otherwise it's a
// plain static list.
//
// It is a *thin bridge*, not a new editing model: the table still owns the edit
// session (draft + commit + cursor) on its `EditableTableController`. The box's
// controller is bound to the table's existing draft [TextEditingController] so:
//   • the seeded draft shows immediately,
//   • every keystroke flows back through [onChanged] → controller.updateDraft,
//   • picking a suggestion calls [onChanged] + [onCommit] (move down, like Enter),
//   • free-text Enter commits + moves down; Esc cancels; Tab moves sideways.
// The grid's commit / cancel / navigation logic is untouched.
//
//   File: lib/design_system/components/data/editable_table_combo_editor.dart
// ============================================================

import 'package:flutter/material.dart';
import '../forms/auto_suggestions_box.dart';
import '../forms/auto_suggestions_box_controller.dart';
import '../forms/auto_suggestions_box_models.dart';
import '../forms/auto_suggestions_box_theme.dart';
import 'editable_table_columns.dart';
import 'editable_table_models.dart';
import 'editable_table_theme.dart';

/// Inline auto-suggest editor for a combo cell. Reads/writes the shared draft
/// controller and reports intent through callbacks.
class EditableComboCellEditor extends StatefulWidget {
  /// The combo column being edited (its `options` / `fetchOptions` drive the box).
  final EditableColumn column;

  /// The table's live draft controller — already seeded with the cell's value
  /// by the time this editor mounts. Bound to the box so typed text and picked
  /// suggestions both land here; never disposed by this widget.
  final TextEditingController textController;

  /// Right-align the field (numeric-ish combos); start-aligned by default.
  final bool alignEnd;

  /// The current table theme, for a matching field + overlay look.
  final EditableTableThemeData theme;

  /// Called on every text change → forward to `controller.updateDraft`.
  final ValueChanged<String> onChanged;

  /// Called to commit + move the cursor by (dRow, dCol) → `_commitMove`.
  final void Function(int dRow, int dCol) onCommit;

  /// Called to abandon the edit (Esc) → `_cancel`.
  final VoidCallback onCancel;

  const EditableComboCellEditor({
    super.key,
    required this.column,
    required this.textController,
    required this.theme,
    required this.onChanged,
    required this.onCommit,
    required this.onCancel,
    this.alignEnd = false,
  });

  @override
  State<EditableComboCellEditor> createState() => _EditableComboCellEditorState();
}

class _EditableComboCellEditorState extends State<EditableComboCellEditor> {
  late final AutoSuggestionsBoxController<String> _box;

  @override
  void initState() {
    super.initState();
    _box = AutoSuggestionsBoxController<String>(
      source: _buildSource(),
      textController: widget.textController, // share the table's draft text
      allowFreeText: true,
    );
  }

  AutoSuggestionsSource<String> _buildSource() {
    final col = widget.column;
    final options = col.options;
    final items = [for (final o in options) AutoSuggestion<String>(value: o, label: o)];
    if (col is ComboBoxColumn && col.fetchOptions != null) {
      // Hybrid: local first, then load more from the column's async loader.
      return AutoSuggestionsSource<String>.hybrid(
        initialItems: items,
        remoteThreshold: col.remoteThreshold,
        remoteMinChars: col.remoteMinChars,
        fetch: (q) async {
          final more = await col.fetchOptions!(q);
          return [for (final o in more) AutoSuggestion<String>(value: o, label: o)];
        },
      );
    }
    return AutoSuggestionsSource<String>.list(items);
  }

  @override
  void dispose() {
    // The text controller is owned by the table — only dispose our controller's
    // own machinery (it won't dispose the shared text controller).
    _box.dispose();
    super.dispose();
  }

  /// Map the table theme onto the box's ThemeExtension so the overlay matches.
  AutoSuggestionsBoxThemeData _boxTheme() {
    final t = widget.theme;
    final dark = t.bg.computeLuminance() < 0.5;
    final base = dark ? AutoSuggestionsBoxThemeData.dark : AutoSuggestionsBoxThemeData.light;
    return base.copyWith(
      overlayBg: t.surface,
      fieldBg: t.surface,
      fieldBgFocus: t.surface,
      hover: t.selectionFill(0.14),
      border: t.border,
      borderFocus: EditableTableThemeData.accent,
      fg1: t.fg1,
      fg2: t.fg3,
      fg3: t.fg4,
      groupFg: t.fg4,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Theme(
      data: Theme.of(context).copyWith(extensions: [_boxTheme()]),
      child: AutoSuggestionsBox<String>(
        controller: _box,
        bare: true,
        autofocus: true,
        scrollOnFocus: false, // the table owns cell scrolling
        fieldHeight: EditableTableThemeData.rowHeight,
        maxVisibleRows: 7,
        clearButton: false,
        hintText: widget.column.options.isEmpty ? null : 'Type or pick…',
        textStyle: TextStyle(
          fontFamily: widget.column.mono ? EditableTableThemeData.monoFont : EditableTableThemeData.bodyFont,
          fontSize: 13,
          height: 1.2,
          color: t.fg1,
        ),
        onChanged: widget.onChanged,
        onSelected: (s) {
          widget.onChanged(s.value);
          // Pick behaves like Enter: commit and step down to the next row.
          widget.onCommit(1, 0);
        },
        onSubmitted: (_) => widget.onCommit(1, 0), // free-text Enter
        onEscape: widget.onCancel,
        onTabNext: () => widget.onCommit(0, 1),
        onTabPrev: () => widget.onCommit(0, -1),
      ),
    );
  }
}
