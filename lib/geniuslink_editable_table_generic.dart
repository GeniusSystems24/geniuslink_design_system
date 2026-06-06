// ============================================================
// GeniusLink — EditableTable (GENERIC row type) — public barrel.
//   import 'package:geniuslink_design_system/geniuslink_editable_table_generic.dart';
//
// A strongly-typed, Excel-style data-entry grid: `EditableTable<T>` over a
// `List<T>` of an immutable value, with `EditableColumn<T>` (value / setValue)
// accessors, inline editing, click-to-sort, drag-to-resize + reorder columns,
// TSV copy, RTL-aware keyboard navigation and scroll-on-focus.
//
//   • Model + Controller — editable_table_generic.dart
//   • View               — editable_table_generic_view.dart
//   • Theme              — editable_table_theme.dart  (shared table theme)
//
// NOTE: This barrel and `geniuslink_editable_table.dart` (the map-backed table)
// declare the same names (`EditableTable`, `EditableColumn`, …). Import ONE of
// them per file.
// ============================================================

export 'design_system/components/data/editable_table_theme.dart';
export 'design_system/components/data/editable_table_generic.dart';
export 'design_system/components/data/editable_table_generic_view.dart';
