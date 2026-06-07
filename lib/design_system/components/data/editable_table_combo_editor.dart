// ============================================================
// EditableTable — COMBO CELL EDITOR.
// ------------------------------------------------------------
// The inline editor for [EditableColumnType.combo] columns (built by
// `ComboBoxColumn`). It replaces the plain text field + popup-menu suffix with
// the first-party **smart_auto_suggest_box** package (publisher: GeniusSystems24,
// same as this design system), giving combo cells a real auto-suggest field:
// type to filter, ↑ ↓ to move through matches, Enter / click to pick, or just
// type a free value and commit.
//
// It is a *thin bridge*, not a new editing model: the table still owns the edit
// session (draft + commit + cursor) on its `EditableTableController`. This
// widget binds the table's existing draft [TextEditingController] to the
// suggest box (via the package's supported `controller:` parameter) so:
//   • the seeded draft shows immediately,
//   • every keystroke flows back through [onChanged] → controller.updateDraft,
//   • picking a suggestion calls [onChanged] + [onCommit] (move down, like Enter),
//   • Esc / Tab / Enter fall through to [onCancel] / [onCommit].
// The grid's commit / cancel / navigation logic is untouched.
//
//   File: lib/design_system/components/data/editable_table_combo_editor.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_auto_suggest_box/smart_auto_suggest_box.dart';
import 'editable_table_models.dart';
import 'editable_table_theme.dart';

/// Inline auto-suggest editor for a combo cell. Stateless-feeling from the
/// table's perspective: it reads/writes the shared draft controller and reports
/// intent through callbacks.
class EditableComboCellEditor extends StatefulWidget {
  /// The combo column being edited (its `options` seed the suggestions).
  final EditableColumn column;

  /// The table's live draft controller — already seeded with the cell's value
  /// by the time this editor mounts. Bound to the suggest box so typed text and
  /// picked suggestions both land here; never disposed by this widget.
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
  late final SmartAutoSuggestDataSource<String> _dataSource;
  String _lastEmitted = '';

  @override
  void initState() {
    super.initState();
    _lastEmitted = widget.textController.text;
    _dataSource = SmartAutoSuggestDataSource<String>(
      itemBuilder: (context, value) => SmartAutoSuggestItem<String>(value: value, label: value),
      initialList: (context) => widget.column.options,
    );
    // Mirror every text change back into the table's draft.
    widget.textController.addListener(_emit);
  }

  @override
  void dispose() {
    widget.textController.removeListener(_emit);
    _dataSource.dispose();
    super.dispose();
  }

  void _emit() {
    final v = widget.textController.text;
    if (v == _lastEmitted) return;
    _lastEmitted = v;
    widget.onChanged(v);
  }

  // Build a package theme that matches our cell editor / overlay surfaces.
  SmartAutoSuggestTheme _suggestTheme() {
    final t = widget.theme;
    final dark = t.bg.computeLuminance() < 0.5;
    final base = dark ? SmartAutoSuggestTheme.dark() : SmartAutoSuggestTheme.light();
    return base.copyWith(
      overlayBorderRadius: BorderRadius.circular(EditableTableThemeData.radiusMd),
      selectedTileColor: t.selectionFill(0.14),
    );
  }

  InputDecoration _decoration() {
    final t = widget.theme;
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: t.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      hintText: widget.column.options.isEmpty ? null : 'Type or pick…',
      hintStyle: TextStyle(color: t.fg4, fontSize: 12.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    // Keyboard fallbacks: the box handles ↑↓ + Enter/Esc for its overlay; these
    // catch the cases where the overlay is closed so the grid still feels native.
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): widget.onCancel,
        const SingleActivator(LogicalKeyboardKey.tab): () => widget.onCommit(0, 1),
        const SingleActivator(LogicalKeyboardKey.tab, shift: true): () => widget.onCommit(0, -1),
      },
      child: DefaultTextStyle.merge(
        style: TextStyle(
          fontFamily: widget.column.mono ? EditableTableThemeData.monoFont : EditableTableThemeData.bodyFont,
          fontSize: 13,
          color: t.fg1,
        ),
        // ignore: deprecated_member_use — `controller:` is the supported bridge to
        // the table's draft text; `smartController` only exposes selection, not
        // the raw typed value the grid commits.
        child: SmartAutoSuggestBox<String>(
          dataSource: _dataSource,
          controller: widget.textController,
          theme: _suggestTheme(),
          decoration: _decoration(),
          onSelected: (item) {
            if (item == null) return;
            widget.onChanged(item.value);
            _lastEmitted = item.value;
            // Pick behaves like Enter: commit and step down to the next row.
            widget.onCommit(1, 0);
          },
        ),
      ),
    );
  }
}
